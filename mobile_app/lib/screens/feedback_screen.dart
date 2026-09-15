import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/feedback_theme.dart';
import '../widgets/guest_gate.dart';
import '../services/settings_service.dart';

enum ReportStatus { underReview, investigated, resolved }

extension ReportStatusX on ReportStatus {
  String label(bool isEn) {
    if (isEn) {
      switch (this) {
        case ReportStatus.underReview:
          return 'Under Review';
        case ReportStatus.investigated:
          return 'Investigated';
        case ReportStatus.resolved:
          return 'Resolved';
      }
    }
    switch (this) {
      case ReportStatus.underReview:
        return 'Sinusuri Pa';
      case ReportStatus.investigated:
        return 'Iniimbestigahan';
      case ReportStatus.resolved:
        return 'Nalutas Na';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.underReview:
        return AppTheme.accentGold;
      case ReportStatus.investigated:
        return AppTheme.primaryRedDark;
      case ReportStatus.resolved:
        return AppTheme.freshGreen;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.underReview:
        return Icons.hourglass_top_rounded;
      case ReportStatus.investigated:
        return Icons.search_rounded;
      case ReportStatus.resolved:
        return Icons.verified_outlined;
    }
  }
}

class _ReportFeedback {
  final String reportId;
  final String meatType;
  final ReportStatus status;

  final String? findings;

  final DateTime? respondedAt;

  final DateTime submittedAt;
  final bool isNew;

  const _ReportFeedback({
    required this.reportId,
    required this.meatType,
    required this.status,
    required this.submittedAt,
    this.findings,
    this.respondedAt,
    this.isNew = false,
  });
}

class FeedbackScreen extends StatefulWidget {

  final String? highlightReportId;

  const FeedbackScreen({super.key, this.highlightReportId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isRefreshing = false;
  String? _highlightReportId;

  final Map<String, GlobalKey> _tileKeys = {};

  final List<_ReportFeedback> _feedback = [
    _ReportFeedback(
      reportId: 'report_1',
      meatType: 'Chicken',
      status: ReportStatus.resolved,
      submittedAt: DateTime.now().subtract(const Duration(days: 4)),
      respondedAt: DateTime.now().subtract(const Duration(hours: 5)),
      findings:
          'Inspection confirmed early spoilage consistent with a broken cold chain at the point of sale. '
          'The vendor has been notified and re-inspected under NMIS storage guidelines. Thank you for flagging this — '
          'reports like yours help us catch handling issues before they affect more consumers.',
      isNew: true,
    ),
    _ReportFeedback(
      reportId: 'report_2',
      meatType: 'Pork',
      status: ReportStatus.investigated,
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      respondedAt: DateTime.now().subtract(const Duration(days: 1)),
      findings: 'An inspector visited the reported vendor and is reviewing storage logs. '
          "We'll follow up with a final assessment shortly.",
    ),
    _ReportFeedback(
      reportId: 'report_3',
      meatType: 'Beef',
      status: ReportStatus.underReview,
      submittedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _highlightReportId = widget.highlightReportId;
    for (final f in _feedback) {
      _tileKeys[f.reportId] = GlobalKey();
    }
    if (_highlightReportId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlighted());
      // Highlight ring fades after a few seconds so it reads as a pointer,
      // not a permanent state.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightReportId = null);
      });
    }
  }

  void _scrollToHighlighted() {
    final key = _tileKeys[_highlightReportId];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), alignment: 0.1);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.highlightReportId == null) {
      final routeArg = ModalRoute.of(context)?.settings.arguments;
      if (routeArg is String && routeArg != _highlightReportId) {
        setState(() => _highlightReportId = routeArg);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlighted());
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _formatTimestamp(DateTime dt, bool isEn) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return isEn ? 'Just now' : 'Ngayon lang';
    if (diff.inMinutes < 60) return isEn ? '${diff.inMinutes}m ago' : '${diff.inMinutes}m ang nakalipas';
    if (diff.inHours < 24) return isEn ? '${diff.inHours}h ago' : '${diff.inHours}h ang nakalipas';
    if (diff.inDays < 7) return isEn ? '${diff.inDays}d ago' : '${diff.inDays}d ang nakalipas';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  void _openDetail(_ReportFeedback f) {
    setState(() {
      final idx = _feedback.indexOf(f);
      if (idx != -1) _feedback[idx] = _copyAsSeen(f);
    });
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FeedbackDetailScreen(feedback: f)));
  }

  _ReportFeedback _copyAsSeen(_ReportFeedback f) => _ReportFeedback(
        reportId: f.reportId,
        meatType: f.meatType,
        status: f.status,
        submittedAt: f.submittedAt,
        respondedAt: f.respondedAt,
        findings: f.findings,
        isNew: false,
      );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.1 : 20.0;

    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
                  child: AppTheme.screenHeader(context, isEn ? 'NMIS Feedback' : 'Feedback ng NMIS'),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GuestGate(
                    title: isEn ? 'Login Required' : 'Kailangan Mag-login',
                    message: isEn
                        ? 'Log in or create an account to view NMIS inspector responses to your reports.'
                        : 'Mag-login o gumawa ng account para makita ang tugon ng NMIS inspector sa iyong mga report.',
                    icon: Icons.forum_outlined,
                    child: _buildFeedbackContent(horizontalPadding, isEn),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackContent(double horizontalPadding, bool isEn) {
    final sorted = [..._feedback]..sort((a, b) {
        final aTime = a.respondedAt ?? a.submittedAt;
        final bTime = b.respondedAt ?? b.submittedAt;
        return bTime.compareTo(aTime);
      });

    return RefreshIndicator(
      color: AppTheme.roleAccent,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEn ? "Inspector responses to the reports you've submitted." : 'Mga tugon ng inspector sa mga report na naisumite mo.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              if (sorted.isEmpty)
                _buildEmptyState(isEn)
              else
                ...sorted.map((f) => Padding(
                      key: _tileKeys[f.reportId],
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FeedbackTile(
                        feedback: f,
                        timeLabel: _formatTimestamp(f.respondedAt ?? f.submittedAt, isEn),
                        isHighlighted: f.reportId == _highlightReportId,
                        isEn: isEn,
                        onTap: () => _openDetail(f),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: AppTheme.outlinedCard(),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, color: AppTheme.textFaint, size: 34),
          const SizedBox(height: 10),
          Text(isEn ? 'No feedback yet' : 'Wala Pang Feedback', style: AppTheme.emptyTitle),
          const SizedBox(height: 4),
          Text(
            isEn ? "Once you submit a report, NMIS's response will show up here" : 'Kapag nagsumite ka ng report, lalabas dito ang tugon ng NMIS',
            textAlign: TextAlign.center,
            style: AppTheme.emptySubtitle,
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final _ReportFeedback feedback;
  final String timeLabel;
  final bool isHighlighted;
  final bool isEn;
  final VoidCallback onTap;

  const _FeedbackTile({
    required this.feedback,
    required this.timeLabel,
    required this.isHighlighted,
    required this.isEn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = feedback.status;
    final hasResponse = feedback.findings != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: FeedbackTheme.feedbackTileDecoration(isNew: feedback.isNew, isHighlighted: isHighlighted),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppTheme.iconBadgeBg(status.color),
                child: Icon(status.icon, color: status.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${feedback.meatType} ', style: FeedbackTheme.reportSubjectText),
                        ),
                        if (feedback.isNew)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 2),
                            decoration: FeedbackTheme.newReplyDot,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: AppTheme.statusPillBg(status.color),
                      child: Text(status.label(isEn).toUpperCase(), style: AppTheme.statusPillText(status.color)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasResponse
                          ? feedback.findings!
                          : (isEn ? 'NMIS is reviewing this report — no findings yet.' : 'Sinusuri pa ito ng NMIS — wala pang findings.'),
                      style: FeedbackTheme.findingsPreviewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasResponse
                          ? (isEn ? 'NMIS responded $timeLabel' : 'Tumugon ang NMIS $timeLabel')
                          : (isEn ? 'Submitted $timeLabel' : 'Naisumite $timeLabel'),
                      style: FeedbackTheme.timestampText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackDetailScreen extends StatelessWidget {
  final _ReportFeedback feedback;
  const _FeedbackDetailScreen({required this.feedback});

  String _formatFullDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final status = feedback.status;

    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          appBar: AppBar(
            backgroundColor: AppTheme.bgColor,
            elevation: 0,
            foregroundColor: AppTheme.textDark,
            title: Text(isEn ? 'Report Feedback' : 'Feedback sa Report', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: FeedbackTheme.detailHeaderCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('${feedback.meatType} ', style: FeedbackTheme.detailReportTitle),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: AppTheme.statusPillBg(status.color),
                                child: Text(status.label(isEn).toUpperCase(), style: AppTheme.statusPillText(status.color)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Report #${feedback.reportId}', style: TextStyle(color: AppTheme.textFaint, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(isEn ? 'SUBMITTED' : 'NAISUMITE', style: FeedbackTheme.detailSectionLabel),
                    const SizedBox(height: 6),
                    Text(_formatFullDate(feedback.submittedAt), style: TextStyle(color: AppTheme.textDark, fontSize: 13)),
                    const SizedBox(height: 20),
                    Text(isEn ? 'NMIS FINDINGS' : 'MGA FINDINGS NG NMIS', style: FeedbackTheme.detailSectionLabel),
                    const SizedBox(height: 8),
                    if (feedback.findings != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: FeedbackTheme.detailFindingsCard,
                        child: Text(feedback.findings!, style: FeedbackTheme.detailFindingsBody),
                      ),
                      const SizedBox(height: 8),
                      if (feedback.respondedAt != null)
                        Text(
                          isEn ? 'Responded ${_formatFullDate(feedback.respondedAt!)}' : 'Tumugon noong ${_formatFullDate(feedback.respondedAt!)}',
                          style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5),
                        ),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: FeedbackTheme.detailFindingsCard,
                        child: Text(
                          isEn
                              ? "An inspector hasn't responded yet. You'll be notified as soon as findings are available."
                              : 'Wala pang sumasagot na inspector. Aabisuhan ka kapag mayroon nang findings.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
