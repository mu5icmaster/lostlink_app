import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String languageCode;

  const AppSettings({required this.themeMode, required this.languageCode});

  AppSettings copyWith({ThemeMode? themeMode, String? languageCode}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class AppSettingsService {
  static const String _themeKey = 'lost_link_theme_mode';
  static const String _languageKey = 'lost_link_language';

  static final ValueNotifier<AppSettings> settings = ValueNotifier(
    const AppSettings(themeMode: ThemeMode.system, languageCode: 'en'),
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? 'system';
    final languageCode = prefs.getString(_languageKey) ?? 'en';

    settings.value = AppSettings(
      themeMode: _themeModeFromName(themeName),
      languageCode: languageCode,
    );
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.name);
    settings.value = settings.value.copyWith(themeMode: themeMode);
  }

  static Future<void> setLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    settings.value = settings.value.copyWith(languageCode: languageCode);
  }

  static String text(String key) {
    final language = settings.value.languageCode;
    return _translations[language]?[key] ?? _translations['en']![key] ?? key;
  }

  static ThemeMode _themeModeFromName(String name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'appTitle': 'LostLink',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
    },
    'ms': {
      'appTitle': 'LostLink',
      'settings': 'Tetapan',
      'darkMode': 'Mod Gelap',
      'language': 'Bahasa',
    },
    'zh': {
      'appTitle': 'LostLink',
      'settings': '设置',
      'darkMode': '深色模式',
      'language': '语言',
    },
  };
}
