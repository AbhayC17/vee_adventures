import 'dart:math';

import 'ai_provider.dart';

class SurpriseChoice {
  final String id;
  final String label;
  const SurpriseChoice(this.id, this.label);
}

class SurpriseSelector {
  final AiProvider provider;
  final Random random;
  SurpriseSelector({AiProvider? provider, Random? random})
      : provider = provider ?? OpenAiCompatibleProvider(),
        random = random ?? Random();

  Future<SurpriseChoice> choose({required List<SurpriseChoice> allowed, String context = ''}) async {
    if (allowed.isEmpty) return const SurpriseChoice('small_glow', 'A tiny glow appears.');
    final json = await provider.generateJson(
      systemPrompt: 'Choose one surprise ID only. Never invent IDs or child-facing facts. Return JSON: {"surprise_id":"..."}.',
      userPrompt: 'Allowed surprises: ${allowed.map((e) => e.id).join(', ')}. Context: $context',
    );
    final id = json?['surprise_id'] as String?;
    final match = allowed.where((e) => e.id == id).firstOrNull;
    return match ?? allowed[random.nextInt(allowed.length)];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
