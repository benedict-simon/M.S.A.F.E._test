import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';

class DevelopersScreen extends StatelessWidget {
  const DevelopersScreen({super.key});

  static const _developers = [
    'Benedict Simon Basagre',
    'Kyla Gay Carino',
    'Trisha Mae Navarro',
    'Jethro Miguel Pangco',
  ];

  String _initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AppTheme.screenHeader(context, isEn ? 'About the Developers' : 'Tungkol sa mga Developer'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      Text(
                        isEn ? 'The team behind M.S.A.F.E.' : 'Ang koponan sa likod ng M.S.A.F.E.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.45),
                      ),
                      const SizedBox(height: 20),
                      for (final name in _developers) ...[
                        _DeveloperCard(name: name, initials: _initialsOf(name)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  final String name;
  final String initials;

  const _DeveloperCard({required this.name, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardWithShadowRadius(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppTheme.roleAccent, shape: BoxShape.circle),
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text('Full Stack Developer', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
