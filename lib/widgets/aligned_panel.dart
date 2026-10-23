import 'package:flutter/material.dart';

/// Keeps child-facing content neatly aligned inside a visual panel.
///
/// Use this around text/cards that sit on artwork or wooden boards instead
/// of positioning text with hard-coded left/top offsets.
class AlignedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const AlignedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    this.maxWidth = 760,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: Center(
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
