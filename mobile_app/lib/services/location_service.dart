import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'bug_report_service.dart';

class GeocodedAddress {
  final String displayName;
  final double? lat;
  final double? lng;
  final String? houseNumber;
  final String? street;
  final String? barangay;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? country;

  const GeocodedAddress({
    required this.displayName,
    this.lat,
    this.lng,
    this.houseNumber,
    this.street,
    this.barangay,
    this.city,
    this.province,
    this.postalCode,
    this.country,
  });
}

class LocationService {
  LocationService._();

  static const _userAgentHeader = {'User-Agent': 'MSAFE-mobile-app (address lookup)'};

  static Future<String?> reverseGeocode(double lat, double lng) async {
    final result = await reverseGeocodeDetailed(lat, lng);
    return result?.displayName;
  }

  /// Reverse-geocodes [lat]/[lng] into a full address plus a best-effort
  /// breakdown (house number, street, barangay, city, province, postal
  /// code, country). The breakdown is best-effort only — Nominatim's
  /// component keys are inconsistent for PH addresses (barangay can land
  /// under suburb/village/neighbourhood, and some components may be
  /// missing entirely), so [displayName] remains the source of truth.
  static Future<GeocodedAddress?> reverseGeocodeDetailed(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
    );
    final json = await _fetchJsonObject(url);
    return json == null ? null : _parseAddress(json);
  }

  /// Forward-geocodes a freely typed address (e.g. "Vitales St, Pasay City")
  /// into the same full-address-plus-breakdown shape as
  /// [reverseGeocodeDetailed] — used when the user types the location
  /// instead of pinning it on the map, so typed addresses still get split
  /// into their own barangay/city/province/etc. columns.
  static Future<GeocodedAddress?> forwardGeocodeDetailed(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '1',
      'countrycodes': 'ph',
      'q': trimmed,
    });
    final json = await _fetchJsonArrayFirst(url);
    return json == null ? null : _parseAddress(json);
  }

  /// Returns up to [limit] address suggestions matching the freely typed
  /// [query], for a "type ahead and pick from a dropdown" search box (e.g.
  /// typing "aurora blvd" and choosing among the matching locations) —
  /// same shape as [forwardGeocodeDetailed] but without collapsing to a
  /// single best match.
  static Future<List<GeocodedAddress>> searchSuggestions(String query, {int limit = 5}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '$limit',
      'countrycodes': 'ph',
      'q': trimmed,
    });
    final body = await _fetch(url);
    if (body == null) return const [];
    final list = jsonDecode(body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(_parseAddress)
        .whereType<GeocodedAddress>()
        .toList();
  }

  static Future<Map<String, dynamic>?> _fetchJsonObject(Uri url) async {
    final body = await _fetch(url);
    return body == null ? null : jsonDecode(body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> _fetchJsonArrayFirst(Uri url) async {
    final body = await _fetch(url);
    if (body == null) return null;
    final list = jsonDecode(body) as List<dynamic>;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  static Future<String?> _fetch(Uri url) async {
    try {
      final response = await http.get(url, headers: _userAgentHeader).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('LocationService: geocode error ${response.statusCode} - ${response.body}');
        return null;
      }
      return response.body;
    } catch (e, st) {
      debugPrint('LocationService: geocode request failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot look up location');
      return null;
    }
  }

  static GeocodedAddress? _parseAddress(Map<String, dynamic> data) {
    final displayName = (data['display_name'] as String?)?.trim();
    if (displayName == null || displayName.isEmpty) return null;

    final address = (data['address'] as Map<String, dynamic>?) ?? const {};
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    return GeocodedAddress(
      displayName: displayName,
      lat: double.tryParse('${data['lat'] ?? ''}'),
      lng: double.tryParse('${data['lon'] ?? ''}'),
      houseNumber: pick(['house_number']),
      street: pick(['road', 'pedestrian', 'footway']),
      barangay: pick(['suburb', 'village', 'neighbourhood', 'quarter']),
      city: pick(['city', 'municipality', 'town']),
      province: pick(['state', 'county', 'region']),
      postalCode: pick(['postcode']),
      country: pick(['country']),
    );
  }
}
