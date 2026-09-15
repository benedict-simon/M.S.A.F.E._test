import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/meat_type.dart';
import '../services/meat_type_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class MeatTypeSelectionScreen extends StatefulWidget {
  const MeatTypeSelectionScreen({super.key});

  @override
  State<MeatTypeSelectionScreen> createState() => _MeatTypeSelectionScreenState();
}

class _MeatTypeSelectionScreenState extends State<MeatTypeSelectionScreen> {
  late Future<List<MeatType>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _typesFuture = MeatTypeService.fetchAll();
  }

  void _retry() => setState(() => _typesFuture = MeatTypeService.fetchAll());

  void _selectAndContinue(BuildContext context, MeatType type) {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(context, '/scan', arguments: type);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundBackButton(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isEn ? 'What are you scanning?' : 'Ano ang iyong sina-scan?',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn
                        ? 'Pick a meat type so we can check it against the right model.'
                        : 'Pumili ng uri ng karne para masuri ito gamit ang tamang modelo.',
                    style: TextStyle(
                      color: AppTheme.textDark.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: FutureBuilder<List<MeatType>>(
                      future: _typesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Center(child: CircularProgressIndicator(color: AppTheme.roleAccent));
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return _buildErrorState(isEn);
                        }
                        final types = snapshot.data!;
                        if (types.isEmpty) {
                          return AppTheme.emptyState(
                            icon: Icons.set_meal_outlined,
                            title: isEn ? 'No meat types yet' : 'Wala Pang Uri ng Karne',
                            subtitle: isEn ? 'Ask an admin to add meat types in the CMS.' : 'Hilingin sa admin na magdagdag ng uri ng karne sa CMS.',
                          );
                        }
                        return ListView.separated(
                          itemCount: types.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final type = types[index];
                            return _MeatTypeCard(
                              type: type,
                              onTap: () => _selectAndContinue(context, type),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(bool isEn) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, color: AppTheme.textFaint, size: 34),
          const SizedBox(height: 10),
          Text(isEn ? 'Could not load meat types' : 'Hindi Na-load ang mga Uri ng Karne', style: AppTheme.emptyTitle),
          const SizedBox(height: 4),
          Text(isEn ? 'Check your connection and try again.' : 'Suriin ang iyong koneksyon at subukan muli.', style: AppTheme.emptySubtitle, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh_rounded, size: 16), label: Text(isEn ? 'Try Again' : 'Subukan Muli')),
        ]),
      ),
    );
  }
}

class _MeatTypeCard extends StatelessWidget {
  final MeatType type;
  final VoidCallback onTap;

  const _MeatTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              AppTheme.meatThumbnail(type.name, size: 48, radius: 14),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      type.label,
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.subtitle,
                      style: TextStyle(
                        color: AppTheme.textDark.withOpacity(0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textDark.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RoundBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.chevron_left_rounded, color: AppTheme.textDark, size: 20),
        ),
      ),
    );
  }
}
