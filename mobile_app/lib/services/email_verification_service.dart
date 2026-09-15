import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'bug_report_service.dart';

class EmailVerificationService {
  EmailVerificationService._();

  static const String _abstractApiKey = '97baf1feab844f4cab215d646e910880';

  static Future<bool> isEmailReal(String email) async {
    final url = Uri.parse(
      'https://emailreputation.abstractapi.com/v1/?api_key=$_abstractApiKey&email=$email',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('EmailVerificationService: API error ${response.statusCode} - ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final deliverability = data['email_deliverability'] as Map<String, dynamic>?;
      final quality = data['email_quality'] as Map<String, dynamic>?;
      final risk = data['email_risk'] as Map<String, dynamic>?;

      final status = deliverability?['status'] as String?;
      final isSmtpValid = deliverability?['is_smtp_valid'] as bool? ?? false;
      final isMxValid = deliverability?['is_mx_valid'] as bool? ?? false;
      final isDisposable = quality?['is_disposable'] as bool? ?? false;
      final riskStatus = risk?['address_risk_status'] as String? ?? 'high';

      return status == 'deliverable' && isSmtpValid && isMxValid && !isDisposable && riskStatus != 'high';
    } catch (e, st) {
      debugPrint('EmailVerificationService.isEmailReal failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot verify email address');
      return false;
    }
  }
}
