import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/typography.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/phone_frame.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// S1 · Start — the whole app reduced to one button.
class SimpleStartScreen extends StatelessWidget {
  const SimpleStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Center(child: AppMark(size: 88, radius: 26)),
          const SizedBox(height: S.x22),
          const Center(child: Text('PoPo', style: T.wordmark)),
          const SizedBox(height: S.x14),
          Text(
            l.simpleIntro,
            style: T.simpleBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 44),
          PrimaryButton(l.startSetup, oversized: true),
          const SizedBox(height: S.x18),
          Center(child: TextLink(l.advancedMode)),
        ],
      ),
    );
  }
}

/// S2 · Steps running — three automatic steps, no technical error copy.
class SimpleStepsScreen extends StatelessWidget {
  const SimpleStepsScreen({super.key});

  static List<(String, String, String, StepState, Color)> _steps(L l) => [
        (l.stepSearchTitle, l.stepSearchNote(10, 128), l.stateDone,
            StepState.done, C.success),
        (l.stepHealthTitle, l.stepHealthNote(31), l.stateRunning,
            StepState.running, C.primary),
        (l.stepPickTitle, l.stepPickNote, l.stateWaiting,
            StepState.waiting, C.muted),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x20),
          const Center(child: StatusHero(state: HeroState.working, size: 112)),
          const SizedBox(height: S.x22),
          Center(
            child: HeroCaption(
              title: l.pleaseWait,
              titleStyle: T.hero,
              body: l.stepOfSteps(2, 3),
            ),
          ),
          const SizedBox(height: S.x26),
          for (final (title, note, state, circle, color) in _steps(l)) ...[
            ListCard(
              child: Row(
                children: [
                  StepCircle(circle),
                  const SizedBox(width: S.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: T.simpleListItem.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(note, style: T.small),
                      ],
                    ),
                  ),
                  const SizedBox(width: S.x8),
                  Text(state, style: T.chip.copyWith(color: color)),
                ],
              ),
            ),
            const SizedBox(height: S.x10),
          ],
          const SizedBox(height: S.x14),
          SecondaryButton(l.cancel),
        ],
      ),
    );
  }
}

/// S3 · Ready — the setup finished; one button left.
class SimpleReadyScreen extends StatelessWidget {
  const SimpleReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 36),
          const Center(child: StatusHero(state: HeroState.ready, size: 112)),
          const SizedBox(height: S.x22),
          Center(child: Text(l.ready, style: T.simpleHero)),
          const SizedBox(height: S.x14),
          Text(
            l.readyBody,
            style: T.simpleBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: S.x16),
          const Center(
            child: MonoText(
              'NL · Amsterdam · 42 ms',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: 40),
          PrimaryButton(l.connect, oversized: true),
          const SizedBox(height: S.x12),
          SecondaryButton(l.pickManually),
        ],
      ),
    );
  }
}

/// S4 · Connected + switch — the only screen a simple-mode user sees day to day.
class SimpleConnectedScreen extends StatelessWidget {
  const SimpleConnectedScreen({super.key});

  static List<(String, String, Color, bool)> _servers(L l) => [
        (l.placeNlAmsterdam, '42 ms', C.success, true),
        (l.placeDeFrankfurt, '78 ms', C.success, false),
        (l.placeFiHelsinki, '126 ms', C.warning, false),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x14),
          const Center(child: StatusHero(state: HeroState.working, size: 104)),
          const SizedBox(height: S.x18),
          Center(child: Text(l.connected, style: T.simpleHero)),
          const SizedBox(height: S.x10),
          const Center(
            child: MonoText(
              '42 ms · 00:37:12',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: S.x24),
          SectionTitle(l.pickServer),
          for (final (name, ping, color, selected) in _servers(l))
            Container(
              padding: const EdgeInsets.symmetric(vertical: S.x12),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  AppRadio(selected),
                  const SizedBox(width: S.x12),
                  Expanded(child: Text(name, style: T.simpleListItem)),
                  MonoText(ping, style: T.monoValue.copyWith(color: color)),
                ],
              ),
            ),
          const SizedBox(height: S.x24),
          PrimaryButton(l.disconnect, oversized: true, showConnectedDot: true),
          const SizedBox(height: S.x12),
          GhostButton(
            l.redoSetup,
            expand: true,
            large: true,
            color: C.primaryMuted,
            leading: const AppIcon(AppIcons.refresh, size: 16, color: C.primaryMuted),
          ),
        ],
      ),
    );
  }
}
