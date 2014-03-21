// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.admin_server;

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import '../log.dart' as log;
import 'base_server.dart';
import 'build_environment.dart';
import 'web_socket_api.dart';

/// The web admin interface to pub serve.
// TODO(rnystrom): Currently this just provides access to the Web Socket API.
// See #16954.
class AdminServer extends BaseServer {
  /// All currently open [WebSocket] connections.
  final _webSockets = new Set<WebSocket>();

  /// Creates a new server and binds it to [port] of [host].
  static Future<AdminServer> bind(BuildEnvironment environment,
      String host, int port) {
    return Chain.track(HttpServer.bind(host, port)).then((server) {
      log.fine('Bound admin server to $host:$port.');
      return new AdminServer._(environment, server);
    });
  }

  AdminServer._(BuildEnvironment environment, HttpServer server)
      : super(environment, server);

  /// Closes the server and all Web Socket connections.
  Future close() {
    var futures = [super.close()];
    futures.addAll(_webSockets.map((socket) => socket.close()));
    return Future.wait(futures);
  }

  /// Handles an HTTP request.
  void handleRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      _handleWebSocket(request);
      return;
    }

    // TODO(rnystrom): Actually respond to requests once there is an admin
    // interface. See #16954.
    logRequest(request, "501 Not Implemented");
    request.response.headers.contentType =
        ContentType.parse("text/plain; charset=utf-8");

    request.response.statusCode = 501;
    request.response.reasonPhrase = "Not Implemented";
    request.response.write(
        "Currently this server only accepts Web Socket connections.");
    request.response.close();
  }

  /// Creates a web socket for [request] which should be an upgrade request.
  void _handleWebSocket(HttpRequest request) {
    Chain.track(WebSocketTransformer.upgrade(request)).then((socket) {
      _webSockets.add(socket);
      var api = new WebSocketApi(socket, environment);

      return api.listen().whenComplete(() => _webSockets.remove(api));
    }).catchError(addError);
  }
}
