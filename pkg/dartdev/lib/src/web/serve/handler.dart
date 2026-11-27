// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartdev/src/web/serve/dart_sources.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

const _corpHeader = 'cross-origin-resource-policy';

/// Files whose bytes never change during a `dart serve` session, so their
/// `ETag` is computed once.
const _unchangingPaths = {
  'ddc_module_loader.js',
  'dart_stack_trace_mapper.js',
  'dart_sdk.js',
  'dart_sdk.js.map',
};

/// Returns the file to serve at the URL [path] (relative to the server root,
/// without a leading `/`), or `null` if there is none.
typedef FileLookup = Uint8List? Function(String path);

/// Creates the HTTP handler that serves the app.
///
/// The server root is the app's [webDirectory]. A request is answered with,
/// in order:
/// 1. A file that [lookupFile] returns.
/// 2. A file from [webDirectory], with `index.html` for directories.
/// 3. A `.dart` file from [dartSources], for the source maps.
/// 4. A plain-text 404.
///
/// [hostname] is the host the server was configured to bind (such as
/// `'localhost'`, `'127.0.0.1'`, or `'any'`), used to validate `Host` headers
/// against DNS rebinding.
///
/// Requests wait until [ready] completes, so that the browser doesn't get
/// 404s for the compiled files before the first compile finishes.
// TODO(https://github.com/dart-lang/sdk/issues/64888): Decide whether and how
// non-Dart package assets (`/packages/<pkg>/<asset>`) are served.
Handler createAppHandler({
  required FileLookup lookupFile,
  required String webDirectory,
  DartSources? dartSources,
  String hostname = 'localhost',
  Future<void>? ready,
}) {
  final staticHandler = createStaticHandler(
    webDirectory,
    defaultDocument: 'index.html',
  );
  final sdkETags = <String, String>{};

  /// Answers [request] with a file from [lookupFile], a `web/` file, a
  /// `.dart` source, or a 404, once the request passed the security checks.
  Future<Response> serveAppFiles(Request request) async {
    if (request.method != 'GET' && request.method != 'HEAD') {
      return Response(
        HttpStatus.methodNotAllowed,
        body: 'Method not allowed',
        headers: {HttpHeaders.allowHeader: 'GET, HEAD'},
      );
    }
    if (!_hasSafePath(request.url)) {
      return Response.notFound('Not found: /${request.url.path}');
    }
    await ready;
    final path = request.url.path;
    if (lookupFile(path) case final file?) {
      return _fileResponse(
        request,
        body: () => file,
        length: file.length,
        contentType: _contentType(path),
        // App modules and bootstrap scripts change when the app recompiles,
        // so they're hashed on each request.
        etag: _unchangingPaths.contains(path)
            ? sdkETags[path] ??= _strongETag(file)
            : _strongETag(file),
      );
    }
    final response = await staticHandler(request);
    if (response.statusCode != HttpStatus.notFound) {
      // Always revalidate against shelf_static's ETag so edits show up on
      // reload instead of being served from heuristic browser caches.
      return response.change(
        headers: {HttpHeaders.cacheControlHeader: 'no-cache'},
      );
    }
    if (dartSources?.resolve(request.url.pathSegments) case final source?) {
      // The size and modification time change when the user edits the file,
      // and are read without opening it.
      final stat = source.statSync();
      return _fileResponse(
        request,
        // Stops at the announced length, in case the file grew since.
        body: () => source.openRead(0, stat.size),
        length: stat.size,
        contentType: 'text/plain; charset=utf-8',
        etag:
            '"${stat.size.toRadixString(16)}-'
            '${stat.modified.microsecondsSinceEpoch.toRadixString(16)}"',
      );
    }
    return Response.notFound('Not found: /$path');
  }

  return const Pipeline()
      .addMiddleware(_securityMiddleware(hostname))
      .addHandler(serveAppFiles);
}

/// Answers [request] with a file of [length] bytes that browsers keep but
/// check before each use: it's sent with `Cache-Control: no-cache` and its
/// [etag], and answered with a 304 when the browser's copy has that [etag].
///
/// [body] is only called when the file's contents are sent.
Response _fileResponse(
  Request request, {
  required Object Function() body,
  required int length,
  required String contentType,
  required String etag,
}) {
  final cacheHeaders = {
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.etagHeader: etag,
  };
  if (_matchesIfNoneMatch(request, etag)) {
    return Response.notModified(headers: cacheHeaders);
  }
  return Response.ok(
    request.method == 'HEAD' ? null : body(),
    headers: {
      HttpHeaders.contentTypeHeader: contentType,
      HttpHeaders.contentLengthHeader: '$length',
      ...cacheHeaders,
    },
  );
}

/// Rejects DNS-rebinding `Host` headers and cross-site subresource loads, and
/// sets `Cross-Origin-Resource-Policy: same-site` on every response.
Middleware _securityMiddleware(String configuredHostname) {
  final normalizedConfigured = configuredHostname.toLowerCase();
  return (Handler innerHandler) => (Request request) async {
    final hostHeaders = request.headersAll[HttpHeaders.hostHeader];
    if (hostHeaders == null ||
        hostHeaders.length != 1 ||
        !_isAllowedHost(hostHeaders.single, normalizedConfigured)) {
      return Response.forbidden(
        'Forbidden: invalid Host header.',
        headers: {_corpHeader: 'same-site'},
      );
    }
    if (!_isAllowedFetchMetadata(request)) {
      return Response.forbidden(
        'Forbidden: cross-site request not allowed.',
        headers: {_corpHeader: 'same-site'},
      );
    }
    final response = await innerHandler(request);
    return response.change(headers: {_corpHeader: 'same-site'});
  };
}

bool _isAllowedHost(String hostHeader, String configuredHostname) {
  final Uri uri;
  try {
    uri = Uri.parse('http://$hostHeader');
  } on FormatException {
    return false;
  }
  if (uri.userInfo.isNotEmpty ||
      uri.path.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.host.isEmpty) {
    return false;
  }
  final host = uri.host.toLowerCase();
  if (host == 'localhost' ||
      (host.length > '.localhost'.length && host.endsWith('.localhost'))) {
    return true;
  }
  if (InternetAddress.tryParse(host) != null) return true;
  if (configuredHostname != 'any' && host == configuredHostname) return true;
  return false;
}

bool _isAllowedFetchMetadata(Request request) {
  final site = request.headers['sec-fetch-site']?.trim().toLowerCase();
  if (site == null ||
      site == 'same-origin' ||
      site == 'same-site' ||
      site == 'none') {
    return true;
  }
  // Allow top-level and iframe navigations (e.g. clicking a link to localhost),
  // but never <object> or <embed>.
  final isGetOrHead = request.method == 'GET' || request.method == 'HEAD';
  final mode = request.headers['sec-fetch-mode']?.trim().toLowerCase();
  final dest = request.headers['sec-fetch-dest']?.trim().toLowerCase();
  return isGetOrHead &&
      mode == 'navigate' &&
      dest != 'object' &&
      dest != 'embed';
}

/// Checks every segment of [url], ignoring the single trailing empty segment
/// that `Uri.pathSegments` includes when [url] ends with `/`.
bool _hasSafePath(Uri url) {
  if (url.path.startsWith('/')) return false;
  final segments = url.pathSegments;
  final nonTrailing = url.path.endsWith('/') && segments.isNotEmpty
      ? segments.sublist(0, segments.length - 1)
      : segments;
  return nonTrailing.every(isSafeUrlSegment);
}

/// A strong HTTP `ETag` for [bytes]: their SHA-256 hash, so it changes
/// whenever any byte does (including across SDK upgrades).
String _strongETag(Uint8List bytes) => '"${sha256.convert(bytes)}"';

bool _matchesIfNoneMatch(Request request, String etag) {
  final header = request.headers[HttpHeaders.ifNoneMatchHeader];
  if (header == null) return false;
  if (header.trim() == '*') return true;
  return header
      .split(',')
      .map((tag) => tag.trim())
      .any((tag) => tag == etag || tag == 'W/$etag');
}

/// The content type of the file at [path].
String _contentType(String path) => path.endsWith('.js')
    ? 'application/javascript; charset=utf-8'
    // Source maps (`.map`) and debug metadata (`.metadata`) are JSON.
    : 'application/json; charset=utf-8';
