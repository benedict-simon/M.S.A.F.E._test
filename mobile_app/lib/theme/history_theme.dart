import 'package:flutter/material.dart';
import 'app_theme.dart';

class HistoryTheme {
  HistoryTheme._();

  static TextStyle get groupLabel =>
      TextStyle(color: AppTheme.textFaint, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8);

  static TextStyle get countLabel => TextStyle(color: AppTheme.textFaint, fontSize: 12, fontWeight: FontWeight.w600);

  static BoxDecoration smallBadgeBg(Color color) => BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      );

  static Widget smallBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: smallBadgeBg(color),
        child: Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}