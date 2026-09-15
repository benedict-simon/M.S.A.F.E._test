import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/notification_theme.dart';
import '../services/notification_service.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../widgets/guest_gate.dart';
import 'receipt_screen.dart';
import 'scan_result_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _loading = true;
  String? _error;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {

    if (SessionService.isGuest) {
      NotificationService.items.value = [];
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await NotificationService.fetchAll();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is NotificationServiceException
            ? e.message
            : (_isEn ? "We couldn't load your notifications." : 'Hindi namin na-load ang iyong mga abiso.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _markAllRead() {
    for (final n in NotificationService.items.value) {
      if (!n.isRead) NotificationService.markRead(n.id);
    }
  }

  void _handleTap(BuildContext context, AppNotification n) {
    NotificationService.markRead(n.id);

    switch (n.kind) {
      case NotificationKind.scanResult:
        final item = n.scanId == null ? null : HistoryService.findByScanId(n.scanId!);
        if (item == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultScreen(
              meatType: item.meatType,
              isFresh: item.isFresh,
              confidence: item.confidence,
              findings: item.findings,
              recommendation: item.recommendation,
              storageTips: item.storageTips,
              scanReference: item.scanReference,
              scanTimestamp: item.timestamp,
              readOnly: true,
              scanId: item.scanId,
              flagged: item.flagged,
            ),
          ),
        );
        break;
      case NotificationKind.reportSubmitted:
      case NotificationKind.reportReviewed:
        final record = n.reportId == null ? null : ReportService.findById(n.reportId!);
        if (record == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              meatType: record.meatType,
              scanReference: record.scanReference,
              scanTimestamp: record.scanTimestamp,
              placeOfPurchase: record.placeOfPurchase,
              purchaseDate: record.purchaseDate,
              purchaseTime: record.purchaseTime,
              additionalDetails: record.additionalDetails,
              isPreview: false,
              isReviewed: record.isReviewed,
            ),
          ),
        );
        break;
      case NotificationKind.feedbackResponded:
      case NotificationKind.bugReportSubmitted:
      case NotificationKind.system:
        break;
      case NotificationKind.storageTip:
        Navigator.pushNamed(context, '/education', arguments: 'storage');
        break;
      case NotificationKind.vendorApplication:
        Navigator.pushNamed(context, '/profile');
        break;
      case NotificationKind.supplierReport:
        Navigator.pushNamed(context, '/reports');
        break;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return _isEn ? 'Just now' : 'Ngayon lang';
    if (diff.inMinutes < 60) return _isEn ? '${diff.inMinutes}m ago' : '${diff.inMinutes}m ang nakalipas';
    if (diff.inHours < 24) return _isEn ? '${diff.inHours}h ago' : '${diff.inHours}h ang nakalipas';

    final isYesterday = now.subtract(const Duration(days: 1)).day == dt.day && diff.inDays < 2;
    if (isYesterday) return _isEn ? 'Yesterday' : 'Kahapon';

    if (diff.inDays < 7) return _isEn ? '${diff.inDays}d ago' : '${diff.inDays}d ang nakalipas';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Color _colorFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.scanResult:
        return AppTheme.spoiledRed;
      case NotificationKind.reportSubmitted:
        return AppTheme.primaryRed;
      case NotificationKind.reportReviewed:
        return AppTheme.primaryRedDark;
      case NotificationKind.feedbackResponded:
        return AppTheme.freshGreen;
      case NotificationKind.storageTip:
        return AppTheme.accentGold;
      case NotificationKind.vendorApplication:
        return AppTheme.vendorBlue;
      case NotificationKind.supplierReport:
        return AppTheme.vendorBlue;
      case NotificationKind.bugReportSubmitted:
        return AppTheme.spoiledRed;
      case NotificationKind.system:
        return AppTheme.freshGreen;
    }
  }

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
            child: ValueListenableBuilder<SessionStatus>(
              valueListenable: SessionService.status,
              builder: (context, status, _) {
                final isGuest = status == SessionStatus.guest;
                return ValueListenableBuilder<List<AppNotification>>(
                  valueListenable: NotificationService.items,
                  builder: (context, notifications, _) {
                    final hasUnread = !isGuest && notifications.any((n) => !n.isRead);

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
                          child: AppTheme.screenHeader(
                            context,
                            isEn ? 'Notifications' : 'Mga Abiso',
                            trailing:
                                hasUnread ? AppTheme.textActionButton(isEn ? 'Mark all read' : 'Markahan lahat na nabasa', _markAllRead) : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: GuestGate(
                            title: isEn ? 'Login Required' : 'Kailangan Mag-login',
                            message: isEn
                                ? 'Log in or create an account to view your notifications.'
                                : 'Mag-login o gumawa ng account para makita ang iyong mga abiso.',
                            icon: Icons.notifications_none_rounded,
                            child: RefreshIndicator(
                              color: AppTheme.roleAccent,
                              onRefresh: _load,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 560),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_loading && notifications.isEmpty)
                                        _buildLoadingState()
                                      else if (_error != null && notifications.isEmpty)
                                        _buildErrorState(isEn)
                                      else if (notifications.isEmpty)
                                        _buildEmptyState(isEn)
                                      else
                                        ...notifications.map((n) => Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: Dismissible(
                                                key: ValueKey(n.id),
                                                direction: DismissDirection.endToStart,
                                                onDismissed: (_) => NotificationService.remove(n.id),
                                                background: NotificationTheme.dismissBackground(),
                                                child: _NotificationTile(
                                                  icon: n.icon,
                                                  iconColor: _colorFor(n.kind),
                                                  title: n.title,
                                                  body: n.body,
                                                  timeLabel: _formatTimestamp(n.timestamp),
                                                  isRead: n.isRead,
                                                  onTap: () => _handleTap(context, n),
                                                ),
                                              ),
                                            )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator(color: AppTheme.roleAccent)),
    );
  }

  Widget _buildErrorState(bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: AppTheme.outlinedCard(),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppTheme.textFaint, size: 34),
          const SizedBox(height: 10),
          Text(_error ?? (isEn ? "We couldn't load your notifications." : 'Hindi namin na-load ang iyong mga abiso.'),
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13.5)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 16), label: Text(isEn ? 'Try Again' : 'Subukan Muli')),
        ],
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
          Icon(Icons.notifications_none_rounded, color: AppTheme.textFaint, size: 34),
          const SizedBox(height: 10),
          Text(
            isEn ? "You're all caught up" : 'Wala Ka Nang Bagong Abiso',
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            isEn ? 'New scan results and updates will show up here' : 'Ang mga bagong resulta ng scan at update ay lalabas dito',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String timeLabel;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: NotificationTheme.notificationTileDecoration(isRead: isRead, iconColor: iconColor),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppTheme.iconBadgeBg(iconColor),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 13.5,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 2),
                            decoration: NotificationTheme.unreadDot,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(color: AppTheme.textFaint, fontSize: 11, fontWeight: FontWeight.w500),
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
