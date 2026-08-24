import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/discovery/models.dart';
import 'package:popo/core/tunnel/outbound_builder.dart';
import 'package:popo/core/tunnel/tunnel_config.dart';

Endpoint config(String raw, {String host = 'example.com', int port = 443}) => Endpoint(
      raw: raw,
      kind: EndpointKind.config,
      protocol: Protocol.vless,
      host: host,
      port: port,
      fingerprint: 'f|$host|$port|u',
    );

/// Configs the Go suite re-validates against the real sing-box parser.
final _corpus = <String, Map<String, dynamic>>{};

void keep(String name, Map<String, dynamic> document) => _corpus[name] = document;

void main() {
  group('OutboundBuilder', () {
    test('vless with reality', () {
      final out = OutboundBuilder.fromUri(
        'vless://uuid-1@1.2.3.4:443?encryption=none&security=reality'
        '&sni=www.microsoft.com&fp=chrome&pbk=PUBKEY&sid=ab&type=tcp'
        '&flow=xtls-rprx-vision#NL',
      );

      expect(out['type'], 'vless');
      expect(out['server'], '1.2.3.4');
      expect(out['server_port'], 443);
      expect(out['uuid'], 'uuid-1');
      expect(out['flow'], 'xtls-rprx-vision');
      expect(out['tls']['reality']['public_key'], 'PUBKEY');
      expect(out['tls']['reality']['short_id'], 'ab');
      expect(out['tls']['utls']['fingerprint'], 'chrome');
      expect(out.containsKey('transport'), isFalse, reason: 'tcp needs no transport');
    });

    test('reality without a public key is rejected rather than half-built', () {
      expect(
        () => OutboundBuilder.fromUri('vless://u@1.2.3.4:443?security=reality'),
        throwsA(isA<UnsupportedConfigException>()),
      );
    });

    test('vision flow is dropped when there is no TLS', () {
      final out = OutboundBuilder.fromUri(
          'vless://u@1.2.3.4:443?flow=xtls-rprx-vision&type=tcp');

      expect(out.containsKey('flow'), isFalse,
          reason: 'sing-box rejects vision without TLS');
    });

    test('vless over websocket', () {
      final out = OutboundBuilder.fromUri(
        'vless://u@1.2.3.4:443?security=tls&type=ws&path=%2Fws&host=cdn.example.com',
      );

      expect(out['transport']['type'], 'ws');
      expect(out['transport']['path'], '/ws');
      expect(out['transport']['headers']['Host'], 'cdn.example.com');
    });

    test('vless over grpc strips the leading slash from the service name', () {
      final out = OutboundBuilder.fromUri(
          'vless://u@1.2.3.4:443?security=tls&type=grpc&serviceName=%2Fgun');

      expect(out['transport']['type'], 'grpc');
      expect(out['transport']['service_name'], 'gun');
    });

    test('vmess decodes its base64 payload', () {
      final payload = base64.encode(utf8.encode(jsonEncode({
        'v': '2',
        'ps': 'DE',
        'add': '5.6.7.8',
        'port': '8443',
        'id': 'vmess-uuid',
        'aid': '0',
        'net': 'ws',
        'path': '/p',
        'host': 'h.example.com',
        'tls': 'tls',
        'sni': 'sni.example.com',
      })));

      final out = OutboundBuilder.fromUri('vmess://$payload#DE');

      expect(out['type'], 'vmess');
      expect(out['server'], '5.6.7.8');
      expect(out['server_port'], 8443);
      expect(out['uuid'], 'vmess-uuid');
      expect(out['tls']['server_name'], 'sni.example.com');
      expect(out['transport']['type'], 'ws');
    });

    test('an unknown vmess cipher falls back to auto rather than failing', () {
      final payload = base64.encode(utf8.encode(jsonEncode({
        'add': '5.6.7.8',
        'port': '443',
        'id': 'u',
        'scy': 'something-new',
      })));

      expect(OutboundBuilder.fromUri('vmess://$payload')['security'], 'auto');
    });

    test('trojan defaults to TLS even when the parameter is missing', () {
      final out = OutboundBuilder.fromUri('trojan://pass@9.9.9.9:443#X');

      expect(out['type'], 'trojan');
      expect(out['password'], 'pass');
      expect(out['tls']['enabled'], isTrue);
    });

    test('shadowsocks in both encodings', () {
      final userInfo = base64.encode(utf8.encode('aes-256-gcm:secret'));
      final a = OutboundBuilder.fromUri('ss://$userInfo@1.1.1.1:8388#A');

      final whole = base64.encode(utf8.encode('aes-256-gcm:secret@1.1.1.1:8388'));
      final b = OutboundBuilder.fromUri('ss://$whole#B');

      for (final out in [a, b]) {
        expect(out['type'], 'shadowsocks');
        expect(out['method'], 'aes-256-gcm');
        expect(out['password'], 'secret');
        expect(out['server'], '1.1.1.1');
        expect(out['server_port'], 8388);
      }
    });

    test('hysteria2 with obfs', () {
      final out = OutboundBuilder.fromUri(
          'hysteria2://pw@2.2.2.2:36712?obfs=salamander&obfs-password=x&sni=s.example#FI');

      expect(out['type'], 'hysteria2');
      expect(out['obfs']['type'], 'salamander');
      expect(out['obfs']['password'], 'x');
      expect(out['tls']['server_name'], 's.example');
    });

    test('tuic splits uuid and password', () {
      final out = OutboundBuilder.fromUri('tuic://uuid-2:pw@3.3.3.3:443?sni=t.example#T');

      expect(out['type'], 'tuic');
      expect(out['uuid'], 'uuid-2');
      expect(out['password'], 'pw');
    });

    test('a discovered bare proxy becomes a socks outbound', () {
      const proxy = Endpoint(
        raw: '51.15.42.7:1080',
        kind: EndpointKind.proxy,
        protocol: Protocol.socks5,
        host: '51.15.42.7',
        port: 1080,
        fingerprint: 'proxy|51.15.42.7|1080',
      );

      final out = OutboundBuilder.fromEndpoint(proxy);
      expect(out['type'], 'socks');
      expect(out['version'], '5');
    });

    test('an unknown scheme is refused', () {
      expect(() => OutboundBuilder.fromUri('wireguard://x@1.2.3.4:51820'),
          throwsA(isA<UnsupportedConfigException>()));
    });

    test('IPv6 literals keep their address', () {
      final out = OutboundBuilder.fromUri('vless://u@[2001:db8::1]:443?security=tls');
      expect(out['server'], '2001:db8::1');
      expect(out['server_port'], 443);
    });
  });

  group('TunnelConfig', () {
    final endpoint = config(
        'vless://u@1.2.3.4:443?security=reality&pbk=K&sni=a.example&fp=chrome&type=tcp');

    test('kill switch sends unmatched traffic to the proxy', () {
      final document = TunnelConfig.build(endpoint: endpoint);
      keep('killswitch_on', document);

      expect(document['route']['final'], 'proxy');
    });

    test('kill switch off allows a direct fallback', () {
      final document = TunnelConfig.build(
        endpoint: endpoint,
        options: const TunnelOptions(killSwitch: false),
      );
      keep('killswitch_off', document);

      expect(document['route']['final'], 'direct');
    });

    test('DNS is hijacked before any other rule', () {
      final document = TunnelConfig.build(endpoint: endpoint);
      final rules = document['route']['rules'] as List;

      expect(rules.first['protocol'], 'dns',
          reason: 'unintercepted DNS leaks every hostname to the operator');
    });

    test('a platform-managed TUN turns off auto route', () {
      final document =
          TunnelConfig.build(endpoint: endpoint, platformManagedTun: true);
      keep('tun_platform', document);

      final tun = (document['inbounds'] as List).first;
      expect(tun.containsKey('file_descriptor'), isFalse,
          reason: 'sing-box takes the descriptor through its platform '
              'interface; the key makes the document fail to parse');
      expect(tun['auto_route'], isFalse,
          reason: 'the platform already owns routing when it owns the device');
    });

    test('desktop opens the device itself', () {
      final document = TunnelConfig.build(endpoint: endpoint);
      final tun = (document['inbounds'] as List).first;

      expect(tun.containsKey('file_descriptor'), isFalse);
      expect(tun['auto_route'], isTrue);
    });

    test('sharing binds to the hotspot address, not to everything', () {
      final document = TunnelConfig.build(
        endpoint: endpoint,
        options: const TunnelOptions(
          shareListenAddress: '192.168.43.1',
          sharePort: 8888,
          socksSharePort: 1080,
          shareUsername: 'popo',
          sharePassword: 'secret',
        ),
      );
      keep('sharing', document);

      final inbounds = (document['inbounds'] as List).cast<Map<String, dynamic>>();
      final http = inbounds.firstWhere((i) => i['tag'] == 'share-http');
      final socks = inbounds.firstWhere((i) => i['tag'] == 'share-socks');

      expect(http['listen'], '192.168.43.1');
      expect(http['listen_port'], 8888);
      expect(socks['listen_port'], 1080);
      expect(http['users'].first['username'], 'popo');
      expect(inbounds.any((i) => i['listen'] == '0.0.0.0'), isFalse,
          reason: 'binding to every interface exposes the proxy beyond the hotspot');
    });

    test('split tunnel exclude routes the named packages direct', () {
      final document = TunnelConfig.build(
        endpoint: endpoint,
        options: const TunnelOptions(
          splitTunnel: SplitTunnel.exclude(['com.bank.app']),
        ),
      );
      keep('split_exclude', document);

      final rules = (document['route']['rules'] as List).cast<Map<String, dynamic>>();
      final rule = rules.firstWhere((r) => r.containsKey('package_name'));
      expect(rule['package_name'], ['com.bank.app']);
      expect(rule['outbound'], 'direct');
    });

    test('split tunnel include sends only the named packages through', () {
      final document = TunnelConfig.build(
        endpoint: endpoint,
        options: const TunnelOptions(
          splitTunnel: SplitTunnel.include(['com.browser']),
        ),
      );
      keep('split_include', document);

      final rules = (document['route']['rules'] as List).cast<Map<String, dynamic>>();
      expect(rules.any((r) => r['package_name'] != null && r['outbound'] == 'proxy'),
          isTrue);
    });

    test('an empty package list leaves routing alone', () {
      final document = TunnelConfig.build(
        endpoint: endpoint,
        options: const TunnelOptions(splitTunnel: SplitTunnel.exclude([])),
      );

      final rules = (document['route']['rules'] as List).cast<Map<String, dynamic>>();
      expect(rules.any((r) => r.containsKey('package_name')), isFalse);
    });

    test('a loopback listener is added when asked for', () {
      final document = TunnelConfig.build(
        endpoint: endpoint,
        includeTun: false,
        options: const TunnelOptions(mixedPort: 2080),
      );
      keep('mixed_only', document);

      final inbounds = (document['inbounds'] as List).cast<Map<String, dynamic>>();
      expect(inbounds.single['type'], 'mixed');
      expect(inbounds.single['listen'], '127.0.0.1');
    });

    test('buildJson round-trips', () {
      final json = TunnelConfig.buildJson(endpoint: endpoint);
      expect(jsonDecode(json)['route']['final'], 'proxy');
    });
  });

  group('every protocol produces a document', () {
    final links = {
      'vless_reality':
          'vless://u@1.2.3.4:443?security=reality&pbk=K&sid=ab&fp=chrome&sni=a.example&type=tcp',
      'vless_ws':
          'vless://u@1.2.3.4:443?security=tls&type=ws&path=%2Fws&host=h.example&sni=h.example',
      'vless_grpc':
          'vless://u@1.2.3.4:443?security=tls&type=grpc&serviceName=gun&sni=h.example',
      'trojan': 'trojan://pw@1.2.3.4:443?security=tls&sni=t.example',
      'shadowsocks':
          'ss://${base64.encode(utf8.encode('aes-256-gcm:secret'))}@1.2.3.4:8388',
      'hysteria2': 'hysteria2://pw@1.2.3.4:36712?sni=h.example',
      'tuic': 'tuic://uuid:pw@1.2.3.4:443?sni=t.example',
      'vmess': 'vmess://${base64.encode(utf8.encode(jsonEncode({
            'add': '1.2.3.4',
            'port': '443',
            'id': 'vmess-uuid',
            'aid': '0',
            'net': 'ws',
            'path': '/p',
            'tls': 'tls',
            'sni': 's.example',
          })))}',
    };

    for (final MapEntry(key: name, value: link) in links.entries) {
      test(name, () {
        final document = TunnelConfig.build(endpoint: config(link));
        keep(name, document);

        expect(document['outbounds'], isNotEmpty);
        expect((document['outbounds'] as List).first['tag'], 'proxy');
      });
    }
  });

  tearDownAll(() {
    // Hand the generated documents to the Go suite, which parses each one with
    // the real sing-box. Dart alone can only prove the shape it intended, not
    // that the core accepts it.
    final directory = Directory('build/tunnel_corpus');
    directory.createSync(recursive: true);
    for (final MapEntry(key: name, value: document) in _corpus.entries) {
      File('${directory.path}/$name.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(document));
    }
  });
}
