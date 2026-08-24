import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/discovery/extract.dart';
import '../../core/discovery/models.dart';
import '../../core/util/prefs.dart';

/// One completed discovery run, as the history screen lists it.
class RunRecord {
  const RunRecord({
    required this.at,
    required this.found,
    required this.healthy,
    required this.engines,
  });

  final DateTime at;
  final int found;
  final int healthy;
  final int engines;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'found': found,
        'healthy': healthy,
        'engines': engines,
      };

  static RunRecord fromJson(Map<String, dynamic> json) => RunRecord(
        at: DateTime.parse(json['at'] as String),
        found: json['found'] as int,
        healthy: json['healthy'] as int,
        engines: json['engines'] as int,
      );
}

/// Which half of the results list is showing, and how it is filtered.
class ResultFilters {
  const ResultFilters({
    this.kind = EndpointKind.config,
    this.protocol,
    this.sort = ResultSort.ping,
  });

  final EndpointKind kind;

  /// Null means "all".
  final Protocol? protocol;
  final ResultSort sort;

  ResultFilters copyWith({
    EndpointKind? kind,
    Protocol? protocol,
    ResultSort? sort,
    bool clearProtocol = false,
  }) =>
      ResultFilters(
        kind: kind ?? this.kind,
        protocol: clearProtocol ? null : (protocol ?? this.protocol),
        sort: sort ?? this.sort,
      );
}

enum ResultSort { ping, score, recent }

/// Everything the results, saved and history screens read.
///
/// Saved endpoints and run history persist; the full result set of a run stays
/// in memory. That split is deliberate for now: saved items and history are
/// small and bounded, while a result set can run to thousands of rows and wants
/// a real database rather than a JSON blob in preferences. Swapping in SQLite
/// later touches this class alone.
class ResultsStore extends ChangeNotifier {
  ResultsStore({required this.prefs, this.extractor = const Extractor()}) {
    _load();
  }

  static const _savedKey = 'results.saved';
  static const _historyKey = 'results.history';

  final Prefs prefs;
  final Extractor extractor;

  final Map<String, Endpoint> _current = {};
  final Map<String, Endpoint> _saved = {};
  List<RunRecord> _history = [];
  ResultFilters _filters = const ResultFilters();

  // --- Reads -----------------------------------------------------------------

  /// Everything from the latest run, plus saved items so they never vanish from
  /// the list just because the newest run did not rediscover them.
  List<Endpoint> get all {
    final merged = <String, Endpoint>{..._saved, ..._current};
    return merged.values.toList();
  }

  List<Endpoint> get saved => _saved.values.toList()..sort(_byPing);
  List<RunRecord> get history => List.unmodifiable(_history);
  ResultFilters get filters => _filters;

  int get configCount => all.where((e) => e.kind == EndpointKind.config).length;
  int get proxyCount => all.where((e) => e.kind == EndpointKind.proxy).length;

  /// The protocols actually present, so the filter chips reflect the data
  /// instead of a hardcoded list.
  List<Protocol> get availableProtocols {
    final present = all
        .where((e) => e.kind == _filters.kind)
        .map((e) => e.protocol)
        .toSet()
        .toList();
    present.sort((a, b) => a.name.compareTo(b.name));
    return present;
  }

  /// The current filtered, sorted view.
  List<Endpoint> get visible {
    final out = all
        .where((e) => e.kind == _filters.kind)
        .where((e) => _filters.protocol == null || e.protocol == _filters.protocol)
        .toList();

    out.sort(switch (_filters.sort) {
      ResultSort.ping => _byPing,
      ResultSort.score => (a, b) => b.score.compareTo(a.score),
      ResultSort.recent => (a, b) => (b.lastTestedAt ?? DateTime(0))
          .compareTo(a.lastTestedAt ?? DateTime(0)),
    });
    return out;
  }

  /// The best endpoint to connect to: healthy, lowest ping. Null when a run
  /// found nothing usable — simple mode shows its failure state rather than
  /// connecting to something untested.
  Endpoint? get best {
    final healthy = all
        .where((e) => e.health == Health.ok || e.health == Health.slow)
        .toList()
      ..sort(_byPing);
    return healthy.isEmpty ? null : healthy.first;
  }

  bool isSaved(String fingerprint) => _saved.containsKey(fingerprint);

  // --- Writes ----------------------------------------------------------------

  /// Replaces the current run's results, carrying over the saved flag.
  void setResults(List<Endpoint> endpoints) {
    _current
      ..clear()
      ..addEntries(endpoints.map((e) =>
          MapEntry(e.fingerprint, e.copyWith(saved: _saved.containsKey(e.fingerprint)))));

    // Saved copies are refreshed with the new measurements — a saved item
    // showing a ping from last week would be worse than showing none.
    for (final endpoint in endpoints) {
      if (_saved.containsKey(endpoint.fingerprint)) {
        _saved[endpoint.fingerprint] = endpoint.copyWith(saved: true);
      }
    }
    _persistSaved();
    notifyListeners();
  }

  void removeAll(Iterable<String> fingerprints) {
    for (final fingerprint in fingerprints) {
      _current.remove(fingerprint);
    }
    notifyListeners();
  }

  Future<void> toggleSaved(String fingerprint) async {
    if (_saved.remove(fingerprint) == null) {
      final endpoint = _current[fingerprint];
      if (endpoint == null) return;
      _saved[fingerprint] = endpoint.copyWith(saved: true);
    }
    final current = _current[fingerprint];
    if (current != null) {
      _current[fingerprint] =
          current.copyWith(saved: _saved.containsKey(fingerprint));
    }
    await _persistSaved();
    notifyListeners();
  }

  Future<void> unsaveAll(Iterable<String> fingerprints) async {
    for (final fingerprint in fingerprints) {
      _saved.remove(fingerprint);
      final current = _current[fingerprint];
      if (current != null) _current[fingerprint] = current.copyWith(saved: false);
    }
    await _persistSaved();
    notifyListeners();
  }

  void setFilters(ResultFilters filters) {
    _filters = filters;
    notifyListeners();
  }

  Future<void> clearResults() async {
    _current.clear();
    notifyListeners();
  }

  Future<void> recordRun(RunRecord record) async {
    // Newest first, and bounded — history is a list to glance at, not an archive.
    _history = [record, ..._history].take(30).toList();
    await prefs.setStringList(
        _historyKey, _history.map((r) => jsonEncode(r.toJson())).toList());
    notifyListeners();
  }

  // --- Import ----------------------------------------------------------------

  /// Adds endpoints parsed out of pasted text: a subscription body, a clipboard
  /// full of links, or a single config URI.
  ///
  /// This is the same extractor discovery uses, so a base64 subscription payload
  /// and a plain list of links both work without special cases. On the Apple
  /// builds, where discovery is compiled out, this is the app's only way in.
  int importFromText(String text, {String source = 'import'}) {
    final found = extractor.extract(text, source: source);
    if (found.isEmpty) return 0;

    for (final endpoint in found) {
      final existing = _current[endpoint.fingerprint];
      _current[endpoint.fingerprint] = existing == null
          ? endpoint
          : existing.copyWith(sources: {...existing.sources, ...endpoint.sources});
    }
    notifyListeners();
    return found.length;
  }

  /// A subscription body is often one base64 blob; the extractor handles both
  /// that and a plain newline-separated list.
  int importSubscription(String body, {required String url}) =>
      importFromText(body, source: url);

  // --- Storage ---------------------------------------------------------------

  void _load() {
    for (final raw in prefs.getStringList(_savedKey) ?? const <String>[]) {
      final endpoint = _tryDecodeEndpoint(raw);
      if (endpoint != null) _saved[endpoint.fingerprint] = endpoint;
    }
    _history = [
      for (final raw in prefs.getStringList(_historyKey) ?? const <String>[])
        ?_tryDecodeRun(raw),
    ];
  }

  Future<void> _persistSaved() => prefs.setStringList(
      _savedKey, _saved.values.map((e) => jsonEncode(e.toJson())).toList());

  /// Stored records are decoded defensively: a shape change between versions
  /// should cost the user one stale row, not every saved server.
  Endpoint? _tryDecodeEndpoint(String raw) {
    try {
      return Endpoint.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  RunRecord? _tryDecodeRun(String raw) {
    try {
      return RunRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  static int _byPing(Endpoint a, Endpoint b) {
    final aPing = a.ping;
    final bPing = b.ping;
    if (aPing != null && bPing != null) return aPing.compareTo(bPing);
    if (aPing != null) return -1;
    if (bPing != null) return 1;
    return b.score.compareTo(a.score);
  }
}
