// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_cancel_request.dart';
import 'package:analysis_server/src/lsp/handlers/handler_reject.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';

export 'package:analyzer/src/utilities/cancellation.dart';

/// Converts an iterable using the provided function and skipping over any
/// null values.
Iterable<T> convert<T, E>(Iterable<E> items, T? Function(E) converter) {
  // TODO(dantup): Now this is used outside of handlers, is there somewhere
  // better to put it, and/or a better name for it?
  return items.map(converter).where((item) => item != null).cast<T>();
}

/// A base class for LSP handlers that require an LSP analysis server and are
/// not supported over the legacy protocol.
typedef LspMessageHandler<P, R> = MessageHandler<P, R, LspAnalysisServer>;

abstract class CommandHandler<P, R> with Handler<R>, HandlerHelperMixin {
  @override
  final LspAnalysisServer server;

  CommandHandler(this.server);

  /// Whether this command records its own analytics and should be excluded from
  /// logging by the main command handler.
  ///
  /// This is useful if a command is generic (for example "performRefactor") and
  /// can record a more specific command name.
  bool get recordsOwnAnalytics => false;

  Future<ErrorOr<Object?>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  );
}

mixin Handler<T> {
  // TODO(dantup): Merge this into HandlerHelperMixin by converting to methods
  //  so T can be inferred.
  final fileModifiedError = error<T>(ErrorCodes.ContentModified,
      'Document was modified before operation completed', null);

  final serverNotInitializedError = error<T>(ErrorCodes.ServerNotInitialized,
      'Request not valid before server is initialized');
}

/// Providers some helpers for request handlers to produce common errors or
/// obtain resolved results after waiting for in-progress analysis.
mixin HandlerHelperMixin {
  LspAnalysisServer get server;

  ErrorOr<T> analysisFailedError<T>(String path) => error<T>(
      ServerErrorCodes.FileAnalysisFailed, 'Analysis failed for file', path);

  bool fileHasBeenModified(String path, num? clientVersion) {
    final serverDocIdentifier = server.getVersionedDocumentIdentifier(path);
    return clientVersion != null &&
        clientVersion != serverDocIdentifier.version;
  }

  ErrorOr<T> fileNotAnalyzedError<T>(String path) => error<T>(
      ServerErrorCodes.FileNotAnalyzed, 'File is not being analyzed', path);

  ErrorOr<LineInfo> getLineInfo(String path) {
    final lineInfo = server.getLineInfo(path);

    if (lineInfo == null) {
      return error(ServerErrorCodes.InvalidFilePath,
          'Unable to obtain line information for file', path);
    } else {
      return success(lineInfo);
    }
  }

  /// Attempts to get a [ResolvedLibraryResult] for the library the includes the
  /// file at [path] or an error.
  ///
  /// When [waitForInProgressContextRebuilds] is `true` and the file appears to
  /// not be analyzed but analysis roots are currently being discovered, will
  /// wait for discovery to complete and then try again (once) to get a result.
  Future<ErrorOr<ResolvedLibraryResult>> requireResolvedLibrary(
    String path, {
    bool waitForInProgressContextRebuilds = true,
  }) async {
    final result = await server.getResolvedLibrary(path);
    if (result == null) {
      // Handle retry if allowed.
      if (waitForInProgressContextRebuilds) {
        await server.analysisContextsRebuilt;
        return requireResolvedLibrary(path,
            waitForInProgressContextRebuilds: false);
      }

      // If the file was being analyzed and we got a null result, that usually
      // indicates a parser or analysis failure, so provide a more specific
      // message.
      return server.isAnalyzed(path)
          ? analysisFailedError(path)
          : fileNotAnalyzedError(path);
    }
    return success(result);
  }

  /// Attempts to get a [ResolvedUnitResult] for [path] or an error.
  ///
  /// When [waitForInProgressContextRebuilds] is `true` and the file appears to
  /// not be analyzed but analysis roots are currently being discovered, will
  /// wait for discovery to complete and then try again (once) to get a result.
  Future<ErrorOr<ResolvedUnitResult>> requireResolvedUnit(
    String path, {
    bool waitForInProgressContextRebuilds = true,
  }) async {
    final result = await server.getResolvedUnit(path);
    if (result == null) {
      // Handle retry if allowed.
      if (waitForInProgressContextRebuilds) {
        await server.analysisContextsRebuilt;
        return requireResolvedUnit(path,
            waitForInProgressContextRebuilds: false);
      }

      // If the file was being analyzed and we got a null result, that usually
      // indicates a parser or analysis failure, so provide a more specific
      // message.
      return server.isAnalyzed(path)
          ? analysisFailedError(path)
          : fileNotAnalyzedError(path);
    } else if (!result.exists) {
      return error(
          ServerErrorCodes.InvalidFilePath, 'File does not exist', path);
    }
    return success(result);
  }

  Future<ErrorOr<ParsedUnitResult>> requireUnresolvedUnit(
    String path, {
    bool waitForInProgressContextRebuilds = true,
  }) async {
    final result = await server.getParsedUnit(path);
    if (result == null) {
      // Handle retry if allowed.
      if (waitForInProgressContextRebuilds) {
        await server.analysisContextsRebuilt;
        return requireUnresolvedUnit(path,
            waitForInProgressContextRebuilds: false);
      }

      // If the file was being analyzed and we got a null result, that usually
      // indicates a parser or analysis failure, so provide a more specific
      // message.
      return server.isAnalyzed(path)
          ? analysisFailedError(path)
          : fileNotAnalyzedError(path);
    }
    return success(result);
  }
}

mixin LspPluginRequestHandlerMixin<T extends AnalysisServer>
    on RequestHandlerMixin<T> {
  Future<List<Response>> requestFromPlugins(
    String path,
    RequestParams params, {
    Duration timeout = const Duration(milliseconds: 500),
  }) {
    final driver = server.getAnalysisDriver(path);
    final pluginFutures = server.broadcastRequestToPlugins(params, driver);
    return waitForResponses(pluginFutures,
        requestParameters: params, timeout: timeout);
  }
}

/// An object that can handle messages and produce responses for requests.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MessageHandler<P, R, S extends LspAnalysisServer>
    with Handler<R>, HandlerHelperMixin, RequestHandlerMixin<S> {
  @override
  final S server;

  MessageHandler(this.server);

  /// The method that this handler can handle.
  Method get handlesMessage;

  /// A handler that can parse and validate JSON params.
  LspJsonHandler<P> get jsonHandler;

  FutureOr<ErrorOr<R>> handle(
      P params, MessageInfo message, CancellationToken token);

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<ErrorOr<R>> handleMessage(IncomingMessage message,
      MessageInfo messageInfo, CancellationToken token) {
    final reporter = LspJsonReporter('params');
    final paramsJson = message.params as Map<String, Object?>?;
    if (!jsonHandler.validateParams(paramsJson, reporter)) {
      return error(
        ErrorCodes.InvalidParams,
        'Invalid params for ${message.method}:\n'
                '${reporter.errors.isNotEmpty ? reporter.errors.first : ''}'
            .trim(),
        null,
      );
    }

    final params =
        paramsJson != null ? jsonHandler.convertParams(paramsJson) : null as P;
    return handle(params, messageInfo, token);
  }
}

/// Additional information about an incoming message (request or notification)
/// provided to a handler.
class MessageInfo {
  /// Returns the amount of time (in milliseconds) since the client sent this
  /// request or `null` if the client did not provide [clientRequestTime].
  final int? timeSinceRequest;

  OperationPerformanceImpl performance;

  MessageInfo({required this.performance, this.timeSinceRequest});
}

mixin PositionalArgCommandHandler {
  /// Parses "legacy" arguments passed a list, rather than in a map as a single
  /// argument.
  ///
  /// This is provided for backwards compatibility and may not be provided by
  /// all command handlers.
  Map<String, Object?> parseArgList(List<Object?> arguments);
}

/// A message handler that handles all messages for a given server state.
abstract class ServerStateMessageHandler {
  final LspAnalysisServer server;
  final Map<Method, LspMessageHandler<Object?, Object?>> _messageHandlers = {};
  final CancelRequestHandler _cancelHandler;
  final NotCancelableToken _notCancelableToken = NotCancelableToken();

  ServerStateMessageHandler(this.server)
      : _cancelHandler = CancelRequestHandler(server) {
    registerHandler(_cancelHandler);
  }

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<ErrorOr<Object?>> handleMessage(
      IncomingMessage message, MessageInfo messageInfo) async {
    final handler = _messageHandlers[message.method];
    if (handler == null) {
      return handleUnknownMessage(message);
    }

    if (message is! RequestMessage) {
      return handler.handleMessage(message, messageInfo, _notCancelableToken);
    }

    // Create a cancellation token that will allow us to cancel this request if
    // requested to save processing (the handler will need to specifically
    // check the token after `await` points).
    final token = _cancelHandler.createToken(message);
    try {
      final result = await handler.handleMessage(message, messageInfo, token);
      // Do a final check before returning the result, because if the request was
      // cancelled we can save the overhead of serializing everything to JSON
      // and the client to deserializing the same in order to read the ID to see
      // that it was a request it didn't need (in the case of completions this
      // can be quite large).
      await Future.delayed(Duration.zero);
      return token.isCancellationRequested ? cancelled() : result;
    } finally {
      _cancelHandler.clearToken(message);
    }
  }

  FutureOr<ErrorOr<Object?>> handleUnknownMessage(IncomingMessage message) {
    // If it's an optional *Notification* we can ignore it (return success).
    // Otherwise respond with failure. Optional Requests must still be responded
    // to so they don't leave open requests on the client.
    return _isOptionalNotification(message)
        ? success(null)
        : error(ErrorCodes.MethodNotFound, 'Unknown method ${message.method}');
  }

  void registerHandler(LspMessageHandler<Object?, Object?> handler) {
    _messageHandlers[handler.handlesMessage] = handler;
  }

  void reject(Method method, ErrorCodes code, String message) {
    registerHandler(RejectMessageHandler(server, method, code, message));
  }

  bool _isOptionalNotification(IncomingMessage message) {
    // Not a notification.
    if (message is! NotificationMessage) {
      return false;
    }

    // Messages that start with $/ are optional.
    final stringValue = message.method.toJson();
    return stringValue is String && stringValue.startsWith(r'$/');
  }
}
