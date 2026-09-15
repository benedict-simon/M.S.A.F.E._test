import 'package:flutter/material.dart' show Color;
import 'bug_report_service.dart';
import 'supabase_service.dart';

class EducationNode {
  final String id;
  final String? parentId;
  final String nodeType;
  final String title;
  final String? body;
  final String? lawReference;
  final String? colorHex;
  final List<String> items;
  final int sortOrder;

  final List<EducationNode> children = [];

  EducationNode({
    required this.id,
    required this.parentId,
    required this.nodeType,
    required this.title,
    required this.body,
    required this.lawReference,
    required this.colorHex,
    required this.items,
    required this.sortOrder,
  });

  factory EducationNode.fromRow(Map<String, dynamic> row) {
    final rawItems = row['items'];
    return EducationNode(
      id: row['education_content_id'] as String,
      parentId: row['parent_id'] as String?,
      nodeType: (row['node_type'] as String?) ?? 'lesson',
      title: (row['title'] as String?)?.trim() ?? '',
      body: row['body'] as String?,
      lawReference: row['law_reference'] as String?,
      colorHex: row['color'] as String?,
      items: rawItems is List ? rawItems.map((e) => e.toString()).toList() : const [],
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Color? get color {
    final hex = colorHex?.trim().replaceFirst('#', '');
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final value = int.tryParse(normalized, radix: 16);
    return value == null ? null : Color(value);
  }

  String get plainBody {
    final raw = body;
    if (raw == null || raw.isEmpty) return '';
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class EducationServiceException implements Exception {
  final String message;
  const EducationServiceException(this.message);
  @override
  String toString() => message;
}

class EducationService {
  EducationService._();

  static Future<List<EducationNode>> fetchTree() async {
    try {
      final rows = await SupabaseService.client
          .from('education_content')
          .select('education_content_id, title, body, law_reference, parent_id, node_type, color, items, sort_order')
          .order('sort_order', ascending: true);

      final nodes = rows.map((r) => EducationNode.fromRow(r)).toList();
      final byId = {for (final n in nodes) n.id: n};
      final roots = <EducationNode>[];

      for (final node in nodes) {
        final parent = node.parentId == null ? null : byId[node.parentId];
        if (parent != null) {
          parent.children.add(node);
        } else {
          roots.add(node);
        }
      }

      void sortChildren(EducationNode n) {
        n.children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        for (final c in n.children) {
          sortChildren(c);
        }
      }

      roots.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final r in roots) {
        sortChildren(r);
      }

      return roots;
    } catch (e, st) {
      BugReportService.reportError(e, st, context: 'Cannot load education content');
      throw const EducationServiceException(
        "We couldn't load the education content. Please check your connection and try again.",
      );
    }
  }
}
