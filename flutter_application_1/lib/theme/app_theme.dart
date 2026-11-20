import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFFF8F7F3);
  static const green = Color(0xFF315C47);
  static const ink = Color(0xFF27312C);
  static const muted = Color(0xFF84908A);
  static const border = Color(0xFFE1E5DF);
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(seedColor: green)
        .copyWith(primary: green, surface: background, onSurface: ink),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: green,
        textStyle: const TextStyle(fontSize: 13),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintStyle: const TextStyle(color: muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: green),
      ),
    ),
  );
}
