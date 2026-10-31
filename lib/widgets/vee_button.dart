import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'haptics.dart';

/// The game's one button style: a big pill. The main version is deep teal
/// with white text; [outlined] is a cream pill with a teal outline for the
/// second choice. Both squash a little when pressed.
class VeeButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  /// Fill colour of the main version. Text colour is chosen automatically.
  final Color color;
  final bool outlined;
  final IconData? icon;
  final double minWidth;
  final double? maxWidth;
  final EdgeInsets padding;
  final double fontSize;

  const VeeButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = VeeTokens.teal,
    this.outlined = false,
    this.icon,
    this.minWidth = 160,
    this.maxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    this.fontSize = 20,
  });

  /// A slightly darker shade of [color].
  static Color darker(Color color, [double amount = .16]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// A slightly lighter shade of [color].
  static Color lighter(Color color, [double amount = .07]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  State<VeeButton> createState() => _VeeButtonState();
}

class _VeeButtonState extends State<VeeButton> {
  bool _down = false;
  bool _hover = false;

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool value) {
    if (!_enabled || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Color fill;
    final Color foreground;
    final Color? border;
    if (!_enabled) {
      fill = VeeTokens.creamDeep;
      foreground = VeeTokens.textDisabled;
      border = null;
    } else if (widget.outlined) {
      fill = _hover ? VeeTokens.white : VeeTokens.cardWhite;
      foreground = VeeTokens.teal;
      border = VeeTokens.teal;
    } else {
      fill = _hover ? VeeButton.lighter(widget.color, .04) : widget.color;
      foreground = VeeTokens.readableForeground(widget.color);
      border = null;
    }

    final label = DefaultTextStyle.merge(
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      child: widget.child,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
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
          onTap: _enabled
              ? () {
                  Haptics.selection();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _down && !reduceMotion ? .97 : 1,
            duration: Duration(milliseconds: reduceMotion ? 0 : 90),
            child: Container(
              constraints: BoxConstraints(
                minWidth: widget.minWidth,
                maxWidth: widget.maxWidth ?? double.infinity,
              ),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(60),
                border: border == null
                    ? null
                    : Border.all(color: border, width: 3),
                boxShadow: _enabled
                    ? <BoxShadow>[
                        BoxShadow(
                          color: VeeTokens.shadow,
                          blurRadius: _down ? 6 : 16,
                          offset: Offset(0, _down ? 3 : 8),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.icon != null) ...<Widget>[
                      Icon(
                        widget.icon,
                        color: foreground,
                        size: widget.fontSize * 1.35,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(child: label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
