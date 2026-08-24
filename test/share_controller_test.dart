import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/util/prefs.dart';
import 'package:popo/features/sharing/share_controller.dart';

import 'connection_controller_test.dart' show FakeTunnelService, endpoint;

void main() {
  late MemoryPrefs prefs;
  late FakeTunnelService service;
  late ShareController controller;

  setUp(() {
    prefs = MemoryPrefs();
    service = FakeTunnelService();
    controller = ShareController(service: service, prefs: prefs);
  });

  test('generates a password and keeps it across restarts', () async {
    final first = controller.password;
    expect(first, hasLength(10));

    final reopened = ShareController(service: service, prefs: prefs);
    expect(
      reopened.password,
      first,
      reason: 'a password that changes on restart breaks every paired device',
    );
  });

  test('rotating the password changes and persists it', () async {
    final before = controller.password;
    await controller.regeneratePassword();

    expect(controller.password, isNot(before));
    expect(
      ShareController(service: service, prefs: prefs).password,
      controller.password,
    );
  });

  test('the QR carries a usable proxy URL, not just an address', () {
    expect(controller.qrPayload, startsWith('http://popo:'));
    expect(controller.qrPayload, contains('@192.168.43.1:8888'));
  });

  test(
    'enabling without a connection explains rather than half-starting',
    () async {
      await controller.setEnabled(true);

      expect(service.startedConfigs, isEmpty);
      expect(controller.error, contains('connect first'));
    },
  );

  test('enabling with an upstream starts the shared listeners', () async {
    await controller.setEnabled(true, upstream: endpoint());

    expect(service.startedConfigs, hasLength(1));
    final config = service.startedConfigs.single;
    expect(config, contains('share-http'));
    expect(config, contains('share-socks'));
    expect(config, contains('"listen":"192.168.43.1"'));
    expect(
      config,
      isNot(contains('"listen":"0.0.0.0"')),
      reason: 'binding everywhere exposes the proxy beyond the hotspot',
    );
  });

  test('the shared listeners are password protected', () async {
    await controller.setEnabled(true, upstream: endpoint());

    expect(service.startedConfigs.single, contains('"username":"popo"'));
    expect(service.startedConfigs.single, contains(controller.password));
  });

  test('disabling stops the tunnel and clears the device list', () async {
    await controller.setEnabled(true, upstream: endpoint());
    controller.setDevices([
      const SharedDevice(
        id: '1',
        name: 'Laptop',
        address: '192.168.43.24',
        state: SharedDeviceState.active,
      ),
    ]);

    await controller.setEnabled(false);

    expect(service.stopCount, 1);
    expect(controller.devices, isEmpty);
  });

  test('enabled state survives a restart', () async {
    await controller.setEnabled(true, upstream: endpoint());

    expect(ShareController(service: service, prefs: prefs).isEnabled, isTrue);
  });

  test('counts active devices and totals their traffic', () {
    controller.setDevices(const [
      SharedDevice(
        id: '1',
        name: 'Laptop',
        address: '192.168.43.24',
        state: SharedDeviceState.active,
        bytesToday: 840 * 1024 * 1024,
      ),
      SharedDevice(
        id: '2',
        name: 'Phone',
        address: '192.168.43.47',
        state: SharedDeviceState.awaitingApproval,
        bytesToday: 0,
      ),
    ]);

    expect(controller.activeDeviceCount, 1);
    expect(controller.usageToday, '840 MB');
  });

  test(
    'an unsupported platform says so rather than appearing to share',
    () async {
      final unsupported = ShareController(
        service: FakeTunnelService(isSupported: false),
        prefs: MemoryPrefs(),
      );

      await unsupported.setEnabled(true, upstream: endpoint());

      expect(unsupported.error, contains('tunnel core'));
    },
  );

  group('formatBytes', () {
    test('scales to the unit the design shows', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(1400 * 1024 * 1024), '1.4 GB');
    });
  });
}
