import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Define the immutable state class
class ThemeState {
  final bool useSystemTheme;
  final bool isDarkMode;

  ThemeState({
    this.useSystemTheme = false,
    this.isDarkMode = false,
  });

  ThemeMode get themeMode {
    if (useSystemTheme) return ThemeMode.system;
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeState copyWith({bool? useSystemTheme, bool? isDarkMode}) {
    return ThemeState(
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

// 2. Define the Notifier
class ThemeNotifier extends Notifier<ThemeState> {
  static const String _useSystemThemeKey = 'use_system_theme';
  static const String _isDarkModeKey = 'is_dark_mode';

  @override
  ThemeState build() {
    // Trigger async load, but provide a default state immediately
    _loadThemeFromPrefs();
    return ThemeState();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final useSystemTheme = prefs.getBool(_useSystemThemeKey) ?? false;
    final isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;

    // Update state immutably
    state = ThemeState(
      useSystemTheme: useSystemTheme,
      isDarkMode: isDarkMode,
    );
  }

  void toggleTheme(bool isDark) {
    setIsDarkMode(isDark);
  }

  Future<void> setUseSystemTheme(bool value) async {
    state = state.copyWith(useSystemTheme: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSystemThemeKey, value);
  }

  Future<void> setIsDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, value);
  }
}

// 3. Expose the Provider globally
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});