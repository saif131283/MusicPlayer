import 'package:flutter/material.dart';

abstract final class AppTheme {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF242424);
  static const Color accent = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF888888);
  static const Color divider = Color(0xFF2C2C2C);

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        cardColor: card,
        dividerColor: divider,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),

        // Text
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: textPrimary),
          titleSmall: TextStyle(color: textSecondary),
        ),

        // Icons
        iconTheme: const IconThemeData(color: textPrimary),

        // Slider
        sliderTheme: const SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: divider,
          thumbColor: accent,
          overlayColor: Color(0x33FF6B35),
          trackHeight: 3,
        ),

        // Tab bar
        tabBarTheme: const TabBarThemeData(
          labelColor: accent,
          unselectedLabelColor: textSecondary,
          indicatorColor: accent,
        ),

        // BottomSheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),

        // Input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          hintStyle: const TextStyle(color: textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Floating action button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          titleTextStyle:
              const TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: const TextStyle(color: textSecondary, fontSize: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}
