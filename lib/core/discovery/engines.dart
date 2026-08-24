import 'models.dart';

/// How reliably an engine can be scraped from a client with no API key.
///
/// This is recorded honestly rather than assumed, because it decides how the
/// run spends its budget: an engine that answers one query in five should not
/// be given the same share as one that answers every time. It is also what the
/// UI's per-engine status row reflects.
enum ScrapeViability {
  /// HTML endpoint, no JS, tolerant of a plain client. Worth querying first.
  good,

  /// Works, but rate-limits or shows an interstitial under load.
  fair,

  /// Usually blocks a plain client: JS challenge, captcha, or hard bot
  /// detection. Kept because it sometimes works and the user can enable it.
  poor,

  /// Cannot work without credentials the app does not have.
  needsApiKey,
}

/// One search engine adapter.
class SearchEngine {
  const SearchEngine({
    required this.id,
    required this.name,
    required this.viability,
    required this.queryTemplate,
    this.supportsSiteOperator = true,
    this.enabledByDefault = true,
    this.linkPattern,
    this.blockMarkers = const [],
  });

  final String id;
  final String name;
  final ScrapeViability viability;

  /// `{q}` is replaced with the percent-encoded phrase.
  final String queryTemplate;

  final bool supportsSiteOperator;
  final bool enabledByDefault;

  /// Extracts result URLs from the SERP HTML. Falls back to [_genericLinks]
  /// when null.
  final RegExp? linkPattern;

  /// Substrings that mean "we were detected", not "no results".
  final List<String> blockMarkers;

  String buildUrl(String phrase) =>
      queryTemplate.replaceAll('{q}', Uri.encodeQueryComponent(phrase));

  /// Reads result links out of SERP HTML.
  ///
  /// Deliberately regex-based rather than a DOM parse: these markups change
  /// constantly and a loose pattern that degrades to "fewer links" survives a
  /// redesign better than a selector chain that returns nothing.
  List<String> parseLinks(String html) {
    final pattern = linkPattern ?? _genericLinks;
    final out = <String>{};
    for (final m in pattern.allMatches(html)) {
      final url = _clean(m.group(1));
      if (url != null) out.add(url);
    }
    return out.toList();
  }

  /// Distinguishes a block from an empty result set, so the run can back off
  /// instead of concluding the phrase was bad.
  EngineStatus classify(int statusCode, String body) {
    if (statusCode == 429) return EngineStatus.blocked;
    if (statusCode == 403) return EngineStatus.blocked;
    if (statusCode >= 500) return EngineStatus.failed;
    final lower = body.toLowerCase();
    for (final marker in blockMarkers) {
      if (lower.contains(marker)) {
        return marker.contains('captcha')
            ? EngineStatus.captcha
            : EngineStatus.blocked;
      }
    }
    return EngineStatus.done;
  }

  static final _genericLinks = RegExp(
    r'href="((?:https?:)?//[^"]+)"',
    caseSensitive: false,
  );

  static String? _clean(String? raw) {
    if (raw == null) return null;
    var url = raw.replaceAll('&amp;', '&');

    // DuckDuckGo and Yandex wrap results in a redirector; unwrap to the target.
    final uddg = RegExp(r'[?&]uddg=([^&]+)').firstMatch(url);
    if (uddg != null) {
      url = Uri.decodeComponent(uddg.group(1)!);
    }
    if (url.startsWith('//')) url = 'https:$url';
    if (!url.startsWith('http')) return null;

    // Drop the engines' own chrome — nav, help and account links.
    for (final noise in _noiseHosts) {
      if (url.contains(noise)) return null;
    }
    return url;
  }

  static const _noiseHosts = [
    'duckduckgo.com/settings',
    'google.com/preferences',
    'google.com/advanced_search',
    'microsoft.com',
    'bing.com/account',
    'yandex.com/support',
    'policies.google',
    'support.google',
    'accounts.google',
    '/privacy',
    '/terms',
  ];
}

/// The ten engines from the design, in the order the UI lists them.
///
/// Baidu and Kagi ship disabled, matching screen 01: Baidu returns almost
/// nothing useful for these phrases, and Kagi has no anonymous search at all.
const kEngines = <SearchEngine>[
  SearchEngine(
    id: 'duckduckgo',
    name: 'DuckDuckGo',
    viability: ScrapeViability.good,
    // The HTML endpoint, which is the one that answers without JS.
    queryTemplate: 'https://html.duckduckgo.com/html/?q={q}',
    blockMarkers: ['anomaly detected', 'unfortunately, bots'],
  ),
  SearchEngine(
    id: 'google',
    name: 'Google',
    viability: ScrapeViability.poor,
    queryTemplate: 'https://www.google.com/search?q={q}&num=20',
    blockMarkers: ['captcha', 'unusual traffic', 'sorry/index'],
  ),
  SearchEngine(
    id: 'bing',
    name: 'Bing',
    viability: ScrapeViability.fair,
    queryTemplate: 'https://www.bing.com/search?q={q}&count=30',
    blockMarkers: ['captcha', 'blocked'],
  ),
  SearchEngine(
    id: 'yahoo',
    name: 'Yahoo',
    viability: ScrapeViability.fair,
    queryTemplate: 'https://search.yahoo.com/search?p={q}',
    blockMarkers: ['captcha'],
  ),
  SearchEngine(
    id: 'brave',
    name: 'Brave',
    viability: ScrapeViability.fair,
    queryTemplate: 'https://search.brave.com/search?q={q}',
    blockMarkers: ['captcha', 'are you a robot'],
  ),
  SearchEngine(
    id: 'ecosia',
    name: 'Ecosia',
    viability: ScrapeViability.fair,
    queryTemplate: 'https://www.ecosia.org/search?q={q}',
    blockMarkers: ['captcha'],
  ),
  SearchEngine(
    id: 'startpage',
    name: 'Startpage',
    viability: ScrapeViability.poor,
    queryTemplate: 'https://www.startpage.com/sp/search?query={q}',
    blockMarkers: ['captcha', 'suspicious activity'],
  ),
  SearchEngine(
    id: 'yandex',
    name: 'Yandex',
    viability: ScrapeViability.poor,
    queryTemplate: 'https://yandex.com/search/?text={q}',
    blockMarkers: ['captcha', 'showcaptcha', 'are not a robot'],
  ),
  SearchEngine(
    id: 'baidu',
    name: 'Baidu',
    viability: ScrapeViability.poor,
    queryTemplate: 'https://www.baidu.com/s?wd={q}',
    supportsSiteOperator: false,
    enabledByDefault: false,
    blockMarkers: ['验证', 'security verification'],
  ),
  SearchEngine(
    id: 'kagi',
    name: 'Kagi',
    viability: ScrapeViability.needsApiKey,
    queryTemplate: 'https://kagi.com/search?q={q}',
    enabledByDefault: false,
    blockMarkers: ['sign in', 'log in to continue'],
  ),
];

SearchEngine? engineById(String id) {
  for (final e in kEngines) {
    if (e.id == id) return e;
  }
  return null;
}
