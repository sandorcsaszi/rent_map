import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class SettingsService {
  static const _themeKey = 'theme_mode';
  static const _bkkKey = 'show_bkk';

  Future<AppThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String? value;
    switch (mode) {
      case AppThemeMode.system:
        value = null;
        break;
      case AppThemeMode.light:
        value = 'light';
        break;
      case AppThemeMode.dark:
        value = 'dark';
        break;
    }
    if (value == null) {
      await prefs.remove(_themeKey);
    } else {
      await prefs.setString(_themeKey, value);
    }
  }

  Future<bool> loadBkkStopsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bkkKey) ?? false;
  }

  Future<void> saveBkkStopsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bkkKey, value);
  }
}

