// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.admin_server;

import 'dart:async';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../io.dart';
import '../log.dart' as log;
import 'asset_environment.dart';
import 'base_server.dart';
import 'web_socket_api.dart';

/// The web admin interface to pub serve.
// TODO(rnystrom): Currently this just provides access to the Web Socket API.
// See #16954.
class AdminServer extends BaseServer {
  /// All currently open [WebSocket] connections.
  final _webSockets = new Set<CompatibleWebSocket>();

  shelf.Handler _handler;

  /// Creates a new server and binds it to [port] of [host].
  static Future<AdminServer> bind(AssetEnvironment environment,
      String host, int port) {
    return bindServer(host, port).then((server) {
      log.fine('Bound admin server to $host:$port.');
      return new AdminServer._(environment, server);
    });
  }

  AdminServer._(AssetEnvironment environment, HttpServer server)
      : super(environment, server) {
    _handler = new shelf.Cascade()
        .add(webSocketHandler(_handleWebSocket))
        .add(_handleHttp).handler;
  }

  /// Closes the server and all Web Socket connections.
  Future close() {
    var futures = [super.close()];
    futures.addAll(_webSockets.map((socket) => socket.close()));
    return Future.wait(futures);
  }

  handleRequest(shelf.Request request) => _handler(request);

  /// Handles an HTTP request.
  _handleHttp(shelf.Request request) {
    // TODO(rnystrom): Actually respond to requests once there is an admin
    // interface. See #16954.
    logRequest(request, "501 Not Implemented");
    return new shelf.Response(501,
        body: "Currently this server only accepts Web Socket connections.");
  }

  /// Creates a web socket for [request] which should be an upgrade request.
  void _handleWebSocket(CompatibleWebSocket socket) {
    _webSockets.add(socket);
    var api = new WebSocketApi(socket, environment);
    api.listen()
        .whenComplete(() => _webSockets.remove(api))
        .catchError(addError);
  }
}
