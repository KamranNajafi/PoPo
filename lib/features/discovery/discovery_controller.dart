import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/discovery/engines.dart';
import '../../core/discovery/fetcher.dart';
import '../../core/discovery/http_fetcher.dart';
import '../../core/discovery/keywords.dart';
import '../../core/discovery/models.dart';
import '../../core/discovery/pipeline.dart';
import '../keywords/keyword_store.dart';

/// Phase of a discovery run, as the UI sees it.
enum RunPhase { idle, running, done, cancelled, failed }

/// Why a run could not proceed. Kept as an enum so the message is chosen where
/// the localizations are available, not here.
enum RunError { noEnginesEnabled, runFailed }

/// Owns one discovery run: which engines are on, which phrases were generated,
/// and the live state of the run.
///
/// A plain [ChangeNotifier] rather than a state-management package — this is the
/// only stateful thing in the app so far, and adding a dependency for it would
/// be a decision made too early.
class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    Fetcher? fetcher,
    this.config = const DiscoveryConfig(),
    this.generator = const KeywordGenerator(),
    this.keywordStore,
  }) : _fetcher = fetcher ?? HttpFetcher() {
    _enabled = {
      for (final e in kEngines)
        if (e.enabledByDefault) e.id,
    };
    keywordStore?.addListener(_onKeywordsChanged);
    _refreshKeywords();
  }

  /// When present, the user's edited phrases replace the generator's own — that
  /// is the whole point of making them editable.
  final KeywordStore? keywordStore;

  void _onKeywordsChanged() {
    _refreshKeywords();
    notifyListeners();
  }

  void _refreshKeywords() {
    final store = keywordStore;
    _keywords = store == null
        ? generator.generate(limit: config.keywordLimit)
        : store.effective.take(config.keywordLimit).toList();
  }

  final Fetcher _fetcher;
  final DiscoveryConfig config;
  final KeywordGenerator generator;

  late Set<String> _enabled;
  late List<Keyword> _keywords;

  DiscoveryPipeline? _pipeline;
  StreamSubscription<DiscoveryProgress>? _subscription;

  RunPhase _phase = RunPhase.idle;
  Map<String, EngineState> _engineStates = {};
  List<Endpoint> _results = const [];
  int _found = 0;
  int _pagesFetched = 0;
  RunError? _errorKind;
  String? _errorDetail;

  // --- Read by the screens ---------------------------------------------------

  RunPhase get phase => _phase;
  bool get isRunning => _phase == RunPhase.running;
  List<Keyword> get keywords => List.unmodifiable(_keywords);
  Set<String> get enabledEngines => Set.unmodifiable(_enabled);
  Map<String, EngineState> get engineStates => Map.unmodifiable(_engineStates);
  List<Endpoint> get results => List.unmodifiable(_results);
  int get found => _found;
  int get pagesFetched => _pagesFetched;

  /// What went wrong, as a kind rather than a message: the controller has no
  /// BuildContext, so it must not decide what the user reads.
  RunError? get errorKind => _errorKind;

  /// The raw exception text, for the log — never shown as the primary message.
  String? get errorDetail => _errorDetail;

  /// Engines that have reported at least one result this run.
  int get enginesReporting =>
      _engineStates.values.where((e) => e.hits > 0).length;

  /// The phrase shown in the search field: the highest-weighted one, which is
  /// what the run actually leads with.
  String get leadKeyword => _keywords.isEmpty ? '' : _keywords.first.text;

  bool isEnabled(String engineId) => _enabled.contains(engineId);

  // --- Commands --------------------------------------------------------------

  void toggleEngine(String engineId) {
    final engine = engineById(engineId);
    if (engine == null) return;
    if (!_enabled.remove(engineId)) _enabled.add(engineId);
    notifyListeners();
  }

  /// Starts a run. Safe to call while one is in flight — it is ignored.
  Future<void> start() async {
    if (isRunning) return;

    final engines = kEngines.where((e) => _enabled.contains(e.id)).toList();
    if (engines.isEmpty) {
      _phase = RunPhase.failed;
      _errorKind = RunError.noEnginesEnabled;
      notifyListeners();
      return;
    }

    _phase = RunPhase.running;
    _errorKind = null;
    _errorDetail = null;
    _results = const [];
    _found = 0;
    _pagesFetched = 0;
    _engineStates = {
      for (final e in engines)
        e.id: EngineState(id: e.id, status: EngineStatus.queued),
    };
    notifyListeners();

    final pipeline = DiscoveryPipeline(
      fetcher: _fetcher,
      config: config,
      generator: generator,
      engines: engines,
      keywords: _keywords,
    );
    _pipeline = pipeline;

    _subscription = pipeline.progress.listen((progress) {
      _engineStates = progress.engines;
      _found = progress.found;
      _pagesFetched = progress.pagesFetched;
      notifyListeners();
    });

    try {
      final results = await pipeline.run();
      _results = results;
      _found = results.length;
      _phase = pipeline.isCancelled ? RunPhase.cancelled : RunPhase.done;
    } on Object catch (e) {
      _errorKind = RunError.runFailed;
      _errorDetail = '$e';
      _phase = RunPhase.failed;
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      _pipeline = null;
      notifyListeners();
    }
  }

  /// Stops the run but keeps whatever was found.
  void stop() {
    _pipeline?.cancel();
  }

  @override
  void dispose() {
    keywordStore?.removeListener(_onKeywordsChanged);
    _subscription?.cancel();
    _pipeline?.cancel();
    if (_fetcher case final HttpFetcher f) f.close();
    super.dispose();
  }
}
