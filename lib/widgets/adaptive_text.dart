import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Contrast helpers for text on known, solid-colour surfaces.
///
/// Do not place essential text directly over an unfiltered image or texture.
/// Put it on an opaque/near-opaque card first; selecting a single foreground
/// cannot guarantee contrast against every pixel in a photograph.
class VeeTextContrast {
  VeeTextContrast._();

  static Color foregroundFor(Color background) =>
      VeeTokens.readableForeground(background);

  static TextStyle overBackground(
    BuildContext context, {
    required Color background,
    TextStyle? base,
  }) {
    final style = base ?? DefaultTextStyle.of(context).style;
    final foreground = foregroundFor(background);
    return style.copyWith(
      color: foreground,
      shadows: const [],
      decorationColor: foreground,
    );
  }

  static ThemeData readableTheme(
    BuildContext context, {
    required Color background,
  }) {
    final base = Theme.of(context);
    final foreground = foregroundFor(background);
    final textTheme = base.textTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
      decorationColor: foreground,
    );
    return base.copyWith(textTheme: textTheme, primaryTextTheme: textTheme);
  }
}

/// Reusable text for a known solid surface. For photographic or busy artwork,
/// render this widget inside a solid card/overlay rather than sampling pixels.
class AdaptiveVeeText extends StatelessWidget {
  final String text;
  final Color background;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const AdaptiveVeeText(
    this.text, {
    super.key,
    required this.background,
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: VeeTextContrast.overBackground(
          context,
          background: background,
          base: style,
        ),
      );
}
