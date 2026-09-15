import 'package:flutter/foundation.dart';
import 'bug_report_service.dart';
import 'supabase_service.dart';

class FeedbackServiceException implements Exception {
  final String message;
  const FeedbackServiceException(this.message);
  @override
  String toString() => message;
}

class FeedbackService {
  FeedbackService._();

  static Future<void> submit({
    required String subject,
    required String message,
    required String email,
    int? rating,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw const FeedbackServiceException('You need to be signed in to send feedback.');
    }

    try {
      await SupabaseService.client.from('user_feedback').insert({
        'user_id': user.id,
        'subject': subject,
        'message': message,
        'rating': rating,
        'status': 'open',
      });
    } catch (e, st) {
      debugPrint('FeedbackService.submit failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot send feedback');
      throw const FeedbackServiceException(
        "We couldn't send your message. Please check your connection and try again.",
      );
    }
  }
}
