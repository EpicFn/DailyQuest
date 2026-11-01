import 'package:flutter/material.dart';

class QuestTheme {
  static const background = Color(0xFF11101B);
  static const surface = Color(0xFF1D1B2C);
  static const purple = Color(0xFFB9A3FF);
  static const lime = Color(0xFFD4F59A);
  static const muted = Color(0xFFB6B1C9);
  static const border = Color(0xFF363147);

  static ThemeData get data {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF8359F5),
          brightness: Brightness.dark,
        ).copyWith(
          primary: purple,
          onPrimary: const Color(0xFF26134E),
          primaryContainer: const Color(0xFF38265F),
          onPrimaryContainer: const Color(0xFFEBDDFF),
          secondary: lime,
          onSecondary: const Color(0xFF24330F),
          surface: surface,
          onSurface: const Color(0xFFF5F1FF),
          onSurfaceVariant: muted,
          outlineVariant: border,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 76,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? purple : muted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
