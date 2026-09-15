import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, filipino }

const _kLanguageKey = 'settings.language';
const _kDarkModeKey = 'settings.darkMode';
const _kNotificationsEnabledKey = 'settings.notificationsEnabled';

class SettingsService {
  SettingsService._();

  static final ValueNotifier<AppLanguage> language = ValueNotifier(AppLanguage.english);
  static final ValueNotifier<bool> darkMode = ValueNotifier(false);
  static final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);

  static bool get isEnglish => language.value == AppLanguage.english;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final storedLanguage = prefs.getString(_kLanguageKey);
    language.value = storedLanguage == AppLanguage.filipino.name ? AppLanguage.filipino : AppLanguage.english;

    darkMode.value = prefs.getBool(_kDarkModeKey) ?? false;
    notificationsEnabled.value = prefs.getBool(_kNotificationsEnabledKey) ?? true;
  }

  static Future<void> setLanguage(AppLanguage value) async {
    language.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, value.name);
  }

  static Future<void> setDarkMode(bool value) async {
    darkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, value);
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabledKey, value);
  }
}
