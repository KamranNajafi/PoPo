import 'dart:convert';

import 'models.dart';

/// Pulls endpoints out of arbitrary page text.
///
/// Three shapes appear in the wild and all three are handled: bare config URIs
/// in the page body, base64 blobs that decode to a newline-separated list of
/// them (what a subscription URL actually serves), and plain `ip:port` proxy
/// tables. Everything is normalized to a [fingerprint] so the same server
/// republished under twenty different display names collapses to one result.
class Extractor {
  const Extractor();

  /// Config URI schemes. Anchored to a scheme so arbitrary URLs are not matched.
  static final _configUri = RegExp(
    r'\b(vless|vmess|trojan|ss|ssr|hysteria2|hy2|tuic)://[^\s"' r"'" r'<>\)\]\}\\]+',
    caseSensitive: false,
  );

  /// `1.2.3.4:8080`, optionally prefixed with a protocol word from a table cell.
  static final _ipPort = RegExp(
    r'(?:(socks5|socks4|https?)\s*[:\|\s]\s*)?'
    r'\b((?:\d{1,3}\.){3}\d{1,3})\s*[:\s]\s*(\d{2,5})\b',
    caseSensitive: false,
  );

  /// An unbroken base64 run — candidate subscription payload. 40 chars is about
  /// the shortest run that decodes to a usable link rather than to noise.
  static final _base64Blob = RegExp(r'[A-Za-z0-9+/_-]{40,}={0,2}');

  /// Extracts every endpoint in [text]. [source] labels where it came from and
  /// is what dedup later counts to measure corroboration.
  List<Endpoint> extract(String text, {required String source}) {
    final found = <String, Endpoint>{};

    void put(Endpoint? e) {
      if (e == null) return;
      final existing = found[e.fingerprint];
      found[e.fingerprint] = existing == null
          ? e
          : existing.copyWith(sources: {...existing.sources, ...e.sources});
    }

    // Config URIs are matched first and then blanked out, because every one of
    // them contains a "host:port" that the proxy scan would otherwise re-match
    // as a separate SOCKS5 proxy that does not exist.
    final masked = StringBuffer();
    var cursor = 0;
    for (final m in _configUri.allMatches(text)) {
      put(_parseConfigUri(m.group(0)!, source));
      masked
        ..write(text.substring(cursor, m.start))
        ..write(' ' * (m.end - m.start));
      cursor = m.end;
    }
    masked.write(text.substring(cursor));

    for (final m in _ipPort.allMatches(masked.toString())) {
      put(_parseProxy(m, source));
    }

    // A subscription payload is base64 of the very same URIs, so decode and
    // re-run rather than duplicating the parsing. Two shapes: a blob embedded in
    // a page, and a whole response body that is nothing but a wrapped blob.
    for (final candidate in [
      ..._base64Blob.allMatches(text).map((m) => m.group(0)!),
      text,
    ]) {
      final decoded = _tryDecodeBase64(candidate);
      if (decoded == null || !decoded.contains('://')) continue;
      for (final m in _configUri.allMatches(decoded)) {
        put(_parseConfigUri(m.group(0)!, source));
      }
    }

    return found.values.toList();
  }

  Endpoint? _parseConfigUri(String raw, String source) {
    final trimmed = raw.trim().replaceAll(RegExp(r'[.,;]+$'), '');
    final schemeEnd = trimmed.indexOf('://');
    if (schemeEnd <= 0) return null;

    final protocol = Protocol.fromScheme(trimmed.substring(0, schemeEnd));
    if (protocol == Protocol.unknown) return null;

    final label = _fragment(trimmed);

    // vmess:// carries a base64 JSON body rather than a URL authority.
    final (host, port) = protocol == Protocol.vmess
        ? _vmessHostPort(trimmed.substring(schemeEnd + 3))
        : _authorityHostPort(trimmed.substring(schemeEnd + 3));

    if (host == null || port == null || !_plausiblePort(port)) return null;

    return Endpoint(
      raw: trimmed,
      kind: EndpointKind.config,
      protocol: protocol,
      host: host,
      port: port,
      // The display name is excluded: it is the one part publishers always
      // change, and including it would defeat dedup entirely.
      fingerprint: '${protocol.name}|${host.toLowerCase()}|$port|${_credential(trimmed, protocol)}',
      label: label,
      sources: {source},
    );
  }

  /// The user/uuid part, which distinguishes two accounts on one server.
  String _credential(String uri, Protocol protocol) {
    if (protocol == Protocol.vmess) {
      final json = _vmessJson(uri.substring(uri.indexOf('://') + 3));
      return (json?['id'] ?? '').toString();
    }
    final afterScheme = uri.substring(uri.indexOf('://') + 3);
    final at = afterScheme.indexOf('@');
    return at > 0 ? afterScheme.substring(0, at) : '';
  }

  String? _fragment(String uri) {
    final hash = uri.indexOf('#');
    if (hash < 0 || hash == uri.length - 1) return null;
    try {
      return Uri.decodeComponent(uri.substring(hash + 1));
    } on ArgumentError {
      return uri.substring(hash + 1);
    }
  }

  (String?, int?) _authorityHostPort(String afterScheme) {
    var s = afterScheme;
    for (final cut in const ['#', '?', '/']) {
      final i = s.indexOf(cut);
      if (i >= 0) s = s.substring(0, i);
    }
    final at = s.lastIndexOf('@');
    if (at >= 0) s = s.substring(at + 1);

    // IPv6 literal: [::1]:443
    if (s.startsWith('[')) {
      final close = s.indexOf(']');
      if (close < 0) return (null, null);
      final host = s.substring(1, close);
      final rest = s.substring(close + 1);
      return (host, rest.startsWith(':') ? int.tryParse(rest.substring(1)) : null);
    }

    final colon = s.lastIndexOf(':');
    if (colon <= 0) return (null, null);
    return (s.substring(0, colon), int.tryParse(s.substring(colon + 1)));
  }

  (String?, int?) _vmessHostPort(String body) {
    final json = _vmessJson(body);
    if (json == null) return (null, null);
    final host = (json['add'] ?? '').toString();
    final port = int.tryParse((json['port'] ?? '').toString());
    return (host.isEmpty ? null : host, port);
  }

  Map<String, dynamic>? _vmessJson(String body) {
    final decoded = _tryDecodeBase64(body.split('#').first);
    if (decoded == null) return null;
    try {
      final parsed = jsonDecode(decoded);
      return parsed is Map<String, dynamic> ? parsed : null;
    } on FormatException {
      return null;
    }
  }

  Endpoint? _parseProxy(RegExpMatch m, String source) {
    final host = m.group(2)!;
    final port = int.tryParse(m.group(3)!);
    if (port == null || !_plausiblePort(port)) return null;
    if (!_plausibleIpv4(host)) return null;

    final protocol = m.group(1) == null
        ? Protocol.socks5
        : Protocol.fromScheme(m.group(1)!);

    return Endpoint(
      raw: '$host:$port',
      kind: EndpointKind.proxy,
      protocol: protocol == Protocol.unknown ? Protocol.socks5 : protocol,
      host: host,
      port: port,
      // Proxy tables list the same address under http and socks5 lines, and the
      // port is what actually differs, so the protocol stays out of the key.
      fingerprint: 'proxy|$host|$port',
      sources: {source},
    );
  }

  bool _plausiblePort(int port) => port > 0 && port <= 65535;

  /// Rejects version strings and dates that look like dotted quads.
  bool _plausibleIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n > 255) return false;
      if (p.length > 1 && p.startsWith('0')) return false;
    }
    // 0.x and 127.x are never a usable public proxy.
    final first = int.parse(parts.first);
    return first != 0 && first != 127 && first < 224;
  }

  String? _tryDecodeBase64(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length < 8) return null;
    // Subscription payloads are commonly unpadded, and often URL-safe.
    final normalized = cleaned.replaceAll('-', '+').replaceAll('_', '/');
    final padded = normalized.padRight(
      normalized.length + (4 - normalized.length % 4) % 4,
      '=',
    );
    try {
      return utf8.decode(base64.decode(padded), allowMalformed: false);
    } on Object {
      return null;
    }
  }
}
