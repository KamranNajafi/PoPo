import 'dart:convert';

import '../discovery/models.dart';
import 'outbound_builder.dart';

/// How the tunnel should route and protect traffic.
class TunnelOptions {
  const TunnelOptions({
    this.killSwitch = true,
    this.dnsServer = 'https://1.1.1.1/dns-query',
    this.autoDetectInterface = true,
    this.mixedPort,
    this.shareListenAddress,
    this.sharePort,
    this.socksSharePort,
    this.shareUsername,
    this.sharePassword,
    this.splitTunnel = const SplitTunnel.disabled(),
    this.logLevel = 'warn',
  });

  /// When on, traffic that cannot go through the tunnel is dropped rather than
  /// leaking to the direct interface.
  final bool killSwitch;

  /// DNS-over-HTTPS endpoint. Plain DNS would be resolvable and blockable by
  /// the same network the tunnel exists to get past.
  final String dnsServer;

  final bool autoDetectInterface;

  /// A loopback SOCKS/HTTP port for the app's own use, when TUN is unavailable.
  final int? mixedPort;

  /// Connection sharing: the interface other devices reach, and its ports.
  final String? shareListenAddress;
  final int? sharePort;
  final int? socksSharePort;
  final String? shareUsername;
  final String? sharePassword;

  final SplitTunnel splitTunnel;
  final String logLevel;

  bool get sharingEnabled => shareListenAddress != null && sharePort != null;

  TunnelOptions copyWith({
    bool? killSwitch,
    String? dnsServer,
    int? mixedPort,
    String? shareListenAddress,
    int? sharePort,
    int? socksSharePort,
    String? shareUsername,
    String? sharePassword,
    SplitTunnel? splitTunnel,
    bool clearSharing = false,
  }) =>
      TunnelOptions(
        killSwitch: killSwitch ?? this.killSwitch,
        dnsServer: dnsServer ?? this.dnsServer,
        autoDetectInterface: autoDetectInterface,
        mixedPort: mixedPort ?? this.mixedPort,
        shareListenAddress:
            clearSharing ? null : (shareListenAddress ?? this.shareListenAddress),
        sharePort: clearSharing ? null : (sharePort ?? this.sharePort),
        socksSharePort: clearSharing ? null : (socksSharePort ?? this.socksSharePort),
        shareUsername: clearSharing ? null : (shareUsername ?? this.shareUsername),
        sharePassword: clearSharing ? null : (sharePassword ?? this.sharePassword),
        splitTunnel: splitTunnel ?? this.splitTunnel,
        logLevel: logLevel,
      );
}

/// Which apps bypass the tunnel. Android only — no other platform exposes
/// per-app routing.
class SplitTunnel {
  const SplitTunnel.disabled()
      : mode = SplitTunnelMode.off,
        packages = const [];

  /// Only the listed packages go through the tunnel.
  const SplitTunnel.include(this.packages) : mode = SplitTunnelMode.include;

  /// Everything goes through the tunnel except the listed packages.
  const SplitTunnel.exclude(this.packages) : mode = SplitTunnelMode.exclude;

  final SplitTunnelMode mode;
  final List<String> packages;

  bool get isActive => mode != SplitTunnelMode.off && packages.isNotEmpty;
}

enum SplitTunnelMode { off, include, exclude }

/// Builds the complete sing-box configuration the core runs.
///
/// The whole document is produced here rather than templated in the platform
/// layers, so Android, iOS and desktop cannot end up with subtly different
/// routing. Platform differences are expressed as arguments — the TUN inbound
/// is added by the caller that owns the file descriptor.
abstract final class TunnelConfig {
  /// A tunnel config for one endpoint.
  ///
  /// [tunFd] is supplied by the platform VPN service on Android and iOS; on
  /// desktop, sing-box opens the device itself, so it stays null.
  static Map<String, dynamic> build({
    required Endpoint endpoint,
    TunnelOptions options = const TunnelOptions(),
    bool platformManagedTun = false,
    bool includeTun = true,
  }) {
    final outbound = OutboundBuilder.fromEndpoint(endpoint);

    return {
      'log': {'level': options.logLevel, 'timestamp': true},
      'dns': _dns(options),
      'inbounds': _inbounds(options,
          platformManagedTun: platformManagedTun, includeTun: includeTun),
      'outbounds': [
        outbound,
        {'type': 'direct', 'tag': 'direct'},
      ],
      'route': _route(options),
    };
  }

  /// The same document as JSON text, which is what crosses into the core.
  static String buildJson({
    required Endpoint endpoint,
    TunnelOptions options = const TunnelOptions(),
    bool platformManagedTun = false,
    bool includeTun = true,
  }) =>
      jsonEncode(build(
        endpoint: endpoint,
        options: options,
        platformManagedTun: platformManagedTun,
        includeTun: includeTun,
      ));

  static Map<String, dynamic> _dns(TunnelOptions options) => {
        'servers': [
          {'type': 'https', 'tag': 'secure', 'server': _dnsHost(options.dnsServer)},
        ],
        // Queries must not leak to the local resolver, which is exactly what the
        // network operator controls.
        'strategy': 'prefer_ipv4',
        'independent_cache': true,
      };

  static String _dnsHost(String server) {
    final parsed = Uri.tryParse(server);
    return parsed?.host.isNotEmpty == true ? parsed!.host : server;
  }

  static List<Map<String, dynamic>> _inbounds(
    TunnelOptions options, {
    required bool platformManagedTun,
    required bool includeTun,
  }) {
    final inbounds = <Map<String, dynamic>>[];

    if (includeTun) {
      // No file descriptor here: sing-box adopts a platform-opened device
      // through its platform interface, and a `file_descriptor` key makes the
      // whole document fail to parse. The core takes the fd as an argument
      // instead — see Tunnel.StartWithTun.
      inbounds.add({
        'type': 'tun',
        'tag': 'tun-in',
        'address': ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
        'mtu': 9000,
        // When the platform owns the device it also owns routing; claiming
        // auto_route on top of that fights it.
        'auto_route': !platformManagedTun,
        'strict_route': !platformManagedTun,
        'stack': 'mixed',
      });
    }

    // A loopback listener for the app's own traffic when there is no TUN.
    if (options.mixedPort != null) {
      inbounds.add({
        'type': 'mixed',
        'tag': 'mixed-in',
        'listen': '127.0.0.1',
        'listen_port': options.mixedPort,
      });
    }

    // Connection sharing: other devices on the hotspot point their proxy
    // settings at these. Bound to the hotspot address specifically — binding to
    // 0.0.0.0 would also expose it on whatever else the device is attached to.
    if (options.sharingEnabled) {
      final users = options.shareUsername == null
          ? null
          : [
              {
                'username': options.shareUsername,
                'password': options.sharePassword ?? '',
              }
            ];

      inbounds.add({
        'type': 'http',
        'tag': 'share-http',
        'listen': options.shareListenAddress,
        'listen_port': options.sharePort,
        'users': ?users,
      });

      if (options.socksSharePort != null) {
        inbounds.add({
          'type': 'socks',
          'tag': 'share-socks',
          'listen': options.shareListenAddress,
          'listen_port': options.socksSharePort,
          'users': ?users,
        });
      }
    }

    return inbounds;
  }

  static Map<String, dynamic> _route(TunnelOptions options) {
    final rules = <Map<String, dynamic>>[
      // DNS has to be intercepted before anything else, or queries escape the
      // tunnel and the operator sees every hostname.
      {'protocol': 'dns', 'action': 'hijack-dns'},
    ];

    final split = options.splitTunnel;
    if (split.isActive) {
      switch (split.mode) {
        case SplitTunnelMode.exclude:
          rules.add({
            'package_name': split.packages,
            'outbound': 'direct',
          });
        case SplitTunnelMode.include:
          // Everything not listed goes direct; the listed packages fall through
          // to the proxy as the final outbound.
          rules.add({
            'package_name': split.packages,
            'outbound': 'proxy',
          });
          rules.add({
            'inbound': ['tun-in'],
            'invert': true,
            'outbound': 'direct',
          });
        case SplitTunnelMode.off:
          break;
      }
    }

    return {
      'rules': rules,
      // With the kill switch on, anything unmatched goes to the proxy and fails
      // closed when the proxy is down. With it off, unmatched traffic can fall
      // back to the direct interface.
      'final': options.killSwitch ? 'proxy' : 'direct',
      'auto_detect_interface': options.autoDetectInterface,
    };
  }

  /// The config for connection sharing without a tunnel of its own — used when
  /// the phone shares an already-established connection.
  static Map<String, dynamic> shareOnly({
    required String listenAddress,
    required int httpPort,
    int? socksPort,
    String? username,
    String? password,
    required Endpoint upstream,
  }) =>
      build(
        endpoint: upstream,
        includeTun: false,
        options: TunnelOptions(
          shareListenAddress: listenAddress,
          sharePort: httpPort,
          socksSharePort: socksPort,
          shareUsername: username,
          sharePassword: password,
          killSwitch: true,
        ),
      );
}
