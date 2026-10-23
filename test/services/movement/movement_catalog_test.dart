import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/models/activity.dart';
import 'package:vees_adventures/services/activity_selection/movement_profile.dart';
import 'package:vees_adventures/services/movement/movement_catalog.dart';

void main() {
  group('MovementCatalog', () {
    test('contains unique, complete movement definitions', () {
      expect(MovementCatalog.validate(), isTrue);
      expect(MovementCatalog.all, hasLength(30));
      expect(
        MovementCatalog.all.map((movement) => movement.id).toSet(),
        hasLength(30),
      );
      for (final movement in MovementCatalog.all) {
        expect(movement.label.trim(), isNotEmpty, reason: movement.id);
        expect(movement.instruction.trim(), isNotEmpty, reason: movement.id);
        expect(movement.baseCount, greaterThan(0), reason: movement.id);
      }
    });

    test('gentle pool excludes high-impact movements', () {
      final ids = MovementCatalog.forProfile(MovementProfile.gentle)
          .map((movement) => movement.id)
          .toSet();

      expect(ids, contains('tiny_steps'));
      expect(ids, contains('airplane_balance'));
      expect(ids, isNot(contains('high_jump')));
      expect(ids, isNot(contains('star_jumps')));
      expect(ids, isNot(contains('mountain_climbers')));
    });

    test('energetic profile scales the same base movement higher', () {
      final gentle = MovementCatalog.stepFor(
        'cross_body_taps',
        MovementProfile.gentle,
      );
      final energetic = MovementCatalog.stepFor(
        'cross_body_taps',
        MovementProfile.energetic,
      );

      expect(gentle, isA<MovementStep>());
      expect(gentle.name, energetic.name);
      expect(gentle.count, lessThan(energetic.count));
      expect(gentle.count, inInclusiveRange(2, 10));
      expect(energetic.count, inInclusiveRange(2, 10));
    });

    test('older ages receive a modestly larger repetition target', () {
      final definition = MovementCatalog.resolve('cross_body_taps');
      final younger = MovementCatalog.countFor(
        definition,
        MovementProfile.gentle,
        age: 2,
      );
      final older = MovementCatalog.countFor(
        definition,
        MovementProfile.gentle,
        age: 6,
      );

      expect(younger, lessThan(older));
      expect(younger, inInclusiveRange(2, 10));
      expect(older, inInclusiveRange(2, 10));
    });

    test('unknown ids resolve safely instead of crashing', () {
      final definition = MovementCatalog.resolve('legacy_move');

      expect(definition.id, 'legacy_move');
      expect(definition.label, 'Legacy Move');
      expect(definition.instruction, isNotEmpty);
    });
  });

  group('MovementBag', () {
    test('does not repeat until the selected profile pool is exhausted', () {
      final bag = MovementBag(random: Random(1234));
      final steps = List<MovementStep>.generate(
        5,
        (_) => bag.nextStep(MovementProfile.gentle),
      );

      expect(steps.map((step) => step.name).toSet(), hasLength(5));
      final gentleIds = MovementCatalog.forProfile(MovementProfile.gentle)
          .map((movement) => movement.id)
          .toSet();
      expect(steps.every((step) => gentleIds.contains(step.name)), isTrue);
    });

    test('a profile change selects from the new profile pool', () {
      final bag = MovementBag(random: Random(77));
      for (var i = 0; i < 3; i++) {
        bag.nextStep(MovementProfile.energetic);
      }

      final gentleStep = bag.nextStep(MovementProfile.gentle);
      final gentleIds = MovementCatalog.forProfile(MovementProfile.gentle)
          .map((movement) => movement.id)
          .toSet();

      expect(gentleIds, contains(gentleStep.name));
    });
  });
}
