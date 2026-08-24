import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/util/fa.dart';
import '../features/sharing/qr_painter.dart';
import '../features/sharing/share_controller.dart';
import '../features/tunnel/connection_controller.dart';
import '../features/tunnel/split_tunnel_controller.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/phone_frame.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// 12 · Proxy server — the local HTTP + SOCKS5 listener other devices route through.
///
/// Android and desktop only: iOS cannot keep a background listener alive, so this
/// screen sits behind the same kind of build flag as discovery.
class ProxyServerScreen extends StatelessWidget {
  const ProxyServerScreen({
    super.key,
    this.share,
    this.onShowQr,
    this.connection,
  });

  /// Null on the design canvas; live it drives the toggle and the meta rows.
  final ShareController? share;
  final ConnectionController? connection;
  final VoidCallback? onShowQr;

  @override
  Widget build(BuildContext context) {
    final s = share;
    if (s == null) return _build(context, null);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => _build(context, s),
    );
  }

  Widget _build(BuildContext context, ShareController? share) {
    final l = L.of(context);
    final on = share?.isEnabled ?? true;
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            leading: Text(l.shareConnection, style: T.screenTitle),
            trailing: AppToggle(
              on,
              onChanged: share == null
                  ? null
                  : (value) =>
                        share.setEnabled(value, upstream: connection?.endpoint),
            ),
          ),
          const SizedBox(height: S.x24),
          Center(
            child: StatusHero(
              state: on ? HeroState.ready : HeroState.idle,
              size: 96,
            ),
          ),
          const SizedBox(height: S.x18),
          Center(
            child: Text(
              on ? l.serverOn : l.shareConnection,
              style: T.connectedHero,
            ),
          ),
          const SizedBox(height: S.x10),
          Center(
            child: MonoText(
              share?.address ?? '192.168.43.1 : 8888',
              style: const TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l.shareDevicesAndUsage(
                share?.activeDeviceCount ?? 3,
                share?.usageToday ?? '1.4 GB',
              ),
              style: T.small,
            ),
          ),
          if (share?.error != null) ...[
            const SizedBox(height: S.x10),
            Center(
              child: Text(
                share!.error!,
                style: T.small.copyWith(color: C.warning),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: S.x22),
          MetaRow(l.metaProxyAddress, share?.hotspotAddress ?? '192.168.43.1'),
          MetaRow(l.metaHttpPort, '${ShareController.httpPort}'),
          MetaRow(l.metaSocksPort, '${ShareController.socksPort}'),
          MetaRow(l.metaUsername, ShareController.username),
          // Masked: the pairing QR carries it, so there is no reason to leave
          // it readable over someone's shoulder.
          MetaRow(
            l.metaPassword,
            '•' * (share?.password.length ?? 8),
            showDivider: false,
          ),
          const SizedBox(height: S.x18),
          PrimaryButton(l.showConnectionQr, onTap: onShowQr),
          const SizedBox(height: S.x10),
          SplitRow(
            start: SecondaryButton(
              l.changePassword,
              onTap: share?.regeneratePassword,
            ),
            end: SecondaryButton(l.turnOnHotspot),
          ),
        ],
      ),
    );
  }
}

/// 13 · Connected devices.
class ConnectedDevicesScreen extends StatelessWidget {
  const ConnectedDevicesScreen({super.key, this.share});

  final ShareController? share;

  static List<(IconData, String, String, String, Color, String)> _devices(
    L l,
  ) => [
    (
      AppIcons.laptop,
      l.deviceWorkLaptop,
      '192.168.43.24',
      l.deviceActive,
      C.success,
      l.deviceUsageToday('840 MB'),
    ),
    (
      AppIcons.tv,
      l.deviceLivingRoomTv,
      '192.168.43.31',
      l.deviceActive,
      C.success,
      l.deviceUsageToday('490 MB'),
    ),
    (
      AppIcons.phone,
      l.deviceSecondPhone,
      '192.168.43.47',
      l.devicePendingApproval,
      C.warning,
      '—',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = share;
    if (s == null) return _build(context, null);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => _build(context, s),
    );
  }

  Widget _build(BuildContext context, ShareController? share) {
    final l = L.of(context);
    final rows = share == null
        ? _devices(l)
        : [
            for (final device in share.devices)
              (
                AppIcons.device,
                device.name,
                device.address,
                switch (device.state) {
                  SharedDeviceState.active => l.deviceActive,
                  SharedDeviceState.awaitingApproval => l.devicePendingApproval,
                  SharedDeviceState.blocked => l.deviceDisconnect,
                },
                switch (device.state) {
                  SharedDeviceState.active => C.success,
                  SharedDeviceState.awaitingApproval => C.warning,
                  SharedDeviceState.blocked => C.danger,
                },
                l.deviceUsageToday(formatBytes(device.bytesToday)),
              ),
          ];

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.connectedDevices, style: T.screenTitle),
          const SizedBox(height: S.x16),
          if (rows.isEmpty) Text(l.noResultsYet, style: T.caption),
          for (final (icon, name, ip, state, color, usage) in rows) ...[
            ListCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIcon(icon, size: 22),
                      const SizedBox(width: S.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: T.listTitle),
                            const SizedBox(height: 2),
                            MonoText(ip, style: T.monoSub),
                          ],
                        ),
                      ),
                      const SizedBox(width: S.x8),
                      Text(state, style: T.chip.copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: S.x12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(usage, style: T.small)),
                      const SizedBox(width: S.x8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GhostButton(l.deviceLimit),
                          const SizedBox(width: S.x8),
                          GhostButton.destructive(l.deviceDisconnect),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x12),
          ],
          const SizedBox(height: S.x8),
          SettingRow(
            label: l.onlyApprovedDevices,
            trailing: AppToggle(
              share?.requireApproval ?? true,
              onChanged: share?.setRequireApproval,
            ),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

/// 14 · Pairing guide — how a second device joins.
class PairingGuideScreen extends StatelessWidget {
  const PairingGuideScreen({super.key, this.share});

  final ShareController? share;

  static List<(String, String)> _steps(L l) => [
    (l.pairStep1Title, l.pairStep1Body),
    (l.pairStep2Title, l.pairStep2Body),
    (l.pairStep3Title, l.pairStep3Body),
    (l.pairStep4Title, l.pairStep4Body),
  ];

  @override
  Widget build(BuildContext context) {
    final s = share;
    if (s == null) return _build(context, null);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => _build(context, s),
    );
  }

  Widget _build(BuildContext context, ShareController? share) {
    final l = L.of(context);
    final steps = _steps(l);
    final address = share?.address ?? '192.168.43.1 : 8888';
    final qr = share == null ? null : PairingQr.encode(share.qrPayload);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pairingTitle, style: T.screenTitle),
          const SizedBox(height: S.x18),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: C.heading,
                borderRadius: R.mdAll,
              ),
              clipBehavior: Clip.antiAlias,
              child: qr == null
                  ? const Center(
                      child: AppIcon(
                        AppIcons.qr,
                        size: 104,
                        color: C.gradientBottom,
                      ),
                    )
                  : CustomPaint(painter: QrPainter(qr)),
            ),
          ),
          const SizedBox(height: S.x22),
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: C.accentTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: C.accentBorder),
                  ),
                  child: Center(
                    child: Text(
                      formatNumber(context, i + 1),
                      style: T.chip.copyWith(
                        color: C.primaryMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: S.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].$1, style: T.stepTitle),
                      const SizedBox(height: 3),
                      Text(steps[i].$2, style: T.caption),
                      if (i == 2) ...[
                        const SizedBox(height: S.x8),
                        SunkenBlock(
                          padding: const EdgeInsets.symmetric(
                            vertical: S.x10,
                            horizontal: S.x12,
                          ),
                          child: MonoText(
                            address,
                            style: const TextStyle(
                              fontFamily: kMono,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: C.heading,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x16),
          ],
          const SizedBox(height: S.x4),
          PrimaryButton(
            l.copyAddressPort,
            onTap: () => Clipboard.setData(
              ClipboardData(text: address.replaceAll(' ', '')),
            ),
          ),
        ],
      ),
    );
  }
}

/// 15 · Split tunneling. Android only — iOS has no per-app routing API.
class SplitTunnelScreen extends StatelessWidget {
  const SplitTunnelScreen({super.key, this.controller});

  final SplitTunnelController? controller;

  static List<(IconData, String, String, bool)> _apps(L l) => [
    (AppIcons.browser, l.appBrowser, l.routedThroughTunnel, true),
    (AppIcons.chat, l.appMessenger, l.routedThroughTunnel, true),
    (AppIcons.bank, l.appBank, l.routedDirect, false),
    (AppIcons.video, l.appVideo, l.routedDirect, false),
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

  Widget _build(BuildContext context, SplitTunnelController? controller) {
    final l = L.of(context);

    final rows = controller == null || controller.apps.isEmpty
        ? _apps(l)
        : [
            for (final app in controller.apps)
              (
                AppIcons.browser,
                app.name,
                controller.isRouted(app.packageName)
                    ? l.routedThroughTunnel
                    : l.routedDirect,
                controller.isRouted(app.packageName),
              ),
          ];

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.splitTitle, style: T.screenTitle),
          const SizedBox(height: 6),
          Text(l.splitBody, style: T.caption),
          const SizedBox(height: S.x16),
          for (final (index, row) in rows.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  AppIcon(row.$1, size: 22),
                  const SizedBox(width: S.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.$2,
                          style: T.settingLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(row.$3, style: T.small),
                      ],
                    ),
                  ),
                  AppToggle(
                    row.$4,
                    onChanged: controller == null || controller.apps.isEmpty
                        ? null
                        : (_) => controller.toggle(
                            controller.apps[index].packageName,
                          ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: S.x22),
          SplitRow(
            start: SecondaryButton(
              l.allThroughTunnel,
              onTap: controller?.routeAll,
            ),
            end: SecondaryButton(
              l.noneThroughTunnel,
              onTap: controller?.routeNone,
            ),
          ),
        ],
      ),
    );
  }
}

/// 16 · Security & sync.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key, this.connection});

  /// Null on the design canvas; live it drives the kill switch and DNS.
  final ConnectionController? connection;

  static const _log = [
    ('12:04:11', 'tunnel up · vless/reality · nl-ams', C.success),
    ('12:04:11', 'dns → 1.1.1.1 (DoH)', C.body),
    ('12:19:48', 'probe 42 ms · stable', C.body),
    ('12:31:02', 'handshake retry (1/3)', C.warning),
    ('12:31:04', 'recovered', C.success),
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

  Widget _build(BuildContext context, ConnectionController? connection) {
    final l = L.of(context);
    final options = connection?.options;

    // Only the two that actually change routing are wired; the rest stay
    // display-only rather than pretending to do something.
    final rows = <(String, String, bool, ValueChanged<bool>?)>[
      (
        l.settingKillSwitch,
        l.settingKillSwitchNote,
        options?.killSwitch ?? true,
        connection == null
            ? null
            : (value) => connection.setOptions(
                connection.options.copyWith(killSwitch: value),
              ),
      ),
      (l.settingSecureDns, l.settingSecureDnsNote, true, null),
      (l.settingAutoConnect, l.settingAutoConnectNote, true, null),
      (l.settingSyncLists, l.settingSyncListsNote, false, null),
    ];

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.securityTitle, style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (label, caption, on, onChanged) in rows)
            SettingRow(
              label: label,
              caption: caption,
              trailing: AppToggle(on, onChanged: onChanged),
            ),
          const SizedBox(height: S.x22),
          SectionTitle(l.connectionLog),
          SunkenBlock(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (ts, msg, color) in _log)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ts, style: T.monoRaw.copyWith(color: C.muted)),
                          const SizedBox(width: S.x10),
                          Expanded(
                            child: Text(
                              msg,
                              style: T.monoRaw.copyWith(color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
