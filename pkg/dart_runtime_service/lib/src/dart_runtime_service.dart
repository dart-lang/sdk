// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:stream_channel/stream_channel.dart';

import 'clients.dart';
import 'dart_runtime_service_backend.dart';
import 'dart_runtime_service_options.dart';
import 'event_streams.dart';
import 'exceptions.dart';
import 'handlers.dart';
import 'utils.dart';

typedef RpcResponse = Map<String, Object?>;
typedef DartRuntimeServiceBackendBuilder =
    DartRuntimeServiceBackend Function(DartRuntimeService);

class DartRuntimeService {
  DartRuntimeService._({
    required this.config,
    required DartRuntimeServiceBackendBuilder backendBuilder,
  }) : authCode = config.disableAuthCodes ? null : generateSecret() {
    if (config.enableLogging) {
      _logger.onRecord.listen(stdout.writeln);
    }
    backend = backendBuilder(this);
  }

  static Future<DartRuntimeService> initialize({
    required DartRuntimeServiceOptions config,
    required DartRuntimeServiceBackendBuilder backendBuilder,
  }) async {
    final service = DartRuntimeService._(
      config: config,
      backendBuilder: backendBuilder,
    );
    await service._initialize();
    return service;
  }

  final DartRuntimeServiceOptions config;

  late final DartRuntimeServiceBackend backend;

  /// The ws:// URI pointing to this [DartRuntimeService]'s server.
  ///
  /// Throws [DartRuntimeServiceServerNotRunning] if the HTTP server is not
  /// active.
  ///
  /// It's possible that the returned [Uri] is no longer valid if the server
  /// was recently shut down.
  Uri get uri {
    if (_server == null) {
      throw const DartRuntimeServiceServerNotRunning();
    }
    return _uri!;
  }

  Uri? _uri;

  /// The http:// URI pointing to this [DartRuntimeService]'s server.
  ///
  /// Throws [DartRuntimeServiceServerNotRunning] if the HTTP server is not
  /// active.
  ///
  /// It's possible that the returned [Uri] is no longer valid if the server
  /// was recently shut down.
  Uri get httpUri => uri.replace(scheme: 'http');

  /// The sse:// URI pointing to this [DartRuntimeService]'s server.
  ///
  /// Throws [StateError] if [DartRuntimeServiceOptions.sseHandlerPath] is not
  /// set.
  ///
  /// Throws [DartRuntimeServiceServerNotRunning] if the HTTP server is not
  /// active.
  ///
  /// It's possible that the returned [Uri] is no longer valid if the server
  /// was recently shut down.
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

  /// Exposes methods for controlling acceptance of new [Client] connections.
  ClientConnectionController get clientConnectionController => clientManager;

  @visibleForTesting
  late final ClientManager clientManager = backend.clientManagerBuilder();

  /// The set of currently connected [Client]s.
  UnmodifiableClientNamedLookup get clients => clientManager.clients;

  /// Exposes methods for interacting with event streams.
  EventStreamMethods get eventStreams => eventStreamManager;

  @visibleForTesting
  late final eventStreamManager = EventStreamManager(
    backend: backend,
    clientsGetter: () => clients,
  );

  // TODO(bkonyi): this should be protected by a mutex.
  HttpServer? _server;

  /// Returns true if the HTTP server is active.
  bool get isServerRunning => _server != null;

  /// Initializes the service's state without starting the web server.
  Future<void> _initialize() async {
    await backend.initialize();

    if (config.autoStart) {
      _logger.info('Autostart enabled. Starting server.');
      await _startServer();
    }
    await backend.onServiceReady(this);
  }

  /// Shuts down the service and cleans up backend state.
  Future<void> shutdown() async {
    await backend.clearState();
    await backend.shutdown();
    await _shutdownServer();
    await clientManager.shutdown();
    Logger.root.clearListeners();
  }

  /// Enables or disables the server based on the value of [enable].
  ///
  /// [silenceOutput] is used to determine if the service will output
  /// non-logging information to the terminal.
  ///
  /// This is called when `dart:developer`'s [Service.controlWebServer] is
  /// invoked.
  // TODO(bkonyi): respect silenceOutput
  Future<void> serverControl({
    required bool enable,
    bool? silenceOutput,
  }) async {
    // TODO(bkonyi): verify there's no race conditions
    if (!enable && isServerRunning) {
      await _shutdownServer();
    } else if (enable && !isServerRunning) {
      await _startServer();
    }
  }

  /// Toggles the state of the HTTP server, enabling it if it's not running and
  /// disabling it if it is running.
  Future<void> toggleServer() async {
    // TODO(bkonyi): verify there's no race conditions
    if (isServerRunning) {
      await _shutdownServer();
    } else {
      await _startServer();
    }
  }

  /// Creates an artificial client to process JSON-RPC requests from
  /// non-standard sources (e.g., from native code).
  Client addArtificialClient({
    required StreamChannel<String> connection,
    required String name,
  }) {
    return clientManager.addClient(
      connection: connection,
      name: name,
      artificial: true,
    );
  }

  Future<void> _startServer() async {
    if (_server != null) {
      _logger.warning(
        "Attempted to start the HTTP server, but it's already running.",
      );
      throw const DartRuntimeServiceServerAlreadyRunning();
    }
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
    await backend.onServerStarted(httpUri: httpUri, wsUri: uri);
    _logger.info(
      'Dart Runtime Service HTTP server started successfully and is listening '
      'at $uri.',
    );
  }

  Future<void> _shutdownServer() async {
    final server = _server;
    if (server == null) {
      _logger.warning(
        "Attempting to shut down the HTTP server, but it's not "
        'running.',
      );
      throw const DartRuntimeServiceServerNotRunning();
    }
    _logger.info('Dart Runtime Service HTTP server is shutting down.');
    _server = null;
    _uri = null;
    await server.close();
  }

  /// Send a [StreamEvent] to subscribed clients.
  void sendEvent({required StreamEventBase event}) {
    event.send(eventStreamMethods: eventStreamManager);
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

    if (!config.disableOriginCheck) {
      _logger.info('Origin checks are enabled. Adding CORS check handler.');
      pipeline = pipeline.addMiddleware(originCheckMiddleware(frontend: this));
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

    _logger.info('HTTP requests are accepted. Adding HTTP request handler.');
    handlerCascade = handlerCascade.add(httpRequestHandler(frontend: this));

    _logger.info('Shelf handlers generated.');
    return pipeline.addHandler(handlerCascade.handler);
  }
}
