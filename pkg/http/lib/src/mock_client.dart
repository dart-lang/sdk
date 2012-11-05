// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_client;

import 'dart:io';

import 'base_client.dart';
import 'base_request.dart';
import 'request.dart';
import 'response.dart';
import 'streamed_response.dart';
import 'utils.dart';

// TODO(nweiz): once Dart has some sort of Rack- or WSGI-like standard for
// server APIs, MockClient should conform to it.

/// A mock HTTP client designed for use when testing code that uses
/// [BaseClient]. This client allows you to define a handler callback for all
/// requests that are made through it so that you can mock a server without
/// having to send real HTTP requests.
class MockClient extends BaseClient {
  /// The handler for receiving [StreamedRequest]s and sending
  /// [StreamedResponse]s.
  final MockClientStreamHandler _handler;

  /// Creates a [MockClient] with a handler that receives [Request]s and sends
  /// [Response]s.
  MockClient(MockClientHandler fn)
    : this.streaming((baseRequest, bodyStream) {
      return consumeInputStream(bodyStream).chain((bodyBytes) {
        var request = new Request(baseRequest.method, baseRequest.url);
        request.persistentConnection = baseRequest.persistentConnection;
        request.followRedirects = baseRequest.followRedirects;
        request.maxRedirects = baseRequest.maxRedirects;
        mapAddAll(request.headers, baseRequest.headers);
        request.bodyBytes = bodyBytes;
        request.finalize();

        return fn(request);
      }).transform((response) {
        var stream = new ListInputStream();
        stream.write(response.bodyBytes);
        stream.markEndOfStream();

        return new StreamedResponse(
            stream,
            response.statusCode,
            response.contentLength,
            headers: response.headers,
            isRedirect: response.isRedirect,
            persistentConnection: response.persistentConnection,
            reasonPhrase: response.reasonPhrase);
      });
    });

  /// Creates a [MockClient] with a handler that receives [StreamedRequest]s and
  /// sends [StreamedResponse]s.
  MockClient.streaming(MockClientStreamHandler this._handler);

  /// Sends a request.
  Future<StreamedResponse> send(BaseRequest request) {
    var bodyStream = request.finalize();
    return async.chain((_) => _handler(request, bodyStream));
  }
}

/// A handler function that receives [StreamedRequest]s and sends
/// [StreamedResponse]s. Note that [request] will be finalized.
typedef Future<StreamedResponse> MockClientStreamHandler(
    BaseRequest request, InputStream bodyStream);

/// A handler function that receives [Request]s and sends [Response]s. Note that
/// [request] will be finalized.
typedef Future<Response> MockClientHandler(Request request);
