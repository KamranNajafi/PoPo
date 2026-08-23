// ignore: unnecessary_library_name
library popo.discovery.models;

/// Core types for discovery. Deliberately free of I/O so the whole pipeline can
/// be tested without a network, and ported to the Go core unchanged in shape.

/// What a discovered endpoint is.
enum EndpointKind { config, proxy }

/// Transport/protocol of a discovered endpoint.
enum Protocol {
  vless,
  vmess,
  trojan,
  shadowsocks,
  shadowsocksR,
  hysteria2,
  tuic,
  socks5,
  http,
  https,
  unknown;

  static Protocol fromScheme(String scheme) => switch (scheme.toLowerCase()) {
        'vless' => vless,
        'vmess' => vmess,
        'trojan' => trojan,
        'ss' => shadowsocks,
        'ssr' => shadowsocksR,
        'hysteria2' || 'hy2' => hysteria2,
        'tuic' => tuic,
        'socks5' || 'socks' => socks5,
        'http' => http,
        'https' => https,
        _ => unknown,
      };

  bool get isConfig => switch (this) {
        vless || vmess || trojan || shadowsocks || shadowsocksR || hysteria2 || tuic => true,
        _ => false,
      };
}

/// One endpoint as discovered — before any latency or liveness testing.
class Endpoint {
  const Endpoint({
    required this.raw,
    required this.kind,
    required this.protocol,
    required this.host,
    required this.port,
    required this.fingerprint,
    this.label,
    this.sources = const {},
    this.score = 0,
  });

  /// The original link or `ip:port`, exactly as found.
  final String raw;

  final EndpointKind kind;
  final Protocol protocol;
  final String host;
  final int port;

  /// Identity for dedup: protocol + host + port + the parts that actually change
  /// how you connect. The display name is excluded on purpose — the same server
  /// is republished under dozens of names.
  final String fingerprint;

  /// The `#name` fragment, when the publisher set one.
  final String? label;

  /// Every page this endpoint was found on. Appearing in several independent
  /// places is the strongest signal available before testing.
  final Set<String> sources;

  final double score;

  Endpoint copyWith({Set<String>? sources, double? score}) => Endpoint(
        raw: raw,
        kind: kind,
        protocol: protocol,
        host: host,
        port: port,
        fingerprint: fingerprint,
        label: label,
        sources: sources ?? this.sources,
        score: score ?? this.score,
      );

  @override
  String toString() => '$protocol $host:$port (${sources.length} sources)';
}

/// A generated search phrase, with the reason it was generated.
class Keyword {
  const Keyword(this.text, {this.weight = 1.0, this.tags = const {}});

  /// The phrase handed to a search engine.
  final String text;

  /// Prior belief that this phrase yields configs. Used to order queries so the
  /// per-run budget is spent on the best phrases first.
  final double weight;

  /// Where the phrase came from: `protocol`, `persian`, `site`, `fresh`…
  final Set<String> tags;

  @override
  bool operator ==(Object other) => other is Keyword && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}

/// A link a search engine returned.
class SearchHit {
  const SearchHit({required this.url, required this.engineId, required this.keyword});

  final String url;
  final String engineId;
  final String keyword;
}

/// Why an engine stopped producing results.
enum EngineStatus { idle, queued, running, done, blocked, captcha, failed }

/// Live state of one engine within a run.
class EngineState {
  const EngineState({
    required this.id,
    this.status = EngineStatus.idle,
    this.hits = 0,
    this.error,
  });

  final String id;
  final EngineStatus status;
  final int hits;
  final String? error;

  EngineState copyWith({EngineStatus? status, int? hits, String? error}) => EngineState(
        id: id,
        status: status ?? this.status,
        hits: hits ?? this.hits,
        error: error ?? this.error,
      );
}
