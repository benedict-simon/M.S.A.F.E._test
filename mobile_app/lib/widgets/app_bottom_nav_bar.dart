import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';
import '../services/settings_service.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static void navigateTo(BuildContext context, int currentIndex, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.popUntil(context, ModalRoute.withName('/home'));
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/scan');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/education');
        break;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
        builder: (context, _) {
          final isEn = SettingsService.isEnglish;
          return Container(
            decoration: HomeTheme.navBarDecoration,
            child: SafeArea(
              top: false,

              child: MediaQuery.withNoTextScaling(
                child: SizedBox(
                  height: 70,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _NavBarItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavBarItem(
                      icon: Icons.history_rounded,
                      label: isEn ? 'History' : 'Kasaysayan',
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    _ScanNavButton(onTap: () => onTap(2), scanLabel: isEn ? 'Scan' : 'I-scan'),
                    _NavBarItem(
                      icon: Icons.menu_book_outlined,
                      label: isEn ? 'Learn' : 'Aral',
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      );
}

class _ScanNavButton extends StatelessWidget {
  final VoidCallback onTap;
  final String scanLabel;
  const _ScanNavButton({required this.onTap, required this.scanLabel});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Transform.translate(
          offset: const Offset(0, -14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(width: 54, height: 54, decoration: HomeTheme.scanButtonDecoration, child: Icon(Icons.camera_alt_rounded, color: AppTheme.roleAccentDark, size: 24)),
            ),
          ),
        ),
        Transform.translate(offset: const Offset(0, -8), child: Text(scanLabel, style: HomeTheme.scanNavLabel)),
      ]);
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavBarItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.accentGold : AppTheme.textFaint;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 3),
          Text(label, style: (isActive ? HomeTheme.navLabelActive : HomeTheme.navLabel).copyWith(color: color)),
        ]),
      ),
    );
  }
}
