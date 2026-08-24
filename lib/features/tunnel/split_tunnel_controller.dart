import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/tunnel/tunnel_config.dart';
import '../../core/tunnel/tunnel_service.dart';
import '../../core/util/prefs.dart';

/// One installed app, as the split-tunnel screen lists it.
class InstalledApp {
  const InstalledApp({required this.packageName, required this.name});

  final String packageName;
  final String name;
}

/// Which apps bypass the tunnel.
///
/// Android only: no other platform exposes per-app routing, which is why the
/// screen is Android-only rather than hidden elsewhere. The rules are stored
/// natively too, because Android applies them through VpnService.Builder when
/// the interface is built — sing-box never sees them.
class SplitTunnelController extends ChangeNotifier {
  SplitTunnelController({required this.prefs, MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel(PlatformTunnelService.methodChannelName) {
    _routed = (prefs.getStringList(_routedKey) ?? const []).toSet();
    _mode = switch (prefs.getString(_modeKey)) {
      'include' => SplitTunnelMode.include,
      'exclude' => SplitTunnelMode.exclude,
      _ => SplitTunnelMode.off,
    };
  }

  static const _routedKey = 'split.packages';
  static const _modeKey = 'split.mode';

  final Prefs prefs;
  final MethodChannel _channel;

  late Set<String> _routed;
  late SplitTunnelMode _mode;
  List<InstalledApp> _apps = const [];

  SplitTunnelMode get mode => _mode;
  Set<String> get routed => Set.unmodifiable(_routed);
  List<InstalledApp> get apps => List.unmodifiable(_apps);

  bool isRouted(String packageName) => _routed.contains(packageName);

  /// The configuration slice the tunnel builder needs.
  SplitTunnel get config => switch (_mode) {
    SplitTunnelMode.off => const SplitTunnel.disabled(),
    SplitTunnelMode.include => SplitTunnel.include(_routed.toList()),
    SplitTunnelMode.exclude => SplitTunnel.exclude(_routed.toList()),
  };

  Future<void> toggle(String packageName) async {
    if (!_routed.remove(packageName)) _routed.add(packageName);
    await _persist();
  }

  Future<void> routeAll() async {
    _mode = SplitTunnelMode.off;
    _routed = {};
    await _persist();
  }

  Future<void> routeNone() async {
    // "None through the tunnel" is include-mode with an empty list, not off:
    // off means everything goes through.
    _mode = SplitTunnelMode.include;
    _routed = {};
    await _persist();
  }

  Future<void> setMode(SplitTunnelMode mode) async {
    _mode = mode;
    await _persist();
  }

  /// Reads the installed apps from the platform. Returns an empty list where
  /// there is no such concept, which is every platform but Android.
  Future<void> loadApps() async {
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'installedApps',
      );
      _apps = (raw ?? const [])
          .map(
            (entry) => InstalledApp(
              packageName: entry['packageName'] as String? ?? '',
              name: entry['name'] as String? ?? '',
            ),
          )
          .where((app) => app.packageName.isNotEmpty)
          .toList();
    } on Object {
      _apps = const [];
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    await prefs.setStringList(_routedKey, _routed.toList());
    await prefs.setString(_modeKey, _mode.name);

    // Pushed to the platform immediately: the rules are read when the VPN
    // interface is built, so a change that only lives in Dart would be lost.
    try {
      await _channel.invokeMethod<void>('setSplitTunnel', {
        'mode': _mode.name,
        'packages': _routed.toList(),
      });
    } on Object {
      // No platform side in this build; the stored value still applies once
      // there is one.
    }
    notifyListeners();
  }
}
