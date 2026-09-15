import '../models/meat_type.dart';
import 'bug_report_service.dart';
import 'supabase_service.dart';

class MeatTypeServiceException implements Exception {
  final String message;
  const MeatTypeServiceException(this.message);
  @override
  String toString() => message;
}

class MeatTypeService {
  MeatTypeService._();

  static Future<List<MeatType>> fetchAll() async {
    try {
      final rows = await SupabaseService.client
          .from('meat_types')
          .select('meat_type_id, name')
          .order('meat_type_id', ascending: true);
      return rows.map((r) => MeatType.fromRow(r)).toList();
    } catch (e, st) {
      BugReportService.reportError(e, st, context: 'Cannot load meat types');
      throw const MeatTypeServiceException(
        "We couldn't load meat types. Please check your connection and try again.",
      );
    }
  }
}
