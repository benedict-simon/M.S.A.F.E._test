// lib\services\user_service.dart

import 'package:flutter/foundation.dart';
import 'bug_report_service.dart';
import 'supabase_service.dart';

class UserProfile {
  final String userId;
  final String firstName;
  final String middleInitial;
  final String lastName;
  final String username;
  final String email;

  final String phone;
  final String accountType;
  final DateTime? deletionRequestedAt;

  const UserProfile({
    required this.userId,
    required this.firstName,
    this.middleInitial = '',
    required this.lastName,
    required this.username,
    required this.email,
    this.phone = '',
    this.accountType = 'consumer',
    this.deletionRequestedAt,
  });

  String get fullName => [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  bool get isVendor => accountType == 'vendor';

  bool get isPendingDeletion => deletionRequestedAt != null;

  DateTime? get permanentDeletionDate => deletionRequestedAt?.add(const Duration(days: 30));
}

class UserService {
  UserService._();

  static final ValueNotifier<UserProfile?> profile = ValueNotifier(null);

  static Future<void> loadCurrentProfile() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      profile.value = null;
      return;
    }

    final email = user.email ?? '';
    final meta = user.userMetadata ?? {};

    try {
      final row = await SupabaseService.client
          .from('profiles')
          .select('first_name, middle_initial, last_name, username, phone_number, account_type, deletion_requested_at')
          .eq('profile_id', user.id)
          .maybeSingle();

      final deletionRequestedAtStr = row?['deletion_requested_at'] as String?;

      profile.value = UserProfile(
        userId: user.id,
        firstName: (row?['first_name'] as String?)?.trim() ?? (meta['first_name'] as String?)?.trim() ?? '',
        middleInitial: (row?['middle_initial'] as String?)?.trim() ?? (meta['middle_initial'] as String?)?.trim() ?? '',
        lastName: (row?['last_name'] as String?)?.trim() ?? (meta['last_name'] as String?)?.trim() ?? '',
        username: (row?['username'] as String?)?.trim() ?? (meta['username'] as String?)?.trim() ?? '',
        email: email,
        phone: (row?['phone_number'] as String?)?.trim() ?? (meta['phone_number'] as String?)?.trim() ?? '',
        accountType: (row?['account_type'] as String?)?.trim() ?? 'consumer',
        deletionRequestedAt: deletionRequestedAtStr != null ? DateTime.parse(deletionRequestedAtStr).toLocal() : null,
      );
    } catch (e, st) {
      debugPrint('UserService.loadCurrentProfile failed, falling back to auth metadata: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load your profile');

      profile.value = UserProfile(
        userId: user.id,
        firstName: (meta['first_name'] as String?)?.trim() ?? '',
        middleInitial: (meta['middle_initial'] as String?)?.trim() ?? '',
        lastName: (meta['last_name'] as String?)?.trim() ?? '',
        username: (meta['username'] as String?)?.trim() ?? '',
        email: email,
        phone: (meta['phone_number'] as String?)?.trim() ?? '',
      );
    }
  }

  static void clear() => profile.value = null;

  /// Where a just-authenticated user should land — factored out since both
  /// SplashScreen (app cold-launched with a session already restored, e.g.
  /// via the email confirmation deep link) and SupabaseService's
  /// onAuthStateChange listener (a fresh sign-in) need to make this same
  /// decision.
  static String get postLoginRoute {
    final p = profile.value;
    if (p == null) return '/home';
    if (p.username.isEmpty) return '/finish-profile';
    if (p.isPendingDeletion) return '/account-restore';
    return '/home';
  }
}
