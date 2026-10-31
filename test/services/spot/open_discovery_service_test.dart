import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/services/ai/ai_provider.dart';
import 'package:vees_adventures/services/spot/open_discovery.dart';
import 'package:vees_adventures/services/spot/open_discovery_rules.dart';

class _FakeProvider implements AiProvider {
  _FakeProvider(this.answer);
  final Map<String, dynamic>? answer;
  String? lastPrompt;

  @override
  Future<Map<String, dynamic>?> generateJson({
    required String systemPrompt,
    required String userPrompt,
  }) async => null;

  @override
  Future<Map<String, dynamic>?> generateVisionJson({
    required String prompt,
    required List<int> bytes,
    String? mimeType,
  }) async {
    lastPrompt = prompt;
    return answer;
  }
}

Map<String, dynamic> _answer([Map<String, dynamic> changes = const {}]) => {
  'contains_person': false,
  'safe_for_children': true,
  'catalog_id': 'unknown',
  'confidence': 0.9,
  'object_name': 'tennis ball',
  'fits_clue': true,
  'facts': ['Tennis balls are fuzzy and bounce.'],
  'movement_id': 'frog_hops',
  ...changes,
};

Future<OpenOutcome?> _run(
  Map<String, dynamic>? answer,
  TextModerator moderator, {
  _FakeProvider? provider,
}) {
  final service = OpenDiscoveryService(
    provider: provider ?? _FakeProvider(answer),
    moderator: moderator,
  );
  return service.discover(
    bytes: const [1, 2, 3],
    allowedCatalogIds: const ['apple', 'tomato'],
    movementIds: const ['frog_hops'],
    cluePrompt: 'Find something ROUND.',
  );
}

void main() {
  test('a safe new object keeps its checked facts', () async {
    final seen = <String>[];
    final outcome = await _run(_answer(), (text) async {
      seen.add(text);
      return true;
    });
    expect(outcome!.kind, OpenOutcomeKind.find);
    expect(outcome.facts, ['Tennis balls are fuzzy and bounce.']);
    expect(seen.single, contains('tennis ball'));
    expect(seen.single, contains('fuzzy'));
  });

  test('if the safety check says no, nothing is shown', () async {
    final outcome = await _run(_answer(), (_) async => false);
    expect(outcome!.kind, OpenOutcomeKind.blocked);
  });

  test(
    'if the safety check cannot run, the name stays but facts are left out',
    () async {
      final outcome = await _run(_answer(), (_) async => null);
      expect(outcome!.kind, OpenOutcomeKind.find);
      expect(outcome.name, 'tennis ball');
      expect(outcome.facts, isEmpty);
    },
  );

  test('people are refused without any safety call', () async {
    var calls = 0;
    final outcome = await _run(_answer({'contains_person': true}), (_) async {
      calls++;
      return true;
    });
    expect(outcome!.kind, OpenOutcomeKind.person);
    expect(calls, 0);
  });

  test(
    'the game\'s own items use the catalogue and skip the safety call',
    () async {
      var calls = 0;
      final outcome = await _run(_answer({'catalog_id': 'apple'}), (_) async {
        calls++;
        return true;
      });
      expect(outcome!.kind, OpenOutcomeKind.catalog);
      expect(calls, 0);
    },
  );

  test('a fact the game\'s own validator dislikes is dropped', () async {
    final outcome = await _run(
      _answer({
        'facts': ['It rolls along the road.', 'Tennis balls are fuzzy.'],
      }),
      (_) async => true,
    );
    expect(outcome!.facts, ['Tennis balls are fuzzy.']);
  });

  test('no answer from the AI gives null and an error', () async {
    final provider = _FakeProvider(null);
    final service = OpenDiscoveryService(
      provider: provider,
      moderator: (_) async => true,
    );
    final outcome = await service.discover(
      bytes: const [1],
      allowedCatalogIds: const ['apple'],
      movementIds: const ['frog_hops'],
      cluePrompt: 'Find something ROUND.',
    );
    expect(outcome, isNull);
    expect(service.lastError, isNotNull);
  });

  test(
    'the prompt carries the clue, the allowed ids and the safety rules',
    () async {
      final provider = _FakeProvider(_answer());
      await _run(null, (_) async => true, provider: provider);
      final prompt = provider.lastPrompt!;
      expect(prompt, contains('Find something ROUND.'));
      expect(prompt, contains('apple, tomato'));
      expect(prompt, contains('frog_hops'));
      expect(prompt, contains('contains_person'));
      expect(prompt, contains('safe_for_children'));
    },
  );
}
