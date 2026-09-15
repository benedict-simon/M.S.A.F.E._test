// main.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'theme/app_theme.dart';
import 'models/meat_type.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/meat_type_selection_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/history_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/report_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/education_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'services/supabase_service.dart';
import 'services/settings_service.dart';
import 'services/user_service.dart';
import 'services/navigation_service.dart';
import 'services/bug_report_service.dart';
import 'screens/feedback_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/vendor_application_screen.dart';
import 'screens/google_profile_finish_screen.dart';
import 'screens/account_restore_screen.dart';
import 'screens/reset_password_screen.dart';

Future<void> main() async {
  // On web, Flutter defaults to hash-based URLs (e.g. "/#/home"), which
  // breaks when Supabase redirects back with its own "#access_token=..."
  // fragment (email confirmation, password reset) — Flutter tries to treat
  // that fragment as a route name and fails with "Page not found". Clean
  // path-based URLs avoid the collision. No-op on non-web platforms.
  usePathUrlStrategy();

  // Catches anything that slips past FlutterError.onError/PlatformDispatcher
  // below — e.g. errors thrown from async code not attached to a Flutter
  // error zone. Together the three handlers cover: framework/widget errors,
  // platform-level errors, and everything else uncaught and async.
  runZonedGuarded(() async {
    // SUPABASE MUST BE READY BEFORE THE APP OPENS
    WidgetsFlutterBinding.ensureInitialized();

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      originalOnError?.call(details); // keep the normal red-screen/console output in debug
      // FlutterErrorDetails.summary describes what the framework was doing
      // when it broke (e.g. "building MyWidget(dirty)") — far more useful
      // in a report than a bare "FlutterError" label.
      BugReportService.reportError(
        details.exception,
        details.stack,
        context: details.summary.toString(),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      BugReportService.reportError(error, stack, context: 'Cannot complete a platform-level operation');
      return true; // handled — don't also crash the platform-level isolate
    };

    await SupabaseService.initialize();
    await SettingsService.init();
    runApp(const MSafeApp());
  }, (error, stack) {
    BugReportService.reportError(error, stack, context: 'Cannot complete a background operation');
  });
}

class MSafeApp extends StatelessWidget {
  const MSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.darkMode, UserService.profile]),
      builder: (context, _) {
        return MaterialApp(
          title: 'M.S.A.F.E.',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,

          // LETS SERVICES WITHOUT A BuildContext (LIKE SupabaseService'S
          // AUTH LISTENER) REDIRECT THE USER IMPERATIVELY
          navigatorKey: NavigationService.navigatorKey,

          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/onboarding': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              return OnboardingScreen(nextRoute: args is String ? args : '/home');
            },
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
            '/finish-profile': (context) => const GoogleProfileFinishScreen(),
            '/account-restore': (context) => const AccountRestoreScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/meat-type': (context) => const MeatTypeSelectionScreen(),
            '/scan': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              if (args is MeatType) {
                return ScanScreen(meatType: args);
              }

              return const MeatTypeSelectionScreen();
            },
            '/history': (context) => const HistoryScreen(),
            '/scan-result': (context) => const ScanResultScreen(),
            '/report': (context) => ReportScreen(),
            '/reports': (context) => const ReportsScreen(),
            '/education': (context) => const EducationScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/notifications': (context) => const NotificationScreen(),
            '/feedback': (context) => const FeedbackScreen(),
            '/summary': (context) => const SummaryScreen(),
            '/vendor-application': (context) => const VendorApplicationScreen(),
          },
          onUnknownRoute: (settings) {
            // Supabase's auth redirects (email confirmation, password
            // reset) land on the bare root path with a query string (e.g.
            // "/?code=...") — treat that the same as a normal cold launch
            // instead of registering "/" as a permanent, poppable route in
            // `routes` (that broke popUntil/back-navigation elsewhere in
            // the app, since it made "/" a real destination the Navigator
            // stack could return to). SplashScreen already waits for
            // Supabase to finish processing whatever's in the URL before
            // deciding where to go next.
            final name = settings.name ?? '';
            if (name == '/' || name.startsWith('/?')) {
              return MaterialPageRoute(builder: (context) => const SplashScreen());
            }
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Page not found')),
                body: Center(child: Text('No route defined for "${settings.name}"')),
              ),
            );
          },
        );
      },
    );
  }
}