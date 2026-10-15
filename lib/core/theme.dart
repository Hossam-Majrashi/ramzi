import 'package:flutter/material.dart';

/// Ramzi brand seed color (deep indigo-violet).
const brandSeed = Color(0xFF5B5BD6);

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandSeed,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias, elevation: 0),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandSeed,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias, elevation: 0),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
