import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's appearance choice across app launches.
class ThemeService {
  ThemeService._();
  // Keep the existing preference key so current installations retain their choice.
  static const _key = 'cater_pro_theme_mode_v1';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Premium dark remains the first-launch default; users can choose Light or System.
    final value = prefs.getString(_key) ?? 'dark';
    mode.value = switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  static Future<void> setMode(ThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
    mode.value = value;
  }
}
