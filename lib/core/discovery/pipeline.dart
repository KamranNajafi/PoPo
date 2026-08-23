import 'dart:async';

import 'engines.dart';
import 'extract.dart';
import 'fetcher.dart';
import 'keywords.dart';
import 'models.dart';

/// Tuning for one discovery run.
class DiscoveryConfig {
  const DiscoveryConfig({
    this.keywordLimit = 40,
    this.queriesPerEngine = 6,
    this.pagesPerQuery = 8,
    this.maxPagesTotal = 120,
    this.perEngineResultCap = 50,
    this.engineConcurrency = 3,
    this.pageConcurrency = 6,
    this.requestTimeout = const Duration(seconds: 8),
    this.minSourcesToTrust = 1,
  });

  final int keywordLimit;
  final int queriesPerEngine;

  /// SERP links followed per query.
  final int pagesPerQuery;

  /// Hard ceiling on page fetches, so a run cannot grow without bound.
  final int maxPagesTotal;

  final int perEngineResultCap;
  final int engineConcurrency;
  final int pageConcurrency;
  final Duration requestTimeout;

  /// Raise above 1 to keep only endpoints corroborated by several pages.
  final int minSourcesToTrust;
}

/// Progress emitted while a run is in flight — this is what screen 02 renders.
class DiscoveryProgress {
  const DiscoveryProgress({
    required this.engines,
    required this.found,
    required this.pagesFetched,
  });

  final Map<String, EngineState> engines;
  final int found;
  final int pagesFetched;
}

/// Search → follow → extract → dedup → rank.
///
/// The two hard constraints shape everything here. Engines block clients that
/// hammer them, so queries are spread across engines and each engine drops out
/// on its first block rather than retrying into a ban. And a run must be
/// bounded, because the phrases are open-ended and the link graph is not — so
/// every stage has a cap and the totals are enforced globally, not per stage.
class DiscoveryPipeline {
  DiscoveryPipeline({
    required this.fetcher,
    this.config = const DiscoveryConfig(),
    this.generator = const KeywordGenerator(),
    this.extractor = const Extractor(),
    List<SearchEngine>? engines,
    this.keywords,
  }) : engines = engines ?? kEngines.where((e) => e.enabledByDefault).toList();

  final Fetcher fetcher;
  final DiscoveryConfig config;
  final KeywordGenerator generator;
  final Extractor extractor;
  final List<SearchEngine> engines;

  /// Phrases to search. When null the generator supplies them; callers pass this
  /// to search a user-edited list instead.
  final List<Keyword>? keywords;

  final _progress = StreamController<DiscoveryProgress>.broadcast();
  Stream<DiscoveryProgress> get progress => _progress.stream;

  final Map<String, EngineState> _states = {};
  final Map<String, Endpoint> _found = {};
  final Set<String> _visited = {};
  int _pagesFetched = 0;
  bool _cancelled = false;

  /// Stops the run at the next checkpoint. Whatever has already been found is
  /// kept and returned — a user pressing "stop" wants the partial list, not an
  /// empty one.
  void cancel() {
    _cancelled = true;
    for (final MapEntry(key: id, value: state) in _states.entries) {
      if (state.status == EngineStatus.running || state.status == EngineStatus.queued) {
        _states[id] = state.copyWith(status: EngineStatus.idle);
      }
    }
    _emit();
  }

  bool get isCancelled => _cancelled;

  /// Runs discovery to completion and returns the ranked endpoints.
  Future<List<Endpoint>> run() async {
    _states.clear();
    _found.clear();
    _visited.clear();
    _pagesFetched = 0;
    _cancelled = false;

    final phrases = keywords ?? generator.generate(limit: config.keywordLimit);
    for (final e in engines) {
      _states[e.id] = EngineState(id: e.id, status: EngineStatus.queued);
    }
    _emit();

    // Engines run a few at a time. Sequential wastes the whole run on one slow
    // engine; all at once looks like a burst and gets everything blocked.
    await _forEachLimited(engines, config.engineConcurrency, (engine) async {
      if (_cancelled) return;
      await _runEngine(engine, phrases);
    });

    await _progress.close();
    return ranked();
  }

  Future<void> _runEngine(SearchEngine engine, List<Keyword> keywords) async {
    _setState(engine.id, status: EngineStatus.running);

    // Each engine gets its own slice of the keyword list, so the engines cover
    // different phrases instead of all asking the same top query.
    final offset = engines.indexOf(engine);
    final phrases = _sliceFor(keywords, offset, engine);

    var produced = 0;
    for (final keyword in phrases) {
      if (_cancelled) return;
      if (produced >= config.perEngineResultCap) break;
      if (_pagesFetched >= config.maxPagesTotal) break;

      final FetchResult result;
      try {
        result = await fetcher
            .get(engine.buildUrl(keyword.text), headers: _serpHeaders)
            .timeout(config.requestTimeout);
      } on Object catch (e) {
        _setState(engine.id, status: EngineStatus.failed, error: '$e');
        return;
      }

      final verdict = engine.classify(result.statusCode, result.body);
      if (verdict != EngineStatus.done) {
        // A blocked engine stays blocked for this run. Retrying is what turns a
        // rate-limit into a ban, and the other engines cover the same phrases.
        _setState(engine.id, status: verdict);
        return;
      }

      final links = engine
          .parseLinks(result.body)
          .where(_looksPromising)
          .take(config.pagesPerQuery)
          .toList();

      produced += await _harvest(links, engine.id);
      _emit();
    }

    if (!_cancelled && _states[engine.id]?.status == EngineStatus.running) {
      _setState(engine.id, status: EngineStatus.done);
    }
  }

  /// Fetches result pages and extracts endpoints from each.
  Future<int> _harvest(List<String> links, String engineId) async {
    var added = 0;

    await _forEachLimited(links, config.pageConcurrency, (url) async {
      if (_cancelled) return;
      if (!_visited.add(_canonical(url))) return;
      if (_pagesFetched >= config.maxPagesTotal) return;
      _pagesFetched++;

      final FetchResult page;
      try {
        page = await fetcher.get(url, headers: _pageHeaders).timeout(config.requestTimeout);
      } on Object {
        return; // One dead link is not a reason to abandon the query.
      }
      if (!page.ok) return;

      for (final endpoint in extractor.extract(page.body, source: url)) {
        final existing = _found[endpoint.fingerprint];
        if (existing == null) {
          _found[endpoint.fingerprint] = endpoint;
          added++;
        } else {
          _found[endpoint.fingerprint] =
              existing.copyWith(sources: {...existing.sources, ...endpoint.sources});
        }
      }
    });

    _setState(engineId, hits: (_states[engineId]?.hits ?? 0) + added);
    return added;
  }

  /// Ranked results, best first.
  ///
  /// This ordering is a prior, not a measurement — it decides which endpoints
  /// are worth spending a latency probe on. Real ping replaces it afterwards.
  List<Endpoint> ranked() {
    final out = _found.values
        .where((e) => e.sources.length >= config.minSourcesToTrust)
        .map((e) => e.copyWith(score: _score(e)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  double _score(Endpoint e) {
    var score = 0.0;

    // Corroboration is the strongest pre-test signal: an endpoint republished
    // on several independent pages is far more likely to be live. Damped, so
    // one popular list cannot dominate the ranking.
    score += 3.0 * _log2(e.sources.length + 1);

    // Source quality.
    for (final source in e.sources) {
      if (source.contains('raw.githubusercontent.com')) score += 1.5;
      if (source.contains('gist.github.com')) score += 1.2;
      if (source.contains('github.com')) score += 1.0;
      if (source.contains('t.me')) score += 0.6;
    }

    // Protocol prior: newer transports survive filtering longer.
    score += switch (e.protocol) {
      Protocol.vless => 2.0,
      Protocol.hysteria2 => 1.8,
      Protocol.tuic => 1.5,
      Protocol.trojan => 1.2,
      Protocol.vmess => 1.0,
      Protocol.shadowsocks => 1.0,
      Protocol.shadowsocksR => 0.4,
      _ => 0.5,
    };

    // Reality and TLS on 443 blend into ordinary traffic.
    final raw = e.raw.toLowerCase();
    if (raw.contains('reality')) score += 1.5;
    if (raw.contains('security=tls')) score += 0.5;
    if (e.port == 443) score += 0.8;

    // A config carrying no transport parameters is usually a truncated paste.
    if (e.kind == EndpointKind.config && !raw.contains('?') && e.protocol != Protocol.vmess) {
      score -= 1.0;
    }

    return score;
  }

  /// Skips SERP links that never carry configs, before spending a fetch on them.
  bool _looksPromising(String url) {
    final lower = url.toLowerCase();
    for (final bad in _uselessHosts) {
      if (lower.contains(bad)) return false;
    }
    // Binaries and archives cannot be scanned as text.
    return !RegExp(r'\.(png|jpe?g|gif|svg|mp4|zip|exe|apk|dmg|pdf)(\?|$)').hasMatch(lower);
  }

  static const _uselessHosts = [
    'youtube.com',
    'facebook.com',
    'instagram.com',
    'twitter.com',
    'x.com',
    'linkedin.com',
    'amazon.',
    'play.google.com',
    'apps.apple.com',
    'wikipedia.org',
  ];

  /// Query slice for one engine: strided so engines cover different phrases,
  /// and site-scoped phrases dropped where the operator is unsupported.
  List<Keyword> _sliceFor(List<Keyword> keywords, int offset, SearchEngine engine) {
    final usable = engine.supportsSiteOperator
        ? keywords
        : keywords.where((k) => !k.text.contains('site:')).toList();
    if (usable.isEmpty) return const [];

    final out = <Keyword>[];
    for (var i = 0; i < config.queriesPerEngine; i++) {
      out.add(usable[(offset + i * engines.length) % usable.length]);
    }
    return out;
  }

  /// Collapses trivially different URLs so the same page is not fetched twice.
  String _canonical(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    return Uri(
      scheme: 'https',
      host: parsed.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), ''),
      path: parsed.path.endsWith('/') && parsed.path.length > 1
          ? parsed.path.substring(0, parsed.path.length - 1)
          : parsed.path,
      query: parsed.query.isEmpty ? null : parsed.query,
    ).toString();
  }

  void _setState(String id, {EngineStatus? status, int? hits, String? error}) {
    final current = _states[id];
    if (current == null) return;
    _states[id] = current.copyWith(status: status, hits: hits, error: error);
    _emit();
  }

  void _emit() {
    if (_progress.isClosed) return;
    _progress.add(DiscoveryProgress(
      engines: Map.unmodifiable(_states),
      found: _found.length,
      pagesFetched: _pagesFetched,
    ));
  }

  static const _serpHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/122.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml',
    'Accept-Language': 'en-US,en;q=0.9,fa;q=0.8',
  };

  static const _pageHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/122.0 Safari/537.36',
    'Accept': 'text/html,text/plain,*/*',
  };
}

double _log2(int n) {
  var result = 0.0;
  var value = n;
  while (value > 1) {
    value >>= 1;
    result += 1;
  }
  return result;
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
        final T item;
        // Advancing the shared iterator is safe: there is no await between the
        // check and the read, so no other worker can interleave here.
        if (!iterator.moveNext()) return;
        item = iterator.current;
        await action(item);
      }
    }));
  }

  await Future.wait(workers);
}
