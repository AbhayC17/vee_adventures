import 'package:flutter/material.dart';

/// Central design tokens for the game (storybook look: warm cream, deep teal, sunny yellow).
///
/// Keep semantic foreground/background pairs here instead of choosing text
/// colours ad hoc inside screens. Contrast ratios are WCAG relative-luminance
/// ratios and are exercised by `test/theme/contrast_accessibility_test.dart`.
class VeeTokens {
  VeeTokens._();

  // Surfaces
  static const cream = Color(0xFFFDF6E6);
  static const creamDeep = Color(0xFFEADFC3);
  static const white = Color(0xFFFFFEF9);
  static const mint = Color(0xFFDDEFD9);
  static const paleGreen = Color(0xFFDCE9D1);

  // Brand/accent colours. `teal` is intentionally deep enough to work both
  // as a text accent on pale surfaces and as a button background with white.
  static const sky = Color(0xFF41BFE8);
  static const teal = Color(0xFF0F5F55);
  static const leaf = Color(0xFF8DCB59);
  static const yellow = Color(0xFFFFC62E);
  static const orange = Color(0xFFF5963F);
  static const lilac = Color(0xFFAB9CEB);
  static const peach = Color(0xFFF6A57F);
  static const softPeach = Color(0xFFFFE1D2);
  static const wood = Color(0xFF8C451D);

  // Added for the storybook look: a coral tag colour, the pale circle used
  // behind icon buttons, and a few scene greens.
  static const coral = Color(0xFFE65A3C);
  static const softMint = Color(0xFFE3EEE5);
  static const cardWhite = Color(0xFFFFFDF6);
  static const forest = Color(0xFF2F7F5B);
  static const meadow = Color(0xFF7DB85A);
  // A soft green-brown shadow looks friendlier than neutral black.
  static const shadow = Color(0x2E1F4A3A);

  // Semantic foreground tokens. Use these for text, not decorative accents.
  static const textOnLight = Color(0xFF08403A);
  static const textSecondaryOnLight = Color(0xFF3A6B62);
  static const textOnDark = Color(0xFFFFFEF9);
  static const textSecondaryOnDark = Color(0xFFF8EBDD);
  static const textOnAccent = Color(0xFFFFFEF9);
  static const textOnWarmButton = Color(0xFF382719);
  static const textDisabled = Color(0xFF3A6B62);

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
