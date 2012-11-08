// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library request;

import 'dart:io';
import 'dart:scalarlist';
import 'dart:uri';

import 'base_request.dart';
import 'utils.dart';

/// An HTTP request where the entire request body is known in advance.
class Request extends BaseRequest {
  /// The size of the request body, in bytes. This is calculated from
  /// [bodyBytes].
  ///
  /// The content length cannot be set for [Request], since it's automatically
  /// calculated from [bodyBytes].
  int get contentLength => bodyBytes.length;

  set contentLength(int value) {
    throw new UnsupportedError("Cannot set the contentLength property of "
        "non-streaming Request objects.");
  }

  /// The default encoding to use when converting between [bodyBytes] and
  /// [body]. This is only used if [encoding] hasn't been manually set and if
  /// the content-type header has no encoding information.
  Encoding _defaultEncoding;

  /// The encoding used for the request. This encoding is used when converting
  /// between [bodyBytes] and [body].
  ///
  /// If the request has a `Content-Type` header and that header has a `charset`
  /// parameter, that parameter's value is used as the encoding. Otherwise, if
  /// [encoding] has been set manually, that encoding is used. If that hasn't
  /// been set either, this defaults to [Encoding.UTF_8].
  ///
  /// If the `charset` parameter's value is not a known [Encoding], reading this
  /// will throw a [FormatException].
  ///
  /// If the request has a `Content-Type` header, setting this will set the
  /// charset parameter on that header.
  Encoding get encoding {
    if (_contentType == null || _contentType.charset == null) {
      return _defaultEncoding;
    }
    return requiredEncodingForCharset(_contentType.charset);
  }

  set encoding(Encoding value) {
    _checkFinalized();
    _defaultEncoding = value;
    var contentType = _contentType;
    if (contentType != null) {
      contentType.charset = value.name;
      _contentType = contentType;
    }
  }

  // TODO(nweiz): make this return a read-only view
  /// The bytes comprising the body of the request. This is converted to and
  /// from [body] using [encoding].
  ///
  /// This list should only be set, not be modified in place.
  Uint8List get bodyBytes => _bodyBytes;
  Uint8List _bodyBytes;

  set bodyBytes(List<int> value) {
    _checkFinalized();
    _bodyBytes = toUint8List(value);
  }

  /// The body of the request as a string. This is converted to and from
  /// [bodyBytes] using [encoding].
  ///
  /// When this is set, if the request does not yet have a `Content-Type`
  /// header, one will be added with the type `text/plain`. Then the `charset`
  /// parameter of the `Content-Type` header (whether new or pre-existing) will
  /// be set to [encoding] if it wasn't already set.
  String get body => decodeString(bodyBytes, encoding);

  set body(String value) {
    bodyBytes = encodeString(value, encoding);
    var contentType = _contentType;
    if (contentType == null) contentType = new ContentType("text", "plain");
    if (contentType.charset == null) contentType.charset = encoding.name;
    _contentType = contentType;
  }

  /// The form-encoded fields in the body of the request as a map from field
  /// names to values. The form-encoded body is converted to and from
  /// [bodyBytes] using [encoding] (in the same way as [body]).
  ///
  /// If the request doesn't have a `Content-Type` header of
  /// `application/x-www-form-urlencoded`, reading this will throw a
  /// [StateError].
  ///
  /// If the request has a `Content-Type` header with a type other than
  /// `application/x-www-form-urlencoded`, setting this will throw a
  /// [StateError]. Otherwise, the content type will be set to
  /// `application/x-www-form-urlencoded`.
  ///
  /// This map should only be set, not modified in place.
  Map<String, String> get bodyFields {
    if (_contentType == null ||
        _contentType.value != "application/x-www-form-urlencoded") {
      throw new StateError('Cannot access the body fields of a Request without '
          'content-type "application/x-www-form-urlencoded".');
    }

    return queryToMap(body);
  }

  set bodyFields(Map<String, String> fields) {
    if (_contentType == null) {
      _contentType = new ContentType("application", "x-www-form-urlencoded");
    } else if (_contentType.value != "application/x-www-form-urlencoded") {
      throw new StateError('Cannot set the body fields of a Request with '
          'content-type "${_contentType.value}".');
    }

    this.body = mapToQuery(fields);
  }

  /// Creates a new HTTP request.
  Request(String method, Uri url)
    : super(method, url),
      _defaultEncoding = Encoding.UTF_8,
      _bodyBytes = new Uint8List(0);

  /// Freeze all mutable fields and return an [InputStream] containing the
  /// request body.
  InputStream finalize() {
    super.finalize();

    var stream = new ListInputStream();
    stream.write(bodyBytes);
    stream.markEndOfStream();
    return stream;
  }

  /// The `Content-Type` header of the request (if it exists) as a
  /// [ContentType].
  ContentType get _contentType {
    var contentType = headers[HttpHeaders.CONTENT_TYPE];
    if (contentType == null) return null;
    return new ContentType.fromString(contentType);
  }

  set _contentType(ContentType value) {
    headers[HttpHeaders.CONTENT_TYPE] = value.toString();
  }

  /// Throw an error if this request has been finalized.
  void _checkFinalized() {
    if (!finalized) return;
    throw new StateError("Can't modify a finalized Request.");
  }
}
