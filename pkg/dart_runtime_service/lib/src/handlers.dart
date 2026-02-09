// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'clients.dart';

/// Creates [Middleware] responsible for logging the result of HTTP requests.
///
/// Note: this only outputs logs when the response is sent. Connections that
/// are upgraded to web socket or SSE connections successfully won't result in
/// logs being output until the connection is closed.
Middleware requestLoggingMiddleware() {
  final logger = Logger('RequestResult');
  return logRequests(
    logger: (message, isError) {
      isError ? logger.warning(message) : logger.info(message);
    },
  );
}

/// Creates [Middleware] responsible for verifying incoming requests have an
/// [authCode] in their path.
///
/// Connections without a matching [authCode] will be rejected.
Middleware authCodeVerificationMiddleware({required String authCode}) =>
    (Handler innerHandler) => (Request request) {
      final forbidden = Response.forbidden(
        'missing or invalid authentication code',
      );
      final logger = Logger('AuthCodeMiddleware');
      final pathSegments = request.url.pathSegments;
      logger.info(
        "Validating authentication code in path: '${request.url.path}'",
      );
      if (pathSegments.isEmpty) {
        logger.info('Empty path. Forbidden.');
        return forbidden;
      }
      final clientProvidedCode = pathSegments[0];
      if (clientProvidedCode != authCode) {
        logger.info(
          "Authentication code '$clientProvidedCode' does not match "
          "'$authCode'. Forbidden.",
        );
        return forbidden;
      }
      logger.info('Authentication code validated.');
      return innerHandler(request.change(path: clientProvidedCode));
    };

/// Creates a [Handler] for incoming web socket connections.
Handler webSocketClientHandler({required ClientManager clientManager}) =>
    webSocketHandler((WebSocketChannel ws, _) {
      // Note: the WebSocketChannel type below is needed for compatibility with
      // package:shelf_web_socket v2.
      final logger = Logger('WebSocketHandler');
      logger.info('New web socket connection. Creating $Client.');
      clientManager.addClient(ws.cast<String>());
    });

/// Creates a [Handler] for incoming SSE connections.
Handler sseClientHandler({
  required ClientManager clientManager,
  required String sseHandlerPath,
  required String? authCode,
}) {
  final logger = Logger('SSEClientHandler');
  // Give connections time to reestablish before considering them closed.
  // Required to reestablish connections killed by UberProxy.
  const sseKeepAlive = Duration(seconds: 30);

  final handler = SseHandler(
    Uri.parse(['', ?authCode, sseHandlerPath].join('/')),
    keepAlive: sseKeepAlive,
  );

  handler.connections.rest.listen((sseConnection) {
    logger.info('New SSE connection. Creating $Client.');
    clientManager.addClient(sseConnection);
  });

  return handler.handler;
}
