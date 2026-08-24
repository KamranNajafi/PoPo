import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/discovery/models.dart';
import 'package:popo/core/tunnel/tunnel_config.dart';
import 'package:popo/core/tunnel/tunnel_service.dart';
import 'package:popo/features/tunnel/connection_controller.dart';

class FakeTunnelService implements TunnelService {
  FakeTunnelService({
    this.isSupported = true,
    this.permissionGranted = true,
    this.startError,
  });

  @override
  final bool isSupported;

  bool permissionGranted;
  TunnelException? startError;

  final _controller = StreamController<TunnelStatus>.broadcast();
  final List<String> startedConfigs = [];
  int stopCount = 0;
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> start(String configJson, {String? endpointFingerprint}) async {
    if (startError != null) throw startError!;
    startedConfigs.add(configJson);
    _controller.add(const TunnelStatus(state: TunnelState.connected));
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _controller.add(const TunnelStatus.disconnected());
  }

  @override
  Future<TunnelStatus> status() async => const TunnelStatus.disconnected();

  @override
  Stream<TunnelStatus> get statusStream => _controller.stream;

  void push(TunnelStatus status) => _controller.add(status);
}

Endpoint endpoint([String raw = 'vless://u@1.2.3.4:443?security=tls&sni=a.example']) {
  // Derive the address from the link so a test that swaps servers really swaps.
  final authority = raw.split('://').last.split('?').first.split('#').first;
  final address = authority.contains('@') ? authority.split('@').last : authority;
  final host = address.split(':').first;
  final port = int.parse(address.split(':').last);

  return Endpoint(
    raw: raw,
    kind: EndpointKind.config,
    protocol: Protocol.vless,
    host: host,
    port: port,
    fingerprint: 'vless|$host|$port|u',
  );
}

void main() {
  test('connecting asks permission, then starts with a built config', () async {
    final service = FakeTunnelService();
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint());

    expect(service.permissionRequests, 1);
    expect(service.startedConfigs, hasLength(1));
    expect(service.startedConfigs.single, contains('"type":"vless"'));
    expect(controller.isConnected, isTrue);
    controller.dispose();
  });

  test('a declined prompt is reported as declined, not as a failure', () async {
    final service = FakeTunnelService(permissionGranted: false);
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint());

    expect(controller.error, ConnectionError.permissionDenied);
    expect(service.startedConfigs, isEmpty,
        reason: 'starting without permission would fail anyway');
    controller.dispose();
  });

  test('a config that cannot be built never reaches the permission prompt',
      () async {
    final service = FakeTunnelService();
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint('wireguard://x@1.2.3.4:51820'));

    expect(controller.error, ConnectionError.unsupportedConfig);
    expect(service.permissionRequests, 0,
        reason: 'a malformed config should not cost the user a system prompt');
    controller.dispose();
  });

  test('a platform failure surfaces as a platform failure', () async {
    final service = FakeTunnelService(
      startError: const TunnelException('tun device busy'),
    );
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint());

    expect(controller.error, ConnectionError.platformFailed);
    expect(controller.errorDetail, contains('tun device busy'));
    expect(controller.state, TunnelState.failed);
    controller.dispose();
  });

  test('an unsupported platform says so instead of pretending', () async {
    final service = FakeTunnelService(isSupported: false);
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint());

    expect(controller.isConnected, isFalse);
    expect(controller.error, ConnectionError.platformFailed);
    expect(service.startedConfigs, isEmpty);
    controller.dispose();
  });

  test('disconnecting stops the service and clears the state', () async {
    final service = FakeTunnelService();
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint());
    await controller.disconnect();

    expect(service.stopCount, 1);
    expect(controller.state, TunnelState.disconnected);
    controller.dispose();
  });

  test('switching server starts again without a manual stop', () async {
    final service = FakeTunnelService();
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint());
    await controller.switchTo(endpoint('vless://u2@5.6.7.8:443?security=tls&sni=b.example'));

    expect(service.startedConfigs, hasLength(2));
    expect(service.stopCount, 0,
        reason: 'the core replaces its instance, so the user sees no gap');
    expect(controller.endpoint!.host, '5.6.7.8');
    controller.dispose();
  });

  test('platform status updates are reflected', () async {
    final service = FakeTunnelService();
    final controller = ConnectionController(service: service);

    service.push(const TunnelStatus(
      state: TunnelState.connected,
      uptime: Duration(minutes: 5),
    ));
    await Future<void>.delayed(Duration.zero);

    expect(controller.isConnected, isTrue);
    expect(controller.uptime, const Duration(minutes: 5));
    controller.dispose();
  });

  test('changing options while connected reapplies them immediately', () async {
    final service = FakeTunnelService();
    final controller = ConnectionController(service: service);

    await controller.connect(endpoint());
    await controller.setOptions(const TunnelOptions(killSwitch: false));

    expect(service.startedConfigs, hasLength(2),
        reason: 'a kill switch that waits until next time is not a kill switch');
    expect(service.startedConfigs.last, contains('"final":"direct"'));
    controller.dispose();
  });

  test('the config carries the split tunnel rules it was given', () async {
    final service = FakeTunnelService();
    final controller = ConnectionController(
      service: service,
      options: const TunnelOptions(
        splitTunnel: SplitTunnel.exclude(['com.bank.app']),
      ),
    );

    await controller.connect(endpoint());

    expect(service.startedConfigs.single, contains('com.bank.app'));
    controller.dispose();
  });

  group('formatUptime', () {
    test('renders the design\'s clock', () {
      expect(formatUptime(const Duration(hours: 0, minutes: 37, seconds: 12)),
          '00:37:12');
      expect(formatUptime(const Duration(hours: 25, minutes: 1, seconds: 2)),
          '25:01:02');
      expect(formatUptime(Duration.zero), '00:00:00');
    });
  });
}
