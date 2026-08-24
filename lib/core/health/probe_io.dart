import 'dart:io';

import 'probe.dart';

/// Latency as the time to complete a TCP handshake.
///
/// A connect is the right measurement here: it proves something is listening and
/// costs one round trip, whereas a full protocol handshake would need the tunnel
/// engine and a config the app cannot yet parse. It is a liveness and latency
/// signal, not proof the proxy actually forwards traffic — that only the tunnel
/// can establish.
class TcpProbe implements LatencyProbe {
  const TcpProbe();

  @override
  Future<ProbeResult> probe(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      stopwatch.stop();
      return ProbeResult.reachable(stopwatch.elapsed);
    } on SocketException catch (e) {
      return ProbeResult.unreachable(e.osError?.message ?? e.message);
    } on Object catch (e) {
      return ProbeResult.unreachable('$e');
    } finally {
      // destroy() rather than close(): close() waits for the peer, and a probe
      // has no reason to wait for anything after the handshake.
      socket?.destroy();
    }
  }
}

LatencyProbe createProbe() => const TcpProbe();
