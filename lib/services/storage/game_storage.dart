import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Browser-first local persistence boundary.
///
/// Writes are serialized so concurrent calls to save() cannot finish out of
/// order and allow an older snapshot to overwrite a newer one.
class GameStorage {
  static const String snapshotKey = 'vee.snapshot';

  SharedPreferences? _prefs;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, dynamic>?> readSnapshot() async {
    await init();
    final raw = _prefs?.getString(snapshotKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.fromEntries(
        decoded.entries.where((entry) => entry.key is String).map(
              (entry) => MapEntry(entry.key as String, entry.value),
            ),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> writeSnapshot(Map<String, dynamic> data) {
    // Snapshot a stable JSON string now, rather than retaining mutable lists.
    final encoded = jsonEncode(data);
    final write = _writeQueue.then((_) async {
      await init();
      final prefs = _prefs;
      if (prefs == null) {
        throw StateError('Game storage has not been initialized.');
      }
      final stored = await prefs.setString(snapshotKey, encoded);
      if (!stored) {
        throw StateError('The game progress snapshot could not be stored.');
      }
    });

    // Keep later writes possible after a failure; this caller still receives
    // the original future and can show a retry message.
    _writeQueue = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }

  Future<void> clearSnapshot() async {
    await init();
    await _prefs?.remove(snapshotKey);
  }
}
