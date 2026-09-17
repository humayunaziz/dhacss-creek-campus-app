import 'package:flutter/material.dart';

abstract final class CampusColors {
  static const ink = Color(0xFF173D3B);
  static const teal = Color(0xFF13786E);
  static const canvas = Color(0xFFF5F6F2);
  static const mint = Color(0xFFE3F2E9);
  static const lavender = Color(0xFFEDE8F7);
  static const peach = Color(0xFFFFEEE0);
  static const muted = Color(0xFF687977);
}

ThemeData campusTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: CampusColors.teal,
    primary: CampusColors.teal,
    surface: Colors.white,
    onSurface: CampusColors.ink,
  ),
  scaffoldBackgroundColor: CampusColors.canvas,
  appBarTheme: const AppBarTheme(
    backgroundColor: CampusColors.canvas,
    foregroundColor: CampusColors.ink,
    elevation: 0,
    centerTitle: false,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.8),
    titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -.4),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE1E7E4))),
    contentPadding: const EdgeInsets.all(18),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: CampusColors.mint,
    height: 76,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  ),
);
