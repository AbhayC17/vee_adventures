/// Typed progression state for a single PLAY episode.
///
/// The screen renders a stage; this class decides whether a requested
/// transition is valid. Keeping this logic outside the widget makes episodes
/// easier to test and extend without duplicating progression rules.
enum PlayStage {
  intro,
  pathChoice,
  firstMovement,
  firstSurprise,
  puzzle,
  secondMovement,
  mystery,
  finalMovement,
  finaleSurprise,
  ending,
}

class PlayAdventureSession {
  PlayStage _stage = PlayStage.intro;
  String _path = '';
  String _status = '';
  bool _finished = false;

  PlayStage get stage => _stage;
  int get stageIndex => _stage.index;
  String get path => _path;
  String get status => _status;
  bool get isFinished => _finished;

  /// Advances exactly one stage. Skipping, going backwards, or moving after
  /// completion is rejected. A path must be selected before the first movement.
  bool advanceTo(
    PlayStage next, {
    String? path,
    String? status,
  }) {
    if (_finished || next.index != _stage.index + 1) return false;

    final nextPath = path?.trim();
    if (_stage == PlayStage.pathChoice &&
        (nextPath ?? _path).trim().isEmpty) {
      return false;
    }

    if (nextPath != null && nextPath.isNotEmpty) _path = nextPath;
    if (status != null) _status = status;
    _stage = next;
    return true;
  }

  /// Updates feedback without changing progression, for example after an
  /// incorrect puzzle answer. The active stage remains unchanged.
  bool updateStatus(String message) {
    if (_finished) return false;
    _status = message;
    return true;
  }

  /// Marks the episode finished once the final screen has been reached and
  /// its reward has been successfully persisted.
  bool markFinished() {
    if (_finished || _stage != PlayStage.ending) return false;
    _finished = true;
    return true;
  }
}
