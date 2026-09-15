import 'package:flutter/material.dart';
import 'app_theme.dart';

class ReportTheme {
  static Widget fieldLabel(String text) => AppTheme.fieldLabel(text);

  static Widget readOnlyField({required String value, required IconData icon}) =>
      AppTheme.readOnlyField(value: value, icon: icon);

  static BoxDecoration get inputFieldDecoration => AppTheme.inputFieldDecoration;

  static Widget disclaimerBanner(String text) => AppTheme.tintedInfoBox(
        icon: Icons.info_outline_rounded,
        color: AppTheme.spoiledRed,
        opacity: 0.08,
        contentColor: AppTheme.spoiledRed.withOpacity(0.85),
        fontSize: 13,
        text: text,
      );
}