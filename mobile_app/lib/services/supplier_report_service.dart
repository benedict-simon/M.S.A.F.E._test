// lib/services/supplier_report_service.dart

import 'package:flutter/foundation.dart';
import 'bug_report_service.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class SupplierReportServiceException implements Exception {
  final String message;
  const SupplierReportServiceException(this.message);
  @override
  String toString() => message;
}

class SupplierReport {
  final String id;
  final String scanId;
  final String meatType;
  final DateTime scanTimestamp;
  final String supplierName;
  final String supplierContact;
  final DateTime? deliveryDate;
  final String additionalDetails;
  final DateTime submittedAt;
  final String status;
  final DateTime? reviewedAt;
  final String? supplierLocation;
  final String? supplierHouseNumber;
  final String? supplierStreet;
  final String? supplierBarangay;
  final String? supplierCity;
  final String? supplierProvince;
  final String? supplierPostalCode;
  final String? supplierCountry;
  final double? supplierLat;
  final double? supplierLng;

  const SupplierReport({
    required this.id,
    required this.scanId,
    required this.meatType,
    required this.scanTimestamp,
    required this.supplierName,
    required this.supplierContact,
    required this.deliveryDate,
    required this.additionalDetails,
    required this.submittedAt,
    required this.status,
    this.reviewedAt,
    this.supplierLocation,
    this.supplierHouseNumber,
    this.supplierStreet,
    this.supplierBarangay,
    this.supplierCity,
    this.supplierProvince,
    this.supplierPostalCode,
    this.supplierCountry,
    this.supplierLat,
    this.supplierLng,
  });

  bool get isReviewed => reviewedAt != null;

  String get scanReference => 'SCN-${scanId.substring(0, 8).toUpperCase()}';

  factory SupplierReport.fromRow(Map<String, dynamic> row) {
    final scanRow = row['scans'] as Map<String, dynamic>?;
    final meatTypeRow = scanRow?['meat_types'] as Map<String, dynamic>?;
    final deliveryDateStr = row['delivery_date'] as String?;

    return SupplierReport(
      id: row['supplier_report_id'] as String,
      scanId: row['scan_id'] as String,
      meatType: (meatTypeRow?['name'] as String?)?.trim() ?? '',
      scanTimestamp: scanRow?['scanned_at'] != null ? DateTime.parse(scanRow!['scanned_at'] as String).toLocal() : DateTime.now(),
      supplierName: (row['supplier_name'] as String?)?.trim() ?? '',
      supplierContact: (row['supplier_contact'] as String?)?.trim() ?? '',
      deliveryDate: deliveryDateStr != null ? DateTime.parse(deliveryDateStr) : null,
      additionalDetails: (row['additional_details'] as String?)?.trim() ?? '',
      submittedAt: DateTime.parse(row['submitted_at'] as String).toLocal(),
      status: (row['status'] as String?)?.trim() ?? 'pending',
      reviewedAt: row['reviewed_at'] != null ? DateTime.parse(row['reviewed_at'] as String).toLocal() : null,
      supplierLocation: (row['supplier_location'] as String?)?.trim(),
      supplierHouseNumber: (row['supplier_house_number'] as String?)?.trim(),
      supplierStreet: (row['supplier_street'] as String?)?.trim(),
      supplierBarangay: (row['supplier_barangay'] as String?)?.trim(),
      supplierCity: (row['supplier_city'] as String?)?.trim(),
      supplierProvince: (row['supplier_province'] as String?)?.trim(),
      supplierPostalCode: (row['supplier_postal_code'] as String?)?.trim(),
      supplierCountry: (row['supplier_country'] as String?)?.trim(),
      supplierLat: (row['supplier_lat'] as num?)?.toDouble(),
      supplierLng: (row['supplier_lng'] as num?)?.toDouble(),
    );
  }
}

class SupplierReportService {
  SupplierReportService._();

  static final ValueNotifier<List<SupplierReport>> items = ValueNotifier([]);

  static const _columns =
      'supplier_report_id, scan_id, supplier_name, supplier_contact, delivery_date, additional_details, status, submitted_at, reviewed_at, '
      'supplier_location, supplier_house_number, supplier_street, supplier_barangay, supplier_city, supplier_province, '
      'supplier_postal_code, supplier_country, supplier_lat, supplier_lng, scans(scanned_at, meat_types(name))';

  static Future<void> fetchAll() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      items.value = [];
      return;
    }
    try {
      final rows = await SupabaseService.client
          .from('supplier_reports')
          .select(_columns)
          .eq('reporter_id', user.id)
          .order('submitted_at', ascending: false);
      items.value = rows.map((r) => SupplierReport.fromRow(r)).toList();
    } catch (e, st) {
      debugPrint('SupplierReportService.fetchAll failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load supplier reports');
    }
  }

  static Future<SupplierReport> submit({
    required String scanId,
    required String supplierName,
    required String supplierContact,
    required DateTime? deliveryDate,
    required String additionalDetails,
    String? supplierLocation,
    String? supplierHouseNumber,
    String? supplierStreet,
    String? supplierBarangay,
    String? supplierCity,
    String? supplierProvince,
    String? supplierPostalCode,
    String? supplierCountry,
    double? supplierLat,
    double? supplierLng,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw const SupplierReportServiceException('You need to be signed in to submit a supplier report.');
    }

    try {
      final row = await SupabaseService.client
          .from('supplier_reports')
          .insert({
            'scan_id': scanId,
            'reporter_id': user.id,
            'supplier_name': supplierName,
            'supplier_contact': supplierContact,
            if (deliveryDate != null)
              'delivery_date':
                  '${deliveryDate.year.toString().padLeft(4, '0')}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}',
            'additional_details': additionalDetails,
            if (supplierLocation != null && supplierLocation.isNotEmpty) 'supplier_location': supplierLocation,
            if (supplierHouseNumber != null && supplierHouseNumber.isNotEmpty)
              'supplier_house_number': supplierHouseNumber,
            if (supplierStreet != null && supplierStreet.isNotEmpty) 'supplier_street': supplierStreet,
            if (supplierBarangay != null && supplierBarangay.isNotEmpty) 'supplier_barangay': supplierBarangay,
            if (supplierCity != null && supplierCity.isNotEmpty) 'supplier_city': supplierCity,
            if (supplierProvince != null && supplierProvince.isNotEmpty) 'supplier_province': supplierProvince,
            if (supplierPostalCode != null && supplierPostalCode.isNotEmpty)
              'supplier_postal_code': supplierPostalCode,
            if (supplierCountry != null && supplierCountry.isNotEmpty) 'supplier_country': supplierCountry,
            if (supplierLat != null) 'supplier_lat': supplierLat,
            if (supplierLng != null) 'supplier_lng': supplierLng,
            'status': 'pending',
          })
          .select(_columns)
          .single();

      final record = SupplierReport.fromRow(row);
      items.value = [record, ...items.value];
      return record;
    } catch (e, st) {
      debugPrint('SupplierReportService.submit failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot submit supplier report');
      throw const SupplierReportServiceException(
        "We couldn't submit your supplier report. Please check your connection and try again.",
      );
    }
  }

  static SupplierReport? findById(String id) {
    for (final r in items.value) {
      if (r.id == id) return r;
    }
    return null;
  }

  static void markReviewed(String id) {
    final record = items.value.where((r) => r.id == id).firstOrNull;
    if (record == null) return;

    NotificationService.add(
      kind: NotificationKind.supplierReport,
      title: 'Supplier report reviewed',
      body: 'An NMIS inspector reviewed your ${record.meatType} supplier report.',
    );
  }

  static void clear() => items.value = [];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
