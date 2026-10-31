import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vees_adventures/app/app_controller.dart';
import 'package:vees_adventures/app/brand.dart';
import 'package:vees_adventures/app/design_tokens.dart';
import 'package:vees_adventures/app/game_app_scope.dart';
import 'package:vees_adventures/app/theme.dart';
import 'package:vees_adventures/features/explore/explore_screen.dart';
import 'package:vees_adventures/features/hub/adventure_hub.dart';
import 'package:vees_adventures/features/onboarding/onboarding_screen.dart';
import 'package:vees_adventures/models/environment_mode.dart';
import 'package:vees_adventures/services/assets/optional_assets.dart';
import 'package:vees_adventures/widgets/scene_background.dart';
import 'package:vees_adventures/widgets/hiding_spot.dart';
import 'package:vees_adventures/widgets/scene_ui.dart';

Future<AppController> _pump(WidgetTester tester, Widget home) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = AppController();
  await controller.init();
  await tester.pumpWidget(
    GameAppScope(
      controller: controller,
      child: MaterialApp(theme: buildVeeTheme(), home: home),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => OptionalAssets.setForTesting(<String>{}));

  group('design pieces', () {
    testWidgets('step pill shows "Spot • 1 of 3" and three dots', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: StepPill(label: 'Spot', current: 0, total: 3)),
          ),
        ),
      );
      expect(find.text('Spot • 1 of 3'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StepPill),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('coral and mint tags show their text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PillTag('Your next clue'),
                PillTag.coral('Look closer'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Your next clue'), findsOneWidget);
      expect(find.text('Look closer'), findsOneWidget);
    });

    testWidgets('every scene draws without generated artwork', (tester) async {
      for (final kind in SceneKind.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 800,
              height: 450,
              child: SceneBackground(kind: kind),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: kind.name);
      }
    });

    test('indoor mode picks the indoor scene', () {
      expect(SceneKind.forMode(EnvironmentMode.indoor), SceneKind.indoor);
      expect(SceneKind.forMode(EnvironmentMode.outdoor), SceneKind.meadow);
    });

    test('brand and palette match the reference', () {
      expect(AppBrand.name, 'Movement Missions');
      expect(VeeTokens.teal, const Color(0xFF0F5F55));
      expect(VeeTokens.cream, const Color(0xFFFDF6E6));
    });
  });

  group('screens', () {
    testWidgets('first-run card asks a grown-up and can be skipped', (
      tester,
    ) async {
      await _pump(tester, const OnboardingScreen());
      expect(find.text('An adventure awaits!'), findsOneWidget);
      expect(find.text('Your explorer starts here'), findsOneWidget);
      expect(find.text('For grown-ups'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // A bad email is refused kindly.
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('That email doesn’t look quite right.'), findsOneWidget);

      // "Maybe later" moves on to the child's name.
      await tester.tap(find.text('Maybe later'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('What’s your name?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the hub shows the three missions and the movement button', (
      tester,
    ) async {
      await _pump(tester, const AdventureHub());
      expect(find.text('SPOT'), findsOneWidget);
      expect(find.text('EXPLORE'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('Start a movement mission'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EXPLORE: pick a world, peek behind every spot, round ends', (
      tester,
    ) async {
      await _pump(tester, const ExploreScreen());
      expect(find.text('Where do you want to explore?'), findsOneWidget);
      expect(find.text('Surprise me!'), findsOneWidget);

      await tester.tap(find.text('Surprise me!'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HidingSpotView), findsWidgets);
      expect(find.textContaining('Round 1'), findsOneWidget);

      final spots = find.byType(HidingSpotView);
      final count = spots.evaluate().length;
      for (var i = 0; i < count; i++) {
        await tester.tap(spots.at(i), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 750));
      }
      // The round ends on its own after a short pause.
      await tester.pump(const Duration(seconds: 3));

      const endings = [
        'Sparkle surprise!',
        'Something needs your help!',
        'Round complete!',
      ];
      expect(
        endings.any((text) => find.text(text).evaluate().isNotEmpty),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      // Let the quiet save timer finish before the test ends.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
