import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFA02334);
  static const Color primaryRedDark = Color(0xFF7A1A28);
  static const Color accentGold = Color(0xFFD9A441);
  static const Color freshGreen = Color(0xFF4C8C4A);
  static const Color spoiledRed = Color(0xFFC0392B);

  static const Color vendorBlue = Color(0xFF1F6F8B);
  static const Color vendorBlueDark = Color(0xFF14505F);

  static bool get _isDark => SettingsService.darkMode.value;
  static bool get _isVendorAccount => UserService.profile.value?.isVendor ?? false;

  static Color get roleAccent => _isVendorAccount ? vendorBlue : primaryRed;
  static Color get roleAccentDark => _isVendorAccount ? vendorBlueDark : primaryRedDark;

  static LinearGradient get roleGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [roleAccent, roleAccentDark],
      );

  static Color get bgColor => _isDark ? const Color(0xFF1A1714) : const Color(0xFFFAF7F2);
  static Color get cardColor => _isDark ? const Color(0xFF242019) : const Color(0xFFFFFFFF);
  static Color get borderColor => _isDark ? const Color(0xFF3A3329) : const Color(0xFFE5DED4);

  static Color get textDark => _isDark ? const Color(0xFFF2EDE6) : const Color(0xFF2B2621);
  static Color get textMuted => _isDark ? const Color(0xFFB8AFA3) : const Color(0xFF7A7168);
  static Color get textFaint => _isDark ? const Color(0xFF8A8074) : const Color(0xFFA39A8F);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, primaryRedDark],
  );

  static BoxDecoration _panel({
    Color? color,
    double radius = 16,
    bool bordered = true,
    List<BoxShadow>? shadow,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      BoxDecoration(
        color: color ?? cardColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
        border: bordered ? Border.all(color: borderColor) : null,
        boxShadow: shadow,
      );

  static BoxDecoration _tint(Color color, {double opacity = 0.12, double radius = 12, BoxShape shape = BoxShape.rectangle}) =>
      BoxDecoration(
        color: color.withOpacity(opacity),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
      );

  static List<BoxShadow> _shadow(Color color, {double opacity = 0.06, double blur = 24, Offset offset = const Offset(0, 8)}) =>
      [BoxShadow(color: color.withOpacity(opacity), blurRadius: blur, offset: offset)];

  static InputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color, width: width));

  // ---------- Shared text styles (dashboard / cards / tiles) ----------
  static TextStyle get sectionTitle => TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800);
  static TextStyle get cardTitle => TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w700);
  static TextStyle get cardSubtitle => TextStyle(color: textMuted, fontSize: 12.5);
  static TextStyle get tileTitle => TextStyle(color: textDark, fontSize: 14.5, fontWeight: FontWeight.w700);
  static TextStyle get tileSubtitle => TextStyle(color: textMuted, fontSize: 12.5);
  static TextStyle get emptyTitle => TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14.5);
  static TextStyle get emptySubtitle => TextStyle(color: textMuted, fontSize: 12.5);

  static TextStyle statusPillText(Color color) =>
      TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3);

  // ---------- Shared decorations ----------
  static BoxDecoration outlinedCard({double radius = 20}) => _panel(radius: radius);

  static BoxDecoration iconBadgeBg(Color color, {double radius = 14}) => _tint(color, radius: radius);

  static BoxDecoration statusPillBg(Color color) => _tint(color, radius: 20);

  /// A soft neutral shadow plus a faint colored glow, so cards feel warm
  /// rather than flat — same recipe as the home screen's card style.
  static List<BoxShadow> get cardShadow => [
        ..._shadow(Colors.black, opacity: 0.05, blur: 20),
        BoxShadow(color: roleAccent.withOpacity(0.06), blurRadius: 22, offset: const Offset(0, 9)),
      ];

  static IconData _meatIconData(String meatType) {
    switch (meatType.toLowerCase().trim()) {
      case 'chicken':
      case 'poultry':
        return Icons.egg_outlined;
      case 'pork':
        return Icons.kebab_dining;
      case 'beef':
        return Icons.lunch_dining;
      case 'fish':
      case 'seafood':
        return Icons.set_meal;
      default:
        return Icons.restaurant_outlined;
    }
  }

  static Widget meatIconImage(String meatType, {double size = 24, Color? color}) {
    return Icon(_meatIconData(meatType), size: size, color: color ?? textDark);
  }

  static String? _meatImageAsset(String meatType) {
    switch (meatType.toLowerCase().trim()) {
      case 'chicken':
      case 'poultry':
        return 'assets/images/chicken_icon.png';
      case 'pork':
        return 'assets/images/pork_icon.png';
      case 'beef':
        return 'assets/images/beef_icon.png';
      default:
        return null;
    }
  }

  static Widget meatThumbnail(String meatType, {double size = 44, double radius = 14, Color? color}) {
    final resolvedColor = color ?? textDark;
    final asset = _meatImageAsset(meatType);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: asset != null
          ? Image.asset(asset, width: size, height: size, fit: BoxFit.cover)
          : Container(
              width: size,
              height: size,
              decoration: iconBadgeBg(resolvedColor, radius: radius),
              child: meatIconImage(meatType, size: size * 0.45, color: resolvedColor),
            ),
    );
  }

  static BoxDecoration get backButtonDecoration => _panel(shape: BoxShape.circle);

  static Widget screenHeader(BuildContext context, String title, {Widget? trailing, double titleFontSize = 17}) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: backButtonDecoration,
              child: Icon(Icons.chevron_left_rounded, color: textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: titleFontSize),
            ),
          ),
          if (trailing != null) trailing,
        ],
      );

  static Widget textActionButton(String label, VoidCallback onPressed) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      );

  // ---------- Shared empty state ----------
  static BoxDecoration emptyIconBg(Color color) => _tint(color, opacity: 0.08, shape: BoxShape.circle);

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final resolvedColor = color ?? roleAccent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: emptyIconBg(resolvedColor),
              child: Icon(icon, color: resolvedColor, size: 42),
            ),
            const SizedBox(height: 20),
            Text(title, style: emptyTitle.copyWith(fontSize: 16.5)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: emptySubtitle.copyWith(fontSize: 13.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Filter chip ----------
  static Widget filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: roleAccent,
        backgroundColor: cardColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: BorderSide(color: selected ? roleAccent : borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );

  // ---------- List card (thumbnail-row style) ----------
  static BoxDecoration get cardWithShadow => cardWithShadowRadius(18);

  static BoxDecoration cardWithShadowRadius(double radius) => _panel(radius: radius, shadow: cardShadow);

  // ---------- Pill toggle (language switch, small segmented control) ----------
  static BoxDecoration get pillContainerDecoration => _panel(radius: 20);

  static Widget pillContainer(List<Widget> chips) => Container(
        padding: const EdgeInsets.all(3),
        decoration: pillContainerDecoration,
        child: Row(mainAxisSize: MainAxisSize.min, children: chips),
      );

  static Widget pillToggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? roleAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ),
      );

  // ---------- Bulleted list row (comparison lists, tip lists) ----------
  static Widget bulletItem({
    required String text,
    required Color color,
    double dotSize = 5,
    double fontSize = 12.5,
    double? topOffset,
    EdgeInsets padding = const EdgeInsets.only(bottom: 8),
  }) =>
      Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topOffset ?? 5),
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            SizedBox(width: dotSize > 5 ? 10 : 8),
            Expanded(
              child: Text(text, style: TextStyle(color: textDark, fontSize: fontSize, height: 1.4)),
            ),
          ],
        ),
      );

  // ---------- Tinted info box (intro banners, disclaimers, alerts) ----------
  static Widget tintedInfoBox({
    required IconData icon,
    required String text,
    Color color = primaryRed,
    double opacity = 0.06,
    double iconSize = 18,
    double fontSize = 13.5,
    bool italic = false,
    Color? contentColor,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    // contentColor overrides both icon and text tint; otherwise falls back to the original look.
    final resolvedIconColor = contentColor ?? (color == primaryRed ? primaryRed : textMuted);
    final resolvedTextColor = contentColor ?? (italic ? textMuted : textDark);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: _tint(color, opacity: opacity),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: resolvedIconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: resolvedTextColor,
                fontSize: fontSize,
                height: 1.4,
                fontWeight: italic ? FontWeight.normal : FontWeight.w500,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Scan/camera screen ----------
  static const Color scanControlBg = Color(0x33FFFFFF); // translucent white

  static Color roundIconBg(bool isActive) => isActive ? accentGold.withOpacity(0.9) : scanControlBg;
  static Color roundIconColor(bool isActive) => isActive ? primaryRedDark : Colors.white;

  static const double cornerBracketSize = 28;
  static const double cornerBracketThickness = 2.5;
  static const Color cornerBracketColor = accentGold;

  static const BoxDecoration shutterOuterDecoration = BoxDecoration(
    shape: BoxShape.circle,
    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2.5)),
  );

  // ---------- Bottom sheet ----------
  static const BorderRadius sheetTopRadius = BorderRadius.vertical(top: Radius.circular(24));

  static BoxDecoration get sheetHandleDecoration =>
      BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2));

  static Widget sheetHandle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: sheetHandleDecoration,
      );

  /// Checkmark-prefixed tip row, used in bottom-sheet tip lists.
  static Widget checkTipRow(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.check_circle, color: freshGreen, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: TextStyle(color: textMuted, fontSize: 12.5, height: 1.4)),
            ),
          ],
        ),
      );

  // ---------- Icon + label row (card section headers) ----------
  static Widget iconLabelRow({
    required IconData icon,
    required String label,
    Color? color,
    double fontSize = 15,
  }) {
    final resolvedColor = color ?? textDark;
    return Row(
      children: [
        Icon(icon, size: 18, color: resolvedColor),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: resolvedColor, fontWeight: FontWeight.w700, fontSize: fontSize)),
      ],
    );
  }

  // ---------- Bordered pill badge (e.g. meat type · cut) ----------
  static Widget pillBadge({required Widget child}) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: outlinedCard(radius: 24),
          child: child,
        ),
      );

  static Widget outlinedDot({double size = 8, Color? color}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color ?? textMuted, width: 1.2)),
      );

  // ---------- Tinted card (recommendation banners, status callouts) ----------
  static BoxDecoration tintedCardDecoration(Color color, {double opacity = 0.12, double radius = 20}) =>
      _tint(color, opacity: opacity, radius: radius);

  // ---------- White card with shadow, no border ----------
  static BoxDecoration cardShadowOnly({double radius = 20}) => _panel(radius: radius, bordered: false, shadow: cardShadow);

  // ---------- Full-width bottom action buttons ----------
  static Widget primaryActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? textDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        ),
      );

  static Widget secondaryActionButton({required String label, required VoidCallback onPressed}) => SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textDark,
            backgroundColor: cardColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: borderColor),
            ),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );

  /// Like [primaryActionButton] but takes an arbitrary child (e.g. a loading spinner).
  static Widget primaryButton({
    required Widget child,
    required VoidCallback? onPressed,
    Color? color,
  }) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? roleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: child,
        ),
      );

  static Widget gradientButton({
    required Widget child,
    required VoidCallback? onPressed,
    Gradient? gradient,
  }) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient ?? roleGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? [BoxShadow(color: roleAccent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Small uppercase field/section label ----------
  static Widget fieldLabel(String text) => Text(
        text,
        style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      );

  // ---------- Read-only field (locked value display) ----------
  static Widget readOnlyField({required String value, required IconData icon}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: outlinedCard(radius: 16),
        child: Row(
          children: [
            Icon(icon, size: 17, color: textFaint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value, style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.lock_outline_rounded, size: 15, color: textFaint),
          ],
        ),
      );

  // ---------- Tappable bordered field (e.g. date picker) ----------
  static BoxDecoration get inputFieldDecoration => _panel(color: bgColor, radius: 16);

  // ---------- Danger outlined button (e.g. sign out) ----------
  static Widget dangerOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = spoiledRed,
  }) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: color),
          label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withOpacity(0.4)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        ),
      );

  // ---------- Stat card (icon + big value + label) ----------
  static Widget statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: outlinedCard(radius: 18),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 19)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 11.5)),
          ],
        ),
      );

  static const Color _snackBarBg = Color(0xFF2B2621);

  static ThemeData get themeData {
    final isDark = _isDark;
    final accent = roleAccent;
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Roboto',
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accent,
              secondary: accentGold,
              surface: cardColor,
              error: spoiledRed,
              onSurface: textDark,
            )
          : ColorScheme.light(primary: accent, secondary: accentGold, surface: cardColor, error: spoiledRed),
      textTheme: TextTheme(
        headlineSmall: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 22),
        titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 16),
        bodyMedium: TextStyle(color: textDark, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: textMuted, fontSize: 12.5, height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgColor,
        labelStyle: TextStyle(color: textMuted, fontSize: 14),
        floatingLabelStyle: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: textFaint, fontSize: 14),
        errorStyle: const TextStyle(color: spoiledRed, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(borderColor),
        enabledBorder: _border(borderColor),
        focusedBorder: _border(accent, 1.6),
        errorBorder: _border(spoiledRed, 1.2),
        focusedErrorBorder: _border(spoiledRed, 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accent.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? accent : Colors.transparent,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _snackBarBg,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}