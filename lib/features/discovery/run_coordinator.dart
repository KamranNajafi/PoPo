import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/discovery/models.dart';
import '../../core/health/health_tester.dart';
import '../../core/health/probe.dart';
import '../results/app_settings.dart';
import '../results/results_store.dart';
import 'discovery_controller.dart';

/// Which stage a full run is in. Mirrors the three step cards on S2.
enum RunStage { idle, searching, testing, picking, done, failed }

/// Chains discovery, health testing and result storage into the one operation
/// both modes actually want.
///
/// Simple mode is this with the stages shown as three cards; advanced mode is
/// the same run with the search screen driving it. Keeping one coordinator means
/// the two modes cannot drift apart in behaviour, which is the failure the
/// design's "simple mode is a view, not a second app" note is guarding against.
class RunCoordinator extends ChangeNotifier {
  RunCoordinator({
    required this.discovery,
    required this.results,
    required this.settings,
    this.probe,
  }) {
    discovery.addListener(notifyListeners);
  }

  final DiscoveryController discovery;
  final ResultsStore results;
  final AppSettings settings;

  /// Injected in tests; null means the platform's real probe.
  final LatencyProbe? probe;

  HealthTester? _tester;
  StreamSubscription<HealthProgress>? _healthSubscription;

  RunStage _stage = RunStage.idle;
  HealthProgress? _healthProgress;
  bool _probingSupported = true;
  Object? _failure;

  RunStage get stage => _stage;
  HealthProgress? get healthProgress => _healthProgress;
  bool get isRunning =>
      _stage == RunStage.searching ||
      _stage == RunStage.testing ||
      _stage == RunStage.picking;

  /// False when the platform cannot open sockets, so the UI can say "not tested
  /// here" instead of showing a list that looks entirely dead.
  bool get probingSupported => _probingSupported;

  Object? get failure => _failure;

  /// How many engines reported, for the first step card.
  int get enginesReporting => discovery.enginesReporting;
  int get foundCount => discovery.found;
  int get healthyCount =>
      _healthProgress?.healthy ?? results.all.where(_isHealthy).length;

  /// The endpoint a connect would use.
  Endpoint? get best => results.best;

  /// Search, test, then pick. Safe to call while running — it is ignored.
  Future<void> run() async {
    if (isRunning) return;

    _failure = null;
    _healthProgress = null;
    _probingSupported = true;

    _stage = RunStage.searching;
    notifyListeners();

    try {
      await discovery.start();
      if (discovery.errorKind != null) {
        _stage = RunStage.failed;
        _failure = discovery.errorKind;
        notifyListeners();
        return;
      }

      final found = discovery.results;
      results.setResults(found);

      _stage = RunStage.testing;
      notifyListeners();

      final tester = HealthTester(
        probe: probe,
        config: HealthConfig(
          timeout: settings.testTimeout,
          autoRemoveDead: settings.autoRemoveDead,
          removeDeadAfterFailures: settings.removeAfterFailures,
        ),
      );
      _tester = tester;
      _healthSubscription = tester.progress.listen((progress) {
        _healthProgress = progress;
        notifyListeners();
      });

      final report = await tester.test(found);
      _probingSupported = report.probingSupported;
      results.setResults(report.tested);

      _stage = RunStage.picking;
      notifyListeners();

      await results.recordRun(
        RunRecord(
          at: DateTime.now(),
          found: found.length,
          healthy: report.healthy.length,
          engines: discovery.engineStates.length,
        ),
      );

      _stage = RunStage.done;
    } on Object catch (e) {
      _failure = e;
      _stage = RunStage.failed;
    } finally {
      await _healthSubscription?.cancel();
      _healthSubscription = null;
      _tester = null;
      notifyListeners();
    }
  }

  /// Re-tests what is already in the store, without searching again.
  Future<void> retestExisting() async {
    if (isRunning) return;

    _stage = RunStage.testing;
    notifyListeners();

    final tester = HealthTester(
      probe: probe,
      config: HealthConfig(
        timeout: settings.testTimeout,
        autoRemoveDead: settings.autoRemoveDead,
        removeDeadAfterFailures: settings.removeAfterFailures,
      ),
    );
    _tester = tester;
    _healthSubscription = tester.progress.listen((progress) {
      _healthProgress = progress;
      notifyListeners();
    });

    final report = await tester.test(results.all);
    _probingSupported = report.probingSupported;
    results.setResults(report.tested);

    await _healthSubscription?.cancel();
    _healthSubscription = null;
    _tester = null;
    _stage = RunStage.done;
    notifyListeners();
  }

  void stop() {
    discovery.stop();
    _tester?.cancel();
  }

  static bool _isHealthy(Endpoint e) =>
      e.health == Health.ok || e.health == Health.slow;

  @override
  void dispose() {
    discovery.removeListener(notifyListeners);
    _healthSubscription?.cancel();
    _tester?.cancel();
    super.dispose();
  }
}
