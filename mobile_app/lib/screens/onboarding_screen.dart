import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/login_theme.dart';
import '../services/onboarding_service.dart';
import '../services/settings_service.dart';

class _OnboardPage {
  final IconData? icon;
  final bool isWelcome;
  final Color color;
  final String Function(bool isEn) title;
  final String Function(bool isEn) body;

  const _OnboardPage({
    this.icon,
    this.isWelcome = false,
    required this.color,
    required this.title,
    required this.body,
  });
}

class OnboardingScreen extends StatefulWidget {
  final String nextRoute;

  const OnboardingScreen({super.key, required this.nextRoute});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _continuing = false;

  static final _pages = <_OnboardPage>[
    _OnboardPage(
      isWelcome: true,
      color: AppTheme.primaryRed,
      title: (isEn) => isEn ? 'Welcome to M.S.A.F.E.' : 'Maligayang Pagdating sa M.S.A.F.E.',
      body: (isEn) => isEn
          ? 'A quick freshness read based on a photo — swipe through to see how it works before your first scan.'
          : 'Mabilis na freshness read batay sa larawan — mag-swipe para makita kung paano ito gumagana bago ang unang scan mo.',
    ),
    _OnboardPage(
      icon: Icons.photo_camera_back_outlined,
      color: AppTheme.freshGreen,
      title: (isEn) => isEn ? 'What it does' : 'Ano ang ginagawa nito',
      body: (isEn) => isEn
          ? 'Takes a photo of raw meat and classifies it Fresh or Spoiled, with a confidence score and the visual signs behind that result.'
          : 'Kumukuha ng larawan ng hilaw na karne at kino-classify ito bilang Sariwa o Sira, kasama ang confidence score at ang mga visual na palatandaan sa likod ng resultang iyon.',
    ),
    _OnboardPage(
      icon: Icons.warning_amber_rounded,
      color: AppTheme.accentGold,
      title: (isEn) => isEn ? "What it can't guarantee" : 'Ang hindi nito magagarantiya',
      body: (isEn) => isEn
          ? "It's a visual estimate, not a lab test — it can't detect bacteria, contamination, or spoilage that hasn't visibly started yet. Lower-confidence results are more ambiguous; when in doubt, trust your own senses too."
          : 'Ito ay visual na pagtatantya, hindi lab test — hindi nito matutukoy ang bacteria, kontaminasyon, o pagkasirang hindi pa nakikita. Mas malabo ang mga resultang may mas mababang confidence; kung may pagdududa, pagtiwalaan din ang sarili mong pandama.',
    ),
    _OnboardPage(
      icon: Icons.flag_outlined,
      color: AppTheme.primaryRedDark,
      title: (isEn) => isEn ? 'If something looks wrong' : 'Kung may mali',
      body: (isEn) => isEn
          ? 'You can flag a spoiled result to NMIS for review, right from the scan result.'
          : 'Maaari mong i-flag ang resultang sira sa NMIS para sa review, direkta mula sa resulta ng scan.',
    ),
  ];

  bool get _isFirstPage => _page == 0;
  bool get _isLastPage => _page == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _back() {
    _pageController.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _skip() {
    _pageController.animateToPage(_pages.length - 1, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    setState(() => _continuing = true);
    await OnboardingService.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        final currentColor = _pages[_page].color;
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            color: Color.lerp(AppTheme.bgColor, currentColor, 0.05),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: !_isLastPage
                            ? TextButton(
                                onPressed: _skip,
                                child: Text(isEn ? 'Skip' : 'Laktawan', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) => _buildPage(_pages[i], isEn),
                    ),
                  ),
                  _buildDots(),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      children: [
                        if (!_isFirstPage) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _continuing ? null : _back,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                side: BorderSide(color: AppTheme.borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(isEn ? 'Back' : 'Bumalik', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: _isFirstPage ? 1 : 2,
                          child: AppTheme.primaryButton(
                            color: currentColor,
                            onPressed: _continuing ? null : _next,
                            child: _continuing
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                : Text(_isLastPage
                                    ? (isEn ? 'Get Started' : 'Simulan Na')
                                    : (isEn ? 'Next' : 'Susunod')),
                          ),
                        ),
                      ],
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

  Widget _buildPage(_OnboardPage page, bool isEn) {
    if (page.isWelcome) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 12))],
              ),
              child: ClipOval(
                child: Image.asset(
                  LoginTheme.logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.set_meal_outlined, color: Colors.white, size: 56),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              page.title(isEn),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textDark, fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Text(
              page.body(isEn),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.55),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: page.color.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Icon(page.icon, size: 46, color: page.color),
          ),
          const SizedBox(height: 30),
          Text(
            page.title(isEn),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textDark, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            page.body(isEn),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _pages.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _page ? 24 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _page ? _pages[_page].color : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      );
}
