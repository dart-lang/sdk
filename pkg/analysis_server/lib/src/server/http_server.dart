// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';

/**
 * Instances of the class [AbstractGetHandler] handle GET requests.
 */
abstract class AbstractGetHandler {
  /**
   * Handle a GET request received by the HTTP server.
   */
  void handleGetRequest(HttpRequest request);
}

/**
 * An [AbstractGetHandler] that always returns the given error message.
 */
class ErrorGetHandler extends AbstractGetHandler {
  final String message;

  ErrorGetHandler(this.message);

  @override
  void handleGetRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.contentType = ContentType.TEXT;
    response.write(message);
    response.close();
  }
}

/**
 * Instances of the class [HttpServer] implement a simple HTTP server. The
 * server:
 *
 * - listens for an UPGRADE request in order to start an analysis server
 * - serves diagnostic information as html pages
 */
class HttpAnalysisServer {
  /**
   * Number of lines of print output to capture.
   */
  static const int MAX_PRINT_BUFFER_LENGTH = 1000;

  /**
   * An object that can handle either a WebSocket connection or a connection
   * to the client over stdio.
   */
  SocketServer socketServer;

  /**
   * An object that can handle GET requests.
   */
  AbstractGetHandler getHandler;

  /**
   * Future that is completed with the HTTP server once it is running.
   */
  Future<HttpServer> _serverFuture;

  /**
   * Last PRINT_BUFFER_LENGTH lines printed.
   */
  List<String> _printBuffer = <String>[];

  /**
   * Initialize a newly created HTTP server.
   */
  HttpAnalysisServer(this.socketServer);

  /**
   * Return the port this server is bound to.
   */
  Future<int> get boundPort async => (await _serverFuture)?.port;

  void close() {
    _serverFuture.then((HttpServer server) {
      server.close();
    });
  }

  /**
   * Record that the given line was printed out by the analysis server.
   */
  void recordPrint(String line) {
    _printBuffer.add(line);
    if (_printBuffer.length > MAX_PRINT_BUFFER_LENGTH) {
      _printBuffer.removeRange(
          0, _printBuffer.length - MAX_PRINT_BUFFER_LENGTH);
    }
  }

  /**
   * Begin serving HTTP requests over the given port.
   */
  Future<int> serveHttp([int initialPort]) async {
    if (_serverFuture != null) {
      return boundPort;
    }

    try {
      _serverFuture =
          HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, initialPort ?? 0);

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

  /**
   * Handle a GET request received by the HTTP server.
   */
  Future<Null> _handleGetRequest(HttpRequest request) async {
    if (getHandler == null) {
      if (socketServer.analysisServer.options.enableNewAnalysisDriver) {
        getHandler = new DiagnosticsSite(socketServer, _printBuffer);
      } else {
        getHandler = new ErrorGetHandler(
            'Diagnostics only supported for the new analysis driver.');
      }
    }
    await getHandler.handleGetRequest(request);
  }

  /**
   * Attach a listener to a newly created HTTP server.
   */
  void _handleServer(HttpServer httpServer) {
    httpServer.listen((HttpRequest request) async {
      List<String> updateValues = request.headers[HttpHeaders.UPGRADE];
      if (request.method == 'GET') {
        await _handleGetRequest(request);
      } else if (updateValues != null &&
          updateValues.indexOf('websocket') >= 0) {
        // We no longer support serving analysis server communications over
        // WebSocket connections.
        HttpResponse response = request.response;
        response.statusCode = HttpStatus.NOT_FOUND;
        response.headers.contentType = ContentType.TEXT;
        response.write(
            'WebSocket connections not supported (${request.uri.path}).');
        response.close();
      } else {
        _returnUnknownRequest(request);
      }
    });
  }

  /**
   * Return an error in response to an unrecognized request received by the HTTP
   * server.
   */
  void _returnUnknownRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.contentType = ContentType.TEXT;
    response.write('Not found');
    response.close();
  }
}
