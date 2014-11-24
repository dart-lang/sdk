// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A Shelf adapter for handling [HttpRequest] objects from `dart:io`.
///
/// One can provide an instance of [HttpServer] as the `requests` parameter in
/// [serveRequests].
///
/// The `dart:io` adapter supports request hijacking; see [Request.hijack].
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
///
/// Errors thrown by [handler] while serving a request will be printed to the
/// console and cause a 500 response with no body. Errors thrown asynchronously
/// by [handler] will be printed to the console or, if there's an active error
/// zone, passed to that zone.
void serveRequests(Stream<HttpRequest> requests, Handler handler) {
  catchTopLevelErrors(() {
    requests.listen((request) => handleRequest(request, handler));
  }, (error, stackTrace) {
    _logError('Asynchronous error\n$error', stackTrace);
  });
}

/// Uses [handler] to handle [request].
///
/// Returns a [Future] which completes when the request has been handled.
Future handleRequest(HttpRequest request, Handler handler) {
  var shelfRequest;
  try {
    shelfRequest = _fromHttpRequest(request);
  } catch (error, stackTrace) {
    var response = _logError('Error parsing request.\n$error', stackTrace);
    return _writeResponse(response, request.response);
  }

  // TODO(nweiz): abstract out hijack handling to make it easier to implement an
  // adapter.
  return syncFuture(() => handler(shelfRequest))
      .catchError((error, stackTrace) {
    if (error is HijackException) {
      // A HijackException should bypass the response-writing logic entirely.
      if (!shelfRequest.canHijack) throw error;

      // If the request wasn't hijacked, we shouldn't be seeing this exception.
      return _logError(
          "Caught HijackException, but the request wasn't hijacked.",
          stackTrace);
    }

    return _logError('Error thrown by handler.\n$error', stackTrace);
  }).then((response) {
    if (response == null) {
      response = _logError('null response from handler.');
    } else if (!shelfRequest.canHijack) {
      var message = new StringBuffer()
          ..writeln("Got a response for hijacked request "
              "${shelfRequest.method} ${shelfRequest.requestedUri}:")
          ..writeln(response.statusCode);
      response.headers.forEach((key, value) =>
          message.writeln("${key}: ${value}"));
      throw new Exception(message.toString().trim());
    }

    return _writeResponse(response, request.response);
  }).catchError((error, stackTrace) {
    // Ignore HijackExceptions.
    if (error is! HijackException) throw error;
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

  onHijack(callback) {
    return request.response.detachSocket(writeHeaders: false)
        .then((socket) => callback(socket, socket));
  }

  return new Request(request.method, request.requestedUri,
      protocolVersion: request.protocolVersion, headers: headers,
      body: request, onHijack: onHijack);
}

Future _writeResponse(Response response, HttpResponse httpResponse) {
  httpResponse.statusCode = response.statusCode;

  response.headers.forEach((header, value) {
    if (value == null) return;
    httpResponse.headers.set(header, value);
  });

  if (!response.headers.containsKey(HttpHeaders.SERVER)) {
    httpResponse.headers.set(HttpHeaders.SERVER, 'dart:io with Shelf');
  }

  if (!response.headers.containsKey(HttpHeaders.DATE)) {
    httpResponse.headers.date = new DateTime.now().toUtc();
  }

  return httpResponse.addStream(response.read())
      .then((_) => httpResponse.close());
}

// TODO(kevmoo) A developer mode is needed to include error info in response
// TODO(kevmoo) Make error output plugable. stderr, logging, etc
Response _logError(String message, [StackTrace stackTrace]) {
  var chain = new Chain.current();
  if (stackTrace != null) {
    chain = new Chain.forTrace(stackTrace);
  }
  chain = chain
      .foldFrames((frame) => frame.isCore || frame.package == 'shelf')
      .terse;

  stderr.writeln('ERROR - ${new DateTime.now()}');
  stderr.writeln(message);
  stderr.writeln(chain);
  return new Response.internalServerError();
}
