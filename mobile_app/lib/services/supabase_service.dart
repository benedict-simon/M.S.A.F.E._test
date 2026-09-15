// lib/services/supabase_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_service.dart';
import 'user_service.dart';
import 'navigation_service.dart';
import 'history_service.dart';
import 'report_service.dart';
import 'notification_service.dart';
import 'vendor_service.dart';
import 'supplier_report_service.dart';

class SupabaseService {
  // FROM PROJECT SETTINGS > API > DATA API
  static const String supabaseUrl = 'https://flurlbxydnnpmccsashm.supabase.co';

  // FROM PROJECT SETTINGS > API KEYS > LEGACY ANON PUBLIC KEY
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsdXJsYnh5ZG5ucG1jY3Nhc2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxNjE0MjQsImV4cCI6MjEwMDczNzQyNH0.Ky7ou8DN4fqBR4Mu2Mew-Nfnb9rwIc9ZBWHSt43_zd4';

  // Fetches everything a logged-in session needs on Home/History/Reports —
  // shared between the cold-start session restore below and anywhere else
  // that needs the same post-login data pull.
  static Future<void> _loadUserData() async {
    try {
      await Future.wait([
        HistoryService.fetchAll(),
        ReportService.fetchAll(),
        NotificationService.fetchAll(),
        VendorService.fetchCurrent(),
        SupplierReportService.fetchAll(),
      ]);
    } catch (e, st) {
      debugPrint('SupabaseService: post-login data fetch failed: $e\n$st');
    }
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    final restoredUser = client.auth.currentUser;
    if (restoredUser != null && restoredUser.emailConfirmedAt != null) {
      SessionService.markLoggedIn();
      await UserService.loadCurrentProfile();
      // THIS WAS MISSING — A RESTORED SESSION NEVER GOES THROUGH
      // LOGIN_SCREEN'S onSuccess, SO HISTORY/REPORTS NEVER GOT FETCHED
      await _loadUserData();
    }

    client.auth.onAuthStateChange.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          final user = data.session?.user;
          if (user != null && user.emailConfirmedAt == null) {
            client.auth.signOut();
            break;
          }

          SessionService.markLoggedIn();
          await UserService.loadCurrentProfile();

          final route = UserService.postLoginRoute;
          if (route != '/home') {
            NavigationService.navigatorKey.currentState
                ?.pushNamedAndRemoveUntil(route, (route) => false);
          }
          break;
        case AuthChangeEvent.passwordRecovery:
          // Fires when the user lands back in the app via a "forgot
          // password" email link — Supabase grants a temporary recovery
          // session for this. Mark it logged in too (not just navigate) so
          // SplashScreen's own session-settling wait — see splash_screen.dart
          // — doesn't time out if it happens to process this before we do.
          SessionService.markLoggedIn();
          await UserService.loadCurrentProfile();
          // Send them straight to the password-reset screen, not Home,
          // since they haven't set a new password yet.
          NavigationService.navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/reset-password', (route) => false);
          break;
        case AuthChangeEvent.signedOut:
          SessionService.signOut();
          break;
        default:
          break;
      }
    });
  }

  static SupabaseClient get client => Supabase.instance.client;
}