// lib\services\history_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../utils/scan_explanation.dart';
import 'bug_report_service.dart';
import 'local_cache_service.dart';
import 'supabase_service.dart';

const _kHistoryCacheKey = 'history_cache';

class HistoryServiceException implements Exception {
  final String message;
  const HistoryServiceException(this.message);
  @override
  String toString() => message;
}

class HistoryItem {
  final String scanId;
  final String meatType; // 'Pork' | 'Beef' | 'Chicken'
  final bool isFresh;
  final double confidence;
  final DateTime timestamp;
  final bool flagged;
  final List<String> findings;
  final String recommendation;
  final List<String> storageTips;

  // Real per-photo color measurements (see
  // backend/app/services/image_analysis.py) — null for scans saved before
  // this feature existed, or if the column just isn't selected.
  final double? hueDeg;
  final double? saturationPct;
  final double? brightnessPct;
  final double? uniformityPct;

  HistoryItem({
    required this.scanId,
    required this.meatType,
    required this.isFresh,
    required this.confidence,
    required this.timestamp,
    this.flagged = false,
    List<String>? findings,
    String? recommendation,
    List<String>? storageTips,
    this.hueDeg,
    this.saturationPct,
    this.brightnessPct,
    this.uniformityPct,
  })  : findings = findings ??
            buildScanExplanation(
              meatType: meatType,
              isFresh: isFresh,
              confidence: confidence,
              hueDeg: hueDeg,
              saturationPct: saturationPct,
              brightnessPct: brightnessPct,
              uniformityPct: uniformityPct,
            ).findings,
        recommendation = recommendation ??
            buildScanExplanation(meatType: meatType, isFresh: isFresh, confidence: confidence).recommendation,
        storageTips = storageTips ??
            buildScanExplanation(meatType: meatType, isFresh: isFresh, confidence: confidence).storageTips;

  String get scanReference => 'SCN-${scanId.substring(0, 8).toUpperCase()}';

  factory HistoryItem.fromRow(Map<String, dynamic> row) {
    final meatTypeRow = row['meat_types'] as Map<String, dynamic>?;
    return HistoryItem(
      scanId: row['scan_id'] as String,
      meatType: (meatTypeRow?['name'] as String?)?.trim() ?? '',
      isFresh: (row['classification'] as String?)?.toLowerCase().trim() == 'fresh',
      confidence: (row['confidence_score'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.parse(row['scanned_at'] as String).toLocal(),
      hueDeg: (row['hue_deg'] as num?)?.toDouble(),
      saturationPct: (row['saturation_pct'] as num?)?.toDouble(),
      brightnessPct: (row['brightness_pct'] as num?)?.toDouble(),
      uniformityPct: (row['uniformity_pct'] as num?)?.toDouble(),
    );
  }

  /// A flat, local-only shape for the offline cache — distinct from
  /// [fromRow]'s Supabase-row shape, and round-trips [flagged] which the
  /// server fetch never sets.
  Map<String, dynamic> toJson() => {
        'scanId': scanId,
        'meatType': meatType,
        'isFresh': isFresh,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'flagged': flagged,
        'findings': findings,
        'recommendation': recommendation,
        'storageTips': storageTips,
        'hueDeg': hueDeg,
        'saturationPct': saturationPct,
        'brightnessPct': brightnessPct,
        'uniformityPct': uniformityPct,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        scanId: json['scanId'] as String,
        meatType: json['meatType'] as String,
        isFresh: json['isFresh'] as bool,
        confidence: (json['confidence'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        flagged: json['flagged'] as bool? ?? false,
        findings: (json['findings'] as List<dynamic>?)?.cast<String>(),
        recommendation: json['recommendation'] as String?,
        storageTips: (json['storageTips'] as List<dynamic>?)?.cast<String>(),
        hueDeg: (json['hueDeg'] as num?)?.toDouble(),
        saturationPct: (json['saturationPct'] as num?)?.toDouble(),
        brightnessPct: (json['brightnessPct'] as num?)?.toDouble(),
        uniformityPct: (json['uniformityPct'] as num?)?.toDouble(),
      );

  HistoryItem copyWith({bool? flagged}) => HistoryItem(
        scanId: scanId,
        meatType: meatType,
        isFresh: isFresh,
        confidence: confidence,
        timestamp: timestamp,
        flagged: flagged ?? this.flagged,
        findings: findings,
        recommendation: recommendation,
        storageTips: storageTips,
        hueDeg: hueDeg,
        saturationPct: saturationPct,
        brightnessPct: brightnessPct,
        uniformityPct: uniformityPct,
      );
}

class HistoryService {
  HistoryService._();

  static final ValueNotifier<List<HistoryItem>> items = ValueNotifier([]);

  static Future<void> fetchAll() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      items.value = [];
      return;
    }
    try {
      final rows = await SupabaseService.client
          .from('scans')
          .select(
            'scan_id, classification, confidence_score, scanned_at, meat_types(name), '
            'hue_deg, saturation_pct, brightness_pct, uniformity_pct',
          )
          .eq('profile_id', user.id)
          .order('scanned_at', ascending: false);
      items.value = rows.map((r) => HistoryItem.fromRow(r)).toList();
      unawaited(LocalCacheService.writeList(_kHistoryCacheKey, items.value.map((i) => i.toJson()).toList()));
    } catch (e, st) {
      debugPrint('HistoryService.fetchAll failed: $e\n$st');
      BugReportService.reportError(e, st, context: 'Cannot load scan history');

      final cached = await LocalCacheService.readList(_kHistoryCacheKey);
      if (cached != null) {
        items.value = cached.map((j) => HistoryItem.fromJson(j)).toList();
        return;
      }
      throw const HistoryServiceException(
        "We couldn't load your scan history. Please check your connection and try again.",
      );
    }
  }

  /// Adopts a scan the backend already saved to Supabase (see
  /// `backend/app/services/history.py`) into the local list so it shows up
  /// immediately in Recent Scans / History without waiting for the next
  /// [fetchAll]. Does not write to Supabase itself — the backend already did.
  static void addSaved(HistoryItem item) {
    items.value = [item, ...items.value];
  }

  static HistoryItem? findByScanId(String scanId) {
    for (final item in items.value) {
      if (item.scanId == scanId) return item;
    }
    return null;
  }

  static void markFlagged(String scanId) {
    items.value = [
      for (final item in items.value)
        if (item.scanId == scanId) item.copyWith(flagged: true) else item,
    ];
  }
}
