import 'package:flutter/material.dart';

abstract final class CampusColors {
  static const ink = Color(0xFF092A4D);
  static const teal = Color(0xFF008D79);
  static const canvas = Color(0xFFF3FBFF);
  static const mint = Color(0xFFDCF9ED);
  static const lavender = Color(0xFFF0E7FC);
  static const peach = Color(0xFFFFEEDB);
  static const sky = Color(0xFFE1F3FF);
  static const rose = Color(0xFFFFE7EF);
  static const sunshine = Color(0xFFFFF7D7);
  static const blue = Color(0xFF008DDE);
  static const muted = Color(0xFF586878);
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
      textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
      color: states.contains(WidgetState.selected) ? CampusColors.teal : CampusColors.muted,
      size: 27,
    )),
    labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
      color: states.contains(WidgetState.selected) ? CampusColors.teal : CampusColors.muted,
      fontSize: 12, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
    )),
    backgroundColor: Colors.white,
    indicatorColor: CampusColors.mint,
    height: 76,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  ),
);
