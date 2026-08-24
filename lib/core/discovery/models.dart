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

/// How an endpoint performed when it was last tested.
enum Health {
  /// Never tested.
  untested,

  /// Answered quickly. The design's threshold is 100ms.
  ok,

  /// Answered, but slowly. Up to 180ms; above that it is still `slow` but shown
  /// in the danger colour.
  slow,

  /// Did not answer.
  dead;

  /// Classifies a latency. Thresholds come from the design's ping colours.
  static Health fromLatency(Duration? latency) {
    if (latency == null) return dead;
    final ms = latency.inMilliseconds;
    if (ms <= 100) return ok;
    return slow;
  }
}

/// One endpoint, as discovered and then as tested.
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
    this.ping,
    this.health = Health.untested,
    this.lastTestedAt,
    this.failureCount = 0,
    this.saved = false,
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

  /// Pre-test ranking. Once [ping] exists, measurement replaces this guess.
  final double score;

  /// Measured round trip, null until tested or when the last test failed.
  final Duration? ping;

  final Health health;
  final DateTime? lastTestedAt;

  /// Consecutive failed tests. The auto-remove setting acts on this.
  final int failureCount;

  final bool saved;

  Endpoint copyWith({
    Set<String>? sources,
    double? score,
    Duration? ping,
    Health? health,
    DateTime? lastTestedAt,
    int? failureCount,
    bool? saved,
    bool clearPing = false,
  }) =>
      Endpoint(
        raw: raw,
        kind: kind,
        protocol: protocol,
        host: host,
        port: port,
        fingerprint: fingerprint,
        label: label,
        sources: sources ?? this.sources,
        score: score ?? this.score,
        // A failed retest has to be able to clear a previously good ping, which
        // `ping ?? this.ping` alone cannot express.
        ping: clearPing ? null : (ping ?? this.ping),
        health: health ?? this.health,
        lastTestedAt: lastTestedAt ?? this.lastTestedAt,
        failureCount: failureCount ?? this.failureCount,
        saved: saved ?? this.saved,
      );

  /// A display name: the publisher's label when there is one, else the address.
  String get displayName => label?.trim().isNotEmpty == true
      ? label!.trim()
      : '\$host:\$port';

  Map<String, dynamic> toJson() => {
        'raw': raw,
        'kind': kind.name,
        'protocol': protocol.name,
        'host': host,
        'port': port,
        'fingerprint': fingerprint,
        'label': label,
        'sources': sources.toList(),
        'score': score,
        'pingMs': ping?.inMilliseconds,
        'health': health.name,
        'lastTestedAt': lastTestedAt?.toIso8601String(),
        'failureCount': failureCount,
        'saved': saved,
      };

  static Endpoint fromJson(Map<String, dynamic> json) => Endpoint(
        raw: json['raw'] as String,
        kind: EndpointKind.values.byName(json['kind'] as String),
        protocol: Protocol.values.byName(json['protocol'] as String),
        host: json['host'] as String,
        port: json['port'] as int,
        fingerprint: json['fingerprint'] as String,
        label: json['label'] as String?,
        sources: ((json['sources'] as List?) ?? const []).cast<String>().toSet(),
        score: (json['score'] as num?)?.toDouble() ?? 0,
        ping: json['pingMs'] == null
            ? null
            : Duration(milliseconds: json['pingMs'] as int),
        health: Health.values.byName((json['health'] as String?) ?? 'untested'),
        lastTestedAt: json['lastTestedAt'] == null
            ? null
            : DateTime.parse(json['lastTestedAt'] as String),
        failureCount: (json['failureCount'] as int?) ?? 0,
        saved: (json['saved'] as bool?) ?? false,
      );

  @override
  String toString() => '\$protocol \$host:\$port (\${sources.length} sources)';
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
