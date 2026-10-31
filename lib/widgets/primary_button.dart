import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'vee_button.dart';

/// Kept so older screens still compile. It is the shared main pill button;
/// the [color] argument is accepted but every screen now uses the same teal
/// pill so the whole game looks alike.
class WorldButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;

  const WorldButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = VeeTokens.teal,
  });

  @override
  Widget build(BuildContext context) =>
      VeeButton(onPressed: onPressed, child: child);
}
