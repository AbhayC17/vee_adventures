import 'package:flutter/material.dart';

/// The game's screen change: a quick fade with a tiny zoom. It is cheaper than
/// the default Material transition (which slides and scales two large screens
/// at once) and keeps the shared background feeling steady.
class VeePageRoute<T> extends PageRouteBuilder<T> {
  VeePageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(
                  begin: .985,
                  end: 1,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            ),
          );
        },
      );
}

/// Lightweight navigation helpers. Kept separate from app composition so
/// feature screens do not depend on the startup file.
void goTo(BuildContext context, Widget page) {
  Navigator.of(context).push(VeePageRoute<void>(builder: (_) => page));
}

void replaceTo(BuildContext context, Widget page) {
  Navigator.of(context)
      .pushReplacement(VeePageRoute<void>(builder: (_) => page));
}
