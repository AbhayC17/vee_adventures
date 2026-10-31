import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../../models/play_episode.dart';
import '../discovery_engine.dart';

/// Loads, validates and selects PLAY episodes from the bundled JSON catalog.
///
/// Episode copy and configuration live in assets/data/play_episodes.json.
/// This service owns parsing, validation, caching and mode-aware selection.
class PlayEpisodeCatalog {
  PlayEpisodeCatalog._();

  static const String assetPath = 'assets/data/play_episodes.json';
  static Future<List<PlayEpisode>>? _cachedEpisodes;

  static Future<List<PlayEpisode>> loadAll({AssetBundle? bundle}) async {
    if (bundle != null) {
      return _loadAndValidate(bundle);
    }

    final cached = _cachedEpisodes;
    if (cached != null) return cached;

    final pending = _loadAndValidate(rootBundle);
    _cachedEpisodes = pending;
    try {
      return await pending;
    } catch (_) {
      // Do not cache a failure permanently; a later retry may succeed.
      _cachedEpisodes = null;
      rethrow;
    }
  }

  static Future<List<PlayEpisode>> _loadAndValidate(AssetBundle bundle) async {
    late final String raw;
    try {
      raw = await bundle.loadString(assetPath);
    } catch (error) {
      throw FormatException('Could not load $assetPath: $error');
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw FormatException('Invalid JSON in $assetPath: ${error.message}');
    }

    if (decoded is! List) {
      throw const FormatException('PLAY episode JSON must contain a list.');
    }

    final episodes = <PlayEpisode>[];
    for (var index = 0; index < decoded.length; index++) {
      final value = decoded[index];
      if (value is! Map) {
        throw FormatException(
          'PLAY episode at index $index must be an object.',
        );
      }
      try {
        episodes.add(PlayEpisode.fromJson(Map<String, dynamic>.from(value)));
      } on FormatException catch (error) {
        throw FormatException(
          'Invalid PLAY episode at index $index: ${error.message}',
        );
      }
    }

    if (episodes.isEmpty) {
      throw const FormatException('The PLAY episode catalog is empty.');
    }

    final issues = validate(episodes);
    if (issues.isNotEmpty) {
      throw FormatException(
        'PLAY episode catalog validation failed:\n- ${issues.join('\n- ')}',
      );
    }

    return List<PlayEpisode>.unmodifiable(episodes);
  }

  static List<PlayEpisode> forMode(
    List<PlayEpisode> episodes,
    EnvironmentMode mode,
  ) => List<PlayEpisode>.unmodifiable(
    episodes.where((episode) => episode.mode == mode),
  );

  static final List<String> _recent = <String>[];

  /// Like [pickForMode] but avoids the episodes played most recently, so the
  /// child does not meet the same story twice in a row. Once every episode has
  /// been seen recently the full list is used again.
  static Future<PlayEpisode> pickFresh(
    EnvironmentMode mode, {
    Random? random,
    int remember = 3,
  }) async {
    final candidates = forMode(await loadAll(), mode);
    if (candidates.isEmpty) {
      throw StateError('No PLAY episodes are configured for ${mode.name}.');
    }
    final unseen = candidates
        .where((episode) => !_recent.contains(episode.id))
        .toList();
    final pool = unseen.isEmpty ? candidates : unseen;
    final rng = random ?? Random();
    final pick = pool[rng.nextInt(pool.length)];
    _recent
      ..remove(pick.id)
      ..add(pick.id);
    while (_recent.length > remember) {
      _recent.removeAt(0);
    }
    return pick;
  }

  static Future<PlayEpisode> pickForMode(
    EnvironmentMode mode, {
    Random? random,
  }) async {
    final candidates = forMode(await loadAll(), mode);
    if (candidates.isEmpty) {
      throw StateError('No PLAY episodes are configured for ${mode.name}.');
    }
    final rng = random ?? Random();
    return candidates[rng.nextInt(candidates.length)];
  }

  /// Returns configuration problems, useful for unit tests and tooling.
  /// An empty list means the episode definitions reference valid content.
  static List<String> validate(List<PlayEpisode> episodes) {
    final issues = <String>[];
    final seenIds = <String>{};

    for (final episode in episodes) {
      if (!seenIds.add(episode.id)) {
        issues.add('Duplicate episode id: ${episode.id}');
      }
      if (episode.paths.length < 2) {
        issues.add('${episode.id} must provide at least two paths.');
      }
      if (episode.paths.toSet().length != episode.paths.length) {
        issues.add('${episode.id} contains duplicate path labels.');
      }
      if (episode.surpriseIds.isEmpty) {
        issues.add('${episode.id} must provide at least one surprise.');
      }

      final setting = ContentCatalog.settingsById[episode.setting];
      if (setting == null) {
        issues.add(
          '${episode.id} references unknown setting ${episode.setting}.',
        );
      } else {
        if (setting.mode != episode.mode) {
          issues.add(
            '${episode.id} mode does not match setting ${setting.id}.',
          );
        }
        if (!setting.itemIds.contains(episode.objectId)) {
          issues.add(
            '${episode.id} object ${episode.objectId} is not available in ${setting.id}.',
          );
        }
      }

      if (ContentCatalog.get(episode.objectId) == null) {
        issues.add(
          '${episode.id} references unknown catalog item ${episode.objectId}.',
        );
      }

      for (final surpriseId in episode.surpriseIds) {
        if (DiscoveryEngine.event(surpriseId).id != surpriseId) {
          issues.add('${episode.id} references unknown surprise $surpriseId.');
        }
      }
    }

    return List<String>.unmodifiable(issues);
  }

  /// Testing/development helper that allows a test to force a fresh asset read.
  static void clearCache() {
    _cachedEpisodes = null;
    _recent.clear();
  }
}
