// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.request;

import 'dart:async';
import 'dart:collection';

// TODO(kevmoo): use UnmodifiableMapView from SDK once 1.4 ships
import 'package:collection/wrappers.dart' as pc;
import 'package:path/path.dart' as p;

import 'message.dart';
import 'util.dart';

/// Represents an HTTP request to be processed by a Shelf application.
class Request extends Message {
  /// The remainder of the [requestedUri] path designating the virtual
  /// "location" of the request's target within the handler.
  ///
  /// [pathInfo] may be an empty string, if [requestedUri ]targets the handler
  /// root and does not have a trailing slash.
  ///
  /// [pathInfo] is never null. If it is not empty, it will start with `/`.
  ///
  /// [scriptName] and [pathInfo] combine to create a valid path that should
  /// correspond to the [requestedUri] path.
  final String pathInfo;

  /// The portion of the request URL that follows the "?", if any.
  final String queryString;

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
  /// [scriptName] and [pathInfo] combine to create a valid path that should
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

  Request(this.pathInfo, String queryString, this.method,
      this.scriptName, this.protocolVersion, this.requestedUri,
      Map<String, String> headers, {Stream<List<int>> body})
      : this.queryString = queryString == null ? '' : queryString,
        super(new pc.UnmodifiableMapView(new HashMap.from(headers)),
            body == null ? new Stream.fromIterable([]) : body) {
    if (method.isEmpty) throw new ArgumentError('method cannot be empty.');

    if (scriptName.isNotEmpty && !scriptName.startsWith('/')) {
      throw new ArgumentError('scriptName must be empty or start with "/".');
    }

    if (scriptName == '/') {
      throw new ArgumentError(
          'scriptName can never be "/". It should be empty instead.');
    }

    if (scriptName.endsWith('/')) {
      throw new ArgumentError('scriptName must not end with "/".');
    }

    if (pathInfo.isNotEmpty && !pathInfo.startsWith('/')) {
      throw new ArgumentError('pathInfo must be empty or start with "/".');
    }

    if (scriptName.isEmpty && pathInfo.isEmpty) {
      throw new ArgumentError('scriptName and pathInfo cannot both be empty.');
    }
  }

  /// Convenience property to access [pathInfo] data as a [List].
  List<String> get pathSegments {
    var segs = p.url.split(pathInfo);
    if (segs.length > 0) {
      assert(segs.first == p.url.separator);
      segs.removeAt(0);
    }
    return segs;
  }
}
