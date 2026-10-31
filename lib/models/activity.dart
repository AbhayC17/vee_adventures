enum ActivityType { spot, explore, play }

extension ActivityTypeLabel on ActivityType {
  String get label => switch (this) {
    ActivityType.spot => 'SPOT',
    ActivityType.explore => 'EXPLORE',
    ActivityType.play => 'PLAY',
  };
}

class MovementStep {
  final String name;
  final int count;

  const MovementStep(this.name, this.count);

  Map<String, dynamic> toJson() => {'name': name, 'count': count};

  factory MovementStep.fromJson(Map<String, dynamic> j) => MovementStep(
    (j['name'] as String? ?? 'reach').trim(),
    (j['count'] as num? ?? 1).toInt(),
  );
}

class AdventureBlueprint {
  final String id;
  final ActivityType activityType;
  final String theme;
  final String setting;
  final String opening;
  final List<String> veeDialogue;
  final String objective;
  final List<MovementStep> movementSequence;
  final List<String> interactionSequence;
  final List<String> environmentalEvents;
  final String surpriseEvent;
  final String discovery;
  final String educationalMoment;
  final String rewardMoment;
  final String ending;
  final String movementPattern;
  final String interactionPattern;
  final String surpriseType;
  final String discoveryCategory;
  final String storyStructure;

  const AdventureBlueprint({
    required this.id,
    required this.activityType,
    required this.theme,
    required this.setting,
    required this.opening,
    required this.veeDialogue,
    required this.objective,
    required this.movementSequence,
    required this.interactionSequence,
    required this.environmentalEvents,
    required this.surpriseEvent,
    required this.discovery,
    required this.educationalMoment,
    required this.rewardMoment,
    required this.ending,
    required this.movementPattern,
    required this.interactionPattern,
    required this.surpriseType,
    required this.discoveryCategory,
    required this.storyStructure,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityType': activityType.name,
    'theme': theme,
    'setting': setting,
    'opening': opening,
    'veeDialogue': veeDialogue,
    'objective': objective,
    'movementSequence': movementSequence.map((e) => e.toJson()).toList(),
    'interactionSequence': interactionSequence,
    'environmentalEvents': environmentalEvents,
    'surpriseEvent': surpriseEvent,
    'discovery': discovery,
    'educationalMoment': educationalMoment,
    'rewardMoment': rewardMoment,
    'ending': ending,
    'movementPattern': movementPattern,
    'interactionPattern': interactionPattern,
    'surpriseType': surpriseType,
    'discoveryCategory': discoveryCategory,
    'storyStructure': storyStructure,
  };

  factory AdventureBlueprint.fromJson(
    Map<String, dynamic> j,
  ) => AdventureBlueprint(
    id: j['id'] as String? ?? 'adventure',
    activityType: ActivityType.values.firstWhere(
      (e) => e.name == (j['activityType'] as String? ?? 'play'),
      orElse: () => ActivityType.play,
    ),
    theme: j['theme'] as String? ?? 'forest',
    setting: j['setting'] as String? ?? 'meadow',
    opening: j['opening'] as String? ?? 'A new path is glowing.',
    veeDialogue:
        (j['veeDialogue'] as List<dynamic>? ?? const ["Let's explore!"])
            .map((e) => e.toString())
            .take(3)
            .toList(),
    objective: j['objective'] as String? ?? 'Complete the adventure',
    movementSequence: (j['movementSequence'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => MovementStep.fromJson(Map<String, dynamic>.from(e)))
        .take(4)
        .toList(),
    interactionSequence:
        (j['interactionSequence'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .take(5)
            .toList(),
    environmentalEvents:
        (j['environmentalEvents'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .take(4)
            .toList(),
    surpriseEvent: j['surpriseEvent'] as String? ?? 'A hidden star appears.',
    discovery: j['discovery'] as String? ?? 'A tiny leaf',
    educationalMoment:
        j['educationalMoment'] as String? ??
        'Leaves help plants collect light.',
    rewardMoment: j['rewardMoment'] as String? ?? 'You found a star!',
    ending: j['ending'] as String? ?? 'Adventure complete!',
    movementPattern: j['movementPattern'] as String? ?? 'reach',
    interactionPattern: j['interactionPattern'] as String? ?? 'tap',
    surpriseType: j['surpriseType'] as String? ?? 'small',
    discoveryCategory: j['discoveryCategory'] as String? ?? 'nature',
    storyStructure: j['storyStructure'] as String? ?? 'discover-react-reward',
  );

  String signature() => [
    activityType.name,
    movementPattern,
    theme,
    setting,
    interactionPattern,
    surpriseType,
    discoveryCategory,
    storyStructure,
  ].join('|').toLowerCase();
}
