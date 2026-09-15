import 'package:flutter/material.dart';
import 'app_theme.dart';

class ScanTheme {
  static Color roundIconBg(bool isActive) => AppTheme.roundIconBg(isActive);
  static Color roundIconColor(bool isActive) => AppTheme.roundIconColor(isActive);

  static const double cornerBracketSize = AppTheme.cornerBracketSize;
  static const double cornerBracketThickness = AppTheme.cornerBracketThickness;
  static const Color cornerBracketColor = AppTheme.cornerBracketColor;

  static const BoxDecoration shutterOuterDecoration = AppTheme.shutterOuterDecoration;

  static const Color scanControlBg = AppTheme.scanControlBg;

  static const Color scaffoldBackground = Color(0xFF2B2621);

  static const Color viewfinderBackground = Colors.black;
}