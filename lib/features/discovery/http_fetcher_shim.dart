import '../../core/discovery/http_fetcher.dart';

/// Fetches a subscription URL and returns its body, or null.
///
/// A one-shot helper rather than a long-lived client: an import is a single
/// request the user initiated, and holding a client open between them buys
/// nothing.
Future<String?> fetchSubscriptionBody(String url) async {
  final fetcher = HttpFetcher();
  try {
    final response = await fetcher.get(url);
    return response.ok ? response.body : null;
  } on Object {
    return null;
  } finally {
    fetcher.close();
  }
}
