import 'package:flutter/services.dart';

/// Gentle vibration feedback that can never crash the game.
///
/// Many devices and browsers have no haptics, and some report an error for
/// the request. These helpers swallow that, so a missing vibration motor is
/// simply silent.
class Haptics {
  Haptics._();

  static void selection() => _run(HapticFeedback.selectionClick);
  static void light() => _run(HapticFeedback.lightImpact);
  static void medium() => _run(HapticFeedback.mediumImpact);

  static void _run(Future<void> Function() call) {
    try {
      call().catchError((Object _) {});
    } catch (_) {
      // Ignore: haptics are optional.
    }
  }
}
