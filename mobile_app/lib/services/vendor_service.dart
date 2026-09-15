// lib/services/vendor_service.dart

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bug_report_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'user_service.dart';

class VendorServiceException implements Exception {
  final String message;
  const VendorServiceException(this.message);
  @override
  String toString() => message;
}

enum VendorApplicationStatus { pending, approved, rejected }

class VendorApplication {
  final String id;
  final String businessName;
  final String contactNumber;
  final String? stallNumber;
  final String? stallLocation;
  final String? stallHouseNumber;
  final String? stallStreet;
  final String? stallBarangay;
  final String? stallCity;
  final String? stallProvince;
  final String? stallPostalCode;
  final String? stallCountry;
  final double? stallLat;
  final double? stallLng;
  final VendorApplicationStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? validIdPath;
  final String? vendorPermitPath;
  final String? storeDescription;
  final String? storeHours;
  final List<String> storeCategories;

  const VendorApplication({
    required this.id,
    required this.businessName,
    required this.contactNumber,
    this.stallNumber,
    this.stallLocation,
    this.stallHouseNumber,
    this.stallStreet,
    this.stallBarangay,
    this.stallCity,
    this.stallProvince,
    this.stallPostalCode,
    this.stallCountry,
    this.stallLat,
    this.stallLng,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.validIdPath,
    this.vendorPermitPath,
    this.storeDescription,
    this.storeHours,
    this.storeCategories = const [],
  });

  factory VendorApplication.fromRow(Map<String, dynamic> row) => VendorApplication(
        id: row['vendor_application_id'] as String,
        businessName: (row['business_name'] as String?)?.trim() ?? '',
        contactNumber: (row['contact_number'] as String?)?.trim() ?? '',
        stallNumber: (row['stall_number'] as String?)?.trim(),
        stallLocation: (row['stall_location'] as String?)?.trim(),
        stallHouseNumber: (row['stall_house_number'] as String?)?.trim(),
        stallStreet: (row['stall_street'] as String?)?.trim(),
        stallBarangay: (row['stall_barangay'] as String?)?.trim(),
        stallCity: (row['stall_city'] as String?)?.trim(),
        stallProvince: (row['stall_province'] as String?)?.trim(),
        stallPostalCode: (row['stall_postal_code'] as String?)?.trim(),
        stallCountry: (row['stall_country'] as String?)?.trim(),
        stallLat: (row['stall_lat'] as num?)?.toDouble(),
        stallLng: (row['stall_lng'] as num?)?.toDouble(),
        status: _statusFromString(row['status'] as String?),
        rejectionReason: (row['rejection_reason'] as String?)?.trim(),
        submittedAt: DateTime.parse(row['submitted_at'] as String).toLocal(),
        reviewedAt: row['reviewed_at'] != null ? DateTime.parse(row['reviewed_at'] as String).toLocal() : null,
        validIdPath: row['valid_id_path'] as String?,
        vendorPermitPath: row['vendor_permit_path'] as String?,
        storeDescription: (row['store_description'] as String?)?.trim(),
        storeHours: (row['store_hours'] as String?)?.trim(),
        storeCategories: (row['store_categories'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );

  static VendorApplicationStatus _statusFromString(String? s) {
    switch (s) {
      case 'approved':
        return VendorApplicationStatus.approved;
      case 'rejected':
        return VendorApplicationStatus.rejected;
      default:
        return VendorApplicationStatus.pending;
    }
  }
}

class VendorService {
  VendorService._();

  static const _columns =
      'vendor_application_id, business_name, contact_number, stall_number, stall_location, stall_house_number, stall_street, '
      'stall_barangay, stall_city, stall_province, stall_postal_code, stall_country, stall_lat, stall_lng, status, '
      'rejection_reason, submitted_at, reviewed_at, valid_id_path, vendor_permit_path, store_description, store_hours, '
      'store_categories';

  static final ValueNotifier<VendorApplication?> currentApplication = ValueNotifier(null);

  /// Loads the applicant's most recent vendor application, if any.
  static Future<void> fetchCurrent() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      currentApplication.value = null;
      return;
    }
    try {
      final row = await SupabaseService.client
          .from('vendor_applications')
          .select(_columns)
          .eq('profile_id', user.id)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();
      currentApplication.value = row != null ? VendorApplication.fromRow(row) : null;
    } catch (e, st) {
      debugPrint('VendorService.fetchCurrent failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load vendor application status');
    }
  }

  static Future<String> _uploadDocument(String userId, String label, XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : 'jpg';
    final path = '$userId/${label}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await SupabaseService.client.storage.from('vendor-documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: file.mimeType, upsert: true),
        );

    return path;
  }

  static Future<VendorApplication> submit({
    required String businessName,
    required String contactNumber,
    required XFile validIdFile,
    required XFile vendorPermitFile,
    String? stallLocation,
    String? stallHouseNumber,
    String? stallStreet,
    String? stallBarangay,
    String? stallCity,
    String? stallProvince,
    String? stallPostalCode,
    String? stallCountry,
    double? stallLat,
    double? stallLng,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw const VendorServiceException('You need to be signed in to apply for a vendor account.');
    }

    try {
      final validIdPath = await _uploadDocument(user.id, 'valid_id', validIdFile);
      final vendorPermitPath = await _uploadDocument(user.id, 'vendor_permit', vendorPermitFile);

      final row = await SupabaseService.client
          .from('vendor_applications')
          .insert({
            'profile_id': user.id,
            'business_name': businessName,
            'contact_number': contactNumber,
            if (stallLocation != null && stallLocation.isNotEmpty) 'stall_location': stallLocation,
            if (stallHouseNumber != null && stallHouseNumber.isNotEmpty) 'stall_house_number': stallHouseNumber,
            if (stallStreet != null && stallStreet.isNotEmpty) 'stall_street': stallStreet,
            if (stallBarangay != null && stallBarangay.isNotEmpty) 'stall_barangay': stallBarangay,
            if (stallCity != null && stallCity.isNotEmpty) 'stall_city': stallCity,
            if (stallProvince != null && stallProvince.isNotEmpty) 'stall_province': stallProvince,
            if (stallPostalCode != null && stallPostalCode.isNotEmpty) 'stall_postal_code': stallPostalCode,
            if (stallCountry != null && stallCountry.isNotEmpty) 'stall_country': stallCountry,
            if (stallLat != null) 'stall_lat': stallLat,
            if (stallLng != null) 'stall_lng': stallLng,
            'valid_id_path': validIdPath,
            'vendor_permit_path': vendorPermitPath,
            'status': 'pending',
          })
          .select(_columns)
          .single();

      final application = VendorApplication.fromRow(row);
      currentApplication.value = application;

      await NotificationService.add(
        kind: NotificationKind.vendorApplication,
        title: 'Vendor application submitted',
        body: 'We received your vendor application for "$businessName". '
            "We'll notify you once it's reviewed.",
      );

      return application;
    } on PostgrestException catch (e, st) {
      debugPrint('VendorService.submit PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: 'Cannot submit vendor application');
      throw VendorServiceException(
        kDebugMode
            ? "We couldn't submit your vendor application: ${e.message} (code: ${e.code})"
            : "We couldn't submit your vendor application. Please try again.",
      );
    } catch (e, st) {
      debugPrint('VendorService.submit failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot submit vendor application');
      throw const VendorServiceException(
        "We couldn't submit your vendor application. Please check your connection and try again.",
      );
    }
  }

  /// Lets an approved vendor edit their own store profile after the fact —
  /// unlike [submit], this doesn't reset review status or require
  /// documents, since it's just profile upkeep, not a fresh application.
  /// Only touches store-owned columns (name, contact number, stall
  /// number/location, description, hours, categories), leaving supplier
  /// details untouched.
  static Future<VendorApplication> updateStoreDetails({
    String? businessName,
    String? contactNumber,
    String? stallNumber,
    String? stallLocation,
    String? stallHouseNumber,
    String? stallStreet,
    String? stallBarangay,
    String? stallCity,
    String? stallProvince,
    String? stallPostalCode,
    String? stallCountry,
    double? stallLat,
    double? stallLng,
    String? storeDescription,
    String? storeHours,
    List<String> storeCategories = const [],
  }) async {
    return _updateFields(
      {
        if (businessName != null && businessName.isNotEmpty) 'business_name': businessName,
        if (contactNumber != null && contactNumber.isNotEmpty) 'contact_number': contactNumber,
        'stall_number': stallNumber,
        'stall_location': stallLocation,
        'stall_house_number': stallHouseNumber,
        'stall_street': stallStreet,
        'stall_barangay': stallBarangay,
        'stall_city': stallCity,
        'stall_province': stallProvince,
        'stall_postal_code': stallPostalCode,
        'stall_country': stallCountry,
        'stall_lat': stallLat,
        'stall_lng': stallLng,
        'store_description': storeDescription,
        'store_hours': storeHours,
        'store_categories': storeCategories,
      },
      failureMessage: "We couldn't save your store details.",
      logLabel: 'Cannot save store details',
    );
  }

  static Future<VendorApplication> _updateFields(
    Map<String, dynamic> fields, {
    required String failureMessage,
    required String logLabel,
  }) async {
    final application = currentApplication.value;
    if (application == null) {
      throw const VendorServiceException('No vendor application found to update.');
    }

    try {
      final row = await SupabaseService.client
          .from('vendor_applications')
          .update(fields)
          .eq('vendor_application_id', application.id)
          .select(_columns)
          .single();

      final updated = VendorApplication.fromRow(row);
      currentApplication.value = updated;
      return updated;
    } on PostgrestException catch (e, st) {
      debugPrint('VendorService.$logLabel PostgrestException: ${e.message} (code: ${e.code})\n$st');
      BugReportService.reportError(e, st, context: logLabel);
      throw VendorServiceException(
        kDebugMode ? '$failureMessage ${e.message} (code: ${e.code})' : '$failureMessage Please try again.',
      );
    } catch (e, st) {
      debugPrint('VendorService.$logLabel failed: $e\n$st');
      BugReportService.reportError(e, st, context: logLabel);
      throw VendorServiceException('$failureMessage Please check your connection and try again.');
    }
  }

  static bool get isVendor => UserService.profile.value?.isVendor ?? false;

  static void clear() => currentApplication.value = null;
}
