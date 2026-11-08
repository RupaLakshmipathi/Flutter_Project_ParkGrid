import 'package:flutter/material.dart';

class AppTheme {
  static const powderBlue = Color(0xFFDCEBFA);
  static const softMint = Color(0xFFD9F1E6);
  static const lavender = Color(0xFFE8E0FA);
  static const peach = Color(0xFFFBE4D8);
  static const butterYellow = Color(0xFFFFF0C9);
  static const background = powderBlue;
  static const primaryText = Color(0xFF253858);
  static const accent = Color(0xFF5B7694);

  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: powderBlue,
      brightness: Brightness.light,
      primary: accent,
      secondary: softMint,
      tertiary: lavender,
      surface: Colors.white,
      onSurface: primaryText,
      onPrimary: Colors.white,
      onSecondary: primaryText,
      onTertiary: primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: powderBlue,
        foregroundColor: primaryText,
        centerTitle: false,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: primaryText,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: primaryText),
        bodyLarge: TextStyle(color: primaryText, height: 1.4),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lavender),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: softMint,
          foregroundColor: primaryText,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lavender,
        indicatorColor: softMint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: primaryText,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
