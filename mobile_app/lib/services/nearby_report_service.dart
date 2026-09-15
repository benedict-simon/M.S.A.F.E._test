import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

class NearbySummary {
  final int complaintCount;
  const NearbySummary({this.complaintCount = 0});
}

/// Calls the FastAPI backend's aggregate-only nearby-report lookup (see
/// backend/app/routers/reports.py) — informational only, so a failure here
/// should never block a report submission.
class NearbyReportService {
  static const _timeout = Duration(seconds: 10);

  Future<NearbySummary> summary(double lat, double lng) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/reports/nearby-summary');
    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'lat': lat, 'lng': lng}))
          .timeout(_timeout);
      if (response.statusCode != 200) return const NearbySummary();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return NearbySummary(complaintCount: body['complaint_count'] as int? ?? 0);
    } catch (_) {
      return const NearbySummary();
    }
  }
}
