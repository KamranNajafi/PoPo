import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'core/theme/tokens.dart';
import 'core/theme/typography.dart';
import 'core/util/locale_controller.dart';
import 'core/build/features.dart';
import 'core/util/prefs.dart';
import 'features/keywords/keyword_store.dart';
import 'features/results/app_settings.dart';
import 'core/tunnel/tunnel_service.dart';
import 'features/results/results_store.dart';
import 'features/sharing/share_controller.dart';
import 'features/tunnel/connection_controller.dart';
import 'features/tunnel/split_tunnel_controller.dart';
import 'gallery/gallery_page.dart';
import 'l10n/app_localizations.dart';

export 'gallery/gallery_page.dart' show ScreenPage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPrefs.load();
  runApp(PoPoApp(prefs: prefs));
}

class PoPoApp extends StatefulWidget {
  const PoPoApp({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<PoPoApp> createState() => _PoPoAppState();
}

class _PoPoAppState extends State<PoPoApp> {
  late final LocaleController _locale = LocaleController(widget.prefs);
  // Constructed behind const flags: a controller built unconditionally keeps
  // everything it references alive in the binary, which is exactly what the
  // Apple builds must not ship.
  late final KeywordStore? _keywords =
      Features.enableDiscovery ? KeywordStore(prefs: widget.prefs) : null;
  late final ResultsStore _results = ResultsStore(prefs: widget.prefs);
  late final AppSettings _settings = AppSettings(widget.prefs);
  late final TunnelService _tunnel = createTunnelService();
  late final ConnectionController _connection =
      ConnectionController(service: _tunnel);
  late final ShareController? _share = Features.enableSharing
      ? ShareController(service: _tunnel, prefs: widget.prefs)
      : null;
  late final SplitTunnelController? _splitTunnel =
      Features.enableSplitTunnel ? SplitTunnelController(prefs: widget.prefs) : null;

  @override
  void dispose() {
    _locale.dispose();
    _keywords?.dispose();
    _results.dispose();
    _settings.dispose();
    _connection.dispose();
    _share?.dispose();
    _splitTunnel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      prefs: widget.prefs,
      localeController: _locale,
      keywordStore: _keywords,
      resultsStore: _results,
      settings: _settings,
      connection: _connection,
      share: _share,
      splitTunnel: _splitTunnel,
      child: ListenableBuilder(
        listenable: _locale,
        builder: (context, _) => MaterialApp(
          title: 'PoPo',
          debugShowCheckedModeBanner: false,

          // Text direction is not hardcoded: Flutter derives it from the active
          // locale, so Persian lays out RTL and English LTR without either being
          // a special case. Technical values opt back into LTR individually
          // through MonoText.
          locale: _locale.locale,
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: C.page,
            fontFamily: kSans,
            colorScheme: const ColorScheme.dark(
              primary: C.primary,
              secondary: C.primaryMuted,
              surface: C.surface,
              error: C.danger,
              onPrimary: C.onPrimary,
              onSurface: C.heading,
            ),
          ),
          home: const GalleryPage(),
        ),
      ),
    );
  }
}
