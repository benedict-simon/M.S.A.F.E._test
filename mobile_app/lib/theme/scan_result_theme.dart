import 'package:flutter/material.dart';
import 'app_theme.dart';

class ScanResultTheme {
  static Widget pillBadge({required Widget child}) => AppTheme.pillBadge(child: child);

  static Widget outlinedDot({double size = 8, Color? color}) =>
      AppTheme.outlinedDot(size: size, color: color ?? AppTheme.textMuted);

  static BoxDecoration get backButtonDecoration => AppTheme.backButtonDecoration;

  static BoxDecoration cardShadowOnly({double radius = 18}) => AppTheme.cardShadowOnly(radius: radius);

  static Widget iconLabelRow({required IconData icon, required String label, Color? color, double fontSize = 15}) =>
      AppTheme.iconLabelRow(icon: icon, label: label, color: color ?? AppTheme.textDark, fontSize: fontSize);

  static Widget sectionHeader({required IconData icon, required String label, Color? color}) {
    final resolvedColor = color ?? AppTheme.textDark;
    return Row(children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: AppTheme.iconBadgeBg(resolvedColor, radius: 12).copyWith(
            boxShadow: [BoxShadow(color: resolvedColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Icon(icon, size: 17, color: resolvedColor),
      ),
      const SizedBox(width: 11),
      Text(label.toUpperCase(),
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.7)),
    ]);
  }

  static Widget bulletItem({
    required String text,
    required Color color,
    double dotSize = 5,
    double fontSize = 12.5,
    double? topOffset,
    EdgeInsets padding = const EdgeInsets.only(bottom: 8),
  }) =>
      AppTheme.bulletItem(text: text, color: color, dotSize: dotSize, fontSize: fontSize, topOffset: topOffset, padding: padding);

  static BoxDecoration tintedCardDecoration(Color color, {double opacity = 0.10, double radius = 18}) =>
      AppTheme.tintedCardDecoration(color, opacity: opacity, radius: radius);

  static Widget primaryActionButton({required String label, required IconData icon, required VoidCallback onPressed, Color? color}) =>
      AppTheme.primaryActionButton(label: label, icon: icon, onPressed: onPressed, color: color ?? AppTheme.textDark);

  static Widget secondaryActionButton({required String label, required VoidCallback onPressed}) =>
      AppTheme.secondaryActionButton(label: label, onPressed: onPressed);

  static BoxDecoration get footerDecoration => BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      );

  static Color statusColor(bool isFresh) => isFresh ? AppTheme.freshGreen : AppTheme.spoiledRed;
}