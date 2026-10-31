import 'package:flutter/widgets.dart';

import 'app_controller.dart';

/// Exposes the app controller and rebuilds dependants whenever its state changes.
/// This is an InheritedNotifier rather than a plain InheritedWidget so shared
/// UI such as the star counter cannot become stale after a reward is awarded.
class GameAppScope extends InheritedNotifier<AppController> {
  const GameAppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameAppScope>();
    assert(scope != null, 'GameAppScope is missing above this widget.');
    return scope!.notifier!;
  }
}
