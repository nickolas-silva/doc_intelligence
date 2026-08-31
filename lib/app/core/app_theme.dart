import 'package:flutter/material.dart';

/// Tema visual escuro e sofisticado (Legal Tech) com tons dourados/âmbar.
class AppTheme {
  // Cores Primárias — Dourado / Âmbar
  static const Color primary = Color(0xFFD4A843); // Dourado principal
  static const Color primaryDark = Color(0xFFB8922E); // Dourado escuro
  static const Color accent = Color(0xFFE8C268); // Dourado claro / destaque
  static const Color accentLight = Color(0xFFF0D68A);
  static const Color accentSubtle = Color(0xFF2A2518); // Dourado muito sutil sobre fundo escuro

  // Superfícies e Fundos — Escuros
  static const Color background = Color(0xFF0E0E10); // Quase preto
  static const Color surface = Color(0xFF18181B); // Zinc 900
  static const Color surfaceMuted = Color(0xFF1F1F23); // Surface elevada
  static const Color border = Color(0xFF2E2E33); // Borda sutil
  static const Color borderSubtle = Color(0xFF252529);

  // Textos
  static const Color textPrimary = Color(0xFFF4F4F5); // Zinc 100
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textMuted = Color(0xFF71717A); // Zinc 500

  // Status & Badges
  static const Color success = Color(0xFF4ADE80); // Verde claro
  static const Color successBg = Color(0xFF14291E);
  static const Color warning = Color(0xFFFBBF24); // Âmbar
  static const Color warningBg = Color(0xFF2A2310);
  static const Color danger = Color(0xFFF87171); // Vermelho claro
  static const Color dangerBg = Color(0xFF2A1515);
  static const Color info = Color(0xFF38BDF8); // Azul claro
  static const Color infoBg = Color(0xFF0C1F2E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: danger,
        onPrimary: Color(0xFF0E0E10),
        onSecondary: Color(0xFF0E0E10),
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0E0E10),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceMuted),
        headingTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        dataTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerThickness: 1,
        horizontalMargin: 20,
        columnSpacing: 24,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceMuted,
        contentTextStyle: TextStyle(color: textPrimary),
      ),
    );
  }
}