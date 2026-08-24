import 'package:flutter/widgets.dart';

import '../../core/discovery/models.dart';
import '../../core/theme/tokens.dart';

/// The design's ping colour bands: ≤100ms healthy, ≤180ms warning, above that
/// danger, and a dead endpoint shows an em dash rather than a number.
Color pingColorOf(Endpoint endpoint) {
  final ping = endpoint.ping;
  if (ping == null) return endpoint.health == Health.dead ? C.danger : C.muted;
  final ms = ping.inMilliseconds;
  if (ms <= 100) return C.success;
  if (ms <= 180) return C.warning;
  return C.danger;
}

/// Always LTR and Latin: this is a technical value, not prose.
String pingLabel(Endpoint endpoint) {
  final ping = endpoint.ping;
  if (ping != null) return '${ping.inMilliseconds} ms';
  return endpoint.health == Health.dead ? '—' : '· · ·';
}

/// `VLESS · TCP` style subtitle for a config, `SOCKS5 · 1.2.3.4:1080` for a proxy.
String protocolLine(Endpoint endpoint) {
  final protocol = endpoint.protocol.name.toUpperCase();
  return endpoint.kind == EndpointKind.proxy
      ? '$protocol · ${endpoint.host}:${endpoint.port}'
      : '$protocol · ${endpoint.host}:${endpoint.port}';
}

/// How long ago the endpoint was tested, in the compact form the cards use.
String testedAgo(Endpoint endpoint, DateTime now) {
  final at = endpoint.lastTestedAt;
  if (at == null) return '';
  final delta = now.difference(at);
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
  if (delta.inHours < 24) return '${delta.inHours} h ago';
  return '${delta.inDays} d ago';
}
