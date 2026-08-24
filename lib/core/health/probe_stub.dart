import 'probe.dart';

/// Web has no raw sockets, so probing is reported as unsupported rather than as
/// failure — calling every server dead would be worse than saying nothing.
class UnsupportedProbe implements LatencyProbe {
  const UnsupportedProbe();

  @override
  Future<ProbeResult> probe(
    String host,
    int port, {
    required Duration timeout,
  }) async => const ProbeResult.unsupported();
}

LatencyProbe createProbe() => const UnsupportedProbe();
