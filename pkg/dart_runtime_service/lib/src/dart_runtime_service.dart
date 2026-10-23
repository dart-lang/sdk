// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';
import 'package:stream_channel/stream_channel.dart';

import 'clients.dart';
import 'dart_runtime_service_backend.dart';
import 'dart_runtime_service_options.dart';
import 'event_streams.dart';
import 'exceptions.dart';
import 'utils.dart';

typedef RpcResponse = Map<String, Object?>;
typedef DartRuntimeServiceBackendBuilder =
    DartRuntimeServiceBackend Function(DartRuntimeService);

class DartRuntimeService {
  DartRuntimeService._({
    required this.config,
    required DartRuntimeServiceBackendBuilder backendBuilder,
  }) : authCode = config.disableAuthCodes ? null : generateSecret() {
    backend = backendBuilder(this);
    if (config.enableLogging) {
      _loggerSub = _logger.onRecord.listen(backend.writeLogRecord);
    }
    // We can't use the const constructors here as they won't pickup Dart
    // environment variables specified at runtime when the service is compiled
    // to a snapshot. This behavior is somewhat undefined and doesn't work
    // in AOT, but is maintained for backwards compatibility.
    // We use const bool.fromEnvironment('dart.library.io'), because web
    // compilers don't support non-const bool.fromEnvironment.
    silenceServiceOutput =
        const bool.fromEnvironment('dart.library.io') &&
        (
        // TODO(48602): deprecate SILENT_OBSERVATORY in favor of
        // SILENT_VM_SERVICE
        // ignore: prefer_const_constructors
        bool.fromEnvironment('SILENT_OBSERVATORY') ||
            // ignore: prefer_const_constructors
            bool.fromEnvironment('SILENT_VM_SERVICE') ||
            // ignore: prefer_const_constructors
            bool.fromEnvironment('SILENT_SERVICE'));
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
  /// Throws [DartRuntimeServiceServerNotRunning] if the server is not running
  /// or the backend does not expose a server URI.
  ///
  /// It's possible that the returned [Uri] is no longer valid if the server
  /// was recently shut down.
  Uri get uri {
    if (!_isServerRunning || _uri == null) {
      throw const DartRuntimeServiceServerNotRunning();
    }
    return _uri!;
  }

  Uri? _uri;

  /// The http:// URI pointing to this [DartRuntimeService]'s server.
  ///
  /// Throws [DartRuntimeServiceServerNotRunning] if the server is not running
  /// or the backend does not expose a server URI.
  ///
  /// It's possible that the returned [Uri] is no longer valid if the server
  /// was recently shut down.
  Uri get httpUri {
    final segments = <String>[
      ...uri.pathSegments,
      if (uri.pathSegments.isEmpty || uri.pathSegments.last.isNotEmpty) '',
    ];
    if (segments.length == 1) {
      segments.add('');
    }
    return uri.replace(
      scheme: (uri.isScheme('wss') || uri.isScheme('https')) ? 'https' : 'http',
      pathSegments: segments,
    );
  }

  /// The sse:// URI pointing to this [DartRuntimeService]'s server.
  ///
  /// Throws [StateError] if [DartRuntimeServiceOptions.sseHandlerPath] is not
  /// set.
  ///
  /// Throws [DartRuntimeServiceServerNotRunning] if the server is not running
  /// or the backend does not expose a server URI.
  ///
  /// It's possible that the returned [Uri] is no longer valid if the server
  /// was recently shut down.
  Uri get sseUri {
    if (config.sseHandlerPath == null) {
      throw StateError('SSE handler path not configured.');
    }
    return uri.replace(
      scheme:
          (uri.isScheme('wss') || uri.isScheme('https') || uri.isScheme('sses'))
          ? 'sses'
          : 'sse',
      pathSegments: [...uri.pathSegments, config.sseHandlerPath!],
    );
  }

  /// The authentication code needed to communicate with the service.
  ///
  /// When authentication codes are disabled, this field is null.
  final String? authCode;

  final _logger = Logger('$DartRuntimeService');
  StreamSubscription<LogRecord>? _loggerSub;

  /// Exposes methods for controlling acceptance of new [Client] connections.
  ClientConnectionController get clientConnectionController => clientManager;

  @internal
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

  final _serverLock = Pool(1);
  bool _isServerRunning = false;
  bool _shutdownCalled = false;
  final _initializedCompleter = Completer<void>();

  /// Returns true if the server is active.
  bool get isServerRunning => _isServerRunning;

  /// If true, the service won't write any messages to STDOUT.
  ///
  /// Note: this does not impact logging output when
  /// [DartRuntimeServiceOptions.enableLogging] is true.
  bool silenceServiceOutput = false;

  /// Writes [message] to STDOUT, unless [silenceServiceOutput] is true.
  void printServiceOutput(String message) {
    if (silenceServiceOutput) {
      return;
    }
    // print() must be used instead of stdout.writeln() so that embedded
    // environments (such as Flutter on Android) can capture VM service
    // listening announcements through the embedder's print handler and
    // system logcat, as stdout is discarded by default on Android.
    print(message);
  }

  /// Initializes the service's state without starting the web server.
  Future<void> _initialize() async {
    try {
      await backend.initialize();

      if (_shutdownCalled) {
        _logger.info(
          'Shutdown was called during backend initialization. Aborting.',
        );
        return;
      }

      if (config.autoStart) {
        _logger.info('Autostart enabled. Starting server.');
        await _startServer();
      }
      if (_shutdownCalled) {
        _logger.info('Shutdown was called during initialization. Aborting.');
        return;
      }
      await backend.onServiceReady(this);
    } catch (_) {
      _initializedCompleter.complete();
      await shutdown();
      rethrow;
    } finally {
      if (!_initializedCompleter.isCompleted) {
        _initializedCompleter.complete();
      }
    }
  }

  /// Shuts down the service and cleans up backend state.
  Future<void> shutdown() async {
    _shutdownCalled = true;
    if (!_initializedCompleter.isCompleted) {
      await _initializedCompleter.future;
    }
    await clientManager.shutdown();
    await backend.clearState();
    await backend.shutdown();
    try {
      await _shutdownServer();
    } on DartRuntimeServiceServerNotRunning {
      // Ignore if the server was not running.
    }
    _logger.info('Dart Runtime Service shutdown complete.');
    await _loggerSub?.cancel();
    _loggerSub = null;
  }

  /// Enables or disables the server based on the value of [enable].
  ///
  /// [silenceOutput] is used to determine if the service will output
  /// non-logging information to the terminal.
  ///
  /// This is called when `dart:developer`'s [Service.controlWebServer] is
  /// invoked.
  Future<void> serverControl({required bool enable, bool? silenceOutput}) {
    return _serverLock.withResource(() async {
      if (silenceOutput != null) {
        _logger.info(
          'silenceServiceOutput: $silenceServiceOutput -> $silenceOutput',
        );
        silenceServiceOutput = silenceOutput;
      }
      if (!enable && isServerRunning) {
        await _shutdownServerLocked();
      } else if (enable && !isServerRunning) {
        await _startServerLocked();
      }
    });
  }

  /// Toggles the state of the HTTP server, enabling it if it's not running and
  /// disabling it if it is running.
  Future<void> toggleServer() {
    return _serverLock.withResource(() async {
      if (isServerRunning) {
        await _shutdownServerLocked();
      } else {
        await _startServerLocked();
      }
    });
  }

  /// Creates an artificial client to process JSON-RPC requests from
  /// non-standard sources (e.g., from native code).
  Client addArtificialClient({
    required StreamChannel<Object?> connection,
    required String name,
  }) {
    return clientManager.addClient(
      connection: connection,
      name: name,
      artificial: true,
    );
  }

  Future<void> _startServer() => _serverLock.withResource(_startServerLocked);

  Future<void> _startServerLocked() async {
    if (_isServerRunning) {
      _logger.warning(
        "Attempted to start the HTTP server, but it's already running.",
      );
      throw const DartRuntimeServiceServerAlreadyRunning();
    }
    _uri = await backend.startServer(config: config, logger: _logger);
    _isServerRunning = true;
    try {
      await backend.onServerStarted();
    } catch (_) {
      await _shutdownServerLocked();
      rethrow;
    }
    if (_uri != null) {
      _logger.info(
        'Dart Runtime Service HTTP server started successfully and is '
        'listening at $_uri.',
      );
    }
  }

  Future<void> _shutdownServer() =>
      _serverLock.withResource(_shutdownServerLocked);

  Future<void> _shutdownServerLocked() async {
    if (!_isServerRunning) {
      _logger.warning(
        "Attempting to shut down the HTTP server, but it's not "
        'running.',
      );
      throw const DartRuntimeServiceServerNotRunning();
    }
    _logger.info('Dart Runtime Service HTTP server is shutting down.');
    _isServerRunning = false;
    _uri = null;
    await backend.shutdownServer();
    _logger.info('Dart Runtime Service HTTP server is closed.');
    await backend.onServerShutdown();
  }

  /// Send a [StreamEvent] to subscribed clients.
  void sendEvent({required StreamEventBase event}) {
    event.send(eventStreamMethods: eventStreamManager);
  }
}
