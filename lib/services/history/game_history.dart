import '../../models/activity.dart';

class GameHistory {
  final List<AdventureRecord> adventures = [];
  final List<String> movements = [];
  final List<String> stories = [];
  final List<String> discoveries = [];
  final List<String> surprises = [];

  /// Recently selected fixed-task IDs, kept separately by activity.
  final Map<ActivityType, List<String>> taskHistory = {
    ActivityType.spot: <String>[],
    ActivityType.explore: <String>[],
    ActivityType.play: <String>[],
  };

  Future<void> load(Map<String, dynamic> json) async {
    adventures
      ..clear()
      ..addAll(
        _list(json['adventures'])
            .whereType<Map>()
            .map((m) => AdventureRecord.fromJson(_stringKeyedMap(m))),
      );

    movements
      ..clear()
      ..addAll(_stringList(json['movements']));
    stories
      ..clear()
      ..addAll(_stringList(json['stories']));
    discoveries
      ..clear()
      ..addAll(_stringList(json['discoveries']));
    surprises
      ..clear()
      ..addAll(_stringList(json['surprises']));

    final rawTaskHistory = json['taskHistory'];
    final taskMap = rawTaskHistory is Map ? rawTaskHistory : const {};
    for (final type in ActivityType.values) {
      taskHistory[type] = _stringList(taskMap[type.name]);
    }
  }

  Map<String, dynamic> toJson() => {
    'adventures': adventures.map((e) => e.toJson()).toList(),
    'movements': movements,
    'stories': stories,
    'discoveries': discoveries,
    'surprises': surprises,
    'taskHistory': {
      for (final entry in taskHistory.entries) entry.key.name: entry.value,
    },
  };

  static List<dynamic> _list(Object? value) =>
      value is List ? value : <dynamic>[];

  static List<String> _stringList(Object? value) =>
      _list(value).whereType<String>().toList();

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      Map<String, dynamic>.fromEntries(
        value.entries
            .where((entry) => entry.key is String)
            .map((entry) => MapEntry(entry.key as String, entry.value)),
      );

  void record(AdventureBlueprint a) {
    adventures.add(AdventureRecord.fromBlueprint(a));
    movements.addAll(a.movementSequence.map((e) => e.name));
    stories.add(a.storyStructure);
    discoveries.add(a.discoveryCategory);
    surprises.add(a.surpriseType);
  }

  void recordTask(ActivityType type, String taskId) {
    final list = taskHistory[type] ??= <String>[];
    list.remove(taskId);
    list.add(taskId);
    while (list.length > 12) {
      list.removeAt(0);
    }
  }

  List<String> recentTaskIds(ActivityType type, [int count = 8]) {
    final list = taskHistory[type] ?? const <String>[];
    return list.reversed.take(count).toList(growable: false);
  }

  List<String> recentSignatures([int count = 12]) => adventures.reversed
      .take(count)
      .map((e) => e.signature)
      .toList(growable: false);
}

class AdventureRecord {
  final String signature;
  final String theme;
  final String movementPattern;

  AdventureRecord(this.signature, this.theme, this.movementPattern);

  factory AdventureRecord.fromBlueprint(AdventureBlueprint a) =>
      AdventureRecord(a.signature(), a.theme, a.movementPattern);

  factory AdventureRecord.fromJson(Map<String, dynamic> j) => AdventureRecord(
    j['signature'] is String ? j['signature'] as String : '',
    j['theme'] is String ? j['theme'] as String : '',
    j['movementPattern'] is String ? j['movementPattern'] as String : '',
  );

  Map<String, dynamic> toJson() => {
    'signature': signature,
    'theme': theme,
    'movementPattern': movementPattern,
  };
}
