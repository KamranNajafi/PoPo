import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/discovery/models.dart';
import '../../core/discovery/pipeline.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/mono.dart';
import '../../core/widgets/phone_frame.dart';
import '../../core/widgets/surfaces.dart';
import '../../screens/advanced_core.dart';
import '../../app_scope.dart';
import 'discovery_controller.dart';

/// The live 01 → 02 flow, against the real network.
///
/// Owns the controller for its lifetime so a run cannot outlive the screens
/// watching it, and so leaving the flow closes the HTTP client.
class DiscoveryFlowPage extends StatefulWidget {
  const DiscoveryFlowPage({super.key});

  @override
  State<DiscoveryFlowPage> createState() => _DiscoveryFlowPageState();
}

class _DiscoveryFlowPageState extends State<DiscoveryFlowPage> {
  late DiscoveryController _controller;

  /// Kept modest on purpose: a first real run should cost a handful of requests,
  /// not a few hundred. The settings screen owns these numbers later.
  static const _config = DiscoveryConfigPreset.firstRun;

  DiscoveryController? _built;

  @override
  Widget build(BuildContext context) {
    // Built here rather than in initState so it can pick up the keyword store
    // from the scope above.
    _built ??= DiscoveryController(
      config: _config,
      keywordStore: AppScope.maybeOf(context)?.keywordStore,
    );
    _controller = _built!;
    return _page(context);
  }

  @override
  void dispose() {
    _built?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_controller.isRunning) return;

    // Push the scanning screen first so progress is visible from the first
    // engine, rather than after the run resolves.
    final navigator = Navigator.of(context);
    unawaited(_controller.start());
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => _ScanningRoute(controller: _controller),
    ));
  }

  Widget _page(BuildContext context) {
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.all(S.x16),
              child: SearchScreen(controller: _controller, onSearch: _start),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningRoute extends StatelessWidget {
  const _ScanningRoute({required this.controller});

  final DiscoveryController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.all(S.x16),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Column(
                  children: [
                    Expanded(
                      child: ScanningScreen(
                        controller: controller,
                        onStop: controller.stop,
                      ),
                    ),
                    if (!controller.isRunning) ...[
                      const SizedBox(height: S.x12),
                      PrimaryButton(
                        L.of(context).seeResults(controller.results.length),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                _RawResultsRoute(results: controller.results),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain listing of what the run actually returned.
///
/// Deliberately not screen 03: that screen is a finished design for tested,
/// ranked results, and dressing raw untested output in it would misrepresent
/// what the pipeline knows. Latency testing comes next; this is the honest
/// intermediate view.
class _RawResultsRoute extends StatelessWidget {
  const _RawResultsRoute({required this.results});

  final List<Endpoint> results;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.all(S.x16),
              child: PhoneFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.foundCount(results.length), style: T.screenTitle),
                    const SizedBox(height: 6),
                    Text(l.notTestedYet, style: T.small),
                    const SizedBox(height: S.x16),
                    if (results.isEmpty)
                      Text(l.nothingFoundBody, style: T.caption),
                    for (final e in results.take(50)) ...[
                      ListCard(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.label ?? e.protocol.name.toUpperCase(),
                                    style: T.listTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: S.x8),
                                MonoText(
                                  e.score.toStringAsFixed(1),
                                  style: T.monoValue.copyWith(color: C.primaryMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            MonoText('${e.protocol.name} · ${e.host}:${e.port}',
                                style: T.monoSub),
                            const SizedBox(height: 3),
                            Text(l.sourcesCount(e.sources.length), style: T.small),
                          ],
                        ),
                      ),
                      const SizedBox(height: S.x10),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Presets for how hard a run pushes.
abstract final class DiscoveryConfigPreset {
  /// Small enough to be polite and to finish while the user is watching.
  static const firstRun = DiscoveryConfig(
    keywordLimit: 24,
    queriesPerEngine: 3,
    pagesPerQuery: 6,
    maxPagesTotal: 40,
    perEngineResultCap: 40,
    engineConcurrency: 2,
    pageConcurrency: 4,
  );
}
