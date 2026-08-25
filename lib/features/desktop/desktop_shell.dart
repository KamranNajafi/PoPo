import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/build/features.dart';
import '../../core/discovery/models.dart';
import '../../core/theme/tokens.dart';
import '../../screens/advanced_core.dart';
import '../../screens/cross_platform.dart';
import '../../screens/sharing.dart';
import '../../screens/simple_mode.dart';
import '../../screens/supporting.dart';
import '../discovery/http_fetcher_shim.dart';
import '../keywords/keywords_screen.dart';
import '../settings/language_screen.dart';

/// The desktop window.
///
/// The sidebar entries used to be decoration — a fixed selection with no
/// handler. Here they drive the content pane, so the seven destinations the
/// design promised are actually reachable on Linux, Windows and macOS.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selected = 0;

  /// Indices match DesktopScreen's sidebar order.
  static const _dashboard = 0;
  static const _results = 1;
  static const _saved = 2;
  static const _share = 3;
  static const _history = 4;
  static const _simple = 5;
  static const _settings = 6;

  void _open(Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _DesktopSubPage(child: child)),
    );
  }

  Widget? _body(AppScope scope) {
    final store = scope.resultsStore;
    switch (_selected) {
      case _dashboard:
        // Null keeps DesktopScreen's own dashboard, which is the point of it.
        return null;
      case _results:
        return _pane(
          ResultsScreen(store: store, onOpen: (e) => _openDetail(scope, e)),
        );
      case _saved:
        return _pane(
          SavedScreen(store: store, onOpen: (e) => _openDetail(scope, e)),
        );
      case _share:
        final share = scope.share;
        if (share == null) return _pane(const SizedBox.shrink());
        return _pane(
          ProxyServerScreen(
            share: share,
            connection: scope.connection,
            onShowQr: () => _open(PairingGuideScreen(share: share)),
            onOpenDevices: () => _open(ConnectedDevicesScreen(share: share)),
          ),
        );
      case _history:
        return _pane(
          HistoryScreen(
            store: store,
            onFetchSubscription: fetchSubscriptionBody,
          ),
        );
      case _simple:
        return _pane(
          SimpleStartScreen(
            onStart: () => setState(() => _selected = _results),
            onAdvanced: () => setState(() => _selected = _dashboard),
          ),
        );
      case _settings:
        final keywords = scope.keywordStore;
        final split = scope.splitTunnel;
        return _pane(
          SettingsScreen(
            settings: scope.settings,
            keywordCount: keywords?.effective.length,
            onOpenKeywords: keywords == null
                ? null
                : () => _open(KeywordsScreen(store: keywords)),
            onOpenLanguage: () =>
                _open(LanguageScreen(controller: scope.localeController)),
            onOpenSplitTunnel: split == null
                ? null
                : () => _open(SplitTunnelScreen(controller: split)),
            onOpenSecurity: () =>
                _open(SecurityScreen(connection: scope.connection)),
            onClearResults: store.clearResults,
          ),
        );
      default:
        return null;
    }
  }

  void _openDetail(AppScope scope, Endpoint endpoint) {
    _open(
      endpoint.kind == EndpointKind.proxy
          ? ProxyDetailScreen(
              endpoint: endpoint,
              onToggleSaved: () =>
                  scope.resultsStore.toggleSaved(endpoint.fingerprint),
            )
          : ConfigDetailScreen(
              endpoint: endpoint,
              onToggleSaved: () =>
                  scope.resultsStore.toggleSaved(endpoint.fingerprint),
            ),
    );
  }

  /// The phone-shaped screens are reused as-is inside the content pane, capped
  /// so they do not stretch across a wide window and lose their proportions.
  ///
  /// Not a scroll view: these screens are built on PhoneFrame, whose Stack needs
  /// a bounded height. The pane sits inside an Expanded, so filling it gives
  /// them exactly that; scrolling here would leave the Stack unbounded and blow
  /// up at layout.
  Widget _pane(Widget child) => Padding(
    padding: const EdgeInsets.all(S.x20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(S.x16),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              scope.connection,
              scope.resultsStore,
              scope.settings,
              scope.share,
            ]),
            builder: (context, _) => DesktopScreen(
              connection: scope.connection,
              results: scope.resultsStore,
              share: scope.share,
              selected: _selected,
              onNavigate: (index) => setState(() => _selected = index),
              body: _body(scope),
              onConnect: () {
                // Nothing to connect to until a run has produced something, so
                // the dashboard button sends the user where servers come from.
                final best = scope.resultsStore.visible.firstOrNull;
                if (best == null) {
                  setState(
                    () => _selected = Features.enableDiscovery
                        ? _simple
                        : _history,
                  );
                  return;
                }
                scope.connection.connect(best);
              },
              onRedoSetup: () => setState(() => _selected = _simple),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pushed desktop page: the screen on the window background, with a way back.
class _DesktopSubPage extends StatelessWidget {
  const _DesktopSubPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: Column(
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: BackButton(color: C.body),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(S.x20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
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
