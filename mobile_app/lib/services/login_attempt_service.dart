import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

class LoginLockStatus {
  final bool locked;
  final int? retryAfterSeconds;
  final int? attemptsRemaining;
  const LoginLockStatus({required this.locked, this.retryAfterSeconds, this.attemptsRemaining});
}

class LoginAttemptService {
  static const _timeout = Duration(seconds: 10);

  Future<LoginLockStatus> checkLock(String username) async {
    final result = await _post('/auth/login-check', username);
    if (result == null) return const LoginLockStatus(locked: false);
    return LoginLockStatus(
      locked: result['locked'] as bool? ?? false,
      retryAfterSeconds: result['retry_after_seconds'] as int?,
    );
  }

  Future<LoginLockStatus> recordFailure(String username) async {
    final result = await _post('/auth/login-failed', username);
    if (result == null) return const LoginLockStatus(locked: false);
    return LoginLockStatus(
      locked: result['locked'] as bool? ?? false,
      retryAfterSeconds: result['retry_after_seconds'] as int?,
      attemptsRemaining: result['attempts_remaining'] as int?,
    );
  }

  Future<void> recordSuccess(String username) async {
    await _post('/auth/login-success', username);
  }

  // Login-lockout tracking is a defense-in-depth extra, not the primary
  // gate (Supabase's own auth call still does the real authentication) — so
  // if the backend is unreachable, fail open (return null/not-locked)
  // rather than blocking every login whenever the backend happens to be down.
  Future<Map<String, dynamic>?> _post(String path, String username) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}$path');
    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username}))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
