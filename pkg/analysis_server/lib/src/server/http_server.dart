// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/channel/web_socket_channel.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/get_handler.dart';
import 'package:analysis_server/src/status/get_handler2.dart';

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
  Future<HttpServer> _server;

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
  Future<int> get boundPort async => (await _server)?.port;

  void close() {
    _server.then((HttpServer server) {
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
    if (_server != null) {
      return boundPort;
    }

    try {
      _server =
          HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, initialPort ?? 0);
      HttpServer server = await _server;
      _handleServer(server);
      return server.port;
    } catch (ignore) {
      return null;
    }
  }

  /**
   * Handle a GET request received by the HTTP server.
   */
  void _handleGetRequest(HttpRequest request) {
    if (getHandler == null) {
      if (socketServer.analysisServer.options.enableNewAnalysisDriver) {
        getHandler = new GetHandler2(socketServer, _printBuffer);
      } else {
        getHandler = new GetHandler(socketServer, _printBuffer);
      }
    }
    getHandler.handleGetRequest(request);
  }

  /**
   * Attach a listener to a newly created HTTP server.
   */
  void _handleServer(HttpServer httpServer) {
    httpServer.listen((HttpRequest request) {
      List<String> updateValues = request.headers[HttpHeaders.UPGRADE];
      if (updateValues != null && updateValues.indexOf('websocket') >= 0) {
        WebSocketTransformer.upgrade(request).then((WebSocket websocket) {
          _handleWebSocket(websocket);
        });
      } else if (request.method == 'GET') {
        _handleGetRequest(request);
      } else {
        _returnUnknownRequest(request);
      }
    });
  }

  /**
   * Handle an UPGRADE request received by the HTTP server by creating and
   * running an analysis server on a [WebSocket]-based communication channel.
   */
  void _handleWebSocket(WebSocket socket) {
    // TODO(devoncarew): This serves the analysis server over a websocket
    // connection for historical reasons (and should probably be removed).
    socketServer.createAnalysisServer(new WebSocketServerChannel(
        socket, socketServer.instrumentationService));
  }

  /**
   * Return an error in response to an unrecognized request received by the HTTP
   * server.
   */
  void _returnUnknownRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.contentType =
        new ContentType("text", "plain", charset: "utf-8");
    response.write('Not found');
    response.close();
  }
}
