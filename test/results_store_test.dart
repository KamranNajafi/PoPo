import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/discovery/models.dart';
import 'package:popo/core/util/prefs.dart';
import 'package:popo/features/results/results_store.dart';

Endpoint endpoint(
  String host, {
  EndpointKind kind = EndpointKind.config,
  Protocol protocol = Protocol.vless,
  Duration? ping,
  Health health = Health.untested,
  double score = 1,
}) => Endpoint(
  raw: '${protocol.name}://u@$host:443',
  kind: kind,
  protocol: protocol,
  host: host,
  port: 443,
  fingerprint: '${protocol.name}|$host|443|u',
  ping: ping,
  health: health,
  score: score,
);

void main() {
  late MemoryPrefs prefs;
  late ResultsStore store;

  setUp(() {
    prefs = MemoryPrefs();
    store = ResultsStore(prefs: prefs);
  });

  test('holds the latest run and counts each kind', () {
    store.setResults([
      endpoint('a.example'),
      endpoint(
        'b.example',
        kind: EndpointKind.proxy,
        protocol: Protocol.socks5,
      ),
    ]);

    expect(store.all, hasLength(2));
    expect(store.configCount, 1);
    expect(store.proxyCount, 1);
  });

  test('saving persists across a restart', () async {
    store.setResults([endpoint('a.example')]);
    final fingerprint = store.all.single.fingerprint;

    await store.toggleSaved(fingerprint);
    expect(store.isSaved(fingerprint), isTrue);

    final reopened = ResultsStore(prefs: prefs);
    expect(reopened.saved.map((e) => e.host), ['a.example']);
  });

  test('a saved endpoint survives a run that does not rediscover it', () async {
    store.setResults([endpoint('a.example')]);
    await store.toggleSaved(store.all.single.fingerprint);

    store.setResults([endpoint('b.example')]);

    expect(
      store.all.map((e) => e.host),
      containsAll(['a.example', 'b.example']),
      reason: 'a saved server must not vanish because one run missed it',
    );
  });

  test('a new run refreshes the measurements on saved copies', () async {
    store.setResults([
      endpoint('a.example', ping: const Duration(milliseconds: 90)),
    ]);
    final fingerprint = store.all.single.fingerprint;
    await store.toggleSaved(fingerprint);

    store.setResults([
      endpoint(
        'a.example',
        ping: const Duration(milliseconds: 300),
        health: Health.slow,
      ),
    ]);

    expect(
      store.saved.single.ping,
      const Duration(milliseconds: 300),
      reason: 'a saved row showing last week\'s ping would be worse than none',
    );
  });

  test('unsaving removes it everywhere', () async {
    store.setResults([endpoint('a.example')]);
    final fingerprint = store.all.single.fingerprint;
    await store.toggleSaved(fingerprint);

    await store.unsaveAll([fingerprint]);

    expect(store.saved, isEmpty);
    expect(store.all.single.saved, isFalse);
  });

  group('filters', () {
    setUp(() {
      store.setResults([
        endpoint(
          'fast.example',
          ping: const Duration(milliseconds: 20),
          health: Health.ok,
        ),
        endpoint(
          'slow.example',
          ping: const Duration(milliseconds: 300),
          health: Health.slow,
        ),
        endpoint('vm.example', protocol: Protocol.vmess),
        endpoint(
          'p.example',
          kind: EndpointKind.proxy,
          protocol: Protocol.socks5,
        ),
      ]);
    });

    test('shows configs by default, sorted by ping', () {
      expect(store.visible.every((e) => e.kind == EndpointKind.config), isTrue);
      expect(store.visible.first.host, 'fast.example');
    });

    test('switching tab shows proxies', () {
      store.setFilters(store.filters.copyWith(kind: EndpointKind.proxy));
      expect(store.visible.map((e) => e.host), ['p.example']);
    });

    test('protocol filter narrows to that protocol', () {
      store.setFilters(store.filters.copyWith(protocol: Protocol.vmess));
      expect(store.visible.map((e) => e.host), ['vm.example']);
    });

    test('available protocols reflect the data, not a fixed list', () {
      expect(
        store.availableProtocols,
        containsAll([Protocol.vless, Protocol.vmess]),
      );
      expect(
        store.availableProtocols,
        isNot(contains(Protocol.socks5)),
        reason: 'socks5 is a proxy and the config tab is showing',
      );
    });
  });

  group('best', () {
    test('picks the healthy endpoint with the lowest ping', () {
      store.setResults([
        endpoint(
          'slow.example',
          ping: const Duration(milliseconds: 300),
          health: Health.slow,
        ),
        endpoint(
          'fast.example',
          ping: const Duration(milliseconds: 20),
          health: Health.ok,
        ),
        endpoint('dead.example', health: Health.dead, score: 99),
      ]);

      expect(store.best!.host, 'fast.example');
    });

    test('is null when nothing was proven healthy', () {
      store.setResults([
        endpoint('untested.example'),
        endpoint('dead.example', health: Health.dead),
      ]);

      expect(
        store.best,
        isNull,
        reason: 'simple mode must not connect to something never proven up',
      );
    });
  });

  group('import', () {
    test('reads plain config links', () {
      final count = store.importFromText(
        'vless://u1@1.2.3.4:443?security=reality#A\ntrojan://p@5.6.7.8:443#B',
      );

      expect(count, 2);
      expect(store.all, hasLength(2));
    });

    test('reads a base64 subscription body', () {
      // The same payload shape a subscription URL serves.
      const body =
          'dmxlc3M6Ly91MUAxMC4wLjAuMTo0NDM/c2VjdXJpdHk9cmVhbGl0eSNBCnRyb2phbjovL3BAMTAuMC4wLjI6NDQzI0I=';

      final count = store.importSubscription(
        body,
        url: 'https://example.com/sub',
      );

      expect(count, 2);
      expect(
        store.all.map((e) => e.host),
        containsAll(['10.0.0.1', '10.0.0.2']),
      );
    });

    test('returns zero for text with nothing in it', () {
      expect(store.importFromText('just some prose, no links here'), 0);
    });

    test('importing the same list twice does not duplicate', () {
      const text = 'vless://u1@1.2.3.4:443?security=reality#A';
      store.importFromText(text);
      store.importFromText(text);

      expect(store.all, hasLength(1));
    });
  });

  test('history is newest first, bounded, and persisted', () async {
    for (var i = 0; i < 35; i++) {
      await store.recordRun(
        RunRecord(
          at: DateTime(2026, 1, 1).add(Duration(days: i)),
          found: i,
          healthy: i,
          engines: 8,
        ),
      );
    }

    expect(store.history, hasLength(30));
    expect(store.history.first.found, 34);

    final reopened = ResultsStore(prefs: prefs);
    expect(reopened.history, hasLength(30));
    expect(reopened.history.first.found, 34);
  });

  test('clearing results keeps saved items', () async {
    store.setResults([endpoint('a.example'), endpoint('b.example')]);
    await store.toggleSaved(store.all.first.fingerprint);

    await store.clearResults();

    expect(store.saved, hasLength(1));
    expect(store.all, hasLength(1));
  });

  test('a corrupt stored row costs one entry, not the whole list', () async {
    store.setResults([endpoint('a.example')]);
    await store.toggleSaved(store.all.single.fingerprint);

    final rows = prefs.getStringList('results.saved')!;
    await prefs.setStringList('results.saved', [...rows, 'not json at all']);

    final reopened = ResultsStore(prefs: prefs);
    expect(reopened.saved, hasLength(1));
  });
}
