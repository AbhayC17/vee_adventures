import 'dart:math';

import 'ai_provider.dart';

class SurpriseChoice {
  final String id;
  final String label;
  const SurpriseChoice(this.id, this.label);
}

/// Picks which surprise appears after a child completes a challenge.
///
/// This used to ask the AI proxy to choose one ID from a short allow-list.
/// That cost a full network round trip (2–3 s, up to 55 s on a timeout) for
/// a decision that is just "pick one of N", and it froze the screen right
/// after the child's best moment. The choice is now local and instant.
///
/// It also avoids repeating the previous surprise, so replays feel fresher.
///
/// The [provider] parameter is kept only so existing callers such as
/// AppController keep compiling unchanged. It is intentionally unused, so
/// this class makes no network calls.
class SurpriseSelector {
  final AiProvider? provider;
  final Random random;
  String? _lastId;

  SurpriseSelector({this.provider, Random? random})
    : random = random ?? Random();

  /// Still async so callers that `await` it need no changes, but it completes
  /// without waiting on anything.
  Future<SurpriseChoice> choose({
    required List<SurpriseChoice> allowed,
    String context = '',
  }) async {
    if (allowed.isEmpty) {
      return const SurpriseChoice('small_glow', 'A tiny glow appears.');
    }

    final fresh = allowed.length > 1
        ? allowed.where((e) => e.id != _lastId).toList(growable: false)
        : allowed;
    final pick = fresh[random.nextInt(fresh.length)];
    _lastId = pick.id;
    return pick;
  }
}
