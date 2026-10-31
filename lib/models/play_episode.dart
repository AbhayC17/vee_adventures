import 'environment_mode.dart';

/// Content definition for one reusable PLAY adventure.
///
/// This model intentionally contains data only. Progression rules live in
/// PlayAdventureSession and the UI lives in PlayScreen.
class PlayEpisode {
  final String id;
  final String title;
  final String hook;
  final List<String> paths;
  final String setting;
  final String objectId;
  final EnvironmentMode mode;
  final List<String> surpriseIds;

  const PlayEpisode({
    required this.id,
    required this.title,
    required this.hook,
    required this.paths,
    required this.setting,
    required this.objectId,
    required this.mode,
    required this.surpriseIds,
  });

  factory PlayEpisode.fromJson(Map<String, dynamic> json) {
    final modeValue = json['mode'];
    final mode = EnvironmentMode.values.firstWhere(
      (value) => value.name == modeValue,
      orElse: () =>
          throw FormatException('Unknown PLAY episode mode: $modeValue'),
    );

    List<String> readStringList(String key) {
      final value = json[key];
      if (value is! List) {
        throw FormatException('PLAY episode field "$key" must be a list.');
      }
      final result = <String>[];
      for (final entry in value) {
        if (entry is! String || entry.trim().isEmpty) {
          throw FormatException(
            'PLAY episode field "$key" must contain non-empty strings.',
          );
        }
        result.add(entry.trim());
      }
      return List<String>.unmodifiable(result);
    }

    String readRequiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('PLAY episode field "$key" is required.');
      }
      return value.trim();
    }

    return PlayEpisode(
      id: readRequiredString('id'),
      title: readRequiredString('title'),
      hook: readRequiredString('hook'),
      paths: readStringList('paths'),
      setting: readRequiredString('setting'),
      objectId: readRequiredString('objectId'),
      mode: mode,
      surpriseIds: readStringList('surpriseIds'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'hook': hook,
    'paths': paths,
    'setting': setting,
    'objectId': objectId,
    'mode': mode.name,
    'surpriseIds': surpriseIds,
  };
}
