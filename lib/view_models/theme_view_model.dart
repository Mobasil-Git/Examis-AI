import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  static const String _useSystemThemeKey = 'use_system_theme';
  static const String _isDarkModeKey = 'is_dark_mode';

  bool _useSystemTheme = false;
  bool _isDarkMode = false;

  bool get useSystemTheme => _useSystemTheme;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode {
    if (_useSystemTheme) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeViewModel() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool(_useSystemThemeKey) ?? false;
    _isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
    notifyListeners();
  }
  void toggleTheme(bool isDark) {
    setIsDarkMode(isDark);
  }

  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSystemThemeKey, value);
  }

  Future<void> setIsDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, value);
  }
}