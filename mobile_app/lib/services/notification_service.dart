import 'dart:async';

import 'package:flutter/material.dart';
import 'local_cache_service.dart';
import 'supabase_service.dart';
import 'settings_service.dart';

const _kNotificationsCacheKey = 'notifications_cache';

class NotificationServiceException implements Exception {
  final String message;
  const NotificationServiceException(this.message);
  @override
  String toString() => message;
}

enum NotificationKind { scanResult, reportSubmitted, reportReviewed, feedbackResponded, storageTip, vendorApplication, supplierReport, bugReportSubmitted, system }

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  final String? scanId;
  final String? reportId;
  final String? feedbackId;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.scanId,
    this.reportId,
    this.feedbackId,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        scanId: scanId,
        reportId: reportId,
        feedbackId: feedbackId,
      );

  factory AppNotification.fromRow(Map<String, dynamic> row) => AppNotification(
        id: row['notification_id'] as String,
        kind: _kindFromType(row['type'] as String?),
        title: (row['title'] as String?)?.trim() ?? '',
        body: (row['body'] as String?)?.trim() ?? '',
        timestamp: DateTime.parse(row['created_at'] as String).toLocal(),
        isRead: row['is_read'] as bool? ?? false,
        scanId: row['scan_id'] as String?,
        reportId: row['report_id'] as String?,
        feedbackId: row['feedback_id'] as String?,
      );

  static NotificationKind _kindFromType(String? type) {
    for (final kind in NotificationKind.values) {
      if (kind.name == type) return kind;
    }
    return NotificationKind.system;
  }

  /// A local-only cache shape, distinct from [fromRow]'s Supabase-row shape.
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'scanId': scanId,
        'reportId': reportId,
        'feedbackId': feedbackId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        kind: _kindFromType(json['kind'] as String?),
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
        scanId: json['scanId'] as String?,
        reportId: json['reportId'] as String?,
        feedbackId: json['feedbackId'] as String?,
      );

  IconData get icon {
    switch (kind) {
      case NotificationKind.scanResult:
        return Icons.photo_camera_back_outlined;
      case NotificationKind.reportSubmitted:
        return Icons.flag_rounded;
      case NotificationKind.reportReviewed:
        return Icons.forum_rounded;
      case NotificationKind.feedbackResponded:
        return Icons.chat_bubble_outline_rounded;
      case NotificationKind.storageTip:
        return Icons.menu_book_outlined;
      case NotificationKind.vendorApplication:
        return Icons.storefront_rounded;
      case NotificationKind.supplierReport:
        return Icons.local_shipping_rounded;
      case NotificationKind.bugReportSubmitted:
        return Icons.bug_report_rounded;
      case NotificationKind.system:
        return Icons.info_outline_rounded;
    }
  }
}

class NotificationService {
  NotificationService._();

  static final ValueNotifier<List<AppNotification>> items = ValueNotifier([]);

  static Future<void> fetchAll() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      items.value = [];
      return;
    }
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final rows = await SupabaseService.client
          .from('notifications')
          .select('notification_id, title, body, type, created_at, is_read, scan_id, report_id, feedback_id')
          .eq('profile_id', user.id)
          .filter('archived_at', 'is', null)
          .or('expires_at.is.null,expires_at.gt.$nowIso')
          .order('created_at', ascending: false);
      items.value = rows.map((r) => AppNotification.fromRow(r)).toList();
      unawaited(LocalCacheService.writeList(_kNotificationsCacheKey, items.value.map((n) => n.toJson()).toList()));
    } catch (e, st) {
      debugPrint('NotificationService.fetchAll failed: $e\n$st');

      final cached = await LocalCacheService.readList(_kNotificationsCacheKey);
      if (cached != null) {
        items.value = cached.map((j) => AppNotification.fromJson(j)).toList();
        return;
      }
      throw const NotificationServiceException(
        "We couldn't load your notifications. Please check your connection and try again.",
      );
    }
  }

  static Future<void> add({
    required NotificationKind kind,
    required String title,
    required String body,
    String? scanId,
    String? reportId,
    String? feedbackId,
  }) async {

    if (!SettingsService.notificationsEnabled.value) return;

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await SupabaseService.client
          .from('notifications')
          .insert({
            'profile_id': user.id,
            'title': title,
            'body': body,
            'type': kind.name,
            'scan_id': scanId,
            'report_id': reportId,
            'feedback_id': feedbackId,
          })
          .select('notification_id, created_at')
          .single();

      final n = AppNotification(
        id: row['notification_id'] as String,
        kind: kind,
        title: title,
        body: body,
        timestamp: DateTime.parse(row['created_at'] as String).toLocal(),
        scanId: scanId,
        reportId: reportId,
        feedbackId: feedbackId,
      );
      items.value = [n, ...items.value];
    } catch (e, st) {
      debugPrint('NotificationService.add: failed to persist notification: $e\n$st');
    }
  }

  static Future<void> markRead(String id) async {
    final alreadyRead = items.value.any((n) => n.id == id && n.isRead);
    if (alreadyRead) return;

    items.value = [
      for (final n in items.value)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];

    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('notification_id', id);
    } catch (e, st) {
      debugPrint('NotificationService.markRead: failed to persist: $e\n$st');
    }
  }

  static Future<void> remove(String id) async {
    items.value = items.value.where((n) => n.id != id).toList();
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
          .eq('notification_id', id);
    } catch (e, st) {
      debugPrint('NotificationService.remove: failed to archive notification: $e\n$st');
    }
  }

  static int get unreadCount => items.value.where((n) => !n.isRead).length;
}
