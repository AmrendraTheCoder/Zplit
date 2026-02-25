import 'package:flutter/material.dart';

/// Zplit brand color palette.
/// 
/// Designed for a premium expense-splitting app with both
/// light and dark mode support.
class AppColors {
  AppColors._();

  // ── Brand Primary ──────────────────────────────────────
  static const Color primary = Color(0xFF00C48C);
  static const Color primaryLight = Color(0xFF33D4A4);
  static const Color primaryDark = Color(0xFF009B6E);
  static const Color primarySurface = Color(0xFFE6F9F1);

  // ── Secondary / Teal ───────────────────────────────────
  static const Color secondary = Color(0xFF0A84FF);
  static const Color secondaryLight = Color(0xFF4DA3FF);
  static const Color secondaryDark = Color(0xFF0066CC);
  static const Color secondarySurface = Color(0xFFE5F1FF);

  // ── Accent / Orange (warnings, highlights) ─────────────
  static const Color accent = Color(0xFFFF9F43);
  static const Color accentLight = Color(0xFFFFBB70);
  static const Color accentDark = Color(0xFFE68A30);

  // ── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF00C48C);
  static const Color warning = Color(0xFFFF9F43);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF0A84FF);

  // ── Money ──────────────────────────────────────────────
  static const Color moneyOwed = Color(0xFFFF5252);   // You owe
  static const Color moneyOwedTo = Color(0xFF00C48C);  // Others owe you
  static const Color settled = Color(0xFF64B5F6);

  // ── Neutrals (Light Mode) ─────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE8ECF0);
  static const Color textPrimaryLight = Color(0xFF1A1D29);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  // ── Neutrals (Dark Mode) ──────────────────────────────
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color cardDark = Color(0xFF1C2333);
  static const Color dividerDark = Color(0xFF30363D);
  static const Color textPrimaryDark = Color(0xFFF0F6FC);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color textTertiaryDark = Color(0xFF6E7681);

  // ── Avatar Colors ─────────────────────────────────────
  static const List<Color> avatarColors = [
    Color(0xFF00C48C),
    Color(0xFF0A84FF),
    Color(0xFFFF9F43),
    Color(0xFFFF5252),
    Color(0xFF9B59B6),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFFFF7043),
    Color(0xFF5C6BC0),
  ];

  // ── Category Colors ───────────────────────────────────
  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFFF9F43),
    'transport': Color(0xFF0A84FF),
    'entertainment': Color(0xFF9B59B6),
    'shopping': Color(0xFFE91E63),
    'utilities': Color(0xFF00BCD4),
    'rent': Color(0xFF5C6BC0),
    'health': Color(0xFFFF5252),
    'other': Color(0xFF9CA3AF),
  };
}
