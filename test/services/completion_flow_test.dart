import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vees_adventures/app/app_controller.dart';
import 'package:vees_adventures/services/storage/game_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('one completion token awards stars only once', () async {
    final app = AppController();
    await app.init();

    final first = await app.finishActivity(
      activityId: 'play-lost_treasure',
      completionToken: 'test-run-1',
      starsEarned: 6,
      discoveryIds: const <String>['play-lost_treasure'],
    );
    final duplicate = await app.finishActivity(
      activityId: 'play-lost_treasure',
      completionToken: 'test-run-1',
      starsEarned: 6,
      discoveryIds: const <String>['play-lost_treasure'],
    );

    expect(first, isTrue);
    expect(duplicate, isFalse);
    expect(app.stars, 6);
    expect(app.totalCompletions, 1);
    expect(app.completedActivities, <String>['play-lost_treasure']);
    expect(app.discoveries, contains('play-lost_treasure'));
    app.dispose();
  });

  test('completion state restores from saved snapshot', () async {
    final firstApp = AppController();
    await firstApp.init();
    await firstApp.finishActivity(
      activityId: 'spot-garden',
      completionToken: 'test-run-restore',
      starsEarned: 4,
      discoveryIds: const <String>['spot-garden'],
    );
    firstApp.dispose();

    final restoredApp = AppController();
    await restoredApp.init();

    expect(restoredApp.stars, 4);
    expect(restoredApp.totalCompletions, 1);
    expect(restoredApp.completionTokens, contains('test-run-restore'));
    expect(restoredApp.discoveries, contains('spot-garden'));
    final duplicateAfterRestore = await restoredApp.finishActivity(
      activityId: 'spot-garden',
      completionToken: 'test-run-restore',
      starsEarned: 4,
      discoveryIds: const <String>['spot-garden'],
    );
    expect(duplicateAfterRestore, isFalse);
    expect(restoredApp.stars, 4);
    restoredApp.dispose();
  });


  test('malformed legacy fields are recovered with safe defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameStorage.snapshotKey: jsonEncode(<String, dynamic>{
        'profile': <String, dynamic>{'name': 99, 'age': 'unknown'},
        'stars': 'many',
        'completedActivities': <Object?>[false, 'spot-garden'],
        'history': <String, dynamic>{
          'adventures': <Object?>['bad-record', <String, dynamic>{'theme': 1}],
          'movements': 'not-a-list',
          'taskHistory': 'not-a-map',
        },
        'factMemory': <String, dynamic>{'leaf': 'not-a-list'},
      }),
    });

    final app = AppController();
    await app.init();

    expect(app.startupError, isNull);
    expect(app.ready, isTrue);
    expect(app.profile.name, '');
    expect(app.profile.age, 4);
    expect(app.stars, 0);
    expect(app.completedActivities, <String>['spot-garden']);

    app.dispose();
  });

  test('queued writes keep the newest snapshot', () async {
    final storage = GameStorage();
    await storage.init();
    await Future.wait<void>(<Future<void>>[
      storage.writeSnapshot(<String, dynamic>{'value': 1}),
      storage.writeSnapshot(<String, dynamic>{'value': 2}),
    ]);
    expect((await storage.readSnapshot())?['value'], 2);
  });
}
