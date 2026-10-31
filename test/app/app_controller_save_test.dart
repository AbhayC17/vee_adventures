import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vees_adventures/app/app_controller.dart';
import 'package:vees_adventures/services/storage/game_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'rapid discoveries are saved once, quietly, without rebuilding the UI',
    () async {
      final app = AppController();
      await app.init();
      var notifications = 0;
      app.addListener(() => notifications++);

      for (final id in <String>[
        'item-apple',
        'item-banana',
        'item-tomato',
        'item-carrot',
        'item-flower',
      ]) {
        app.addDiscovery(id);
      }

      // Nothing is written yet, and no widget was asked to rebuild.
      expect(notifications, 0);
      final storage = GameStorage();
      await storage.init();
      expect(await storage.readSnapshot(), isNull);

      await app.flushPendingSave();
      final snapshot = await storage.readSnapshot();
      expect((snapshot?['discoveries'] as List).length, 5);
      expect(notifications, 0);
      app.dispose();
    },
  );

  test('finishing an activity still saves immediately', () async {
    final app = AppController();
    await app.init();
    app.addDiscovery('item-apple');
    final saved = await app.finishActivity(
      activityId: 'play-test',
      completionToken: 'token-1',
      starsEarned: 6,
    );
    expect(saved, isTrue);

    final storage = GameStorage();
    await storage.init();
    final snapshot = await storage.readSnapshot();
    expect(snapshot?['stars'], 6);
    expect(snapshot?['discoveries'], contains('item-apple'));
    app.dispose();
  });

  test('sticker book recognises items found by every activity', () async {
    final app = AppController();
    await app.init();
    app.addDiscovery('item-apple');
    app.addDiscovery('discovery-rock');
    app.addDiscovery('play-puzzle-flower');
    app.addDiscovery('wow-water-tiny_rainbow');
    app.addDiscovery('spot-kitchen_hunt'); // an adventure badge, not an item
    app.addDiscovery('item-not_a_real_item');

    expect(app.collectedItemIds, <String>{'apple', 'rock', 'flower', 'water'});
    app.dispose();
  });

  test(
    'Discover anything is off by default and the choice is remembered',
    () async {
      final app = AppController();
      await app.init();
      expect(app.openDiscoveryEnabled, isFalse);
      await app.setOpenDiscovery(true);
      app.dispose();

      final again = AppController();
      await again.init();
      expect(again.openDiscoveryEnabled, isTrue);
      await again.setOpenDiscovery(false);
      again.dispose();

      final third = AppController();
      await third.init();
      expect(third.openDiscoveryEnabled, isFalse);
      third.dispose();
    },
  );
}
