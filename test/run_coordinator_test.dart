import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/discovery/engines.dart';
import 'package:popo/core/discovery/fetcher.dart';
import 'package:popo/core/discovery/models.dart';
import 'package:popo/core/discovery/pipeline.dart';
import 'package:popo/core/health/probe.dart';
import 'package:popo/core/util/prefs.dart';
import 'package:popo/features/discovery/discovery_controller.dart';
import 'package:popo/features/discovery/run_coordinator.dart';
import 'package:popo/features/results/app_settings.dart';
import 'package:popo/features/results/results_store.dart';

class FakeFetcher implements Fetcher {
  FakeFetcher(this.pages);

  final Map<String, String> pages;

  @override
  Future<FetchResult> get(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    for (final MapEntry(key: pattern, value: body) in pages.entries) {
      if (url.contains(pattern)) {
        return FetchResult(statusCode: 200, body: body);
      }
    }
    return const FetchResult(statusCode: 404, body: '');
  }
}

class FakeProbe implements LatencyProbe {
  FakeProbe(this.answers, {this.supported = true});

  final Map<String, int?> answers;
  final bool supported;

  @override
  Future<ProbeResult> probe(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    if (!supported) return const ProbeResult.unsupported();
    final ms = answers[host];
    return ms == null
        ? const ProbeResult.unreachable('refused')
        : ProbeResult.reachable(Duration(milliseconds: ms));
  }
}

RunCoordinator build({
  required Map<String, String> pages,
  required Map<String, int?> pings,
  bool probingSupported = true,
  Prefs? prefs,
}) {
  final store = ResultsStore(prefs: prefs ?? MemoryPrefs());
  final settings = AppSettings(prefs ?? MemoryPrefs());

  return RunCoordinator(
    discovery: DiscoveryController(
      fetcher: FakeFetcher(pages),
      config: const DiscoveryConfig(queriesPerEngine: 1),
    )..toggleEngineForTest(),
    results: store,
    settings: settings,
    probe: FakeProbe(pings, supported: probingSupported),
  );
}

/// Narrows the controller to a single engine so a test run is deterministic.
extension on DiscoveryController {
  void toggleEngineForTest() {
    for (final engine in kEngines) {
      if (engine.id != 'duckduckgo' && isEnabled(engine.id)) {
        toggleEngine(engine.id);
      }
    }
  }
}

void main() {
  const serp = '<a href="https://gist.github.com/list">a</a>';

  test('searches, tests, stores and ranks in one run', () async {
    final coordinator = build(
      pages: {
        'duckduckgo.com': serp,
        'gist.github.com':
            'vless://u1@1.1.1.1:443?security=reality#Fast\n'
            'vless://u2@2.2.2.2:443?security=reality#Slow\n'
            'vless://u3@3.3.3.3:443?security=reality#Dead',
      },
      pings: {'1.1.1.1': 20, '2.2.2.2': 300, '3.3.3.3': null},
    );

    await coordinator.run();

    expect(coordinator.stage, RunStage.done);

    final results = coordinator.results.all;
    final byHost = {for (final e in results) e.host: e};

    expect(byHost['1.1.1.1']!.health, Health.ok);
    expect(byHost['1.1.1.1']!.ping, const Duration(milliseconds: 20));
    expect(byHost['2.2.2.2']!.health, Health.slow);
    expect(byHost['3.3.3.3']!.health, Health.dead);

    expect(
      coordinator.best!.host,
      '1.1.1.1',
      reason: 'the fastest proven-healthy endpoint is what a connect uses',
    );
  });

  test('records the run in history', () async {
    final coordinator = build(
      pages: {
        'duckduckgo.com': serp,
        'gist.github.com': 'vless://u@1.1.1.1:443#A',
      },
      pings: {'1.1.1.1': 30},
    );

    await coordinator.run();

    final history = coordinator.results.history;
    expect(history, hasLength(1));
    expect(history.single.found, 1);
    expect(history.single.healthy, 1);
  });

  test('a platform without sockets does not condemn everything', () async {
    final coordinator = build(
      pages: {
        'duckduckgo.com': serp,
        'gist.github.com': 'vless://u@1.1.1.1:443#A',
      },
      pings: const {},
      probingSupported: false,
    );

    await coordinator.run();

    expect(coordinator.probingSupported, isFalse);
    expect(coordinator.results.all.single.health, Health.untested);
  });

  test('best is null when a run finds nothing healthy', () async {
    final coordinator = build(
      pages: {
        'duckduckgo.com': serp,
        'gist.github.com': 'vless://u@9.9.9.9:443#A',
      },
      pings: {'9.9.9.9': null},
    );

    await coordinator.run();

    expect(coordinator.best, isNull);
  });

  test('moves through the stages the simple-mode cards show', () async {
    final coordinator = build(
      pages: {
        'duckduckgo.com': serp,
        'gist.github.com': 'vless://u@1.1.1.1:443#A',
      },
      pings: {'1.1.1.1': 30},
    );

    final stages = <RunStage>[];
    coordinator.addListener(() {
      if (stages.isEmpty || stages.last != coordinator.stage) {
        stages.add(coordinator.stage);
      }
    });

    await coordinator.run();

    expect(
      stages,
      containsAllInOrder([RunStage.searching, RunStage.testing, RunStage.done]),
    );
  });

  test('retesting re-measures without searching again', () async {
    final prefs = MemoryPrefs();
    final coordinator = build(
      pages: {
        'duckduckgo.com': serp,
        'gist.github.com': 'vless://u@1.1.1.1:443#A',
      },
      pings: {'1.1.1.1': 30},
      prefs: prefs,
    );

    await coordinator.run();
    expect(coordinator.results.history, hasLength(1));

    await coordinator.retestExisting();

    expect(
      coordinator.results.all.single.ping,
      const Duration(milliseconds: 30),
    );
    expect(
      coordinator.results.history,
      hasLength(1),
      reason: 'a retest is not a new run and must not add a history row',
    );
  });
}
