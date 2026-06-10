import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 450);

  // Border radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double xlargeRadius = 20.0;
  static const double xxlargeRadius = 28.0;

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Icon sizes
  static const double iconSmall = 18.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  // Font sizes
  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0;
  static const double fontLarge = 16.0;
  static const double fontXLarge = 20.0;
  static const double fontXXLarge = 24.0;

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
    Color(0xFF3B82F6),
  ];

  // Pagination
  static const int postsPerPage = 20;
  static const int messagesPerPage = 50;
  static const int commentsPerPage = 20;

  // Debounce durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration scrollDebounce = Duration(milliseconds: 300);

  // Cache settings
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheExpiration = Duration(days: 7);
}
