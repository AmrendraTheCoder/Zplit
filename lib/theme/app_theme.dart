import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'theme_provider.dart';

/// Zplit dynamic theme engine.
///
/// Generates full ThemeData from an [AppThemeMode], supporting
/// Midnight (dark), Arctic (light), and Emerald (dark-green) themes.
class AppTheme {
  AppTheme._();

  /// Generate a ThemeData from the selected theme mode.
  static ThemeData fromMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.midnight => _midnight(),
      AppThemeMode.arctic => _arctic(),
      AppThemeMode.emerald => _emerald(),
    };
  }

  // ── Midnight (Default Dark) ─────────────────────────────
  static ThemeData _midnight() {
    return _buildTheme(
      brightness: Brightness.dark,
      accent: AppColors.primary,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      card: AppColors.cardDark,
      divider: AppColors.dividerDark,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      textTertiary: AppColors.textTertiaryDark,
    );
  }

  // ── Arctic (Light) ─────────────────────────────────────
  static ThemeData _arctic() {
    return _buildTheme(
      brightness: Brightness.light,
      accent: const Color(0xFF3B82F6),
      background: const Color(0xFFF0F4F8),
      surface: Colors.white,
      card: Colors.white,
      divider: const Color(0xFFE2E8F0),
      textPrimary: const Color(0xFF1E293B),
      textSecondary: const Color(0xFF64748B),
      textTertiary: const Color(0xFF94A3B8),
    );
  }

  // ── Emerald (Dark Green) ───────────────────────────────
  static ThemeData _emerald() {
    return _buildTheme(
      brightness: Brightness.dark,
      accent: const Color(0xFF10B981),
      background: const Color(0xFF022C22),
      surface: const Color(0xFF064E3B),
      card: const Color(0xFF065F46),
      divider: const Color(0xFF047857),
      textPrimary: const Color(0xFFECFDF5),
      textSecondary: const Color(0xFF6EE7B7),
      textTertiary: const Color(0xFF34D399),
    );
  }

  // ── Shared builder ─────────────────────────────────────
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color accent,
    required Color background,
    required Color surface,
    required Color card,
    required Color divider,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: Colors.white,
      secondary: isLight ? const Color(0xFF0A84FF) : AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    );

    final textTheme = _buildTextTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }

  // ── Typography ─────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32, fontWeight: FontWeight.w800, color: primary, letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w700, color: primary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700, color: primary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600, color: primary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: primary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600, color: secondary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: primary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: secondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500, color: secondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
