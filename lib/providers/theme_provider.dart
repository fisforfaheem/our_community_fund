import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  final SharedPreferences _prefs;

  ThemeProvider(this._prefs) {
    _loadSavedTheme();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void _loadSavedTheme() {
    final savedTheme = _prefs.getString(_themeKey) ?? 'System Default';
    _applyTheme(savedTheme);
  }

  Future<void> setTheme(String themeName) async {
    await _prefs.setString(_themeKey, themeName);
    _applyTheme(themeName);
    notifyListeners();
  }

  void _applyTheme(String themeName) {
    switch (themeName) {
      case 'Light Theme':
        _themeMode = ThemeMode.light;
        break;
      case 'Dark Theme':
        _themeMode = ThemeMode.dark;
        break;
      case 'System Default':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }
  }

  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}
