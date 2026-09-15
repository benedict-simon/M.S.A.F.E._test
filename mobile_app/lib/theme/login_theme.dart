import 'package:flutter/material.dart';
import 'app_theme.dart';

class LoginTheme {

  static const String logoAsset = 'assets/images/msafe_logo.png';

  // ---------- Form field text ----------
  static TextStyle get fieldTextStyle => TextStyle(color: AppTheme.textDark);

  static InputDecorationTheme inputDecorationTheme() {
    OutlineInputBorder ring(Color color, [double width = 1.6]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: color, width: width));
    return InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.bgColor,
      labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: AppTheme.primaryRed, fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: AppTheme.textFaint, fontSize: 13.5),
      errorStyle: const TextStyle(color: AppTheme.spoiledRed, fontSize: 11.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: ring(Colors.transparent, 0),
      enabledBorder: ring(Colors.transparent, 0),
      focusedBorder: ring(AppTheme.primaryRed),
      errorBorder: ring(AppTheme.spoiledRed, 1.2),
      focusedErrorBorder: ring(AppTheme.spoiledRed, 1.6),
    );
  }

  // ---------- Header (logo banner) ----------
  static TextStyle headerTitle({required double fontSize, double letterSpacing = 0}) => TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: letterSpacing,
      );

  static TextStyle headerSubtitle({required double fontSize}) => TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get kickerLabel =>
      TextStyle(color: AppTheme.primaryRed, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.6);

  static TextStyle welcomeTitle({required double fontSize}) =>
      TextStyle(color: AppTheme.textDark, fontSize: fontSize, fontWeight: FontWeight.w800);

  static TextStyle welcomeSubtitle({required double fontSize}) =>
      TextStyle(color: AppTheme.textMuted, fontSize: fontSize, height: 1.35);

  // ---------- "OR CONTINUE WITH" divider ----------
  static TextStyle get dividerLabel => TextStyle(
    color: AppTheme.textFaint,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ---------- "Don't have an account? Create one" prompt ----------
  static TextStyle get promptText => TextStyle(color: AppTheme.textMuted, fontSize: 13);
  static const TextStyle promptLink = TextStyle(color: AppTheme.primaryRed, fontSize: 13, fontWeight: FontWeight.w600);

  // ---------- Guest-mode notice box ----------
  static BoxDecoration noticeBoxBg(Color color, {double opacity = 0.12}) => BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(12),
      );

  static TextStyle noticeText({double fontSize = 12}) =>
      TextStyle(color: AppTheme.textMuted, fontSize: fontSize, height: 1.4);

  static const double cardElevation = 14;
  static Color get cardShadowColor => Colors.black.withOpacity(0.35);

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppTheme.textDark,
    backgroundColor: AppTheme.cardColor,
    side: BorderSide(color: AppTheme.borderColor, width: 1.3),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
  );

  static ButtonStyle compactSecondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppTheme.textDark,
    backgroundColor: AppTheme.cardColor,
    side: BorderSide(color: AppTheme.borderColor, width: 1.1),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
  );

  static Widget iconGlyphBadge({required Widget child, Color? color}) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: (color ?? AppTheme.primaryRed).withOpacity(0.13), shape: BoxShape.circle),
        child: child,
      );

  static const BoxDecoration waveHeaderDecoration = BoxDecoration(gradient: AppTheme.primaryGradient);

  static BoxDecoration logoBadgeDecoration() => BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 6))],
      );

  static Widget softCircle(double size, {double opacity = 0.08}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
      );
}
