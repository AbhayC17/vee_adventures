import 'dart:async';

import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'brand.dart';
import 'asset_preloader.dart';
import 'game_app_scope.dart';
import 'root_router.dart';
import 'theme.dart';
import '../widgets/landscape_orientation_gate.dart';

class VeesAdventuresApp extends StatefulWidget {
  const VeesAdventuresApp({super.key});

  @override
  State<VeesAdventuresApp> createState() => _VeesAdventuresAppState();
}

class _VeesAdventuresAppState extends State<VeesAdventuresApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController();
    unawaited(controller.init());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameAppScope(
      controller: controller,
      child: MaterialApp(
        title: AppBrand.name,
        debugShowCheckedModeBanner: false,
        theme: buildVeeTheme(),
        home: const LandscapeOrientationGate(
          child: AssetPreloader(child: RootRouter()),
        ),
      ),
    );
  }
}
