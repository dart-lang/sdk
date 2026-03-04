// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

import 'clients.dart';
import 'dart_runtime_service_backend.dart';
import 'dart_runtime_service_options.dart';
import 'event_streams.dart';
import 'exceptions.dart';
import 'handlers.dart';
import 'utils.dart';

class DartRuntimeService {
  DartRuntimeService._({required this.config, required this.backend})
    : authCode = config.disableAuthCodes ? null : generateSecret() {
    if (config.enableLogging) {
      _logger.onRecord.listen(stdout.writeln);
    }
  }

  static Future<DartRuntimeService> start({
    required DartRuntimeServiceOptions config,
    required DartRuntimeServiceBackend backend,
  }) async {
    final service = DartRuntimeService._(config: config, backend: backend);
    await service._startService();
    return service;
  }

  final DartRuntimeServiceOptions config;

  final DartRuntimeServiceBackend backend;

  /// The ws:// URI pointing to this [DartRuntimeService]'s server.
  Uri get uri => _uri!;
  Uri? _uri;

  /// The sse:// URI pointing to this [DartRuntimeService]'s server.
  Uri get sseUri {
    if (config.sseHandlerPath == null) {
      throw StateError('SSE handler path not configured.');
    }
    return uri.replace(
      scheme: 'sse',
      pathSegments: [...uri.pathSegments, config.sseHandlerPath!],
    );
  }

  /// The authentication code needed to communicate with the service.
  ///
  /// When authentication codes are disabled, this field is null.
  final String? authCode;

  final _logger = Logger('$DartRuntimeService');

  @visibleForTesting
  late final ClientManager clientManager = ClientManager(
    eventStreamMethods: eventStreamManager,
  );

  @visibleForTesting
  late final eventStreamManager = EventStreamManager(
    clientsGetter: () => UnmodifiableNamedLookup(clientManager.clients),
  );

  HttpServer? _server;

  /// Shuts down the service and cleans up backend state.
  Future<void> shutdown() async {
    await _server?.close(force: true);
    await clientManager.shutdown();
    await backend.shutdown();
    Logger.root.clearListeners();
  }

  Future<void> _startService() async {
    // TODO(bkonyi): support IPv6
    final host = InternetAddress.loopbackIPv4.host;

    _logger.info('Starting the Dart Runtime Service.');
    late String errorMessage;
    final server = await runZonedGuarded(
      () async {
        try {
          final handlers = _handlers();
          _logger.info('Attempting to bind to $host:${config.port}');
          return await io.serve(handlers, host, config.port);
        } on SocketException catch (e) {
          errorMessage = e.message;
          if (e.osError != null) {
            errorMessage += ' (${e.osError!.message})';
          }
          errorMessage += ': ${e.address?.host}:${e.port}';
          return null;
        }
      },
      (e, st) {
        _logger.warning('Asynchronous error: $e\n$st');
      },
    );

    if (server == null) {
      final message = 'Failed to start server: $errorMessage';
      _logger.warning(message);
      throw DartRuntimeServiceFailedToStartException(message: errorMessage);
    }

    _server = server;
    _uri = Uri(
      scheme: 'ws',
      host: host,
      port: server.port,
      path: authCode != null ? '/$authCode' : '',
    );
    _logger.info(
      'Dart Runtime Service started successfully and is listening at $uri.',
    );
  }

  shelf.Handler _handlers() {
    _logger.info('Building Shelf handlers.');
    var pipeline = const shelf.Pipeline();
    if (config.enableLogging) {
      pipeline = pipeline.addMiddleware(requestLoggingMiddleware());
    }
    if (!config.disableAuthCodes) {
      _logger.info(
        'Authentication codes are enabled. Adding authentication '
        'code verification handler.',
      );
      pipeline = pipeline.addMiddleware(
        authCodeVerificationMiddleware(authCode: authCode!),
      );
    }

    var handlerCascade = shelf.Cascade();
    if (config.sseHandlerPath != null) {
      _logger.info(
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

    _logger.info(
      'Web socket connections are enabled. Adding web socket handler.',
    );
    handlerCascade = handlerCascade.add(
      webSocketClientHandler(clientManager: clientManager),
    );

    _logger.info('Shelf handlers generated.');
    return pipeline.addHandler(handlerCascade.handler);
  }
}
