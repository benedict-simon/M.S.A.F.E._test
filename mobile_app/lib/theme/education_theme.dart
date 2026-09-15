import 'package:flutter/material.dart';
import 'app_theme.dart';

class EducationTheme {
  EducationTheme._();

  static bool isFreshnessFolder(String title) {
    final t = title.toLowerCase();
    return t.contains('freshness') || t.contains('identif');
  }

  static bool isHandlingFolder(String title) {
    final t = title.toLowerCase();
    return t.contains('handling') || t.contains('storage') || t.contains('safety');
  }

  static bool isLegalFolder(String title) {
    final t = title.toLowerCase();
    return t.contains('legal') || t.contains('law');
  }

  static IconData iconForFolder(String title) {
    if (isFreshnessFolder(title)) return Icons.search_rounded;
    if (isHandlingFolder(title)) return Icons.clean_hands_rounded;
    if (isLegalFolder(title)) return Icons.gavel_rounded;
    return Icons.folder_outlined;
  }

  static Color colorForFolder(String title) {
    if (isFreshnessFolder(title)) return AppTheme.spoiledRed;
    if (isHandlingFolder(title)) return AppTheme.freshGreen;
    if (isLegalFolder(title)) return AppTheme.primaryRed;
    return AppTheme.primaryRedDark;
  }

  /// Small pill used to badge a legal citation, e.g. "RA 9296".
  static Widget codePill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  static Widget highlightWrapper({
    required Key sectionKey,
    required bool isHighlighted,
    required Color color,
    required Widget child,
  }) =>
      AnimatedContainer(
        key: sectionKey,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(isHighlighted ? 12 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isHighlighted ? color : Colors.transparent, width: 2),
          color: isHighlighted ? color.withOpacity(0.05) : Colors.transparent,
        ),
        child: child,
      );

  static Widget sectionHeader({required IconData icon, required String label, required Color color}) => Row(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: AppTheme.iconBadgeBg(color, radius: 12)
              .copyWith(boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 11),
        Text(label.toUpperCase(),
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.6)),
      ]);

  static Widget accentCard({required Color color, required Widget child, double radius = 18}) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: AppTheme.cardWithShadowRadius(radius),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 4, color: color.withOpacity(0.9)),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ]),
      );

  static Widget navCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: AppTheme.cardWithShadow,
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: AppTheme.iconBadgeBg(color, radius: 14),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textFaint),
          ]),
        ),
      );
}