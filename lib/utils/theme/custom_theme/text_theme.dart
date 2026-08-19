import 'package:examisai/utils/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TTextTheme {
  TTextTheme._();

  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryLight,
      letterSpacing: 1.5,
    ),
    displayMedium: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryLight,
      letterSpacing: 1.2,
    ),
    titleLarge: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryLight,
      letterSpacing: 0.5,
    ),
    bodyLarge: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimaryLight,
    ),
    bodyMedium: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondaryLight,
    ),
  );

  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryDark,
      letterSpacing: 1.5,
    ),
    displayMedium: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryDark,
      letterSpacing: 1.2,
    ),
    titleLarge: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDark,
      letterSpacing: 0.5,
    ),
    bodyLarge: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimaryDark,
    ),
    bodyMedium: const TextStyle(
      fontFamily: 'Lato',
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondaryDark,
    ),
  );
}