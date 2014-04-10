// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A Shelf adapter for handling [HttpRequest] objects from `dart:io`.
///
/// One can provide an instance of [HttpServer] as the `requests` parameter in
/// [serveRequests].
library shelf.io;

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import 'shelf.dart';
import 'src/util.dart';

/// Starts an [HttpServer] that listens on the specified [address] and
/// [port] and sends requests to [handler].
///
/// See the documentation for [HttpServer.bind] for more details on [address],
/// [port], and [backlog].
Future<HttpServer> serve(Handler handler, address, int port,
    {int backlog}) {
  if (backlog == null) backlog = 0;
  return HttpServer.bind(address, port, backlog: backlog).then((server) {
    serveRequests(server, handler);
    return server;
  });
}

/// Serve a [Stream] of [HttpRequest]s.
///
/// [HttpServer] implements [Stream<HttpRequest>] so it can be passed directly
/// to [serveRequests].
void serveRequests(Stream<HttpRequest> requests, Handler handler) {
  requests.listen((request) => handleRequest(request, handler));
}

/// Uses [handler] to handle [request].
///
/// Returns a [Future] which completes when the request has been handled.
Future handleRequest(HttpRequest request, Handler handler) {
  var shelfRequest = _fromHttpRequest(request);

  return syncFuture(() => handler(shelfRequest))
      .catchError((error, stackTrace) {
    var chain = new Chain.current();
    if (stackTrace != null) {
      chain = new Chain.forTrace(stackTrace)
          .foldFrames((frame) => frame.isCore || frame.package == 'shelf')
          .terse;
    }

    return _logError('Error thrown by handler\n$error\n$chain');
  }).then((response) {
    if (response == null) {
      response = _logError('null response from handler');
    }

    return _writeResponse(response, request.response);
  });
}

/// Creates a new [Request] from the provided [HttpRequest].
Request _fromHttpRequest(HttpRequest request) {
  var headers = {};
  request.headers.forEach((k, v) {
    // Multiple header values are joined with commas.
    // See http://tools.ietf.org/html/draft-ietf-httpbis-p1-messaging-21#page-22
    headers[k] = v.join(',');
  });

  return new Request(request.method, request.requestedUri,
      protocolVersion: request.protocolVersion, headers: headers,
      body: request);
}

Future _writeResponse(Response response, HttpResponse httpResponse) {
  httpResponse.statusCode = response.statusCode;

  response.headers.forEach((header, value) {
    if (value == null) return;
    httpResponse.headers.set(header, value);
  });

  if (response.headers[HttpHeaders.SERVER] == null) {
    var value = httpResponse.headers.value(HttpHeaders.SERVER);
    httpResponse.headers.set(HttpHeaders.SERVER, '$value with Shelf');
  }
  return httpResponse.addStream(response.read())
      .then((_) => httpResponse.close());
}

// TODO(kevmoo) A developer mode is needed to include error info in response
// TODO(kevmoo) Make error output plugable. stderr, logging, etc
Response _logError(String message) {
  stderr.writeln('ERROR - ${new DateTime.now()}');
  stderr.writeln(message);
  return new Response.internalServerError();
}
