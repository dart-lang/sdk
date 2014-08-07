// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_base;

import 'dart:async';

/// These headers should be ignored by [Client]s when making requests and when
/// receiving headers from a HTTP server.
const List<String> _TRANSPORT_HEADERS =
    const ['connection', 'upgrade', 'keep-alive', 'transfer-encoding'];

/// These headers cannot be folded into one header value via ',' joining.
const List<String> _COOKIE_HEADERS = const ['set-cookie', 'cookie'];

/// Representation of a set of HTTP headers.
abstract class Headers {
  /// Returns the names of all header fields.
  Iterable<String> get names;

  /// Returns `true` if a header field of the specified [name] exist.
  bool contains(String name);

  /// Returns the value for the header field named [name].
  ///
  /// The HTTP standard supports multiple values for each header field name.
  /// Header fields with multiple values can be represented as a
  /// comma-separated list. If a header has multiple values the returned string
  /// is the comma-separated list of all these values.
  ///
  /// For header field-names which do not allow combining multiple values with
  /// comma, this index operator will throw `ArgumentError`.
  /// This is currently the case for the 'Cookie' and 'Set-Cookie' headers. Use
  /// `getMultiple` method to iterate over the header values for these.
  String operator [](String name);

  /// Returns the values for the header field named [name].
  ///
  /// The order in which the values for the field name appear is the same
  /// as the order in which they are to be send or was received.
  ///
  /// If there are no header values named [name] `null` will be returned.
  Iterable<String> getMultiple(String name);
}


/// Representation of a HTTP request.
abstract class Request {
  /// Request method.
  String get method;

  /// Request url.
  Uri get url;

  /// Request headers.
  Headers get headers;

  /// Request body.
  Stream<List<int>> read();
}


/// Representation of a HTTP response.
abstract class Response {
  /// Response status code.
  int get statusCode;

  /// Response headers.
  Headers get headers;

  /// Response body.
  Stream<List<int>> read();
}


/// Function for performing an HTTP request.
///
/// The [RequestHandler] may use any transport mechanism it wants
/// (e.g. HTTP/1.1, HTTP/2.0, SPDY) to perform the HTTP request.
///
/// [RequestHandler]s are composable. E.g. A [RequestHandler] may add an
/// 'Authorization' header to [request] and forward to another [RequestHandler].
///
/// A [RequestHandler] may ignore connection specific headers in [request] and
/// may not present them in the [Response] object.
///
/// Connection specific headers:
///    'Connection', 'Upgrade', 'Keep-Alive', 'Transfer-Encoding'
typedef Future<Response> RequestHandler(Request request);


/// An implementation of [Headers].
class HeadersImpl implements Headers {
  static const HeadersImpl Empty = const HeadersImpl.empty();

  final Map<String, List<String>> _m;

  /// Constructs a [HeadersImpl] with no headers.
  const HeadersImpl.empty() : _m = const {};

  /// Constructs a new [HeaderImpl] initialized with [map].
  ///
  /// [map] must contain only String keys and either String or
  /// Iterable<String> values.
  HeadersImpl(Map map) : _m = {} {
    _addDiff(map);
  }

  /// Makes a copy of this [HeadersImpl] and replaces all headers in present in
  /// [differenceMap].
  ///
  /// [differenceMap] must contain only String keys and either String or
  /// Iterable<String> values.
  HeadersImpl replace(Map differenceMap) {
    var headers = new HeadersImpl({});
    _m.forEach((String key, List<String> value) {
      headers._m[key] = value;
    });
    headers._addDiff(differenceMap);
    return headers;
  }

  void _addDiff(Map diff) {
    diff.forEach((String key, value) {
      key = key.toLowerCase();

      if (value == null) {
        _m.remove(key);
      } else if (value is String) {
        var values = new List(1);
        values[0] = value;
        _m[key] = values;
      } else {
        _m[key] = value.toList();
      }
    });
  }

  Iterable<String> get names => _m.keys;

  bool contains(String name) =>  _m.containsKey(name.toLowerCase());

  String operator [](String name) {
    name = name.toLowerCase();

    if (_COOKIE_HEADERS.contains(name)) {
      throw new ArgumentError('Cannot use Headers[] with $name header.');
    }

    var values = _m[name];
    if (values == null) return null;
    if (values.length == 1) return values.first;
    return values.join(',');
  }

  Iterable<String> getMultiple(String name) {
    name = name.toLowerCase();
    var values = _m[name];
    if (values == null) return values;

    if (_COOKIE_HEADERS.contains(name)) {
      return values;
    } else {
      return values.expand((e) => e.split(',')).map((e) => e.trim());
    }
  }
}


/// Internal helper class to reduce code duplication between [RequestImpl]
/// and [ResponseImpl].
class _Message {
  final Headers headers;
  final Stream<List<int>> _body;
  bool _bodyRead = false;

  _Message(Headers headers_, body)
      : headers = headers_ != null ? headers_ : HeadersImpl.Empty,
        _body = body != null ? body : (new StreamController()..close()).stream;

  /// Returns the [Stream] of bytes of this message.
  ///
  /// The body of a message can only be read once.
  Stream<List<int>> read() {
    if (_bodyRead) {
      throw new StateError('The response stream has already been listened to.');
    }
    _bodyRead = true;
    return _body;
  }
}


/// An immutable implementation of [Request].
///
/// The request can be modified with the copy-on-write `replace` method.
class RequestImpl extends _Message implements Request {
  final String method;
  final Uri url;

  RequestImpl(this.method, this.url, {Headers headers, Stream<List<int>> body})
      : super(headers, body);

  /// Makes a copy of this [RequestImpl] by overriding `method`, `url`,
  /// `headers` and `body` if they are not null.
  ///
  /// In case no [body] was supplied, the current `body` will be used and is
  /// therefore no longer available to users. This is a transfer of the owner
  /// of the body stream to the returned object.
  RequestImpl replace(
        {String method, Uri url, Headers headers, Stream<List<int>> body}) {
    if (method == null) method = this.method;
    if (url == null) url = this.url;
    if (headers == null) headers = this.headers;
    if (body == null) body = read();

    return new RequestImpl(method, url, headers: headers, body: body);
  }
}


/// An immutable implementation of [Response].
///
/// The response can be modified with the copy-on-write `replace` method.
class ResponseImpl extends _Message implements Response {
  final int statusCode;

  ResponseImpl(this.statusCode, {Headers headers, Stream<List<int>> body})
      : super(headers, body);

  /// Returns a copy of this [ResponseImpl] by overriding `statusCode`,
  /// `headers` and `body` if they are not null.
  ///
  /// In case no [body] was supplied, the current `body` will be used and is
  /// therefore no longer available to users. This is a transfer of the owner
  /// of the body stream to the returned object.
  ResponseImpl replace(
        {int statusCode, Headers headers, Stream<List<int>> body}) {
    if (statusCode == null) statusCode = this.statusCode;
    if (headers == null) headers = this.headers;
    if (body == null) body = read();

    return new ResponseImpl(statusCode, headers: headers, body: body);
  }
}
