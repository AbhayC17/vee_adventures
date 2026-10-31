import 'package:flutter/material.dart';

import '../models/environment_mode.dart';
import 'game_app_scope.dart';

/// Decodes the artwork the first screens use, right after the first frame, so
/// moving between screens does not wait on image decoding.
///
/// Only the current mode's background and Vee's most-used poses are loaded
/// up front; everything else loads when it is first needed. This keeps memory
/// low on small phones. Failures are ignored (the picture simply loads later).
class AssetPreloader extends StatefulWidget {
  final Widget child;

  const AssetPreloader({super.key, required this.child});

  static const List<String> veePoses = <String>[
    'assets/vee/vee_happy_idle.webp',
    'assets/vee/vee_wave.webp',
    'assets/vee/vee_encourage.webp',
    'assets/vee/vee_spot.webp',
    'assets/vee/vee_celebration.webp',
  ];

  static String sceneFor(EnvironmentMode mode) => mode == EnvironmentMode.indoor
      ? 'assets/scenes/bg_indoor.webp'
      : 'assets/scenes/bg_meadow.webp';

  @override
  State<AssetPreloader> createState() => _AssetPreloaderState();
}

class _AssetPreloaderState extends State<AssetPreloader> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final mode = GameAppScope.of(context).profile.environmentMode;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final paths = <String>[
        AssetPreloader.sceneFor(mode),
        ...AssetPreloader.veePoses,
      ];
      for (final path in paths) {
        if (!mounted) return;
        try {
          await precacheImage(AssetImage(path), context);
        } catch (_) {
          // Not fatal: the image will load when a screen asks for it.
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
