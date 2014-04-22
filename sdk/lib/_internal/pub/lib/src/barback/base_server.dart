// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.base_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:stack_trace/stack_trace.dart';

import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';

/// Base class for a pub-controlled server.
abstract class BaseServer<T> {
  /// The [BuildEnvironment] being served.
  final AssetEnvironment environment;

  /// The underlying HTTP server.
  final HttpServer _server;

  /// The server's port.
  int get port => _server.port;

  /// The servers's address.
  InternetAddress get address => _server.address;

  /// The server's base URL.
  Uri get url => baseUrlForAddress(_server.address, port);

  /// The results of requests handled by the server.
  ///
  /// These can be used to provide visual feedback for the server's processing.
  /// This stream is also used to emit any programmatic errors that occur in the
  /// server.
  Stream<T> get results => _resultsController.stream;
  final _resultsController = new StreamController<T>.broadcast();

  BaseServer(this.environment, this._server) {
    Chain.track(_server).listen(handleRequest, onError: (error, stackTrace) {
      _resultsController.addError(error, stackTrace);
      close();
    });
  }

  /// Closes this server.
  Future close() {
    return Future.wait([_server.close(), _resultsController.close()]);
  }

  /// Handles an HTTP request.
  void handleRequest(HttpRequest request);

  /// Responds to [request] with a 405 response and closes it.
  void methodNotAllowed(HttpRequest request) {
    logRequest(request, "405 Method Not Allowed");
    request.response.statusCode = 405;
    request.response.reasonPhrase = "Method Not Allowed";
    request.response.headers.add('Allow', 'GET, HEAD');
    request.response.write(
        "The ${request.method} method is not allowed for ${request.uri}.");
    request.response.close();
  }

  /// Responds to [request] with a 404 response and closes it.
  ///
  /// If [asset] is given, it is the ID of the asset that couldn't be found.
  void notFound(HttpRequest request, {String error, AssetId asset}) {
    logRequest(request, "Not Found");

    // Force a UTF-8 encoding so that error messages in non-English locales are
    // sent correctly.
    request.response.headers.contentType =
        ContentType.parse("text/html; charset=utf-8");
    request.response.statusCode = 404;
    request.response.reasonPhrase = "Not Found";

    // TODO(rnystrom): Apply some styling to make it visually clear that this
    // error is coming from pub serve itself.
    request.response.writeln("""
        <!DOCTYPE html>
        <head>
        <title>404 Not Found</title>
        </head>
        <body>
        <h1>404 Not Found</h1>""");

    if (asset != null) {
      request.response.writeln("<p>Could not find asset "
          "<code>${HTML_ESCAPE.convert(asset.path)}</code> in package "
          "<code>${HTML_ESCAPE.convert(asset.package)}</code>.</p>");
    }

    if (error != null) {
      request.response.writeln("<p>Error: ${HTML_ESCAPE.convert(error)}</p>");
    }

    request.response.writeln("""
        </body>""");

    request.response.close();
  }

  /// Log [message] at [log.Level.FINE] with metadata about [request].
  void logRequest(HttpRequest request, String message) =>
    log.fine("$this ${request.method} ${request.uri}\n$message");

  /// Adds [result] to the server's [results] stream.
  void addResult(T result) {
    _resultsController.add(result);
  }

  /// Adds [error] as an error to the server's [results] stream.
  void addError(error, [stackTrace]) {
    _resultsController.addError(error, stackTrace);
  }
}
