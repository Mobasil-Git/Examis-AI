import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Default to system theme initially
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // Helper boolean if you need to quickly check if it's explicitly dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Constructor automatically loads the saved theme on startup
  ThemeProvider() {
    _loadThemeFromDevice();
  }

  // --- Load Theme ---
  Future<void> _loadThemeFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('app_theme_preference');

    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Tell the app to rebuild with the saved theme
    notifyListeners();
  }

  // --- Update Theme ---
  Future<void> setThemeMode(ThemeMode mode) async {
    // Don't rebuild if they select the theme they are already on
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    // Save the new choice to the device
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString('app_theme_preference', 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString('app_theme_preference', 'dark');
    } else {
      await prefs.setString('app_theme_preference', 'system');
    }
  }

  // --- Quick Toggle (Great for simple switches) ---
  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}