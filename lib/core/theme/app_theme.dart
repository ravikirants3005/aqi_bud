import 'package:flutter/material.dart';

const Color darkSurface = Color(0xFF060E20);
const Color darkSurfaceContainerLowest = Color(0xFF000000);
const Color darkSurfaceContainerLow = Color(0xFF091328);
const Color darkSurfaceContainer = Color(0xFF0F1930);
const Color darkSurfaceContainerHigh = Color(0xFF141F38);
const Color darkSurfaceContainerHighest = Color(0xFF192540);
const Color darkSurfaceBright = Color(0xFF1F2B49);

const Color darkPrimary = Color(0xFF69F6B8);
const Color darkPrimaryContainer = Color(0xFF06B77F);
const Color darkOnPrimary = Color(0xFF005A3C);

const Color darkSecondary = Color(0xFFF8A010);
const Color darkTertiary = Color(0xFFFF716A);
const Color darkError = Color(0xFFFF716C);

const Color darkOnSurface = Color(0xFFDEE5FF);
const Color darkOnSurfaceVariant = Color(0xFFA3AAC4);
const Color darkOutlineVariant = Color(0xFF40485D);

final ThemeData appDarkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: darkSurface,
    primary: darkPrimary,
    primaryContainer: darkPrimaryContainer,
    onPrimary: darkOnPrimary,
    secondary: darkSecondary,
    tertiary: darkTertiary,
    error: darkError,
    onSurface: darkOnSurface,
    onSurfaceVariant: darkOnSurfaceVariant,
    surfaceContainerLowest: darkSurfaceContainerLowest,
    surfaceContainerLow: darkSurfaceContainerLow,
    surfaceContainer: darkSurfaceContainer,
    surfaceContainerHigh: darkSurfaceContainerHigh,
    surfaceContainerHighest: darkSurfaceContainerHighest,
    outlineVariant: darkOutlineVariant,
  ),
  scaffoldBackgroundColor: darkSurface,
  fontFamily: 'Inter',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: darkOnSurface,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: darkSurfaceContainerLowest,
    selectedItemColor: darkPrimary,
    unselectedItemColor: darkOnSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  useMaterial3: true,
);

final ThemeData appLightTheme = appDarkTheme; // Forcing dark mode for the premium experience as requested.
