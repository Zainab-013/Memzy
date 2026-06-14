import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchTheme {
  // Colors (Light Theme)
  static const Color primary = Color(0xFF4648D4);
  static const Color secondary = Color(0xFF883CA6);
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0D1C2E);
  static const Color onSurfaceVariant = Color(0xFF464554);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE6EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD5E3FC);
  static const Color outline = Color(0xFF767586);
  static const Color outlineVariant = Color(0xFFC7C4D7);
  
  static const Color primaryFixed = Color(0xFFE1E0FF);
  static const Color primaryFixedDim = Color(0xFFC0C1FF);
  static const Color onPrimaryFixed = Color(0xFF07006C);
  static const Color onPrimaryFixedVariant = Color(0xFF2F2EBE);
  
  static const Color secondaryFixed = Color(0xFFF9D8FF);
  static const Color secondaryFixedDim = Color(0xFFEDB1FF);
  static const Color onSecondaryFixed = Color(0xFF320046);
  static const Color onSecondaryFixedVariant = Color(0xFF6E208C);

  static const Color tertiaryFixed = Color(0xFFEDDCFF);
  static const Color tertiaryFixedDim = Color(0xFFD2BFE8);
  static const Color onTertiaryFixed = Color(0xFF221534);
  static const Color onTertiaryFixedVariant = Color(0xFF4F4062);
  static const Color tertiaryContainer = Color(0xFF7E6E92);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkOnBackground = Color(0xFFEAF1FF);
  static const Color darkOnSurface = Color(0xFFEAF1FF);
  static const Color darkOnSurfaceVariant = Color(0xFFC7C4D7);
  static const Color darkSurfaceContainerLowest = Color(0xFF1A1A1A);
  static const Color darkSurfaceContainerLow = Color(0xFF222222);
  static const Color darkSurfaceContainer = Color(0xFF2A2A2A);
  static const Color darkSurfaceContainerHigh = Color(0xFF323232);
  static const Color darkSurfaceContainerHighest = Color(0xFF3A3A3A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        background: background,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: onSurface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        errorContainer: errorContainer,
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.8,
          color: onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: onSurfaceVariant,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          color: outline,
        ),
      )),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryFixedDim,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryFixedDim,
        secondary: secondaryFixedDim,
        background: darkBackground,
        surface: darkSurface,
        onPrimary: onPrimaryFixed,
        onSecondary: onSecondaryFixed,
        onBackground: darkOnBackground,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        errorContainer: errorContainer,
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.8,
          color: darkOnSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: darkOnSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkOnSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkOnSurfaceVariant,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          color: outline,
        ),
      )),
    );
  }

  // Rounded Corner Geometries
  static BorderRadius get cardRadius => BorderRadius.circular(16);
  static BorderRadius get elementRadius => BorderRadius.circular(8);
  static BorderRadius get inputRadius => BorderRadius.circular(24);

  // Message bubble border radius (4px tail on the corner pointing to screen edge)
  static BorderRadius userBubbleRadius = const BorderRadius.only(
    topLeft: Radius.circular(20),
    bottomLeft: Radius.circular(20),
    bottomRight: Radius.circular(20),
    topRight: Radius.circular(4),
  );

  static BorderRadius systemBubbleRadius = const BorderRadius.only(
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
    bottomRight: Radius.circular(20),
    topLeft: Radius.circular(4),
  );
}
