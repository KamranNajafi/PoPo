import 'package:flutter/widgets.dart';

import '../core/discovery/models.dart';
import '../core/theme/tokens.dart';
import '../features/discovery/run_coordinator.dart';
import '../features/results/ping_display.dart';
import '../features/tunnel/connection_controller.dart';
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
  const SimpleStartScreen({super.key, this.onStart, this.onAdvanced});

  final VoidCallback? onStart;
  final VoidCallback? onAdvanced;

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
          Text(l.simpleIntro, style: T.simpleBody, textAlign: TextAlign.center),
          const SizedBox(height: 44),
          PrimaryButton(l.startSetup, oversized: true, onTap: onStart),
          const SizedBox(height: S.x18),
          Center(child: TextLink(l.advancedMode, onTap: onAdvanced)),
        ],
      ),
    );
  }
}

/// One step card's contents.
class _Step {
  const _Step({
    required this.title,
    required this.note,
    required this.state,
    required this.circle,
    required this.color,
  });

  final String title;
  final String note;
  final String state;
  final StepState circle;
  final Color color;
}

/// S2 · Steps running — three automatic steps, no technical error copy.
class SimpleStepsScreen extends StatelessWidget {
  const SimpleStepsScreen({
    super.key,
    this.coordinator,
    this.onCancel,
    this.onRetry,
  });

  final RunCoordinator? coordinator;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = coordinator;
    if (c == null) return _build(context, null);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => _build(context, c),
    );
  }

  Widget _build(BuildContext context, RunCoordinator? c) {
    final l = L.of(context);
    final stage = c?.stage ?? RunStage.testing;
    final failed = stage == RunStage.failed;

    final search = _state(l, stage, RunStage.searching, failed);
    final health = _state(l, stage, RunStage.testing, failed);
    final pick = _state(l, stage, RunStage.picking, failed);

    final steps = <_Step>[
      _Step(
        title: l.stepSearchTitle,
        note: c == null
            ? l.stepSearchNote(10, 128)
            : l.stepSearchNote(c.enginesReporting, c.foundCount),
        state: search.$1,
        circle: search.$2,
        color: search.$3,
      ),
      _Step(
        title: l.stepHealthTitle,
        note: c == null
            ? l.stepHealthNote(31)
            : l.stepHealthNote(c.healthProgress?.healthy ?? 0),
        state: health.$1,
        circle: health.$2,
        color: health.$3,
      ),
      _Step(
        title: l.stepPickTitle,
        note: l.stepPickNote,
        state: pick.$1,
        circle: pick.$2,
        color: pick.$3,
      ),
    ];

    final currentIndex = switch (stage) {
      RunStage.searching => 1,
      RunStage.testing => 2,
      _ => 3,
    };

    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x20),
          Center(
            child: StatusHero(
              state: failed
                  ? HeroState.idle
                  : (stage == RunStage.done
                        ? HeroState.ready
                        : HeroState.working),
              size: 112,
            ),
          ),
          const SizedBox(height: S.x22),
          Center(
            child: HeroCaption(
              title: failed ? l.errorOfflineTitle : l.pleaseWait,
              titleStyle: T.hero,
              body: l.stepOfSteps(currentIndex.clamp(1, 3), 3),
            ),
          ),
          const SizedBox(height: S.x26),
          for (final step in steps) ...[
            ListCard(
              child: Row(
                children: [
                  StepCircle(step.circle),
                  const SizedBox(width: S.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: T.simpleListItem.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(step.note, style: T.small),
                      ],
                    ),
                  ),
                  const SizedBox(width: S.x8),
                  Text(step.state, style: T.chip.copyWith(color: step.color)),
                ],
              ),
            ),
            const SizedBox(height: S.x10),
          ],
          const SizedBox(height: S.x14),
          // A failed run offers a retry rather than dead-ending on an error.
          if (failed)
            PrimaryButton(l.errorOfflineAction, onTap: onRetry)
          else
            SecondaryButton(l.cancel, onTap: onCancel),
        ],
      ),
    );
  }

  /// The label, circle and colour for one step given the run's stage.
  static (String, StepState, Color) _state(
    L l,
    RunStage stage,
    RunStage mine,
    bool failed,
  ) {
    const order = [RunStage.searching, RunStage.testing, RunStage.picking];
    final currentIndex = order.indexOf(stage);
    final myIndex = order.indexOf(mine);

    if (stage == RunStage.done) return (l.stateDone, StepState.done, C.success);
    if (failed && currentIndex == myIndex) {
      return (l.errorOfflineTitle, StepState.waiting, C.danger);
    }
    if (currentIndex < 0 || currentIndex > myIndex) {
      return (l.stateDone, StepState.done, C.success);
    }
    if (currentIndex == myIndex) {
      return (l.stateRunning, StepState.running, C.primary);
    }
    return (l.stateWaiting, StepState.waiting, C.muted);
  }
}

/// S3 · Ready — the setup finished; one button left.
class SimpleReadyScreen extends StatelessWidget {
  const SimpleReadyScreen({
    super.key,
    this.best,
    this.onConnect,
    this.onPickManually,
    this.connection,
  });

  /// The endpoint a connect would use. Null when nothing usable was found.
  final Endpoint? best;
  final VoidCallback? onConnect;
  final VoidCallback? onPickManually;

  /// Null on the design canvas; live it reports permission and failure states.
  final ConnectionController? connection;

  @override
  Widget build(BuildContext context) {
    final c = connection;
    if (c == null) return _build(context, null);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => _build(context, c),
    );
  }

  Widget _build(BuildContext context, ConnectionController? c) {
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
            best == null && onConnect != null ? l.noHealthyFound : l.readyBody,
            style: T.simpleBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: S.x16),
          Center(
            child: MonoText(
              best == null
                  ? 'NL · Amsterdam · 42 ms'
                  : '${best!.displayName} · ${pingLabel(best!)}',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: best == null ? C.success : pingColorOf(best!),
              ),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            c != null && c.isBusy ? l.connecting : l.connect,
            oversized: true,
            onTap: c != null && c.isBusy ? null : onConnect,
          ),
          const SizedBox(height: S.x12),
          SecondaryButton(l.pickManually, onTap: onPickManually),
          // The honest states: a build with no core, a declined prompt, and a
          // failure are three different things and read as three different
          // things.
          if (c != null && !c.isSupported) ...[
            const SizedBox(height: S.x14),
            Text(
              l.tunnelUnavailable,
              style: T.small.copyWith(color: C.warning),
              textAlign: TextAlign.center,
            ),
          ] else if (c?.error != null) ...[
            const SizedBox(height: S.x14),
            Text(
              switch (c!.error!) {
                ConnectionError.permissionDenied => l.permissionDeclined,
                ConnectionError.unsupportedConfig => l.connectFailed,
                ConnectionError.platformFailed => l.connectFailed,
                ConnectionError.noEndpoint => l.noHealthyFound,
              },
              style: T.small.copyWith(color: C.danger),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// S4 · Connected + switch — the only screen a simple-mode user sees day to day.
class SimpleConnectedScreen extends StatelessWidget {
  const SimpleConnectedScreen({
    super.key,
    this.servers = const [],
    this.selected,
    this.onSelect,
    this.onDisconnect,
    this.onRedoSetup,
    this.connection,
  });

  /// The few fastest endpoints, for the switcher.
  final List<Endpoint> servers;
  final String? selected;
  final void Function(Endpoint)? onSelect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onRedoSetup;
  final ConnectionController? connection;

  Widget _serverRow(
    String name,
    String ping,
    Color color,
    bool isSelected,
    VoidCallback? onTap,
  ) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: S.x12),
      decoration: const BoxDecoration(border: hairlineBottom),
      child: Row(
        children: [
          AppRadio(isSelected, onTap: onTap),
          const SizedBox(width: S.x12),
          Expanded(
            child: Text(
              name,
              style: T.simpleListItem,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          MonoText(ping, style: T.monoValue.copyWith(color: color)),
        ],
      ),
    ),
  );

  static List<(String, String, Color, bool)> _servers(L l) => [
    (l.placeNlAmsterdam, '42 ms', C.success, true),
    (l.placeDeFrankfurt, '78 ms', C.success, false),
    (l.placeFiHelsinki, '126 ms', C.warning, false),
  ];

  @override
  Widget build(BuildContext context) {
    final c = connection;
    if (c == null) return _build(context, null);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => _build(context, c),
    );
  }

  Widget _build(BuildContext context, ConnectionController? c) {
    final l = L.of(context);
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x14),
          const Center(child: StatusHero(state: HeroState.working, size: 104)),
          const SizedBox(height: S.x18),
          Center(
            child: Text(
              c == null || c.isConnected
                  ? l.connected
                  : (c.isBusy ? l.disconnecting : l.connected),
              style: T.simpleHero,
            ),
          ),
          const SizedBox(height: S.x10),
          Center(
            child: MonoText(
              c == null
                  ? '42 ms · 00:37:12'
                  : '${c.endpoint == null ? '—' : pingLabel(c.endpoint!)}'
                        ' · ${formatUptime(c.uptime)}',
              style: const TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: S.x24),
          SectionTitle(l.pickServer),
          if (servers.isEmpty)
            for (final (name, ping, color, isSelected) in _servers(l))
              _serverRow(name, ping, color, isSelected, null)
          else
            for (final endpoint in servers)
              _serverRow(
                endpoint.displayName,
                pingLabel(endpoint),
                pingColorOf(endpoint),
                selected == endpoint.fingerprint,
                onSelect == null ? null : () => onSelect!(endpoint),
              ),
          const SizedBox(height: S.x24),
          PrimaryButton(
            l.disconnect,
            oversized: true,
            showConnectedDot: true,
            onTap: onDisconnect,
          ),
          const SizedBox(height: S.x12),
          GhostButton(
            l.redoSetup,
            onTap: onRedoSetup,
            expand: true,
            large: true,
            color: C.primaryMuted,
            leading: const AppIcon(
              AppIcons.refresh,
              size: 16,
              color: C.primaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}
