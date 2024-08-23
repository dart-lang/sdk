// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/server/performance.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

/// The state of the connection to DTD.
enum DtdConnectionState {
  /// A connection is being made or initialization is in progress.
  Connecting,

  /// The connection is available to use.
  Connected,

  /// The connection is closing or closed.
  Disconnected,

  /// A fatal error occurred setting up the connection to DTD.
  Error,
}

/// A connection to DTD that exposes some analysis services (such as a subset
/// of LSP) to other DTD clients.
class DtdServices {
  /// The name of the DTD service that methods will be registered under.
  static const _lspServiceName = 'Lsp';

  /// The name of the DTD stream that events/notifications will be posted to.
  static const _lspStreamName = 'Lsp';

  final AnalysisServer _server;

  final Uri dtdUri;

  /// A raw connection to the Dart Tooling Daemon.
  DartToolingDaemon? _dtd;

  DtdConnectionState _state = DtdConnectionState.Connecting;

  DtdServices._(this._server, this.dtdUri);

  DtdConnectionState get state => _state;

  /// Closes the connection to DTD and cleans up.
  void _close([DtdConnectionState state = DtdConnectionState.Disconnected]) {
    _state = state;

    // This code may have been closed because the connection closed, or it might
    // close just as we're getting here (eg. if the IDE was closed and we're
    // both shutting down at the same time), so catch and log any errors]
    // attempting to shut down.
    try {
      _dtd?.close();
    } catch (error, stack) {
      // Record as INFO, since this may be common during shutdown.
      _server.instrumentationService.logInfo(
        'Error closing DTD connection:\n$error\n$stack',
      );
    }
  }

  /// Attempts to connect to DTD, handling any errors that occur during
  /// connection or initialization.
  Future<void> _connect() async {
    try {
      var dtd = _dtd = await DartToolingDaemon.connect(dtdUri);

      unawaited(
        dtd.done.then(
          (_) => _close(),
          onError: (error, stack) => _handleError(error, stack),
        ),
      );

      // Register the LSP servers once the server becomes initialized and
      // the handlers are available.
      unawaited(
        Future.value(_server.lspInitialized)
            .then(
              (handler) => _registerAllLspServices(handler, dtd),
              onError: (error, stack) => _handleError(error, stack),
            )
            // Errors could occur if the server shuts down before we complete
            // register with DTD. The JSON-RPC client will throw
            // 'The client closed with pending request "registerService"'.
            .catchError(_handleError),
      );

      // When the server moves out of the initialized state, shut down the
      // connection to DTD.
      unawaited(
        _server.lspUninitialized.then(
          (handler) => _close(),
          onError: (error, stack) => _handleError(error, stack),
        ),
      );
    } catch (e, s) {
      _handleError(e, s);
      rethrow;
    }
  }

  /// Executes the LSP handler [messageHandler] with [params] and returns the
  /// results as a map to provide back to DTD.
  ///
  /// If the handler fails, throws an [RpcException] to be propagated to the
  /// client.
  Future<Map<String, Object?>> _executeLspHandler(
    MessageHandler<Object?, Object?, AnalysisServer> messageHandler,
    Parameters params,
    OperationPerformanceImpl performance,
  ) async {
    // TODO(dantup): Currently the handler just runs immediately, but this
    //  should interact with the scheduler in future.

    // Map the incoming request into types we use for LSP request handling.
    var message = IncomingMessage(
      jsonrpc: jsonRpcVersion,
      method: messageHandler.handlesMessage,
      params: params.asMap,
    );
    var info = MessageInfo(performance: performance);
    var token = NotCancelableToken(); // We don't currently support cancel.

    // Execute the handler.
    var result = await messageHandler.handleMessage(message, info, token);

    // Map the result (or error) on to what a DTD handler needs to return.
    return result.map(
      // Map LSP errors on to equiv JSON-RPC errors for DTD.
      (error) => throw RpcException(
        error.code.toJson(),
        error.message,
        data: error.data,
      ),
      // DTD requires that all results are a Map and that they contain a
      // 'type' field. This differs slightly from LSP where we could return a
      // boolean (for example). This means we need to put the result in a
      // field, which we're calling 'result'.
      (result) => {
        'type': result?.runtimeType.toString(),
        'result': result,
      },
    );
  }

  /// Handles an unexpected error occurring on the DTD connection by logging and
  /// closing the connection.
  void _handleError(Object? error, Object? stack) {
    _server.instrumentationService.logError([
      'Failed to connect to/initialize DTD:',
      error,
      if (stack != null) stack,
    ].join('\n'));

    _close(DtdConnectionState.Error);
  }

  /// Registers any request handlers provided by the server handler [handler]
  /// to DTD if they allow untrusted callers.
  Future<void> _registerAllLspServices(
    InitializedStateMessageHandler handler,
    DartToolingDaemon dtd,
  ) async {
    await Future.wait([
      for (var lspHandler in handler.messageHandlers.values)
        _registerLspService(lspHandler, dtd),
    ]);

    // Post a 'initialized' event to the LSP stream so clients know that all
    // services have finished registering.
    await dtd.postEvent(_lspStreamName, 'initialized', {});
  }

  /// Registers a single message handler to DTD if it allows untrusted callers.
  Future<void> _registerLspService(
    MessageHandler<Object?, Object?, AnalysisServer> messageHandler,
    DartToolingDaemon dtd,
  ) async {
    if (messageHandler.requiresTrustedCaller) return;
    await dtd.registerService(
      _lspServiceName,
      messageHandler.handlesMessage.toString(),
      (Parameters params) async {
        var rootPerformance = OperationPerformanceImpl('<root>');
        RequestPerformance? requestPerformance;
        return await rootPerformance.runAsync('request', (performance) async {
          // Record request performance so DTD requests show up in the
          // server diagnostic pages.
          requestPerformance = RequestPerformance(
            operation: '${messageHandler.handlesMessage} (DTD)',
            performance: performance,
          );
          _server.recentPerformance.requests.add(requestPerformance!);

          return await _executeLspHandler(messageHandler, params, performance);
        });
      },
    );
  }

  /// Connects to DTD at [uri] and exposes shared LSP handlers from [server]
  /// as DTD service methods.
  ///
  /// Returns a [ErrorCodes.RequestFailed] error if the connection cannot be
  /// made or fails to initialize.
  static Future<ErrorOr<DtdServices>> connect(
      AnalysisServer server, Uri uri) async {
    try {
      var dtd = DtdServices._(server, uri);
      await dtd._connect();
      return success(dtd);
    } catch (e) {
      return error(
        ErrorCodes.RequestFailed,
        'Failed to connect to DTD at $uri\n$e',
      );
    }
  }
}
