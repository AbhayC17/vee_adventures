import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/models/environment_mode.dart';
import 'package:vees_adventures/services/play/play_puzzles.dart';
import 'package:vees_adventures/widgets/puzzle_card.dart';

void main() {
  PlayPuzzle puzzle() => PlayPuzzleBuilder.build(
    PlayPuzzleKind.clueGuess,
    pool: PlayPuzzleBuilder.modePool(EnvironmentMode.outdoor),
    mode: EnvironmentMode.outdoor,
    random: Random(3),
    optionCount: 4,
  );

  testWidgets('a wrong answer nudges kindly and does not finish the puzzle', (
    tester,
  ) async {
    final p = puzzle();
    var solved = 0;
    final attempts = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PuzzleCard(
              puzzle: p,
              onSolved: () => solved++,
              onAttempt: attempts.add,
            ),
          ),
        ),
      ),
    );

    final wrong = p.options.firstWhere((o) => o.id != p.answer.id);
    await tester.tap(find.text(wrong.name));
    await tester.pump(const Duration(milliseconds: 500));

    expect(attempts, <bool>[false]);
    expect(solved, 0);

    // The child can keep trying and still finish.
    await tester.tap(find.text(p.answer.name));
    await tester.pump(const Duration(milliseconds: 900));
    expect(attempts, <bool>[false, true]);
    expect(solved, 1);
  });

  testWidgets('the right answer finishes exactly once', (tester) async {
    final p = puzzle();
    var solved = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PuzzleCard(puzzle: p, onSolved: () => solved++),
          ),
        ),
      ),
    );

    await tester.tap(find.text(p.answer.name));
    await tester.tap(find.text(p.answer.name));
    await tester.pump(const Duration(milliseconds: 900));

    expect(solved, 1);
  });
}
