import 'models.dart';

/// Builds the search phrases a run will use.
///
/// The generator is a cross product of five axes, not a hand-written list: a
/// fixed list goes stale the moment publishers change vocabulary, whereas the
/// axes can be extended one entry at a time. Every phrase carries a weight so
/// the run spends its query budget on the phrases most likely to pay off, and
/// tags so a failing category can be traced and dropped.
class KeywordGenerator {
  const KeywordGenerator({
    this.now,
    this.includePersian = true,
    this.includeSiteHints = true,
  });

  /// Injected so "this month" is deterministic in tests.
  final DateTime? now;

  final bool includePersian;

  /// `site:` operators. Supported by DuckDuckGo, Google, Bing, Brave, Startpage,
  /// Yandex; ignored or unsupported elsewhere — see [SearchEngine.supportsSiteOperator].
  final bool includeSiteHints;

  /// Protocol vocabulary. Weight reflects how much usable output each term
  /// historically yields, not how good the protocol is.
  static const _protocols = <String, double>{
    'v2ray': 1.0,
    'vless': 1.0,
    'vmess': 0.9,
    'reality': 1.0,
    'trojan': 0.8,
    'shadowsocks': 0.8,
    'hysteria2': 0.7,
    'tuic': 0.5,
    'xray': 0.7,
    'sing-box': 0.6,
    'socks5': 0.6,
    'http proxy': 0.5,
  };

  /// What publishers call the thing they are publishing.
  static const _nouns = <String>[
    'config',
    'configs',
    'subscription',
    'sub link',
    'server list',
    'free servers',
  ];

  /// Qualifiers that correlate with a live, recently updated list.
  static const _qualifiers = <String, double>{
    'free': 1.0,
    'daily': 1.1,
    'updated': 1.1,
    'fresh': 1.0,
    'working': 1.0,
    '': 0.8, // the bare "<protocol> <noun>" form
  };

  /// Persian publishers use their own vocabulary; skipping it loses a whole
  /// segment of sources.
  static const _persian = <String>[
    'کانفیگ رایگان',
    'کانفیگ v2ray',
    'لیست پروکسی رایگان',
    'سابسکریپشن رایگان',
    'کانفیگ vless',
    'پروکسی سالم',
  ];

  /// Hosts that actually carry lists. Ordered by yield.
  static const _sites = <String, double>{
    'github.com': 1.2,
    'gist.github.com': 1.2,
    'raw.githubusercontent.com': 1.1,
    't.me': 1.0,
    'telegram.me': 0.8,
    'pastebin.com': 0.7,
  };

  /// Generates up to [limit] phrases, best first.
  List<Keyword> generate({int limit = 60}) {
    final at = now ?? DateTime.now();
    final out = <String, Keyword>{};

    void add(String text, double weight, Set<String> tags) {
      final key = text.trim().toLowerCase();
      if (key.isEmpty) return;
      final existing = out[key];
      // The same phrase can be reachable down two axes; keep the better claim.
      if (existing == null || weight > existing.weight) {
        out[key] = Keyword(text.trim(), weight: weight, tags: tags);
      }
    }

    // 1. protocol x noun x qualifier
    for (final MapEntry(key: protocol, value: pw) in _protocols.entries) {
      for (final noun in _nouns) {
        for (final MapEntry(key: qualifier, value: qw) in _qualifiers.entries) {
          add('$qualifier $protocol $noun', pw * qw, {'protocol', 'en'});
        }
      }
    }

    // 2. freshness — publishers stamp lists with the month or year, and these
    //    phrases are what separate a live list from a 2021 dump.
    final year = at.year.toString();
    final month = _months[at.month - 1];
    for (final MapEntry(key: protocol, value: pw) in _protocols.entries) {
      add('$protocol config $year', pw * 1.15, {'protocol', 'fresh'});
      add('$protocol config $month $year', pw * 1.2, {'protocol', 'fresh'});
    }

    // 3. Persian
    if (includePersian) {
      for (final phrase in _persian) {
        add(phrase, 1.0, {'persian'});
        add('$phrase $year', 1.05, {'persian', 'fresh'});
      }
    }

    // 4. site-scoped — highest yield per query, so they get the top weights.
    if (includeSiteHints) {
      for (final MapEntry(key: site, value: sw) in _sites.entries) {
        for (final protocol in const ['v2ray', 'vless', 'reality', 'shadowsocks']) {
          add('$protocol subscription site:$site', sw * 1.25, {'site', 'protocol'});
        }
        add('free proxy list site:$site', sw, {'site'});
      }
    }

    // 5. subscription-shaped queries — these find the raw list itself rather
    //    than a page describing one.
    for (final protocol in const ['v2ray', 'vless', 'vmess', 'trojan']) {
      add('$protocol subscription link raw', 1.15, {'raw'});
      add('"$protocol://" list', 1.1, {'raw'});
    }

    final sorted = out.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return sorted.take(limit).toList();
  }

  static const _months = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];
}
