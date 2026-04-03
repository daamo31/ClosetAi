/// app_theme.dart — Sistema de diseño de ClosetAI
/// Material Design 3 con paleta oscura y elegante
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Paleta de colores ──────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF8B5CF6);   // Violeta elegante
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color accent      = Color(0xFFEC4899);   // Rosa moda
  static const Color gold        = Color(0xFFF59E0B);   // Dorado CPW

  // Fondos oscuros
  static const Color bgDark      = Color(0xFF0A0A0F);
  static const Color bgCard      = Color(0xFF13131A);
  static const Color bgSurface   = Color(0xFF1A1A24);
  static const Color bgSurface2  = Color(0xFF22222F);

  // Texto
  static const Color textPrimary   = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFFAAAAAF);
  static const Color textMuted     = Color(0xFF666680);

  // Bordes
  static const Color border      = Color(0xFF2A2A3A);
  static const Color borderLight = Color(0xFF3A3A4A);

  // Estado
  static const Color success = Color(0xFF10B981);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ── Gradientes ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [bgCard, bgSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Sombras ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 30,
      spreadRadius: -5,
    ),
  ];

  // ── ThemeData principal ────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary:       primary,
      secondary:     accent,
      surface:       bgCard,
      error:         error,
      onPrimary:     Colors.white,
      onSecondary:   Colors.white,
      onSurface:     textPrimary,
    ).copyWith(surfaceContainerHighest: bgSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDark,

      // Tipografía Inter
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      // Botones primarios
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // Botones outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Bottom Nav
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgCard,
        indicatorColor: primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: primary, fontSize: 11, fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(color: textMuted, fontSize: 11);
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: bgSurface,
        selectedColor: primary.withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border, thickness: 1, space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgSurface2,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Extensión para usar colores del tema fácilmente
extension AppColors on BuildContext {
  Color get primary     => AppTheme.primary;
  Color get accent      => AppTheme.accent;
  Color get bgDark      => AppTheme.bgDark;
  Color get bgCard      => AppTheme.bgCard;
  Color get bgSurface   => AppTheme.bgSurface;
  Color get textPrimary => AppTheme.textPrimary;
  Color get textMuted   => AppTheme.textMuted;
  Color get border      => AppTheme.border;
  Color get success     => AppTheme.success;
  Color get error       => AppTheme.error;
}
