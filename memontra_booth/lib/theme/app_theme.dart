import 'package:flutter/material.dart';

class AppTheme {
  // Logo Core Colors
  static const Color primary = Color(0xFF1C7B7F); // Teal from logo
  static const Color secondary = Color(0xFFEFBF04); // Yellow from logo
  static const Color universal = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF111111);
  static const Color textDark = Color(0xFF0F4C5C); // Dark teal text

  // Light Background Gradient Palette
  static const Color bgTeal = Color(0xFF7CBDBB);
  static const Color bgPeach = Color(0xFFF9D1BE);
  static const Color surfaceWhite = Color(0xFFF4F8F7);

  // Button Colors
  static const Color buttonPrimary = Color(0xFFE5987A); // Next button orange
  static const Color buttonSecondary = Color(0xFFFFFFFF); // Back button white

  // State Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: surfaceWhite,
      fontFamily: 'Google Sans',
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: universal,
        error: error,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonPrimary,
          foregroundColor: universal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: 2,
          shadowColor: buttonPrimary.withValues(alpha: 0.35),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          backgroundColor: buttonSecondary,
          side: const BorderSide(color: textDark, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }
}
