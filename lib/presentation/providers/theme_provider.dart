import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:our_community_fund/data/datasources/theme_local_data_source.dart';

/// Manages app theme state. Persists preference via [ThemeLocalDataSource].
class ThemeProvider with ChangeNotifier {
  final ThemeLocalDataSource _themeLocal;

  ThemeProvider(ThemeLocalDataSource themeLocal) : _themeLocal = themeLocal {
    _loadSavedTheme();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void _loadSavedTheme() {
    final savedTheme = _themeLocal.getSavedTheme() ?? 'System Default';
    _applyTheme(savedTheme);
  }

  Future<void> setTheme(String themeName) async {
    await _themeLocal.saveTheme(themeName);
    _applyTheme(themeName);
    notifyListeners();
  }

  void _applyTheme(String themeName) {
    switch (themeName) {
      case 'Light Theme':
        _themeMode = ThemeMode.light;
      case 'Dark Theme':
        _themeMode = ThemeMode.dark;
      case 'System Default':
        _themeMode = ThemeMode.system;
      default:
        _themeMode = ThemeMode.system;
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
