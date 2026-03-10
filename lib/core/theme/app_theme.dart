/// Material Design 3 theme - REQ 3.1 UI
library;

import 'package:flutter/material.dart';

final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0D7377),
    brightness: Brightness.light,
    primary: const Color(0xFF0D7377),
    secondary: const Color(0xFF14A3B8),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF14A3B8),
    brightness: Brightness.dark,
    primary: const Color(0xFF14A3B8),
    secondary: const Color(0xFF32E0C4),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
