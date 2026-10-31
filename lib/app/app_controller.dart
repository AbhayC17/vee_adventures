import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/storage/game_storage.dart';
import '../services/history/game_history.dart';
import '../services/activity_selection/activity_selector.dart';
import '../services/activity_selection/movement_profile.dart';
import '../services/ai/ai_provider.dart';
import '../services/safety/safety_validator.dart';
import '../services/assets/asset_registry.dart';
import '../services/spot/discovery_analyzer.dart';
import '../services/spot/open_discovery.dart';
import '../models/content_catalog.dart';
import '../services/ai/surprise_selector.dart';
import '../models/activity.dart';
import '../models/environment_mode.dart';

class AppController extends ChangeNotifier {
  final GameStorage storage = GameStorage();
  final GameHistory history = GameHistory();
  final ActivitySelector selector = ActivitySelector();
  final SafetyValidator safety = SafetyValidator();
  final AssetRegistry assets = AssetRegistry();
  late final DiscoveryAnalyzer spotAnalyzer;
  final FactMemory factMemory = FactMemory();
  late final SurpriseSelector surpriseSelector;
  late final OpenDiscoveryService openDiscoveryService;
  late final AiProvider aiProvider;
  bool ready = false;
  String? startupError;
  bool _initInProgress = false;
  bool _disposed = false;
  Timer? _saveTimer;

  ChildProfileState profile = ChildProfileState();
  int stars = 0;
  final List<String> discoveries = [];
  final List<String> completedActivities = [];
  final List<String> experienceSignatures = [];
  String lastActivity = '';
  AdventureBlueprint? currentAdventure;
  int progression = 1;

  int totalCompletions = 0;
  final List<String> completionTokens = <String>[];

  /// UI language preference; stored with the same local snapshot as progress.
  /// A grown-up can turn this on to let SPOT name and talk about ANY object in
  /// a photo, not just the game's own catalogue. Off by default.
  bool openDiscoveryEnabled = false;

  /// Recent, local-only events used by the discovery journal and parent report.
  final List<Map<String, dynamic>> activityEvents = <Map<String, dynamic>>[];

  /// Worlds unlock from actual play progress and discoveries.
  Set<String> get unlockedWorldItems {
    final unlocked = <String>{};
    if (totalCompletions >= 1 || discoveries.isNotEmpty) {
      unlocked.add('starter_garden');
    }
    if (discoveries.any((id) => id.toLowerCase().contains('butterfly')) ||
        totalCompletions >= 3) {
      unlocked.add('butterfly_meadow');
    }
    if (totalCompletions >= 5 || discoveries.length >= 4) {
      unlocked.add('curiosity_cave');
    }
    if (totalCompletions >= 8 || discoveries.length >= 7) {
      unlocked.add('rainbow_river');
    }
    return unlocked;
  }

  AppController() {
    // These services are lightweight wrappers; constructing them here keeps
    // retries after a storage error from attempting to reassign late-final
    // fields. Network requests remain lazy inside each provider call.
    aiProvider = OpenAiCompatibleProvider();
    spotAnalyzer = DiscoveryAnalyzer(provider: aiProvider);
    openDiscoveryService = OpenDiscoveryService(provider: aiProvider);
    surpriseSelector = SurpriseSelector(provider: aiProvider);
  }

  Future<void> init() async {
    if (_initInProgress || (ready && startupError == null)) return;
    _initInProgress = true;
    startupError = null;

    try {
      await storage.init();
      final snapshot = await storage.readSnapshot();
      if (snapshot != null) {
        profile = ChildProfileState.fromJson(_map(snapshot['profile']));
        stars = _int(snapshot['stars'], 0).clamp(0, 1000000).toInt();
        discoveries
          ..clear()
          ..addAll(
            _strings(snapshot['discoveries']).map(_normalizeDiscoveryId),
          );
        completedActivities
          ..clear()
          ..addAll(_strings(snapshot['completedActivities']));
        experienceSignatures
          ..clear()
          ..addAll(_strings(snapshot['experienceSignatures']));
        completionTokens
          ..clear()
          ..addAll(_strings(snapshot['completionTokens']).takeLast(300));
        lastActivity = snapshot['lastActivity'] is String
            ? snapshot['lastActivity'] as String
            : '';
        progression = _int(
          snapshot['progression'],
          1,
        ).clamp(1, 1000000).toInt();
        totalCompletions = _int(
          snapshot['totalCompletions'],
          completedActivities.length,
        ).clamp(0, 1000000000).toInt();
        openDiscoveryEnabled = snapshot['openDiscovery'] == true;
        activityEvents
          ..clear()
          ..addAll(_eventMaps(snapshot['activityEvents']).takeLast(300));
        await history.load(_map(snapshot['history']));
        factMemory.load(_map(snapshot['factMemory']));
      }
    } catch (error, stackTrace) {
      startupError = 'Vee could not load saved progress. Please try again.';
      debugPrint('App initialization failed: $error\n$stackTrace');
    } finally {
      _initInProgress = false;
      ready = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> retryInitialization() async {
    if (_initInProgress) return;
    ready = false;
    startupError = null;
    if (!_disposed) notifyListeners();
    await init();
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.fromEntries(
      value.entries
          .where((entry) => entry.key is String)
          .map((entry) => MapEntry(entry.key as String, entry.value)),
    );
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : <String>[];

  static List<Map<String, dynamic>> _eventMaps(Object? value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map(
          (event) => Map<String, dynamic>.fromEntries(
            event.entries
                .where((entry) => entry.key is String)
                .map((entry) => MapEntry(entry.key as String, entry.value)),
          ),
        )
        .toList();
  }

  void _recordEvent(String type, String label) {
    activityEvents.add(<String, dynamic>{
      'type': type,
      'label': label,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    if (activityEvents.length > 300) activityEvents.removeAt(0);
  }

  /// Turns "Discover anything" in SPOT on or off. Saved straight away.
  Future<void> setOpenDiscovery(bool value) async {
    if (openDiscoveryEnabled == value) return;
    final previous = openDiscoveryEnabled;
    openDiscoveryEnabled = value;
    try {
      await save();
    } catch (_) {
      openDiscoveryEnabled = previous;
      if (!_disposed) notifyListeners();
      rethrow;
    }
  }

  Future<void> resetAdventureProgress() async {
    final oldStars = stars;
    final oldDiscoveries = List<String>.from(discoveries);
    final oldCompleted = List<String>.from(completedActivities);
    final oldSignatures = List<String>.from(experienceSignatures);
    final oldTokens = List<String>.from(completionTokens);
    final oldEvents = activityEvents
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final oldProgression = progression;
    final oldTotal = totalCompletions;
    final oldLastActivity = lastActivity;
    final oldHistory = history.toJson();
    final oldFactMemory = factMemory.toJson();
    stars = 0;
    discoveries.clear();
    completedActivities.clear();
    experienceSignatures.clear();
    completionTokens.clear();
    activityEvents.clear();
    progression = 1;
    totalCompletions = 0;
    lastActivity = '';
    await history.load(<String, dynamic>{});
    factMemory.load(<String, dynamic>{});
    try {
      await save();
    } catch (_) {
      stars = oldStars;
      discoveries
        ..clear()
        ..addAll(oldDiscoveries);
      completedActivities
        ..clear()
        ..addAll(oldCompleted);
      experienceSignatures
        ..clear()
        ..addAll(oldSignatures);
      completionTokens
        ..clear()
        ..addAll(oldTokens);
      activityEvents
        ..clear()
        ..addAll(oldEvents);
      progression = oldProgression;
      totalCompletions = oldTotal;
      lastActivity = oldLastActivity;
      await history.load(oldHistory);
      factMemory.load(oldFactMemory);
      rethrow;
    }
  }

  static int _int(Object? value, int fallback) =>
      value is num ? value.toInt() : fallback;

  Map<String, dynamic> _snapshot() => <String, dynamic>{
    'profile': profile.toJson(),
    'stars': stars,
    'discoveries': discoveries,
    'completedActivities': completedActivities,
    'experienceSignatures': experienceSignatures,
    'lastActivity': lastActivity,
    'progression': progression,
    'totalCompletions': totalCompletions,
    'completionTokens': completionTokens,
    'schemaVersion': 3,
    'openDiscovery': openDiscoveryEnabled,
    'activityEvents': activityEvents,
    'history': history.toJson(),
    'factMemory': factMemory.toJson(),
  };

  /// Writes the whole snapshot and then tells the UI something changed.
  /// Use this for changes the player can see (stars, profile, language).
  Future<void> save() async {
    await storage.writeSnapshot(_snapshot());
    if (!_disposed) notifyListeners();
  }

  /// Saves soon, without waking every widget in the app.
  ///
  /// Tapping around a world can add a discovery on nearly every tap. Writing
  /// and re-notifying on each one made the game stutter, so rapid calls are
  /// merged into a single quiet write. [finishActivity] and [save] still write
  /// immediately, and they include anything scheduled here.
  void scheduleSave({Duration delay = const Duration(milliseconds: 600)}) {
    if (_disposed) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(delay, () {
      _saveTimer = null;
      unawaited(_writeQuietly());
    });
  }

  /// Writes any scheduled save right now. Safe to call at any time.
  Future<void> flushPendingSave() async {
    if (_saveTimer == null) return;
    _saveTimer?.cancel();
    _saveTimer = null;
    await _writeQuietly();
  }

  Future<void> _writeQuietly() async {
    try {
      await storage.writeSnapshot(_snapshot());
    } catch (error, stackTrace) {
      debugPrint('Could not save progress: $error\n$stackTrace');
    }
  }

  /// Persists profile changes before notifying the UI. This prevents the root
  /// router from switching screens based on onboardingComplete until the new
  /// profile has safely reached local storage.
  Future<void> updateProfileAndSave(ChildProfileState next) async {
    final previous = profile;
    profile = next;
    try {
      await save();
    } catch (_) {
      profile = previous;
      if (!_disposed) notifyListeners();
      rethrow;
    }
  }

  /// Updates a transient profile in memory. Use updateProfileAndSave for
  /// user-visible profile changes that must survive a browser refresh.
  void updateProfile(ChildProfileState next) {
    profile = next;
    if (!_disposed) notifyListeners();
  }

  Future<void> setEnvironmentMode(EnvironmentMode mode) async {
    if (profile.environmentMode == mode) return;
    final previous = profile.environmentMode;
    profile.environmentMode = mode;
    try {
      await save();
    } catch (_) {
      profile.environmentMode = previous;
      if (!_disposed) notifyListeners();
      rethrow;
    }
  }

  void addStars(int value) {
    if (value <= 0) return;
    stars = (stars + value).clamp(0, 1000000).toInt();
    if (!_disposed) notifyListeners();
  }

  /// Atomically records one activity run, its discoveries, and its reward.
  /// Repeated calls with the same token never award stars twice; replaying an
  /// activity with a fresh token is still allowed.
  Future<bool> finishActivity({
    required String activityId,
    required String completionToken,
    required int starsEarned,
    Iterable<String> discoveryIds = const <String>[],
  }) async {
    final id = activityId.trim();
    final token = completionToken.trim();
    if (id.isEmpty || token.isEmpty || completionTokens.contains(token)) {
      return false;
    }

    final oldStars = stars;
    final oldTotal = totalCompletions;
    final oldProgression = progression;
    final oldActivities = List<String>.from(completedActivities);
    final oldTokens = List<String>.from(completionTokens);
    final oldDiscoveries = List<String>.from(discoveries);
    final oldEvents = activityEvents
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    completionTokens.add(token);
    if (completionTokens.length > 300) completionTokens.removeAt(0);
    completedActivities.add(id);
    totalCompletions++;
    if (totalCompletions % 3 == 0) progression++;
    stars = (stars + starsEarned.clamp(0, 100)).clamp(0, 1000000).toInt();
    for (final item in discoveryIds) {
      final before = discoveries.length;
      _addDiscovery(item);
      if (discoveries.length > before) _recordEvent('discovery_found', item);
    }
    _recordEvent('activity_completed', id);

    try {
      await save();
      return true;
    } catch (_) {
      stars = oldStars;
      totalCompletions = oldTotal;
      progression = oldProgression;
      completedActivities
        ..clear()
        ..addAll(oldActivities);
      completionTokens
        ..clear()
        ..addAll(oldTokens);
      discoveries
        ..clear()
        ..addAll(oldDiscoveries);
      activityEvents
        ..clear()
        ..addAll(oldEvents);
      rethrow;
    }
  }

  String _normalizeDiscoveryId(String raw) {
    final value = raw.trim();
    final match = RegExp(r'^(spot|explore|play)-(spot|explore|play)-(.+)$')
        .firstMatch(value);
    if (match != null && match.group(1) == match.group(2)) {
      return '${match.group(1)}-${match.group(3)}';
    }
    return value;
  }

  void addDiscovery(String id) {
    final before = discoveries.length;
    _addDiscovery(id);
    if (discoveries.length != before) {
      _recordEvent('discovery_found', id);
      scheduleSave();
    }
  }

  /// Catalog item IDs the child has met so far (for the sticker book).
  ///
  /// Items are recorded under several discovery prefixes depending on which
  /// activity found them, so all of them are recognised here.
  Set<String> get collectedItemIds {
    final found = <String>{};
    for (final raw in discoveries) {
      final id = _normalizeDiscoveryId(raw);
      String? key;
      if (id.startsWith('item-')) {
        key = id.substring(5);
      } else if (id.startsWith('discovery-')) {
        key = id.substring(10);
      } else if (id.startsWith('play-puzzle-')) {
        key = id.substring(12);
      } else if (id.startsWith('wow-')) {
        final rest = id.substring(4);
        final dash = rest.indexOf('-');
        key = dash > 0 ? rest.substring(0, dash) : rest;
      }
      if (key != null && ContentCatalog.get(key) != null) found.add(key);
    }
    return found;
  }

  void _addDiscovery(String id) {
    final normalized = _normalizeDiscoveryId(id);
    if (normalized.isEmpty) return;
    for (final old in List<String>.from(discoveries)) {
      final cleaned = _normalizeDiscoveryId(old);
      if (cleaned != old) discoveries[discoveries.indexOf(old)] = cleaned;
    }
    if (!discoveries.contains(normalized)) discoveries.add(normalized);
  }

  /// Legacy adapter for any remaining callers. New activity screens should
  /// use finishActivity so completion and reward changes are persisted together.
  void complete(String id) {
    completedActivities.add(id);
    totalCompletions++;
    if (totalCompletions % 3 == 0) progression++;
    _recordEvent('activity_completed', id);
    save().catchError((Object error, StackTrace stackTrace) {
      debugPrint('Could not save completed activity: $error');
    });
  }

  void recordCompletedAdventure(AdventureBlueprint adventure) {
    history.record(adventure);
    experienceSignatures.add(adventure.signature());
    if (experienceSignatures.length > 24) experienceSignatures.removeAt(0);
  }

  ActivityType chooseActivity() {
    final type = selector.select(
      age: profile.age,
      progression: progression,
      lastActivity: lastActivity,
      history: history,
      movementPreference: profile.movementPreference,
      environmentMode: profile.environmentMode,
    );
    lastActivity = type.name;
    if (!_disposed) notifyListeners();
    return type;
  }

  MovementProfile get movementProfile =>
      movementProfileFor(profile.movementPreference);

  @override
  void dispose() {
    _disposed = true;
    if (_saveTimer != null) {
      _saveTimer?.cancel();
      _saveTimer = null;
      unawaited(_writeQuietly());
    }
    super.dispose();
  }

  int get movementDifficultyLevel => switch (movementProfile) {
    MovementProfile.gentle => 1,
    MovementProfile.steady => 2,
    MovementProfile.energetic => 3,
  };
}

class ChildProfileState {
  String name;
  int age;
  String movementPreference;
  EnvironmentMode environmentMode;
  bool onboardingComplete;

  ChildProfileState({
    this.name = '',
    this.age = 4,
    this.movementPreference = 'Hop & reach',
    this.environmentMode = EnvironmentMode.outdoor,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'movementPreference': movementPreference,
    'environmentMode': environmentMode.name,
    'onboardingComplete': onboardingComplete,
  };

  factory ChildProfileState.fromJson(Map<String, dynamic> j) =>
      ChildProfileState(
        name: j['name'] is String ? j['name'] as String : '',
        age: j['age'] is num
            ? (j['age'] as num).toInt().clamp(2, 6).toInt()
            : 4,
        movementPreference: j['movementPreference'] is String
            ? j['movementPreference'] as String
            : 'Hop & reach',
        environmentMode: EnvironmentMode.values.firstWhere(
          (e) =>
              e.name ==
              (j['environmentMode'] is String
                  ? j['environmentMode'] as String
                  : 'outdoor'),
          orElse: () => EnvironmentMode.outdoor,
        ),
        onboardingComplete: j['onboardingComplete'] is bool
            ? j['onboardingComplete'] as bool
            : false,
      );
}

extension ListTail<T> on List<T> {
  List<T> takeLast(int count) {
    if (count <= 0) return <T>[];
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
