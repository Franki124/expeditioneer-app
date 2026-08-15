import 'package:flutter/material.dart';

import 'colors.dart';
import 'radii.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.navy,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.navy,
      primary: AppColors.gold,
      secondary: AppColors.gold,
      error: AppColors.error,
      onPrimary: AppColors.navyDeep,
      onSurface: AppColors.cream,
    ),
    textTheme: AppTypography.textTheme,
    // Bare ElevatedButton/OutlinedButton calls still fall back to this;
    // prefer the AppButton widget — kept here mainly so any stray bare
    // button still reads on-theme.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navyDeep,
        textStyle: AppTypography.label(fontSize: 15, color: AppColors.navyDeep),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
    ),
  );
}
