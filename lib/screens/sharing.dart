import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/util/fa.dart';
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
  const ProxyServerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            leading: Text(l.shareConnection, style: T.screenTitle),
            trailing: const AppToggle(true),
          ),
          const SizedBox(height: S.x24),
          const Center(child: StatusHero(state: HeroState.ready, size: 96)),
          const SizedBox(height: S.x18),
          Center(child: Text(l.serverOn, style: T.connectedHero)),
          const SizedBox(height: S.x10),
          const Center(
            child: MonoText(
              '192.168.43.1 : 8888',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text(l.shareDevicesAndUsage(3, '1.4 GB'), style: T.small)),
          const SizedBox(height: S.x22),
          MetaRow(l.metaProxyAddress, '192.168.43.1'),
          MetaRow(l.metaHttpPort, '8888'),
          MetaRow(l.metaSocksPort, '1080'),
          MetaRow(l.metaUsername, 'popo'),
          MetaRow(l.metaPassword, '•••• ••••', showDivider: false),
          const SizedBox(height: S.x18),
          PrimaryButton(l.showConnectionQr),
          const SizedBox(height: S.x10),
          SplitRow(
            start: SecondaryButton(l.changePassword),
            end: SecondaryButton(l.turnOnHotspot),
          ),
        ],
      ),
    );
  }
}

/// 13 · Connected devices.
class ConnectedDevicesScreen extends StatelessWidget {
  const ConnectedDevicesScreen({super.key});

  static List<(IconData, String, String, String, Color, String)> _devices(L l) => [
        (AppIcons.laptop, l.deviceWorkLaptop, '192.168.43.24', l.deviceActive,
            C.success, l.deviceUsageToday('840 MB')),
        (AppIcons.tv, l.deviceLivingRoomTv, '192.168.43.31', l.deviceActive,
            C.success, l.deviceUsageToday('490 MB')),
        (AppIcons.phone, l.deviceSecondPhone, '192.168.43.47',
            l.devicePendingApproval, C.warning, '—'),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.connectedDevices, style: T.screenTitle),
          const SizedBox(height: S.x16),
          for (final (icon, name, ip, state, color, usage) in _devices(l)) ...[
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
          SecondaryButton(l.onlyApprovedDevices),
        ],
      ),
    );
  }
}

/// 14 · Pairing guide — how a second device joins.
class PairingGuideScreen extends StatelessWidget {
  const PairingGuideScreen({super.key});

  static List<(String, String)> _steps(L l) => [
        (l.pairStep1Title, l.pairStep1Body),
        (l.pairStep2Title, l.pairStep2Body),
        (l.pairStep3Title, l.pairStep3Body),
        (l.pairStep4Title, l.pairStep4Body),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final steps = _steps(l);
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
              child: const Center(
                child: AppIcon(AppIcons.qr, size: 104, color: C.gradientBottom),
              ),
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
                    child: Text(formatNumber(context, i + 1),
                        style: T.chip.copyWith(color: C.primaryMuted, fontSize: 13)),
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
                        const SunkenBlock(
                          padding: EdgeInsets.symmetric(vertical: S.x10, horizontal: S.x12),
                          child: MonoText('192.168.43.1 : 8888',
                              style: TextStyle(
                                fontFamily: kMono,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: C.heading,
                              )),
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
          PrimaryButton(l.copyAddressPort),
        ],
      ),
    );
  }
}

/// 15 · Split tunneling. Android only — iOS has no per-app routing API.
class SplitTunnelScreen extends StatelessWidget {
  const SplitTunnelScreen({super.key});

  static List<(IconData, String, String, bool)> _apps(L l) => [
        (AppIcons.browser, l.appBrowser, l.routedThroughTunnel, true),
        (AppIcons.chat, l.appMessenger, l.routedThroughTunnel, true),
        (AppIcons.bank, l.appBank, l.routedDirect, false),
        (AppIcons.video, l.appVideo, l.routedDirect, false),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.splitTitle, style: T.screenTitle),
          const SizedBox(height: 6),
          Text(l.splitBody, style: T.caption),
          const SizedBox(height: S.x16),
          for (final (icon, name, note, on) in _apps(l))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  AppIcon(icon, size: 22),
                  const SizedBox(width: S.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: T.settingLabel),
                        const SizedBox(height: 3),
                        Text(note, style: T.small),
                      ],
                    ),
                  ),
                  AppToggle(on),
                ],
              ),
            ),
          const SizedBox(height: S.x22),
          SplitRow(
            start: SecondaryButton(l.allThroughTunnel),
            end: SecondaryButton(l.noneThroughTunnel),
          ),
        ],
      ),
    );
  }
}

/// 16 · Security & sync.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  static List<(String, String, bool)> _rows(L l) => [
        (l.settingKillSwitch, l.settingKillSwitchNote, true),
        (l.settingSecureDns, l.settingSecureDnsNote, true),
        (l.settingAutoConnect, l.settingAutoConnectNote, true),
        (l.settingSyncLists, l.settingSyncListsNote, false),
      ];

  static const _log = [
    ('12:04:11', 'tunnel up · vless/reality · nl-ams', C.success),
    ('12:04:11', 'dns → 1.1.1.1 (DoH)', C.body),
    ('12:19:48', 'probe 42 ms · stable', C.body),
    ('12:31:02', 'handshake retry (1/3)', C.warning),
    ('12:31:04', 'recovered', C.success),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.securityTitle, style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (label, caption, on) in _rows(l))
            SettingRow(label: label, caption: caption, trailing: AppToggle(on)),
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
                            child: Text(msg, style: T.monoRaw.copyWith(color: color)),
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
