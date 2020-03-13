// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/edit/nnbd_migration/migration_state.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';

/// Instances of the class [AbstractGetHandler] handle GET requests.
abstract class AbstractGetHandler {
  /// Handle a GET request received by the HTTP server.
  Future<void> handleGetRequest(HttpRequest request);
}

/// Instances of the class [AbstractPostHandler] handle POST requests.
abstract class AbstractPostHandler {
  /// Handle a POST request received by the HTTP server.
  Future<void> handlePostRequest(HttpRequest request);
}

/// Instances of the class [HttpPreviewServer] implement a simple HTTP server
/// that serves up dartfix preview pages.
class HttpPreviewServer {
  /// The state of the migration being previewed.
  final MigrationState migrationState;

  /// The [PreviewSite] that can handle GET and POST requests.
  PreviewSite previewSite;

  /// Future that is completed with the HTTP server once it is running.
  Future<HttpServer> _serverFuture;

  // A function which allows the migration to be rerun.
  final Future<MigrationState> Function() rerunFunction;

  /// Initialize a newly created HTTP server.
  HttpPreviewServer(this.migrationState, this.rerunFunction);

  /// Return the port this server is bound to.
  Future<int> get boundPort async {
    return (await _serverFuture)?.port;
  }

  void close() {
    _serverFuture?.then((HttpServer server) {
      server.close();
    });
  }

  /// Begin serving HTTP requests over the given port.
  Future<int> serveHttp([int initialPort]) async {
    if (_serverFuture != null) {
      return boundPort;
    }

    try {
      _serverFuture =
          HttpServer.bind(InternetAddress.loopbackIPv4, initialPort ?? 0);

      HttpServer server = await _serverFuture;
      _handleServer(server);
      return server.port;
    } catch (ignore) {
      // If we can't bind to the specified port, don't remember the broken
      // server.
      _serverFuture = null;

      return null;
    }
  }

  /// Handle a GET request received by the HTTP server.
  Future<void> _handleGetRequest(HttpRequest request) async {
    previewSite ??= PreviewSite(migrationState, rerunFunction);
    await previewSite.handleGetRequest(request);
  }

  /// Handle a POST request received by the HTTP server.
  Future<void> _handlePostRequest(HttpRequest request) async {
    previewSite ??= PreviewSite(migrationState, rerunFunction);
    await previewSite.handlePostRequest(request);
  }

  /// Attach a listener to a newly created HTTP server.
  void _handleServer(HttpServer httpServer) {
    httpServer.listen((HttpRequest request) async {
      List<String> updateValues = request.headers[HttpHeaders.upgradeHeader];
      if (request.method == 'GET') {
        await _handleGetRequest(request);
      } else if (request.method == 'POST') {
        await _handlePostRequest(request);
      } else if (updateValues != null && updateValues.contains('websocket')) {
        // We do not support serving analysis server communications over
        // WebSocket connections.
        HttpResponse response = request.response;
        response.statusCode = HttpStatus.notFound;
        response.headers.contentType = ContentType.text;
        response.write(
            'WebSocket connections not supported (${request.uri.path}).');
        response.close();
      } else {
        _returnUnknownRequest(request);
      }
    });
  }

  /// Return an error in response to an unrecognized request received by the HTTP
  /// server.
  void _returnUnknownRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.notFound;
    response.headers.contentType = ContentType.text;
    response.write('Not found');
    response.close();
  }
}
