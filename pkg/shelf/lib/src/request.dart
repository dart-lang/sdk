// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.request;

import 'dart:async';

import 'package:http_parser/http_parser.dart';

import 'message.dart';

/// Represents an HTTP request to be processed by a Shelf application.
class Request extends Message {
  /// The remainder of the [requestedUri] path and query designating the virtual
  /// "location" of the request's target within the handler.
  ///
  /// [url] may be an empty, if [requestedUri]targets the handler
  /// root and does not have a trailing slash.
  ///
  /// [url] is never null. If it is not empty, it will start with `/`.
  ///
  /// [scriptName] and [url] combine to create a valid path that should
  /// correspond to the [requestedUri] path.
  final Uri url;

  /// The HTTP request method, such as "GET" or "POST".
  final String method;

  /// The initial portion of the [requestedUri] path that corresponds to the
  /// handler.
  ///
  /// [scriptName] allows a handler to know its virtual "location".
  ///
  /// If the handler corresponds to the "root" of a server, it will be an
  /// empty string, otherwise it will start with a `/`
  ///
  /// [scriptName] and [url] combine to create a valid path that should
  /// correspond to the [requestedUri] path.
  final String scriptName;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  final String protocolVersion;

  /// The original [Uri] for the request.
  final Uri requestedUri;

  /// If this is non-`null` and the requested resource hasn't been modified
  /// since this date and time, the server should return a 304 Not Modified
  /// response.
  ///
  /// This is parsed from the If-Modified-Since header in [headers]. If
  /// [headers] doesn't have an If-Modified-Since header, this will be `null`.
  DateTime get ifModifiedSince {
    if (_ifModifiedSinceCache != null) return _ifModifiedSinceCache;
    if (!headers.containsKey('if-modified-since')) return null;
    _ifModifiedSinceCache = parseHttpDate(headers['if-modified-since']);
    return _ifModifiedSinceCache;
  }
  DateTime _ifModifiedSinceCache;

  /// Creates a new [Request].
  ///
  /// If [url] and [scriptName] are omitted, they are inferred from
  /// [requestedUri].
  ///
  /// Setting one of [url] or [scriptName] and not the other will throw an
  /// [ArgumentError].
  ///
  /// The default value for [protocolVersion] is '1.1'.
  // TODO(kevmoo) finish documenting the rest of the arguments.
  Request(this.method, Uri requestedUri, {String protocolVersion,
    Map<String, String> headers, Uri url, String scriptName,
    Stream<List<int>> body})
      : this.requestedUri = requestedUri,
        this.protocolVersion = protocolVersion == null ?
            '1.1' : protocolVersion,
        this.url = _computeUrl(requestedUri, url, scriptName),
        this.scriptName = _computeScriptName(requestedUri, url, scriptName),
        super(body == null ? new Stream.fromIterable([]) : body,
            headers: headers) {
    if (method.isEmpty) throw new ArgumentError('method cannot be empty.');

    // TODO(kevmoo) use isAbsolute property on Uri once Issue 18053 is fixed
    if (requestedUri.scheme.isEmpty) {
      throw new ArgumentError('requstedUri must be an absolute URI.');
    }

    if (this.scriptName.isNotEmpty && !this.scriptName.startsWith('/')) {
      throw new ArgumentError('scriptName must be empty or start with "/".');
    }

    if (this.scriptName == '/') {
      throw new ArgumentError(
          'scriptName can never be "/". It should be empty instead.');
    }

    if (this.scriptName.endsWith('/')) {
      throw new ArgumentError('scriptName must not end with "/".');
    }

    if (this.url.path.isNotEmpty && !this.url.path.startsWith('/')) {
      throw new ArgumentError('url must be empty or start with "/".');
    }

    if (this.scriptName.isEmpty && this.url.path.isEmpty) {
      throw new ArgumentError('scriptName and url cannot both be empty.');
    }
  }
}

/// Computes `url` from the provided [Request] constructor arguments.
///
/// If [url] and [scriptName] are `null`, infer value from [requestedUrl],
/// otherwise return [url].
///
/// If [url] is provided, but [scriptName] is omitted, throws an
/// [ArgumentError].
Uri _computeUrl(Uri requestedUri, Uri url, String scriptName) {
  if (url == null && scriptName == null) {
    return new Uri(path: requestedUri.path, query: requestedUri.query,
        fragment: requestedUri.fragment);
  }

  if (url != null && scriptName != null) {
    // TODO(kevmoo) use isAbsolute property on Uri once Issue 18053 is fixed
    if (url.scheme.isNotEmpty) throw new ArgumentError('url must be relative.');
    return url;
  }

  throw new ArgumentError(
      'url and scriptName must both be null or both be set.');
}

/// Computes `scriptName` from the provided [Request] constructor arguments.
///
/// If [url] and [scriptName] are `null` it returns an empty string, otherwise
/// [scriptName] is returned.
///
/// If [script] is provided, but [url] is omitted, throws an
/// [ArgumentError].
String _computeScriptName(Uri requstedUri, Uri url, String scriptName) {
  if (url == null && scriptName == null) {
    return '';
  }

  if (url != null && scriptName != null) {
    return scriptName;
  }

  throw new ArgumentError(
      'url and scriptName must both be null or both be set.');
}
