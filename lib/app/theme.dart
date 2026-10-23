import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Global visual system for Vee's Adventures.
///
/// Fredoka is bundled inside the Flutter application, so the
/// game uses the same typography on Windows, Chrome, Android,
/// iOS and other supported targets.
ThemeData buildVeeTheme() {
  const family = 'Fredoka';

  const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: family,
      fontSize: 54,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.0,
      letterSpacing: -0.8,
    ),
    displayMedium: TextStyle(
      fontFamily: family,
      fontSize: 46,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.04,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontFamily: family,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.06,
    ),
    headlineLarge: TextStyle(
      fontFamily: family,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.08,
    ),
    headlineMedium: TextStyle(
      fontFamily: family,
      fontSize: 31,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.1,
    ),
    headlineSmall: TextStyle(
      fontFamily: family,
      fontSize: 27,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.12,
    ),
    titleLarge: TextStyle(
      fontFamily: family,
      fontSize: 25,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.14,
    ),
    titleMedium: TextStyle(
      fontFamily: family,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: VeeTokens.textOnLight,
      height: 1.15,
    ),
    titleSmall: TextStyle(
      fontFamily: family,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: VeeTokens.textOnLight,
      height: 1.16,
    ),
    bodyLarge: TextStyle(
      fontFamily: family,
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: VeeTokens.textSecondaryOnLight,
      height: 1.3,
    ),
    bodyMedium: TextStyle(
      fontFamily: family,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: VeeTokens.textSecondaryOnLight,
      height: 1.28,
    ),
    bodySmall: TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: VeeTokens.textSecondaryOnLight,
      height: 1.25,
    ),
    labelLarge: TextStyle(
      fontFamily: family,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: VeeTokens.textOnLight,
      height: 1.1,
    ),
    labelMedium: TextStyle(
      fontFamily: family,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: VeeTokens.textOnLight,
      height: 1.1,
    ),
    labelSmall: TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: VeeTokens.textOnLight,
      height: 1.1,
    ),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: VeeTokens.teal,
    brightness: Brightness.light,
    surface: VeeTokens.cream,
  ).copyWith(
    primary: VeeTokens.teal,
    onPrimary: VeeTokens.textOnAccent,
    secondary: VeeTokens.yellow,
    onSecondary: VeeTokens.textOnWarmButton,
    surface: VeeTokens.cream,
    onSurface: VeeTokens.textOnLight,
    error: const Color(0xFF9B2C2C),
    onError: VeeTokens.textOnDark,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: VeeTokens.cream,
    dividerColor: const Color(0xFFD9C9AA),
    disabledColor: VeeTokens.textDisabled,
    colorScheme: colorScheme,

    // THIS makes Fredoka the default application font.
    fontFamily: family,

    textTheme: textTheme,
    primaryTextTheme: textTheme,

    visualDensity: VisualDensity.standard,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VeeTokens.white,

      hintStyle: const TextStyle(
        fontFamily: family,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: VeeTokens.textSecondaryOnLight,
      ),

      labelStyle: const TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: VeeTokens.textSecondaryOnLight,
      ),

      floatingLabelStyle: const TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: VeeTokens.teal,
      ),
      errorStyle: const TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9B2C2C),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: VeeTokens.teal,
          width: 2.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: VeeTokens.orange,
          width: 2.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 20,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 58),
        padding: const EdgeInsets.symmetric(
          horizontal: 26,
          vertical: 15,
        ),
        textStyle: const TextStyle(
          fontFamily: family,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VeeTokens.teal,
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(
          fontFamily: family,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: VeeTokens.mint,
      selectedColor: VeeTokens.creamDeep,
      secondaryLabelStyle: const TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: VeeTokens.textOnLight,
      ),
      labelStyle: const TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: VeeTokens.textOnLight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}