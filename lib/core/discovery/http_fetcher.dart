import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fetcher.dart';

/// The real network implementation of [Fetcher].
///
/// Discovery follows links chosen by strangers, so this is a hostile-input
/// boundary: every response is capped, type-checked and decoded leniently
/// before any of it reaches the parser. A single page must never be able to
/// exhaust memory or stall a run.
class HttpFetcher implements Fetcher {
  HttpFetcher({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
    this.maxBytes = 2 * 1024 * 1024,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// Pages beyond this are truncated rather than refused: a list is usually near
  /// the top, and a 40MB page is not worth buffering to find out.
  final int maxBytes;

  @override
  Future<FetchResult> get(String url, {Map<String, String> headers = const {}}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isScheme('http') && !uri.isScheme('https')) {
      throw FetchException('unsupported url: $url');
    }

    final request = http.Request('GET', uri)
      ..followRedirects = true
      ..maxRedirects = 5
      ..headers.addAll(headers);

    http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw const FetchException('timeout');
    } on Object catch (e) {
      throw FetchException('$e');
    }

    // Binary bodies cannot be scanned for links, and buffering one is pure waste.
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.isNotEmpty && !_isTextual(contentType)) {
      return FetchResult(
        statusCode: response.statusCode,
        body: '',
        finalUrl: response.request?.url.toString(),
      );
    }

    final bytes = <int>[];
    try {
      await for (final chunk in response.stream.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length >= maxBytes) break;
      }
    } on TimeoutException {
      throw const FetchException('timeout while reading body');
    } on Object catch (e) {
      throw FetchException('$e');
    }

    return FetchResult(
      statusCode: response.statusCode,
      // Encodings are wrong or absent often enough that a strict decode would
      // discard usable pages; the parser only ever looks for ASCII patterns.
      body: utf8.decode(bytes, allowMalformed: true),
      finalUrl: response.request?.url.toString(),
    );
  }

  bool _isTextual(String contentType) {
    final lower = contentType.toLowerCase();
    return lower.startsWith('text/') ||
        lower.contains('json') ||
        lower.contains('xml') ||
        lower.contains('javascript') ||
        lower.contains('x-www-form-urlencoded');
  }

  void close() => _client.close();
}
