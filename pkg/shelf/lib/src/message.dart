// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.message;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

// TODO(kevmoo): use UnmodifiableMapView from SDK once 1.4 ships
import 'package:collection/wrappers.dart' as pc;
import 'package:http_parser/http_parser.dart';
import 'package:stack_trace/stack_trace.dart';

/// Represents logic shared between [Request] and [Response].
abstract class Message {
  /// The HTTP headers.
  ///
  /// The value is immutable.
  final Map<String, String> headers;

  /// Extra context that can be used by for middleware and handlers.
  ///
  /// For requests, this is used to pass data to inner middleware and handlers;
  /// for responses, it's used to pass data to outer middleware and handlers.
  ///
  /// Context properties that are used by a particular package should begin with
  /// that package's name followed by a period. For example, if [logRequests]
  /// wanted to take a prefix, its property name would be `"shelf.prefix"`,
  /// since it's in the `shelf` package.
  ///
  /// The value is immutable.
  final Map<String, Object> context;

  /// The streaming body of the message.
  ///
  /// This can be read via [read] or [readAsString].
  final Stream<List<int>> _body;

  /// Creates a new [Message].
  ///
  /// If [headers] is `null`, it is treated as empty.
  Message(this._body, {Map<String, String> headers,
        Map<String, Object> context})
      : this.headers = _getIgnoreCaseMapView(headers),
        this.context = new pc.UnmodifiableMapView(
            context == null ? const {} : new Map.from(context));

  /// The contents of the content-length field in [headers].
  ///
  /// If not set, `null`.
  int get contentLength {
    if (_contentLengthCache != null) return _contentLengthCache;
    if (!headers.containsKey('content-length')) return null;
    _contentLengthCache = int.parse(headers['content-length']);
    return _contentLengthCache;
  }
  int _contentLengthCache;

  /// The MIME type of the message.
  ///
  /// This is parsed from the Content-Type header in [headers]. It contains only
  /// the MIME type, without any Content-Type parameters.
  ///
  /// If [headers] doesn't have a Content-Type header, this will be `null`.
  String get mimeType {
    var contentType = _contentType;
    if (contentType == null) return null;
    return contentType.mimeType;
  }

  /// The encoding of the message body.
  ///
  /// This is parsed from the "charset" paramater of the Content-Type header in
  /// [headers].
  ///
  /// If [headers] doesn't have a Content-Type header or it specifies an
  /// encoding that [dart:convert] doesn't support, this will be `null`.
  Encoding get encoding {
    var contentType = _contentType;
    if (contentType == null) return null;
    if (!contentType.parameters.containsKey('charset')) return null;
    return Encoding.getByName(contentType.parameters['charset']);
  }

  /// The parsed version of the Content-Type header in [headers].
  ///
  /// This is cached for efficient access.
  MediaType get _contentType {
    if (_contentTypeCache != null) return _contentTypeCache;
    if (!headers.containsKey('content-type')) return null;
    _contentTypeCache = new MediaType.parse(headers['content-type']);
    return _contentTypeCache;
  }
  MediaType _contentTypeCache;

  /// Returns a [Stream] representing the body.
  ///
  /// Can only be called once.
  Stream<List<int>> read() => _body;

  /// Returns a [Future] containing the body as a String.
  ///
  /// If [encoding] is passed, that's used to decode the body.
  /// Otherwise the encoding is taken from the Content-Type header. If that
  /// doesn't exist or doesn't have a "charset" parameter, UTF-8 is used.
  ///
  /// This calls [read] internally, which can only be called once.
  Future<String> readAsString([Encoding encoding]) {
    if (encoding == null) encoding = this.encoding;
    if (encoding == null) encoding = UTF8;
    return Chain.track(encoding.decodeStream(read()));
  }
}

/// Creates on an unmodifiable map of [headers] with case-insensitive access.
Map<String, String> _getIgnoreCaseMapView(Map<String, String> headers) {
  if (headers == null) return const {};
  // TODO(kevmoo) generalize this model with a 'canonical map' to align with
  // similiar implementation in http pkg [BaseRequest].
  var map = new LinkedHashMap<String, String>(
      equals: (key1, key2) => key1.toLowerCase() == key2.toLowerCase(),
      hashCode: (key) => key.toLowerCase().hashCode);

  map.addAll(headers);

  return new pc.UnmodifiableMapView<String, String>(map);
}
