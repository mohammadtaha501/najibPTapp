import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure Black Theme Colors (Corrected from User Feedback)
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF000000); // Pitch Black
  static const Color surfaceColor = Color(0xFF121212); // Deep Grey for cards
  static const Color mutedTextColor = Color(0xFF8E8E93);
  static const Color errorColor = Color(0xFFFF453A);
  static const Color accentColor = Color(0xFF007AFF); // iOS Blue or any other accent

  // Light Theme Colors (Placeholders)
  static const Color lightPrimaryColor = Color(0xFF000000);
  static const Color lightBackgroundColor = Color(0xFFF2F2F7);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightTextColor = Color(0xFF1C1C1E);
  static const Color lightMutedTextColor = Color(0xFF636366);

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
    final baseTheme = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    
    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: text.withOpacity(0.1)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: mutedText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white, // Contrast text
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
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
        secondary: primary,
        onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
      ),
    );
  }
}
