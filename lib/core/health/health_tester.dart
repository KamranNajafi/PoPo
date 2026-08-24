import 'dart:async';

import '../discovery/models.dart';
import 'probe.dart';

/// How a health run is configured.
class HealthConfig {
  const HealthConfig({
    this.timeout = const Duration(seconds: 5),
    this.concurrency = 12,
    this.removeDeadAfterFailures = 2,
    this.autoRemoveDead = true,
    this.maxToTest = 200,
  });

  /// From the settings screen ("test timeout").
  final Duration timeout;

  /// Probes in flight at once. High enough to finish a list while the user
  /// watches, low enough not to look like a port scan from one address.
  final int concurrency;

  /// Consecutive failures before an endpoint is dropped.
  final int removeDeadAfterFailures;

  final bool autoRemoveDead;

  /// Ceiling on how many endpoints one run tests, best-ranked first.
  final int maxToTest;
}

/// Progress while testing, for the simple-mode step card and screen 02.
class HealthProgress {
  const HealthProgress({
    required this.tested,
    required this.total,
    required this.healthy,
  });

  final int tested;
  final int total;
  final int healthy;

  double get fraction => total == 0 ? 0 : tested / total;
}

/// The outcome of testing a list.
class HealthReport {
  const HealthReport({
    required this.tested,
    required this.removed,
    required this.probingSupported,
  });

  /// Every endpoint that survived, with ping and health filled in, fastest
  /// first.
  final List<Endpoint> tested;

  /// Endpoints dropped for failing too many times in a row.
  final List<Endpoint> removed;

  /// False on platforms without raw sockets. The caller must not present the
  /// results as "all dead" in that case.
  final bool probingSupported;

  List<Endpoint> get healthy =>
      tested.where((e) => e.health != Health.dead).toList();
}

/// Measures latency for a list of endpoints and classifies their health.
///
/// This is what turns discovery's guesses into something worth showing: the
/// pipeline's score is a prior over where an endpoint was published, while this
/// is a measurement of whether it answers at all.
class HealthTester {
  HealthTester({LatencyProbe? probe, this.config = const HealthConfig()})
      : _probe = probe ?? defaultProbe();

  final LatencyProbe _probe;
  final HealthConfig config;

  final _progress = StreamController<HealthProgress>.broadcast();
  Stream<HealthProgress> get progress => _progress.stream;

  bool _cancelled = false;

  /// Stops at the next checkpoint, keeping what has already been measured.
  void cancel() => _cancelled = true;

  Future<HealthReport> test(List<Endpoint> endpoints) async {
    _cancelled = false;

    // Test the best-ranked first, so a capped run spends its probes on the
    // endpoints most likely to be worth having.
    final queue = [...endpoints]..sort((a, b) => b.score.compareTo(a.score));
    final subject = queue.take(config.maxToTest).toList();
    final untouched = queue.skip(config.maxToTest).toList();

    final results = <Endpoint>[];
    final removed = <Endpoint>[];
    var tested = 0;
    var healthy = 0;
    var supported = true;

    void emit() {
      if (_progress.isClosed) return;
      _progress.add(HealthProgress(
        tested: tested,
        total: subject.length,
        healthy: healthy,
      ));
    }

    emit();

    await _forEachLimited(subject, config.concurrency, (endpoint) async {
      if (_cancelled) return;

      final result =
          await _probe.probe(endpoint.host, endpoint.port, timeout: config.timeout);
      if (!result.supported) supported = false;

      final now = DateTime.now();
      final Endpoint updated;

      if (result.reachable) {
        updated = endpoint.copyWith(
          ping: result.latency,
          health: Health.fromLatency(result.latency),
          lastTestedAt: now,
          failureCount: 0, // a success clears the streak
        );
        healthy++;
      } else if (!result.supported) {
        // Nothing was learned, so nothing is recorded — an untestable platform
        // must not mark healthy servers dead or advance their failure count.
        updated = endpoint;
      } else {
        updated = endpoint.copyWith(
          clearPing: true,
          health: Health.dead,
          lastTestedAt: now,
          failureCount: endpoint.failureCount + 1,
        );
      }

      tested++;

      final dropped = config.autoRemoveDead &&
          result.supported &&
          updated.health == Health.dead &&
          updated.failureCount >= config.removeDeadAfterFailures;

      if (dropped) {
        removed.add(updated);
      } else {
        results.add(updated);
      }
      emit();
    });

    // Endpoints beyond the cap keep whatever they had; they were not tested.
    results.addAll(untouched);
    results.sort(_byQuality);

    await _progress.close();
    return HealthReport(
      tested: results,
      removed: removed,
      probingSupported: supported,
    );
  }

  /// Tested and fast first, then untested, then dead — the order the results
  /// screen wants without any further sorting.
  static int _byQuality(Endpoint a, Endpoint b) {
    int rank(Endpoint e) => switch (e.health) {
          Health.ok => 0,
          Health.slow => 1,
          Health.untested => 2,
          Health.dead => 3,
        };

    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;

    final aPing = a.ping;
    final bPing = b.ping;
    if (aPing != null && bPing != null) return aPing.compareTo(bPing);
    if (aPing != null) return -1;
    if (bPing != null) return 1;
    return b.score.compareTo(a.score);
  }
}

/// Runs [action] over [items] with at most [limit] in flight.
Future<void> _forEachLimited<T>(
  List<T> items,
  int limit,
  Future<void> Function(T) action,
) async {
  final iterator = items.iterator;
  final workers = <Future<void>>[];

  for (var i = 0; i < limit; i++) {
    workers.add(Future(() async {
      while (true) {
        if (!iterator.moveNext()) return;
        final item = iterator.current;
        await action(item);
      }
    }));
  }

  await Future.wait(workers);
}
