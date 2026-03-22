/// Material Design 3 theme - REQ 3.1 UI
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final Color _surface = const Color(0xFF060E20);
final Color _primary = const Color(0xFF69F6B8);
final Color _onSurface = const Color(0xFFDEE5FF);

final ThemeData appLightTheme = _buildDarkTheme();
final ThemeData appDarkTheme = _buildDarkTheme();

ThemeData _buildDarkTheme() {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _surface,
    colorScheme: ColorScheme.dark(
      surface: _surface,
      primary: _primary,
      secondary: const Color(0xFFF8A010),
      error: const Color(0xFFFF716A),
      onSurface: _onSurface,
      onPrimary: const Color(0xFF005A3C),
    ),
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          letterSpacing: -2.2,
          color: _onSurface),
      headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: _onSurface),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, height: 1.6, color: _onSurface),
      labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFA3AAC4)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _surface,
      foregroundColor: _onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0F1930),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: const Color(0xFF40485D).withValues(alpha: 0.15)),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: const Color(0xFF005A3C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        elevation: 0,
      ),
    ),
  );
}
