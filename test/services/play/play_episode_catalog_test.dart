import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/models/environment_mode.dart';
import 'package:vees_adventures/models/play_episode.dart';
import 'package:vees_adventures/services/play/play_episode_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PlayEpisodeCatalog.clearCache();
  });

  group('PlayEpisodeCatalog', () {
    test('loads and validates bundled episode data', () async {
      final episodes = await PlayEpisodeCatalog.loadAll();

      expect(episodes, isNotEmpty);
      expect(PlayEpisodeCatalog.validate(episodes), isEmpty);
    });

    test('episode IDs are unique', () async {
      final episodes = await PlayEpisodeCatalog.loadAll();
      final ids = episodes.map((episode) => episode.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('mode filter never returns episodes for another mode', () async {
      final all = await PlayEpisodeCatalog.loadAll();

      for (final mode in EnvironmentMode.values) {
        final episodes = PlayEpisodeCatalog.forMode(all, mode);
        expect(episodes, isNotEmpty);
        expect(episodes.every((episode) => episode.mode == mode), isTrue);
      }
    });

    test('selection is deterministic with a seeded random source', () async {
      final first = await PlayEpisodeCatalog.pickForMode(
        EnvironmentMode.outdoor,
        random: Random(42),
      );
      final second = await PlayEpisodeCatalog.pickForMode(
        EnvironmentMode.outdoor,
        random: Random(42),
      );

      expect(first.id, second.id);
      expect(first.mode, EnvironmentMode.outdoor);
    });

    test('episode JSON round-trip preserves all fields', () async {
      final original = (await PlayEpisodeCatalog.loadAll()).first;
      final json = jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
      final restored = PlayEpisode.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.hook, original.hook);
      expect(restored.paths, original.paths);
      expect(restored.setting, original.setting);
      expect(restored.objectId, original.objectId);
      expect(restored.mode, original.mode);
      expect(restored.surpriseIds, original.surpriseIds);
    });

    test('invalid JSON mode is rejected clearly', () {
      expect(
        () => PlayEpisode.fromJson(<String, dynamic>{
          'id': 'bad',
          'title': 'Bad',
          'hook': 'Hook',
          'paths': <String>['A', 'B'],
          'setting': 'garden',
          'objectId': 'rock',
          'mode': 'space',
          'surpriseIds': <String>['tiny_trail'],
        }),
        throwsFormatException,
      );
    });

    test('missing episode asset reports a useful loading error', () async {
      final missingAssetBundle = _MissingEpisodeBundle();
      await expectLater(
        PlayEpisodeCatalog.loadAll(bundle: missingAssetBundle),
        throwsA(isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains(PlayEpisodeCatalog.assetPath),
        )),
      );
    });
  });
}

class _MissingEpisodeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Missing asset: $key');
  }
}
