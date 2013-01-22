// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io_client;

import 'dart:async';
import 'dart:io';

import 'base_client.dart';
import 'base_request.dart';
import 'streamed_response.dart';
import 'utils.dart';

/// A `dart:io`-based HTTP client. This is the default client.
class IOClient extends BaseClient {
  /// The underlying `dart:io` HTTP client.
  HttpClient _inner;

  /// Creates a new HTTP client.
  IOClient() : _inner = new HttpClient();

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request) {
    var stream = request.finalize();

    var completer = new Completer<StreamedResponse>();
    var connection = _inner.openUrl(request.method, request.url);
    bool completed = false;
    connection.followRedirects = request.followRedirects;
    connection.maxRedirects = request.maxRedirects;
    connection.onError = (e) {
      async.then((_) {
        // TODO(nweiz): issue 4974 means that any errors that appear in the
        // onRequest or onResponse callbacks get passed to onError. If the
        // completer has already fired, we want to re-throw those exceptions
        // to the top level so that they aren't silently ignored.
        if (completed) throw e;

        completed = true;
        completer.completeError(e);
      });
    };

    var pipeCompleter = new Completer();
    connection.onRequest = (underlyingRequest) {
      underlyingRequest.contentLength = request.contentLength;
      underlyingRequest.persistentConnection = request.persistentConnection;
      request.headers.forEach((name, value) {
        underlyingRequest.headers.set(name, value);
      });

      chainToCompleter(
          stream.pipe(wrapOutputStream(underlyingRequest.outputStream)),
          pipeCompleter);
    };

    connection.onResponse = (response) {
      var headers = {};
      response.headers.forEach((key, value) => headers[key] = value);

      if (completed) return;

      completed = true;
      completer.complete(new StreamedResponse(
          wrapInputStream(response.inputStream),
          response.statusCode,
          response.contentLength,
          request: request,
          headers: headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase));
    };

    return Future.wait([
      completer.future,
      pipeCompleter.future
    ]).then((values) => values.first);
  }

  /// Closes the client. This terminates all active connections. If a client
  /// remains unclosed, the Dart process may not terminate.
  void close() {
    if (_inner != null) _inner.shutdown(force: true);
    _inner = null;
  }
}
