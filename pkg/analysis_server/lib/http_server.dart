// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http.server;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/channel/web_socket_channel.dart';
import 'package:analysis_server/src/get_handler.dart';
import 'package:analysis_server/src/socket_server.dart';

/**
 * Instances of the class [HttpServer] implement a simple HTTP server. The
 * primary responsibility of this server is to listen for an UPGRADE request and
 * to start an analysis server.
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
  GetHandler getHandler;

  /**
   * Initialize a newly created HTTP server.
   */
  HttpAnalysisServer(this.socketServer);

  /**
   * Future that is completed with the HTTP server once it is running.
   */
  Future<HttpServer> _server;

  /**
   * Last PRINT_BUFFER_LENGTH lines printed.
   */
  List<String> _printBuffer = <String>[];

  /**
   * Attach a listener to a newly created HTTP server.
   */
  void _handleServer(HttpServer httServer) {
    httServer.listen((HttpRequest request) {
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
   * Handle a GET request received by the HTTP server.
   */
  void _handleGetRequest(HttpRequest request) {
    if (getHandler == null) {
      getHandler = new GetHandler(socketServer, _printBuffer);
    }
    getHandler.handleGetRequest(request);
  }

  /**
   * Handle an UPGRADE request received by the HTTP server by creating and
   * running an analysis server on a [WebSocket]-based communication channel.
   */
  void _handleWebSocket(WebSocket socket) {
    socketServer.createAnalysisServer(new WebSocketServerChannel(socket));
  }

  /**
   * Return an error in response to an unrecognized request received by the HTTP
   * server.
   */
  void _returnUnknownRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.add(HttpHeaders.CONTENT_TYPE, "text/plain");
    response.write('Not found');
    response.close();
  }

  /**
   * Begin serving HTTP requests over the given port.
   */
  void serveHttp(int port) {
    _server = HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port);
    _server.then(_handleServer);
  }

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
      _printBuffer.removeRange(0,
          _printBuffer.length - MAX_PRINT_BUFFER_LENGTH);
    }
  }
}
