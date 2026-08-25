import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/build/features.dart';
import '../../core/discovery/fetcher.dart';
import '../../core/discovery/http_fetcher.dart';
import '../../core/discovery/models.dart';
import '../../core/discovery/pipeline.dart';
import '../../core/theme/tokens.dart';
import '../../screens/advanced_core.dart';
import '../../screens/simple_mode.dart';
import '../../screens/sharing.dart';
import '../../screens/supporting.dart';
import '../keywords/keywords_screen.dart';
import '../settings/language_screen.dart';
import 'discovery_controller.dart';
import 'http_fetcher_shim.dart';
import '../tunnel/connection_controller.dart';
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

  /// Builds the discovery machinery, or returns null on a build without it.
  ///
  /// Null is the whole point: constructing a DiscoveryController would keep the
  /// engine list, the scraper and the keyword generator reachable, and the
  /// Apple builds must not contain them at all.
  RunCoordinator? _ensure(BuildContext context) {
    if (!Features.enableDiscovery) return null;

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
    if (coordinator == null || coordinator.isRunning) return;

    final navigator = Navigator.of(context);
    final run = coordinator.run();

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => _simple
            ? _SimpleProgressRoute(
                coordinator: coordinator,
                connection: AppScope.of(context).connection,
              )
            : _ScanningRoute(coordinator: coordinator),
      ),
    );
    await run;
  }

  /// Which advanced tab is showing. Search, results and saved are one shell
  /// rather than a stack: a bottom nav that pushes routes accumulates history
  /// the user never asked for.
  int _tab = 0;

  Widget _advancedBody(RunCoordinator coordinator) => switch (_tab) {
    // With discovery compiled out there is nothing to search, so the shell
    // opens on results and import instead.
    0 when !Features.enableDiscovery => ResultsScreen(
      store: coordinator.results,
      probingSupported: coordinator.probingSupported,
      onRetest: coordinator.retestExisting,
      onNavigate: (index) => setState(() => _tab = index),
      onOpen: (endpoint) => _openDetail(context, coordinator, endpoint),
    ),
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

  /// The shell for a build with no discovery: results, saved and import.
  Widget _importOnlyShell(BuildContext context, AppScope scope) {
    return _Framed(
      results: scope.resultsStore,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _Framed(
                  results: scope.resultsStore,
                  child: HistoryScreen(
                    store: scope.resultsStore,
                    onFetchSubscription: fetchSubscriptionBody,
                  ),
                ),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              color: C.primaryMuted,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () => openSettings(context),
            icon: const Icon(Icons.settings_rounded, color: C.body, size: 20),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: scope.resultsStore,
        builder: (context, _) => _tab == 2
            ? SavedScreen(
                store: scope.resultsStore,
                onNavigate: (index) => setState(() => _tab = index),
              )
            : ResultsScreen(
                store: scope.resultsStore,
                onNavigate: (index) => setState(() => _tab = index),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final coordinator = _ensure(context);

    // No discovery in this build: results and import are the whole app, which
    // is what the handoff prescribes for the Apple builds.
    if (coordinator == null) return _importOnlyShell(context, scope);

    return _Framed(
      results: scope.resultsStore,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _openHistory(context, coordinator),
            icon: const Icon(Icons.history_rounded, color: C.body, size: 20),
          ),
          IconButton(
            onPressed: () => openSettings(context),
            icon: const Icon(Icons.settings_rounded, color: C.body, size: 20),
          ),
          TextButton(
            onPressed: () => setState(() => _simple = !_simple),
            child: Text(
              _simple ? 'Advanced' : 'Simple',
              style: const TextStyle(color: C.primaryMuted, fontSize: 13),
            ),
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
                onOpen: (endpoint) =>
                    _openDetail(context, coordinator, endpoint),
              ),
      ),
    );
  }
}

void _openHistory(BuildContext context, RunCoordinator coordinator) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _Framed(
        results: coordinator.results,
        child: HistoryScreen(
          store: coordinator.results,
          onFetchSubscription: fetchSubscriptionBody,
        ),
      ),
    ),
  );
}

/// Simple mode: steps (S2), then ready (S3), then connected (S4).
class _SimpleProgressRoute extends StatefulWidget {
  const _SimpleProgressRoute({
    required this.coordinator,
    required this.connection,
  });

  final RunCoordinator coordinator;
  final ConnectionController connection;

  @override
  State<_SimpleProgressRoute> createState() => _SimpleProgressRouteState();
}

class _SimpleProgressRouteState extends State<_SimpleProgressRoute> {
  String? _chosen;

  Future<void> _connect(Endpoint endpoint) async {
    setState(() => _chosen = endpoint.fingerprint);
    await widget.connection.connect(endpoint);
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = widget.coordinator;
    final connection = widget.connection;

    return _Framed(
      results: coordinator.results,
      child: ListenableBuilder(
        listenable: Listenable.merge([coordinator, connection]),
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

          if (!connection.isConnected) {
            return SimpleReadyScreen(
              best: coordinator.best,
              connection: connection,
              onConnect: coordinator.best == null
                  ? null
                  : () => _connect(coordinator.best!),
              onPickManually: () => _openResults(context, coordinator),
            );
          }

          final fastest = coordinator.results.visible.take(3).toList();
          return SimpleConnectedScreen(
            servers: fastest,
            selected: _chosen,
            connection: connection,
            // Switching server replaces the core's instance, so the user never
            // sees a disconnected gap.
            onSelect: (endpoint) => _connect(endpoint),
            onDisconnect: connection.disconnect,
            onRedoSetup: () async {
              await connection.disconnect();
              await coordinator.run();
            },
          );
        },
      ),
    );
  }
}

void _openResults(BuildContext context, RunCoordinator coordinator) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _Framed(
        results: coordinator.results,
        child: ResultsScreen(
          store: coordinator.results,
          probingSupported: coordinator.probingSupported,
          onRetest: coordinator.retestExisting,
          onOpen: (endpoint) => _openDetail(context, coordinator, endpoint),
        ),
      ),
    ),
  );
}

void _openDetail(
  BuildContext context,
  RunCoordinator coordinator,
  Endpoint endpoint,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
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
    ),
  );
}

/// Settings and everything reachable from it.
///
/// These eleven screens existed but had no way in except the design canvas,
/// which is the difference between a screen being built and a screen being
/// usable. Each entry is null when its feature is compiled out, so an Apple
/// build shows no sharing row rather than a row that leads nowhere.
void openSettings(BuildContext context) {
  final scope = AppScope.of(context);
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => _SettingsRoute(scope: scope)));
}

class _SettingsRoute extends StatelessWidget {
  const _SettingsRoute({required this.scope});

  final AppScope scope;

  void _push(BuildContext context, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _Framed(results: scope.resultsStore, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keywords = scope.keywordStore;
    final share = scope.share;
    final split = scope.splitTunnel;

    return _Framed(
      results: scope.resultsStore,
      child: ListenableBuilder(
        // The keyword count and every toggle live in these two, so the rows
        // have to rebuild when either moves.
        listenable: Listenable.merge([scope.settings, keywords]),
        builder: (context, _) => SettingsScreen(
          settings: scope.settings,
          keywordCount: keywords?.effective.length,
          onOpenKeywords: keywords == null
              ? null
              : () => _push(context, KeywordsScreen(store: keywords)),
          onOpenLanguage: () => _push(
            context,
            LanguageScreen(controller: scope.localeController),
          ),
          onOpenSharing: share == null
              ? null
              : () => _push(context, _SharingHub(scope: scope)),
          onOpenSplitTunnel: split == null
              ? null
              : () => _push(context, SplitTunnelScreen(controller: split)),
          onOpenSecurity: () =>
              _push(context, SecurityScreen(connection: scope.connection)),
          onClearResults: scope.resultsStore.clearResults,
        ),
      ),
    );
  }
}

/// Proxy server (12), with the devices list (13) and the pairing guide (14)
/// hanging off it — the QR is the point of the screen, so it is one tap away.
class _SharingHub extends StatelessWidget {
  const _SharingHub({required this.scope});

  final AppScope scope;

  void _push(BuildContext context, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _Framed(results: scope.resultsStore, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final share = scope.share;
    return ListenableBuilder(
      listenable: Listenable.merge([share, scope.connection]),
      builder: (context, _) => ProxyServerScreen(
        share: share,
        connection: scope.connection,
        onShowQr: () => _push(context, PairingGuideScreen(share: share)),
        onOpenDevices: () =>
            _push(context, ConnectedDevicesScreen(share: share)),
      ),
    );
  }
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
