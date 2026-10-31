import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Handles pause/resume for things that do not automatically stop with
/// Flutter's TickerMode, such as video playback or external game loops.
class LandscapePauseRegistry {
  LandscapePauseRegistry._();

  static final Map<String, _PauseEntry> _entries = <String, _PauseEntry>{};

  static bool isPortrait = false;

  static void register({
    required String id,
    required VoidCallback onPause,
    required VoidCallback onResume,
  }) {
    _entries[id] = _PauseEntry(onPause: onPause, onResume: onResume);

    // A widget may register after portrait mode is already active.
    if (isPortrait) {
      onPause();
    }
  }

  static void unregister(String id) {
    _entries.remove(id);
  }

  static void setPortrait(bool value) {
    if (isPortrait == value) return;

    isPortrait = value;

    final entries = List<_PauseEntry>.from(_entries.values);

    for (final entry in entries) {
      if (value) {
        entry.onPause();
      } else {
        entry.onResume();
      }
    }
  }
}

class _PauseEntry {
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _PauseEntry({required this.onPause, required this.onResume});
}

/// Android-only orientation gate.
///
/// Portrait:
/// - pauses app animation
/// - pauses registered video/game loops
/// - shows the rotate-phone prompt
///
/// Landscape:
/// - removes the prompt
/// - resumes registered content
///
/// We intentionally do not force-lock the Android device orientation.
class LandscapeOrientationGate extends StatefulWidget {
  final Widget child;

  const LandscapeOrientationGate({super.key, required this.child});

  @override
  State<LandscapeOrientationGate> createState() =>
      _LandscapeOrientationGateState();
}

class _LandscapeOrientationGateState extends State<LandscapeOrientationGate> {
  bool _isPortrait = false;

  bool _shouldBlock(Size size) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    return size.height > size.width;
  }

  void _syncOrientation(bool portrait) {
    if (!mounted) return;

    if (_isPortrait == portrait) {
      return;
    }

    _isPortrait = portrait;

    LandscapePauseRegistry.setPortrait(portrait);
  }

  void _scheduleOrientationSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Re-read the size here instead of using a stale value from the
      // previous build. This prevents race conditions when the phone is
      // halfway through an Android orientation transition.
      final currentSize = MediaQuery.sizeOf(context);
      final currentPortrait = _shouldBlock(currentSize);

      _syncOrientation(currentPortrait);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final portrait = _shouldBlock(size);

    if (_isPortrait != portrait) {
      _scheduleOrientationSync();
    }

    return TickerMode(
      enabled: !portrait,
      child: Stack(
        fit: StackFit.expand,
        children: [widget.child, if (portrait) const _PortraitPrompt()],
      ),
    );
  }
}

class _PortraitPrompt extends StatelessWidget {
  const _PortraitPrompt();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF4FFF9EE),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.fromLTRB(30, 32, 30, 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7F3EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.screen_rotation_alt_rounded,
                        size: 52,
                        color: VeeTokens.teal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Turn your phone sideways',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: VeeTokens.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Vee's world is made for a wide screen.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: VeeTokens.textSecondaryOnLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2E9BD),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Rotate to landscape to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: VeeTokens.textOnLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
