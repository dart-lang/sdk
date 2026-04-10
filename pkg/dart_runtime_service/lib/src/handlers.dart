// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'clients.dart';
import 'dart_runtime_service.dart';
import 'dart_runtime_service_backend.dart';

/// Return from a handler to indicate that the request can't be handled by the
/// current handler.
Response notHandledByHandler() => Response.notFound('');

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

Middleware originCheckMiddleware({required DartRuntimeService frontend}) =>
    (Handler innerHandler) => (Request request) {
      // First check the web-socket specific origin.
      var origins = request.headers['Sec-WebSocket-Origin'];
      // Fall back to the general Origin field.
      origins ??= request.headers['Origin'];
      if (origins == null) {
        // No origin sent. This is a non-browser client or a same-origin
        // request.
        return innerHandler(request);
      }

      bool isAllowedOrigin(String origin) {
        Uri uri;
        try {
          uri = Uri.parse(origin);
        } catch (_) {
          return false;
        }

        // Explicitly add localhost and 127.0.0.1 on any port (necessary for
        // adb port forwarding).
        if ((uri.host == 'localhost') ||
            (uri.host == InternetAddress.loopbackIPv6.address) ||
            (uri.host == InternetAddress.loopbackIPv4.address)) {
          return true;
        }

        final serverUri = frontend.uri;
        if (uri.port == serverUri.port && uri.host == serverUri.host) {
          return true;
        }

        return false;
      }

      for (final origin in origins.split(',')) {
        if (isAllowedOrigin(origin)) {
          return innerHandler(request);
        }
      }
      return Response.forbidden('forbidden origin');
    };

/// Creates a [Handler] responsible for processing HTTP requests.
///
/// If [frontend] has a [DartRuntimeServiceBackend] with a
/// [DartRuntimeServiceBackend.httpHandler] override, the backend's handler
/// will be invoked first. Otherwise, the HTTP request is treated as a JSON-RPC
/// invocation.
Handler httpRequestHandler({required DartRuntimeService frontend}) =>
    (Request request) async {
      final logger = Logger('HttpRequestHandler');
      final method = request.url.pathSegments.firstOrNull ?? '';
      final params = request.url.queryParameters;
      logger.info('(${request.method}) ${request.url}');

      try {
        final backendResult = await frontend.backend.httpHandler(request);
        if (backendResult != null) {
          logger.info(
            'Returning backend provided result: ${backendResult.statusCode}',
          );
          return backendResult;
        }

        final httpClient = StreamChannelController<String>(sync: true);
        try {
          frontend.addArtificialClient(
            connection: httpClient.foreign,
            name: 'HTTP request',
          );

          final jsonRpcClient = json_rpc.Client(httpClient.local);
          unawaited(jsonRpcClient.listen());
          final result = await jsonRpcClient.sendRequest(method, params);
          logger.info('HTTP result: $result');
          return Response.ok(
            json.encode({'result': result}),
            headers: {
              // We closed the connection for bad origins earlier.
              'Access-Control-Allow-Origin': '*',
              'content-type': ContentType.json.mimeType,
            },
          );
        } finally {
          await Future.wait([
            httpClient.foreign.sink.close(),
            httpClient.local.sink.close(),
          ]);
        }
      } on json_rpc.RpcException catch (e) {
        return Response.ok(json.encode(e.serialize(method)));
      } catch (e) {
        return Response.badRequest(body: e.toString());
      }
    };

/// Creates a [Handler] for incoming web socket connections.
Handler webSocketClientHandler({required ClientManager clientManager}) {
  final logger = Logger('WebSocketHandler');
  // Note: the WebSocketChannel type below is needed for compatibility with
  // package:shelf_web_socket v2.
  final handler = webSocketHandler((WebSocketChannel ws, _) {
    logger.info('New web socket connection. Creating $Client.');
    clientManager.addClient(connection: ws.cast<Object?>());
  });

  return (request) {
    if (!request.isWebSocketUpgradeRequest) {
      return notHandledByHandler();
    }
    if (!clientManager.acceptNewConnections) {
      logger.info(
        'New connections not accepted. Rejecting web socket connection.',
      );
      final redirectUri = clientManager.redirectUri;
      if (redirectUri != null) {
        return Response.seeOther(clientManager.redirectUri.toString());
      }
      return Response.forbidden(
        'New connections not accepted. Rejecting web socket connection.',
      );
    }
    return handler(request);
  };
}

/// Creates a [Handler] for incoming SSE connections.
Handler sseClientHandler({
  required ClientManager clientManager,
  required String sseHandlerPath,
  required String? authCode,
}) {
  // Give connections time to reestablish before considering them closed.
  // Required to reestablish connections killed by UberProxy.
  const sseKeepAlive = Duration(seconds: 30);

  final handler = SseHandler(
    Uri.parse(['', ?authCode, sseHandlerPath].join('/')),
    keepAlive: sseKeepAlive,
  );

  final logger = Logger('SSEClientHandler');

  return (request) {
    if (!clientManager.acceptNewConnections && request.isSSEConnectionRequest) {
      logger.info('New connections not accepted. Rejecting SSE connection.');
      final redirectUri = clientManager.redirectUri;
      if (redirectUri != null) {
        return Response.seeOther(clientManager.redirectUri.toString());
      }
      return Response.forbidden(
        'New connections not accepted. Rejecting SSE connection.',
      );
    }

    handler.connections.rest.listen((sseConnection) {
      logger.info('New SSE connection. Creating $Client.');
      clientManager.addClient(connection: sseConnection);
    });

    return handler.handler(request);
  };
}

/// Adds checks for specific headers to determine if a [Request] is attempting
/// to establish a web socket or SSE connection.
extension on Request {
  bool get isWebSocketUpgradeRequest =>
      headers.containsKey('Sec-WebSocket-Key');

  bool get isSSEConnectionRequest =>
      headers['accept'] == 'text/event-stream' && method == 'GET';
}
