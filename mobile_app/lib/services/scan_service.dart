import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/meat_type.dart';
import 'backend_config.dart';
import 'supabase_service.dart';

class ScanServiceException implements Exception {
  final String message;
  const ScanServiceException(this.message);
  @override
  String toString() => message;
}

/// The backend's meat_gate rejected the photo as not looking like meat
/// (HTTP 422) — an expected, correctly-working outcome of a bad photo, not
/// an app malfunction. Kept distinct from ScanServiceException so callers
/// can skip auto-filing this as a bug report.
class MeatNotRecognizedException extends ScanServiceException {
  const MeatNotRecognizedException(super.message);
}

class ScanResult {
  final bool isFresh;
  final double confidence;

  final String? scanId;

  final double? hueDeg;
  final double? saturationPct;
  final double? brightnessPct;
  final double? uniformityPct;

  const ScanResult({
    required this.isFresh,
    required this.confidence,
    this.scanId,
    this.hueDeg,
    this.saturationPct,
    this.brightnessPct,
    this.uniformityPct,
  });
}

class ScanService {
  static const _timeout = Duration(seconds: 30);

  Future<ScanResult> classify(XFile imageFile, {required MeatType meatType}) async {
    try {
      final uri = Uri.parse('${BackendConfig.baseUrl}/scan');
      final request = http.MultipartRequest('POST', uri)
        ..fields['meat_type'] = meatType.apiValue
        ..fields['meat_type_id'] = meatType.id.toString()
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ));


      final accessToken = SupabaseService.client.auth.currentSession?.accessToken;
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      final http.StreamedResponse streamed;
      try {
        streamed = await request.send().timeout(_timeout);
      } catch (e) {
        throw ScanServiceException('Could not reach the scan server: $e');
      }

      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 422) {
        throw MeatNotRecognizedException(_errorDetail(response.body));
      }
      if (response.statusCode != 200) {
        throw ScanServiceException('Scan failed (${response.statusCode}): ${_errorDetail(response.body)}');
      }

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ScanServiceException('Scan server returned an unexpected response: $e');
      }

      try {
        return ScanResult(
          isFresh: json['is_fresh'] as bool,
          confidence: (json['confidence'] as num).toDouble(),
          scanId: json['scan_id'] as String?,
          hueDeg: (json['hue_deg'] as num?)?.toDouble(),
          saturationPct: (json['saturation_pct'] as num?)?.toDouble(),
          brightnessPct: (json['brightness_pct'] as num?)?.toDouble(),
          uniformityPct: (json['uniformity_pct'] as num?)?.toDouble(),
        );
      } catch (e) {
        throw ScanServiceException('Scan server response was missing expected fields: $e');
      }
    } on ScanServiceException {
      rethrow;
    } catch (e) {

      throw ScanServiceException('Could not prepare the scan: $e');
    }
  }

  static String _errorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) return decoded['detail'].toString();
    } catch (_) {}
    return body;
  }
}
