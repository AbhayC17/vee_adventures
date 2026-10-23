import 'package:flutter/material.dart';

/// Lightweight navigation helpers. Kept separate from app composition so
/// feature screens do not depend on the startup file.
void goTo(BuildContext context, Widget page) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

void replaceTo(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}
