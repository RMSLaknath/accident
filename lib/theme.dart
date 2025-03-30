import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData modernTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        secondary: const Color(0xFF64B5F6),
        tertiary: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
      fontFamily: 'Poppins',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: const Color(0xFF2196F3).withOpacity(0.9),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}