import 'package:flutter/material.dart';

class AppTheme {
  // Dark cultivation palette
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color primary = Color(0xFF8B0000); // Dark blood red
  static const Color primaryLight = Color(0xFFB22222);
  static const Color accent = Color(0xFFC9A227); // Muted gold
  static const Color accentDark = Color(0xFF8B7355);
  static const Color jade = Color(0xFF2E8B57);
  static const Color jadeLight = Color(0xFF3CB371);
  static const Color ink = Color(0xFFE8E0D5); // Parchment ink
  static const Color inkDim = Color(0xFFA89F91);
  static const Color danger = Color(0xFF8B0000);
  static const Color success = Color(0xFF2E8B57);
  static const Color locked = Color(0xFF3A3A3A);
  static const Color border = Color(0xFF3D3D3D);
  static const Color parchment = Color(0xFF2A2520);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: danger,
        onPrimary: ink,
        onSecondary: background,
        onSurface: ink,
        onError: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: inkDim,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accentDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: inkDim),
        hintStyle: const TextStyle(color: inkDim),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: ink, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: ink, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: ink, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: ink),
        bodyMedium: TextStyle(color: inkDim),
        labelLarge: TextStyle(color: ink, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 0.5,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: surfaceElevated,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
