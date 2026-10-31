import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'juicy_tap.dart';

/// The two-leaf logo mark, drawn in code (no image file needed).
class LeafMark extends StatelessWidget {
  final double size;
  const LeafMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: const _LeafMarkPainter(),
    ),
  );
}

class _LeafMarkPainter extends CustomPainter {
  const _LeafMarkPainter();

  Path _leaf(Offset base, Offset tip, double bulge) {
    final mid = Offset.lerp(base, tip, .5)!;
    final dir = tip - base;
    final normal = Offset(-dir.dy, dir.dx) / dir.distance;
    final a = mid + normal * bulge;
    final b = mid - normal * bulge;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(a.dx, a.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(b.dx, b.dy, base.dx, base.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Offset(w * .48, h * .94);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF1E7A4E);
    canvas.drawPath(_leaf(base, Offset(w * .08, h * .34), w * .26), paint);
    paint.color = const Color(0xFF9CCB4A);
    canvas.drawPath(_leaf(base, Offset(w * .92, h * .06), w * .24), paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .5);
    canvas.drawLine(base, Offset(w * .22, h * .45), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A pale circle holding one icon, as used for the menu and sound buttons.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: JuicyTap(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: VeeTokens.softMint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: VeeTokens.teal, size: size * .52),
      ),
    ),
  );
}

/// "Spot • 1 of 3" with progress dots underneath.
class StepPill extends StatelessWidget {
  final String label;
  final int current; // zero-based
  final int total;
  final bool showLeaf;

  const StepPill({
    super.key,
    required this.label,
    required this.current,
    required this.total,
    this.showLeaf = true,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final dotSize = total > 6 ? 10.0 : 14.0;
    return Semantics(
      label: '$label, step ${current + 1} of $total',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: VeeTokens.cardWhite.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: VeeTokens.shadow,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (showLeaf) ...<Widget>[
                    const LeafMark(size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '$label • ${current + 1} of $total',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < total; i++)
                    AnimatedContainer(
                      duration: Duration(milliseconds: reduceMotion ? 0 : 220),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == current ? dotSize + 4 : dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: i < current
                            ? VeeTokens.teal
                            : i == current
                            ? VeeTokens.yellow
                            : const Color(0xFFD8E3D5),
                        borderRadius: BorderRadius.circular(dotSize),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small rounded label such as "Your next clue" (mint) or "Look closer"
/// (coral).
class PillTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final bool showLeaf;
  final double fontSize;

  const PillTag(
    this.text, {
    super.key,
    this.color = VeeTokens.mint,
    this.textColor = VeeTokens.textOnLight,
    this.showLeaf = true,
    this.fontSize = 20,
  });

  /// The bright coral version with white text.
  const PillTag.coral(this.text, {super.key})
    : color = VeeTokens.coral,
      textColor = VeeTokens.textOnDark,
      showLeaf = false,
      fontSize = 20;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showLeaf) ...<Widget>[
          const LeafMark(size: 26),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Three little yellow dashes that burst out, like a "ta-da" mark.
class SparkleDashes extends StatelessWidget {
  final double size;
  final double rotation; // radians
  final Color color;

  const SparkleDashes({
    super.key,
    this.size = 56,
    this.rotation = 0,
    this.color = VeeTokens.yellow,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Transform.rotate(
      angle: rotation,
      child: CustomPaint(size: Size.square(size), painter: _DashPainter(color)),
    ),
  );
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .1;
    final origin = Offset(size.width * .12, size.height * .88);
    for (final degrees in <double>[-75, -40, -5]) {
      final angle = degrees * math.pi / 180;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        origin + dir * (size.width * .5),
        origin + dir * (size.width * .86),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Small helper text that stays readable on top of a busy scene.
class SceneCaption extends StatelessWidget {
  final String text;
  const SceneCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: VeeTokens.cardWhite.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: VeeTokens.textSecondaryOnLight,
      ),
    ),
  );
}

/// A soft cream plaque behind a heading, so dark text stays readable even when
/// it lands on top of a tree or other detailed artwork.
class ScenePlaque extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const ScenePlaque({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: VeeTokens.cardWhite.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(34),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: VeeTokens.shadow,
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}
