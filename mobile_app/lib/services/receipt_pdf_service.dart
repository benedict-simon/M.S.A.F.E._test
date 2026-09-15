import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'bug_report_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptPdfService {
  ReceiptPdfService._();

  static const String _logoAsset = 'assets/images/msafe_logo.png';
  static pw.MemoryImage? _logo;

  static const MethodChannel _downloadsChannel = MethodChannel('msafe/downloads');

  static const double _pageWidth = 80 * PdfPageFormat.mm;
  static const double _margin = 14;
  static final PdfPageFormat _pageFormat = PdfPageFormat(
    _pageWidth,
    double.infinity,
    marginAll: _margin,
  );

  static const PdfColor _ink = PdfColor.fromInt(0xFF2B2621); 
  static const PdfColor _inkMuted = PdfColor.fromInt(0xFF7A7168); 
  static const PdfColor _inkFaint = PdfColor.fromInt(0xFFA39A8F);
  static const PdfColor _rule = PdfColor.fromInt(0xFFCCC3B6);
  static const PdfColor _brand = PdfColor.fromInt(0xFF7A1A28);
  static const PdfColor _pending = PdfColor.fromInt(0xFFD9A441); 
  static const PdfColor _reviewed = PdfColor.fromInt(0xFF4C8C4A); 

  static Future<pw.MemoryImage> _loadLogo() async {
    final cached = _logo;
    if (cached != null) return cached;
    final data = await rootBundle.load(_logoAsset);
    final image = pw.MemoryImage(data.buffer.asUint8List());
    _logo = image;
    return image;
  }

  static Future<Uint8List> build({
    required String meatType,
    required String scanReference,
    required DateTime scanTimestamp,
    required String placeOfPurchase,
    String? locationAddress,
    required DateTime? purchaseDate,
    required String? purchaseTime,
    required String additionalDetails,
    required String statusLabel,
    bool isReviewed = false,
    String locationLabel = 'PURCHASED AT',
    String dateLabel = 'PURCHASE DATE',
    bool showTime = true,
  }) async {
    final logo = await _loadLogo();
    final now = DateTime.now();

    meatType = _ascii(meatType);
    scanReference = _ascii(scanReference);
    placeOfPurchase = _ascii(placeOfPurchase);
    locationAddress = locationAddress == null ? null : _ascii(locationAddress);
    additionalDetails = _ascii(additionalDetails);
    statusLabel = _ascii(statusLabel);

    final theme = pw.ThemeData.withFont(
      base: pw.Font.courier(),
      bold: pw.Font.courierBold(),
      italic: pw.Font.courierOblique(),
      boldItalic: pw.Font.courierBoldOblique(),
    );

    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.Page(
        pageFormat: _pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Column(children: [
                pw.Image(logo, width: 46, height: 46),
                pw.SizedBox(height: 8),
                pw.Text(
                  'M.S.A.F.E.',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, letterSpacing: 3, color: _brand),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'MEAT SPOILAGE & FRESHNESS EVALUATOR',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 6.5, letterSpacing: 0.6, color: _inkMuted),
                ),
              ]),
            ),
            pw.SizedBox(height: 12),
            _rule2(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'NMIS REPORT RECEIPT',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.6, color: _ink),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'National Meat Inspection Service',
                style: const pw.TextStyle(fontSize: 7, color: _inkFaint),
              ),
            ),
            pw.SizedBox(height: 10),
            _dottedRule(),
            pw.SizedBox(height: 10),
            _field('SCAN REF', scanReference, bold: true),
            _field('SCAN DATE', _formatDateTime(scanTimestamp)),
            _field('MEAT TYPE', meatType.toUpperCase()),
            _field(
              locationLabel,
              placeOfPurchase.isEmpty ? '-' : placeOfPurchase,
              tight: locationAddress != null && locationAddress.isNotEmpty,
            ),
            if (locationAddress != null && locationAddress.isNotEmpty) _fieldSubline(locationAddress),
            _field(dateLabel, purchaseDate == null ? '-' : _formatDate(purchaseDate)),
            if (showTime) _field('PURCHASE TIME', purchaseTime == null || purchaseTime.isEmpty ? '-' : purchaseTime),
            pw.SizedBox(height: 10),
            _dottedRule(),
            pw.SizedBox(height: 12),
            pw.Center(child: _statusStamp(statusLabel, isReviewed: isReviewed)),
            if (additionalDetails.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _dottedRule(),
              pw.SizedBox(height: 8),
              pw.Text(
                'NOTES',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: _inkMuted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(additionalDetails, style: const pw.TextStyle(fontSize: 8, color: _ink, lineSpacing: 2)),
            ],
            pw.SizedBox(height: 14),
            _rule2(),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.BarcodeWidget(
                data: scanReference,
                barcode: pw.Barcode.code128(),
                width: _pageWidth - (_margin * 2) - 24,
                height: 46,
                drawText: true,
                textStyle: const pw.TextStyle(fontSize: 8, letterSpacing: 1.5, color: _ink),
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 14),
            _rule2(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                '*** CUSTOMER COPY ***',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2, color: _ink),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Issued ${_formatDateTime(now)}',
                style: const pw.TextStyle(fontSize: 6.5, color: _inkFaint),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Keep this receipt for your records.',
                style: const pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: _inkFaint),
              ),
            ),
            pw.SizedBox(height: 14),
            _dottedRule(),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static const double _labelColumnWidth = 62;

  static pw.Widget _field(String label, String value, {bool bold = false, bool tight = false}) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: tight ? 1.5 : 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: _labelColumnWidth,
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: _inkMuted, letterSpacing: 0.4)),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
      );

  /// A muted, indented line under a [_field] value — used for an address
  /// that belongs to the field above it (e.g. a supplier's location under
  /// their name) rather than a standalone labeled row.
  static pw.Widget _fieldSubline(String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          children: [
            pw.SizedBox(width: _labelColumnWidth),
            pw.Expanded(
              child: pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 7, color: _inkMuted, lineSpacing: 1.5),
              ),
            ),
          ],
        ),
      );

  static pw.Widget _statusStamp(String label, {required bool isReviewed}) {
    final color = isReviewed ? _reviewed : _pending;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        label,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: color),
      ),
    );
  }

  static pw.Widget _dottedRule() => pw.Text(
        '.' * 220,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: const pw.TextStyle(fontSize: 8, color: _rule),
      );

  /// A solid double rule used above/below major sections.
  static pw.Widget _rule2() => pw.Column(children: [
        pw.Container(height: 0.9, color: _ink),
        pw.SizedBox(height: 1.6),
        pw.Container(height: 0.9, color: _ink),
      ]);

  static String _ascii(String input) => input
      .replaceAll(RegExp(r'[—–]'), '-')
      .replaceAll('·', '-')
      .replaceAll('•', '*')
      .replaceAll('…', '...')
      .replaceAll(RegExp('[‘’]'), "'")
      .replaceAll(RegExp('[“”]'), '"');

  static String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour12:$minute $period';
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  static String fileName(String scanReference) =>
      'MSAFE_Report_${scanReference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '')}.pdf';

  static Future<void> print({required Uint8List bytes, required String scanReference}) {
    return Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: fileName(scanReference),
    );
  }

  static Future<bool> download({required Uint8List bytes, required String scanReference}) async {
    final name = fileName(scanReference);

    if (await _saveToPublicDownloads(bytes: bytes, fileName: name)) {
      return true;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'M.S.A.F.E. NMIS Report Receipt');
    return false;
  }

  static Future<bool> _saveToPublicDownloads({required Uint8List bytes, required String fileName}) async {
    if (!Platform.isAndroid) return false;
    try {
      final savedUri = await _downloadsChannel.invokeMethod<String>('saveToDownloads', {
        'fileName': fileName,
        'mimeType': 'application/pdf',
        'bytes': bytes,
      });
      return savedUri != null;
    } catch (e, st) {
      debugPrint('ReceiptPdfService: direct Downloads save failed, falling back to share: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot save receipt PDF to Downloads');
      return false;
    }
  }
}
