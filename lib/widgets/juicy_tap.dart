import 'package:flutter/material.dart';

import 'haptics.dart';

/// A tappable wrapper that reacts the instant a finger touches it.
///
/// Plain GestureDetector + Container buttons give no feedback until the finger
/// lifts, which makes a game feel laggy to a small child even when the code is
/// fast. JuicyTap squishes on touch-down and pops back on release, and gives a
/// light haptic tick where the device supports it.
///
/// Usage: replace `GestureDetector(onTap: ..., child: Container(...))` with
/// `JuicyTap(onTap: ..., child: Container(...))`.
///
/// Respects the system "reduce motion" setting. Uses only Flutter built-ins.
class JuicyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Scale while the finger is down. 1.0 disables the squish.
  final double pressedScale;

  /// Light haptic tick on tap. No effect on platforms without haptics.
  final bool haptic;

  /// Screen-reader label. Leave null when the child already contains text.
  final String? semanticLabel;

  const JuicyTap({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.92,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<JuicyTap> createState() => _JuicyTapState();
}

class _JuicyTapState extends State<JuicyTap> {
  bool _down = false;
  bool _hover = false;

  bool get _enabled => widget.onTap != null;

  void _setDown(bool value) {
    if (!_enabled || _down == value) return;
    setState(() => _down = value);
  }

  void _handleTap() {
    final onTap = widget.onTap;
    if (onTap == null) return;
    if (widget.haptic) Haptics.selection();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget content = widget.child;
    if (!reduceMotion) {
      content = AnimatedScale(
        scale: _down ? widget.pressedScale : (_hover ? 1.04 : 1.0),
        // Quick squish down, slightly slower overshoot back up.
        duration: Duration(milliseconds: _down ? 80 : 260),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) {
          if (_enabled && !_hover) setState(() => _hover = true);
        },
        onExit: (_) {
          if (_hover) setState(() => _hover = false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setDown(true),
          onTapUp: (_) => _setDown(false),
          onTapCancel: () => _setDown(false),
          onTap: _enabled ? _handleTap : null,
          child: content,
        ),
      ),
    );
  }
}
