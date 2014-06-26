// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_base;

import 'dart:async';

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
  /// comma, this index operator will throw `IllegalArgument`.
  /// This is currently the case for the 'Cookie' and 'Set-Cookie' headers. Use
  /// `getMultiple` method to iterate over the header values for these.
  String operator [](String name);

  /// Returns the values for the header field named [name].
  ///
  /// The order in which the values for the field name appear is the same
  /// as the order in which they are to be send or was received.
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
