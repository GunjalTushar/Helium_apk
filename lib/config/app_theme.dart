import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Dark Theme - Therapeutic & Elegant
/// Mood: Calm intelligence • Night spa • Focused elegance
class AppTheme {
  // 🖤 Core Surfaces
  static const Color backgroundDeepNightTeal = Color(0xFF0F1F22); // Main background
  static const Color surfaceDarkSlateTeal = Color(0xFF152A2E); // Cards, modals
  static const Color surfaceElevated = Color(0xFF1B343A); // Hover, focus
  
  // 🌿 Brand Colors (Dark-Optimized)
  static const Color brandPrimaryLuminousTeal = Color(0xFF4FD1C5); // Primary CTA
  static const Color brandSecondaryEucalyptus = Color(0xFF7FBFB2); // Secondary actions
  static const Color accentChampagneGold = Color(0xFFE6C27A); // Luxury touch
  
  // ✍️ Typography (Eye-Safe)
  static const Color textPrimarySoftPearl = Color(0xFFE7ECEB); // Headings
  static const Color textSecondaryCoolAsh = Color(0xFFA3B1AF); // Descriptions
  static const Color textDisabledHint = Color(0xFF6F8481); // Disabled
  
  // 🚦 Feedback States (Dark-Friendly)
  static const Color stateSuccess = Color(0xFF3FC1A4);
  static const Color stateWarning = Color(0xFFF4B860);
  static const Color stateError = Color(0xFFE07A7A);
  
  // 🎛️ Borders & Focus
  static const Color borderDivider = Color(0xFF1F3A40);
  static const Color focusGlow = Color(0xFF4FD1C5);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDeepNightTeal,
    primaryColor: brandPrimaryLuminousTeal,
    colorScheme: const ColorScheme.dark(
      primary: brandPrimaryLuminousTeal,
      secondary: brandSecondaryEucalyptus,
      surface: surfaceDarkSlateTeal,
      error: stateError,
      onPrimary: backgroundDeepNightTeal,
      onSecondary: backgroundDeepNightTeal,
      onSurface: textPrimarySoftPearl,
      onError: textPrimarySoftPearl,
    ),
    textTheme: GoogleFonts.manropeTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: textPrimarySoftPearl,
        displayColor: textPrimarySoftPearl,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDeepNightTeal,
      elevation: 0,
      foregroundColor: textPrimarySoftPearl,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDarkSlateTeal,
      hintStyle: const TextStyle(color: textDisabledHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: focusGlow, width: 1),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceDarkSlateTeal,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderDivider.withValues(alpha: 0.3)),
      ),
    ),
    dividerColor: borderDivider.withValues(alpha: 0.4),
  );
}
