import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_font_sizes.dart';

/// Centralised typography constants for the app.
/// All text styles use [GoogleFonts.poppins] so fonts can be updated
/// in one place.
///
/// Usage:
///   Text('Hello', style: AppTypography.headlineMedium)
class AppTypography {
  AppTypography._();

  // ── Display ────────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: AppFontSizes.displayLarge,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  // ── Headlines ──────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: AppFontSizes.headlineLarge,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: AppFontSizes.headlineMedium,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: AppFontSizes.headlineSmall,
        fontWeight: FontWeight.w700,
      );

  // ── Titles ─────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: AppFontSizes.titleLarge,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: AppFontSizes.titleMedium,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleSmall => GoogleFonts.poppins(
        fontSize: AppFontSizes.titleSmall,
        fontWeight: FontWeight.w600,
      );

  // ── Body ───────────────────────────────────────────────────────────────────
  /// Standard readable body text (minimum readable size).
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: AppFontSizes.bodyLarge,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: AppFontSizes.bodyMedium,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: AppFontSizes.bodySmall,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ── Labels ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: AppFontSizes.labelLarge,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: AppFontSizes.labelMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: AppFontSizes.labelSmall,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  // ── Section headers (cards, sections) ─────────────────────────────────────
  static TextStyle get sectionHeader => GoogleFonts.poppins(
        fontSize: AppFontSizes.sectionHeader,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      );

  // ── Buttons ────────────────────────────────────────────────────────────────
  static TextStyle get buttonLarge => GoogleFonts.poppins(
        fontSize: AppFontSizes.buttonLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonMedium => GoogleFonts.poppins(
        fontSize: AppFontSizes.buttonMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  // ── Chips / Tags ───────────────────────────────────────────────────────────
  static TextStyle get chip => GoogleFonts.poppins(
        fontSize: AppFontSizes.chip,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get chipSmall => GoogleFonts.poppins(
        fontSize: AppFontSizes.chipSmall,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );
}
