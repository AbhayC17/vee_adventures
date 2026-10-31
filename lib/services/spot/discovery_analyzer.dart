import 'package:flutter/foundation.dart';

import '../ai/ai_provider.dart';

class IdentifiedCatalogItem {
  final String catalogId;
  final double confidence;

  const IdentifiedCatalogItem({
    required this.catalogId,
    required this.confidence,
  });
}

/// Vision is deliberately limited to identification.
/// It never supplies child-facing facts or explanations.
class DiscoveryAnalyzer {
  final AiProvider provider;
  String? lastError;

  DiscoveryAnalyzer({AiProvider? provider})
    : provider = provider ?? OpenAiCompatibleProvider();

  Future<IdentifiedCatalogItem?> identify({
    required List<int> bytes,
    required List<String> allowedCatalogIds,
  }) async {
    lastError = null;
    if (allowedCatalogIds.isEmpty) {
      lastError = 'NO_ALLOWED_CATALOG_ITEMS';
      if (kDebugMode) {
        debugPrint('[SPOT] Identification skipped: no allowed catalog IDs.');
      }
      return null;
    }

    if (kDebugMode) {
      debugPrint(
        '[SPOT] Starting identification: '
        '${bytes.length} image bytes, '
        '${allowedCatalogIds.length} allowed catalog items.',
      );
    }

    final prompt =
        '''You are an object-identification component for a preschool game.
Identify the main visible everyday/nature object in the image using ONLY one of these catalog IDs: ${allowedCatalogIds.join(', ')}.
Return JSON only: {"catalog_id":"one_id_or_unknown","confidence":0.0}.
The confidence must be a number between 0.0 and 1.0.
Do not provide facts, explanations, prose, guesses outside the list, or personal information.
If uncertain, return catalog_id="unknown" and a low confidence.''';

    final json = await provider.generateVisionJson(
      prompt: prompt,
      bytes: bytes,
    );

    if (json == null) {
      lastError = provider is OpenAiCompatibleProvider
          ? (provider as OpenAiCompatibleProvider).lastError
          : null;
      if (kDebugMode) {
        debugPrint(
          '[SPOT] Identification failed: ${lastError ?? 'provider returned no result'}.',
        );
      }
      return null;
    }

    final rawId = json['catalog_id'];
    final rawConfidence = json['confidence'];

    if (kDebugMode) {
      // Log only the structured identification result, not image data.
      debugPrint(
        '[SPOT] Model result: catalog_id=$rawId, '
        'confidence=$rawConfidence.',
      );
    }

    if (rawId is! String) {
      lastError = 'INVALID_MODEL_RESULT';
      if (kDebugMode) {
        debugPrint('[SPOT] Rejected result: catalog_id is not a string.');
      }
      return null;
    }

    final id = rawId.trim();
    final confidence = rawConfidence is num ? rawConfidence.toDouble() : 0.0;

    if (id == 'unknown') {
      lastError = 'MODEL_UNCERTAIN';
      if (kDebugMode) {
        debugPrint('[SPOT] Model could not identify an allowed item.');
      }
      return null;
    }

    if (!allowedCatalogIds.contains(id)) {
      lastError = 'MODEL_RETURNED_DISALLOWED_ID';
      if (kDebugMode) {
        debugPrint('[SPOT] Rejected result: catalog ID is not allowed.');
      }
      return null;
    }

    return IdentifiedCatalogItem(
      catalogId: id,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
    );
  }
}
