import 'package:flutter/foundation.dart';
import 'bug_report_service.dart';
import 'supabase_service.dart';

class VendorDirectoryServiceException implements Exception {
  final String message;
  const VendorDirectoryServiceException(this.message);
  @override
  String toString() => message;
}

class VendorDirectoryEntry {
  final String id;
  final String businessName;
  final String contactNumber;
  final String? stallNumber;
  final String? stallLocation;
  final String? storeDescription;
  final String? storeHours;
  final List<String> storeCategories;
  final double? stallLat;
  final double? stallLng;
  final String? stallHouseNumber;
  final String? stallStreet;
  final String? stallBarangay;
  final String? stallCity;
  final String? stallProvince;
  final String? stallPostalCode;
  final String? stallCountry;

  const VendorDirectoryEntry({
    required this.id,
    required this.businessName,
    required this.contactNumber,
    this.stallNumber,
    this.stallLocation,
    this.storeDescription,
    this.storeHours,
    this.storeCategories = const [],
    this.stallLat,
    this.stallLng,
    this.stallHouseNumber,
    this.stallStreet,
    this.stallBarangay,
    this.stallCity,
    this.stallProvince,
    this.stallPostalCode,
    this.stallCountry,
  });

  String get formattedAddress {
    final parts = [
      stallHouseNumber,
      stallStreet,
      stallBarangay,
      stallCity,
      stallProvince,
      stallPostalCode,
      stallCountry,
    ].where((p) => p != null && p.isNotEmpty).cast<String>();
    return parts.isNotEmpty ? parts.join(', ') : (stallLocation ?? '');
  }

  factory VendorDirectoryEntry.fromRow(Map<String, dynamic> row) => VendorDirectoryEntry(
        id: row['vendor_application_id'] as String,
        businessName: (row['business_name'] as String?)?.trim() ?? '',
        contactNumber: (row['contact_number'] as String?)?.trim() ?? '',
        stallNumber: (row['stall_number'] as String?)?.trim(),
        stallLocation: (row['stall_location'] as String?)?.trim(),
        storeDescription: (row['store_description'] as String?)?.trim(),
        storeHours: (row['store_hours'] as String?)?.trim(),
        storeCategories: (row['store_categories'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        stallLat: (row['stall_lat'] as num?)?.toDouble(),
        stallLng: (row['stall_lng'] as num?)?.toDouble(),
        stallHouseNumber: (row['stall_house_number'] as String?)?.trim(),
        stallStreet: (row['stall_street'] as String?)?.trim(),
        stallBarangay: (row['stall_barangay'] as String?)?.trim(),
        stallCity: (row['stall_city'] as String?)?.trim(),
        stallProvince: (row['stall_province'] as String?)?.trim(),
        stallPostalCode: (row['stall_postal_code'] as String?)?.trim(),
        stallCountry: (row['stall_country'] as String?)?.trim(),
      );
}

class VendorDirectoryService {
  VendorDirectoryService._();

  static const _columns =
      'vendor_application_id, business_name, contact_number, stall_number, stall_location, stall_house_number, '
      'stall_street, stall_barangay, stall_city, stall_province, stall_postal_code, stall_country, stall_lat, '
      'stall_lng, store_description, store_hours, store_categories';

  static Future<List<VendorDirectoryEntry>> fetchAll() async {
    try {
      final rows = await SupabaseService.client
          .from('vendor_directory')
          .select(_columns)
          .order('business_name', ascending: true);
      return rows.map((r) => VendorDirectoryEntry.fromRow(r)).toList();
    } catch (e, st) {
      debugPrint('VendorDirectoryService.fetchAll failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load vendor directory');
      throw const VendorDirectoryServiceException(
        "We couldn't load the vendor directory. Please check your connection and try again.",
      );
    }
  }
}
