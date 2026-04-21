import 'package:flutter/material.dart';

class AppColors {
  // --- PRIMARY BRAND ---
  static const Color primary = Color(0xFF338AF3);
  static const Color primaryLight = Color(0xFF73ACF7);
  static const Color primaryExtraLight = Color(0xFFB4D9FF);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // --- LIGHT MODE COLORS ---
  static const Color lightBackground = Color(0xFFF4F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // --- DARK MODE COLORS ---
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
}

// --- THE NEW ENGINE: THEME EXTENSION ---
// This teaches Flutter how to smoothly cross-fade your custom colors!
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const AppThemeExtension({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  @override
  AppThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
  }) {
    return AppThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
    );
  }

  // --- THIS IS THE MAGIC FADE FUNCTION ---
  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

// --- THE UPDATED MAGIC TRICK (Context Extension) ---
// Now it asks the Theme engine for the color, so it gets the smoothly fading version!
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get primary => AppColors.primary;
  Color get error => AppColors.error;
  Color get success => AppColors.success;

  // Helper to grab our extension
  AppThemeExtension get _ext => Theme.of(this).extension<AppThemeExtension>()!;

  Color get background => _ext.background;
  Color get surface => _ext.surface;
  Color get textPrimary => _ext.textPrimary;
  Color get textSecondary => _ext.textSecondary;
  Color get border => _ext.border;
}