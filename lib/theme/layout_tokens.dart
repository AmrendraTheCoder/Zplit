import 'dart:ui';

import 'package:flutter/material.dart';

/// Layout Tokens — the core of Zplit's modular theme engine.
///
/// Goes beyond standard Material theming by defining **spatial** and
/// **structural** tokens that can vary per theme. Widgets consume these
/// via `Theme.of(context).extension<LayoutTokens>()`, keeping all
/// layout logic out of feature code.
///
/// ## Architecture (3-Layer Theme Engine)
///
/// ```
/// ┌────────────────────────────────────┐
/// │   ThemeBloc / ThemeNotifier         │  ← State Layer
/// │   (active theme ID + persistence)  │
/// ├────────────────────────────────────┤
/// │   LayoutTokens (ThemeExtension)     │  ← Token Layer ★
/// │   (spacing, radii, padding, etc.)  │
/// ├────────────────────────────────────┤
/// │   Widgets consume tokens           │  ← Component Layer
/// │   Theme.of(context).extension<>()  │
/// └────────────────────────────────────┘
/// ```
///
/// Each theme (Midnight, Arctic, Emerald) provides its own token values,
/// enabling completely different visual densities and border treatments
/// without changing any widget code.
class LayoutTokens extends ThemeExtension<LayoutTokens> {
  // ── Spacing ──────────────────────────────────────────
  /// Extra-small spacing (e.g. between icon and label).
  final double spacingXs;

  /// Small spacing (e.g. between list items).
  final double spacingSm;

  /// Medium spacing (e.g. section padding).
  final double spacingMd;

  /// Large spacing (e.g. between major sections).
  final double spacingLg;

  /// Extra-large spacing (e.g. screen-level vertical padding).
  final double spacingXl;

  // ── Border Radius ────────────────────────────────────
  /// Small radius (e.g. chips, tags).
  final double radiusSm;

  /// Medium radius (e.g. cards, buttons).
  final double radiusMd;

  /// Large radius (e.g. bottom sheets, dialogs).
  final double radiusLg;

  /// Full/pill radius (e.g. FAB, avatar badges).
  final double radiusFull;

  // ── Padding ──────────────────────────────────────────
  /// Card internal padding.
  final EdgeInsets cardPadding;

  /// Screen-level horizontal padding.
  final EdgeInsets screenPadding;

  /// List tile content padding.
  final EdgeInsets tilePadding;

  // ── Elevation ────────────────────────────────────────
  /// Card default elevation.
  final double cardElevation;

  /// Modal/dialog elevation.
  final double modalElevation;

  // ── Container ────────────────────────────────────────
  /// Maximum content width (for responsive layouts).
  final double maxContentWidth;

  /// Default icon size in list contexts.
  final double iconSizeMd;

  /// Avatar size for member lists.
  final double avatarRadius;

  const LayoutTokens({
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusFull,
    required this.cardPadding,
    required this.screenPadding,
    required this.tilePadding,
    required this.cardElevation,
    required this.modalElevation,
    required this.maxContentWidth,
    required this.iconSizeMd,
    required this.avatarRadius,
  });

  // ────────────────────────────────────────────────────
  // THEME FACTORIES
  // ────────────────────────────────────────────────────

  /// **Midnight** — Spacious premium dark layout.
  /// Larger radii, generous padding, higher contrast.
  factory LayoutTokens.midnight() {
    return const LayoutTokens(
      spacingXs: 4,
      spacingSm: 8,
      spacingMd: 16,
      spacingLg: 24,
      spacingXl: 32,
      radiusSm: 8,
      radiusMd: 16,
      radiusLg: 24,
      radiusFull: 999,
      cardPadding: EdgeInsets.all(16),
      screenPadding: EdgeInsets.symmetric(horizontal: 20),
      tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      cardElevation: 0,
      modalElevation: 8,
      maxContentWidth: 600,
      iconSizeMd: 24,
      avatarRadius: 20,
    );
  }

  /// **Arctic** — Crisp, compact light layout.
  /// Tighter spacing for data density, subtle shadows.
  factory LayoutTokens.arctic() {
    return const LayoutTokens(
      spacingXs: 4,
      spacingSm: 6,
      spacingMd: 12,
      spacingLg: 20,
      spacingXl: 28,
      radiusSm: 6,
      radiusMd: 12,
      radiusLg: 20,
      radiusFull: 999,
      cardPadding: EdgeInsets.all(14),
      screenPadding: EdgeInsets.symmetric(horizontal: 16),
      tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      cardElevation: 1,
      modalElevation: 4,
      maxContentWidth: 600,
      iconSizeMd: 22,
      avatarRadius: 18,
    );
  }

  /// **Emerald** — Nature-inspired, medium density.
  /// Balanced spacing with organic rounded shapes.
  factory LayoutTokens.emerald() {
    return const LayoutTokens(
      spacingXs: 4,
      spacingSm: 8,
      spacingMd: 14,
      spacingLg: 22,
      spacingXl: 30,
      radiusSm: 10,
      radiusMd: 18,
      radiusLg: 26,
      radiusFull: 999,
      cardPadding: EdgeInsets.all(16),
      screenPadding: EdgeInsets.symmetric(horizontal: 18),
      tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      cardElevation: 0,
      modalElevation: 6,
      maxContentWidth: 600,
      iconSizeMd: 24,
      avatarRadius: 20,
    );
  }

  // ────────────────────────────────────────────────────
  // ThemeExtension overrides
  // ────────────────────────────────────────────────────

  @override
  LayoutTokens copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusFull,
    EdgeInsets? cardPadding,
    EdgeInsets? screenPadding,
    EdgeInsets? tilePadding,
    double? cardElevation,
    double? modalElevation,
    double? maxContentWidth,
    double? iconSizeMd,
    double? avatarRadius,
  }) {
    return LayoutTokens(
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusFull: radiusFull ?? this.radiusFull,
      cardPadding: cardPadding ?? this.cardPadding,
      screenPadding: screenPadding ?? this.screenPadding,
      tilePadding: tilePadding ?? this.tilePadding,
      cardElevation: cardElevation ?? this.cardElevation,
      modalElevation: modalElevation ?? this.modalElevation,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
      iconSizeMd: iconSizeMd ?? this.iconSizeMd,
      avatarRadius: avatarRadius ?? this.avatarRadius,
    );
  }

  @override
  LayoutTokens lerp(covariant LayoutTokens? other, double t) {
    if (other == null) return this;
    return LayoutTokens(
      spacingXs: lerpDouble(spacingXs, other.spacingXs, t) ?? spacingXs,
      spacingSm: lerpDouble(spacingSm, other.spacingSm, t) ?? spacingSm,
      spacingMd: lerpDouble(spacingMd, other.spacingMd, t) ?? spacingMd,
      spacingLg: lerpDouble(spacingLg, other.spacingLg, t) ?? spacingLg,
      spacingXl: lerpDouble(spacingXl, other.spacingXl, t) ?? spacingXl,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
      radiusFull: lerpDouble(radiusFull, other.radiusFull, t) ?? radiusFull,
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      screenPadding: EdgeInsets.lerp(screenPadding, other.screenPadding, t)!,
      tilePadding: EdgeInsets.lerp(tilePadding, other.tilePadding, t)!,
      cardElevation:
          lerpDouble(cardElevation, other.cardElevation, t) ?? cardElevation,
      modalElevation:
          lerpDouble(modalElevation, other.modalElevation, t) ?? modalElevation,
      maxContentWidth:
          lerpDouble(maxContentWidth, other.maxContentWidth, t) ??
          maxContentWidth,
      iconSizeMd: lerpDouble(iconSizeMd, other.iconSizeMd, t) ?? iconSizeMd,
      avatarRadius:
          lerpDouble(avatarRadius, other.avatarRadius, t) ?? avatarRadius,
    );
  }
}
