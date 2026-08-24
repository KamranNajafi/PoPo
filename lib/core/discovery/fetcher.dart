/// The one place discovery touches the network.
///
/// Everything else in this directory is pure, so the pipeline can be tested end
/// to end against a fake. When the Go core lands, only this interface is
/// reimplemented — the keyword, parsing and ranking logic moves unchanged.
abstract interface class Fetcher {
  /// Returns the body, or throws [FetchException].
  Future<FetchResult> get(String url, {Map<String, String> headers});
}

class FetchResult {
  const FetchResult({
    required this.statusCode,
    required this.body,
    this.finalUrl,
  });

  final int statusCode;
  final String body;

  /// Set when the request was redirected; SERP links are often redirector URLs.
  final String? finalUrl;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

class FetchException implements Exception {
  const FetchException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'FetchException($message${statusCode == null ? '' : ', $statusCode'})';
}
