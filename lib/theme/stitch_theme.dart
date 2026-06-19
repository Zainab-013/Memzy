import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchTheme {
  // Colors (Light Theme - Modern Premium Indigo & Rose Accents)
  static const Color primary = Color(0xFF6366F1); // Premium Indigo accent
  static const Color secondary = Color(0xFFEC4899); // Glowing Rose/Pink accent
  static const Color background = Color(0xFFF9FAFB); // Clean soft light gray/white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F2937); // Deep charcoal/slate text
  static const Color onSurfaceVariant = Color(0xFF4B5563); // Cool system gray secondary text
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F6); // Soft gray card fill
  static const Color surfaceContainer = Color(0xFFE5E7EB); // Light slate border/fill
  static const Color surfaceContainerHigh = Color(0xFFD1D5DB); // Gray highlight border
  static const Color surfaceContainerHighest = Color(0xFF9CA3AF);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFF3F4F6);

  static const Color primaryFixed = Color(0xFFEEF2FF);
  static const Color primaryFixedDim = Color(0xFFC7D2FE);
  static const Color onPrimaryFixed = Color(0xFF3730A3); // Rich indigo for contrast
  static const Color onPrimaryFixedVariant = Color(0xFF4F46E5);

  static const Color secondaryFixed = Color(0xFFFDF2F8);
  static const Color secondaryFixedDim = Color(0xFFFBCFE8);
  static const Color onSecondaryFixed = Color(0xFF831843);
  static const Color onSecondaryFixedVariant = Color(0xFF9D174D);

  static const Color tertiaryFixed = Color(0xFFECFDF5);
  static const Color tertiaryFixedDim = Color(0xFFA7F3D0);
  static const Color onTertiaryFixed = Color(0xFF064E3B);
  static const Color onTertiaryFixedVariant = Color(0xFF047857);
  static const Color tertiaryContainer = Color(0xFF10B981);

  static const Color error = Color(0xFFEF4444); // Premium system red
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Dark Theme Colors (Deep Obsidian Black & Glowing Vibrant Accents)
  static const Color darkBackground = Color(0xFF09090C); // Sleek Obsidian Black
  static const Color darkSurface = Color(0xFF15151E); // Midnight Slate surface card
  static const Color darkOnBackground = Color(0xFFF9FAFB);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF); // Slate gray
  static const Color darkSurfaceContainerLowest = Color(0xFF0F0F14); // Deepest obsidian card
  static const Color darkSurfaceContainerLow = Color(0xFF1C1C24); // Obsidian secondary card
  static const Color darkSurfaceContainer = Color(0xFF252530);
  static const Color darkSurfaceContainerHigh = Color(0xFF2F2F3D);
  static const Color darkSurfaceContainerHighest = Color(0xFF3E3E4F);

  // Pastel Message Bubble Background & Text Constants for high contrast
  static const Color userBubbleLightBg = Color(0xFFE0E7FF); // Light pastel indigo
  static const Color userBubbleDarkBg = Color(0xFFC7D2FE); // Glowing neon indigo
  static const Color userBubbleLightBorder = Color(0xFFC7D2FE);
  static const Color userBubbleDarkBorder = Color(0xFF818CF8);
  static const Color userBubbleText = Color(0xFF1E1B4B); // Deep indigo text for perfect contrast

  static const Color systemBubbleLightBg = Color(0xFFF3F4F6); // Light pastel grey
  static const Color systemBubbleDarkBg = Color(0xFFE5E7EB); // Light pastel grey
  static const Color systemBubbleLightBorder = Color(0xFFE5E7EB);
  static const Color systemBubbleDarkBorder = Color(0xFFD1D5DB);
  static const Color systemBubbleText = Color(0xFF1F2937); // Dark text for high contrast

  // Dynamic avatar colors based on chat title hash (Flat Solid Colors - No Purple)
  static Color getAvatarBgColor(String title, bool isDark) {
    final int hash = title.hashCode.abs();
    if (isDark) {
      final List<Color> darkBgColors = [
        const Color(0xFF2C2C2E), // Slate grey
        const Color(0xFF2E3D48), // Dark slate teal
        const Color(0xFF7F5539), // Warm gold-brown
        const Color(0xFF0F4C5C), // Dark ocean teal
        const Color(0xFF1D3557), // Deep steel blue
        const Color(0xFF5C1A1B), // Dark brick red
      ];
      return darkBgColors[hash % darkBgColors.length];
    } else {
      final List<Color> lightBgColors = [
        const Color(0xFFE5E5EA), // Light slate
        const Color(0xFFE0F2FE), // Pastel blue
        const Color(0xFFFEF3C7), // Pastel gold
        const Color(0xFFE8F5E9), // Pastel green
        const Color(0xFFE0F7FA), // Pastel teal
        const Color(0xFFFFE0B2), // Pastel orange/peach
      ];
      return lightBgColors[hash % lightBgColors.length];
    }
  }

  static Color getAvatarIconColor(String title, bool isDark) {
    final int hash = title.hashCode.abs();
    if (isDark) {
      final List<Color> darkIconColors = [
        const Color(0xFFD1D1D6), // Silver
        const Color(0xFF81C784), // Light green
        const Color(0xFFFFD60A), // iMovie Gold
        const Color(0xFFBAE6FD), // Sky blue
        const Color(0xFF80F3D0), // Teal
        const Color(0xFFFF8A8A), // Light red
      ];
      return darkIconColors[hash % darkIconColors.length];
    } else {
      final List<Color> lightIconColors = [
        const Color(0xFF48484A), // Dark slate
        const Color(0xFF2E7D32), // Dark green
        const Color(0xFFD97706), // Gold
        const Color(0xFF0284C7), // Blue
        const Color(0xFF0D9488), // Teal
        const Color(0xFFDB2777), // Red
      ];
      return lightIconColors[hash % lightIconColors.length];
    }
  }

  // Dynamic flat colors for avatars (using uniform colors to avoid gradients)
  static Gradient getAvatarGradient(String title, bool isDark) {
    final Color solidBg = getAvatarBgColor(title, isDark);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [solidBg, solidBg], // Flat/solid color behavior
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        actionsIconTheme: IconThemeData(color: onSurface),
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFF1D1D1F),
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
          color: onSurfaceVariant,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkOnSurface),
        actionsIconTheme: IconThemeData(color: darkOnSurface),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryFixedDim,
        secondary: secondaryFixedDim,
        surface: darkSurface,
        onPrimary: onPrimaryFixed,
        onSecondary: onSecondaryFixed,
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
          color: darkOnSurfaceVariant,
        ),
      )),
    );
  }

  static IconData getChatIcon(int codePoint) {
    if (codePoint == Icons.chat.codePoint) return Icons.chat;
    if (codePoint == Icons.work.codePoint) return Icons.work;
    if (codePoint == Icons.description.codePoint) return Icons.description;
    if (codePoint == Icons.shopping_cart.codePoint) return Icons.shopping_cart;
    if (codePoint == Icons.home.codePoint) return Icons.home;
    if (codePoint == Icons.event.codePoint) return Icons.event;
    if (codePoint == Icons.school.codePoint) return Icons.school;
    if (codePoint == Icons.star.codePoint) return Icons.star;
    if (codePoint == Icons.person.codePoint) return Icons.person;
    return Icons.chat;
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
