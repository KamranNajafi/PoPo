import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/discovery/models.dart';
import '../../core/tunnel/tunnel_config.dart';
import '../../core/tunnel/tunnel_service.dart';

/// Why a connection attempt did not succeed. A kind rather than a message: the
/// controller has no BuildContext and must not decide what the user reads.
enum ConnectionError { permissionDenied, unsupportedConfig, platformFailed, noEndpoint }

/// Owns the connection: which endpoint, whether it is up, and for how long.
///
/// Kept separate from the discovery and health controllers because its lifetime
/// is different — a tunnel outlives any single run, and the user expects it to
/// stay up while they search again.
class ConnectionController extends ChangeNotifier {
  ConnectionController({required this.service, TunnelOptions? options})
      : _options = options ?? const TunnelOptions() {
    _subscription = service.statusStream.listen(_onStatus);
    if (service.isSupported) unawaited(_refresh());
  }

  final TunnelService service;

  StreamSubscription<TunnelStatus>? _subscription;
  Timer? _ticker;

  TunnelOptions _options;
  TunnelStatus _status = const TunnelStatus.disconnected();
  Endpoint? _endpoint;
  ConnectionError? _error;
  String? _errorDetail;

  // --- Reads ------------------------------------------------------------------

  TunnelStatus get status => _status;
  TunnelState get state => _status.state;
  bool get isConnected => _status.isConnected;
  bool get isBusy => _status.isBusy;
  bool get isSupported => service.isSupported;
  Endpoint? get endpoint => _endpoint;
  ConnectionError? get error => _error;
  String? get errorDetail => _errorDetail;
  TunnelOptions get options => _options;

  /// Uptime, ticked locally between platform updates so the timer on S4 moves
  /// once a second instead of once per platform event.
  Duration get uptime => _status.uptime;

  // --- Commands ---------------------------------------------------------------

  /// Connects to [endpoint], replacing any current connection.
  Future<void> connect(Endpoint endpoint) async {
    _error = null;
    _errorDetail = null;
    _endpoint = endpoint;

    if (!service.isSupported) {
      _fail(ConnectionError.platformFailed, 'tunnel unavailable on this platform');
      return;
    }

    _set(const TunnelStatus(state: TunnelState.connecting));

    final String config;
    try {
      // Built and validated before asking for permission: a malformed config
      // should not cost the user a system prompt that then fails.
      config = TunnelConfig.buildJson(
        endpoint: endpoint,
        options: _options,
        platformManagedTun: true,
      );
    } on Object catch (e) {
      _fail(ConnectionError.unsupportedConfig, '$e');
      return;
    }

    try {
      if (!await service.requestPermission()) {
        _fail(ConnectionError.permissionDenied, 'permission declined');
        return;
      }
      await service.start(config, endpointFingerprint: endpoint.fingerprint);
      _startTicker();
    } on TunnelException catch (e) {
      _fail(
        e.permissionDenied
            ? ConnectionError.permissionDenied
            : ConnectionError.platformFailed,
        e.message,
      );
    }
  }

  Future<void> disconnect() async {
    _stopTicker();
    _set(const TunnelStatus(state: TunnelState.disconnecting));
    try {
      await service.stop();
    } on TunnelException catch (e) {
      _errorDetail = e.message;
    }
    _set(const TunnelStatus.disconnected());
  }

  /// Switches server without a visible gap: the core replaces its instance, so
  /// there is no reason to make the user watch a disconnect first.
  Future<void> switchTo(Endpoint endpoint) => connect(endpoint);

  /// Changes routing options. Applied immediately when connected, since a kill
  /// switch that only takes effect next time is not a kill switch.
  Future<void> setOptions(TunnelOptions options) async {
    _options = options;
    notifyListeners();
    final current = _endpoint;
    if (isConnected && current != null) await connect(current);
  }

  // --- Internals --------------------------------------------------------------

  Future<void> _refresh() async => _set(await service.status());

  void _onStatus(TunnelStatus status) {
    _set(status);
    if (status.isConnected) {
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  void _set(TunnelStatus status) {
    _status = status;
    notifyListeners();
  }

  void _fail(ConnectionError error, String detail) {
    _error = error;
    _errorDetail = detail;
    _stopTicker();
    _set(const TunnelStatus(state: TunnelState.failed));
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_status.isConnected) return;
      _status = TunnelStatus(
        state: _status.state,
        uptime: _status.uptime + const Duration(seconds: 1),
        endpointFingerprint: _status.endpointFingerprint,
      );
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    _subscription?.cancel();
    super.dispose();
  }
}

/// Formats an uptime the way the design shows it: `00:37:12`, always LTR.
String formatUptime(Duration uptime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(uptime.inHours)}:${two(uptime.inMinutes % 60)}:${two(uptime.inSeconds % 60)}';
}
