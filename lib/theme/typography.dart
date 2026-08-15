import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Display/heading font = Cinzel, body/UI = EB Garamond — a monumental
/// inscriptional serif for titles paired with a normal reading serif.
class AppTypography {
  AppTypography._();

  static TextStyle display({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.cream,
  }) {
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle body({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.cream,
  }) {
    return GoogleFonts.ebGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Wide-tracked uppercase label — Cinzel's lowercase already reads as
  /// small caps, so this mainly adds letter-spacing for section headers,
  /// button text and other ceremonial-feeling labels.
  static TextStyle label({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.gold,
    double letterSpacing = 2.0,
  }) {
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static const monospace = TextStyle(fontFamily: 'monospace');

  static TextTheme textTheme = TextTheme(
    displayLarge: display(fontSize: 44, fontWeight: FontWeight.w600),
    displayMedium: display(fontSize: 26, fontWeight: FontWeight.w600),
    headlineSmall: display(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: body(fontSize: 17, fontWeight: FontWeight.w700),
    bodyLarge: body(fontSize: 17),
    bodyMedium: body(fontSize: 16),
    bodySmall: body(fontSize: 14, color: AppColors.creamDim),
    labelLarge: body(fontSize: 16, fontWeight: FontWeight.w800),
  );
}
