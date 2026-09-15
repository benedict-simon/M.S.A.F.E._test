import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'supabase_service.dart';

class BugReportService {
  BugReportService._();

  static const String subject = 'Automatic Bug Report';

  static const int _maxReportsPerSession = 5;
  static int _sentThisSession = 0;
  static final Set<String> _alreadyReported = {};

  static Future<void> reportError(Object error, StackTrace? stackTrace, {String? context}) async {

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      debugPrint('BugReportService: not signed in, skipping auto-report for: $error');
      return;
    }

    if (_sentThisSession >= _maxReportsPerSession) {
      debugPrint('BugReportService: session cap ($_maxReportsPerSession) reached, skipping: $context');
      return;
    }
    final signature = '${context ?? ''}|$error';
    if (!_alreadyReported.add(signature)) {
      debugPrint('BugReportService: already reported this error this session, skipping: $context');
      return; // add() returns false if already present
    }
    _sentThisSession++;

    final message = 'Bug detected: ${context ?? 'Something went wrong'}';

    try {
      await SupabaseService.client.from('user_feedback').insert({
        'user_id': user.id,
        'subject': subject,
        'message': message,
        'status': 'open',
      });
    } catch (e) {

      debugPrint('BugReportService: failed to send auto bug report: $e');
      return; // don't tell the user we reported it if we actually didn't
    }

    final isEn = SettingsService.isEnglish;
    await NotificationService.add(
      kind: NotificationKind.bugReportSubmitted,
      title: isEn ? 'We caught a bug' : 'May Na-detect na Bug',
      body: isEn
          ? "Something went wrong on your end just now — we've automatically reported it to our team."
          : 'May naganap na problema kanina — awtomatiko na itong na-report sa aming team.',
    );
  }
}
