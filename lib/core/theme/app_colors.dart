import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00BFA5);
  static const Color primaryDeep = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFFB2DFDB);
  static const Color surface = Color(0xFFF0FBFF);
  static const Color pageBackground = Color(0xFFF5F6FA);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color lightMint = Color(0xFFE0F2F1);
  static const Color darkBackground = Color(0xFF121212);

  // Status colors
  static const Color statusScheduled = Color(0xFF00897B); // primaryDeep
  static const Color statusCompleted = Color(0xFF00BFA5); // primary
  static const Color statusCancelled = Color(0xFFE57373); // distinct red
  static const Color statusPending = Color(0xFFFFB74D);   // distinct orange
  static const Color unavailable = Color(0xFFD94B4B);
  static const Color unavailableLight = Color(0xFFFFA4A4);

  // Standard Neutrals (required for basic text/cards without adding 'new' colorful hues)
  static const Color white = Colors.white;
  static const Color textMain = Color(0xFF0D2B2A);
  static const Color textMuted = Color(0xFF616161); // grey 700ish
  static const Color divider = Color(0xFFEEEEEE);
}
