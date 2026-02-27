import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ptapp/utils/depth_manager.dart';

class AppTheme {
  // Pure Black Theme Colors (Corrected from User Feedback)
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF000000); // Pitch Black
  static const Color surfaceColor = Color(0xFF121212); // Deep Grey for cards
  static const Color mutedTextColor = Color(0xFF8E8E93);
  static const Color errorColor = Color(0xFFFF453A);
  static const Color accentColor = Color(0xFF007AFF);
  static const Color electricLime = Color(0xFFC0FF00);
  static const Color roseBerry = Color(0xFFFB7185);

  // Light Theme Colors (Modern Boutique Aesthetic)
  static const Color lightPrimaryColor =
      primaryColor; // Keep blue for highlights
  static const Color lightBackgroundColor = Color.fromARGB(
    255,
    243,
    228,
    203,
  ); // Premium Linen
  static const Color lightSurfaceColor = Color.fromARGB(255, 247, 238, 225);
  static const Color lightTextColor = Color(0xFF1C1C1E);
  static const Color lightMutedTextColor = Color(0xFF706D69);

  static Color getScaffoldColor(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return theme.scaffoldBackgroundColor;
    }

    // Precise Light Mode Progressive Darkening
    final int depth = PageDepth.of(context);
    // If depth is 0 (not found) or 1 (base), return base color
    if (depth <= 1) return lightBackgroundColor;

    final baseHSL = HSLColor.fromColor(lightBackgroundColor);

    // As depth increases (2, 3, 4...), darkenAmount increases (0.1, 0.2, 0.3...)
    // We reduced the step to 0.1 for more subtle progression
    double darkenAmount = (depth - 1) * 0.07;
    if (darkenAmount > 0.50) darkenAmount = 0.50; // Cap at 50% darkening

    // Subtract from lightness to make it darker (closer to 0)
    double newLightness = (baseHSL.lightness - darkenAmount).clamp(0.0, 1.0);

    return baseHSL.withLightness(newLightness).toColor();
  }

  static ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    background: backgroundColor,
    surface: surfaceColor,
    primary: primaryColor,
    text: Colors.white,
    mutedText: mutedTextColor,
  );

  static ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    background: lightBackgroundColor,
    surface: lightSurfaceColor,
    primary: lightPrimaryColor,
    text: lightTextColor,
    mutedText: lightMutedTextColor,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color text,
    required Color mutedText,
  }) {
    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        elevation: brightness == Brightness.dark ? 0 : 2,
        shadowColor: brightness == Brightness.dark
            ? Colors.transparent
            : Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: brightness == Brightness.dark
                ? text.withOpacity(0.1)
                : Colors.transparent,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: text),
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor:
            Colors.transparent, // Let Scaffold background show through
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: text),
        bodyMedium: TextStyle(fontSize: 14, color: mutedText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: mutedText),
        hintStyle: TextStyle(color: text.withOpacity(0.3)),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
        secondary: brightness == Brightness.dark ? primary : electricLime,
        onSecondary: Colors.black, // High visibility on Lime or Blue
        tertiary: brightness == Brightness.dark ? accentColor : roseBerry,
        error: errorColor,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
      ),
      dividerColor: text.withOpacity(0.1),
    );
  }
}
