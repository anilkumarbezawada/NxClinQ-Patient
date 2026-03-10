import 'package:flutter/material.dart';

/// Premium Violet Palette based on requested rgba(73, 1, 186, 1)
class AppColors {
  AppColors._();

  // ── Primary Brand (Base: rgba(73, 1, 186, 1) / #4901baff) ────────────────────
  static const Color primaryBrand = Color(0xFF6c22f5);      
  static const Color primaryBrandLight = Color(0xFFA166FA); // Bright, shiny highlight
  static const Color primaryBrandDark = Color(0xFF4A00D3);  // Deep shadow edge

  // ── Accent (Complementary or Monochrome) ───────────────────────────────────
  // Following instructions: no red/rose mix, using a lighter/warmer violet
  static const Color accentRose = Color(0xFF8B5CF6);
  static const Color accentRoseLight = Color(0xFFA78BFA);
  static const Color accentRoseDark = Color(0xFF5B21B6);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF9F7FF);      
  static const Color surfaceLightCard = Color(0xFFFFFFFF);  
  static const Color surfaceLightSecondary = Color(0xFFEFE8FF); 

  static const Color surfaceDark = Color(0xFF0F002A);
  static const Color surfaceDarkCard = Color(0xFF190040);
  static const Color surfaceDarkSecondary = Color(0xFF25005A);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF190040);
  static const Color textSecondaryLight = Color(0xFF5A4080);
  
  static const Color textPrimaryDark = Color(0xFFF9F7FF);
  static const Color textSecondaryDark = Color(0xFFB39EDB);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);

  // ── Custom Seed Colors (for user theme picker) ─────────────────────────────
  static const List<Color> seedColors = [
    Color(0xFF8043F9), // Bright Purple (Default)
    Color(0xFFE11D48), // Rose Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Ocean Blue
    Color(0xFF8B5CF6), // Soft Violet
    Color(0xFFD946EF), // Fuchsia / Pink
    Color(0xFFEA580C), // Burnt Orange
    Color(0xFF64748B), // Slate Grey
  ];

  // ── Gradient Presets ───────────────────────────────────────────────────────
  
  /// A static fallback if needed, matches the requested purple-to-magenta.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF8043F9), // Bright Purple
      Color(0xFFC240F6), // Middle mix
      Color(0xFFF043FF), // Pinkish Magenta
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  
  static LinearGradient getPrimaryGradient(Color baseColor) {
    if (baseColor.value == const Color(0xFF8043F9).value) {
      return primaryGradient;
    }

    // For other accent colors, generate a dynamic 3-stop vibrant gradient
    final hsl = HSLColor.fromColor(baseColor);
    final highlight = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).withHue((hsl.hue - 15) % 360).toColor();
    final shadow = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).withHue((hsl.hue + 15) % 360).toColor();

    return LinearGradient(
      colors: [
        shadow,    // Dark on the left
        baseColor, // Middle
        highlight, // Light on the right
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

}
