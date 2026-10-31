import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/app/navigation.dart';
import 'package:vees_adventures/models/content_catalog.dart';
import 'package:vees_adventures/services/assets/optional_assets.dart';
import 'package:vees_adventures/widgets/item_icon.dart';
import 'package:vees_adventures/widgets/star_counter.dart';
import 'package:vees_adventures/widgets/vee_avatar.dart';
import 'package:vees_adventures/widgets/vee_button.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => OptionalAssets.setForTesting(<String>{}));

  group('optional artwork never breaks the game', () {
    test('missing Vee poses fall back to shipped poses', () {
      OptionalAssets.setForTesting(<String>{});
      expect(
        VeeAvatar.assetFor(VeePose.wave),
        'assets/vee/vee_happy_idle.webp',
      );
      expect(
        VeeAvatar.assetFor(VeePose.thinking),
        'assets/vee/vee_encourage.webp',
      );
      expect(
        VeeAvatar.assetFor(VeePose.surprised),
        'assets/vee/vee_celebration.webp',
      );
      expect(
        VeeAvatar.assetFor(VeePose.sleepy),
        'assets/vee/vee_happy_idle.webp',
      );
    });

    test('added Vee poses are used', () {
      OptionalAssets.setForTesting(<String>{
        'assets/vee/vee_wave.webp',
        'assets/vee/vee_thinking.webp',
      });
      expect(VeeAvatar.assetFor(VeePose.wave), 'assets/vee/vee_wave.webp');
      expect(
        VeeAvatar.assetFor(VeePose.thinking),
        'assets/vee/vee_thinking.webp',
      );
      expect(
        VeeAvatar.assetFor(VeePose.surprised),
        'assets/vee/vee_celebration.webp',
      );
    });

    testWidgets('an item without an icon file shows its emoji', (tester) async {
      final apple = ContentCatalog.get('apple')!;
      await tester.pumpWidget(_wrap(ItemIcon(apple, size: 50)));
      expect(find.text(apple.emoji), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets(
      'when the icon file is bundled the picture replaces the emoji',
      (tester) async {
        OptionalAssets.setForTesting(<String>{ItemIcon.pathFor('apple')});
        final apple = ContentCatalog.get('apple')!;
        await tester.pumpWidget(_wrap(ItemIcon(apple, size: 50)));
        expect(find.byType(Image), findsOneWidget);
        expect(find.text(apple.emoji), findsNothing);
      },
    );

    test('every catalogue item has its icon bundled', () async {
      await OptionalAssets.load();
      for (final item in ContentCatalog.items) {
        expect(
          OptionalAssets.has(ItemIcon.pathFor(item.id)),
          isTrue,
          reason: 'assets/items/${item.id}.webp is missing',
        );
      }
    });

    test('every Vee pose and scene file is bundled', () async {
      await OptionalAssets.load();
      for (final path in const <String>[
        'assets/vee/vee_happy_idle.webp',
        'assets/vee/vee_encourage.webp',
        'assets/vee/vee_celebration.webp',
        'assets/vee/vee_wave.webp',
        'assets/vee/vee_spot.webp',
        'assets/vee/vee_thinking.webp',
        'assets/vee/vee_surprised.webp',
        'assets/vee/vee_sleepy.webp',
        'assets/scenes/bg_meadow.webp',
        'assets/scenes/bg_indoor.webp',
        'assets/scenes/bg_closeup.webp',
        'assets/scenes/door_closed.webp',
        'assets/scenes/door_open.webp',
      ]) {
        expect(OptionalAssets.has(path), isTrue, reason: '$path is missing');
      }
    });

    test('the real asset list can be read from the bundle', () async {
      await OptionalAssets.load();
      expect(OptionalAssets.has('assets/vee/vee_happy_idle.webp'), isTrue);
      expect(OptionalAssets.has('assets/vee/not_a_real_file.webp'), isFalse);
    });
  });

  group('VeeButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(VeeButton(onPressed: () => taps++, child: const Text('Go'))),
      );
      await tester.tap(find.text('Go'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
    });

    testWidgets('does nothing when disabled', (tester) async {
      await tester.pumpWidget(
        _wrap(const VeeButton(onPressed: null, child: Text('Go'))),
      );
      await tester.tap(find.text('Go'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Go'), findsOneWidget);
    });
  });

  group('StarCounter', () {
    testWidgets('counts up to the new total', (tester) async {
      await tester.pumpWidget(_wrap(const StarCounter(stars: 2)));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(_wrap(const StarCounter(stars: 8)));
      await tester.pumpAndSettle();
      expect(find.text('8'), findsOneWidget);
    });
  });

  group('screen changes', () {
    testWidgets('replaceTo fades to the next screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      replaceTo(context, const Text('Next screen')),
                  child: const Text('Start'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Next screen'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
  });
}
