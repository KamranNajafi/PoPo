import 'dart:convert';

import '../discovery/models.dart';

/// Raised when a link cannot be turned into something sing-box can dial.
class UnsupportedConfigException implements Exception {
  const UnsupportedConfigException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedConfigException: $message';
}

/// Turns a discovered link into a sing-box outbound.
///
/// This is the join between discovery and the tunnel: everything upstream deals
/// in opaque URIs, everything downstream needs a typed dial. It is pure so it
/// can be tested exhaustively without a core, and the generated JSON is checked
/// against the real sing-box parser in the Go test suite.
abstract final class OutboundBuilder {
  /// Builds the outbound for [endpoint], tagged [tag].
  static Map<String, dynamic> fromEndpoint(Endpoint endpoint, {String tag = 'proxy'}) {
    if (endpoint.kind == EndpointKind.proxy) {
      return _proxy(endpoint, tag);
    }
    return fromUri(endpoint.raw, tag: tag);
  }

  /// Builds the outbound for a raw config URI.
  static Map<String, dynamic> fromUri(String uri, {String tag = 'proxy'}) {
    final trimmed = uri.trim();
    final schemeEnd = trimmed.indexOf('://');
    if (schemeEnd <= 0) {
      throw const UnsupportedConfigException('not a config link');
    }

    final scheme = trimmed.substring(0, schemeEnd).toLowerCase();
    return switch (scheme) {
      'vless' => _vless(trimmed, tag),
      'vmess' => _vmess(trimmed, tag),
      'trojan' => _trojan(trimmed, tag),
      'ss' => _shadowsocks(trimmed, tag),
      'hysteria2' || 'hy2' => _hysteria2(trimmed, tag),
      'tuic' => _tuic(trimmed, tag),
      'socks' || 'socks5' => _socksUri(trimmed, tag),
      'http' || 'https' => _httpUri(trimmed, tag),
      _ => throw UnsupportedConfigException('unsupported protocol: $scheme'),
    };
  }

  // --- Per-protocol -----------------------------------------------------------

  static Map<String, dynamic> _vless(String uri, String tag) {
    final parts = _Uri.parse(uri);
    final out = <String, dynamic>{
      'type': 'vless',
      'tag': tag,
      'server': parts.host,
      'server_port': parts.port,
      'uuid': parts.userInfo,
    };

    // Vision only applies over TLS; sending it on a plain connection makes
    // sing-box reject the config.
    final flow = parts.query['flow'];
    if (flow != null && flow.isNotEmpty && parts.hasTls) out['flow'] = flow;

    final tls = _tls(parts);
    if (tls != null) out['tls'] = tls;

    final transport = _transport(parts);
    if (transport != null) out['transport'] = transport;

    return out;
  }

  /// vmess carries a base64 JSON body rather than a URL authority.
  static Map<String, dynamic> _vmess(String uri, String tag) {
    final body = uri.substring(uri.indexOf('://') + 3).split('#').first;
    final decoded = _decodeBase64(body);
    if (decoded == null) {
      throw const UnsupportedConfigException('vmess payload is not base64');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(decoded) as Map<String, dynamic>;
    } on Object {
      throw const UnsupportedConfigException('vmess payload is not JSON');
    }

    final host = (json['add'] ?? '').toString();
    final port = int.tryParse((json['port'] ?? '').toString());
    if (host.isEmpty || port == null) {
      throw const UnsupportedConfigException('vmess payload has no address');
    }

    final out = <String, dynamic>{
      'type': 'vmess',
      'tag': tag,
      'server': host,
      'server_port': port,
      'uuid': (json['id'] ?? '').toString(),
      // Old clients wrote "auto"; sing-box wants a concrete cipher name and
      // treats an empty one as auto anyway.
      'security': _vmessSecurity(json['scy']),
      'alter_id': int.tryParse((json['aid'] ?? '0').toString()) ?? 0,
    };

    final tlsMode = (json['tls'] ?? '').toString();
    if (tlsMode == 'tls' || tlsMode == 'reality') {
      final sni = (json['sni'] ?? json['host'] ?? '').toString();
      out['tls'] = <String, dynamic>{
        'enabled': true,
        if (sni.isNotEmpty) 'server_name': sni,
        if ((json['alpn'] ?? '').toString().isNotEmpty)
          'alpn': (json['alpn'] as String).split(','),
      };
    }

    final network = (json['net'] ?? 'tcp').toString();
    final transport = _transportFrom(
      network: network,
      path: (json['path'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      serviceName: (json['path'] ?? '').toString(),
    );
    if (transport != null) out['transport'] = transport;

    return out;
  }

  static String _vmessSecurity(Object? raw) {
    final value = (raw ?? '').toString();
    const supported = {'auto', 'none', 'zero', 'aes-128-gcm', 'chacha20-poly1305'};
    return supported.contains(value) ? value : 'auto';
  }

  static Map<String, dynamic> _trojan(String uri, String tag) {
    final parts = _Uri.parse(uri);
    final out = <String, dynamic>{
      'type': 'trojan',
      'tag': tag,
      'server': parts.host,
      'server_port': parts.port,
      'password': parts.userInfo,
    };

    // Trojan is TLS by definition, so it defaults on even without the parameter.
    out['tls'] = _tls(parts) ?? {'enabled': true, 'server_name': parts.host};

    final transport = _transport(parts);
    if (transport != null) out['transport'] = transport;

    return out;
  }

  /// Two encodings are in the wild: `ss://base64(method:pass)@host:port` and
  /// `ss://base64(method:pass@host:port)`. Both are handled.
  static Map<String, dynamic> _shadowsocks(String uri, String tag) {
    final withoutScheme = uri.substring(uri.indexOf('://') + 3);
    final body = withoutScheme.split('#').first.split('?').first;

    String method;
    String password;
    String host;
    int port;

    if (body.contains('@')) {
      final at = body.lastIndexOf('@');
      final credentials = body.substring(0, at);
      final address = body.substring(at + 1);

      final decoded = _decodeBase64(credentials) ?? credentials;
      final colon = decoded.indexOf(':');
      if (colon <= 0) {
        throw const UnsupportedConfigException('shadowsocks credentials are malformed');
      }
      method = decoded.substring(0, colon);
      password = decoded.substring(colon + 1);

      final split = _splitHostPort(address);
      host = split.$1;
      port = split.$2;
    } else {
      final decoded = _decodeBase64(body);
      if (decoded == null) {
        throw const UnsupportedConfigException('shadowsocks payload is not base64');
      }
      final at = decoded.lastIndexOf('@');
      if (at <= 0) {
        throw const UnsupportedConfigException('shadowsocks payload has no address');
      }
      final credentials = decoded.substring(0, at);
      final colon = credentials.indexOf(':');
      if (colon <= 0) {
        throw const UnsupportedConfigException('shadowsocks credentials are malformed');
      }
      method = credentials.substring(0, colon);
      password = credentials.substring(colon + 1);

      final split = _splitHostPort(decoded.substring(at + 1));
      host = split.$1;
      port = split.$2;
    }

    return {
      'type': 'shadowsocks',
      'tag': tag,
      'server': host,
      'server_port': port,
      'method': method,
      'password': password,
    };
  }

  static Map<String, dynamic> _hysteria2(String uri, String tag) {
    final parts = _Uri.parse(uri);
    final out = <String, dynamic>{
      'type': 'hysteria2',
      'tag': tag,
      'server': parts.host,
      'server_port': parts.port,
      'password': parts.userInfo,
    };

    final obfs = parts.query['obfs'];
    final obfsPassword = parts.query['obfs-password'];
    if (obfs != null && obfs.isNotEmpty) {
      out['obfs'] = {
        'type': obfs,
          'password': ?obfsPassword,
      };
    }

    // QUIC-based, so TLS is always present.
    out['tls'] = {
      'enabled': true,
      'server_name': parts.query['sni'] ?? parts.host,
      if (parts.query['insecure'] == '1') 'insecure': true,
    };

    return out;
  }

  static Map<String, dynamic> _tuic(String uri, String tag) {
    final parts = _Uri.parse(uri);
    final credentials = parts.userInfo.split(':');

    return {
      'type': 'tuic',
      'tag': tag,
      'server': parts.host,
      'server_port': parts.port,
      'uuid': credentials.first,
      if (credentials.length > 1) 'password': credentials.sublist(1).join(':'),
      if (parts.query['congestion_control'] != null)
        'congestion_control': parts.query['congestion_control'],
      'tls': {
        'enabled': true,
        'server_name': parts.query['sni'] ?? parts.host,
        if (parts.query['alpn'] != null) 'alpn': parts.query['alpn']!.split(','),
        if (parts.query['allow_insecure'] == '1') 'insecure': true,
      },
    };
  }

  static Map<String, dynamic> _socksUri(String uri, String tag) {
    final parts = _Uri.parse(uri);
    final credentials = parts.userInfo.isEmpty ? null : parts.userInfo.split(':');
    return {
      'type': 'socks',
      'tag': tag,
      'server': parts.host,
      'server_port': parts.port,
      'version': '5',
      if (credentials != null) 'username': credentials.first,
      if (credentials != null && credentials.length > 1)
        'password': credentials.sublist(1).join(':'),
    };
  }

  static Map<String, dynamic> _httpUri(String uri, String tag) {
    final parts = _Uri.parse(uri);
    final credentials = parts.userInfo.isEmpty ? null : parts.userInfo.split(':');
    return {
      'type': 'http',
      'tag': tag,
      'server': parts.host,
      'server_port': parts.port,
      if (uri.toLowerCase().startsWith('https')) 'tls': {'enabled': true},
      if (credentials != null) 'username': credentials.first,
      if (credentials != null && credentials.length > 1)
        'password': credentials.sublist(1).join(':'),
    };
  }

  /// A bare `ip:port` proxy discovered from a table.
  static Map<String, dynamic> _proxy(Endpoint endpoint, String tag) => switch (endpoint.protocol) {
        Protocol.http || Protocol.https => {
            'type': 'http',
            'tag': tag,
            'server': endpoint.host,
            'server_port': endpoint.port,
            if (endpoint.protocol == Protocol.https) 'tls': {'enabled': true},
          },
        _ => {
            'type': 'socks',
            'tag': tag,
            'server': endpoint.host,
            'server_port': endpoint.port,
            'version': '5',
          },
      };

  // --- Shared pieces ----------------------------------------------------------

  static Map<String, dynamic>? _tls(_Uri parts) {
    final security = (parts.query['security'] ?? '').toLowerCase();
    if (security != 'tls' && security != 'reality' && security != 'xtls') return null;

    final sni = parts.query['sni'] ?? parts.query['peer'] ?? parts.host;
    final tls = <String, dynamic>{'enabled': true, 'server_name': sni};

    final alpn = parts.query['alpn'];
    if (alpn != null && alpn.isNotEmpty) tls['alpn'] = alpn.split(',');

    if (parts.query['allowInsecure'] == '1' || parts.query['insecure'] == '1') {
      tls['insecure'] = true;
    }

    final fingerprint = parts.query['fp'];
    if (fingerprint != null && fingerprint.isNotEmpty) {
      tls['utls'] = {'enabled': true, 'fingerprint': fingerprint};
    }

    if (security == 'reality') {
      final publicKey = parts.query['pbk'];
      if (publicKey == null || publicKey.isEmpty) {
        throw const UnsupportedConfigException('reality without a public key');
      }
      tls['reality'] = {
        'enabled': true,
        'public_key': publicKey,
        if (parts.query['sid'] != null) 'short_id': parts.query['sid'],
      };
      // Reality needs a uTLS fingerprint; chrome is what most publishers assume.
      tls['utls'] ??= {'enabled': true, 'fingerprint': 'chrome'};
    }

    return tls;
  }

  static Map<String, dynamic>? _transport(_Uri parts) => _transportFrom(
        network: parts.query['type'] ?? 'tcp',
        path: parts.query['path'] ?? '',
        host: parts.query['host'] ?? '',
        serviceName: parts.query['serviceName'] ?? parts.query['path'] ?? '',
      );

  static Map<String, dynamic>? _transportFrom({
    required String network,
    required String path,
    required String host,
    required String serviceName,
  }) {
    switch (network.toLowerCase()) {
      case 'ws':
        return {
          'type': 'ws',
          if (path.isNotEmpty) 'path': path,
          if (host.isNotEmpty) 'headers': {'Host': host},
        };
      case 'grpc':
        return {
          'type': 'grpc',
          if (serviceName.isNotEmpty) 'service_name': serviceName.replaceFirst('/', ''),
        };
      case 'httpupgrade':
        return {
          'type': 'httpupgrade',
          if (path.isNotEmpty) 'path': path,
          if (host.isNotEmpty) 'host': host,
        };
      case 'http' || 'h2':
        return {
          'type': 'http',
          if (host.isNotEmpty) 'host': [host],
          if (path.isNotEmpty) 'path': path,
        };
      case 'quic':
        return {'type': 'quic'};
      // tcp and anything unrecognised: no transport block, which is sing-box's
      // plain TCP. Guessing here produces a config that fails to parse.
      default:
        return null;
    }
  }

  static (String, int) _splitHostPort(String address) {
    var value = address.split('?').first.split('#').first;
    if (value.startsWith('[')) {
      final close = value.indexOf(']');
      final host = value.substring(1, close);
      final port = int.tryParse(value.substring(close + 2));
      if (port == null) throw const UnsupportedConfigException('missing port');
      return (host, port);
    }
    final colon = value.lastIndexOf(':');
    if (colon <= 0) throw const UnsupportedConfigException('missing port');
    final port = int.tryParse(value.substring(colon + 1));
    if (port == null) throw const UnsupportedConfigException('missing port');
    return (value.substring(0, colon), port);
  }

  static String? _decodeBase64(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s'), '');
    if (cleaned.isEmpty) return null;
    final normalized = cleaned.replaceAll('-', '+').replaceAll('_', '/');
    final padded = normalized.padRight(
        normalized.length + (4 - normalized.length % 4) % 4, '=');
    try {
      return utf8.decode(base64.decode(padded), allowMalformed: false);
    } on Object {
      return null;
    }
  }
}

/// A config URI split into the parts the builders need.
///
/// Dart's own [Uri] is not used: these links routinely carry characters it
/// rejects, and a parse failure here would drop a working server.
class _Uri {
  const _Uri({
    required this.userInfo,
    required this.host,
    required this.port,
    required this.query,
  });

  final String userInfo;
  final String host;
  final int port;
  final Map<String, String> query;

  bool get hasTls {
    final security = (query['security'] ?? '').toLowerCase();
    return security == 'tls' || security == 'reality' || security == 'xtls';
  }

  static _Uri parse(String uri) {
    var rest = uri.substring(uri.indexOf('://') + 3);

    final hash = rest.indexOf('#');
    if (hash >= 0) rest = rest.substring(0, hash);

    final query = <String, String>{};
    final questionMark = rest.indexOf('?');
    if (questionMark >= 0) {
      for (final pair in rest.substring(questionMark + 1).split('&')) {
        if (pair.isEmpty) continue;
        final equals = pair.indexOf('=');
        if (equals <= 0) continue;
        final key = pair.substring(0, equals);
        final value = pair.substring(equals + 1);
        query[key] = _decodeComponent(value);
      }
      rest = rest.substring(0, questionMark);
    }

    final slash = rest.indexOf('/');
    if (slash >= 0) rest = rest.substring(0, slash);

    var userInfo = '';
    final at = rest.lastIndexOf('@');
    if (at >= 0) {
      userInfo = _decodeComponent(rest.substring(0, at));
      rest = rest.substring(at + 1);
    }

    final (host, port) = OutboundBuilder._splitHostPort(rest);
    return _Uri(userInfo: userInfo, host: host, port: port, query: query);
  }

  static String _decodeComponent(String value) {
    try {
      return Uri.decodeComponent(value);
    } on ArgumentError {
      return value;
    }
  }
}
