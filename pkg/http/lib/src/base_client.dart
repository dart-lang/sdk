// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library base_client;

import 'dart:io';
import 'dart:scalarlist';
import 'dart:uri';

import 'base_request.dart';
import 'request.dart';
import 'response.dart';
import 'streamed_response.dart';
import 'utils.dart';

/// The abstract base class for an HTTP client. This is a mixin-style class;
/// subclasses only need to implement [send] and maybe [close], and then they
/// get various convenience methods for free.
abstract class BaseClient {
  /// Sends an HTTP HEAD request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> head(url, {Map<String, String> headers}) =>
    _sendUnstreamed("HEAD", url, headers);

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> get(url, {Map<String, String> headers}) =>
    _sendUnstreamed("GET", url, headers);

  /// Sends an HTTP POST request with the given headers and fields to the given
  /// URL, which can be a [Uri] or a [String]. If any fields are specified, the
  /// content-type is automatically set to
  /// `"application/x-www-form-urlencoded"`.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> post(url,
      {Map<String, String> headers,
       Map<String, String> fields}) =>
    _sendUnstreamed("POST", url, headers, fields);

  /// Sends an HTTP PUT request with the given headers and fields to the given
  /// URL, which can be a [Uri] or a [String]. If any fields are specified, the
  /// content-type is automatically set to
  /// `"application/x-www-form-urlencoded"`.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> put(url,
      {Map<String, String> headers,
       Map<String, String> fields}) =>
    _sendUnstreamed("PUT", url, headers, fields);

  /// Sends an HTTP DELETE request with the given headers to the given URL,
  /// which can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> delete(url, {Map<String, String> headers}) =>
    _sendUnstreamed("DELETE", url, headers);

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String], and returns a Future that completes to the
  /// body of the response as a String.
  ///
  /// The Future will emit an [HttpException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<String> read(url, {Map<String, String> headers}) {
    return get(url, headers: headers).transform((response) {
      _checkResponseSuccess(url, response);
      return response.body;
    });
  }

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String], and returns a Future that completes to the
  /// body of the response as a list of bytes.
  ///
  /// The Future will emit an [HttpException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<Uint8List> readBytes(url, {Map<String, String> headers}) {
    return get(url, headers: headers).transform((response) {
      _checkResponseSuccess(url, response);
      return response.bodyBytes;
    });
  }

  /// Sends an HTTP request and asynchronously returns the response.
  ///
  /// Implementers should call [BaseRequest.finalize] to get the body of the
  /// request as an [InputStream]. They shouldn't make any assumptions about the
  /// state of the stream; it could have data written to it asynchronously at a
  /// later point, or it could already be closed when it's returned.
  Future<StreamedResponse> send(BaseRequest request);

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<Response> _sendUnstreamed(
      String method, url, Map<String, String> headers,
      [Map<String, String> fields]) {
    // Wrap everything in a Future block so that synchronous validation errors
    // are passed asynchronously through the Future chain.
    return async.chain((_) {
      if (url is String) url = new Uri.fromString(url);
      var request = new Request(method, url);

      if (headers != null) mapAddAll(request.headers, headers);
      if (fields != null && !fields.isEmpty) request.bodyFields = fields;

      return send(request);
    }).chain(Response.fromStream);
  }

  /// Throws an error if [response] is not successful.
  void _checkResponseSuccess(url, Response response) {
    if (response.statusCode < 400) return;
    var message = "Request to $url failed with status ${response.statusCode}";
    if (response.reasonPhrase != null) {
      message = "$message: ${response.reasonPhrase}";
    }
    throw new HttpException("$message.");
  }

  /// Closes the client and cleans up any resources associated with it. It's
  /// important to close each client when it's done being used; failing to do so
  /// can cause the Dart process to hang.
  void close() {}
}
