import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../screens/advanced_core.dart';
import '../screens/cross_platform.dart';
import '../screens/sharing.dart';
import '../screens/simple_mode.dart';
import '../app_scope.dart';
import '../core/build/features.dart';
import '../features/keywords/keywords_screen.dart';
import '../features/settings/language_screen.dart';
import '../screens/supporting.dart';

/// Which builds a screen ships in.
///
/// The handoff makes this a compile-time decision, not a runtime toggle: the
/// Apple builds must not contain discovery code at all. Phase 0 only records the
/// intent — the flag itself lands with the platform layer.
enum Availability {
  /// Every platform.
  all,

  /// Android and desktop only. Discovery (01, 02, 07) and connection sharing
  /// (12, 13, 14) — the latter because iOS cannot hold a background listener.
  noApple,

  /// Android only: per-app routing has no iOS equivalent.
  androidOnly,

  /// Desktop shells.
  desktopOnly,
}

class ScreenSpec {
  const ScreenSpec({
    required this.number,
    required this.title,
    required this.builder,
    this.availability = Availability.all,
    this.wide = false,
  });

  final String number;

  /// Reads the screen's name out of the active localizations.
  final String Function(L) title;
  final WidgetBuilder builder;
  final Availability availability;

  /// The desktop window needs more than a phone's width on the canvas.
  final bool wide;
}

/// Every screen in the design, in the order the canvas lays them out.
///
/// The canvas lists them all so the design stays reviewable. What actually
/// ships is [shippingScreens], which applies the compile-time flags.
final kScreens = <ScreenSpec>[
  // Advanced core. The discovery screens are gated on a const flag so the
  // compiler removes them, and everything they reach, from an Apple build.
  if (Features.enableDiscovery) ...[
    ScreenSpec(
      number: '01',
      title: (l) => l.screenSearch,
      builder: _search,
      availability: Availability.noApple,
    ),
    ScreenSpec(
      number: '02',
      title: (l) => l.screenScanning,
      builder: _scanning,
      availability: Availability.noApple,
    ),
  ],
  ScreenSpec(number: '03', title: (l) => l.screenResults, builder: _results),
  ScreenSpec(number: '04', title: (l) => l.screenConfigDetail, builder: _configDetail),

  // Simple mode
  ScreenSpec(number: 'S1', title: (l) => l.screenSimpleStart, builder: _simpleStart),
  ScreenSpec(number: 'S2', title: (l) => l.screenSimpleSteps, builder: _simpleSteps),
  ScreenSpec(number: 'S3', title: (l) => l.screenSimpleReady, builder: _simpleReady),
  ScreenSpec(number: 'S4', title: (l) => l.screenSimpleConnected, builder: _simpleConnected),

  // Supporting
  ScreenSpec(number: '05', title: (l) => l.screenSettings, builder: _settings),
  ScreenSpec(number: '06', title: (l) => l.screenSaved, builder: _saved),
  if (Features.enableDiscovery)
    ScreenSpec(
      number: '07',
      title: (l) => l.screenKeywords,
      builder: _keywords,
      availability: Availability.noApple,
    ),
  ScreenSpec(number: '08', title: (l) => l.screenProxyDetail, builder: _proxyDetail),
  ScreenSpec(number: '09', title: (l) => l.screenHistory, builder: _history),
  ScreenSpec(number: '10', title: (l) => l.screenErrors, builder: _errors),
  ScreenSpec(number: '11', title: (l) => l.screenOnboarding, builder: _onboarding),

  // Connection sharing. iOS cannot keep a background listener alive, so these
  // are compiled out there rather than shipped as a feature that cannot work.
  if (Features.enableSharing) ...[
    ScreenSpec(
      number: '12',
      title: (l) => l.screenProxyServer,
      builder: _proxyServer,
      availability: Availability.noApple,
    ),
    ScreenSpec(
      number: '13',
      title: (l) => l.screenDevices,
      builder: _devices,
      availability: Availability.noApple,
    ),
    ScreenSpec(
      number: '14',
      title: (l) => l.screenPairing,
      builder: _pairing,
      availability: Availability.noApple,
    ),
  ],
  if (Features.enableSplitTunnel)
    ScreenSpec(
      number: '15',
      title: (l) => l.screenSplitTunnel,
      builder: _splitTunnel,
      availability: Availability.androidOnly,
    ),
  ScreenSpec(number: '16', title: (l) => l.screenSecurity, builder: _security),

  // Cross-platform
  ScreenSpec(
    number: '17',
    title: (l) => l.screenDesktop,
    builder: _desktop,
    availability: Availability.desktopOnly,
    wide: true,
  ),
  ScreenSpec(number: '18', title: (l) => l.screenTray, builder: _tray),
];

Widget _search(BuildContext _) => const SearchScreen();
Widget _scanning(BuildContext _) => const ScanningScreen();
Widget _results(BuildContext _) => const ResultsScreen();
Widget _configDetail(BuildContext _) => const ConfigDetailScreen();
Widget _simpleStart(BuildContext _) => const SimpleStartScreen();
Widget _simpleSteps(BuildContext _) => const SimpleStepsScreen();
Widget _simpleReady(BuildContext _) => const SimpleReadyScreen();
Widget _simpleConnected(BuildContext _) => const SimpleConnectedScreen();
/// Settings is live wherever an [AppScope] is above it: the phrase count is
/// real and the two rows navigate. On the bare canvas it falls back to display.
Widget _settings(BuildContext context) {
  final scope = AppScope.maybeOf(context);
  if (scope == null) return const SettingsScreen();

  return SettingsScreen(
    settings: scope.settings,
    keywordCount: scope.keywordStore?.effective.length,
    onClearResults: scope.resultsStore.clearResults,
    onOpenKeywords: scope.keywordStore == null
        ? null
        : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _framed(KeywordsScreen(store: scope.keywordStore)),
              ),
            ),
    onOpenLanguage: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _framed(LanguageScreen(controller: scope.localeController)),
      ),
    ),
  );
}

Widget _keywordsLive(BuildContext context) {
  final scope = AppScope.maybeOf(context);
  return KeywordsScreen(store: scope?.keywordStore);
}

/// Centres a screen on the page background, the way ScreenPage does.
Widget _framed(Widget child) => Builder(
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFF121016),
        body: SafeArea(
          child: Column(
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: BackButton(color: Color(0xFFB8AFC4)),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
Widget _saved(BuildContext _) => const SavedScreen();
Widget _keywords(BuildContext context) => _keywordsLive(context);
Widget _proxyDetail(BuildContext _) => const ProxyDetailScreen();
Widget _history(BuildContext _) => const HistoryScreen();
Widget _errors(BuildContext _) => const ErrorStatesScreen();
Widget _onboarding(BuildContext _) => const OnboardingScreen();
Widget _proxyServer(BuildContext context) {
  final scope = AppScope.maybeOf(context);
  return ProxyServerScreen(share: scope?.share, connection: scope?.connection);
}
Widget _devices(BuildContext context) =>
    ConnectedDevicesScreen(share: AppScope.maybeOf(context)?.share);
Widget _pairing(BuildContext context) =>
    PairingGuideScreen(share: AppScope.maybeOf(context)?.share);
Widget _splitTunnel(BuildContext context) =>
    SplitTunnelScreen(controller: AppScope.maybeOf(context)?.splitTunnel);
Widget _security(BuildContext context) =>
    SecurityScreen(connection: AppScope.maybeOf(context)?.connection);
Widget _desktop(BuildContext context) {
  final scope = AppScope.maybeOf(context);
  return DesktopScreen(
    connection: scope?.connection,
    results: scope?.resultsStore,
    share: scope?.share,
  );
}
Widget _tray(BuildContext context) {
  final scope = AppScope.maybeOf(context);
  return TrayScreen(connection: scope?.connection, share: scope?.share);
}

/// The screens this build ships.
///
/// The same list: gating happens where the entries are built, with const
/// conditions, so a compiled-out screen is not merely filtered away — the code
/// it reaches is gone from the binary.
List<ScreenSpec> get shippingScreens => kScreens;
