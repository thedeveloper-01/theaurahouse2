// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF8B5CF6),
      secondary: const Color(0xFF6366F1),
      surface: Colors.white,
      background: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontFamily: '.SF Pro Display'),
      bodyMedium: TextStyle(color: Colors.black, fontFamily: '.SF Pro Display'),
      bodySmall: TextStyle(
        color: Colors.black87,
        fontFamily: '.SF Pro Display',
      ),
      titleLarge: TextStyle(color: Colors.black, fontFamily: '.SF Pro Display'),
      titleMedium: TextStyle(
        color: Colors.black,
        fontFamily: '.SF Pro Display',
      ),
      titleSmall: TextStyle(
        color: Colors.black87,
        fontFamily: '.SF Pro Display',
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    dividerColor: Colors.black.withValues(alpha: 0.1),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF8B5CF6),
      secondary: const Color(0xFF6366F1),
      surface: const Color(0xFF0A0A0A),
      background: const Color(0xFF0A0A0A),
      error: Colors.red[300]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFF0A0A0A),
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontFamily: '.SF Pro Display'),
      bodyMedium: TextStyle(color: Colors.white, fontFamily: '.SF Pro Display'),
      bodySmall: TextStyle(
        color: Colors.white70,
        fontFamily: '.SF Pro Display',
      ),
      titleLarge: TextStyle(color: Colors.white, fontFamily: '.SF Pro Display'),
      titleMedium: TextStyle(
        color: Colors.white,
        fontFamily: '.SF Pro Display',
      ),
      titleSmall: TextStyle(
        color: Colors.white70,
        fontFamily: '.SF Pro Display',
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.white.withValues(alpha: 0.1),
  );
}
