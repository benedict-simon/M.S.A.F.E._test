// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bug_report_service.dart';
import 'supabase_service.dart';

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  static bool isGuest = false;

  static String get _authRedirectTo =>
      kIsWeb ? Uri.base.origin : 'io.supabase.msafe://login-callback';

  // Account creation itself now happens on the backend, only after an
  // emailed OTP is verified — see SignupOtpService and
  // backend/app/routers/auth.py. This just establishes the client-side
  // session once that account exists, reusing the same signInWithPassword
  // call changePassword() below already relies on for verification.
  Future<void> signInWithPassword({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e, st) {
      debugPrint('signInWithPassword AuthException: ${e.message} (code: ${e.statusCode})\n$st');
      throw AuthServiceException(_friendlyAuthMessage(e));
    } catch (e, st) {
      debugPrint('signInWithPassword unexpected error: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot sign in after signup verification');
      throw const AuthServiceException(
        "Your account was created, but we couldn't sign you in automatically. Please sign in manually.",
      );
    }
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final email = await _client.rpc(
        'get_email_by_username',
        params: {'uname': username},
      ) as String?;

      if (email == null) {
        throw const AuthServiceException('No account found for that username.');
      }

      final res = await _client.auth.signInWithPassword(email: email, password: password);

      if (res.user?.emailConfirmedAt == null) {
        await _client.auth.signOut();
        throw const AuthServiceException(
          'Please confirm your email address first. Check your inbox for the verification link we sent you.',
        );
      }
    } on AuthServiceException {
      rethrow;
    } on AuthException catch (e, st) {
      debugPrint('Sign in AuthException: ${e.message} (code: ${e.statusCode})\n$st');
      throw AuthServiceException(_friendlyAuthMessage(e));
    } on PostgrestException catch (e, st) {
      debugPrint('Sign in PostgrestException: ${e.message} (code: ${e.code})\n$st');
      throw const AuthServiceException(
        "We couldn't sign you in. Please try again.",
      );
    } catch (e, st) {
      debugPrint('Sign in unexpected error: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot sign in');
      throw const AuthServiceException(
        "We couldn't sign you in. Please check your connection and try again.",
      );
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
  try {
    final result = await _client.rpc(
      'is_username_available',
      params: {'uname': username},
    ) as bool?;
    return result ?? true;
  } catch (e, st) {
    debugPrint('isUsernameAvailable check failed: $e\n$st');
    BugReportService.reportError(e, st, context: 'Cannot check username availability');
    return true; // fail open — real signup attempt still catches a genuine duplicate
  }
}

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _authRedirectTo,
      );
    } on AuthException catch (e, st) {
      debugPrint('Google sign-in AuthException: ${e.message} (code: ${e.statusCode})\n$st');
      throw AuthServiceException(_friendlyAuthMessage(e));
    } catch (e, st) {
      debugPrint('Google sign-in unexpected error: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot sign in with Google');
      throw const AuthServiceException('Google sign-in failed. Please try again.');
    }
  }

  Future<void> signInAsGuest() async {
    isGuest = true;

    if (_client.auth.currentUser != null) {
      try {
        await _client.auth.signOut();
      } catch (e, st) {
        debugPrint('signInAsGuest: failed to clear a lingering session: $e\n$st');
      }
    }
  }

  Future<void> updateProfile({
    required String firstName,
    String middleInitial = '',
    required String lastName,
    required String username,
    required String email,
    String phoneNumber = '',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthServiceException('You need to be signed in to update your profile.');
    }

    try {
      await _client.from('profiles').update({
        'first_name': firstName,
        'middle_initial': middleInitial,
        'last_name': lastName,
        'username': username,
        'phone_number': phoneNumber,
        'user_email': email,
      }).eq('profile_id', user.id);

      final emailChanged = email.isNotEmpty && email != user.email;
      await _client.auth.updateUser(UserAttributes(
        email: emailChanged ? email : null,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'phone_number': phoneNumber,
        },
      ));
    } on AuthException catch (e, st) {
      debugPrint('updateProfile AuthException: ${e.message} (code: ${e.statusCode})\n$st');
      throw AuthServiceException(_friendlyAuthMessage(e));
    } on PostgrestException catch (e, st) {
      debugPrint('updateProfile PostgrestException: ${e.message} (code: ${e.code})\n$st');
      throw AuthServiceException(_friendlyDbMessage(e));
    } catch (e, st) {
      debugPrint('updateProfile unexpected error: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot save profile changes');
      throw const AuthServiceException("We couldn't save your changes. Please check your connection and try again.");
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw const AuthServiceException('You need to be signed in to change your password.');
    }

    try {
      await _client.auth.signInWithPassword(email: email, password: currentPassword);
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e, st) {
      debugPrint('changePassword AuthException: ${e.message} (code: ${e.statusCode})\n$st');
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
        throw const AuthServiceException('Your current password is incorrect.');
      }
      throw AuthServiceException(_friendlyAuthMessage(e));
    } catch (e, st) {
      debugPrint('changePassword unexpected error: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot change password');
      throw const AuthServiceException("We couldn't update your password. Please check your connection and try again.");
    }
  }

  /// Asks Supabase to send a password-reset link to [email]. Tapping that
  /// link lands back in the app via AuthChangeEvent.passwordRecovery (see
  /// supabase_service.dart), which routes to reset_password_screen.dart to
  /// actually set the new password.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email, redirectTo: _authRedirectTo);
    } on AuthException catch (e, st) {
      debugPrint('sendPasswordResetEmail AuthException: ${e.message} (code: ${e.statusCode})\n$st');
      throw AuthServiceException(_friendlyAuthMessage(e));
    } on PostgrestException catch (e, st) {
      debugPrint('sendPasswordResetEmail PostgrestException: ${e.message} (code: ${e.code})\n$st');
      throw const AuthServiceException("We couldn't send the reset email. Please try again.");
    } catch (e, st) {
      debugPrint('sendPasswordResetEmail unexpected error: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot send password reset email');
      throw const AuthServiceException(
        "We couldn't send the reset email. Please check your connection and try again.",
      );
    }
  }

  Future<void> updatePasswordAfterReset(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e, st) {
      debugPrint('updatePasswordAfterReset AuthException: ${e.message} (code: ${e.statusCode})\n$st');
      throw AuthServiceException(_friendlyAuthMessage(e));
    } catch (e, st) {
      debugPrint('updatePasswordAfterReset unexpected error: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot set new password');
      throw const AuthServiceException(
        "We couldn't update your password. Please check your connection and try again.",
      );
    }
  }

  Future<void> signOut() async {
    isGuest = false;
    await _client.auth.signOut();
  }

  Future<void> requestAccountDeletion() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthServiceException('You need to be signed in to delete your account.');
    }

    try {
      await _client.from('profiles').update({
        'deletion_requested_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('profile_id', user.id);
    } on PostgrestException catch (e, st) {
      debugPrint('requestAccountDeletion PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot request account deletion');
      throw AuthServiceException(
        kDebugMode
            ? "We couldn't start account deletion: ${e.message} (code: ${e.code})"
            : "We couldn't start account deletion. Please try again.",
      );
    } catch (e, st) {
      debugPrint('requestAccountDeletion failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot request account deletion');
      throw const AuthServiceException(
        "We couldn't start account deletion. Please check your connection and try again.",
      );
    }
  }

  Future<void> restoreAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthServiceException('You need to be signed in to restore your account.');
    }

    try {
      await _client.from('profiles').update({
        'deletion_requested_at': null,
      }).eq('profile_id', user.id);
    } on PostgrestException catch (e, st) {
      debugPrint('restoreAccount PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot restore account');
      throw AuthServiceException(
        kDebugMode
            ? "We couldn't restore your account: ${e.message} (code: ${e.code})"
            : "We couldn't restore your account. Please try again.",
      );
    } catch (e, st) {
      debugPrint('restoreAccount failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot restore account');
      throw const AuthServiceException(
        "We couldn't restore your account. Please check your connection and try again.",
      );
    }
  }

  bool get isLoggedIn => _client.auth.currentSession != null;

  // ---------- Error message mapping ----------

  String _friendlyAuthMessage(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('database error saving new user')) {
      return 'That username or email is already in use. Please try a different one.';
    }
    if (msg.contains('already registered') || msg.contains('already exists') || msg.contains('duplicate')) {
      return 'An account with that email already exists. Try logging in instead.';
    }
    if (msg.contains('password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (msg.contains('invalid') && msg.contains('email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return "We couldn't sign you in. Check your username and password and try again.";
    }
    if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
      return 'Please confirm your email address first. Check your inbox for the verification link we sent you.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    }
    return e.message;
  }

  String _friendlyDbMessage(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('username') && (msg.contains('duplicate') || msg.contains('unique'))) {
      return 'That username is already taken. Please choose another.';
    }
    if (msg.contains('duplicate') || msg.contains('unique')) {
      return 'Some of these details are already in use. Please try different values.';
    }
    if (msg.contains('permission') || msg.contains('policy') || msg.contains('rls')) {
      return "We couldn't finish setting up your account. Please try again in a moment.";
    }
    return "We couldn't finish creating your account. Please try again.";
  }
}