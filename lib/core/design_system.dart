import 'package:flutter/material.dart';

/// Design System Constants
/// Centralized design tokens for consistent UI across the app
class DesignSystem {
  DesignSystem._();

  // ═══════════════════════════════════════════════════════════
  // 🎨 COLOR PALETTE
  // ═══════════════════════════════════════════════════════════

  // Background layers (depth hierarchy)
  static const backgroundDeepest = Color(0xFF08080C); // Layer 0: deepest
  static const backgroundBase = Color(0xFF0B0B0F); // Layer 1: scaffold
  static const backgroundSurface = Color(0xFF111118); // Layer 2: surfaces
  static const backgroundElevated = Color(0xFF16161F); // Layer 3: elevated
  static const backgroundRaised = Color(0xFF1C1C26); // Layer 4: raised cards

  // Primary accents (Deep Royal Purple)
  static const primary = Color(0xFF6C4CF1);
  static const primaryLight = Color(0xFF8B6FF7);
  static const primaryDark = Color(0xFF5538D4);
  static const primaryContainer = Color(0xFF1E1545);
  static const primaryOnContainer = Color(0xFFE8DFFF);

  // Secondary accents (Gold)
  static const secondary = Color(0xFFE6C200);
  static const secondaryLight = Color(0xFFFFDB4D);
  static const secondaryDark = Color(0xFFB89C00);
  static const secondaryContainer = Color(0xFF3D3300);
  static const secondaryOnContainer = Color(0xFFFFF3B0);

  // Tertiary accents (Emerald/Teal for success)
  static const tertiary = Color(0xFF10B981);
  static const tertiaryLight = Color(0xFF34D399);
  static const tertiaryDark = Color(0xFF059669);
  static const tertiaryContainer = Color(0xFF064E3B);
  static const tertiaryOnContainer = Color(0xFFD1FAE5);

  // Purple (Premium accent)
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFA78BFA);
  static const purpleDark = Color(0xFF7C3AED);

  // Status colors
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFF34D399);
  static const successContainer = Color(0xFF064E3B);
  static const successOnContainer = Color(0xFFD1FAE5);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFBBF24);
  static const warningContainer = Color(0xFF78350F);
  static const warningOnContainer = Color(0xFFFEF3C7);

  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFF87171);
  static const errorSoft = Color(0xFFFCA5A5);
  static const errorContainer = Color(0xFF7F1D1D);
  static const errorOnContainer = Color(0xFFFEE2E2);

  // Text colors
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFD1D1D6);
  static const textMuted = Color(0xFF8E8E93);
  static const textDisabled = Color(0xFF636366);

  // Chess board colors (premium)
  static const boardLight = Color(0xFFE8EDF4);
  static const boardDark = Color(0xFF7B9AC2);
  static const boardHighlight = Color(0x556366F1);
  static const boardSelected = Color(0x88BBCB2B);
  static const boardLastMove = Color(0x44FBBF24);

  // Utility colors
  static const border = Color(0xFF1E293B);
  static const borderLight = Color(0xFF1E293B);
  static const borderFocus = Color(0xFF334155);
  static const overlay = Color(0x99000000);
  static const scrim = Color(0x80000000);

  // ═══════════════════════════════════════════════════════════
  // 📏 SPACING SCALE
  // ═══════════════════════════════════════════════════════════

  static const spacing0 = 0.0;
  static const spacing2 = 2.0;
  static const spacing4 = 4.0;
  static const spacing6 = 6.0;
  static const spacing8 = 8.0;
  static const spacing10 = 10.0;
  static const spacing12 = 12.0;
  static const spacing14 = 14.0;
  static const spacing16 = 16.0;
  static const spacing18 = 18.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing28 = 28.0;
  static const spacing32 = 32.0;
  static const spacing40 = 40.0;
  static const spacing48 = 48.0;
  static const spacing56 = 56.0;
  static const spacing64 = 64.0;

  // ═══════════════════════════════════════════════════════════
  // 🔲 BORDER RADIUS SCALE
  // ═══════════════════════════════════════════════════════════

  static const radiusNone = 0.0;
  static const radiusXs = 4.0;
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const radius2xl = 24.0;
  static const radius3xl = 28.0;
  static const radiusFull = 9999.0;

  // ═══════════════════════════════════════════════════════════
  // 🌑 SHADOW SYSTEM
  // ═══════════════════════════════════════════════════════════

  static const shadowColor = Color(0x40000000);

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: shadowColor.withAlpha(20),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: shadowColor.withAlpha(30),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowColor.withAlpha(15),
          offset: const Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: shadowColor.withAlpha(40),
          offset: const Offset(0, 8),
          blurRadius: 32,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowColor.withAlpha(20),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  // Glow effects
  static List<BoxShadow> glowPrimary({double intensity = 1.0}) => [
        BoxShadow(
          color: primary.withAlpha((40 * intensity).round()),
          offset: const Offset(0, 0),
          blurRadius: 20 * intensity,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: primary.withAlpha((20 * intensity).round()),
          offset: const Offset(0, 4),
          blurRadius: 12 * intensity,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> glowSuccess({double intensity = 1.0}) => [
        BoxShadow(
          color: success.withAlpha((40 * intensity).round()),
          offset: const Offset(0, 0),
          blurRadius: 20 * intensity,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> glowError({double intensity = 1.0}) => [
        BoxShadow(
          color: error.withAlpha((40 * intensity).round()),
          offset: const Offset(0, 0),
          blurRadius: 20 * intensity,
          spreadRadius: 0,
        ),
      ];

  // ═══════════════════════════════════════════════════════════
  // ⚡ ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════

  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 200);
  static const durationSlow = Duration(milliseconds: 300);

  // Easing curves
  static const curveEaseInOut = Curves.easeInOut;
  static const curveEaseOut = Curves.easeOut;
  static const curveBounce = Curves.elasticOut;

  // Press animation scale
  static const pressScaleNormal = 1.0;
  static const pressScaleActive = 0.97;

  // ═══════════════════════════════════════════════════════════
  // 📐 LAYOUT CONSTANTS
  // ═══════════════════════════════════════════════════════════

  // Screen padding
  static const screenPaddingHorizontal = 20.0;
  static const screenPaddingVertical = 16.0;

  // Card padding
  static const cardPadding = 20.0;
  static const cardPaddingCompact = 16.0;

  // Icon sizes
  static const iconXs = 16.0;
  static const iconSm = 20.0;
  static const iconMd = 24.0;
  static const iconLg = 28.0;
  static const iconXl = 32.0;
  static const icon2xl = 36.0;
  static const icon3xl = 48.0;

  // Chip
  static const chipPaddingH = 12.0;
  static const chipPaddingV = 8.0;
  static const chipHeight = 32.0;
}
