import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu hiện đại theo phong cách Tailwind / Material 3
  static const Color primaryColor = Color(0xFF0284C7); // Xanh dương tươi sáng (Sky Blue 600)
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color mintColor = Color(0xFF10B981); // Xanh Mint tươi mát (Emerald/Mint 500)
  static const Color secondaryColor = mintColor;
  static const Color accentColor = Color(0xFFF59E0B); // Vàng nhạt điểm nhấn (Warm Amber 500)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Trắng sáng dịu mắt (Slate 50)

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: mintColor,
      tertiary: accentColor,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
      titleMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15),
      titleSmall: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 15),
      bodyMedium: TextStyle(color: Color(0xFF1E293B), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF334155), fontSize: 12),
      labelLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: TextStyle(color: Color(0xFF334155), fontSize: 12),
      labelSmall: TextStyle(color: Color(0xFF475569), fontSize: 11),
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15),
      subtitleTextStyle: TextStyle(color: Color(0xFF334155), fontSize: 13),
      iconColor: Color(0xFF334155),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: const Color(0xFF38BDF8),
      secondary: const Color(0xFF34D399),
      tertiary: const Color(0xFFFBBF24),
      surface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF334155),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
