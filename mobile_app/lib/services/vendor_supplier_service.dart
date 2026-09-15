import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bug_report_service.dart';
import 'supabase_service.dart';
import 'vendor_service.dart';

class VendorSupplierServiceException implements Exception {
  final String message;
  const VendorSupplierServiceException(this.message);
  @override
  String toString() => message;
}

class VendorSupplier {
  final String id;
  final String supplierName;
  final String? supplierContact;
  final String? supplierAddress;
  final String? supplierHouseNumber;
  final String? supplierStreet;
  final String? supplierBarangay;
  final String? supplierCity;
  final String? supplierProvince;
  final String? supplierPostalCode;
  final String? supplierCountry;
  final double? supplierLat;
  final double? supplierLng;
  final String? supplierAccreditationNo;
  final DateTime createdAt;

  const VendorSupplier({
    required this.id,
    required this.supplierName,
    this.supplierContact,
    this.supplierAddress,
    this.supplierHouseNumber,
    this.supplierStreet,
    this.supplierBarangay,
    this.supplierCity,
    this.supplierProvince,
    this.supplierPostalCode,
    this.supplierCountry,
    this.supplierLat,
    this.supplierLng,
    this.supplierAccreditationNo,
    required this.createdAt,
  });

  factory VendorSupplier.fromRow(Map<String, dynamic> row) => VendorSupplier(
        id: row['vendor_supplier_id'] as String,
        supplierName: (row['supplier_name'] as String?)?.trim() ?? '',
        supplierContact: (row['supplier_contact'] as String?)?.trim(),
        supplierAddress: (row['supplier_address'] as String?)?.trim(),
        supplierHouseNumber: (row['supplier_house_number'] as String?)?.trim(),
        supplierStreet: (row['supplier_street'] as String?)?.trim(),
        supplierBarangay: (row['supplier_barangay'] as String?)?.trim(),
        supplierCity: (row['supplier_city'] as String?)?.trim(),
        supplierProvince: (row['supplier_province'] as String?)?.trim(),
        supplierPostalCode: (row['supplier_postal_code'] as String?)?.trim(),
        supplierCountry: (row['supplier_country'] as String?)?.trim(),
        supplierLat: (row['supplier_lat'] as num?)?.toDouble(),
        supplierLng: (row['supplier_lng'] as num?)?.toDouble(),
        supplierAccreditationNo: (row['supplier_accreditation_no'] as String?)?.trim(),
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );
}

class VendorSupplierService {
  VendorSupplierService._();

  static const _columns =
      'vendor_supplier_id, supplier_name, supplier_contact, supplier_address, supplier_house_number, supplier_street, '
      'supplier_barangay, supplier_city, supplier_province, supplier_postal_code, supplier_country, supplier_lat, '
      'supplier_lng, supplier_accreditation_no, created_at';

  static final ValueNotifier<List<VendorSupplier>> suppliers = ValueNotifier([]);

  static Future<void> fetchAll() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      suppliers.value = [];
      return;
    }
    try {
      final rows = await SupabaseService.client
          .from('vendor_suppliers')
          .select(_columns)
          .eq('profile_id', user.id)
          .order('created_at', ascending: true);
      suppliers.value = rows.map((r) => VendorSupplier.fromRow(r)).toList();
    } on PostgrestException catch (e, st) {
      debugPrint('VendorSupplierService.fetchAll PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load your suppliers');
    } catch (e, st) {
      debugPrint('VendorSupplierService.fetchAll failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load your suppliers');
    }
  }

  static Future<VendorSupplier> add({
    required String supplierName,
    String? supplierContact,
    String? supplierAddress,
    String? supplierHouseNumber,
    String? supplierStreet,
    String? supplierBarangay,
    String? supplierCity,
    String? supplierProvince,
    String? supplierPostalCode,
    String? supplierCountry,
    double? supplierLat,
    double? supplierLng,
    String? supplierAccreditationNo,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    final application = VendorService.currentApplication.value;
    if (user == null || application == null) {
      throw const VendorSupplierServiceException('No vendor application found to add a supplier to.');
    }

    try {
      final row = await SupabaseService.client
          .from('vendor_suppliers')
          .insert({
            'vendor_application_id': application.id,
            'profile_id': user.id,
            'supplier_name': supplierName,
            if (supplierContact != null && supplierContact.isNotEmpty) 'supplier_contact': supplierContact,
            if (supplierAddress != null && supplierAddress.isNotEmpty) 'supplier_address': supplierAddress,
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
            if (supplierAccreditationNo != null && supplierAccreditationNo.isNotEmpty)
              'supplier_accreditation_no': supplierAccreditationNo,
          })
          .select(_columns)
          .single();

      final supplier = VendorSupplier.fromRow(row);
      suppliers.value = [...suppliers.value, supplier];
      return supplier;
    } on PostgrestException catch (e, st) {
      debugPrint('VendorSupplierService.add PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot add a supplier');
      throw VendorSupplierServiceException(
        kDebugMode
            ? "We couldn't add that supplier: ${e.message} (code: ${e.code})"
            : "We couldn't add that supplier. Please try again.",
      );
    } catch (e, st) {
      debugPrint('VendorSupplierService.add failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot add a supplier');
      throw const VendorSupplierServiceException(
        "We couldn't add that supplier. Please check your connection and try again.",
      );
    }
  }

  static Future<VendorSupplier> update(
    String id, {
    required String supplierName,
    String? supplierContact,
    String? supplierAddress,
    String? supplierHouseNumber,
    String? supplierStreet,
    String? supplierBarangay,
    String? supplierCity,
    String? supplierProvince,
    String? supplierPostalCode,
    String? supplierCountry,
    double? supplierLat,
    double? supplierLng,
    String? supplierAccreditationNo,
  }) async {
    try {
      final row = await SupabaseService.client
          .from('vendor_suppliers')
          .update({
            'supplier_name': supplierName,
            'supplier_contact': supplierContact,
            'supplier_address': supplierAddress,
            'supplier_house_number': supplierHouseNumber,
            'supplier_street': supplierStreet,
            'supplier_barangay': supplierBarangay,
            'supplier_city': supplierCity,
            'supplier_province': supplierProvince,
            'supplier_postal_code': supplierPostalCode,
            'supplier_country': supplierCountry,
            'supplier_lat': supplierLat,
            'supplier_lng': supplierLng,
            'supplier_accreditation_no': supplierAccreditationNo,
          })
          .eq('vendor_supplier_id', id)
          .select(_columns)
          .single();

      final updated = VendorSupplier.fromRow(row);
      suppliers.value = [
        for (final s in suppliers.value) if (s.id == id) updated else s,
      ];
      return updated;
    } on PostgrestException catch (e, st) {
      debugPrint('VendorSupplierService.update PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot update a supplier');
      throw VendorSupplierServiceException(
        kDebugMode
            ? "We couldn't save that supplier: ${e.message} (code: ${e.code})"
            : "We couldn't save that supplier. Please try again.",
      );
    } catch (e, st) {
      debugPrint('VendorSupplierService.update failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot update a supplier');
      throw const VendorSupplierServiceException(
        "We couldn't save that supplier. Please check your connection and try again.",
      );
    }
  }

  static Future<void> remove(String id) async {
    try {
      await SupabaseService.client.from('vendor_suppliers').delete().eq('vendor_supplier_id', id);
      suppliers.value = suppliers.value.where((s) => s.id != id).toList();
    } on PostgrestException catch (e, st) {
      debugPrint('VendorSupplierService.remove PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot remove a supplier');
      throw VendorSupplierServiceException(
        kDebugMode
            ? "We couldn't remove that supplier: ${e.message} (code: ${e.code})"
            : "We couldn't remove that supplier. Please try again.",
      );
    } catch (e, st) {
      debugPrint('VendorSupplierService.remove failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot remove a supplier');
      throw const VendorSupplierServiceException(
        "We couldn't remove that supplier. Please check your connection and try again.",
      );
    }
  }

  static void clear() => suppliers.value = [];
}
