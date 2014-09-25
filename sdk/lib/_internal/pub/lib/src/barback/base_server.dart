// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.base_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

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
    shelf_io.serveRequests(_server, const shelf.Pipeline()
        .addMiddleware(shelf.createMiddleware(errorHandler: _handleError))
        .addHandler(handleRequest));
  }

  /// Closes this server.
  Future close() {
    return Future.wait([_server.close(), _resultsController.close()]);
  }

  /// Handles an HTTP request.
  handleRequest(shelf.Request request);

  /// Returns a 405 response to [request].
  shelf.Response methodNotAllowed(shelf.Request request) {
    logRequest(request, "405 Method Not Allowed");
    return new shelf.Response(405,
        body: "The ${request.method} method is not allowed for ${request.url}.",
        headers: {'Allow': 'GET, HEAD'});
  }

  /// Returns a 404 response to [request].
  ///
  /// If [asset] is given, it is the ID of the asset that couldn't be found.
  shelf.Response notFound(shelf.Request request, {String error,
      AssetId asset}) {
    logRequest(request, "Not Found");

    // TODO(rnystrom): Apply some styling to make it visually clear that this
    // error is coming from pub serve itself.
    var body = new StringBuffer();
    body.writeln("""
        <!DOCTYPE html>
        <head>
        <title>404 Not Found</title>
        </head>
        <body>
        <h1>404 Not Found</h1>""");

    if (asset != null) {
      body.writeln("<p>Could not find asset "
          "<code>${HTML_ESCAPE.convert(asset.path)}</code> in package "
          "<code>${HTML_ESCAPE.convert(asset.package)}</code>.</p>");
    }

    if (error != null) {
      body.writeln("<p>Error: ${HTML_ESCAPE.convert(error)}</p>");
    }

    body.writeln("""
        </body>""");

    // Force a UTF-8 encoding so that error messages in non-English locales are
    // sent correctly.
    return new shelf.Response.notFound(body.toString(),
        headers: {'Content-Type': 'text/html; charset=utf-8'});
  }

  /// Log [message] at [log.Level.FINE] with metadata about [request].
  void logRequest(shelf.Request request, String message) =>
    log.fine("$this ${request.method} ${request.url}\n$message");

  /// Adds [result] to the server's [results] stream.
  void addResult(T result) {
    _resultsController.add(result);
  }

  /// Adds [error] as an error to the server's [results] stream.
  void addError(error, [stackTrace]) {
    _resultsController.addError(error, stackTrace);
  }

  /// Handles an error thrown by [handleRequest].
  _handleError(error, StackTrace stackTrace) {
    _resultsController.addError(error, stackTrace);
    close();
    return new shelf.Response.internalServerError();
  }
}
