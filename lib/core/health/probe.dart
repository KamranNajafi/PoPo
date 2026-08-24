import 'probe_stub.dart' if (dart.library.io) 'probe_io.dart';

/// What one latency probe found.
class ProbeResult {
  const ProbeResult.reachable(this.latency)
      : reason = null,
        supported = true;

  const ProbeResult.unreachable(this.reason)
      : latency = null,
        supported = true;

  /// The platform cannot open raw sockets — the web build. Distinguished from a
  /// failure so the UI never reports a healthy server as dead.
  const ProbeResult.unsupported()
      : latency = null,
        reason = 'sockets unavailable on this platform',
        supported = false;

  final Duration? latency;
  final String? reason;
  final bool supported;

  bool get reachable => latency != null;
}

/// Measures how long it takes to reach an endpoint.
abstract interface class LatencyProbe {
  Future<ProbeResult> probe(String host, int port, {required Duration timeout});
}

/// The probe for the current platform: a real TCP connect on device and
/// desktop, an "unsupported" stub on web.
LatencyProbe defaultProbe() => createProbe();
