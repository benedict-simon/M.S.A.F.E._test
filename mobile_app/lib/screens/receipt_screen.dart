import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/receipt_pdf_service.dart';
import '../services/settings_service.dart';

class ReceiptScreen extends StatelessWidget {
  final String meatType;
  final String scanReference;
  final DateTime scanTimestamp;
  final String placeOfPurchase;
  final String? locationAddress;
  final DateTime? purchaseDate;
  final String? purchaseTime;
  final String additionalDetails;
  final bool isPreview;
  final bool isReviewed;
  final VoidCallback? onConfirm;
  final String locationLabel;
  final String dateLabel;
  final bool showTime;

  const ReceiptScreen({
    super.key,
    required this.meatType,
    required this.scanReference,
    required this.scanTimestamp,
    required this.placeOfPurchase,
    this.locationAddress,
    this.purchaseDate,
    this.purchaseTime,
    this.additionalDetails = '',
    this.isPreview = false,
    this.isReviewed = false,
    this.onConfirm,
    this.locationLabel = 'PURCHASED AT',
    this.dateLabel = 'PURCHASE DATE',
    this.showTime = true,
  });

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour12:$minute $period';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _statusLabel(bool isEn) {
    if (isPreview) return isEn ? 'READY TO SUBMIT' : 'HANDA NANG ISUMITE';
    if (isReviewed) return isEn ? 'REVIEWED' : 'NA-REVIEW NA';
    return isEn ? 'SUBMITTED · PENDING REVIEW' : 'NAISUMITE · HINIHINTAY ANG REVIEW';
  }

  Color _statusColor() => (!isPreview && isReviewed) ? AppTheme.freshGreen : AppTheme.accentGold;

  bool get _hasLocationAddress => locationAddress != null && locationAddress!.isNotEmpty;

  Future<Uint8List> _buildPdfBytes(bool isEn) => ReceiptPdfService.build(
        meatType: meatType,
        scanReference: scanReference,
        scanTimestamp: scanTimestamp,
        placeOfPurchase: placeOfPurchase,
        locationAddress: locationAddress,
        purchaseDate: purchaseDate,
        purchaseTime: purchaseTime,
        additionalDetails: additionalDetails,
        statusLabel: _statusLabel(isEn),
        isReviewed: isReviewed,
        locationLabel: locationLabel,
        dateLabel: dateLabel,
        showTime: showTime,
      );

  Future<void> _handlePrint(BuildContext context, bool isEn) async {
    try {
      final bytes = await _buildPdfBytes(isEn);
      await ReceiptPdfService.print(bytes: bytes, scanReference: scanReference);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEn
                  ? "We couldn't open the print dialog. Please try again."
                  : 'Hindi mabuksan ang print dialog. Pakisubukang muli.')),
        );
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, bool isEn) async {
    try {
      final bytes = await _buildPdfBytes(isEn);
      final savedToDownloads = await ReceiptPdfService.download(bytes: bytes, scanReference: scanReference);
      if (savedToDownloads && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEn
                  ? 'Receipt saved to your Downloads folder.'
                  : 'Na-save ang resibo sa iyong Downloads folder.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEn
                  ? "We couldn't download the receipt. Please try again."
                  : 'Hindi ma-download ang resibo. Pakisubukang muli.')),
        );
      }
    }
  }

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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppTheme.cardColor, shape: BoxShape.circle),
                      child: Icon(Icons.chevron_left_rounded, color: AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPreview ? (isEn ? 'CONFIRM REPORT' : 'KUMPIRMAHIN ANG REPORT') : (isEn ? 'REPORT RECEIPT' : 'RESIBO NG REPORT'),
                    style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 1.4),
                  ),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [_receiptCard(context, isEn)],
                ),
              ),
              _buildActions(context, isEn),
            ]),
          ),
        );
      },
    );
  }

  Widget _receiptCard(BuildContext context, bool isEn) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(children: [
            _zigzagEdge(flip: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 6),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontFamily: 'monospace'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(
                    child: Column(children: [
                      Image.asset('assets/images/msafe_logo.png', width: 44, height: 44),
                      const SizedBox(height: 8),
                      Text('M.S.A.F.E.',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 3, color: AppTheme.roleAccentDark)),
                      const SizedBox(height: 3),
                      Text('MEAT SPOILAGE & FRESHNESS EVALUATOR',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 8.5, letterSpacing: 0.6, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _rule2(),
                  const SizedBox(height: 10),
                  Center(
                    child: Text('NMIS REPORT RECEIPT',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.8, color: AppTheme.textDark)),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: Text('National Meat Inspection Service',
                        style: TextStyle(color: AppTheme.textFaint, fontSize: 9)),
                  ),
                  const SizedBox(height: 14),
                  _dottedRule(),
                  const SizedBox(height: 12),
                  _field('SCAN REF', scanReference, bold: true),
                  _field('SCAN DATE', _formatDateTime(scanTimestamp)),
                  _field('MEAT TYPE', meatType.toUpperCase()),
                  _field(
                    locationLabel,
                    placeOfPurchase.isEmpty ? '-' : placeOfPurchase,
                    tight: _hasLocationAddress,
                  ),
                  if (_hasLocationAddress) _fieldSubline(locationAddress!),
                  _field(dateLabel, purchaseDate == null ? '-' : _formatDate(purchaseDate!)),
                  if (showTime) _field('PURCHASE TIME', purchaseTime == null || purchaseTime!.isEmpty ? '-' : purchaseTime!),
                  const SizedBox(height: 10),
                  _dottedRule(),
                  const SizedBox(height: 16),
                  Center(child: _statusStamp(_statusLabel(isEn), _statusColor())),
                  if (additionalDetails.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _dottedRule(),
                    const SizedBox(height: 10),
                    Text('NOTES',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 5),
                    Text(additionalDetails, style: TextStyle(color: AppTheme.textDark, fontSize: 11, height: 1.5)),
                  ],
                  const SizedBox(height: 18),
                  _rule2(),
                  const SizedBox(height: 16),
                  Center(child: _barcode(scanReference)),
                  const SizedBox(height: 18),
                  _rule2(),
                  const SizedBox(height: 12),
                  if (isPreview)
                    Center(
                      child: Text(
                        isEn ? 'Please review the details above before submitting.' : 'Pakisuri ang mga detalye sa itaas bago isumite.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textFaint, fontSize: 9.5, fontStyle: FontStyle.italic),
                      ),
                    )
                  else ...[
                    Center(
                      child: Text('*** CUSTOMER COPY ***',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.4, color: AppTheme.textDark)),
                    ),
                    const SizedBox(height: 7),
                    Center(
                      child: Text('Issued ${_formatDateTime(DateTime.now())}',
                          style: TextStyle(color: AppTheme.textFaint, fontSize: 8.5)),
                    ),
                    const SizedBox(height: 3),
                    Center(
                      child: Text('Keep this receipt for your records.',
                          style: TextStyle(color: AppTheme.textFaint, fontSize: 8.5, fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _dottedRule(),
                  const SizedBox(height: 4),
                ]),
              ),
            ),
            _zigzagEdge(flip: true),
          ]),
        ),
      ),
    );
  }

  static const double _labelColumnWidth = 92;

  Widget _field(String label, String value, {bool bold = false, bool tight = false}) => Padding(
        padding: EdgeInsets.only(bottom: tight ? 2 : 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: _labelColumnWidth,
            child: Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, letterSpacing: 0.3)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 11.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                )),
          ),
        ]),
      );

  /// A muted, indented line under a [_field] value — used for an address
  /// that belongs to the field above it (e.g. a supplier's location under
  /// their name) rather than a standalone labeled row.
  Widget _fieldSubline(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(children: [
          const SizedBox(width: _labelColumnWidth),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, height: 1.3),
            ),
          ),
        ]),
      );

  Widget _statusStamp(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      );

  Widget _barcode(String data) => Column(children: [
        SizedBox(
          height: 42,
          width: double.infinity,
          child: CustomPaint(painter: _BarcodeStripPainter(data, AppTheme.textDark)),
        ),
        const SizedBox(height: 6),
        Text(data, style: TextStyle(color: AppTheme.textDark, fontSize: 10.5, letterSpacing: 3, fontWeight: FontWeight.w700)),
      ]);

  /// A dotted rule mimicking a receipt tear/section separator.
  Widget _dottedRule() => Text(
        '.' * 300,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(color: AppTheme.borderColor, fontSize: 11, height: 1),
      );

  /// A solid double rule used above/below major sections, like a printed slip.
  Widget _rule2() => Column(children: [
        Container(height: 1, color: AppTheme.textDark),
        const SizedBox(height: 2),
        Container(height: 1, color: AppTheme.textDark),
      ]);

  Widget _zigzagEdge({required bool flip}) => ClipPath(
        clipper: _ZigzagClipper(flip: flip),
        child: Container(height: 12, color: AppTheme.bgColor),
      );

  Widget _buildActions(BuildContext context, bool isEn) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (isPreview) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: Text(isEn ? 'Confirm & Submit' : 'Kumpirmahin at Isumite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.spoiledRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isEn ? 'Cancel' : 'Kanselahin', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              ),
            ),
          ] else ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handlePrint(context, isEn),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(isEn ? 'Print' : 'I-print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleDownload(context, isEn),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(isEn ? 'Download' : 'I-download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEn ? 'Done' : 'Tapos Na'),
              ),
            ),
          ],
        ]),
      );
}

class _ZigzagClipper extends CustomClipper<Path> {
  final bool flip;
  const _ZigzagClipper({required this.flip});

  @override
  Path getClip(Size size) {
    const zigWidth = 12.0;
    final path = Path();
    final count = (size.width / zigWidth).ceil();

    if (!flip) {
      path.moveTo(0, size.height);
      for (int i = 0; i <= count; i++) {
        final x = i * zigWidth;
        path.lineTo(x + zigWidth / 2, 0);
        path.lineTo(x + zigWidth, size.height);
      }
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      for (int i = 0; i <= count; i++) {
        final x = i * zigWidth;
        path.lineTo(x + zigWidth / 2, size.height);
        path.lineTo(x + zigWidth, 0);
      }
      path.lineTo(size.width, 0);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Decorative Code128-style bar pattern, deterministic from [data] so it
/// stays stable across rebuilds. Purely visual — the real, scannable
/// barcode lives on the printed/downloaded PDF via [ReceiptPdfService].
class _BarcodeStripPainter extends CustomPainter {
  final String data;
  final Color color;
  const _BarcodeStripPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final codes = data.codeUnits.isEmpty ? [1] : data.codeUnits;
    double x = 0;
    var i = 0;
    while (x < size.width) {
      final code = codes[i % codes.length];
      final barWidth = 1.0 + (code % 4);
      final isBar = (code ~/ 4).isEven;
      if (isBar) {
        canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
      }
      x += barWidth + 1.5;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodeStripPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
