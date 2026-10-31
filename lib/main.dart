import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/design_tokens.dart';
import 'services/assets/optional_assets.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Know which optional artwork is bundled before the first screen.
      await OptionalAssets.load();

      // In release builds a widget error would otherwise show a grey box.
      // Show something kind instead. Nothing is sent anywhere.
      if (kReleaseMode) {
        ErrorWidget.builder = (details) => const _FriendlyError();
      }
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      runApp(const VeesAdventuresApp());
    },
    (error, stackTrace) {
      debugPrint('Unhandled error: $error\n$stackTrace');
    },
  );
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: VeeTokens.cream,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Oops! Vee tripped over a rock.\nPlease go back and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: VeeTokens.textOnLight,
            ),
          ),
        ),
      ),
    ),
  );
}
