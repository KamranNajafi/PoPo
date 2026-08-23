import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/discovery/engines.dart';
import 'package:popo/core/discovery/extract.dart';
import 'package:popo/core/discovery/fetcher.dart';
import 'package:popo/core/discovery/keywords.dart';
import 'package:popo/core/discovery/models.dart';
import 'package:popo/core/discovery/pipeline.dart';

/// Serves canned pages so the pipeline can be exercised without a network.
class FakeFetcher implements Fetcher {
  FakeFetcher(this.pages, {this.failFor = const {}, this.blockFor = const {}});

  final Map<String, String> pages;
  final Set<String> failFor;

  /// Host substring -> body that the engine should read as a block.
  final Map<String, String> blockFor;

  final List<String> requested = [];

  @override
  Future<FetchResult> get(String url, {Map<String, String> headers = const {}}) async {
    requested.add(url);
    for (final f in failFor) {
      if (url.contains(f)) throw const FetchException('boom');
    }
    for (final MapEntry(key: host, value: body) in blockFor.entries) {
      if (url.contains(host)) return FetchResult(statusCode: 200, body: body);
    }
    for (final MapEntry(key: pattern, value: body) in pages.entries) {
      if (url.contains(pattern)) return FetchResult(statusCode: 200, body: body);
    }
    return const FetchResult(statusCode: 404, body: '');
  }
}

String vmessUri(String host, int port, String id) {
  final json = jsonEncode({'add': host, 'port': '$port', 'id': id, 'net': 'ws'});
  return 'vmess://${base64.encode(utf8.encode(json))}';
}

void main() {
  group('KeywordGenerator', () {
    test('generates a bounded, deduplicated, sorted set', () {
      final keywords = const KeywordGenerator().generate(limit: 30);

      expect(keywords, hasLength(30));
      expect(keywords.map((k) => k.text).toSet(), hasLength(30),
          reason: 'phrases must be unique');

      for (var i = 1; i < keywords.length; i++) {
        expect(keywords[i - 1].weight, greaterThanOrEqualTo(keywords[i].weight),
            reason: 'best phrases must come first, the budget is spent in order');
      }
    });

    test('stamps the current month and year so stale lists rank lower', () {
      final keywords =
          KeywordGenerator(now: DateTime(2026, 3, 14)).generate(limit: 200);
      final texts = keywords.map((k) => k.text).toList();

      expect(texts, contains('vless config march 2026'));
      expect(texts.any((t) => t.contains('2026')), isTrue);
    });

    test('covers Persian vocabulary, and can be turned off', () {
      final withFa = const KeywordGenerator().generate(limit: 200);
      expect(withFa.any((k) => k.tags.contains('persian')), isTrue);

      final withoutFa =
          const KeywordGenerator(includePersian: false).generate(limit: 200);
      expect(withoutFa.any((k) => k.tags.contains('persian')), isFalse);
    });

    test('site-scoped phrases outrank bare ones', () {
      final keywords = const KeywordGenerator().generate(limit: 1000);
      final site = keywords.firstWhere((k) => k.tags.contains('site'));
      final bare = keywords.firstWhere((k) => k.text == 'v2ray config');

      expect(site.weight, greaterThan(bare.weight));
    });

    test('generator is deterministic for a fixed clock', () {
      final a = KeywordGenerator(now: DateTime(2026, 5)).generate();
      final b = KeywordGenerator(now: DateTime(2026, 5)).generate();
      expect(a.map((k) => k.text), b.map((k) => k.text));
    });
  });

  group('Extractor', () {
    const extractor = Extractor();

    test('pulls every config scheme out of page noise', () {
      const page = '''
        <p>here are todays configs</p>
        vless://uuid-1@1.2.3.4:443?security=reality&sni=x.com#NL-1
        trojan://pass@5.6.7.8:8443#DE
        ss://YWVzOnBhc3N3b3Jk@9.9.9.9:8388#SG
        hysteria2://pw@11.12.13.14:36712#FI
        <a href="https://example.com/page">unrelated</a>
      ''';

      final found = extractor.extract(page, source: 'https://blog.example/list');
      final protocols = found.map((e) => e.protocol).toSet();

      expect(protocols, containsAll([
        Protocol.vless,
        Protocol.trojan,
        Protocol.shadowsocks,
        Protocol.hysteria2,
      ]));
      expect(found.every((e) => e.kind == EndpointKind.config), isTrue);
      expect(found.every((e) => e.sources.contains('https://blog.example/list')), isTrue);
    });

    test('decodes a vmess payload into host and port', () {
      final found = extractor.extract(vmessUri('example.net', 8443, 'abc-123'),
          source: 's');

      expect(found, hasLength(1));
      expect(found.single.protocol, Protocol.vmess);
      expect(found.single.host, 'example.net');
      expect(found.single.port, 8443);
    });

    test('decodes a base64 subscription blob, which is how subs are served', () {
      final payload = base64.encode(utf8.encode([
        'vless://u1@10.0.0.1:443?security=reality#A',
        'trojan://p@10.0.0.2:443#B',
      ].join('\n')));

      final found = extractor.extract('key: $payload', source: 's');

      expect(found, hasLength(2));
      expect(found.map((e) => e.host), containsAll(['10.0.0.1', '10.0.0.2']));
    });

    test('collapses the same server republished under different names', () {
      const page = '''
        vless://uuid-1@1.2.3.4:443?security=reality#Free-Fast-NL
        vless://uuid-1@1.2.3.4:443?security=reality#@some_channel
        vless://uuid-1@1.2.3.4:443?security=reality#%F0%9F%9A%80TURBO
      ''';

      final found = extractor.extract(page, source: 's');

      expect(found, hasLength(1),
          reason: 'the display name is the one part publishers always change');
    });

    test('keeps two accounts on one server apart', () {
      const page = '''
        vless://uuid-1@1.2.3.4:443#A
        vless://uuid-2@1.2.3.4:443#B
      ''';
      expect(extractor.extract(page, source: 's'), hasLength(2));
    });

    test('finds proxy tables, with and without a protocol column', () {
      const page = '''
        <tr><td>SOCKS5</td><td>51.15.42.7:1080</td></tr>
        <tr><td>HTTPS</td><td>185.244.10.9 : 8080</td></tr>
        <tr><td>203.0.113.9:3128</td></tr>
      ''';

      final found = extractor.extract(page, source: 's');
      expect(found.where((e) => e.kind == EndpointKind.proxy), hasLength(3));
    });

    test('rejects version strings, dates and loopback that look like addresses', () {
      const page = 'version 1.2.3.4:5 released, see 127.0.0.1:8080 and 999.1.1.1:80';

      final proxies = extractor
          .extract(page, source: 's')
          .where((e) => e.kind == EndpointKind.proxy);

      expect(proxies.any((e) => e.host == '127.0.0.1'), isFalse);
      expect(proxies.any((e) => e.host == '999.1.1.1'), isFalse);
    });

    test('ignores an unparseable link instead of emitting a broken endpoint', () {
      final found = extractor.extract('vless://@:99999 and vless://nohost', source: 's');
      expect(found, isEmpty);
    });

    test('strips trailing punctuation from a link at the end of a sentence', () {
      final found =
          extractor.extract('use vless://u@1.2.3.4:443?a=b#Name, then connect.', source: 's');
      expect(found.single.port, 443);
      expect(found.single.raw.endsWith(','), isFalse);
    });
  });

  group('SearchEngine', () {
    test('unwraps the DuckDuckGo redirector', () {
      final ddg = engineById('duckduckgo')!;
      const html = '<a href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fgithub.com%2Fa%2Fb">x</a>';

      expect(ddg.parseLinks(html), contains('https://github.com/a/b'));
    });

    test('drops the engine chrome from results', () {
      final ddg = engineById('duckduckgo')!;
      const html = '''
        <a href="https://duckduckgo.com/settings">settings</a>
        <a href="https://gist.github.com/x">real</a>
      ''';

      expect(ddg.parseLinks(html), ['https://gist.github.com/x']);
    });

    test('tells a block apart from an empty result set', () {
      final yandex = engineById('yandex')!;

      expect(yandex.classify(200, 'showcaptcha please'), EngineStatus.captcha);
      expect(yandex.classify(429, ''), EngineStatus.blocked);
      expect(yandex.classify(503, ''), EngineStatus.failed);
      expect(yandex.classify(200, '<html>no results</html>'), EngineStatus.done);
    });

    test('every engine builds a URL that encodes the phrase', () {
      for (final engine in kEngines) {
        final url = engine.buildUrl('free v2ray config site:github.com');
        expect(url, isNot(contains(' ')), reason: '${engine.id} left a raw space');
        expect(url, startsWith('https://'));
      }
    });
  });

  group('DiscoveryPipeline', () {
    const serp = '<a href="https://gist.github.com/list1">a</a>'
        '<a href="https://raw.githubusercontent.com/u/r/list2">b</a>';

    test('searches, follows links, extracts and dedups across sources', () async {
      final fetcher = FakeFetcher({
        'duckduckgo.com': serp,
        'gist.github.com/list1': 'vless://u1@1.2.3.4:443?security=reality#A',
        'raw.githubusercontent.com': 'vless://u1@1.2.3.4:443?security=reality#B',
      });

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('duckduckgo')!],
        config: const DiscoveryConfig(queriesPerEngine: 1),
      );

      final results = await pipeline.run();

      expect(results, hasLength(1), reason: 'both pages carry the same server');
      expect(results.single.sources, hasLength(2),
          reason: 'corroboration from both pages must be recorded');
    });

    test('stops querying an engine once it is blocked', () async {
      final fetcher = FakeFetcher(
        {'gist.github.com': 'vless://u@1.2.3.4:443#A'},
        blockFor: {'yandex.com': 'showcaptcha'},
      );

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('yandex')!],
        config: const DiscoveryConfig(queriesPerEngine: 5),
      );

      await pipeline.run();

      final yandexCalls =
          fetcher.requested.where((u) => u.contains('yandex.com')).length;
      expect(yandexCalls, 1,
          reason: 'retrying a rate-limit is what turns it into a ban');
    });

    test('a failing engine does not take the run down with it', () async {
      final fetcher = FakeFetcher(
        {
          'duckduckgo.com': serp,
          'gist.github.com': 'vless://u@1.2.3.4:443?security=reality#A',
        },
        failFor: {'google.com'},
      );

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('google')!, engineById('duckduckgo')!],
        config: const DiscoveryConfig(queriesPerEngine: 1),
      );

      final results = await pipeline.run();
      expect(results, isNotEmpty);
    });

    test('never fetches the same page twice, however many engines find it', () async {
      final fetcher = FakeFetcher({
        'duckduckgo.com': serp,
        'bing.com': serp,
        'gist.github.com/list1': 'vless://u@1.2.3.4:443#A',
        'raw.githubusercontent.com': 'trojan://p@5.6.7.8:443#B',
      });

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('duckduckgo')!, engineById('bing')!],
        config: const DiscoveryConfig(queriesPerEngine: 2),
      );

      await pipeline.run();

      final listFetches =
          fetcher.requested.where((u) => u.contains('gist.github.com/list1')).length;
      expect(listFetches, 1);
    });

    test('honours the global page ceiling', () async {
      final many = List.generate(
        40,
        (i) => '<a href="https://example.com/page$i">p</a>',
      ).join();

      final fetcher = FakeFetcher({
        'duckduckgo.com': many,
        'example.com': 'vless://u@1.2.3.4:443#A',
      });

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('duckduckgo')!],
        config: const DiscoveryConfig(
          queriesPerEngine: 4,
          pagesPerQuery: 20,
          maxPagesTotal: 5,
        ),
      );

      await pipeline.run();

      final pageFetches =
          fetcher.requested.where((u) => u.contains('example.com/page')).length;
      expect(pageFetches, lessThanOrEqualTo(5));
    });

    test('skips links that never carry configs before spending a fetch', () async {
      final fetcher = FakeFetcher({
        'duckduckgo.com': '<a href="https://youtube.com/watch?v=1">v</a>'
            '<a href="https://example.com/a.png">i</a>'
            '<a href="https://gist.github.com/ok">g</a>',
        'gist.github.com/ok': 'vless://u@1.2.3.4:443#A',
      });

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('duckduckgo')!],
        config: const DiscoveryConfig(queriesPerEngine: 1),
      );

      await pipeline.run();

      expect(fetcher.requested.any((u) => u.contains('youtube')), isFalse);
      expect(fetcher.requested.any((u) => u.endsWith('.png')), isFalse);
    });

    test('ranks corroborated Reality endpoints above lone bare ones', () async {
      final fetcher = FakeFetcher({
        'duckduckgo.com': serp,
        'gist.github.com/list1':
            'vless://u1@1.2.3.4:443?security=reality#Good\nvmess://bad',
        'raw.githubusercontent.com':
            'vless://u1@1.2.3.4:443?security=reality#Good2\n'
                'shadowsocksy\nss://YWVz@9.9.9.9:8388#Lone',
      });

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('duckduckgo')!],
        config: const DiscoveryConfig(queriesPerEngine: 1),
      );

      final results = await pipeline.run();

      expect(results.first.protocol, Protocol.vless);
      expect(results.first.sources, hasLength(2));
      expect(results.first.score, greaterThan(results.last.score));
    });

    test('reports per-engine progress for the scanning screen', () async {
      final fetcher = FakeFetcher({
        'duckduckgo.com': serp,
        'gist.github.com': 'vless://u@1.2.3.4:443?security=reality#A',
      });

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('duckduckgo')!],
        config: const DiscoveryConfig(queriesPerEngine: 1),
      );

      final seen = <DiscoveryProgress>[];
      pipeline.progress.listen(seen.add);
      await pipeline.run();

      expect(seen, isNotEmpty);
      expect(seen.last.engines['duckduckgo']!.status, EngineStatus.done);
      expect(seen.last.found, greaterThan(0));
    });

    test('drops site: phrases for engines that do not support the operator', () async {
      final fetcher = FakeFetcher({'baidu.com': '<html></html>'});

      final pipeline = DiscoveryPipeline(
        fetcher: fetcher,
        engines: [engineById('baidu')!],
        config: const DiscoveryConfig(queriesPerEngine: 6),
      );

      await pipeline.run();

      expect(fetcher.requested.any((u) => u.contains('site%3A')), isFalse);
      expect(fetcher.requested, isNotEmpty);
    });
  });
}
