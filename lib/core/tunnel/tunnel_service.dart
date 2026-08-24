import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the tunnel is doing, as the UI sees it.
enum TunnelState { disconnected, connecting, connected, disconnecting, failed }

/// A snapshot of the tunnel.
class TunnelStatus {
  const TunnelStatus({
    required this.state,
    this.uptime = Duration.zero,
    this.error,
    this.endpointFingerprint,
  });

  const TunnelStatus.disconnected()
      : state = TunnelState.disconnected,
        uptime = Duration.zero,
        error = null,
        endpointFingerprint = null;

  final TunnelState state;
  final Duration uptime;
  final String? error;
  final String? endpointFingerprint;

  bool get isConnected => state == TunnelState.connected;
  bool get isBusy =>
      state == TunnelState.connecting || state == TunnelState.disconnecting;
}

/// Raised when the platform refuses or cannot start the tunnel.
class TunnelException implements Exception {
  const TunnelException(this.message, {this.permissionDenied = false});

  final String message;

  /// The user declined the system VPN prompt. Not an error to report as a
  /// failure — the app should ask again rather than claim something broke.
  final bool permissionDenied;

  @override
  String toString() => 'TunnelException: $message';
}

/// Starts and stops the tunnel.
///
/// The implementation lives outside Dart: on Android and iOS the tunnel runs in
/// a platform-owned service (VpnService, NetworkExtension) that holds the TUN
/// descriptor, and on desktop it runs in-process through dart:ffi. Both are
/// reached through this one interface so the controller above never learns which
/// platform it is on.
abstract interface class TunnelService {
  /// Asks for whatever permission the platform requires. Returns false if the
  /// user declined.
  Future<bool> requestPermission();

  /// Brings the tunnel up with a sing-box configuration.
  Future<void> start(String configJson, {String? endpointFingerprint});

  Future<void> stop();

  Future<TunnelStatus> status();

  /// Status as it changes. The platform pushes these; polling a VPN service
  /// from the UI thread is how you get a stuttering timer.
  Stream<TunnelStatus> get statusStream;

  /// Whether this build can actually run a tunnel. False on web and on any
  /// platform whose native side is not built yet, so the UI can say so rather
  /// than offering a button that does nothing.
  bool get isSupported;
}

/// The platform-channel implementation, used on Android, iOS, and desktop.
class PlatformTunnelService implements TunnelService {
  PlatformTunnelService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
    this.isSupported = true,
  })  : _method = methodChannel ?? const MethodChannel(methodChannelName),
        _events = eventChannel ?? const EventChannel(eventChannelName);

  static const methodChannelName = 'popo/tunnel';
  static const eventChannelName = 'popo/tunnel/status';

  final MethodChannel _method;
  final EventChannel _events;

  @override
  final bool isSupported;

  Stream<TunnelStatus>? _statusStream;

  @override
  Future<bool> requestPermission() async {
    try {
      return await _method.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException catch (e) {
      throw TunnelException(e.message ?? 'permission request failed');
    } on MissingPluginException {
      throw const TunnelException('the tunnel is not available in this build');
    }
  }

  @override
  Future<void> start(String configJson, {String? endpointFingerprint}) async {
    try {
      await _method.invokeMethod<void>('start', {
        'config': configJson,
        'fingerprint': endpointFingerprint,
      });
    } on PlatformException catch (e) {
      throw TunnelException(
        e.message ?? 'could not start the tunnel',
        permissionDenied: e.code == 'permission_denied',
      );
    } on MissingPluginException {
      throw const TunnelException('the tunnel is not available in this build');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _method.invokeMethod<void>('stop');
    } on PlatformException catch (e) {
      throw TunnelException(e.message ?? 'could not stop the tunnel');
    } on MissingPluginException {
      // Nothing to stop if nothing could ever have started.
    }
  }

  @override
  Future<TunnelStatus> status() async {
    try {
      final raw = await _method.invokeMapMethod<String, dynamic>('status');
      return raw == null ? const TunnelStatus.disconnected() : _decode(raw);
    } on Object {
      return const TunnelStatus.disconnected();
    }
  }

  @override
  Stream<TunnelStatus> get statusStream => _statusStream ??= _events
      .receiveBroadcastStream()
      .map((event) => _decode(Map<String, dynamic>.from(event as Map)))
      .handleError((Object _) {})
      .asBroadcastStream();

  static TunnelStatus _decode(Map<String, dynamic> raw) => TunnelStatus(
        state: switch (raw['state']) {
          'connecting' => TunnelState.connecting,
          'connected' => TunnelState.connected,
          'disconnecting' => TunnelState.disconnecting,
          'failed' => TunnelState.failed,
          _ => TunnelState.disconnected,
        },
        uptime: Duration(seconds: (raw['uptimeSeconds'] as num?)?.toInt() ?? 0),
        error: raw['error'] as String?,
        endpointFingerprint: raw['fingerprint'] as String?,
      );
}

/// Picks the implementation for the platform the app is running on.
///
/// Android and iOS run the tunnel in a platform service reached over channels;
/// desktop will use dart:ffi against the same core once the shared library is
/// bundled. Web has neither, and says so.
TunnelService createTunnelService() {
  if (kIsWeb) return UnsupportedTunnelService();
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => PlatformTunnelService(),
    // Desktop goes through the same channel names, implemented by the Flutter
    // desktop embedder once tool/build_core_desktop.sh has run.
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows =>
      PlatformTunnelService(),
    _ => UnsupportedTunnelService(),
  };
}

/// The implementation for platforms with no tunnel: the web preview, and any
/// platform whose native side is not built.
///
/// It reports unsupported rather than pretending to connect. A fake "connected"
/// state in an app whose whole point is carrying traffic would be the worst
/// possible lie.
class UnsupportedTunnelService implements TunnelService {
  UnsupportedTunnelService();

  final _controller = StreamController<TunnelStatus>.broadcast();

  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> start(String configJson, {String? endpointFingerprint}) async =>
      throw const TunnelException('this platform cannot run a tunnel');

  @override
  Future<void> stop() async {}

  @override
  Future<TunnelStatus> status() async => const TunnelStatus.disconnected();

  @override
  Stream<TunnelStatus> get statusStream => _controller.stream;
}
