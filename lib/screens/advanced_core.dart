import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/discovery/engines.dart';
import '../core/discovery/models.dart';
import '../features/results/ping_display.dart';
import '../features/results/results_store.dart';
import '../features/discovery/discovery_controller.dart';
import '../features/discovery/engine_row_status.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/util/fa.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/phone_frame.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// 01 · Search — pick engines and keywords, start a run.
///
/// Renders from a [DiscoveryController] when given one, and from the design's
/// static values otherwise. The gallery relies on the second form: a canvas of
/// 22 screens must not fire off 22 network runs to draw itself.
class SearchScreen extends StatelessWidget {
  const SearchScreen({
    super.key,
    this.controller,
    this.onSearch,
    this.onNavigate,
  });

  final DiscoveryController? controller;
  final VoidCallback? onSearch;
  final ValueChanged<int>? onNavigate;

  /// The five phrases the design shows when there is no live run. These are
  /// search terms, not UI copy, so they are not translated.
  static const _demoKeywords = [
    'free v2ray config',
    'vless reality',
    'socks5 list',
    'کانفیگ رایگان',
    'subscription link',
  ];

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) return _build(context, null);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => _build(context, c),
    );
  }

  Widget _build(BuildContext context, DiscoveryController? c) {
    final l = L.of(context);
    final enabledIds =
        c?.enabledEngines ??
        {
          for (final e in kEngines)
            if (e.enabledByDefault) e.id,
        };

    final keywords = c == null
        ? _demoKeywords
        : c.keywords.take(5).map((k) => k.text).toList();

    return PhoneFrame(
      nav: BottomNav(
        items: Navs.items(l),
        activeIndex: Navs.search,
        onTap: onNavigate,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppMark(),
                const SizedBox(width: S.x10),
                Text(
                  'PoPo',
                  style: T.screenTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            trailing: const RoundIconButton(AppIcons.settings),
          ),
          const SizedBox(height: S.x18),
          _SearchField(value: c?.leadKeyword ?? _demoKeywords.first),
          const SizedBox(height: S.x12),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [for (final k in keywords) AppChip(k, selected: true)],
          ),
          const SizedBox(height: S.x22),
          SectionTitle(
            l.searchEngines,
            trailing: RatioText(
              '${formatNumber(context, enabledIds.length)} / '
              '${formatNumber(context, kEngines.length)}',
              style: T.chip.copyWith(color: C.primaryMuted, fontSize: 13),
            ),
          ),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              for (final engine in kEngines)
                if (enabledIds.contains(engine.id))
                  AppChip(
                    engine.name,
                    mono: true,
                    selected: true,
                    leading: StatusDot(_dotFor(engine)),
                    onTap: c == null ? null : () => c.toggleEngine(engine.id),
                  )
                else
                  GestureDetector(
                    onTap: c == null ? null : () => c.toggleEngine(engine.id),
                    child: DisabledChip(engine.name),
                  ),
            ],
          ),
          const SizedBox(height: S.x24),
          PrimaryButton(
            c != null && c.isRunning ? l.searchRunning : l.searchAction,
            onTap: onSearch,
          ),
          if (c?.errorKind != null) ...[
            const SizedBox(height: S.x12),
            Text(
              runErrorMessage(l, c!.errorKind!),
              style: T.small.copyWith(color: C.danger),
            ),
          ],
        ],
      ),
    );
  }

  /// Engines that a plain client usually cannot scrape are marked amber rather
  /// than hidden: the user can still enable them, but the colour says not to
  /// expect much.
  Color _dotFor(SearchEngine engine) => switch (engine.viability) {
    ScrapeViability.good => C.success,
    ScrapeViability.fair => C.success,
    ScrapeViability.poor => C.warning,
    ScrapeViability.needsApiKey => C.danger,
  };
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: S.x16),
      decoration: BoxDecoration(
        color: C.surfaceElevated,
        borderRadius: R.pill,
        border: hairlineBorder(),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.search, size: 16, color: C.muted),
          const SizedBox(width: S.x10),
          Expanded(
            child: MonoText(
              value,
              style: T.monoValue.copyWith(color: C.heading),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 02 · Scanning — progress of a run.
class ScanningScreen extends StatelessWidget {
  const ScanningScreen({super.key, this.controller, this.onStop});

  final DiscoveryController? controller;
  final VoidCallback? onStop;

  /// The design's frozen mid-run state, used on the canvas.
  static List<(String, String, Color)> _demoRows(L l) => [
    ('DuckDuckGo', l.engineResults(14), C.success),
    ('Google', l.engineResults(11), C.success),
    ('Brave', l.engineResults(9), C.success),
    ('Bing', l.engineSearching, C.primary),
    ('Startpage', l.engineQueued, C.muted),
    ('Yandex', l.engineBlocked, C.danger),
  ];

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) return _build(context, null);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => _build(context, c),
    );
  }

  Widget _build(BuildContext context, DiscoveryController? c) {
    final l = L.of(context);
    final rows = c == null
        ? _demoRows(l)
        : [
            for (final state in c.engineStates.values)
              (
                engineById(state.id)?.name ?? state.id,
                engineRowStatus(l, state).label,
                engineRowStatus(l, state).color,
              ),
          ];

    final found = c?.found ?? 47;
    final reporting = c?.enginesReporting ?? 5;
    final running = c == null || c.isRunning;

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Text(
              running ? l.scanningTitle : l.scanFinished,
              style: T.screenTitle,
            ),
            trailing: running
                ? TextLink(l.stop, color: C.primary, onTap: onStop)
                : null,
          ),
          const SizedBox(height: S.x24),
          Center(
            child: StatusHero(
              state: running ? HeroState.working : HeroState.ready,
            ),
          ),
          const SizedBox(height: S.x18),
          Center(
            child: HeroCaption(
              title: l.configsFound(found),
              titleStyle: T.onboardTitle,
              body: running
                  ? l.soFarFromEngines(reporting)
                  : l.fromEngines(reporting),
            ),
          ),
          const SizedBox(height: S.x24),
          for (final (name, status, color) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: S.x12),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  StatusDot(color),
                  const SizedBox(width: S.x10),
                  MonoText(name, style: T.monoName),
                  const Spacer(),
                  Text(status, style: T.chip.copyWith(color: color)),
                ],
              ),
            ),
          if (c?.errorKind != null) ...[
            const SizedBox(height: S.x16),
            Text(
              runErrorMessage(l, c!.errorKind!),
              style: T.small.copyWith(color: C.danger),
            ),
          ],
        ],
      ),
    );
  }
}

/// A result row on 03 — a config or a proxy.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.place,
    required this.protocol,
    required this.ping,
    required this.pingColor,
    required this.age,
    required this.source,
    this.onTap,
    this.onCopy,
    this.saved = false,
    this.onToggleSaved,
  });

  /// Builds the card from a real endpoint.
  factory ResultCard.fromEndpoint(
    Endpoint endpoint, {
    Key? key,
    required DateTime now,
    VoidCallback? onTap,
    VoidCallback? onCopy,
    VoidCallback? onToggleSaved,
  }) => ResultCard(
    key: key,
    place: endpoint.displayName,
    protocol: protocolLine(endpoint),
    ping: pingLabel(endpoint),
    pingColor: pingColorOf(endpoint),
    age: testedAgo(endpoint, now),
    // The host of the page it came from is the useful part; the full URL
    // does not fit and does not help.
    source: endpoint.sources.isEmpty
        ? ''
        : (Uri.tryParse(endpoint.sources.first)?.host ?? ''),
    onTap: onTap,
    onCopy: onCopy,
    saved: endpoint.saved,
    onToggleSaved: onToggleSaved,
  );

  final String place;
  final String protocol;
  final String ping;
  final Color pingColor;
  final String age;
  final String source;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final bool saved;
  final VoidCallback? onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ListCard(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onToggleSaved,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: saved ? C.accentTint : null,
                      borderRadius: const BorderRadius.all(Radius.circular(7)),
                      border: Border.all(color: C.primaryMuted, width: 2),
                    ),
                    child: saved
                        ? const Center(
                            child: AppIcon(
                              AppIcons.bookmark,
                              size: 14,
                              color: C.primaryMuted,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: S.x10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place, style: T.listTitle),
                      const SizedBox(height: 2),
                      MonoText(protocol, style: T.monoSub),
                    ],
                  ),
                ),
                const SizedBox(width: S.x8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MonoText(
                      ping,
                      style: T.monoValue.copyWith(color: pingColor),
                    ),
                    const SizedBox(height: 2),
                    MonoText(age, style: T.timestamp),
                  ],
                ),
              ],
            ),
            const SizedBox(height: S.x10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    L.of(context).sourceLabel(source),
                    style: T.monoSub.copyWith(fontFamily: kSans),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: S.x8),
                GhostButton(L.of(context).copy, onTap: onCopy),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 03 · Results — the found endpoints.
///
/// Real once a [ResultsStore] is passed: counts, filter chips and cards all
/// come from tested data. Without one it renders the design's sample rows, so
/// the canvas still shows the intended state.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    this.store,
    this.probingSupported = true,
    this.onOpen,
    this.onRetest,
    this.onNavigate,
  });

  final ResultsStore? store;

  /// False on platforms with no sockets — the list is shown, but the screen
  /// says why nothing is marked dead.
  final bool probingSupported;

  final void Function(Endpoint)? onOpen;
  final VoidCallback? onRetest;
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = store;
    if (s == null) return _demo(context);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => _live(context, s),
    );
  }

  Widget _live(BuildContext context, ResultsStore store) {
    final l = L.of(context);
    final now = DateTime.now();
    final filters = store.filters;
    final visible = store.visible;
    final protocols = store.availableProtocols;

    return PhoneFrame(
      nav: BottomNav(
        items: Navs.items(l),
        activeIndex: Navs.results,
        onTap: onNavigate,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Text(l.resultsCount(visible.length), style: T.screenTitle),
            trailing: GhostButton(l.retestAll, onTap: onRetest),
          ),
          const SizedBox(height: S.x16),
          _SegmentedTabs(
            labels: [
              '${l.tabConfigs} (${formatNumber(context, store.configCount)})',
              '${l.tabProxies} (${formatNumber(context, store.proxyCount)})',
            ],
            activeIndex: filters.kind == EndpointKind.config ? 0 : 1,
            onTap: (index) => store.setFilters(
              filters.copyWith(
                kind: index == 0 ? EndpointKind.config : EndpointKind.proxy,
                clearProtocol: true,
              ),
            ),
          ),
          const SizedBox(height: S.x14),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppChip(
                  l.filterAll,
                  selected: filters.protocol == null,
                  onTap: () =>
                      store.setFilters(filters.copyWith(clearProtocol: true)),
                ),
                for (final protocol in protocols) ...[
                  const SizedBox(width: S.x8),
                  AppChip(
                    protocol.name.toUpperCase(),
                    selected: filters.protocol == protocol,
                    onTap: () =>
                        store.setFilters(filters.copyWith(protocol: protocol)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: S.x14),
          if (!probingSupported) ...[
            Text(
              l.probingUnsupported,
              style: T.small.copyWith(color: C.warning),
            ),
            const SizedBox(height: S.x12),
          ],
          if (visible.isEmpty)
            Text(l.noResultsYet, style: T.caption)
          else
            for (final endpoint in visible) ...[
              ResultCard.fromEndpoint(
                endpoint,
                now: now,
                onTap: onOpen == null ? null : () => onOpen!(endpoint),
                onCopy: () =>
                    Clipboard.setData(ClipboardData(text: endpoint.raw)),
                onToggleSaved: () => store.toggleSaved(endpoint.fingerprint),
              ),
              const SizedBox(height: S.x10),
            ],
        ],
      ),
    );
  }

  Widget _demo(BuildContext context) {
    final l = L.of(context);
    final filters = [
      'VLESS',
      'VMess',
      'Shadowsocks',
      'Trojan',
      'HTTP/S',
      'SOCKS5',
    ];

    return PhoneFrame(
      nav: BottomNav(
        items: Navs.items(l),
        activeIndex: Navs.results,
        onTap: onNavigate,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Text(l.resultsCount(128), style: T.screenTitle),
            trailing: Text(l.sortByPing, style: T.small),
          ),
          const SizedBox(height: S.x16),
          _SegmentedTabs(labels: [l.tabConfigs, l.tabProxies], activeIndex: 0),
          const SizedBox(height: S.x14),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppChip(l.filterAll, selected: true),
                for (final name in filters) ...[
                  const SizedBox(width: S.x8),
                  AppChip(name),
                ],
              ],
            ),
          ),
          const SizedBox(height: S.x14),
          ResultCard(
            place: l.placeNlAmsterdam,
            protocol: 'VLESS · TCP · Reality',
            ping: '42 ms',
            pingColor: C.success,
            age: '2 min ago',
            source: 'DuckDuckGo',
          ),
          const SizedBox(height: S.x10),
          ResultCard(
            place: l.placeFiHelsinki,
            protocol: 'SOCKS5 · 51.15.42.7:1080',
            ping: '126 ms',
            pingColor: C.warning,
            age: '8 min ago',
            source: 'Brave',
          ),
          const SizedBox(height: S.x10),
          ResultCard(
            place: l.placePlWarsaw,
            protocol: 'HTTPS · 185.244.10.9:8080',
            ping: '154 ms',
            pingColor: C.warning,
            age: '14 min ago',
            source: 'Google',
          ),
          const SizedBox(height: S.x10),
          ResultCard(
            place: l.placeTrIstanbul,
            protocol: 'Trojan · gRPC',
            ping: '318 ms',
            pingColor: C.danger,
            age: '21 min ago',
            source: 'Bing',
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.activeIndex,
    this.onTap,
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.surfaceElevated,
        borderRadius: R.pill,
        border: hairlineBorder(),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: onTap == null ? null : () => onTap!(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: S.x10),
                  decoration: i == activeIndex
                      ? const BoxDecoration(
                          gradient: C.primaryGradient,
                          borderRadius: R.pill,
                        )
                      : null,
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: T.chip.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: i == activeIndex ? C.onPrimary : C.body,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 04 · Config detail.
class ConfigDetailScreen extends StatelessWidget {
  const ConfigDetailScreen({super.key, this.endpoint, this.onToggleSaved});

  /// Null on the design canvas, which shows the sample config.
  final Endpoint? endpoint;
  final VoidCallback? onToggleSaved;

  static const _sampleRaw =
      'vless://8f3c9a20-4d11-4e7a-9b62-1c0d5e8a7f34@185.199.110.12:443'
      '?encryption=none&security=reality&sni=www.microsoft.com&fp=chrome'
      '&pbk=xnQ7Ip9dK2mV0tRfLb3sYcEuHgWj&type=tcp#PoPo-NL-Amsterdam';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final e = endpoint;
    final now = DateTime.now();

    final raw = e?.raw ?? _sampleRaw;
    final title = e?.displayName ?? l.placeNlAmsterdam;
    final ping = e == null ? '42' : (e.ping?.inMilliseconds.toString() ?? '—');
    final pingTint = e == null ? C.success : pingColorOf(e);

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Text(l.configDetailTitle, style: T.screenTitle),
            trailing: GestureDetector(
              onTap: onToggleSaved,
              child: RoundIconButton(
                AppIcons.bookmark,
                square: true,
                onTap: onToggleSaved,
              ),
            ),
          ),
          const SizedBox(height: S.x24),
          Center(
            child: StatusHero(
              state: HeroState.idle,
              size: 96,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      ping,
                      style: T.mono(
                        26,
                        weight: FontWeight.w500,
                        color: pingTint,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text('ms', style: T.mono(12, color: C.muted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: S.x16),
          Center(
            child: Column(
              children: [
                Text(title, style: T.hero, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                MonoText(
                  e == null ? 'VLESS · TCP · Reality' : protocolLine(e),
                  style: T.monoName,
                ),
              ],
            ),
          ),
          const SizedBox(height: S.x22),
          MetaRow(
            l.metaProtocol,
            e == null ? 'VLESS / Reality' : e.protocol.name.toUpperCase(),
          ),
          MetaRow(
            l.metaIpPort,
            e == null ? '185.***.**.12 : 443' : '${e.host} : ${e.port}',
          ),
          MetaRow(
            l.metaLastSuccess,
            e == null
                ? '2 min ago · 42 ms'
                : (e.lastTestedAt == null
                      ? '—'
                      : '${testedAgo(e, now)} · ${pingLabel(e)}'),
          ),
          MetaRow(
            l.metaSource,
            e == null
                ? 'DuckDuckGo · gist.github'
                : (e.sources.isEmpty
                      ? '—'
                      : (Uri.tryParse(e.sources.first)?.host ?? '—')),
            showDivider: false,
          ),
          const SizedBox(height: S.x16),
          SunkenBlock(
            child: MonoText(raw, style: T.monoRaw, textAlign: TextAlign.left),
          ),
          const SizedBox(height: S.x16),
          PrimaryButton(
            l.copyLink,
            onTap: () => Clipboard.setData(ClipboardData(text: raw)),
          ),
          const SizedBox(height: S.x10),
          SplitRow(
            start: SecondaryButton(l.testAgain),
            end: SecondaryButton(l.save, onTap: onToggleSaved),
          ),
        ],
      ),
    );
  }
}
