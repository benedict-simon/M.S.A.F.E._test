import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  List<(IconData, String, String)> _features(bool isEn) => isEn
      ? const [
          (
            Icons.qr_code_scanner_rounded,
            'Instant Freshness Scans',
            'Point your camera at raw pork, beef, or chicken and get a preliminary freshness read in seconds.',
          ),
          (
            Icons.flag_rounded,
            'Report to NMIS',
            'Flag a spoiled purchase and send the details straight to the National Meat Inspection Service.',
          ),
          (
            Icons.history_rounded,
            'Track Your History',
            'Every scan and report is saved so you can look back on what you\'ve checked and when.',
          ),
          (
            Icons.menu_book_rounded,
            'Food Safety Education',
            'Learn practical tips on proper storage, handling, and spotting early signs of spoilage.',
          ),
        ]
      : const [
          (
            Icons.qr_code_scanner_rounded,
            'Instant na Freshness Scan',
            'I-point ang camera sa hilaw na baboy, baka, o manok para sa paunang pagtaya ng sariwa sa ilang segundo.',
          ),
          (
            Icons.flag_rounded,
            'I-report sa NMIS',
            'I-flag ang sirang binili at direktang ipadala ang detalye sa National Meat Inspection Service.',
          ),
          (
            Icons.history_rounded,
            'Subaybayan ang Kasaysayan',
            'Naka-save ang bawat scan at report para makita mo kung ano ang na-check mo at kailan.',
          ),
          (
            Icons.menu_book_rounded,
            'Edukasyon sa Kaligtasan',
            'Matuto ng praktikal na tip sa tamang pag-imbak, pag-handle, at pagkilala ng maagang senyales ng pagkasira.',
          ),
        ];

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
                  child: AppTheme.screenHeader(context, isEn ? 'About M.S.A.F.E.' : 'Tungkol sa M.S.A.F.E.'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      _heroCard(),
                      const SizedBox(height: 24),
                      Text(
                        isEn ? 'OUR MISSION' : 'MISYON NAMIN',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? 'M.S.A.F.E. helps everyday consumers make safer choices at the market. '
                                'By combining image recognition with food safety know-how, we give you a '
                                'quick, preliminary read on raw meat freshness before it ever reaches your kitchen.'
                            : 'Tinutulungan ng M.S.A.F.E. ang mga karaniwang mamimili na gumawa ng mas '
                                'ligtas na pagpili sa palengke. Sa pamamagitan ng image recognition at '
                                'kaalaman sa food safety, nagbibigay kami ng mabilis na paunang pagtaya sa '
                                'sariwa ng hilaw na karne bago pa ito makarating sa iyong kusina.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isEn ? 'WHAT YOU CAN DO' : 'MAAARI MONG GAWIN',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      for (final feature in _features(isEn)) ...[
                        _FeatureTile(icon: feature.$1, title: feature.$2, description: feature.$3),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 14),
                      AppTheme.tintedInfoBox(
                        icon: Icons.info_outline_rounded,
                        color: AppTheme.accentGold,
                        opacity: 0.1,
                        contentColor: AppTheme.roleAccentDark,
                        text: isEn
                            ? 'M.S.A.F.E. is a screening aid only — it does not replace official '
                                'inspection by a licensed NMIS meat inspector.'
                            : 'Ang M.S.A.F.E. ay tulong sa pag-screen lamang — hindi ito kapalit ng '
                                'opisyal na inspeksyon ng lisensyadong NMIS meat inspector.',
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text('M.S.A.F.E. v1.0.0', style: TextStyle(color: AppTheme.textFaint, fontSize: 12)),
                      ),
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

  Widget _heroCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: AppTheme.roleGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: AppTheme.roleAccent.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Image.asset('assets/images/msafe_logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 14),
            const Text(
              'M.S.A.F.E.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 2.5),
            ),
            const SizedBox(height: 6),
            Text(
              'MEAT SPOILAGE & FRESHNESS EVALUATOR',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureTile({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.outlinedCard(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppTheme.iconBadgeBg(AppTheme.roleAccent),
            child: Icon(icon, color: AppTheme.roleAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(description, style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
