import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/build/features.dart';
import '../core/discovery/models.dart';
import '../core/theme/tokens.dart';
import '../features/results/app_settings.dart';
import '../features/results/ping_display.dart';
import '../features/results/results_store.dart';
import '../core/theme/typography.dart';
import '../core/util/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/phone_frame.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// 05 · Settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.settings,
    this.onOpenKeywords,
    this.onOpenLanguage,
    this.onOpenSharing,
    this.onOpenSplitTunnel,
    this.onOpenSecurity,
    this.keywordCount,
    this.onClearResults,
  });

  /// Null on the design canvas, where the rows are display-only.
  final AppSettings? settings;
  final VoidCallback? onClearResults;

  /// Null on the design canvas, where the rows are display-only.
  final VoidCallback? onOpenKeywords;
  final VoidCallback? onOpenLanguage;

  /// The three feature screens that had no way in before. Each stays null when
  /// its feature is compiled out, and a null row is not rendered at all rather
  /// than rendered dead — an entry that leads nowhere is worse than no entry.
  final VoidCallback? onOpenSharing;
  final VoidCallback? onOpenSplitTunnel;
  final VoidCallback? onOpenSecurity;

  /// The live phrase count, when there is a store to read it from.
  final int? keywordCount;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    if (s == null) return _build(context, null);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => _build(context, s),
    );
  }

  Widget _build(BuildContext context, AppSettings? settings) {
    final l = L.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    // Only the values that actually change a run are wired; the rest stay
    // display-only until the feature behind them exists.
    final rows = <(String, String, bool, ValueChanged<bool>?)>[
      (
        l.settingAutoSearch,
        l.settingEveryHours(settings?.autoSearchHours ?? 6),
        true,
        null,
      ),
      (
        l.settingPerEngineCap,
        l.settingItems(settings?.perEngineCap ?? 50),
        true,
        null,
      ),
      (
        l.settingTestTimeout,
        l.settingSeconds(settings?.testTimeoutSeconds ?? 5),
        true,
        null,
      ),
      (
        l.settingAutoRemoveDead,
        l.settingAfterFailedTests(settings?.removeAfterFailures ?? 2),
        settings?.autoRemoveDead ?? true,
        settings?.setAutoRemoveDead,
      ),
      (
        l.settingSimpleMode,
        l.settingSimpleModeNote,
        settings?.simpleMode ?? false,
        settings?.setSimpleMode,
      ),
    ];

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.settings, style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (label, caption, on, onChanged) in rows)
            SettingRow(
              label: label,
              caption: caption,
              trailing: AppToggle(on, onChanged: onChanged),
            ),
          SettingRow(
            label: l.settingKeywords,
            caption: keywordCount == null
                ? l.keywordsIntro
                : l.settingKeywordsValue(keywordCount!),
            trailing: _chevron(onOpenKeywords),
          ),
          SettingRow(
            label: l.settingLanguage,
            // Listed in its own language: a user who cannot read the current
            // one must still be able to find theirs.
            caption: kLanguageNames[languageCode] ?? languageCode,
            trailing: _chevron(onOpenLanguage),
          ),
          if (Features.enableSharing && onOpenSharing != null)
            SettingRow(
              label: l.screenProxyServer,
              caption: l.settingSharingNote,
              trailing: _chevron(onOpenSharing),
            ),
          if (Features.enableSplitTunnel && onOpenSplitTunnel != null)
            SettingRow(
              label: l.screenSplitTunnel,
              caption: l.settingSplitTunnelNote,
              trailing: _chevron(onOpenSplitTunnel),
            ),
          if (onOpenSecurity != null)
            SettingRow(
              label: l.securityTitle,
              caption: l.settingSecurityNote,
              trailing: _chevron(onOpenSecurity),
            ),
          SettingRow(
            label: l.settingTheme,
            caption: l.settingThemeValue,
            trailing: const AppIcon(AppIcons.swap, size: 18, color: C.muted),
          ),
          const SizedBox(height: S.x24),
          DestructiveButton(l.clearAllResults, onTap: onClearResults),
        ],
      ),
    );
  }

  Widget _chevron(VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: AppIcon(
      AppIcons.swap,
      size: 18,
      color: onTap == null ? C.muted : C.primaryMuted,
    ),
  );
}

/// 06 · Saved + bulk actions.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, this.store, this.onOpen, this.onNavigate});

  final ResultsStore? store;
  final void Function(Endpoint)? onOpen;
  final ValueChanged<int>? onNavigate;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  /// Selection is view state, not stored state — it dies with the screen.
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (store == null) return _demo(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _live(context, store),
    );
  }

  Widget _live(BuildContext context, ResultsStore store) {
    final l = L.of(context);
    final saved = store.saved;

    // A saved item removed elsewhere must not linger in the selection.
    _selected.removeWhere((f) => !saved.any((e) => e.fingerprint == f));

    return PhoneFrame(
      nav: BottomNav(
        items: Navs.items(l),
        activeIndex: Navs.saved,
        onTap: widget.onNavigate,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            leading: Text(l.savedTitle, style: T.screenTitle),
            trailing: Text(l.selectedCount(_selected.length), style: T.small),
          ),
          const SizedBox(height: S.x16),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              AppChip(
                l.copyAll,
                filled: true,
                onTap: () => _copy(_targets(saved)),
              ),
              AppChip(
                l.exportSubscription,
                onTap: () => _exportSubscription(_targets(saved)),
              ),
              AppChip(l.qr),
              if (_selected.isNotEmpty)
                AppChip(
                  l.unsaveSelected,
                  onTap: () => store.unsaveAll(_selected.toList()),
                ),
            ],
          ),
          const SizedBox(height: S.x16),
          if (saved.isEmpty)
            Text(l.savedEmpty, style: T.caption)
          else
            for (final endpoint in saved) ...[
              GestureDetector(
                onTap: widget.onOpen == null
                    ? null
                    : () => widget.onOpen!(endpoint),
                behavior: HitTestBehavior.opaque,
                child: ListCard(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      AppCheckbox(
                        _selected.contains(endpoint.fingerprint),
                        onChanged: (on) => setState(() {
                          if (on) {
                            _selected.add(endpoint.fingerprint);
                          } else {
                            _selected.remove(endpoint.fingerprint);
                          }
                        }),
                      ),
                      const SizedBox(width: S.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              endpoint.displayName,
                              style: T.listTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            MonoText(protocolLine(endpoint), style: T.monoSub),
                          ],
                        ),
                      ),
                      const SizedBox(width: S.x8),
                      MonoText(
                        pingLabel(endpoint),
                        style: T.monoValue.copyWith(
                          color: pingColorOf(endpoint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: S.x10),
            ],
        ],
      ),
    );
  }

  /// The selection when there is one, otherwise everything — "copy all" with
  /// nothing ticked should copy the list, not nothing.
  List<Endpoint> _targets(List<Endpoint> saved) => _selected.isEmpty
      ? saved
      : saved.where((e) => _selected.contains(e.fingerprint)).toList();

  void _copy(List<Endpoint> endpoints) {
    if (endpoints.isEmpty) return;
    Clipboard.setData(
      ClipboardData(text: endpoints.map((e) => e.raw).join('\n')),
    );
  }

  /// A subscription export is the base64 of the links, which is the format
  /// every client already understands.
  void _exportSubscription(List<Endpoint> endpoints) {
    if (endpoints.isEmpty) return;
    final body = endpoints.map((e) => e.raw).join('\n');
    Clipboard.setData(ClipboardData(text: base64.encode(utf8.encode(body))));
  }

  Widget _demo(BuildContext context) {
    final l = L.of(context);
    final rows = [
      (l.placeNlAmsterdam, 'VLESS · Reality', '42 ms', C.success, true),
      (l.placeDeFrankfurt, 'VMess · WS+TLS', '78 ms', C.success, true),
      (
        l.placePlWarsaw,
        'HTTPS · 185.244.10.9:8080',
        '154 ms',
        C.warning,
        false,
      ),
      (l.placeTrIstanbul, 'Trojan · gRPC', '—', C.danger, false),
    ];

    return PhoneFrame(
      nav: BottomNav(
        items: Navs.items(l),
        activeIndex: Navs.saved,
        onTap: widget.onNavigate,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            leading: Text(l.savedTitle, style: T.screenTitle),
            trailing: Text(l.selectedCount(2), style: T.small),
          ),
          const SizedBox(height: S.x16),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              AppChip(l.copyAll, filled: true),
              AppChip(l.exportSubscription),
              AppChip(l.qr),
              AppChip(l.testAll),
            ],
          ),
          const SizedBox(height: S.x16),
          for (final (name, proto, ping, color, checked) in rows) ...[
            ListCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  AppCheckbox(checked),
                  const SizedBox(width: S.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: T.listTitle),
                        const SizedBox(height: 2),
                        MonoText(proto, style: T.monoSub),
                      ],
                    ),
                  ),
                  const SizedBox(width: S.x8),
                  MonoText(ping, style: T.monoValue.copyWith(color: color)),
                ],
              ),
            ),
            const SizedBox(height: S.x10),
          ],
        ],
      ),
    );
  }
}

/// 08 · Proxy detail.
class ProxyDetailScreen extends StatelessWidget {
  const ProxyDetailScreen({super.key, this.endpoint, this.onToggleSaved});

  final Endpoint? endpoint;
  final VoidCallback? onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final e = endpoint;
    final now = DateTime.now();
    final address = e == null ? '51.15.42.7:1080' : '${e.host}:${e.port}';

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.proxyDetailTitle, style: T.screenTitle),
          const SizedBox(height: S.x24),
          Center(child: MonoText(address, style: T.monoHero)),
          const SizedBox(height: S.x10),
          Center(
            child: Text(
              e?.displayName ?? l.placeFiHelsinki,
              style: T.buttonSecondary.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: S.x14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (e == null || e.health != Health.dead)
                _Badge(l.badgePortOpen, C.success),
              const SizedBox(width: S.x8),
              _Badge(e?.protocol.name.toUpperCase() ?? 'Elite', C.primaryMuted),
            ],
          ),
          const SizedBox(height: S.x22),
          MetaRow(l.metaType, e?.protocol.name.toUpperCase() ?? 'SOCKS5'),
          MetaRow(
            l.metaAddress,
            e == null ? '51.15.42.7 : 1080' : '${e.host} : ${e.port}',
          ),
          MetaRow(l.metaAnonymity, 'Elite'),
          MetaRow(
            l.metaHttpsSupport,
            (e?.protocol == Protocol.https || e == null) ? 'yes' : 'unknown',
          ),
          MetaRow(
            l.metaLastPortTest,
            e == null
                ? 'open · 126 ms'
                : (e.lastTestedAt == null
                      ? '—'
                      : '${e.health == Health.dead ? 'closed' : 'open'} · '
                            '${pingLabel(e)} · ${testedAgo(e, now)}'),
            showDivider: false,
          ),
          const SizedBox(height: S.x18),
          PrimaryButton(
            l.copyIpPort,
            onTap: () => Clipboard.setData(ClipboardData(text: address)),
          ),
          const SizedBox(height: S.x10),
          SplitRow(
            start: SecondaryButton(l.testPort),
            end: SecondaryButton(l.openInV2rayNG),
          ),
          const SizedBox(height: S.x14),
          Center(child: TextLink(l.reportBroken, color: C.danger)),
        ],
      ),
    );
  }
}

/// A small outlined badge — "port open", the protocol name.
class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: S.x12),
    decoration: BoxDecoration(
      borderRadius: R.pill,
      border: Border.all(color: color.withValues(alpha: 0.45)),
    ),
    child: Text(label, style: T.chip.copyWith(color: color)),
  );
}

/// 09 · History + import.
///
/// On the Apple builds, where discovery is compiled out, the import block is the
/// app's only way to get a server in — so it is a real, working control here
/// rather than a placeholder.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.store, this.onFetchSubscription});

  final ResultsStore? store;

  /// Fetches a subscription URL and returns its body. Injected because it needs
  /// the network, which this screen otherwise does not touch.
  final Future<String?> Function(String url)? onFetchSubscription;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _urlController = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importFromClipboard() async {
    final store = widget.store;
    if (store == null) return;

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!mounted) return;

    if (text.trim().isEmpty) {
      setState(() => _message = L.of(context).clipboardEmpty);
      return;
    }
    final count = store.importFromText(text, source: 'clipboard');
    setState(
      () => _message = count == 0
          ? L.of(context).importedNothing
          : L.of(context).importedCount(count),
    );
  }

  Future<void> _importFromUrl() async {
    final store = widget.store;
    final fetch = widget.onFetchSubscription;
    if (store == null || fetch == null) return;

    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    final body = await fetch(url);
    if (!mounted) return;

    final count = body == null ? 0 : store.importSubscription(body, url: url);
    setState(() {
      _busy = false;
      _message = count == 0
          ? L.of(context).importedNothing
          : L.of(context).importedCount(count);
      if (count > 0) _urlController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (store == null) return _build(context, null);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, ResultsStore? store) {
    final l = L.of(context);
    final runs = store?.history ?? const <RunRecord>[];

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.historyTitle, style: T.screenTitle),
          const SizedBox(height: S.x14),
          if (store == null)
            for (final (at, meta) in _demoRuns(l)) _runRow(l, at, meta)
          else if (runs.isEmpty)
            Text(l.noResultsYet, style: T.caption)
          else
            for (final run in runs)
              _runRow(
                l,
                _formatWhen(context, run.at),
                l.runSummary(run.found, run.healthy, run.engines),
              ),
          const SizedBox(height: S.x24),
          SectionTitle(l.importTitle),
          if (store == null)
            SplitRow(
              start: SecondaryButton(l.subscriptionLink),
              end: SecondaryButton(l.fromClipboard),
            )
          else ...[
            Container(
              padding: const EdgeInsetsDirectional.only(start: S.x16, end: 6),
              decoration: BoxDecoration(
                color: C.surfaceElevated,
                borderRadius: R.pill,
                border: hairlineBorder(),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      enabled: !_busy,
                      style: T.caption.copyWith(color: C.heading),
                      cursorColor: C.primary,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: l.pasteSubscription,
                        hintStyle: T.caption,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  GhostButton(
                    l.importAction,
                    onTap: _busy ? null : _importFromUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x10),
            SecondaryButton(l.fromClipboard, onTap: _importFromClipboard),
          ],
          if (_message != null) ...[
            const SizedBox(height: S.x10),
            Text(_message!, style: T.small.copyWith(color: C.primaryMuted)),
          ],
        ],
      ),
    );
  }

  Widget _runRow(L l, String at, String meta) => Container(
    padding: const EdgeInsets.symmetric(vertical: S.x14),
    decoration: const BoxDecoration(border: hairlineBottom),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(at, style: T.listTitle),
              const SizedBox(height: 3),
              Text(meta, style: T.small),
            ],
          ),
        ),
        const SizedBox(width: S.x8),
        GhostButton(l.runAgain),
      ],
    ),
  );

  String _formatWhen(BuildContext context, DateTime at) {
    final l = L.of(context);
    final now = DateTime.now();
    final time =
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;

    if (days == 0) return l.historyToday(time);
    if (days == 1) return l.historyYesterday(time);
    return l.historyDaysAgo(days);
  }

  static List<(String, String)> _demoRuns(L l) => [
    (l.historyToday('14:20'), l.runSummary(128, 31, 8)),
    (l.historyYesterday('09:05'), l.runSummary(94, 22, 8)),
    (l.historyDaysAgo(3), l.runSummary(151, 40, 10)),
  ];
}

/// 10 · Empty & error states. Every one names a next action.
class ErrorStatesScreen extends StatelessWidget {
  const ErrorStatesScreen({super.key});

  static List<(Color, String, String, String)> _states(L l) => [
    (
      C.muted,
      l.emptyNoResultsTitle,
      l.emptyNoResultsBody,
      l.emptyNoResultsAction,
    ),
    (C.danger, l.errorOfflineTitle, l.errorOfflineBody, l.errorOfflineAction),
    (
      C.warning,
      l.errorCaptchaTitle('Yandex'),
      l.errorCaptchaBody,
      l.errorCaptchaAction,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.errorStatesTitle, style: T.screenTitle),
          const SizedBox(height: S.x16),
          for (final (dot, title, body, action) in _states(l)) ...[
            ListCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusDot(dot),
                      const SizedBox(width: S.x10),
                      Expanded(child: Text(title, style: T.listTitle)),
                    ],
                  ),
                  const SizedBox(height: S.x8),
                  Text(body, style: T.caption),
                  const SizedBox(height: S.x12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GhostButton(action),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x12),
          ],
        ],
      ),
    );
  }
}

/// 11 · Onboarding + safety.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.onDone, this.onSkip});

  /// Dismisses onboarding for good. Null on the design canvas, where the screen
  /// is only being looked at.
  final VoidCallback? onDone;

  /// Same effect as [onDone] — skipping still counts as having seen it, because
  /// showing this again to someone who deliberately dismissed it is a bug.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x20),
          const Center(child: AppMark(size: 88, radius: 26)),
          const SizedBox(height: S.x22),
          Center(child: Text(l.onboardTitle, style: T.onboardTitle)),
          const SizedBox(height: S.x14),
          Text(l.onboardBody, style: T.caption, textAlign: TextAlign.center),
          const SizedBox(height: S.x20),
          const PagerDots(count: 2, active: 0),
          const SizedBox(height: S.x24),
          Container(
            padding: const EdgeInsets.all(S.x16),
            decoration: BoxDecoration(
              color: C.warnPanelBg,
              borderRadius: R.mdAll,
              border: Border.all(color: C.warnPanelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.warningTitle,
                  style: T.listTitle.copyWith(color: C.warning),
                ),
                const SizedBox(height: S.x8),
                Text(l.warningBody, style: T.caption),
              ],
            ),
          ),
          const SizedBox(height: S.x24),
          PrimaryButton(l.gotIt, onTap: onDone),
          const SizedBox(height: S.x14),
          Center(child: TextLink(l.skip, onTap: onSkip ?? onDone)),
        ],
      ),
    );
  }
}
