// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/server/message_scheduler.dart';
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
  /// The set of LSP methods currently exposed over DTD.
  ///
  /// Eventually all "shared" methods will be exposed, but during initial
  /// development and testing this will be restricted to selected methods (in
  /// particular, those with well defined results that are not affected by
  /// differences in client capabilities).
  static final allowedLspMethods = <Method>{
    // When removing this allowlist or adding simple methods like
    // textDocument/hover, skipped tests in `SharedDtdTests` can be unskipped.
    // TODO(dantup): Enable this but add a flag so we can opt-in to experimental
    //  handlers being exposed over DTD while in dev.
    CustomMethods.experimentalEcho,
    CustomMethods.dartTextDocumentEditableArguments,
  };

  /// The name of the DTD service that methods will be registered under.
  static const _lspServiceName = 'Lsp';

  /// The name of the DTD stream that events/notifications will be posted to.
  static const _lspStreamName = 'Lsp';

  final AnalysisServer _server;

  final Uri dtdUri;

  /// A raw connection to the Dart Tooling Daemon.
  DartToolingDaemon? _dtd;

  DtdConnectionState _state = DtdConnectionState.Connecting;

  /// Whether to register experimental LSP handlers over DTD.
  final bool registerExperimentalHandlers;

  DtdServices._(
    this._server,
    this.dtdUri, {
    this.registerExperimentalHandlers = false,
  });

  DtdConnectionState get state => _state;

  /// Executes the LSP handler for [message] and completes [completer] with the
  /// result or an [RpcException].
  void processMessage(
    IncomingMessage message,
    OperationPerformanceImpl performance,
    Completer<Map<String, Object?>> completer,
  ) async {
    var info = MessageInfo(
      performance: performance,
      // DTD clients requests are always executed with a fixed set of
      // capabilities so that the responses don't change in format based on the
      // owning editor.
      clientCapabilities: fixedBasicLspClientCapabilities,
    );
    var token = NotCancelableToken(); // We don't currently support cancel.

    // Execute the handler.
    var result = await _server.immediatelyHandleLspMessage(
      message,
      info,
      cancellationToken: token,
    );

    // Complete with the result or error.
    result.map(
      // Map LSP errors on to equiv JSON-RPC errors for DTD.
      (error) => completer.completeError(
        RpcException(error.code.toJson(), error.message, data: error.data),
      ),
      // DTD requires that all results are a Map and that they contain a
      // 'type' field. This differs slightly from LSP where we could return a
      // boolean (for example). This means we need to put the result in a
      // field, which we're calling 'result'.
      (result) => completer.complete({
        // result can be null, but DTD requires that we have a `type`, so don't
        // use `?.` here because it results in a missing `type` instead of
        // `Null`.
        'type': result.runtimeType.toString(),
        'result': result,
      }),
    );
  }

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

  /// The incoming request is sent to the [MessageScheduler] for execution.
  /// A completer is returned which will be completed with the result of the
  /// execution of the request by the corresponding [MessageHandler].
  Future<Map<String, Object?>> _executeLspHandler(
    Method method,
    Parameters params,
    OperationPerformanceImpl performance,
  ) async {
    // Map the incoming request into types we use for LSP request handling.
    var message = IncomingMessage(
      jsonrpc: jsonRpcVersion,
      method: method,
      params: params.asMap,
    );
    var scheduler = _server.messageScheduler;
    var completer = Completer<Map<String, Object?>>();
    scheduler.add(
      DtdMessage(
        message: message,
        performance: performance,
        completer: completer,
      ),
    );
    scheduler.notify();
    return completer.future;
  }

  /// Handles an unexpected error occurring on the DTD connection by logging and
  /// closing the connection.
  void _handleError(Object? error, Object? stack) {
    _server.instrumentationService.logError(
      [
        'Failed to connect to/initialize DTD:',
        error,
        if (stack != null) stack,
      ].join('\n'),
    );

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
        if (allowedLspMethods.contains(lspHandler.handlesMessage) &&
            (registerExperimentalHandlers || !lspHandler.isExperimental))
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
    var method = messageHandler.handlesMessage;
    await dtd.registerService(_lspServiceName, method.toString(), (
      Parameters params,
    ) async {
      var rootPerformance = OperationPerformanceImpl('<root>');
      RequestPerformance? requestPerformance;
      return await rootPerformance.runAsync('request', (performance) async {
        // Record request performance so DTD requests show up in the
        // server diagnostic pages.
        requestPerformance = RequestPerformance(
          operation: '$method (DTD)',
          performance: performance,
        );
        _server.recentPerformance.requests.add(requestPerformance!);

        return await _executeLspHandler(method, params, performance);
      });
    });
  }

  /// Connects to DTD at [uri] and exposes shared LSP handlers from [server]
  /// as DTD service methods.
  ///
  /// Returns a [ErrorCodes.RequestFailed] error if the connection cannot be
  /// made or fails to initialize.
  static Future<ErrorOr<DtdServices>> connect(
    AnalysisServer server,
    Uri uri, {
    bool registerExperimentalHandlers = false,
  }) async {
    try {
      var dtd = DtdServices._(
        server,
        uri,
        registerExperimentalHandlers: registerExperimentalHandlers,
      );
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
