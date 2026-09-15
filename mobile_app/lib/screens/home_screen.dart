//homescreen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';
import '../services/supplier_report_service.dart';
import '../services/session_service.dart';
import '../services/user_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../widgets/guest_gate.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'scan_result_screen.dart';
import 'reports_screen.dart';
import 'feedback_screen.dart';
import 'summary_screen.dart';
import 'vendor_directory_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const scan = '/scan';
  static const history = '/history';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const education = '/education';
  static const feedback = '/feedback';
  static const summary = '/summary';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;
  int _navIndex = 0;

  int get _newFeedbackCount => 1;

  bool get _isEn => SettingsService.isEnglish;

  String get _dailyTip => _isEn
      ? 'Raw poultry should never sit at room temperature for more than 2 hours — refrigerate promptly after shopping.'
      : 'Ang hilaw na manok ay hindi dapat naiiwan sa room temperature nang higit sa 2 oras — agad itong ilagay sa refrigerator pagkatapos mamalengke.';

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 700));
    } catch (_) {
      if (mounted) {
        _showError(_isEn ? "Couldn't refresh right now. Pull down to try again." : 'Hindi ma-refresh ngayon. I-pull down para subukan muli.');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ])));

  String _greeting() {
    final h = DateTime.now().hour;
    if (_isEn) {
      if (h < 12) return 'What would you like to check today?';
      if (h < 18) return 'Ready for your next freshness check?';
      return 'Wrapping up? Scan before you store it.';
    }
    if (h < 12) return 'Ano ang gusto mong suriin ngayon?';
    if (h < 18) return 'Handa ka na ba sa susunod na freshness check?';
    return 'Nagtatapos na? Mag-scan bago mo itago.';
  }

  String _formatToday() {
    final w = _isEn
        ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        : ['Lunes', 'Martes', 'Miyerkules', 'Huwebes', 'Biyernes', 'Sabado', 'Linggo'];
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final n = DateTime.now();
    return '${w[n.weekday - 1]}, ${m[n.month - 1]} ${n.day}';
  }

  String _formatScanDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final y = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == y.year && dt.month == y.month && dt.day == y.day;
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$h12:$min $period';
    if (isToday) return _isEn ? 'Today, $time' : 'Ngayon, $time';
    if (isYesterday) return _isEn ? 'Yesterday, $time' : 'Kahapon, $time';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[dt.month - 1]} ${dt.day}, $time';
  }

  void _goToScan() => Navigator.pushNamed(context, AppRoutes.scan);

  Future<void> _goToHistory() async {
    setState(() => _navIndex = 1);
    await Navigator.pushNamed(context, AppRoutes.history);
    if (mounted) setState(() => _navIndex = 0);
  }

  void _goToProfile() => Navigator.pushNamed(context, AppRoutes.profile);
  void _goToNotifications() => Navigator.pushNamed(context, AppRoutes.notifications);

  Future<void> _goToEducation({String? focusSection}) async {
    setState(() => _navIndex = 3);
    await Navigator.pushNamed(context, AppRoutes.education, arguments: focusSection);
    if (mounted) setState(() => _navIndex = 0);
  }

  void _goToReport() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
  void _goToFeedback() => Navigator.pushNamed(context, AppRoutes.feedback);
  void _goToSignup() => Navigator.pushNamed(context, '/signup');
  void _goToLogin() => Navigator.pushNamed(context, '/login');

  void _handleProfileTap(bool isGuest) {
    if (isGuest) {
      showLoginRequiredSheet(
        context,
        title: _isEn ? 'Login Required' : 'Kailangan Mag-login',
        message: _isEn
            ? 'Log in or create an account to view and manage your profile.'
            : 'Mag-login o gumawa ng account para makita at mapamahalaan ang iyong profile.',
        icon: Icons.person_outline_rounded,
      );
      return;
    }
    _goToProfile();
  }

  void _goToSummary() => Navigator.pushNamed(context, AppRoutes.summary);
  void _goToVendorDirectory() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorDirectoryScreen()));

  void _goToScanResult(HistoryItem scan) => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ScanResultScreen(
          meatType: scan.meatType,
          isFresh: scan.isFresh,
          confidence: scan.confidence,
          findings: scan.findings,
          recommendation: scan.recommendation,
          storageTips: scan.storageTips,
          scanReference: scan.scanReference,
          scanTimestamp: scan.timestamp,
          readOnly: true,
        ),
      ));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) => ValueListenableBuilder<SessionStatus>(
        valueListenable: SessionService.status,
        builder: (context, session, _) => ValueListenableBuilder<UserProfile?>(
          valueListenable: UserService.profile,
          builder: (context, profile, _) =>
              _buildScaffold(context, session == SessionStatus.guest, profile, SettingsService.isEnglish),
        ),
      ),
    );
  }

  String _greetingDisplayName(UserProfile? profile) {
    if (profile == null) return '';
    return profile.username.isNotEmpty ? profile.username : profile.fullName;
  }

  String _avatarInitials(UserProfile? profile) {
    final name = (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName : (profile?.username ?? '');
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _buildScaffold(BuildContext context, bool isGuest, UserProfile? profile, bool isEn) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final hPad = isTablet ? screenWidth * 0.1 : 20.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppTheme.roleAccent,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _buildTopBanner(context, hPad, isGuest, profile, isEn),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (isGuest) ...[_buildGuestBanner(context, isEn), const SizedBox(height: 16)],
                      AnimatedOpacity(
                        opacity: _isRefreshing ? 0.5 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: _isRefreshing,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildScannerHero(context, isEn),
                            const SizedBox(height: 16),
                            _buildDailyTip(context, isEn),
                            const SizedBox(height: 22),
                            _buildActionGrid(context, isGuest, profile, isEn),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _SectionHeader(
                        title: isEn ? 'Recent Scans' : 'Kamakailang Scan',
                        actionLabel: isEn ? 'See all' : 'Tingnan lahat',
                        onAction: _goToHistory,
                      ),
                      const SizedBox(height: 12),
                      if (isGuest)
                        GuestLoginPrompt(
                          title: isEn ? 'No Saved Scans' : 'Walang Naka-save na Scan',
                          message: isEn ? 'Log in to keep a history of the meat you scan.' : 'Mag-login para mapanatili ang kasaysayan ng iyong mga na-scan na karne.',
                          icon: Icons.history_rounded,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          showActions: false,
                        )
                      else
                        ValueListenableBuilder<List<HistoryItem>>(
                          valueListenable: HistoryService.items,
                          builder: (context, all, _) {
                            final recent = all.take(2).toList();
                            if (recent.isEmpty) return _buildEmptyState(context, isEn);
                            return Column(
                              children: [
                                for (final scan in recent)
                                  Padding(
                                    key: ValueKey(scan.timestamp),
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _RecentScanTile(
                                      scan: scan,
                                      timeLabel: _formatScanDate(scan.timestamp),
                                      isEn: isEn,
                                      onTap: () => _goToScanResult(scan),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _navIndex,
          onTap: (i) {
            switch (i) {
              case 0: setState(() => _navIndex = 0); break;
              case 1: _goToHistory(); break;
              case 2: _goToScan(); break;
              case 3: _goToEducation(); break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context, double hPad, bool isGuest, UserProfile? profile, bool isEn) {
    final greetingName = _greetingDisplayName(profile);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 22),
      decoration: HomeTheme.topBannerDecoration(),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_formatToday(), style: HomeTheme.greetingDateOnBanner),
                const SizedBox(height: 4),
                Text(
                  isGuest
                      ? (isEn ? 'Hi, Guest' : 'Hi, Bisita')
                      : 'Hi, ${greetingName.isNotEmpty ? greetingName : '...'}',
                  style: HomeTheme.greetingNameOnBanner,
                ),
                const SizedBox(height: 3),
                Text(_greeting(), style: HomeTheme.greetingSubtitleOnBanner),
              ]),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<List<AppNotification>>(
              valueListenable: NotificationService.items,
              builder: (context, notifications, _) {
                final hasUnread = !isGuest && notifications.any((n) => !n.isRead);
                return _IconBadgeButton(
                  icon: Icons.notifications_none_rounded,
                  showDot: hasUnread,
                  tooltip: hasUnread
                      ? (isEn ? 'Notifications (unread)' : 'Mga Abiso (hindi pa nabasa)')
                      : (isEn ? 'Notifications' : 'Mga Abiso'),
                  onPressed: _goToNotifications,
                );
              },
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: isGuest ? (isEn ? 'Log in required' : 'Kailangan mag-login') : (isEn ? 'Open profile' : 'Buksan ang profile'),
              child: GestureDetector(
                onTap: () => _handleProfileTap(isGuest),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    isGuest ? 'G' : _avatarInitials(profile),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ]),
          if (!isGuest) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: HomeTheme.statChipBg,
              child: ValueListenableBuilder<List<HistoryItem>>(
                valueListenable: HistoryService.items,
                builder: (context, all, _) => Row(children: [
                  Expanded(child: _StatItem(icon: Icons.photo_camera_back_outlined, value: '${all.length}', label: isEn ? 'Total Scans' : 'Kabuuang Scan')),
                  Container(width: 1, height: HomeTheme.statDividerHeight, color: Colors.white.withOpacity(0.18)),
                  Expanded(
                    child: (profile?.isVendor ?? false)
                        ? ValueListenableBuilder<List<SupplierReport>>(
                            valueListenable: SupplierReportService.items,
                            builder: (context, reports, _) => _StatItem(
                                icon: Icons.local_shipping_outlined,
                                value: '${reports.length}',
                                label: isEn ? 'Supplier Reports' : 'Ulat sa Supplier'),
                          )
                        : ValueListenableBuilder<List<ReportRecord>>(
                            valueListenable: ReportService.items,
                            builder: (context, reports, _) =>
                                _StatItem(icon: Icons.flag_outlined, value: '${reports.length}', label: isEn ? 'NMIS Reports' : 'Ulat sa NMIS'),
                          ),
                  ),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: HomeTheme.noticeBoxBg(AppTheme.accentGold),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: HomeTheme.noticeIconBadge(AppTheme.accentGold),
          child: Icon(Icons.info_outline_rounded, color: AppTheme.accentGold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEn ? "You're browsing as a guest" : 'Bisita ka pa lamang', style: HomeTheme.noticeTitle),
            const SizedBox(height: 3),
            Text(
              isEn
                  ? 'Create an account to save your scan history and submit NMIS reports.'
                  : 'Gumawa ng account para i-save ang iyong kasaysayan ng scan at magsumite ng NMIS reports.',
              style: HomeTheme.noticeText(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: _goToSignup,
                child: Text(isEn ? 'Create an account →' : 'Gumawa ng account →', style: TextStyle(color: AppTheme.primaryRed, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _goToLogin,
                child: Text(isEn ? 'Log in' : 'Mag-login', style: TextStyle(color: AppTheme.primaryRed, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildScannerHero(BuildContext context, bool isEn) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: _goToScan,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.roleGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: HomeTheme.heroShadow,
            image: DecorationImage(
              image: const AssetImage(HomeTheme.heroBackgroundAsset),
              fit: BoxFit.cover,
              onError: (e, s) {},
              colorFilter: ColorFilter.mode(AppTheme.roleAccentDark.withOpacity(0.55), BlendMode.srcATop),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(children: [
              Positioned(top: -40, right: -30, child: Container(width: 170, height: 170, decoration: HomeTheme.heroGlow)),
              Positioned(bottom: -40, left: -30, child: Container(width: 130, height: 130, decoration: HomeTheme.heroGlowSecondary)),
              Positioned(bottom: -18, right: -10, child: Icon(Icons.set_meal_rounded, size: 110, color: Colors.white.withOpacity(0.08))),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: HomeTheme.heroLabelBadgeBg,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('', style: TextStyle(fontSize: 11)),
                      Text(isEn ? 'MEAT FRESHNESS SCANNER' : 'SCANNER NG SARIWA NG KARNE', style: HomeTheme.heroLabel),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn
                        ? "Scan your meat before you cook — know if it's still fresh in seconds."
                        : 'I-scan ang iyong karne bago magluto — alamin kung sariwa pa ito sa ilang segundo.',
                    style: HomeTheme.heroHeadline,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: HomeTheme.heroCtaBg,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.camera_alt_rounded, color: AppTheme.primaryRedDark, size: 18),
                      const SizedBox(width: 8),
                      Text(isEn ? 'Start Scanning' : 'Simulan ang Pag-scan', style: HomeTheme.heroCta),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTip(BuildContext context, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: HomeTheme.noticeBoxBg(AppTheme.freshGreen),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: HomeTheme.noticeIconBadge(AppTheme.freshGreen),
          child: Icon(Icons.lightbulb_rounded, color: AppTheme.freshGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEn ? "Today's Food Safety Tip" : 'Tip sa Food Safety Ngayon', style: HomeTheme.noticeTitle),
            const SizedBox(height: 3),
            Text(_dailyTip, style: HomeTheme.noticeText()),
          ]),
        ),
      ]),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool isGuest, UserProfile? profile, bool isEn) {
    final loginToView = isEn ? 'Login to view' : 'Mag-login para makita';
    final isVendor = profile?.isVendor ?? false;
    return Column(children: [
      Row(children: [
        Expanded(
          child: isGuest
              ? _ActionCard(
                  icon: Icons.photo_camera_back_outlined,
                  iconColor: AppTheme.freshGreen,
                  title: isEn ? 'My Scans' : 'Aking mga Scan',
                  subtitle: loginToView,
                  onTap: _goToHistory,
                )
              : ValueListenableBuilder<List<HistoryItem>>(
                  valueListenable: HistoryService.items,
                  builder: (context, all, _) => _ActionCard(
                    icon: Icons.photo_camera_back_outlined,
                    iconColor: AppTheme.freshGreen,
                    title: isEn ? 'My Scans' : 'Aking mga Scan',
                    subtitle: isEn ? '${all.length} records' : '${all.length} tala',
                    onTap: _goToHistory,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.menu_book_outlined,
            iconColor: AppTheme.accentGold,
            title: isEn ? 'Safety Guide' : 'Gabay sa Kaligtasan',
            subtitle: isEn ? 'Storage tips' : 'Mga tip sa imbakan',
            onTap: () => _goToEducation(focusSection: 'storage'),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppTheme.spoiledRed,
            title: isEn ? 'Spoilage Signs' : 'Palatandaan ng Pagkasira',
            subtitle: isEn ? 'Know the warning signs' : 'Alamin ang mga babala',
            onTap: () => _goToEducation(focusSection: 'spoilage'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isGuest
              ? _ActionCard(
                  icon: Icons.flag_outlined,
                  iconColor: AppTheme.primaryRedDark,
                  title: isEn ? 'My Reports' : 'Aking mga Report',
                  subtitle: loginToView,
                  onTap: _goToReport,
                )
              : isVendor
                  ? ValueListenableBuilder<List<SupplierReport>>(
                      valueListenable: SupplierReportService.items,
                      builder: (context, reports, _) => _ActionCard(
                        icon: Icons.local_shipping_outlined,
                        iconColor: AppTheme.vendorBlue,
                        title: isEn ? 'Supplier Reports' : 'Ulat sa Supplier',
                        subtitle: isEn ? '${reports.length} submitted to NMIS' : '${reports.length} naisumite sa NMIS',
                        onTap: _goToReport,
                      ),
                    )
                  : ValueListenableBuilder<List<ReportRecord>>(
                      valueListenable: ReportService.items,
                      builder: (context, reports, _) => _ActionCard(
                        icon: Icons.flag_outlined,
                        iconColor: AppTheme.primaryRedDark,
                        title: isEn ? 'My Reports' : 'Aking mga Report',
                        subtitle: isEn ? '${reports.length} submitted to NMIS' : '${reports.length} naisumite sa NMIS',
                        onTap: _goToReport,
                      ),
                    ),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.forum_outlined,
            iconColor: AppTheme.roleAccentDark,
            title: isEn ? 'NMIS Feedback' : 'Feedback ng NMIS',
            subtitle: isGuest
                ? loginToView
                : (_newFeedbackCount > 0
                    ? (isEn ? '$_newFeedbackCount new response(s)' : '$_newFeedbackCount bagong tugon')
                    : (isEn ? 'Inspector responses' : 'Mga tugon ng inspector')),
            showDot: !isGuest && _newFeedbackCount > 0,
            onTap: _goToFeedback,
          ),
        ),
        const SizedBox(width: 12),
        // Entry point into the date-range summary dashboard.
        Expanded(
          child: _ActionCard(
            icon: Icons.bar_chart_rounded,
            iconColor: AppTheme.freshGreen,
            title: isEn ? 'Summary Reports' : 'Buod ng Ulat',
            subtitle: isGuest ? loginToView : (isEn ? 'Stats by date range' : 'Stats ayon sa petsa'),
            onTap: _goToSummary,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      _WideActionCard(
        icon: Icons.storefront_outlined,
        iconColor: AppTheme.roleAccent,
        title: isEn ? 'Vendor Directory' : 'Direktoryo ng Vendor',
        subtitle: isEn ? 'Find approved vendors' : 'Maghanap ng approved na vendor',
        onTap: _goToVendorDirectory,
      ),
    ]);
  }

  Widget _buildEmptyState(BuildContext context, bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: HomeTheme.elevatedCard(),
      child: Column(children: [
        Container(width: 64, height: 64, decoration: AppTheme.emptyIconBg(AppTheme.roleAccent), child: Icon(Icons.set_meal_rounded, color: AppTheme.roleAccent, size: 28)),
        const SizedBox(height: 16),
        Text(isEn ? 'No scans yet' : 'Wala Pang Scan', style: AppTheme.emptyTitle.copyWith(fontSize: 15)),
        const SizedBox(height: 5),
        Text(isEn ? 'Your scanned meat will show up here' : 'Ang iyong na-scan na karne ay lalabas dito', style: AppTheme.emptySubtitle.copyWith(fontSize: 12.5)),
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 5),
        Text(value, style: HomeTheme.statNumber),
        const SizedBox(height: 2),
        Text(label, style: HomeTheme.statLabel, textAlign: TextAlign.center),
      ]);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Row(children: [
          Container(width: 5, height: 18, decoration: BoxDecoration(color: AppTheme.roleAccent, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(title, style: AppTheme.sectionTitle.copyWith(fontSize: 18)),
        ]),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.roleAccent)),
          ),
      ]);
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDot;
  const _ActionCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: 154,
            padding: const EdgeInsets.all(16),
            decoration: HomeTheme.elevatedCard(glow: iconColor),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 46, height: 46, decoration: AppTheme.iconBadgeBg(iconColor, radius: 14), child: Icon(icon, color: iconColor, size: 22)),
                if (showDot) ...[const Spacer(), Container(width: 9, height: 9, decoration: BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle))],
              ]),
              const Spacer(),
              Text(title, style: AppTheme.cardTitle.copyWith(fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTheme.cardSubtitle.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      );
}

/// A full-width variant of _ActionCard with the icon beside the text
/// instead of stacked above it — _ActionCard's vertical layout (icon, then
/// a big gap, then text at the bottom) is designed for the half-width
/// paired tiles above and looks like an empty stretch when used alone at
/// full width.
class _WideActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _WideActionCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: HomeTheme.elevatedCard(glow: iconColor),
            child: Row(children: [
              Container(width: 46, height: 46, decoration: AppTheme.iconBadgeBg(iconColor, radius: 14), child: Icon(icon, color: iconColor, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppTheme.cardTitle.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTheme.cardSubtitle.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textFaint),
            ]),
          ),
        ),
      );
}

class _RecentScanTile extends StatelessWidget {
  final HistoryItem scan;
  final String timeLabel;
  final bool isEn;
  final VoidCallback onTap;
  const _RecentScanTile({required this.scan, required this.timeLabel, required this.isEn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFresh = scan.isFresh;
    final statusColor = isFresh ? AppTheme.freshGreen : AppTheme.spoiledRed;
    final statusLabel = isFresh ? (isEn ? 'FRESH' : 'SARIWA') : (isEn ? 'SPOILED' : 'SIRA');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: HomeTheme.elevatedCard(radius: 18, glow: statusColor),
          child: Row(children: [
            Container(width: 5, height: 72, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  AppTheme.meatThumbnail(scan.meatType, size: 48, radius: 16, color: statusColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(scan.meatType, style: AppTheme.tileTitle.copyWith(fontSize: 14.5)),
                      const SizedBox(height: 3),
                      Text(timeLabel, style: AppTheme.tileSubtitle.copyWith(fontSize: 12.5)),
                    ]),
                  ),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6), decoration: AppTheme.statusPillBg(statusColor), child: Text(statusLabel, style: AppTheme.statusPillText(statusColor))),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;
  final String? tooltip;
  const _IconBadgeButton({required this.icon, required this.onPressed, this.showDot = false, this.tooltip});

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Tooltip(message: tooltip ?? '', child: Container(padding: const EdgeInsets.all(10), decoration: HomeTheme.bannerIconBadgeDecoration(), child: Icon(icon, color: Colors.white, size: 20))),
          ),
        ),
        if (showDot)
          Positioned(
            top: 6,
            right: 6,
            child: ExcludeSemantics(
              child: Container(width: 9, height: 9, decoration: BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryRed, width: 1.5))),
            ),
          ),
      ]);
}

