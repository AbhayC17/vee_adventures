import '../../models/activity.dart';
import '../../models/environment_mode.dart';
import '../history/game_history.dart';
import 'movement_profile.dart';

class ActivitySelector {
  ActivityType select({
    required int age,
    required int progression,
    required String lastActivity,
    required GameHistory history,
    required String movementPreference,
    required EnvironmentMode environmentMode,
  }) {
    final profile = movementProfileFor(movementPreference);
    final recent = history.adventures
        .take(4)
        .map((a) => a.signature.split('|').first)
        .toSet();

    // The move preference controls intensity. Environment mode controls
    // the content framing. Both are inputs to the same activity selector.
    final preferred = switch (profile) {
      MovementProfile.energetic => const [
        ActivityType.play,
        ActivityType.spot,
        ActivityType.explore,
      ],
      MovementProfile.steady => const [
        ActivityType.spot,
        ActivityType.play,
        ActivityType.explore,
      ],
      MovementProfile.gentle => const [
        ActivityType.explore,
        ActivityType.spot,
        ActivityType.play,
      ],
    };

    // Keep the parameter explicit so future selection rules can use it.
    // The actual mode filtering happens inside each activity's content pool.
    // This prevents an outdoor/indoor toggle from ever being cosmetic.
    environmentMode;
    age;
    progression;

    for (final candidate in preferred) {
      if (candidate.name != lastActivity && !recent.contains(candidate.name)) {
        return candidate;
      }
    }

    for (final candidate in preferred) {
      if (candidate.name != lastActivity) return candidate;
    }

    return preferred.first;
  }
}
