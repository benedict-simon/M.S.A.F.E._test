import 'package:flutter/material.dart';
import 'app_theme.dart';

class HomeTheme {
  HomeTheme._();

  static const String heroBackgroundAsset = 'assets/images/scanner_hero.jpg';

  static BoxDecoration topBannerDecoration({double radius = 32}) => BoxDecoration(
        gradient: AppTheme.roleGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(radius), bottomRight: Radius.circular(radius)),
        boxShadow: bannerShadow,
      );

  static List<BoxShadow> get bannerShadow => [
        BoxShadow(color: AppTheme.roleAccent.withOpacity(0.3), blurRadius: 26, offset: const Offset(0, 12)),
      ];

  static BoxDecoration get bannerBlob => BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.06),
      );

  static BoxDecoration bannerIconBadgeDecoration({bool withDot = false}) => BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.38)),
      );

  static const TextStyle greetingNameOnBanner = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.1,
  );

  static const TextStyle greetingSubtitleOnBanner = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle greetingDateOnBanner = TextStyle(
    color: Colors.white70,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  // ---------- Quick stat chips (inside the banner) ----------
  static BoxDecoration get statChipBg => BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.26)),
      );

  static const TextStyle statNumber = TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800);
  static const TextStyle statLabel = TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600);
  static const double statDividerHeight = 28;

  // ---------- Scanner hero card ----------
  static const TextStyle heroLabel = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );

  static BoxDecoration get heroLabelBadgeBg => BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      );

  static const TextStyle heroHeadline = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.35,
  );

  static TextStyle get heroCta => TextStyle(
    color: AppTheme.roleAccentDark,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static BoxDecoration get heroGlow => BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppTheme.accentGold.withOpacity(0.4), AppTheme.accentGold.withOpacity(0.0)],
        ),
      );

  static BoxDecoration get heroGlowSecondary => BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.16), Colors.white.withOpacity(0.0)],
        ),
      );

  static BoxDecoration get heroCtaBg => BoxDecoration(
        color: AppTheme.accentGold,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: AppTheme.accentGold.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      );

  static BoxDecoration get heroImageScrim => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.roleAccentDark.withOpacity(0.15), AppTheme.roleAccentDark.withOpacity(0.75)],
        ),
      );

  static List<BoxShadow> get heroShadow => [
        BoxShadow(color: AppTheme.roleAccent.withOpacity(0.32), blurRadius: 22, offset: const Offset(0, 10)),
      ];

  static BoxDecoration elevatedCard({double radius = 20, Color? glow}) => BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 5)),
          BoxShadow(color: (glow ?? AppTheme.roleAccent).withOpacity(0.07), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      );

  static const TextStyle tileStatusLabel = TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4);

  static BoxDecoration noticeBoxBg(Color color, {double opacity = 0.12}) => BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(opacity * 2.2)),
      );

  static BoxDecoration noticeIconBadge(Color color) => BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
      );

  static TextStyle noticeText({double fontSize = 12.5}) =>
      TextStyle(color: AppTheme.textMuted, fontSize: fontSize, height: 1.45);

  static TextStyle get noticeTitle => TextStyle(color: AppTheme.textDark, fontSize: 13.5, fontWeight: FontWeight.w800);

  static BoxDecoration get navBarDecoration => BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: navBarShadow,
      );

  static List<BoxShadow> get navBarShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, -4)),
      ];

  static BoxDecoration get scanButtonDecoration => BoxDecoration(
        color: AppTheme.accentGold,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppTheme.accentGold.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      );

  static TextStyle get scanNavLabel => TextStyle(
    color: AppTheme.textMuted,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle navLabel = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500);
  static const TextStyle navLabelActive = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700);
}