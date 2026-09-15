import 'package:flutter/foundation.dart';
import 'package:postgrest/postgrest.dart';
import 'bug_report_service.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class ReportServiceException implements Exception {
  final String message;
  const ReportServiceException(this.message);
  @override
  String toString() => message;
}

class ReportRecord {
  final String id;
  final String scanId;
  final String meatType;
  final DateTime scanTimestamp;
  final String placeOfPurchase;
  final DateTime? purchaseDate;
  final String? purchaseTime;
  final String additionalDetails;
  final DateTime submittedAt;
  final String status;
  final DateTime? reviewedAt;
  final String? purchaseHouseNumber;
  final String? purchaseStreet;
  final String? purchaseBarangay;
  final String? purchaseCity;
  final String? purchaseProvince;
  final String? purchasePostalCode;
  final String? purchaseCountry;
  final double? purchaseLat;
  final double? purchaseLng;

  const ReportRecord({
    required this.id,
    required this.scanId,
    required this.meatType,
    required this.scanTimestamp,
    required this.placeOfPurchase,
    required this.purchaseDate,
    required this.purchaseTime,
    required this.additionalDetails,
    required this.submittedAt,
    required this.status,
    this.reviewedAt,
    this.purchaseHouseNumber,
    this.purchaseStreet,
    this.purchaseBarangay,
    this.purchaseCity,
    this.purchaseProvince,
    this.purchasePostalCode,
    this.purchaseCountry,
    this.purchaseLat,
    this.purchaseLng,
  });

  bool get isReviewed => reviewedAt != null;

  String get scanReference => 'SCN-${scanId.substring(0, 8).toUpperCase()}';

  /// A human-readable address built from the stored components, for display
  /// under the stall name/number (e.g. on the receipt or reports list) —
  /// there's no single raw address column, so this reconstructs one.
  String get formattedAddress {
    final parts = [
      purchaseHouseNumber,
      purchaseStreet,
      purchaseBarangay,
      purchaseCity,
      purchaseProvince,
      purchasePostalCode,
      purchaseCountry,
    ].where((p) => p != null && p.isNotEmpty).cast<String>();
    return parts.join(', ');
  }

  factory ReportRecord.fromRow(Map<String, dynamic> row) {
    final scanRow = row['scans'] as Map<String, dynamic>?;
    final meatTypeRow = scanRow?['meat_types'] as Map<String, dynamic>?;
    final purchaseDateStr = row['purchase_date'] as String?;

    return ReportRecord(
      id: row['report_id'] as String,
      scanId: row['scan_id'] as String,
      meatType: (meatTypeRow?['name'] as String?)?.trim() ?? '',
      scanTimestamp: scanRow?['scanned_at'] != null ? DateTime.parse(scanRow!['scanned_at'] as String).toLocal() : DateTime.now(),
      placeOfPurchase: (row['purchase_location'] as String?)?.trim() ?? '',
      purchaseDate: purchaseDateStr != null ? DateTime.parse(purchaseDateStr) : null,
      purchaseTime: (row['purchase_time'] as String?)?.trim(),
      additionalDetails: (row['additional_details'] as String?)?.trim() ?? '',
      submittedAt: DateTime.parse(row['submitted_at'] as String).toLocal(),
      status: (row['status'] as String?)?.trim() ?? 'pending',
      reviewedAt: row['reviewed_at'] != null ? DateTime.parse(row['reviewed_at'] as String).toLocal() : null,
      purchaseHouseNumber: (row['purchase_house_number'] as String?)?.trim(),
      purchaseStreet: (row['purchase_street'] as String?)?.trim(),
      purchaseBarangay: (row['purchase_barangay'] as String?)?.trim(),
      purchaseCity: (row['purchase_city'] as String?)?.trim(),
      purchaseProvince: (row['purchase_province'] as String?)?.trim(),
      purchasePostalCode: (row['purchase_postal_code'] as String?)?.trim(),
      purchaseCountry: (row['purchase_country'] as String?)?.trim(),
      purchaseLat: (row['purchase_lat'] as num?)?.toDouble(),
      purchaseLng: (row['purchase_lng'] as num?)?.toDouble(),
    );
  }
}

class ReportService {
  ReportService._();

  static final ValueNotifier<List<ReportRecord>> items = ValueNotifier([]);

  static const _columns =
      'report_id, scan_id, purchase_location, purchase_house_number, purchase_street, purchase_barangay, purchase_city, '
      'purchase_province, purchase_postal_code, purchase_country, purchase_date, purchase_time, additional_details, status, '
      'submitted_at, reviewed_at, purchase_lat, purchase_lng, scans(scanned_at, meat_types(name))';

  static Future<void> fetchAll() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      items.value = [];
      return;
    }
    try {
      final rows = await SupabaseService.client
          .from('reports')
          .select(_columns)
          .eq('reporter_id', user.id)
          .order('submitted_at', ascending: false);
      items.value = rows.map((r) => ReportRecord.fromRow(r)).toList();
    } on PostgrestException catch (e, st) {
      debugPrint('ReportService.fetchAll PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load NMIS reports');
      throw const ReportServiceException("We couldn't load your reports. Please try again.");
    } catch (e, st) {
      debugPrint('ReportService.fetchAll failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load NMIS reports');
      throw const ReportServiceException(
        "We couldn't load your reports. Please check your connection and try again.",
      );
    }
  }

  static Future<ReportRecord> submit({
    required String scanId,
    required String placeOfPurchase,
    required DateTime? purchaseDate,
    required String? purchaseTime,
    required String additionalDetails,
    String? purchaseHouseNumber,
    String? purchaseStreet,
    String? purchaseBarangay,
    String? purchaseCity,
    String? purchaseProvince,
    String? purchasePostalCode,
    String? purchaseCountry,
    double? purchaseLat,
    double? purchaseLng,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw const ReportServiceException('You need to be signed in to submit a report.');
    }

    try {
      final row = await SupabaseService.client
          .from('reports')
          .insert({
            'scan_id': scanId,
            'reporter_id': user.id,
            'purchase_location': placeOfPurchase,
            if (purchaseHouseNumber != null && purchaseHouseNumber.isNotEmpty)
              'purchase_house_number': purchaseHouseNumber,
            if (purchaseStreet != null && purchaseStreet.isNotEmpty) 'purchase_street': purchaseStreet,
            if (purchaseBarangay != null && purchaseBarangay.isNotEmpty) 'purchase_barangay': purchaseBarangay,
            if (purchaseCity != null && purchaseCity.isNotEmpty) 'purchase_city': purchaseCity,
            if (purchaseProvince != null && purchaseProvince.isNotEmpty) 'purchase_province': purchaseProvince,
            if (purchasePostalCode != null && purchasePostalCode.isNotEmpty)
              'purchase_postal_code': purchasePostalCode,
            if (purchaseCountry != null && purchaseCountry.isNotEmpty) 'purchase_country': purchaseCountry,
            if (purchaseDate != null)
              'purchase_date':
                  '${purchaseDate.year.toString().padLeft(4, '0')}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}',
            if (purchaseTime != null) 'purchase_time': purchaseTime,
            'additional_details': additionalDetails,
            if (purchaseLat != null) 'purchase_lat': purchaseLat,
            if (purchaseLng != null) 'purchase_lng': purchaseLng,
            'status': 'pending',
          })
          .select(_columns)
          .single();

      final record = ReportRecord.fromRow(row);
      items.value = [record, ...items.value];
      return record;
    } on PostgrestException catch (e, st) {
      debugPrint('ReportService.submit PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot submit NMIS report');
      throw ReportServiceException(
        kDebugMode
            ? "We couldn't submit your report: ${e.message} (code: ${e.code})"
            : "We couldn't submit your report. Please try again.",
      );
    } catch (e, st) {
      debugPrint('ReportService.submit failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot submit NMIS report');
      throw const ReportServiceException(
        "We couldn't submit your report. Please check your connection and try again.",
      );
    }
  }

  static ReportRecord? findByScanId(String scanId) {
    for (final r in items.value) {
      if (r.scanId == scanId) return r;
    }
    return null;
  }

  static ReportRecord? findById(String id) {
    for (final r in items.value) {
      if (r.id == id) return r;
    }
    return null;
  }

  static void markReviewed(String id) {
    final record = items.value.where((r) => r.id == id).firstOrNull;
    if (record == null) return;

    NotificationService.add(
      kind: NotificationKind.reportReviewed,
      title: 'Report reviewed',
      body: 'An NMIS inspector reviewed your ${record.meatType} report.',
      reportId: record.id,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
