// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library client;

import 'dart:io';

import 'base_client.dart';
import 'base_request.dart';
import 'io_client.dart';
import 'streamed_response.dart';
import 'utils.dart';

/// The interface for HTTP clients that take care of maintaining persistent
/// connections across multiple requests to the same server. If you only need to
/// send a single request, it's usually easier to use [head], [get], [post],
/// [put], or [delete] instead.
///
/// When creating an HTTP client class with additional functionality, you must
/// extend [BaseClient] rather than [Client]. In most cases, you can wrap
/// another instance of [Client] and add functionality on top of that. This
/// allows all classes implementing [Client] to be mutually composable.
abstract class Client {
  /// Creates a new Client using the default implementation. This implementation
  /// uses an underlying `dart:io` [HttpClient] to make requests.
  factory Client() => new IOClient();

  /// Sends an HTTP HEAD request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> head(url, {Map<String, String> headers});

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> get(url, {Map<String, String> headers});

  /// Sends an HTTP POST request with the given headers and fields to the given
  /// URL, which can be a [Uri] or a [String]. If any fields are specified, the
  /// content-type is automatically set to
  /// `"application/x-www-form-urlencoded"`.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> post(url,
      {Map<String, String> headers,
       Map<String, String> fields});

  /// Sends an HTTP PUT request with the given headers and fields to the given
  /// URL, which can be a [Uri] or a [String]. If any fields are specified, the
  /// content-type is automatically set to
  /// `"application/x-www-form-urlencoded"`.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> put(url,
      {Map<String, String> headers,
       Map<String, String> fields});

  /// Sends an HTTP DELETE request with the given headers to the given URL,
  /// which can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> delete(url, {Map<String, String> headers});

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String], and returns a Future that completes to the
  /// body of the response as a String.
  ///
  /// The Future will emit an [HttpException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<String> read(url, {Map<String, String> headers});

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String], and returns a Future that completes to the
  /// body of the response as a list of bytes.
  ///
  /// The Future will emit an [HttpException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<Uint8List> readBytes(url, {Map<String, String> headers});

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request);

  /// Closes the client and cleans up any resources associated with it. It's
  /// important to close each client when it's done being used; failing to do so
  /// can cause the Dart process to hang.
  void close();
}
