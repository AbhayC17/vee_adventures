import 'package:flutter/material.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/app_controller.dart';
import '../../app/design_tokens.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../widgets/world_shell.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/parent_pass.dart';
import '../hub/adventure_hub.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final name = TextEditingController();
  final email = TextEditingController();
  String emailError = '';
  bool passActivated = false;
  bool doorOpen = false;

  int age = 4;
  String movement = 'Hop & reach';

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  void next() => setState(() => step++);

  Future<void> finish() {
    final c = GameAppScope.of(context);
    return c.updateProfileAndSave(
      ChildProfileState(
        name: name.text.trim().isEmpty ? 'Adventurer' : name.text.trim(),
        age: age,
        movementPreference: movement,
        onboardingComplete: true,
      ),
    );
  }

  bool validEmail(String value) {
    final x = value.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(x);
  }

  @override
  Widget build(BuildContext context) {
    final left = Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 370),
          child: Image.asset(
            _veeAsset(),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    final data = _stepData();

    return WorldShell(
      left: left,
      right: data.right,
      speech: data.speech,
      eyebrow: data.eyebrow,
      showTopBar: false,
      showBackButton: step > 0,
      onBack: _back,
    );
  }

  void _back() {
    if (step <= 0) return;
    setState(() {
      step--;
      if (step < 3) {
        doorOpen = false;
      }
    });
  }

  String _veeAsset() {
    if (step == 3) {
      return passActivated
          ? 'assets/vee/vee_celebration.webp'
          : 'assets/vee/vee_encourage.webp';
    }
    if (step >= 5) return 'assets/vee/vee_celebration.webp';
    if (step == 4) return 'assets/vee/vee_encourage.webp';
    return 'assets/vee/vee_happy_idle.webp';
  }

  ({Widget right, String speech, String? eyebrow}) _stepData() {
    switch (step) {
      case 0:
        return (
          right: Center(
            child: WorldButton(
              child: const Text("Let's begin!"),
              onPressed: next,
              color: VeeTokens.yellow,
            ),
          ),
          speech: "Hi there! I’m Vee. Ready for a tiny adventure?",
          eyebrow: 'WELCOME',
        );

      case 1:
        return (
          right: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  size: 54,
                  color: VeeTokens.teal,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: VeeTokens.textOnLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(
                      color: VeeTokens.textSecondaryOnLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    prefixIcon: Icon(Icons.face_3_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => next(),
                ),
                const SizedBox(height: 14),
                WorldButton(
                  child: const Text('That’s me!'),
                  onPressed: name.text.trim().isEmpty ? null : next,
                  color: VeeTokens.teal,
                ),
              ],
            ),
          ),
          speech: 'What should I call my new adventure buddy?',
          eyebrow: 'MISSION 1',
        );

      case 2:
        return (
          right: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                2,
                3,
                4,
                5,
                6,
              ].map((n) {
                return ChoiceChip(
                  selected: age == n,
                  label: Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onSelected: (_) {
                    setState(() => age = n);
                    Future<void>.delayed(
                      const Duration(milliseconds: 220),
                      () {
                        if (mounted) setState(() => step = 3);
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
          speech: 'How many candles are on your cake?',
          eyebrow: 'MISSION 2',
        );

      case 3:
        return (
          right: ParentPass(
            controller: email,
            activated: passActivated,
            open: doorOpen,
            error: emailError,
            onSubmit: () {
              setState(() {
                if (validEmail(email.text)) {
                  emailError = '';
                  passActivated = true;
                } else {
                  emailError = "Let's check that pass!";
                }
              });
            },
            onDoorContinue: () {
              setState(() => doorOpen = true);
              Future<void>.delayed(
                const Duration(milliseconds: 650),
                () {
                  if (mounted) setState(() => step = 4);
                },
              );
            },
          ),
          speech: passActivated
              ? 'Your grown-up’s magic is working!'
              : 'Whoa! Look at that magical door.',
          eyebrow: 'GROWN-UP MAGIC PASS',
        );

      case 4:
        final selectedProfile = movementProfileFor(movement);
        return (
          right: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose your adventure move',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.textOnLight,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap one card. Your choice will guide the kind of adventures Vee gives you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: VeeTokens.textSecondaryOnLight,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _bigChoice(
                      'Hop & reach',
                      'assets/vee/vee_encourage.webp',
                    ),
                    _bigChoice(
                      'March & clap',
                      'assets/vee/vee_happy_idle.webp',
                    ),
                    _bigChoice(
                      'Balance & stretch',
                      'assets/vee/vee_celebration.webp',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    key: ValueKey(movement),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: VeeTokens.mint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '✓ Your move: $movement  •  ${selectedProfile.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.teal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                WorldButton(
                  child: const Text('Lock in my move!'),
                  onPressed: () => setState(() => step = 5),
                  color: VeeTokens.teal,
                ),
              ],
            ),
          ),
          speech: 'Pick a move that feels like you. I’ll use it to tune your adventures!',
          eyebrow: 'MISSION 3',
        );

      default:
        final profile = movementProfileFor(movement);
        return (
          right: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '✨ Your adventure style is ready!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.textOnLight,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: VeeTokens.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movement,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: VeeTokens.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: VeeTokens.textSecondaryOnLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                WorldButton(
                  child: const Text('Enter the Adventure Hub'),
                  onPressed: () async {
                    await finish();
                    if (mounted) replaceTo(context, const AdventureHub());
                  },
                  color: VeeTokens.yellow,
                ),
              ],
            ),
          ),
          speech: 'All set! Vee will use your move to choose adventures and tune their difficulty.',
          eyebrow: 'ADVENTURE READY',
        );
    }
  }

  Widget _bigChoice(String title, String asset) {
    final selected = movement == title;

    return GestureDetector(
      onTap: () => setState(() => movement = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? VeeTokens.yellow.withOpacity(.92)
              : VeeTokens.white.withOpacity(.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? VeeTokens.teal : Colors.transparent,
            width: selected ? 3 : 0,
          ),
          boxShadow: const [
            BoxShadow(
              color: VeeTokens.shadow,
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 125,
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: VeeTokens.textOnLight,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Text(
                '✓ SELECTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: VeeTokens.textOnLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ChoiceChipWidget on ChoiceChip {
  Widget toWidget() => this;
}
