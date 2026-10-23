import 'package:flutter/material.dart';

/// Central design tokens for Vee's Adventures.
///
/// Keep semantic foreground/background pairs here instead of choosing text
/// colours ad hoc inside screens. Contrast ratios are WCAG relative-luminance
/// ratios and are exercised by `test/theme/contrast_accessibility_test.dart`.
class VeeTokens {
  VeeTokens._();

  // Surfaces
  static const cream = Color(0xFFFFF4D7);
  static const creamDeep = Color(0xFFF5E7B8);
  static const white = Color(0xFFFFFEF9);
  static const mint = Color(0xFFDDF3E7);
  static const paleGreen = Color(0xFFDCE9D1);

  // Brand/accent colours. `teal` is intentionally deep enough to work both
  // as a text accent on pale surfaces and as a button background with white.
  static const sky = Color(0xFF41BFE8);
  static const teal = Color(0xFF176B60);
  static const leaf = Color(0xFF8DCB59);
  static const yellow = Color(0xFFFFC547);
  static const orange = Color(0xFFF08B32);
  static const lilac = Color(0xFF9D8DE2);
  static const peach = Color(0xFFF6A57F);
  static const softPeach = Color(0xFFFFE1D2);
  static const wood = Color(0xFF8C451D);
  static const shadow = Color(0x24000000);

  // Semantic foreground tokens. Use these for text, not decorative accents.
  static const textOnLight = Color(0xFF382719);
  static const textSecondaryOnLight = Color(0xFF5C4332);
  static const textOnDark = Color(0xFFFFFEF9);
  static const textSecondaryOnDark = Color(0xFFF8EBDD);
  static const textOnAccent = Color(0xFFFFFEF9);
  static const textOnWarmButton = Color(0xFF382719);
  static const textDisabled = Color(0xFF5C4332);

  // Compatibility names used throughout the existing app. These aliases
  // deliberately point at readable semantic colours.
  static const ink = textOnLight;
  static const inkSoft = textSecondaryOnLight;

  static const pagePadding = 24.0;
  static const radiusLarge = 28.0;
  static const radiusMedium = 20.0;
  static const radiusSmall = 14.0;

  /// WCAG contrast ratio between two opaque colours (range 1:1 to 21:1).
  static double contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Selects the stronger of the approved light/dark text colours for a solid
  /// background. Dynamic image backgrounds should still use a backplate.
  static Color readableForeground(Color background) {
    final lightRatio = contrastRatio(textOnDark, background);
    final darkRatio = contrastRatio(textOnLight, background);
    return lightRatio >= darkRatio ? textOnDark : textOnLight;
  }
}
