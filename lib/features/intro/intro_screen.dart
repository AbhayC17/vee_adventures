import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/navigation.dart';
import '../../widgets/landscape_orientation_gate.dart';
import '../onboarding/onboarding_screen.dart';

/// Full-screen launch cinematic followed by onboarding.
///
/// The cinematic is intentionally one MP4 file. Keeping it as one progressive
/// video avoids creating two video decoders/controllers during startup and
/// allows the browser to begin playback as soon as the MP4 header and first
/// frames are available.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const String _videoAsset = 'assets/intro/intro_video.mp4';

  VideoPlayerController? _video;
  VoidCallback? _videoListener;

  bool _ready = false;
  bool _finished = false;
  bool _starting = false;
  bool _waitingForLandscape = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();

    LandscapePauseRegistry.register(
      id: 'intro-video',
      onPause: _pauseForPortrait,
      onResume: _resumeFromLandscape,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_start());
    });
  }

  void _pauseForPortrait() {
    if (_finished) return;
    _waitingForLandscape = true;
    _video?.pause();
  }

  Future<void> _resumeFromLandscape() async {
    if (_finished || LandscapePauseRegistry.isPortrait) return;

    _waitingForLandscape = false;
    final controller = _video;

    if (controller == null || !controller.value.isInitialized) {
      if (!_starting) await _start();
      return;
    }

    await _resumeController(controller);
  }

  Future<void> _resumeController(VideoPlayerController controller) async {
    if (_finished || LandscapePauseRegistry.isPortrait) return;
    if (!controller.value.isInitialized) return;

    try {
      final duration = controller.value.duration;
      final position = controller.value.position;

      if (duration > Duration.zero && position >= duration) {
        _finish();
        return;
      }

      // Seeking to the current position refreshes the native/video texture
      // after Android orientation changes.
      await controller.pause();
      await controller.seekTo(controller.value.position);

      if (mounted) setState(() {});
      if (_finished || LandscapePauseRegistry.isPortrait) return;

      await controller.play();
    } catch (_) {
      // Keep the intro recoverable if the platform rejects a transient resume.
    }
  }

  Future<void> _start() async {
    if (_finished || _starting || _ready) return;

    _starting = true;
    final controller = VideoPlayerController.asset(_videoAsset);
    _video = controller;

    try {
      await controller.initialize().timeout(const Duration(seconds: 10));
      if (!mounted) return;

      await controller.setLooping(false);
      await controller.setVolume(0);

      _videoListener = _watchVideo;
      controller.addListener(_videoListener!);
      _ready = true;

      if (mounted) setState(() {});

      if (LandscapePauseRegistry.isPortrait) {
        _waitingForLandscape = true;
        return;
      }

      _waitingForLandscape = false;
      await controller.play();
    } catch (_) {
      _fallback();
    } finally {
      _starting = false;
    }
  }

  void _watchVideo() {
    if (_finished || LandscapePauseRegistry.isPortrait) return;

    final value = _video?.value;
    if (value == null || !value.isInitialized) return;

    if (value.duration > Duration.zero && value.position >= value.duration) {
      _finish();
    }
  }

  void _fallback() {
    if (_finished || !mounted) return;

    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(milliseconds: 900), _finish);
    setState(() {});
  }

  void _finish() {
    if (_finished || !mounted) return;

    _finished = true;
    replaceTo(context, const OnboardingScreen());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _video;
    final showVideo =
        _ready && controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (showVideo)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            _fallbackScene(),
        ],
      ),
    );
  }

  Widget _fallbackScene() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/vee/game_background.webp',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
        ),
        Align(
          alignment: const Alignment(-0.58, 0.18),
          child: FractionallySizedBox(
            widthFactor: 0.32,
            heightFactor: 0.68,
            child: Image.asset(
              'assets/vee/vee_happy_idle.webp',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    LandscapePauseRegistry.unregister('intro-video');
    _fallbackTimer?.cancel();

    if (_video != null && _videoListener != null) {
      _video!.removeListener(_videoListener!);
    }

    _video?.dispose();
    super.dispose();
  }
}
