import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

/// Calls the FastAPI backend's OTP-before-account-creation signup endpoints
/// (see backend/app/routers/auth.py) — no Supabase Auth account exists
/// until verify() succeeds.
class SignupOtpServiceException implements Exception {
  final String message;
  const SignupOtpServiceException(this.message);
  @override
  String toString() => message;
}

class SignupOtpService {
  static const _timeout = Duration(seconds: 20);

  Future<void> requestOtp(String email) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/auth/signup/request-otp');
    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}))
          .timeout(_timeout);
    } catch (e) {
      throw SignupOtpServiceException(
        "Couldn't reach the server to send a code. Please check your connection and try again.",
      );
    }
    if (response.statusCode != 200) {
      throw SignupOtpServiceException(_errorDetail(response));
    }
  }

  Future<void> verify({
    required String email,
    required String otp,
    required String firstName,
    String middleInitial = '',
    required String lastName,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/auth/signup/verify');
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'first_name': firstName,
              'middle_initial': middleInitial,
              'last_name': lastName,
              'username': username,
              'phone_number': phoneNumber,
              'password': password,
            }),
          )
          .timeout(_timeout);
    } catch (e) {
      throw SignupOtpServiceException(
        "Couldn't reach the server to verify that code. Please check your connection and try again.",
      );
    }
    if (response.statusCode != 200) {
      throw SignupOtpServiceException(_errorDetail(response));
    }
  }

  String _errorDetail(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final detail = body is Map ? body['detail'] : null;
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {
      // fall through to the generic message below
    }
    return "Something went wrong. Please try again.";
  }
}
