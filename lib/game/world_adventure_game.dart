import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../widgets/haptics.dart';

/// Vee's living meadow.
///
/// A small Flame scene drawn entirely with Canvas (no image files). Every part
/// of it reacts to a tap, and a tap on empty space still makes sparkles, so a
/// child always gets an answer:
///
/// * fireflies pop into stars that can be collected,
/// * butterflies swirl away,
/// * the tree rustles and drops leaves,
/// * flowers bloom,
/// * the sun, clouds, treasure chest and portal all have a little reaction,
/// * now and then a shooting star crosses the sky.
///
/// [revealLevel] makes the world grow as the child collects more: from level 3
/// a treasure chest appears and from level 4 a magic portal.
///
/// Keep this class cheap: paints are reused, particles are capped, and nothing
/// is allocated in a way that grows over time.
class WorldAdventureGame extends FlameGame with TapCallbacks {
  /// Total taps so far (kept from the original game class).
  int taps = 0;

  /// Seconds since the scene started, used for gentle animation.
  double t = 0;

  /// 0–4. See the class comment.
  int revealLevel;

  /// How many stars (popped fireflies, shooting stars, chests) were caught.
  int starsCaught = 0;

  final void Function(int) onInteraction;
  final void Function(int)? onStarCaught;

  final math.Random _rng;

  WorldAdventureGame({
    required this.onInteraction,
    this.onStarCaught,
    this.revealLevel = 0,
    math.Random? random,
  }) : _rng = random ?? math.Random() {
    _populate();
  }

  // ── scene state ────────────────────────────────────────────────────────

  static const int _maxParticles = 140;

  static final Path _unitStar = _buildUnitStar();

  static Path _buildUnitStar() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? 1.0 : 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  final Paint _p = Paint();
  Paint _skyPaint = Paint();

  double _w = 0;
  double _h = 0;

  final List<_Cloud> _clouds = <_Cloud>[];
  final List<_Firefly> _flies = <_Firefly>[];
  final List<_Butterfly> _butterflies = <_Butterfly>[];
  final List<_Flower> _flowers = <_Flower>[];
  final List<_Particle> _particles = <_Particle>[];

  double _sunPulse = 0;
  double _treeWobble = 0;
  double _chestOpen = 0;
  double _chestTimer = 0;
  double _portalPulse = 0;

  double _nextShoot = 7;
  _Shoot? _shoot;

  double _celebrateLeft = 0;
  double _confettiAcc = 0;

  /// Number of particles currently alive (useful for tests).
  int get activeParticles => _particles.length;

  /// Where the visible fireflies are right now (used by tests to aim taps).
  List<Offset> get fireflyPositions => <Offset>[
    for (final fly in _flies)
      if (!fly.popped) _flyPosition(fly),
  ];

  void _populate() {
    for (var i = 0; i < 3; i++) {
      _clouds.add(
        _Cloud(
          x: .12 + i * .34 + _rng.nextDouble() * .08,
          y: .08 + _rng.nextDouble() * .13,
          scale: .8 + _rng.nextDouble() * .5,
          speed: .004 + _rng.nextDouble() * .006,
        ),
      );
    }
    for (var i = 0; i < 8; i++) {
      _flies.add(
        _Firefly(
          nx: .1 + _rng.nextDouble() * .8,
          ny: .2 + _rng.nextDouble() * .35,
          phase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }
    const butterflyColors = <Color>[
      VeeTokens.peach,
      VeeTokens.lilac,
      VeeTokens.sky,
    ];
    for (var i = 0; i < 3; i++) {
      _butterflies.add(
        _Butterfly(
          phase: _rng.nextDouble() * math.pi * 2,
          speed: .7 + _rng.nextDouble() * .5,
          color: butterflyColors[i],
        ),
      );
    }
    const flowerColors = <Color>[
      VeeTokens.peach,
      VeeTokens.yellow,
      VeeTokens.lilac,
      VeeTokens.orange,
      VeeTokens.sky,
      VeeTokens.peach,
    ];
    for (var i = 0; i < 6; i++) {
      _flowers.add(
        _Flower(
          nx: .08 + i * .105 + _rng.nextDouble() * .03,
          ny: .74 + _rng.nextDouble() * .17,
          color: flowerColors[i],
        ),
      );
    }
  }

  /// Starts a confetti and star celebration (used on the reward screen).
  void celebrate() {
    _celebrateLeft = 2.2;
  }

  // ── size handling ──────────────────────────────────────────────────────

  /// Reads the game size defensively; it is not available before layout.
  bool _syncSize() {
    double width;
    double height;
    try {
      width = size.x;
      height = size.y;
    } catch (_) {
      return false;
    }
    if (width <= 0 || height <= 0) return false;
    if (width != _w || height != _h) {
      _w = width;
      _h = height;
      _skyPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFEAF4EE), VeeTokens.cream],
        ).createShader(Rect.fromLTWH(0, 0, width, height));
    }
    return true;
  }

  // ── update ─────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    // After a long pause (tab switch) dt can be huge; never jump the scene.
    final step = dt > .05 ? .05 : dt;
    t += step;
    if (!_syncSize()) return;

    for (final cloud in _clouds) {
      cloud.x += cloud.speed * step;
      if (cloud.x > 1.25) cloud.x = -.25;
      cloud.puff = math.max(0, cloud.puff - step * 2.2);
    }
    for (final fly in _flies) {
      if (fly.popped && t >= fly.respawnAt) {
        fly.popped = false;
        fly.nx = .1 + _rng.nextDouble() * .8;
        fly.ny = .2 + _rng.nextDouble() * .35;
      }
    }
    for (final butterfly in _butterflies) {
      butterfly.boost = math.max(0, butterfly.boost - step * .6);
      butterfly.travel += step * butterfly.speed * (1 + butterfly.boost * 2.5);
    }
    for (final flower in _flowers) {
      final target = flower.open ? 1.0 : .35;
      flower.bloom += (target - flower.bloom) * math.min(1.0, step * 7);
    }

    _sunPulse = math.max(0, _sunPulse - step * 1.6);
    _treeWobble = math.max(0, _treeWobble - step * 1.1);
    _portalPulse = math.max(0, _portalPulse - step * 1.2);
    if (_chestOpen > 0) {
      _chestTimer -= step;
      if (_chestTimer <= 0) _chestOpen = math.max(0, _chestOpen - step * 2);
    }

    _updateShootingStar(step);
    _updateCelebration(step);
    _updateParticles(step);
  }

  void _updateShootingStar(double step) {
    final shoot = _shoot;
    if (shoot == null) {
      _nextShoot -= step;
      if (_nextShoot <= 0) {
        _shoot = _Shoot(
          x: -_w * .05,
          y: _h * (.06 + _rng.nextDouble() * .16),
          vx: _w * .42,
          vy: _h * .14,
        );
      }
      return;
    }
    shoot.x += shoot.vx * step;
    shoot.y += shoot.vy * step;
    if (shoot.x > _w * 1.1) {
      _shoot = null;
      _nextShoot = 8 + _rng.nextDouble() * 8;
    }
  }

  void _updateCelebration(double step) {
    if (_celebrateLeft <= 0) return;
    _celebrateLeft -= step;
    _confettiAcc += step * 45;
    while (_confettiAcc >= 1) {
      _confettiAcc -= 1;
      _spawn(
        x: _rng.nextDouble() * _w,
        y: -8,
        vx: (_rng.nextDouble() - .5) * 60,
        vy: 70 + _rng.nextDouble() * 110,
        life: 3.2,
        size: 5 + _rng.nextDouble() * 4,
        color: _confettiColor(),
        kind: _rng.nextBool() ? _Kind.confetti : _Kind.star,
        gravity: 30,
      );
    }
  }

  void _updateParticles(double step) {
    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life -= step;
      if (p.life <= 0 || p.y > _h + 30) {
        _particles.removeAt(i);
        continue;
      }
      p.vy += p.gravity * step;
      p.x += p.vx * step;
      p.y += p.vy * step;
      p.rot += p.spin * step;
    }
  }

  Color _confettiColor() {
    const colors = <Color>[
      VeeTokens.yellow,
      VeeTokens.orange,
      VeeTokens.sky,
      VeeTokens.leaf,
      VeeTokens.lilac,
      VeeTokens.peach,
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  // ── particles ──────────────────────────────────────────────────────────

  void _spawn({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double life,
    required double size,
    required Color color,
    required _Kind kind,
    double gravity = 0,
  }) {
    if (_particles.length >= _maxParticles) _particles.removeAt(0);
    _particles.add(
      _Particle(
        x: x,
        y: y,
        vx: vx,
        vy: vy,
        life: life,
        maxLife: life,
        size: size,
        color: color,
        kind: kind,
        gravity: gravity,
        rot: _rng.nextDouble() * math.pi * 2,
        spin: (_rng.nextDouble() - .5) * 8,
      ),
    );
  }

  void _burst(
    double x,
    double y, {
    int count = 10,
    List<Color> colors = const <Color>[VeeTokens.yellow, VeeTokens.white],
    _Kind kind = _Kind.sparkle,
    double speed = 150,
    double life = .9,
    double size = 5,
    double gravity = 0,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final v = speed * (.4 + _rng.nextDouble() * .6);
      _spawn(
        x: x,
        y: y,
        vx: math.cos(angle) * v,
        vy: math.sin(angle) * v,
        life: life * (.7 + _rng.nextDouble() * .5),
        size: size * (.7 + _rng.nextDouble() * .6),
        color: colors[_rng.nextInt(colors.length)],
        kind: kind,
        gravity: gravity,
      );
    }
  }

  void _catchStar(double x, double y) {
    _burst(
      x,
      y,
      count: 12,
      kind: _Kind.star,
      colors: const <Color>[VeeTokens.yellow, VeeTokens.orange],
      speed: 190,
      size: 7,
      life: 1.1,
    );
    starsCaught++;
    Haptics.light();
    onStarCaught?.call(starsCaught);
  }

  // ── geometry used by drawing and by tapping ────────────────────────────

  Offset _flyPosition(_Firefly f) => Offset(
    f.nx * _w + 16 * math.sin(t * .8 + f.phase),
    f.ny * _h + 12 * math.sin(t * 1.3 + f.phase * 1.7),
  );

  Offset _butterflyPosition(_Butterfly b) => Offset(
    _w * (.12 + .76 * ((math.sin(b.travel * .35 + b.phase) + 1) / 2)),
    _h * (.30 + .17 * math.sin(b.travel * .8 + b.phase * 1.7)) +
        8 * math.sin(t * 7 + b.phase),
  );

  Offset get _sunCenter => Offset(_w * .12, _h * .17);
  double get _sunRadius => math.min(_w, _h) * .07;

  Offset get _treeBase => Offset(_w * .75, _h * .66);
  Offset get _crownCenter => Offset(_w * .74, _h * .21);
  double get _crownRadius => _h * .115;

  Rect get _chestRect {
    final width = _w * .12;
    final height = _h * .12;
    return Rect.fromLTWH(_w * .53, _h * .74, width, height);
  }

  Offset get _portalCenter => Offset(_w * .33, _h * .50);

  // ── drawing ────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_syncSize()) return;

    canvas.drawRect(Rect.fromLTWH(0, 0, _w, _h), _skyPaint);
    _drawSun(canvas);
    for (final cloud in _clouds) {
      _drawCloud(canvas, cloud);
    }
    _drawShootingStar(canvas);
    _drawHills(canvas);
    if (revealLevel >= 4) _drawPortal(canvas);
    _drawTree(canvas);
    for (final flower in _flowers) {
      _drawFlower(canvas, flower);
    }
    if (revealLevel >= 3) _drawChest(canvas);
    for (final butterfly in _butterflies) {
      _drawButterfly(canvas, butterfly);
    }
    for (final fly in _flies) {
      if (!fly.popped) _drawFirefly(canvas, fly);
    }
    _drawParticles(canvas);
  }

  void _drawSun(Canvas c) {
    final center = _sunCenter;
    final r = _sunRadius * (1 + .2 * _sunPulse);
    _p
      ..style = PaintingStyle.fill
      ..color = VeeTokens.yellow.withValues(alpha: .28);
    c.drawCircle(center, r * 1.9, _p);
    _p.color = VeeTokens.yellow;
    c.drawCircle(center, r, _p);

    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .14
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 + t * .25;
      final dir = Offset(math.cos(a), math.sin(a));
      c.drawLine(center + dir * (r * 1.35), center + dir * (r * 1.7), _p);
    }
    _p.style = PaintingStyle.fill;
  }

  void _drawCloud(Canvas c, _Cloud cloud) {
    final scale = cloud.scale * (1 + .25 * cloud.puff);
    final cx = cloud.x * _w;
    final cy = cloud.y * _h;
    final unit = math.min(_w, _h) * .05 * scale;
    _p
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: .92);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: unit * 4,
        height: unit * 1.7,
      ),
      _p,
    );
    c.drawCircle(Offset(cx - unit * .8, cy - unit * .5), unit * 1.0, _p);
    c.drawCircle(Offset(cx + unit * .5, cy - unit * .7), unit * 1.25, _p);
  }

  void _drawShootingStar(Canvas c) {
    final shoot = _shoot;
    if (shoot == null) return;
    _p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = VeeTokens.yellow.withValues(alpha: .55);
    c.drawLine(
      Offset(shoot.x, shoot.y),
      Offset(shoot.x - shoot.vx * .35, shoot.y - shoot.vy * .35),
      _p,
    );
    _p
      ..style = PaintingStyle.fill
      ..color = VeeTokens.yellow;
    _drawStar(c, shoot.x, shoot.y, 11, 0);
  }

  void _drawHills(Canvas c) {
    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFB4D8AC);
    c.drawOval(Rect.fromLTWH(_w * .30, _h * .55, _w * .95, _h * .42), _p);
    _p.color = const Color(0xFFBFE08A);
    c.drawOval(Rect.fromLTWH(-_w * .05, _h * .64, _w * 1.1, _h * .5), _p);
  }

  void _drawTree(Canvas c) {
    final base = _treeBase;
    final sway =
        math.sin(t * 1.1) * .012 +
        math.sin(t * 17) * .05 * math.min(1.0, _treeWobble);
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(sway);
    c.translate(-base.dx, -base.dy);

    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF8D5F3A);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_w * .735, _h * .25, _w * .028, _h * .42),
        const Radius.circular(6),
      ),
      _p,
    );

    _p.color = const Color(0xFF5E9F55);
    final crown = _crownCenter;
    final r = _crownRadius;
    c.drawCircle(Offset(crown.dx - _w * .06, crown.dy + r * .15), r, _p);
    c.drawCircle(Offset(crown.dx + _w * .04, crown.dy + r * .05), r * 1.05, _p);
    c.drawCircle(Offset(crown.dx - _w * .01, crown.dy - r * .7), r, _p);
    c.restore();
  }

  void _drawFlower(Canvas c, _Flower flower) {
    final x = flower.nx * _w;
    final y = flower.ny * _h;
    final bloom = flower.bloom;
    final petal = math.min(_w, _h) * .022 * (.6 + .8 * bloom);

    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5E9B3D);
    c.drawLine(Offset(x, y), Offset(x, y + _h * .08), _p);

    _p.style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 + t * .15;
      _p.color = flower.color;
      c.drawCircle(
        Offset(x + math.cos(a) * petal, y + math.sin(a) * petal),
        petal * .85,
        _p,
      );
    }
    _p.color = VeeTokens.yellow;
    c.drawCircle(Offset(x, y), petal * .7, _p);
  }

  void _drawChest(Canvas c) {
    final box = _chestRect;
    final open = _chestOpen.clamp(0.0, 1.0);

    if (open > 0) {
      _p
        ..style = PaintingStyle.fill
        ..color = VeeTokens.yellow.withValues(alpha: .35 * open);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(box.center.dx, box.top),
          width: box.width * 1.6,
          height: box.height * 1.1,
        ),
        _p,
      );
    }

    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF0A33A);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          box.left,
          box.top + box.height * .4,
          box.width,
          box.height * .6,
        ),
        const Radius.circular(12),
      ),
      _p,
    );
    final lidTop = box.top - open * box.height * .35;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(box.left, lidTop, box.width, box.height * .45),
        const Radius.circular(14),
      ),
      _p,
    );
    _p.color = const Color(0xFFFFE08A);
    c.drawRect(
      Rect.fromLTWH(box.center.dx - 6, lidTop, 12, box.height * .45),
      _p,
    );
    _p.color = const Color(0xFF6AB5A1);
    c.drawCircle(Offset(box.center.dx, lidTop + box.height * .45), 7, _p);
  }

  void _drawPortal(Canvas c) {
    final center = _portalCenter;
    final pw = _w * .12 * (1 + .12 * _portalPulse);
    final ph = _h * .34 * (1 + .12 * _portalPulse);
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    for (var i = 0; i < 5; i++) {
      final wobble = math.sin(t * 2 + i) * 3;
      _p.color = Color.lerp(VeeTokens.lilac, VeeTokens.sky, i / 4)!;
      c.drawOval(
        Rect.fromCenter(
          center: center,
          width: pw + i * 16 + wobble,
          height: ph + i * 22 + wobble,
        ),
        _p,
      );
    }
    _p.style = PaintingStyle.fill;
  }

  void _drawFirefly(Canvas c, _Firefly f) {
    final pos = _flyPosition(f);
    final glow = 4 + 1.4 * math.sin(t * 2.4 + f.phase);
    _p
      ..style = PaintingStyle.fill
      ..color = VeeTokens.yellow.withValues(alpha: .28);
    c.drawCircle(pos, glow * 2.6, _p);
    _p.color = VeeTokens.yellow;
    c.drawCircle(pos, glow, _p);
  }

  void _drawButterfly(Canvas c, _Butterfly b) {
    final pos = _butterflyPosition(b);
    final size = math.min(_w, _h) * .045;
    final flap = math.sin(t * 14 + b.phase).abs();
    final wing = size * (.35 + .65 * flap);

    _p
      ..style = PaintingStyle.fill
      ..color = b.color;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx - wing * .55, pos.dy - size * .2),
        width: wing,
        height: size * .95,
      ),
      _p,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx + wing * .55, pos.dy - size * .2),
        width: wing,
        height: size * .95,
      ),
      _p,
    );
    _p.color = b.color.withValues(alpha: .75);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx - wing * .4, pos.dy + size * .3),
        width: wing * .7,
        height: size * .6,
      ),
      _p,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx + wing * .4, pos.dy + size * .3),
        width: wing * .7,
        height: size * .6,
      ),
      _p,
    );
    _p.color = VeeTokens.textOnLight;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: size * .14, height: size * .9),
        const Radius.circular(4),
      ),
      _p,
    );
  }

  void _drawParticles(Canvas c) {
    _p.style = PaintingStyle.fill;
    for (final p in _particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      _p.color = p.color.withValues(alpha: alpha);
      switch (p.kind) {
        case _Kind.sparkle:
          c.drawCircle(Offset(p.x, p.y), p.size * (.5 + .5 * alpha), _p);
        case _Kind.star:
          _drawStar(c, p.x, p.y, p.size * 1.6, p.rot);
        case _Kind.leaf:
          c.save();
          c.translate(p.x, p.y);
          c.rotate(p.rot);
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 2.4,
              height: p.size * 1.2,
            ),
            _p,
          );
          c.restore();
        case _Kind.confetti:
          c.save();
          c.translate(p.x, p.y);
          c.rotate(p.rot);
          c.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.6,
              height: p.size * .8,
            ),
            _p,
          );
          c.restore();
      }
    }
  }

  void _drawStar(Canvas c, double x, double y, double radius, double rotation) {
    c.save();
    c.translate(x, y);
    c.rotate(rotation);
    c.scale(radius, radius);
    c.drawPath(_unitStar, _p);
    c.restore();
  }

  // ── input ──────────────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    final position = event.canvasPosition;
    tapAt(position.x, position.y);
  }

  /// Reacts to a tap at game coordinates ([x], [y]). Public so tests can drive
  /// the scene without creating pointer events.
  void tapAt(double x, double y) {
    taps++;
    onInteraction(taps);
    if (!_syncSize()) return;
    final tap = Offset(x, y);

    // 1. Fireflies pop into collectable stars.
    for (final fly in _flies) {
      if (fly.popped) continue;
      final pos = _flyPosition(fly);
      if ((pos - tap).distance < 38) {
        fly.popped = true;
        fly.respawnAt = t + 2.5 + _rng.nextDouble() * 2;
        _catchStar(pos.dx, pos.dy);
        return;
      }
    }

    // 2. A shooting star is a bigger prize.
    final shoot = _shoot;
    if (shoot != null && (Offset(shoot.x, shoot.y) - tap).distance < 52) {
      _shoot = null;
      _nextShoot = 8 + _rng.nextDouble() * 8;
      _catchStar(shoot.x, shoot.y);
      _burst(shoot.x, shoot.y, count: 14, kind: _Kind.sparkle, size: 4);
      return;
    }

    // 3. Butterflies swirl away.
    for (final butterfly in _butterflies) {
      final pos = _butterflyPosition(butterfly);
      if ((pos - tap).distance < 46) {
        butterfly.boost = 1;
        _burst(
          pos.dx,
          pos.dy,
          count: 9,
          colors: <Color>[butterfly.color, VeeTokens.white],
          speed: 110,
        );
        return;
      }
    }

    // 4. Treasure chest and portal appear as the child progresses.
    if (revealLevel >= 3 && _chestRect.inflate(14).contains(tap)) {
      final wasClosed = _chestOpen <= .05;
      _chestOpen = 1;
      _chestTimer = 2.4;
      _burst(
        _chestRect.center.dx,
        _chestRect.top,
        count: 16,
        kind: _Kind.star,
        colors: const <Color>[VeeTokens.yellow, VeeTokens.orange],
        speed: 200,
        size: 6,
        life: 1.2,
        gravity: 120,
      );
      if (wasClosed) {
        starsCaught++;
        Haptics.medium();
        onStarCaught?.call(starsCaught);
      }
      return;
    }
    if (revealLevel >= 4) {
      final center = _portalCenter;
      final dx = (tap.dx - center.dx) / (_w * .08);
      final dy = (tap.dy - center.dy) / (_h * .21);
      if (dx * dx + dy * dy <= 1) {
        _portalPulse = 1;
        _burst(
          center.dx,
          center.dy,
          count: 18,
          colors: const <Color>[
            VeeTokens.lilac,
            VeeTokens.sky,
            VeeTokens.white,
          ],
          speed: 170,
          life: 1.1,
        );
        return;
      }
    }

    // 5. The tree rustles and drops leaves.
    final crown = _crownCenter;
    final nearCrown = (tap - crown).distance < _crownRadius * 1.9;
    final nearTrunk = Rect.fromLTWH(
      _w * .72,
      _h * .25,
      _w * .06,
      _h * .42,
    ).contains(tap);
    if (nearCrown || nearTrunk) {
      _treeWobble = 1;
      for (var i = 0; i < 12; i++) {
        _spawn(
          x: crown.dx + (_rng.nextDouble() - .5) * _crownRadius * 3,
          y: crown.dy + (_rng.nextDouble() - .2) * _crownRadius,
          vx: (_rng.nextDouble() - .5) * 50,
          vy: 20 + _rng.nextDouble() * 40,
          life: 2.4,
          size: 6 + _rng.nextDouble() * 3,
          color: _rng.nextBool() ? const Color(0xFF5E9F55) : VeeTokens.leaf,
          kind: _Kind.leaf,
          gravity: 55,
        );
      }
      return;
    }

    // 6. Flowers bloom (and close again on the next tap).
    for (final flower in _flowers) {
      final pos = Offset(flower.nx * _w, flower.ny * _h);
      if ((pos - tap).distance < 40) {
        flower.open = !flower.open;
        _burst(
          pos.dx,
          pos.dy,
          count: 8,
          colors: <Color>[flower.color, VeeTokens.white],
          speed: 90,
          gravity: 40,
        );
        return;
      }
    }

    // 7. The sun winks.
    if ((tap - _sunCenter).distance < _sunRadius * 1.8) {
      _sunPulse = 1;
      _burst(
        _sunCenter.dx,
        _sunCenter.dy,
        count: 12,
        colors: const <Color>[VeeTokens.yellow, VeeTokens.orange],
        speed: 140,
      );
      return;
    }

    // 8. Clouds puff and drop sparkles.
    for (final cloud in _clouds) {
      final center = Offset(cloud.x * _w, cloud.y * _h);
      final unit = math.min(_w, _h) * .05 * cloud.scale;
      if ((tap - center).distance < unit * 2.2) {
        cloud.puff = 1;
        _burst(
          center.dx,
          center.dy,
          count: 8,
          colors: const <Color>[VeeTokens.white, VeeTokens.sky],
          speed: 70,
          gravity: 90,
          life: 1.2,
        );
        return;
      }
    }

    // 9. Anywhere else: a little sparkle, so every tap answers back.
    _burst(x, y, count: 7, speed: 100);
  }
}

// ── small scene data classes ─────────────────────────────────────────────

enum _Kind { sparkle, star, leaf, confetti }

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final _Kind kind;
  final double gravity;
  double rot;
  final double spin;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
    required this.kind,
    required this.gravity,
    required this.rot,
    required this.spin,
  });
}

class _Cloud {
  double x;
  final double y;
  final double scale;
  final double speed;
  double puff = 0;

  _Cloud({
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
  });
}

class _Firefly {
  double nx;
  double ny;
  final double phase;
  bool popped = false;
  double respawnAt = 0;

  _Firefly({required this.nx, required this.ny, required this.phase});
}

class _Butterfly {
  final double phase;
  final double speed;
  final Color color;
  double boost = 0;
  double travel = 0;

  _Butterfly({required this.phase, required this.speed, required this.color});
}

class _Flower {
  final double nx;
  final double ny;
  final Color color;
  bool open = false;
  double bloom = .35;

  _Flower({required this.nx, required this.ny, required this.color});
}

class _Shoot {
  double x;
  double y;
  final double vx;
  final double vy;

  _Shoot({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}
