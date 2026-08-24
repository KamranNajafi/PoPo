import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/discovery/models.dart';
import '../../core/tunnel/tunnel_config.dart';
import '../../core/tunnel/tunnel_service.dart';
import '../../core/util/prefs.dart';

/// A device seen using the shared proxy.
class SharedDevice {
  const SharedDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.state,
    this.bytesToday = 0,
  });

  final String id;
  final String name;
  final String address;
  final SharedDeviceState state;
  final int bytesToday;
}

enum SharedDeviceState { active, awaitingApproval, blocked }

/// Connection sharing: the phone runs an HTTP and SOCKS listener on its hotspot
/// so other devices can route through the same tunnel.
///
/// Android and desktop only. iOS cannot keep a background listener alive, so
/// there is no point offering it there — the screens are compiled out on Apple
/// builds for the same reason discovery is.
class ShareController extends ChangeNotifier {
  ShareController({
    required this.service,
    required this.prefs,
    this.hotspotAddress = '192.168.43.1',
  }) {
    final stored = prefs.getString(_passwordKey);
    if (stored != null) {
      _password = stored;
    } else {
      // Persist the first one immediately. A password regenerated on every
      // launch would silently break every device already paired with it.
      _password = _generatePassword();
      unawaited(prefs.setString(_passwordKey, _password));
    }
    _enabled = prefs.getString(_enabledKey) == 'true';
  }

  static const _passwordKey = 'share.password';
  static const _enabledKey = 'share.enabled';
  static const _approvalKey = 'share.requireApproval';

  static const username = 'popo';
  static const httpPort = 8888;
  static const socksPort = 1080;

  final TunnelService service;
  final Prefs prefs;

  /// The hotspot interface address. Bound to specifically, never 0.0.0.0 —
  /// listening on every interface would expose the proxy on whatever else the
  /// device is attached to.
  final String hotspotAddress;

  late bool _enabled;
  late String _password;
  List<SharedDevice> _devices = const [];
  String? _error;

  bool get isEnabled => _enabled;
  String get password => _password;
  List<SharedDevice> get devices => List.unmodifiable(_devices);
  bool get requireApproval => prefs.getString(_approvalKey) != 'false';
  String? get error => _error;

  /// `ip:port` as the pairing screen shows it.
  String get address => '$hotspotAddress : $httpPort';

  /// What the pairing QR encodes.
  ///
  /// A proxy URL rather than a bare address: scanning apps understand the scheme
  /// and can offer to apply it, where a plain "192.168.43.1:8888" is just text.
  String get qrPayload =>
      'http://$username:$_password@$hotspotAddress:$httpPort';

  int get activeDeviceCount =>
      _devices.where((d) => d.state == SharedDeviceState.active).length;

  /// Total traffic today, formatted the way the design shows it.
  String get usageToday {
    final bytes = _devices.fold<int>(0, (sum, d) => sum + d.bytesToday);
    return formatBytes(bytes);
  }

  /// Turns sharing on or off. When a tunnel is running this restarts it with the
  /// share inbounds added, since sing-box takes its listeners from the config.
  Future<void> setEnabled(bool enabled, {Endpoint? upstream}) async {
    _enabled = enabled;
    _error = null;
    await prefs.setString(_enabledKey, '$enabled');
    notifyListeners();

    if (!service.isSupported) {
      _error = 'sharing needs the tunnel core';
      notifyListeners();
      return;
    }

    if (!enabled) {
      await service.stop();
      _devices = const [];
      notifyListeners();
      return;
    }

    if (upstream == null) {
      _error = 'connect first, then share the connection';
      notifyListeners();
      return;
    }

    try {
      await service.start(
        TunnelConfig.buildJson(
          endpoint: upstream,
          platformManagedTun: true,
          options: shareOptions,
        ),
        endpointFingerprint: upstream.fingerprint,
      );
    } on TunnelException catch (e) {
      _enabled = false;
      _error = e.message;
      notifyListeners();
    }
  }

  /// The tunnel options that add the shared listeners.
  TunnelOptions get shareOptions => TunnelOptions(
    shareListenAddress: hotspotAddress,
    sharePort: httpPort,
    socksSharePort: socksPort,
    shareUsername: username,
    sharePassword: _password,
  );

  Future<void> regeneratePassword() async {
    _password = _generatePassword();
    await prefs.setString(_passwordKey, _password);
    notifyListeners();
  }

  Future<void> setRequireApproval(bool value) async {
    await prefs.setString(_approvalKey, '$value');
    notifyListeners();
  }

  /// Replaces the device list. The platform layer reports these; there is no
  /// way to enumerate proxy clients from Dart.
  void setDevices(List<SharedDevice> devices) {
    _devices = devices;
    notifyListeners();
  }

  /// A short, readable password. Not a secret worth protecting for long — it
  /// stops a neighbour wandering in, and is rotated from the UI.
  static String _generatePassword() {
    const alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return List.generate(
      10,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}

/// Bytes in the compact form the design uses.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
}
