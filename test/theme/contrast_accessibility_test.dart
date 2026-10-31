import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/app/design_tokens.dart';
import 'package:vees_adventures/app/theme.dart';

void main() {
  group("Movement Missions contrast design system", () {
    test('normal text pairs meet WCAG AA (4.5:1)', () {
      const lightSurfaces = <Color>[
        VeeTokens.cream,
        VeeTokens.creamDeep,
        VeeTokens.white,
        VeeTokens.mint,
        VeeTokens.paleGreen,
        VeeTokens.softMint,
        VeeTokens.cardWhite,
        VeeTokens.yellow,
        VeeTokens.sky,
        VeeTokens.leaf,
        VeeTokens.orange,
        VeeTokens.peach,
        VeeTokens.lilac,
        Color(0xFFFFB49B),
        Color(0xFFAEDB7A),
        Color(0xFFA6C6F3),
      ];

      for (final background in lightSurfaces) {
        final ratio = VeeTokens.contrastRatio(
          VeeTokens.textOnLight,
          background,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'Dark text must pass on light surface $background (ratio $ratio)',
        );
      }

      for (final background in <Color>[
        VeeTokens.cream,
        VeeTokens.white,
        VeeTokens.mint,
      ]) {
        final ratio = VeeTokens.contrastRatio(
          VeeTokens.textSecondaryOnLight,
          background,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'Secondary text must pass on light surface $background (ratio $ratio)',
        );
      }
    });

    test('light text pairs meet WCAG AA on dark surfaces', () {
      const darkSurfaces = <Color>[
        VeeTokens.teal,
        VeeTokens.textOnLight,
        VeeTokens.wood,
        Color(0xFF65452F),
        Color(0xFF26384A),
        Color(0xFF53634A),
      ];

      for (final background in darkSurfaces) {
        final ratio = VeeTokens.contrastRatio(VeeTokens.textOnDark, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'Light text must pass on dark surface $background (ratio $ratio)',
        );
      }
    });

    test('white text on the coral tag passes the large-text bar (3:1)', () {
      // The tag text is 20px bold, which WCAG treats as large text.
      expect(
        VeeTokens.contrastRatio(VeeTokens.textOnDark, VeeTokens.coral),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('brand text accent passes on approved pale surfaces', () {
      for (final background in <Color>[
        VeeTokens.cream,
        VeeTokens.white,
        VeeTokens.mint,
        VeeTokens.creamDeep,
      ]) {
        final ratio = VeeTokens.contrastRatio(VeeTokens.teal, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'Teal text must pass on approved pale surface $background (ratio $ratio)',
        );
      }
    });

    test('global text theme remains readable on the default cream surface', () {
      final theme = buildVeeTheme();
      final styles = <TextStyle?>[
        theme.textTheme.displayLarge,
        theme.textTheme.displayMedium,
        theme.textTheme.displaySmall,
        theme.textTheme.headlineLarge,
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.titleSmall,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.textTheme.labelMedium,
        theme.textTheme.labelSmall,
      ];

      for (final style in styles) {
        final foreground = style?.color ?? theme.colorScheme.onSurface;
        final ratio = VeeTokens.contrastRatio(foreground, VeeTokens.cream);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'Unreadable text style: $style ($ratio)',
        );
      }
    });

    test(
      'automatic foreground selects readable text for common button colours',
      () {
        expect(
          VeeTokens.readableForeground(VeeTokens.teal),
          VeeTokens.textOnDark,
        );
        expect(
          VeeTokens.readableForeground(VeeTokens.yellow),
          VeeTokens.textOnLight,
        );
        expect(
          VeeTokens.readableForeground(VeeTokens.cream),
          VeeTokens.textOnLight,
        );
      },
    );
  });
}
