import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/services/ai/surprise_selector.dart';

void main() {
  const allowed = <SurpriseChoice>[
    SurpriseChoice('a', 'A'),
    SurpriseChoice('b', 'B'),
    SurpriseChoice('c', 'C'),
  ];

  test(
    'always picks from the allowed list and never repeats back-to-back',
    () async {
      final selector = SurpriseSelector(random: Random(1));
      String? last;
      for (var i = 0; i < 60; i++) {
        final choice = await selector.choose(allowed: allowed);
        expect(allowed.map((e) => e.id), contains(choice.id));
        if (last != null) expect(choice.id, isNot(last));
        last = choice.id;
      }
    },
  );

  test('works instantly with no network or AI provider', () async {
    final watch = Stopwatch()..start();
    await SurpriseSelector().choose(allowed: allowed);
    expect(watch.elapsedMilliseconds, lessThan(200));
  });

  test('handles empty and single-item lists', () async {
    final selector = SurpriseSelector();
    expect((await selector.choose(allowed: const [])).id, 'small_glow');
    final only = <SurpriseChoice>[const SurpriseChoice('x', 'X')];
    expect((await selector.choose(allowed: only)).id, 'x');
    expect((await selector.choose(allowed: only)).id, 'x');
  });
}
