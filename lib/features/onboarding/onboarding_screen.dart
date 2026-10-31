import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/design_tokens.dart';
import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../models/environment_mode.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../widgets/door_art.dart';
import '../../widgets/juicy_tap.dart';
import '../../widgets/scene_background.dart';
import '../../widgets/scene_scaffold.dart';
import '../../widgets/scene_ui.dart';
import '../../widgets/vee_avatar.dart';
import '../../widgets/vee_button.dart';
import '../../widgets/world_shell.dart';
import '../hub/adventure_hub.dart';

/// First-run flow:
///   0. grown-up card ("Your explorer starts here")
///   1. who is exploring (name and age)
///   2. pick a move
///   3. "Your adventure is ready!" with the open door
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  String emailError = '';
  bool saving = false;

  int age = 4;
  String movement = 'Hop & reach';

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(value.trim());

  void _go(int to) => setState(() => step = to);

  void _back() {
    if (step > 0) _go(step - 1);
  }

  void _submitEmail() {
    final value = email.text.trim();
    if (value.isEmpty) {
      setState(
        () => emailError = 'Add a grown-up’s email, or tap “Maybe later”.',
      );
      return;
    }
    if (!_validEmail(value)) {
      setState(() => emailError = 'That email doesn’t look quite right.');
      return;
    }
    setState(() => emailError = '');
    _go(1);
  }

  Future<void> _finish() async {
    if (saving) return;
    setState(() => saving = true);
    final controller = GameAppScope.of(context);
    try {
      await controller.updateProfileAndSave(
        ChildProfileState(
          name: name.text.trim().isEmpty ? 'Adventurer' : name.text.trim(),
          age: age,
          movementPreference: movement,
          environmentMode: controller.profile.environmentMode,
          onboardingComplete: true,
        ),
      );
      if (mounted) replaceTo(context, const AdventureHub());
    } catch (_) {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return _grownUpStep();
      case 1:
        return WorldShell(
          showOptionsButton: false,
          showBackButton: true,
          onBack: _back,
          stepLabel: 'Welcome',
          stepCurrent: 0,
          stepTotal: 3,
          left: const VeeAvatar(pose: VeePose.wave),
          speech: 'Hi there! I’m Vee. Who’s coming exploring?',
          right: _whoStep(),
        );
      case 2:
        return WorldShell(
          showOptionsButton: false,
          showBackButton: true,
          onBack: _back,
          stepLabel: 'Welcome',
          stepCurrent: 1,
          stepTotal: 3,
          left: const VeeAvatar(pose: VeePose.encourage),
          speech: 'Pick a move that feels like you!',
          right: _moveStep(),
        );
      default:
        return _readyStep();
    }
  }

  // ── step 0: grown-ups ───────────────────────────────────────────────────

  Widget _grownUpStep() {
    return SceneScaffold(
      scene: SceneKind.meadow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 28, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 4),
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const Positioned(
                        left: 4,
                        top: 18,
                        child: SparkleDashes(size: 40, rotation: -.2),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Transform.scale(
                          scaleX: -1,
                          child: const SparkleDashes(size: 40, rotation: -.2),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 36),
                        child: ScenePlaque(
                          child: Text(
                            'An adventure awaits!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 40,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              color: VeeTokens.textOnLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ask your grown-up to help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => _veeAndDoor(
                        box,
                        open: false,
                        pose: VeePose.wave,
                        doorShare: .62,
                        veeShare: .52,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(flex: 6, child: StageFit(child: _grownUpCard())),
          ],
        ),
      ),
    );
  }

  Widget _grownUpCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
      decoration: BoxDecoration(
        color: VeeTokens.cardWhite,
        borderRadius: BorderRadius.circular(44),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: VeeTokens.shadow,
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: PillTag('For grown-ups', fontSize: 17),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your explorer starts here',
            style: TextStyle(
              fontSize: 38,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A grown-up adds an email to open the door. '
            'It stays on this device and is never sent anywhere.',
            style: TextStyle(
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: VeeTokens.textSecondaryOnLight,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your email',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: VeeTokens.textOnLight,
            ),
          ),
          const SizedBox(height: 8),
          _field(
            controller: email,
            hint: 'you@example.com',
            keyboard: TextInputType.emailAddress,
            onSubmitted: (_) => _submitEmail(),
          ),
          if (emailError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 6),
              child: Text(
                emailError,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VeeTokens.coral,
                ),
              ),
            ),
          const SizedBox(height: 18),
          VeeButton(
            onPressed: _submitEmail,
            icon: Icons.arrow_forward_rounded,
            child: const Text('Continue'),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _go(1),
              child: const Text(
                'Maybe later',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: VeeTokens.teal,
                  decoration: TextDecoration.underline,
                  decorationColor: VeeTokens.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    ValueChanged<String>? onSubmitted,
    bool autofocus = false,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: BorderSide(color: color, width: 3),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      autofocus: autofocus,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: VeeTokens.textOnLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: VeeTokens.textSecondaryOnLight,
        ),
        filled: true,
        fillColor: VeeTokens.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 26,
          vertical: 18,
        ),
        enabledBorder: border(const Color(0xFFD5DDD3)),
        focusedBorder: border(VeeTokens.teal),
      ),
    );
  }

  // ── step 1: name and age ────────────────────────────────────────────────

  Widget _whoStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const PillTag('Your explorer'),
        const SizedBox(height: 14),
        const Text(
          'What’s your name?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: VeeTokens.textOnLight,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _field(
            controller: name,
            hint: 'Type a name',
            capitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'How old are you?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: VeeTokens.textOnLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final n in <int>[2, 3, 4, 5, 6]) _ageChip(n),
          ],
        ),
        const SizedBox(height: 24),
        VeeButton(
          onPressed: () => _go(2),
          icon: Icons.arrow_forward_rounded,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _ageChip(int n) {
    final selected = age == n;
    return JuicyTap(
      semanticLabel: '$n years old',
      onTap: () => setState(() => age = n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? VeeTokens.teal : VeeTokens.cardWhite,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? VeeTokens.teal : const Color(0xFFD5DDD3),
            width: 3,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: VeeTokens.shadow,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          '$n',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: selected ? VeeTokens.textOnDark : VeeTokens.textOnLight,
          ),
        ),
      ),
    );
  }

  // ── step 2: pick a move ─────────────────────────────────────────────────

  Widget _moveStep() {
    final profile = movementProfileFor(movement);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const PillTag('Your move'),
        const SizedBox(height: 12),
        const Text(
          'Choose your adventure move',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: VeeTokens.textOnLight,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            _moveCard('Hop & reach', Icons.bolt_rounded, VeeTokens.yellow),
            _moveCard(
              'March & clap',
              Icons.directions_walk_rounded,
              VeeTokens.meadow,
            ),
            _moveCard(
              'Balance & stretch',
              Icons.self_improvement_rounded,
              VeeTokens.lilac,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          profile.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: VeeTokens.textSecondaryOnLight,
          ),
        ),
        const SizedBox(height: 16),
        VeeButton(
          onPressed: () => _go(3),
          icon: Icons.arrow_forward_rounded,
          child: const Text('Lock in my move'),
        ),
      ],
    );
  }

  Widget _moveCard(String label, IconData icon, Color color) {
    final selected = movement == label;
    return JuicyTap(
      onTap: () => setState(() => movement = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 168,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: VeeTokens.cardWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? VeeTokens.teal : const Color(0xFFD5DDD3),
            width: selected ? 4 : 3,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: VeeTokens.shadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 42, color: VeeTokens.textOnLight),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: VeeTokens.textOnLight,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: selected ? 1 : 0,
              child: const Icon(
                Icons.check_circle_rounded,
                color: VeeTokens.teal,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vee standing beside a door, both resting on the bottom edge. Sizes are
  /// worked out from the space available so the pair always fits, with Vee
  /// overlapping the door's edge a little.
  Widget _veeAndDoor(
    BoxConstraints box, {
    required bool open,
    required VeePose pose,
    int bounce = 0,
    double doorShare = .6,
    double veeShare = .5,
  }) {
    const doorAspect = .93; // height / width of the door pictures
    const veeAspect = 1.12; // height / width of Vee's poses
    var doorW = box.maxWidth * doorShare;
    var doorH = doorW * doorAspect;
    if (doorH > box.maxHeight * .94) {
      doorH = box.maxHeight * .94;
      doorW = doorH / doorAspect;
    }
    var veeW = box.maxWidth * veeShare;
    var veeH = veeW * veeAspect;
    if (veeH > box.maxHeight * .97) {
      veeH = box.maxHeight * .97;
      veeW = veeH / veeAspect;
    }
    var total = veeW + doorW - veeW * .22;
    if (total > box.maxWidth) {
      final k = box.maxWidth / total;
      doorW *= k;
      doorH *= k;
      veeW *= k;
      veeH *= k;
      total = box.maxWidth;
    }
    return Center(
      child: SizedBox(
        width: total,
        height: box.maxHeight,
        child: Stack(
          children: <Widget>[
            Positioned(
              right: 0,
              bottom: 0,
              width: doorW,
              height: doorH,
              child: DoorArt(open: open),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              width: veeW,
              height: veeH,
              child: VeeAvatar(pose: pose, bounce: bounce),
            ),
          ],
        ),
      ),
    );
  }

  // ── step 3: ready ───────────────────────────────────────────────────────

  Widget _readyStep() {
    final controller = GameAppScope.of(context);
    final indoor = controller.profile.environmentMode == EnvironmentMode.indoor;
    return SceneScaffold(
      showOptionsButton: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Column(
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const Positioned(
                  left: 0,
                  top: 6,
                  child: SparkleDashes(size: 48, rotation: -.1),
                ),
                Positioned(
                  right: 0,
                  top: 6,
                  child: Transform.scale(
                    scaleX: -1,
                    child: const SparkleDashes(size: 48, rotation: -.1),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60),
                  child: ScenePlaque(
                    padding: EdgeInsets.symmetric(horizontal: 34, vertical: 10),
                    child: Text(
                      'Your adventure is ready!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 46,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.textOnLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              indoor ? 'Let’s see what’s inside.' : 'Let’s see what’s outside.',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: VeeTokens.textOnLight,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => _veeAndDoor(
                  box,
                  open: true,
                  pose: VeePose.celebration,
                  bounce: 1,
                  doorShare: .5,
                  veeShare: .4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            VeeButton(
              onPressed: saving ? null : _finish,
              icon: Icons.arrow_forward_rounded,
              fontSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
              child: const Text('Let’s explore'),
            ),
          ],
        ),
      ),
    );
  }
}
