// lib\screens\scan_result_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meat_type.dart';
import '../theme/app_theme.dart';
import '../theme/scan_result_theme.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';
import '../widgets/guest_gate.dart';
import 'report_screen.dart';
import 'supplier_report_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final String meatType; // 'Pork' | 'Beef' | 'Chicken'

  final MeatType? meatTypeInfo;
  final bool isFresh;
  final double confidence;
  final List<String> findings;
  final String recommendation;
  final List<String> storageTips;
  final String? scanReference;
  final DateTime? scanTimestamp;
  final bool readOnly;
  final String? scanId;
  final bool flagged;
  final VoidCallback? onSaveToHistory;
  final VoidCallback? onFlagReport;
  final VoidCallback? onScanAgain;

  final XFile? imageFile;

  const ScanResultScreen({
    super.key,
    this.meatType = 'Pork',
    this.meatTypeInfo,
    this.isFresh = true,
    this.confidence = 0.91,
    this.findings = const [
      'Normal deep pink-red color, with no discoloration or graying.',
      'Firm, uniform surface texture — no sliminess or dryness detected.',
    ],
    this.recommendation =
        'The meat appears fresh. Store properly and cook within the recommended timeframe.',
    this.storageTips = const [
      'Refrigerate at 0–4°C if cooking within 1–2 days.',
      'Freeze if not planning to use it this week.',
    ],
    this.scanReference,
    this.scanTimestamp,
    this.readOnly = false,
    this.scanId,
    this.flagged = false,
    this.onSaveToHistory,
    this.onFlagReport,
    this.onScanAgain,
    this.imageFile,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {

  Future<HistoryItem?>? _saveFuture;
  bool _showConfidenceInfo = false;

  @override
  void initState() {
    super.initState();
    if (!widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (SessionService.isLoggedIn) {
          _autoSaveToHistory();
        } else {

          _promptGuestSave();
        }
      });
    }
  }

  Future<HistoryItem?> _autoSaveToHistory() {
    if (_saveFuture != null) return _saveFuture!;
    final isEn = SettingsService.isEnglish;

    final future = () async {
      final scanId = widget.scanId;
      if (scanId == null) {
        debugPrint('ScanResultScreen: no scanId from the backend — scan was not saved.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn
                  ? "We couldn't save this scan to your history."
                  : 'Hindi namin na-save ang scan na ito sa iyong history.'),
            ),
          );
        }
        return null;
      }

      final item = HistoryItem(
        scanId: scanId,
        meatType: (widget.meatTypeInfo ?? MeatType(id: 0, name: widget.meatType)).name,
        isFresh: widget.isFresh,
        confidence: widget.confidence,
        timestamp: widget.scanTimestamp ?? DateTime.now(),
        findings: widget.findings,
        recommendation: widget.recommendation,
        storageTips: widget.storageTips,
      );
      HistoryService.addSaved(item);

      NotificationService.add(
        kind: NotificationKind.scanResult,
        title: isEn ? 'Scan complete' : 'Tapos na ang Scan',
        body: isEn
            ? 'Your ${widget.meatType} scan came back ${widget.isFresh ? 'FRESH' : 'SPOILED'}.'
            : 'Ang resulta ng iyong ${widget.meatType} scan ay ${widget.isFresh ? 'SARIWA' : 'SIRA'}.',
        scanId: item.scanId,
      );

      return item;
    }();

    _saveFuture = future;
    return future;
  }

  void _promptGuestSave() {
    if (!mounted) return;
    showSaveScanPrompt(context, meatType: widget.meatType);
  }

  Future<void> _handleFlagReport(BuildContext context) async {
    final isEn = SettingsService.isEnglish;
    if (!SessionService.isLoggedIn) {
      showLoginRequiredSheet(
        context,
        title: isEn ? 'Login Required' : 'Kailangan Mag-login',
        message: isEn ? 'Log in or create an account to report this scan to NMIS.' : 'Mag-login o gumawa ng account para i-report ang scan na ito sa NMIS.',
        icon: Icons.flag_outlined,
      );
      return;
    }

    if (widget.readOnly) {
      final scanId = widget.scanId;
      if (scanId == null) return;
      _openReportScreen(context, scanId: scanId);
      return;
    }

    final item = await (_saveFuture ?? _autoSaveToHistory());
    if (!context.mounted) return;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? "We couldn't prepare this scan for reporting. Please try again." : 'Hindi namin naihanda ang scan na ito para i-report. Pakisubukang muli.')),
      );
      return;
    }
    _openReportScreen(context, scanId: item.scanId);
  }

  bool get _isVendor => UserService.profile.value?.isVendor ?? false;

  void _openReportScreen(BuildContext context, {required String scanId}) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _isVendor
              ? SupplierReportScreen(
                  meatType: widget.meatType,
                  scanId: scanId,
                  scanReference: widget.scanReference ?? 'SCN-00000',
                  scanTimestamp: widget.scanTimestamp ?? DateTime.now(),
                )
              : ReportScreen(
                  meatType: widget.meatType,
                  scanId: scanId,
                  scanReference: widget.scanReference ?? 'SCN-00000',
                  scanTimestamp: widget.scanTimestamp ?? DateTime.now(),
                ),
        ),
      );

  Future<void> _handleShare(BuildContext context) async {
    final isEn = SettingsService.isEnglish;
    final summary = isEn
        ? '${widget.meatType} — ${widget.isFresh ? 'Fresh' : 'Spoiled'} (${(widget.confidence * 100).round()}% confidence) via M.S.A.F.E.'
        : '${widget.meatType} — ${widget.isFresh ? 'Sariwa' : 'Sira'} (${(widget.confidence * 100).round()}% confidence) sa pamamagitan ng M.S.A.F.E.';

    final imageFile = widget.imageFile;
    if (imageFile != null) {
      await Share.shareXFiles([XFile(imageFile.path)], text: summary);
    } else {
      await Share.share(summary);
    }
  }

  bool get _showBottomActions => !widget.readOnly || (!widget.isFresh && !widget.flagged);

  Color get _color => ScanResultTheme.statusColor(widget.isFresh);
  String _label(bool isEn) => widget.isFresh ? (isEn ? 'Fresh' : 'Sariwa') : (isEn ? 'Spoiled' : 'Sira');
  String _subtitle(bool isEn) => widget.isFresh
      ? (isEn ? 'No significant spoilage indicators were detected.' : 'Walang makabuluhang palatandaan ng pagkasira ang natukoy.')
      : (isEn ? 'Multiple spoilage indicators were detected.' : 'Maraming palatandaan ng pagkasira ang natukoy.');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: SafeArea(
            child: Column(children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    _buildHeader(context, isEn),
                    const SizedBox(height: 22),
                    ScanResultTheme.pillBadge(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        ScanResultTheme.outlinedDot(color: _color),
                        const SizedBox(width: 8),
                        Text(
                          widget.meatType.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 34),
                    Center(child: _StatusSeal(color: _color, isFresh: widget.isFresh)),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(_label(isEn),
                          style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 25, letterSpacing: 0.3)),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_subtitle(isEn),
                            textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.4)),
                      ),
                    ),
                    if (!widget.readOnly && !SessionService.isLoggedIn) ...[
                      const SizedBox(height: 16),
                      _buildGuestNotice(isEn),
                    ],
                    const SizedBox(height: 28),
                    _resultCard(isEn),
                    const SizedBox(height: 14),
                    _confidenceCard(isEn),
                    const SizedBox(height: 14),
                    _recommendationCard(isEn),
                    if (widget.isFresh && widget.storageTips.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _storageCard(isEn),
                    ],
                  ],
                ),
              ),
              if (_showBottomActions) _buildBottomActions(context, isEn),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildGuestNotice(bool isEn) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentGold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEn
                      ? "You're browsing as a guest — this result won't be saved to history."
                      : 'Bisita ka pa lamang — hindi mase-save ang resultang ito sa history.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildHeader(BuildContext context, bool isEn) => Row(children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: ScanResultTheme.backButtonDecoration,
            child: Icon(Icons.chevron_left_rounded, color: AppTheme.textDark),
          ),
        ),
        const SizedBox(width: 12),
        Text(isEn ? 'SCAN RESULT' : 'RESULTA NG SCAN',
            style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 1.4)),
        const Spacer(),
        InkWell(
          onTap: () => _handleShare(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: ScanResultTheme.backButtonDecoration,
            child: Icon(Icons.ios_share_rounded, size: 17, color: AppTheme.textDark),
          ),
        ),
      ]);

  Widget _sectionCard({
    required BoxDecoration decoration,
    required IconData icon,
    required String label,
    required Color color,
    required Widget content,
    String? caption,
    double gap = 14,
  }) =>
      Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: decoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 4, color: color.withOpacity(0.9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ScanResultTheme.sectionHeader(icon: icon, label: label, color: color),
              if (caption != null) ...[
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 43),
                  child: Text(caption, style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5)),
                ),
              ],
              SizedBox(height: gap),
              Padding(padding: const EdgeInsets.only(left: 43), child: content),
            ]),
          ),
        ]),
      );

  Widget _bulletList(List<String> items, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            ScanResultTheme.bulletItem(text: item, color: color, dotSize: 6, fontSize: 13.5, topOffset: 6),
        ],
      );

  Widget _resultCard(bool isEn) => _sectionCard(
        decoration: ScanResultTheme.cardShadowOnly(radius: 18),
        icon: Icons.fact_check_outlined,
        label: isEn ? 'Result' : 'Resulta',
        color: _color,
        caption: isEn ? 'Based on visual analysis of the submitted image.' : 'Batay sa visual na pagsusuri ng isinumiteng larawan.',
        content: _bulletList(widget.findings, _color),
      );

  String _confidenceTier(bool isEn) {
    final pct = widget.confidence * 100;
    if (pct >= 85) {
      return isEn
          ? 'High confidence — the model found a clear, consistent match for this result.'
          : 'Mataas na confidence — malinaw at pare-parehong tugma ang nakita ng modelo para sa resultang ito.';
    }
    if (pct >= 60) {
      return isEn
          ? "Moderate confidence — still a reliable read, but if you're unsure, a second photo at a different angle can help confirm it."
          : 'Katamtamang confidence — maaasahan pa rin, ngunit kung hindi ka sigurado, makakatulong ang isa pang larawan sa ibang anggulo para kumpirmahin ito.';
    }
    return isEn
        ? 'Lower confidence — the result is more ambiguous. Consider rescanning with better lighting or a closer, unobstructed view of the surface.'
        : 'Mas mababang confidence — mas malabo ang resulta. Subukang mag-scan ulit nang may mas magandang liwanag o mas malapit na view ng ibabaw.';
  }

  Widget _confidenceCard(bool isEn) => _sectionCard(
        decoration: ScanResultTheme.cardShadowOnly(radius: 18),
        icon: Icons.percent_rounded,
        label: isEn ? 'Confidence' : 'Confidence',
        color: _color,
        gap: 10,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(widget.confidence * 100).round()}%',
              style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showConfidenceInfo = !_showConfidenceInfo),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEn ? 'What does this mean?' : 'Ano ang ibig sabihin nito?',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                  ),
                  Icon(_showConfidenceInfo ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: AppTheme.textMuted),
                ],
              ),
            ),
            if (_showConfidenceInfo) ...[
              const SizedBox(height: 8),
              Text(_confidenceTier(isEn), style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.45)),
            ],
          ],
        ),
      );

  Widget _recommendationCard(bool isEn) => _sectionCard(
        decoration: ScanResultTheme.tintedCardDecoration(_color, radius: 18),
        icon: widget.isFresh ? Icons.verified_outlined : Icons.warning_amber_rounded,
        label: isEn ? 'Recommendation' : 'Rekomendasyon',
        color: _color,
        gap: 12,
        content:
            Text(widget.recommendation, style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 14, height: 1.45)),
      );

  Widget _storageCard(bool isEn) => _sectionCard(
        decoration: ScanResultTheme.cardShadowOnly(radius: 18),
        icon: Icons.inventory_2_outlined,
        label: isEn ? 'Storage Guidelines' : 'Gabay sa Pag-imbak',
        color: AppTheme.accentGold,
        content: _bulletList(widget.storageTips, AppTheme.accentGold),
      );

  Widget _buildBottomActions(BuildContext context, bool isEn) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        decoration: ScanResultTheme.footerDecoration,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScanResultTheme.primaryActionButton(

            label: widget.isFresh
                ? (isEn ? 'Done' : 'Tapos Na')
                : (_isVendor
                    ? (isEn ? 'Flag & Report Supplier' : 'I-flag at I-report ang Supplier')
                    : (isEn ? 'Flag & Report to NMIS' : 'I-flag at I-report sa NMIS')),
            icon: widget.isFresh ? Icons.check_rounded : Icons.flag_rounded,
            color: widget.isFresh ? AppTheme.textDark : AppTheme.spoiledRed,
            onPressed: widget.isFresh
                ? (widget.onSaveToHistory ?? () => Navigator.of(context).popUntil((route) => route.isFirst))
                : (widget.onFlagReport ?? () => _handleFlagReport(context)),
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: 10),
            ScanResultTheme.secondaryActionButton(
              label: isEn ? 'Perform New Scan' : 'Mag-scan Ulit',
              onPressed: widget.onScanAgain ?? () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ]),
      );
}

class _StatusSeal extends StatelessWidget {
  final Color color;
  final bool isFresh;
  const _StatusSeal({required this.color, required this.isFresh});

  @override
  Widget build(BuildContext context) => Container(
        width: 176,
        height: 176,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 36, spreadRadius: 2)],
        ),
        child: Container(
          width: 142,
          height: 142,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.3), width: 1.2)),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(isFresh ? Icons.check_rounded : Icons.close_rounded, size: 38, color: color),
          ),
        ),
      );
}