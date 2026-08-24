import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/discovery/models.dart';
import 'package:popo/core/health/health_tester.dart';
import 'package:popo/core/health/probe.dart';

/// A probe with scripted answers, keyed by host.
class FakeProbe implements LatencyProbe {
  FakeProbe(this.answers, {this.supported = true});

  final Map<String, int?> answers;
  final bool supported;
  final List<String> probed = [];
  int inFlight = 0;
  int peakInFlight = 0;

  @override
  Future<ProbeResult> probe(String host, int port,
      {required Duration timeout}) async {
    probed.add('$host:$port');
    inFlight++;
    peakInFlight = peakInFlight > inFlight ? peakInFlight : inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    inFlight--;

    if (!supported) return const ProbeResult.unsupported();
    final ms = answers[host];
    return ms == null
        ? const ProbeResult.unreachable('refused')
        : ProbeResult.reachable(Duration(milliseconds: ms));
  }
}

Endpoint endpoint(
  String host, {
  double score = 1,
  int failureCount = 0,
  Duration? ping,
  Health health = Health.untested,
}) =>
    Endpoint(
      raw: 'vless://u@$host:443',
      kind: EndpointKind.config,
      protocol: Protocol.vless,
      host: host,
      port: 443,
      fingerprint: 'vless|$host|443|u',
      score: score,
      failureCount: failureCount,
      ping: ping,
      health: health,
    );

void main() {
  group('Health.fromLatency', () {
    test('classifies against the design thresholds', () {
      expect(Health.fromLatency(const Duration(milliseconds: 42)), Health.ok);
      expect(Health.fromLatency(const Duration(milliseconds: 100)), Health.ok);
      expect(Health.fromLatency(const Duration(milliseconds: 101)), Health.slow);
      expect(Health.fromLatency(null), Health.dead);
    });
  });

  group('HealthTester', () {
    test('measures latency and marks unreachable endpoints dead', () async {
      final probe = FakeProbe({'a.example': 42, 'b.example': null});
      final tester = HealthTester(probe: probe);

      final report = await tester.test([endpoint('a.example'), endpoint('b.example')]);

      final byHost = {for (final e in report.tested) e.host: e};
      expect(byHost['a.example']!.ping, const Duration(milliseconds: 42));
      expect(byHost['a.example']!.health, Health.ok);
      expect(byHost['b.example']!.health, Health.dead);
      expect(byHost['b.example']!.ping, isNull);
      expect(report.healthy.map((e) => e.host), ['a.example']);
    });

    test('a failed retest clears a previously good ping', () async {
      final probe = FakeProbe({'a.example': null});
      final tester = HealthTester(probe: probe);

      final report = await tester.test([
        endpoint('a.example', ping: const Duration(milliseconds: 30), health: Health.ok),
      ]);

      expect(report.tested.single.ping, isNull,
          reason: 'a stale ping next to a dead badge would be a lie');
    });

    test('a success resets the failure streak', () async {
      final probe = FakeProbe({'a.example': 50});
      final tester = HealthTester(probe: probe);

      final report = await tester.test([endpoint('a.example', failureCount: 1)]);

      expect(report.tested.single.failureCount, 0);
    });

    test('drops an endpoint once it fails the configured number of times',
        () async {
      final probe = FakeProbe({'a.example': null});
      final tester = HealthTester(
        probe: probe,
        config: const HealthConfig(removeDeadAfterFailures: 2),
      );

      final report = await tester.test([endpoint('a.example', failureCount: 1)]);

      expect(report.removed.map((e) => e.host), ['a.example']);
      expect(report.tested, isEmpty);
    });

    test('keeps a first-time failure, so one bad moment is not fatal', () async {
      final probe = FakeProbe({'a.example': null});
      final tester = HealthTester(
        probe: probe,
        config: const HealthConfig(removeDeadAfterFailures: 2),
      );

      final report = await tester.test([endpoint('a.example')]);

      expect(report.removed, isEmpty);
      expect(report.tested.single.failureCount, 1);
    });

    test('auto-remove off keeps everything', () async {
      final probe = FakeProbe({'a.example': null});
      final tester = HealthTester(
        probe: probe,
        config: const HealthConfig(autoRemoveDead: false, removeDeadAfterFailures: 1),
      );

      final report = await tester.test([endpoint('a.example', failureCount: 5)]);

      expect(report.removed, isEmpty);
      expect(report.tested, hasLength(1));
    });

    test('an unsupported platform records nothing rather than marking all dead',
        () async {
      final probe = FakeProbe(const {}, supported: false);
      final tester = HealthTester(probe: probe);

      final report = await tester.test([
        endpoint('a.example', ping: const Duration(milliseconds: 30), health: Health.ok),
      ]);

      expect(report.probingSupported, isFalse);
      expect(report.tested.single.health, Health.ok,
          reason: 'a platform that cannot probe must not condemn a good server');
      expect(report.tested.single.failureCount, 0);
      expect(report.removed, isEmpty);
    });

    test('orders fast, then slow, then untested, then dead', () async {
      final probe = FakeProbe({
        'fast.example': 30,
        'slow.example': 160,
        'dead.example': null,
      });
      final tester = HealthTester(
        probe: probe,
        config: const HealthConfig(autoRemoveDead: false, maxToTest: 3),
      );

      final report = await tester.test([
        endpoint('dead.example', score: 9),
        endpoint('slow.example', score: 1),
        endpoint('fast.example', score: 1),
        endpoint('untested.example', score: 0),
      ]);

      expect(report.tested.map((e) => e.host), [
        'fast.example',
        'slow.example',
        'untested.example',
        'dead.example',
      ]);
    });

    test('tests the best-ranked first and honours the cap', () async {
      final probe = FakeProbe({'top.example': 10, 'mid.example': 20});
      final tester = HealthTester(probe: probe, config: const HealthConfig(maxToTest: 2));

      await tester.test([
        endpoint('low.example', score: 1),
        endpoint('top.example', score: 9),
        endpoint('mid.example', score: 5),
      ]);

      expect(probe.probed, hasLength(2));
      expect(probe.probed.first, startsWith('top.example'));
      expect(probe.probed.any((p) => p.startsWith('low.example')), isFalse);
    });

    test('untested endpoints beyond the cap are kept, not discarded', () async {
      final probe = FakeProbe({'top.example': 10});
      final tester = HealthTester(probe: probe, config: const HealthConfig(maxToTest: 1));

      final report = await tester.test([
        endpoint('top.example', score: 9),
        endpoint('kept.example', score: 1),
      ]);

      expect(report.tested.map((e) => e.host), containsAll(['top.example', 'kept.example']));
    });

    test('respects the concurrency limit', () async {
      final probe = FakeProbe({for (var i = 0; i < 30; i++) 'h$i.example': 10});
      final tester = HealthTester(probe: probe, config: const HealthConfig(concurrency: 4));

      await tester.test([for (var i = 0; i < 30; i++) endpoint('h$i.example')]);

      expect(probe.peakInFlight, lessThanOrEqualTo(4));
    });

    test('reports progress as it goes', () async {
      final probe = FakeProbe({'a.example': 10, 'b.example': null, 'c.example': 20});
      final tester = HealthTester(probe: probe, config: const HealthConfig(concurrency: 1));

      final seen = <HealthProgress>[];
      tester.progress.listen(seen.add);
      await tester.test([endpoint('a.example'), endpoint('b.example'), endpoint('c.example')]);

      expect(seen, isNotEmpty);
      expect(seen.last.tested, 3);
      expect(seen.last.total, 3);
      expect(seen.last.healthy, 2);
      expect(seen.last.fraction, 1.0);
    });

    test('cancelling keeps what was already measured', () async {
      final probe = FakeProbe({for (var i = 0; i < 20; i++) 'h$i.example': 10});
      final tester = HealthTester(probe: probe, config: const HealthConfig(concurrency: 1));

      tester.progress.listen((p) {
        if (p.tested >= 2) tester.cancel();
      });

      final report = await tester.test(
          [for (var i = 0; i < 20; i++) endpoint('h$i.example')]);

      expect(probe.probed.length, lessThan(20));
      expect(report.tested.where((e) => e.ping != null), isNotEmpty);
    });
  });
}
