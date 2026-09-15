import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingSeenKey = 'onboarding.seen';

class OnboardingService {
  OnboardingService._();

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
  }
}
