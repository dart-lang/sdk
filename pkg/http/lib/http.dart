// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A composable, [Future]-based library for making HTTP requests.
///
/// The easiest way to use this library is via the top-level functions. They
/// allow you to make individual HTTP requests with minimal hassle:
///
///     import 'package:http/http.dart' as http;
///
///     var url = "http://example.com/whatsit/create";
///     http.post(url, fields: {"name": "doodle", "color": "blue"})
///         .then((response) {
///       print("Response status: ${response.statusCode}");
///       print("Response body: ${response.body}");
///     });
///
///     http.read("http://example.com/foobar.txt").then(print);
///
/// If you're making multiple requests to the same server, you can keep open a
/// persistent connection by using a [Client] rather than making one-off
/// requests. If you do this, make sure to close the client when you're done:
///
///     var client = new http.Client();
///     client.post(
///         "http://example.com/whatsit/create",
///         fields: {"name": "doodle", "color": "blue"})
///       .chain((response) => client.get(response.bodyFields['uri']))
///       .transform((response) => print(response.body))
///       .onComplete((_) => client.close());
///
/// You can also exert more fine-grained control over your requests and
/// responses by creating [Request] or [StreamedRequest] objects yourself and
/// passing them to [Client.send].
///
/// This package is designed to be composable. This makes it easy for external
/// libraries to work with one another to add behavior to it. Libraries wishing
/// to add behavior should create a subclass of [BaseClient] that wraps another
/// [BaseClient] and adds the desired behavior:
///
///     class UserAgentClient extends http.BaseClient {
///       final String userAgent;
///       final HttpClient _inner;
///
///       UserAgentClient(this.userAgent, this._inner);
///
///       Future<StreamedResponse> send(BaseRequest request) {
///         request.headers[HttpHeaders.USER_AGENT] = userAgent;
///         return _inner.send(request);
///       }
///     }
///
/// In turn, libraries using [Client] should take a [BaseClient] so that the
/// decorated clients can be used transparently.

library http;

import 'dart:scalarlist';
import 'dart:uri';

import 'src/client.dart';
import 'src/response.dart';

export 'src/base_client.dart';
export 'src/base_request.dart';
export 'src/base_response.dart';
export 'src/curl_client.dart';
export 'src/client.dart';
export 'src/multipart_file.dart';
export 'src/multipart_request.dart';
export 'src/request.dart';
export 'src/response.dart';
export 'src/streamed_request.dart';
export 'src/streamed_response.dart';

/// Sends an HTTP HEAD request with the given headers to the given URL, which
/// can be a [Uri] or a [String].
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> head(url, {Map<String, String> headers}) =>
  _withClient((client) => client.head(url, headers: headers));

/// Sends an HTTP GET request with the given headers to the given URL, which can
/// be a [Uri] or a [String].
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> get(url, {Map<String, String> headers}) =>
  _withClient((client) => client.get(url, headers: headers));

/// Sends an HTTP POST request with the given headers and fields to the given
/// URL, which an be a [Uri] or a [String]. If any fields are specified, the
/// content-type is automatically set to `"application/x-www-form-urlencoded"`.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> post(url,
    {Map<String, String> headers,
     Map<String, String> fields}) =>
  _withClient((client) => client.post(url, headers: headers, fields: fields));

/// Sends an HTTP POST request with the given headers and fields to the given
/// URL, which can be a [Uri] or a [String]. If any fields are specified, the
/// content-type is automatically set to `"application/x-www-form-urlencoded"`.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> put(url,
    {Map<String, String> headers,
     Map<String, String> fields}) =>
  _withClient((client) => client.put(url, headers: headers, fields: fields));

/// Sends an HTTP DELETE request with the given headers to the given URL, which
/// can be a [Uri] or a [String].
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> delete(url, {Map<String, String> headers}) =>
  _withClient((client) => client.delete(url, headers: headers));

/// Sends an HTTP GET request with the given headers to the given URL, which can
/// be a [Uri] or a [String], and returns a Future that completes to the body of
/// the response as a [String].
///
/// The Future will emit an [HttpException] if the response doesn't have a
/// success status code.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request and response, use [Request]
/// instead.
Future<String> read(url, {Map<String, String> headers}) =>
  _withClient((client) => client.read(url, headers: headers));

/// Sends an HTTP GET request with the given headers to the given URL, which can
/// be a [Uri] or a [String], and returns a Future that completes to the body of
/// the response as a list of bytes.
///
/// The Future will emit an [HttpException] if the response doesn't have a
/// success status code.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request and response, use [Request]
/// instead.
Future<Uint8List> readBytes(url, {Map<String, String> headers}) =>
  _withClient((client) => client.readBytes(url, headers: headers));

Future _withClient(Future fn(Client)) {
  var client = new Client();
  var future = fn(client);
  future.onComplete((_) => client.close());
  return future;
}
