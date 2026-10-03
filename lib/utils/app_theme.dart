import 'package:flutter/material.dart';

/// Vibrant Cyber-Glass Theme Token System
/// Dựa theo bộ thiết kế Google Stitch (Midnight Obsidian + Electric Cyan + Deep Violet)
class AppTheme {
  // Brand Palette - Vibrant Cyber-Glass
  static const Color primaryCyan = Color(0xFF00F2FE); // Electric Cyan
  static const Color cyanDim = Color(0xFF00DCE6);
  static const Color cyanLight = Color(0xFFE0FDFF);
  
  static const Color secondaryViolet = Color(0xFF7928CA); // Deep Electric Violet
  static const Color electricPurple = secondaryViolet;
  static const Color violetLight = Color(0xFFDBB8FF);
  static const Color violetContainer = Color(0xFF6807BA);

  static const Color tertiaryMagenta = Color(0xFFFF007A); // Neon Coral Magenta (Live, alerts)
  static const Color errorRed = Color(0xFFFFB4AB);

  // Neutral Surfaces (Midnight Obsidian)
  static const Color bgDark = Color(0xFF0B0F19); // Midnight Obsidian Canvas
  static const Color surfaceDark = Color(0xFF0F131D); // Base Surface
  static const Color surfaceContainerLowest = Color(0xFF0A0E18);
  static const Color surfaceContainerLow = Color(0xFF171B26);
  static const Color surfaceContainer = Color(0xFF1C1F2A);
  static const Color surfaceContainerHigh = Color(0xFF262A35);
  static const Color surfaceContainerHighest = Color(0xFF313540);

  // Text & Foregrounds
  static const Color onSurface = Color(0xFFDFE2F1); // High Emphasis Light Text
  static const Color onSurfaceVariant = Color(0xFFB9CACB); // Medium Emphasis Metadata
  static const Color outline = Color(0xFF849495);
  static const Color outlineVariant = Color(0xFF3A494B);

  // Backward compatibility alias constants
  static const Color primaryColor = primaryCyan;
  static const Color primaryDark = Color(0xFF006A70);
  static const Color mintColor = Color(0xFF10B981);
  static const Color secondaryColor = secondaryViolet;
  static const Color accentColor = tertiaryMagenta;
  static const Color backgroundLight = Color(0xFFF1F5F9);

  /// Theme chính thức: Vibrant Cyber-Glass (Dark First)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: surfaceDark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryCyan,
      onPrimary: Color(0xFF00373A),
      primaryContainer: primaryCyan,
      onPrimaryContainer: Color(0xFF006A70),
      secondary: violetLight,
      onSecondary: Color(0xFF470083),
      secondaryContainer: violetContainer,
      onSecondaryContainer: violetLight,
      tertiary: tertiaryMagenta,
      onTertiary: Colors.white,
      error: errorRed,
      onError: Color(0xFF690005),
      surface: surfaceContainer,
      onSurface: onSurface,
      outline: outline,
      outlineVariant: outlineVariant,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryCyan,
        foregroundColor: const Color(0xFF0B0F19),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
      titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 15),
      titleSmall: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: TextStyle(color: onSurface, fontSize: 15),
      bodyMedium: TextStyle(color: onSurface, fontSize: 14),
      bodySmall: TextStyle(color: onSurfaceVariant, fontSize: 12),
      labelLarge: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: TextStyle(color: onSurfaceVariant, fontSize: 12),
      labelSmall: TextStyle(color: onSurfaceVariant, fontSize: 10, letterSpacing: 0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainerLow,
      hintStyle: const TextStyle(color: onSurfaceVariant, fontSize: 14),
      labelStyle: const TextStyle(color: onSurface, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryCyan, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  /// Light theme tương thích
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0284C7),
      brightness: Brightness.light,
      primary: const Color(0xFF0284C7),
      secondary: const Color(0xFF7928CA),
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: false,
    ),
  );
}
