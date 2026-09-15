import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProfileTheme {
  ProfileTheme._();

  static Widget settingsGroup(List<Widget> rows) => Container(
        decoration: AppTheme.outlinedCard(radius: 18),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) settingsDivider(),
            ],
          ],
        ),
      );

  static Widget settingsDivider() => Divider(height: 1, color: AppTheme.borderColor, indent: 62);

  static Widget settingsRow({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: AppTheme.iconBadgeBg(AppTheme.roleAccent, radius: 10),
                child: Icon(icon, size: 17, color: AppTheme.roleAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textFaint),
            ],
          ),
        ),
      );
}