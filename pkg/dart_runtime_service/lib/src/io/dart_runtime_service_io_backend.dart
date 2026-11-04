// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

import '../dart_runtime_service.dart';
import '../dart_runtime_service_backend.dart';
import '../dart_runtime_service_options.dart';
import '../exceptions.dart';
import '../isolate_manager.dart';
import 'handlers.dart';

/// Signature for a custom HTTP request handler that may return `null` to
/// fall through to the default handler cascade.
typedef OptionalHandler = FutureOr<shelf.Response?> Function(shelf.Request);

FutureOr<shelf.Response?> _defaultHttpHandler(shelf.Request _) => null;

/// Mixin for [DartRuntimeServiceBackend] implementations running on `dart:io`
/// that bind a local `package:shelf/shelf_io.dart` [HttpServer] and log to
/// [stderr].
mixin DartRuntimeServiceIoBackend<IM extends IsolateManager>
    on DartRuntimeServiceBackend<IM> {
  HttpServer? _server;

  /// A custom handler for handling HTTP requests.
  ///
  /// This handler is invoked before attempting to execute the HTTP request as
  /// an RPC invocation or performing a redirection to a developer tool (e.g.,
  /// DevTools). Returning null from the handler indicates that the request was
  /// not handled by the custom handler.
  OptionalHandler get httpHandler => _defaultHttpHandler;

  @override
  void writeLogRecord(LogRecord record) {
    stderr.writeln(record);
  }

  @override
  Future<Uri?> startServer({
    required DartRuntimeServiceOptions config,
    required Logger logger,
  }) async {
    final hostStr = config.host ?? InternetAddress.loopbackIPv4.host;
    var parsedHost = InternetAddress.tryParse(hostStr);
    if (parsedHost == null) {
      final addresses = await InternetAddress.lookup(hostStr);
      parsedHost = addresses.firstWhere(
        (a) => a.type == InternetAddressType.IPv4,
        orElse: () => addresses.first,
      );
    }
    final host = parsedHost;

    logger.info('Starting the Dart Runtime Service.');
    String? errorMessage;
    var port = config.port;
    Future<HttpServer?> start() async {
      try {
        logger.info('Attempting to bind to ${host.address}:$port');
        final handlers = _handlers(config: config, logger: logger);
        return await io.serve(handlers, host, port);
      } on SocketException catch (e) {
        if (config.enableServicePortFallback && port != 0) {
          logger.info(
            'Port $port is already in use. Retrying with a random port.',
          );
          port = 0;
          return await start();
        }
        var msg = e.message;
        if (e.osError != null) {
          msg += ' (${e.osError!.message})';
        }
        msg += ': ${e.address?.host}:${e.port}';
        errorMessage = msg;
        return null;
      }
    }

    final server = await runZonedGuarded(start, (e, st) {
      logger.warning('Asynchronous error: $e\n$st');
    });

    if (server == null) {
      final message =
          'Failed to start server: ${errorMessage ?? 'Unknown error'}';
      logger.warning(message);
      throw DartRuntimeServiceFailedToStartException(
        message: errorMessage ?? 'Unknown error',
      );
    }

    _server = server;
    return Uri(
      scheme: 'ws',
      host: host.address,
      port: server.port,
      path: frontend.authCode != null ? '/${frontend.authCode}' : '',
    );
  }

  @override
  Future<void> shutdownServer() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  shelf.Handler _handlers({
    required DartRuntimeServiceOptions config,
    required Logger logger,
  }) {
    logger.info('Building Shelf handlers.');
    final DartRuntimeService(:authCode, :clientManager) = frontend;
    var pipeline = const shelf.Pipeline();
    if (config.enableLogging) {
      pipeline = pipeline.addMiddleware(requestLoggingMiddleware());
    }
    if (!config.disableAuthCodes) {
      logger.info(
        'Authentication codes are enabled. Adding authentication '
        'code verification handler.',
      );
      pipeline = pipeline.addMiddleware(
        authCodeVerificationMiddleware(authCode: authCode!),
      );
    }

    if (!config.disableOriginCheck) {
      logger.info('Origin and Host checks are enabled.');
      pipeline = pipeline.addMiddleware(
        hostCheckMiddleware(frontend: frontend),
      );
      pipeline = pipeline.addMiddleware(
        originCheckMiddleware(frontend: frontend),
      );
    }

    var handlerCascade = shelf.Cascade();
    if (config.sseHandlerPath != null) {
      logger.info(
        'SSE connections are enabled. Adding SSE handler listening '
        'at ${config.sseHandlerPath}.',
      );
      handlerCascade = handlerCascade.add(
        sseClientHandler(
          clientManager: clientManager,
          sseHandlerPath: config.sseHandlerPath!,
          authCode: authCode,
        ),
      );
    }

    logger.info(
      'Web socket connections are enabled. Adding web socket handler.',
    );
    handlerCascade = handlerCascade.add(
      webSocketClientHandler(clientManager: clientManager),
    );

    logger.info('HTTP requests are accepted. Adding HTTP request handler.');
    handlerCascade = handlerCascade.add(httpRequestHandler(backend: this));

    logger.info('Shelf handlers generated.');
    return pipeline.addHandler(handlerCascade.handler);
  }
}
