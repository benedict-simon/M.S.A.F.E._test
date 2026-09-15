import 'package:flutter/material.dart';
import 'app_theme.dart';

class FeedbackTheme {
  FeedbackTheme._();

  static BoxDecoration feedbackTileDecoration({
    required bool isNew,
    bool isHighlighted = false,
  }) =>
      BoxDecoration(
        color: isNew ? AppTheme.roleAccent.withOpacity(0.05) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? AppTheme.accentGold : AppTheme.borderColor,
          width: isHighlighted ? 1.6 : 1,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: AppTheme.accentGold.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 4))]
            : null,
      );

  static BoxDecoration get newReplyDot => BoxDecoration(color: AppTheme.roleAccent, shape: BoxShape.circle);

  static BoxDecoration get timelineConnector => BoxDecoration(color: AppTheme.borderColor);

  static TextStyle get reportSubjectText => TextStyle(
    color: AppTheme.textDark,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get findingsPreviewText => TextStyle(
    color: AppTheme.textMuted,
    fontSize: 12,
    height: 1.35,
  );

  static TextStyle get timestampText => TextStyle(
    color: AppTheme.textFaint,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // ---------- Detail screen ----------
  static BoxDecoration get detailHeaderCard => BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 5)),
          BoxShadow(color: AppTheme.roleAccent.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 9)),
        ],
      );

  static TextStyle get detailReportTitle => TextStyle(
    color: AppTheme.textDark,
    fontSize: 17.5,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get detailSectionLabel => TextStyle(
    color: AppTheme.textFaint,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  static TextStyle get detailFindingsBody => TextStyle(
    color: AppTheme.textDark,
    fontSize: 13.5,
    height: 1.5,
  );

  static BoxDecoration get detailFindingsCard => BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      );
}