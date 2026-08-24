import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/discovery/fetcher.dart';
import '../../core/discovery/http_fetcher.dart';
import '../../core/discovery/models.dart';
import '../../core/discovery/pipeline.dart';
import '../../core/theme/tokens.dart';
import '../../screens/advanced_core.dart';
import '../../screens/simple_mode.dart';
import '../../screens/supporting.dart';
import 'discovery_controller.dart';
import 'http_fetcher_shim.dart';
import 'run_coordinator.dart';

/// The live app: search → test → results, in both modes.
///
/// One coordinator serves both, so simple mode cannot drift from advanced mode.
/// It is created here and disposed with the flow, which is also what closes the
/// HTTP client.
class AppFlow extends StatefulWidget {
  const AppFlow({super.key, this.startInSimpleMode = false});

  final bool startInSimpleMode;

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  RunCoordinator? _coordinator;
  DiscoveryController? _discovery;
  Fetcher? _fetcher;
  late bool _simple = widget.startInSimpleMode;

  /// Small enough to be polite and to finish while the user is watching.
  static const _config = DiscoveryConfig(
    keywordLimit: 24,
    queriesPerEngine: 3,
    pagesPerQuery: 6,
    maxPagesTotal: 40,
    perEngineResultCap: 40,
    engineConcurrency: 2,
    pageConcurrency: 4,
  );

  RunCoordinator _ensure(BuildContext context) {
    final existing = _coordinator;
    if (existing != null) return existing;

    final scope = AppScope.of(context);
    final fetcher = HttpFetcher();
    final discovery = DiscoveryController(
      fetcher: fetcher,
      config: _config.copyWith(perEngineResultCap: scope.settings.perEngineCap),
      keywordStore: scope.keywordStore,
    );
    final coordinator = RunCoordinator(
      discovery: discovery,
      results: scope.resultsStore,
      settings: scope.settings,
    );

    _fetcher = fetcher;
    _discovery = discovery;
    return _coordinator = coordinator;
  }

  @override
  void dispose() {
    _coordinator?.dispose();
    _discovery?.dispose();
    if (_fetcher case final HttpFetcher f) f.close();
    super.dispose();
  }

  Future<void> _start(BuildContext context) async {
    final coordinator = _ensure(context);
    if (coordinator.isRunning) return;

    final navigator = Navigator.of(context);
    final run = coordinator.run();

    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => _simple
          ? _SimpleProgressRoute(coordinator: coordinator)
          : _ScanningRoute(coordinator: coordinator),
    ));
    await run;
  }

  /// Which advanced tab is showing. Search, results and saved are one shell
  /// rather than a stack: a bottom nav that pushes routes accumulates history
  /// the user never asked for.
  int _tab = 0;

  Widget _advancedBody(RunCoordinator coordinator) => switch (_tab) {
        1 => ResultsScreen(
            store: coordinator.results,
            probingSupported: coordinator.probingSupported,
            onRetest: coordinator.retestExisting,
            onNavigate: (index) => setState(() => _tab = index),
            onOpen: (endpoint) => _openDetail(context, coordinator, endpoint),
          ),
        2 => SavedScreen(
            store: coordinator.results,
            onNavigate: (index) => setState(() => _tab = index),
            onOpen: (endpoint) => _openDetail(context, coordinator, endpoint),
          ),
        _ => SearchScreen(
            controller: coordinator.discovery,
            onSearch: () => _start(context),
            onNavigate: (index) => setState(() => _tab = index),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final coordinator = _ensure(context);
    final scope = AppScope.of(context);

    return _Framed(
      results: scope.resultsStore,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _openHistory(context, coordinator),
            icon: const Icon(Icons.history_rounded, color: C.body, size: 20),
          ),
          TextButton(
            onPressed: () => setState(() => _simple = !_simple),
            child: Text(_simple ? 'Advanced' : 'Simple',
                style: const TextStyle(color: C.primaryMuted, fontSize: 13)),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: coordinator,
        builder: (context, _) => _simple
            ? SimpleStartScreen(
                onStart: () => _start(context),
                onAdvanced: () => setState(() => _simple = false),
              )
            : _advancedBody(coordinator),
      ),
    );
  }
}

/// Advanced progress (02), then results (03) when the run finishes.
class _ScanningRoute extends StatelessWidget {
  const _ScanningRoute({required this.coordinator});

  final RunCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return _Framed(
      results: coordinator.results,
      child: ListenableBuilder(
        listenable: coordinator,
        builder: (context, _) => coordinator.isRunning
            ? ScanningScreen(
                controller: coordinator.discovery,
                onStop: coordinator.stop,
              )
            : ResultsScreen(
                store: coordinator.results,
                probingSupported: coordinator.probingSupported,
                onRetest: coordinator.retestExisting,
                onOpen: (endpoint) => _openDetail(context, coordinator, endpoint),
              ),
      ),
    );
  }
}

void _openHistory(BuildContext context, RunCoordinator coordinator) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => _Framed(
      results: coordinator.results,
      child: HistoryScreen(
        store: coordinator.results,
        onFetchSubscription: fetchSubscriptionBody,
      ),
    ),
  ));
}

/// Simple mode: steps (S2), then ready (S3), then connected (S4).
class _SimpleProgressRoute extends StatefulWidget {
  const _SimpleProgressRoute({required this.coordinator});

  final RunCoordinator coordinator;

  @override
  State<_SimpleProgressRoute> createState() => _SimpleProgressRouteState();
}

class _SimpleProgressRouteState extends State<_SimpleProgressRoute> {
  /// Connection is not implemented yet — the tunnel needs the platform layer.
  /// The screen still moves, so the flow can be walked end to end.
  bool _connected = false;
  String? _chosen;

  @override
  Widget build(BuildContext context) {
    final coordinator = widget.coordinator;

    return _Framed(
      results: coordinator.results,
      child: ListenableBuilder(
        listenable: coordinator,
        builder: (context, _) {
          if (coordinator.isRunning || coordinator.stage == RunStage.failed) {
            return SimpleStepsScreen(
              coordinator: coordinator,
              onCancel: () {
                coordinator.stop();
                Navigator.of(context).maybePop();
              },
              onRetry: coordinator.run,
            );
          }

          if (!_connected) {
            return SimpleReadyScreen(
              best: coordinator.best,
              onConnect: coordinator.best == null
                  ? null
                  : () => setState(() {
                        _connected = true;
                        _chosen = coordinator.best?.fingerprint;
                      }),
              onPickManually: () =>
                  _openResults(context, coordinator),
            );
          }

          final fastest = coordinator.results.visible.take(3).toList();
          return SimpleConnectedScreen(
            servers: fastest,
            selected: _chosen,
            onSelect: (endpoint) => setState(() => _chosen = endpoint.fingerprint),
            onDisconnect: () => setState(() => _connected = false),
            onRedoSetup: () {
              setState(() => _connected = false);
              coordinator.run();
            },
          );
        },
      ),
    );
  }
}

void _openResults(BuildContext context, RunCoordinator coordinator) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => _Framed(
      results: coordinator.results,
      child: ResultsScreen(
        store: coordinator.results,
        probingSupported: coordinator.probingSupported,
        onRetest: coordinator.retestExisting,
        onOpen: (endpoint) => _openDetail(context, coordinator, endpoint),
      ),
    ),
  ));
}

void _openDetail(
  BuildContext context,
  RunCoordinator coordinator,
  Endpoint endpoint,
) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => _Framed(
      results: coordinator.results,
      child: endpoint.kind == EndpointKind.proxy
          ? ProxyDetailScreen(
              endpoint: endpoint,
              onToggleSaved: () =>
                  coordinator.results.toggleSaved(endpoint.fingerprint),
            )
          : ConfigDetailScreen(
              endpoint: endpoint,
              onToggleSaved: () =>
                  coordinator.results.toggleSaved(endpoint.fingerprint),
            ),
    ),
  ));
}

/// Centres a phone-width screen on the page background.
class _Framed extends StatelessWidget {
  const _Framed({required this.child, required this.results, this.trailing});

  final Widget child;
  final Object results;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  const BackButton(color: C.body)
                else
                  const SizedBox(width: S.x16),
                const Spacer(),
                ?trailing,
                const SizedBox(width: S.x8),
              ],
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Padding(
                    padding: const EdgeInsets.all(S.x16),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
