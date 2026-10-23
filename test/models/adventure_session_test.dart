import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/models/adventure_session.dart';

void main() {
  group('PlayAdventureSession', () {
    test('starts at intro and prevents skipping ahead', () {
      final session = PlayAdventureSession();

      expect(session.stage, PlayStage.intro);
      expect(session.advanceTo(PlayStage.puzzle), isFalse);
      expect(session.stage, PlayStage.intro);
    });

    test('requires a path before entering the first movement stage', () {
      final session = PlayAdventureSession();

      expect(session.advanceTo(PlayStage.pathChoice), isTrue);
      expect(session.advanceTo(PlayStage.firstMovement), isFalse);
      expect(
        session.advanceTo(PlayStage.firstMovement, path: 'Garden Path'),
        isTrue,
      );
      expect(session.path, 'Garden Path');
      expect(session.stage, PlayStage.firstMovement);
    });

    test('allows only the next stage and updates status without advancing', () {
      final session = PlayAdventureSession();
      expect(session.advanceTo(PlayStage.pathChoice), isTrue);
      expect(
        session.advanceTo(
          PlayStage.firstMovement,
          path: 'Secret Tree',
        ),
        isTrue,
      );

      expect(session.updateStatus('Try again'), isTrue);
      expect(session.stage, PlayStage.firstMovement);
      expect(session.status, 'Try again');
      expect(session.advanceTo(PlayStage.ending), isFalse);
    });

    test('requires the ending stage and only marks finished once', () {
      final session = PlayAdventureSession();
      expect(session.advanceTo(PlayStage.pathChoice), isTrue);
      for (final stage in PlayStage.values.skip(2)) {
        final ok = session.advanceTo(
          stage,
          path: stage == PlayStage.firstMovement ? 'Garden Path' : null,
        );
        expect(ok, isTrue, reason: 'Could not enter $stage');
      }

      expect(session.markFinished(), isTrue);
      expect(session.isFinished, isTrue);
      expect(session.markFinished(), isFalse);
      expect(session.advanceTo(PlayStage.ending), isFalse);
      expect(session.updateStatus('late update'), isFalse);
    });
  });
}
