import 'package:flutter/material.dart';

/// Meridian-inspired palette: warm near-black ink ground, parchment text,
/// a single antique-gold accent (used as outline/glow, never a flood fill).
class AppColors {
  AppColors._();

  static const navy = Color(0xFF181310);
  static const navyDeep = Color(0xFF0D0B09);
  static const navyPanel = Color(0xFF14110C);
  static const navyPanel2 = Color(0xFF221B13);
  static const cream = Color(0xFFE8E2D5);
  static const creamDim = Color(0xB3E8E2D5); // ~60% opacity
  static const gold = Color(0xFFC9A86A);
  static const goldBright = Color(0xFFE8D4A8);
  static const goldDim = Color(0xFFA8895A);
  static const success = Color(0xFF8BC78B);
  static const danger = Color(0xFFD47850);
  static const error = Color(0xFFC96A4A);

  /// Spectral teal-green — the "not yet found" glow on locked quest cards,
  /// echoing the glowing crystal-diamond look from the source game.
  static const locked = Color(0xFF5FD9B4);
}
