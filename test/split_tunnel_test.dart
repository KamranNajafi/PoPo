import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/tunnel/tunnel_config.dart';
import 'package:popo/core/util/prefs.dart';
import 'package:popo/features/tunnel/split_tunnel_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryPrefs prefs;
  late SplitTunnelController controller;
  late List<MethodCall> calls;

  const channel = MethodChannel('popo/tunnel');

  setUp(() {
    prefs = MemoryPrefs();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'installedApps') {
        return [
          {'packageName': 'com.browser', 'name': 'Browser'},
          {'packageName': 'com.bank.app', 'name': 'Bank'},
        ];
      }
      return null;
    });
    controller = SplitTunnelController(prefs: prefs);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('starts with everything through the tunnel', () {
    expect(controller.mode, SplitTunnelMode.off);
    expect(controller.config.isActive, isFalse);
  });

  test('toggling a package records it and pushes it to the platform', () async {
    await controller.toggle('com.bank.app');

    expect(controller.isRouted('com.bank.app'), isTrue);
    final push = calls.lastWhere((c) => c.method == 'setSplitTunnel');
    expect(push.arguments['packages'], contains('com.bank.app'),
        reason: 'rules are read when the VPN interface is built, so a change '
            'that only lives in Dart would be lost');
  });

  test('selections survive a restart', () async {
    await controller.setMode(SplitTunnelMode.exclude);
    await controller.toggle('com.bank.app');

    final reopened = SplitTunnelController(prefs: prefs);
    expect(reopened.mode, SplitTunnelMode.exclude);
    expect(reopened.isRouted('com.bank.app'), isTrue);
  });

  test('"all through tunnel" turns the feature off, not on with everything',
      () async {
    await controller.setMode(SplitTunnelMode.exclude);
    await controller.toggle('com.bank.app');

    await controller.routeAll();

    expect(controller.mode, SplitTunnelMode.off);
    expect(controller.config.isActive, isFalse);
  });

  test('"none through tunnel" is include with an empty list', () async {
    await controller.routeNone();

    expect(controller.mode, SplitTunnelMode.include,
        reason: 'off would mean everything goes through, the opposite');
    expect(controller.routed, isEmpty);
  });

  test('produces the config slice the tunnel builder needs', () async {
    await controller.setMode(SplitTunnelMode.exclude);
    await controller.toggle('com.bank.app');

    final config = controller.config;
    expect(config.mode, SplitTunnelMode.exclude);
    expect(config.packages, ['com.bank.app']);
    expect(config.isActive, isTrue);
  });

  test('reads the installed apps from the platform', () async {
    await controller.loadApps();

    expect(controller.apps.map((a) => a.packageName),
        containsAll(['com.browser', 'com.bank.app']));
  });

  test('a platform with no app list leaves it empty rather than throwing',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException();
    });

    await controller.loadApps();
    expect(controller.apps, isEmpty);
  });
}
