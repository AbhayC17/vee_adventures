import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/models/content_catalog.dart';
import 'package:vees_adventures/services/explore/explore_board.dart';

void main() {
  test('every world, board size and seed makes a valid board', () {
    for (final setting in ContentCatalog.settings) {
      for (final spots in [4, 6, 8]) {
        for (var seed = 0; seed < 20; seed++) {
          final random = Random(seed);
          final collected = {
            for (final item in ContentCatalog.items)
              if (random.nextInt(3) == 0) item.id,
          };
          final board = ExploreBoard.generate(
            setting: setting,
            collected: collected,
            random: Random(seed),
            spotCount: spots,
          );
          final label = '${setting.id}/$spots/$seed';
          expect(board.spots, hasLength(spots), reason: label);
          final items = board.spots
              .where((s) => s.kind == SpotKind.item)
              .map((s) => s.item!.id)
              .toList();
          expect(items.toSet(), hasLength(items.length), reason: label);
          expect(items, isNotEmpty, reason: label);
          expect(
            board.spots.where((s) => s.kind == SpotKind.golden).length,
            spots >= 6 ? 1 : 0,
            reason: label,
          );
          expect(
            board.spots.where((s) => s.kind == SpotKind.critter),
            isNotEmpty,
            reason: label,
          );
        }
      }
    }
  });

  test('boards favour things the child has not collected yet', () {
    final garden = ContentCatalog.settings.firstWhere((s) => s.id == 'garden');
    final all = ContentCatalog.forSetting('garden');
    final collected = {for (final item in all.take(all.length - 2)) item.id};
    for (var seed = 0; seed < 30; seed++) {
      final board = ExploreBoard.generate(
        setting: garden,
        collected: collected,
        random: Random(seed),
      );
      expect(board.itemIds.any((id) => !collected.contains(id)), isTrue);
    }
  });

  test('a round is complete when every item spot is open; gold is a bonus', () {
    final setting = ContentCatalog.settings.first;
    final board = ExploreBoard.generate(
      setting: setting,
      collected: {},
      random: Random(1),
    );
    expect(board.roundComplete, isFalse);
    for (final spot in board.spots.where((s) => s.kind == SpotKind.item)) {
      expect(board.open(spot.index), isNotNull);
      expect(board.open(spot.index), isNull, reason: 'cannot open twice');
    }
    expect(board.roundComplete, isTrue);
    for (final golden in board.spots.where((s) => s.kind == SpotKind.golden)) {
      expect(board.isOpen(golden.index), isFalse);
    }
    expect(board.open(99), isNull);
    expect(board.open(-1), isNull);
  });

  test('the next round avoids what was just shown when it can', () {
    final garden = ContentCatalog.settings.firstWhere((s) => s.id == 'garden');
    final first = ExploreBoard.generate(
      setting: garden,
      collected: {},
      random: Random(1),
    );
    final second = ExploreBoard.generate(
      setting: garden,
      collected: {},
      random: Random(2),
      recent: first.itemIds,
    );
    expect(second.itemIds.difference(first.itemIds), isNotEmpty);
  });

  test('small worlds are topped up so a round is never empty', () {
    final beach = ContentCatalog.settings.firstWhere((s) => s.id == 'beach');
    final board = ExploreBoard.generate(
      setting: beach,
      collected: {},
      random: Random(3),
      spotCount: 8,
    );
    expect(board.itemSpotCount, greaterThanOrEqualTo(4));
  });

  test('world progress and mastery', () {
    final garden = ContentCatalog.settings.firstWhere((s) => s.id == 'garden');
    final everything = {
      for (final item in ContentCatalog.forSetting('garden')) item.id,
    };
    expect(WorldProgress.of(garden, everything).mastered, isTrue);
    expect(WorldProgress.of(garden, {}).mastered, isFalse);
    expect(WorldProgress.of(garden, {}).fraction, 0);
  });
}
