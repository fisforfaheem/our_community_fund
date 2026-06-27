import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for theme preference.
abstract class ThemeLocalDataSource {
  String? getSavedTheme();
  Future<void> saveTheme(String themeName);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  static const String _themeKey = 'app_theme';
  final SharedPreferences _prefs;

  ThemeLocalDataSourceImpl(this._prefs);

  @override
  String? getSavedTheme() => _prefs.getString(_themeKey);

  @override
  Future<void> saveTheme(String themeName) async {
    await _prefs.setString(_themeKey, themeName);
  }
}
