import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/login_theme.dart';
import '../services/onboarding_service.dart';
import '../services/session_service.dart';
import '../services/user_service.dart';
import '../services/settings_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  VoidCallback? _authSettledListener;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _waitThenEnterApp();
  }

  Future<void> _waitThenEnterApp() async {
    final minSplashTime = Future.delayed(const Duration(milliseconds: 1200));

    Future<void> authSettled;
    if (SessionService.isLoggedIn) {
      authSettled = Future.value();
    } else {
      final completer = Completer<void>();
      void listener() {
        if (SessionService.isLoggedIn) completer.complete();
      }
      _authSettledListener = listener;
      SessionService.status.addListener(listener);
      authSettled = completer.future.timeout(
        const Duration(milliseconds: 3000),
        onTimeout: () {},
      );
    }

    await Future.wait([minSplashTime, authSettled]);
    if (_authSettledListener != null) {
      SessionService.status.removeListener(_authSettledListener!);
      _authSettledListener = null;
    }
    _enterApp();
  }

  Future<void> _enterApp() async {
    if (!mounted) return;

    // Don't stomp on a session that was already established while we were
    // waiting above.
    if (!SessionService.isLoggedIn) {
      SessionService.enterAsGuest();
    }

    final route = SessionService.isLoggedIn ? UserService.postLoginRoute : '/home';

    final seenOnboarding = await OnboardingService.hasSeen();
    if (!mounted) return;
    if (!seenOnboarding) {
      Navigator.of(context).pushReplacementNamed('/onboarding', arguments: route);
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    if (_authSettledListener != null) {
      SessionService.status.removeListener(_authSettledListener!);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryRed, AppTheme.primaryRedDark],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -60, right: -50, child: _softCircle(180, 0.08)),
            Positioned(bottom: -80, left: -60, child: _softCircle(220, 0.06)),
            Positioned(top: 140, left: -40, child: _softCircle(90, 0.05)),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(10),
                          alignment: Alignment.center,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              LoginTheme.logoAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.set_meal_outlined,
                                color: AppTheme.primaryRedDark,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'M.S.A.F.E.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListenableBuilder(
                          listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
                          builder: (context, _) => Text(
                            SettingsService.isEnglish
                                ? 'Meat Spoilage & Freshness Evaluation'
                                : 'Pagsusuri sa Pagkasira at Sariwa ng Karne',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 36),
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );
}