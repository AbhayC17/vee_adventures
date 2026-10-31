import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/game/world_adventure_game.dart';

Future<WorldAdventureGame> _mount(
  WidgetTester tester, {
  int revealLevel = 0,
  void Function(int)? onTap,
  void Function(int)? onStar,
}) async {
  final game = WorldAdventureGame(
    onInteraction: onTap ?? (_) {},
    onStarCaught: onStar,
    revealLevel: revealLevel,
    random: Random(5),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 800,
          height: 450,
          child: GameWidget<WorldAdventureGame>(game: game),
        ),
      ),
    ),
  );
  // Let the game load and run a few frames.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  return game;
}

void main() {
  testWidgets('every tap is answered, even on empty sky', (tester) async {
    final taps = <int>[];
    final game = await _mount(tester, onTap: taps.add);

    game.tapAt(5, 440);
    await tester.pump(const Duration(milliseconds: 16));

    expect(taps, <int>[1]);
    expect(game.activeParticles, greaterThan(0));
  });

  testWidgets('tapping a firefly catches a star', (tester) async {
    final stars = <int>[];
    final game = await _mount(tester, onStar: stars.add);

    final flies = game.fireflyPositions;
    expect(flies, isNotEmpty);
    game.tapAt(flies.first.dx, flies.first.dy);

    expect(game.starsCaught, 1);
    expect(stars, <int>[1]);
    expect(game.fireflyPositions.length, flies.length - 1);
  });

  testWidgets('the full world (chest and portal) draws without errors', (
    tester,
  ) async {
    final game = await _mount(tester, revealLevel: 4);
    game.celebrate();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.activeParticles, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('particles are capped so the scene stays fast', (tester) async {
    final game = await _mount(tester);
    for (var i = 0; i < 80; i++) {
      game.tapAt(10.0 + i, 400);
    }
    expect(game.activeParticles, lessThanOrEqualTo(140));
  });
}
