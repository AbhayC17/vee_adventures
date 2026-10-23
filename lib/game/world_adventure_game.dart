import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class WorldAdventureGame extends FlameGame with TapCallbacks {
  int taps = 0;
  double t = 0;
  int revealLevel = 0;
  final void Function(int) onInteraction;

  WorldAdventureGame({required this.onInteraction});

  @override
  void update(double dt) {
    t += dt;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final s = Size(size.x, size.y);
    canvas.drawRect(
      Offset.zero & s,
      Paint()..color = const Color(0xFFEAF7F4),
    );

    _drawGround(canvas, s);
    _drawFireflies(canvas, s);
    _drawFootprints(canvas, s);
    _drawTree(canvas, s);

    if (revealLevel >= 3) _drawTreasure(canvas, s);
    if (revealLevel >= 4) _drawPortal(canvas, s);
  }

  void _drawGround(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFB8D77D);
    c.drawOval(
      Rect.fromLTWH(
        -s.width * .05,
        s.height * .64,
        s.width * 1.1,
        s.height * .5,
      ),
      p,
    );
  }

  void _drawFireflies(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFFFC547);

    for (int i = 0; i < 10; i++) {
      final x = (i + 1) / 11 * s.width;
      final y =
          s.height * (.18 + .18 * ((i * 37) % 10) / 10) +
          12 * math.sin(t * 1.7 + i);
      c.drawCircle(
        Offset(x, y),
        3.0 + 1.2 * math.sin(t * 2 + i),
        p,
      );
    }
  }

  void _drawFootprints(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF6AAE9F);

    for (int i = 0; i < 6; i++) {
      final x = s.width * .24 + i * s.width * .1;
      final y = s.height * .72 - math.sin((t * .7) + i).abs() * 28 - i * 8;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 14,
          height: 8,
        ),
        p,
      );
    }
  }

  void _drawTree(Canvas c, Size s) {
    final trunk = Paint()..color = const Color(0xFF8D5F3A);
    c.drawRect(
      Rect.fromLTWH(
        s.width * .72,
        s.height * .25,
        24,
        s.height * .42,
      ),
      trunk,
    );

    final leaf = Paint()..color = const Color(0xFF82BD57);
    for (final o in [
      Offset(.68, .25),
      Offset(.78, .22),
      Offset(.74, .14),
    ])
      c.drawCircle(
        Offset(s.width * o.dx, s.height * o.dy),
        52,
        leaf,
      );
  }

  void _drawTreasure(Canvas c, Size s) {
    final box = Rect.fromCenter(
      center: Offset(s.width * .52, s.height * .62),
      width: 110,
      height: 70,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(14)),
      Paint()..color = const Color(0xFFF0A33A),
    );
    c.drawRect(
      Rect.fromLTWH(box.center.dx - 7, box.top, 14, box.height),
      Paint()..color = const Color(0xFFFFE08A),
    );
    c.drawCircle(
      Offset(box.center.dx, box.top + box.height / 2),
      7,
      Paint()..color = const Color(0xFF6AB5A1),
    );
  }

  void _drawPortal(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = const Color(0xFF9D8DE2);
    final center = Offset(s.width * .5, s.height * .42);

    c.drawOval(
      Rect.fromCenter(center: center, width: 170, height: 250),
      p,
    );

    for (int i = 1; i < 5; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: center,
          width: 170 + i * 18,
          height: 250 + i * 25,
        ),
        p
          ..color = Color.lerp(
            const Color(0xFF9D8DE2),
            const Color(0xFF4CB9A6),
            i / 5,
          )!,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    taps++;
    onInteraction(taps);
  }
}
