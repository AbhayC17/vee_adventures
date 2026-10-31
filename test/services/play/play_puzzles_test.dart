import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/models/content_catalog.dart';
import 'package:vees_adventures/models/environment_mode.dart';
import 'package:vees_adventures/services/play/play_episode_catalog.dart';
import 'package:vees_adventures/services/play/play_puzzles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PlayEpisodeCatalog.clearCache);

  group('PlayPuzzleBuilder', () {
    test('every episode can be solved: its object is always offered', () async {
      // Regression: "The Treasure That Moved" asked for the Rock, but the
      // puzzle only showed the first three garden items (no Rock), so the
      // story could never be finished.
      final episodes = await PlayEpisodeCatalog.loadAll();
      for (final episode in episodes) {
        final target = ContentCatalog.get(episode.objectId)!;
        final pool = PlayPuzzleBuilder.poolForSetting(
          episode.setting,
          episode.mode,
        );
        for (var seed = 0; seed < 30; seed++) {
          for (final kind in <PlayPuzzleKind>[
            PlayPuzzleKind.dragMatch,
            PlayPuzzleKind.clueGuess,
          ]) {
            final puzzle = PlayPuzzleBuilder.build(
              kind,
              pool: pool,
              mode: episode.mode,
              random: Random(seed),
              target: target,
              optionCount: 3,
            );
            expect(puzzle.answer.id, target.id, reason: episode.id);
            expect(
              puzzle.options.where((o) => o.id == target.id).length,
              1,
              reason: '${episode.id} / ${kind.name} / seed $seed',
            );
          }
        }
      }
    });

    test('options are unique and always contain the answer exactly once', () {
      for (final mode in EnvironmentMode.values) {
        for (final setting in ContentCatalog.settingsForMode(mode)) {
          final pool = PlayPuzzleBuilder.poolForSetting(setting.id, mode);
          for (var seed = 0; seed < 25; seed++) {
            for (final age in <int>[3, 4, 5, 6]) {
              final puzzle = PlayPuzzleBuilder.choose(
                pool: pool,
                mode: mode,
                random: Random(seed),
                age: age,
              );
              final ids = puzzle.options.map((o) => o.id).toList();
              expect(ids.toSet().length, ids.length, reason: puzzle.title);
              expect(ids.where((id) => id == puzzle.answer.id).length, 1);
              expect(puzzle.options.length, greaterThanOrEqualTo(2));
            }
          }
        }
      }
    });

    test('odd one out has exactly one item from a different group', () {
      for (final mode in EnvironmentMode.values) {
        final pool = PlayPuzzleBuilder.modePool(mode);
        for (var seed = 0; seed < 40; seed++) {
          final puzzle = PlayPuzzleBuilder.build(
            PlayPuzzleKind.oddOneOut,
            pool: pool,
            mode: mode,
            random: Random(seed),
          );
          if (puzzle.kind != PlayPuzzleKind.oddOneOut) continue;
          expect(puzzle.options.length, 4);
          expect(
            puzzle.options
                .where((o) => o.category == puzzle.answer.category)
                .length,
            1,
          );
        }
      }
    });

    test('pattern puzzles are consistent for younger and older children', () {
      final pool = PlayPuzzleBuilder.modePool(EnvironmentMode.outdoor);
      final young = PlayPuzzleBuilder.build(
        PlayPuzzleKind.pattern,
        pool: pool,
        mode: EnvironmentMode.outdoor,
        random: Random(1),
        age: 4,
      );
      expect(young.sequence.length, 4);
      expect(young.answer.id, young.sequence.first.id);

      final older = PlayPuzzleBuilder.build(
        PlayPuzzleKind.pattern,
        pool: pool,
        mode: EnvironmentMode.outdoor,
        random: Random(1),
        age: 6,
      );
      // A B C A B ?  ->  the missing picture is C, the third one in the cycle.
      expect(older.sequence.length, 5);
      expect(older.sequence[0].id, older.sequence[3].id);
      expect(older.sequence[1].id, older.sequence[4].id);
      expect(older.answer.id, older.sequence[2].id);
      expect(older.options.any((i) => i.id == older.answer.id), isTrue);
    });

    test('three-year-olds never get the odd-one-out puzzle', () {
      final pool = PlayPuzzleBuilder.modePool(EnvironmentMode.indoor);
      for (var seed = 0; seed < 200; seed++) {
        final puzzle = PlayPuzzleBuilder.choose(
          pool: pool,
          mode: EnvironmentMode.indoor,
          random: Random(seed),
          age: 3,
        );
        expect(puzzle.kind, isNot(PlayPuzzleKind.oddOneOut));
      }
    });

    test('small settings are topped up so there are real choices', () {
      final beach = PlayPuzzleBuilder.poolForSetting(
        'beach',
        EnvironmentMode.outdoor,
      );
      expect(beach.length, greaterThanOrEqualTo(4));
      expect(beach.first.id, 'water');
    });
  });

  group('PlayEpisodeCatalog.pickFresh', () {
    test('does not repeat a recent story', () async {
      for (final mode in EnvironmentMode.values) {
        PlayEpisodeCatalog.clearCache();
        final seen = <String>[];
        for (var i = 0; i < 4; i++) {
          final episode = await PlayEpisodeCatalog.pickFresh(
            mode,
            random: Random(i * 7 + 1),
          );
          seen.add(episode.id);
        }
        expect(seen.toSet().length, 4, reason: '${mode.name}: $seen');
      }
    });

    test('there are enough stories for variety in each mode', () async {
      final all = await PlayEpisodeCatalog.loadAll();
      for (final mode in EnvironmentMode.values) {
        expect(
          PlayEpisodeCatalog.forMode(all, mode).length,
          greaterThanOrEqualTo(6),
        );
      }
    });
  });
}
