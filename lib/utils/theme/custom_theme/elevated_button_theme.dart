import 'package:examisai/utils/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TElevatedButtonTheme {
  TElevatedButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: AppColors.surfaceLight,
      backgroundColor: AppColors.primaryLight,
      disabledForegroundColor: AppColors.surfaceLight.withAlpha(600),
      disabledBackgroundColor: AppColors.primaryLight.withAlpha(400),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.outfit(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
    ),
  );

  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: AppColors.textPrimaryDark,
      backgroundColor: AppColors.primaryDark,
      disabledForegroundColor: AppColors.textSecondaryDark,
      disabledBackgroundColor: AppColors.primaryDark.withAlpha(400),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.outfit(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
    ),
  );
}