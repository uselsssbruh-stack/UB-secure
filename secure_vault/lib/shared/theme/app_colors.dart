import 'package:flutter/material.dart';

/// Theme-reactive color palette.
///
/// Instead of using a static `brightness` field (which has stale-value issues
/// during theme switches), every getter reads brightness from the nearest
/// [Theme] via the [BuildContext] passed to [of].
///
/// Usage:  `AppColors.of(context).textPrimary`
///
/// For the handful of places that truly need a static constant (gradients
/// defined outside a build method, for example), the old `AppColors.xxx`
/// static constants are still available for accent / category colors that
/// don't change between light and dark.
class AppColors {
  final Brightness brightness;
  const AppColors._(this.brightness);

  /// Main factory — call this inside `build()`.
  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  // Primary palette
  Color get backgroundDark => isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC);
  Color get surfaceDark => isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  Color get surfaceLight => isDark ? const Color(0xFF1C2333) : const Color(0xFFF1F5F9);
  Color get cardDark => isDark ? const Color(0xFF21283B) : const Color(0xFFFFFFFF);
  Color get cardHover => isDark ? const Color(0xFF2A3247) : const Color(0xFFF8FAFC);

  // Text
  Color get textPrimary => isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFF8B949E) : const Color(0xFF475569);
  Color get textMuted => isDark ? const Color(0xFF484F58) : const Color(0xFF94A3B8);

  // Borders
  Color get border => isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0);
  Color get borderLight => isDark ? const Color(0xFF3D444D) : const Color(0xFFCBD5E1);

  // Glassmorphism
  Color get glassBackground => isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02);
  Color get glassBorder => isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

  // ── Static accent colors (same in both themes) ──
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentGold = Color(0xFFFFB800);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category colors
  static const Color passwordColor = accentCyan;
  static const Color cardColor = accentGold;
  static const Color identityColor = accentPurple;
  static const Color noteColor = accentGreen;
  static const Color fileColor = accentPink;
}
