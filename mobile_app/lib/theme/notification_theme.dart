import 'package:flutter/material.dart';
import 'app_theme.dart';

class NotificationTheme {
  NotificationTheme._();

  static Widget dismissBackground({
    Color color = AppTheme.spoiledRed,
    IconData icon = Icons.delete_outline_rounded,
  }) =>
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: color, size: 22),
      );

  static BoxDecoration notificationTileDecoration({required bool isRead, required Color iconColor}) =>
      BoxDecoration(
        color: isRead ? AppTheme.cardColor : iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isRead ? AppTheme.borderColor : iconColor.withOpacity(0.2)),
      );

  static const BoxDecoration unreadDot = BoxDecoration(color: AppTheme.spoiledRed, shape: BoxShape.circle);
}