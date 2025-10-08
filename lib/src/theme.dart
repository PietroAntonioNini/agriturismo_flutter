import 'package:flutter/material.dart';

/// Tema professionale con palette colori moderna
/// Primary: #1E88E5 (blu) - Accent: #43A047 (verde)
/// Background: #F5F7FA - Warning: #FB8C00 (arancio)
ThemeData buildTheme() {
  const primary = Color(0xFF1E88E5);
  const accent = Color(0xFF43A047);
  const bg = Color(0xFFF5F7FA);

  return ThemeData(
    colorScheme: const ColorScheme.light(primary: primary, secondary: accent),
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    useMaterial3: true,
  );
}
