// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.message;

import 'dart:async';
import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:stack_trace/stack_trace.dart';

import 'shelf_unmodifiable_map.dart';

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

  /// This boolean indicates whether [_body] has been read.
  ///
  /// After calling [read], or [readAsString] (which internally calls [read]),
  /// this will be `true`.
  bool _bodyWasRead = false;

  /// Creates a new [Message].
  ///
  /// If [headers] is `null`, it is treated as empty.
  Message(this._body, {Map<String, String> headers,
        Map<String, Object> context})
      : this.headers = new ShelfUnmodifiableMap<String>(headers,
            ignoreKeyCase: true),
        this.context = new ShelfUnmodifiableMap<Object>(context,
            ignoreKeyCase: false);

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
  Stream<List<int>> read() {
    if (_bodyWasRead) {
      throw new StateError("The 'read' method can only be called once on a "
                           "shelf.Request/shelf.Response object.");
    }
    _bodyWasRead = true;
    return _body;
  }

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

  /// Creates a new [Message] by copying existing values and applying specified
  /// changes.
  Message change({Map<String, String> headers, Map<String, Object> context});
}
