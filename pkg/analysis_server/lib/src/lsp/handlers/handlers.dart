// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/analysis_server_abstract.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_cancel_request.dart';
import 'package:analysis_server/src/lsp/handlers/handler_reject.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';

/// Converts an iterable using the provided function and skipping over any
/// null values.
Iterable<T> convert<T, E>(Iterable<E> items, T Function(E) converter) {
  // TODO(dantup): Now this is used outside of handlers, is there somewhere
  // better to put it, and/or a better name for it?
  return items.map(converter).where((item) => item != null);
}

class CancelableToken extends CancellationToken {
  bool _isCancelled = false;

  @override
  bool get isCancellationRequested => _isCancelled;

  void cancel() => _isCancelled = true;
}

/// A token used to signal cancellation of an operation. This allows computation
/// to be skipped when a caller is no longer interested in the result, for example
/// when a $/cancel request is recieved for an in-progress request.
abstract class CancellationToken {
  bool get isCancellationRequested;
}

abstract class CommandHandler<P, R> with Handler<P, R> {
  CommandHandler(LspAnalysisServer server) {
    this.server = server;
  }

  Future<ErrorOr<void>> handle(List<dynamic> arguments,
      ProgressReporter progress, CancellationToken cancellationToken);
}

mixin Handler<P, R> {
  LspAnalysisServer server;

  final fileModifiedError = error<R>(ErrorCodes.ContentModified,
      'Document was modified before operation completed', null);

  bool fileHasBeenModified(String path, int clientVersion) {
    final serverDocIdentifier = server.getVersionedDocumentIdentifier(path);
    return clientVersion != null &&
        clientVersion != serverDocIdentifier.version;
  }

  ErrorOr<LineInfo> getLineInfo(String path) {
    final lineInfo = server.getLineInfo(path);

    if (lineInfo == null) {
      return error(ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
    } else {
      return success(lineInfo);
    }
  }

  Future<ErrorOr<ResolvedUnitResult>> requireResolvedUnit(String path) async {
    final result = await server.getResolvedUnit(path);
    if (result?.state != ResultState.VALID) {
      return error(ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
    }
    return success(result);
  }

  ErrorOr<ParsedUnitResult> requireUnresolvedUnit(String path) {
    final result = server.getParsedUnit(path);
    if (result?.state != ResultState.VALID) {
      return error(ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
    }
    return success(result);
  }
}

mixin LspPluginRequestHandlerMixin<T extends AbstractAnalysisServer>
    on RequestHandlerMixin<T> {
  Future<List<Response>> requestFromPlugins(
    String path,
    RequestParams params, {
    int timeout = 500,
  }) {
    final driver = server.getAnalysisDriver(path);
    final pluginFutures = server.pluginManager
        .broadcastRequest(params, contextRoot: driver.contextRoot);

    return waitForResponses(pluginFutures,
        requestParameters: params, timeout: timeout);
  }
}

/// An object that can handle messages and produce responses for requests.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MessageHandler<P, R>
    with Handler<P, R>, RequestHandlerMixin<LspAnalysisServer> {
  MessageHandler(LspAnalysisServer server) {
    this.server = server;
  }

  /// The method that this handler can handle.
  Method get handlesMessage;

  /// A handler that can parse and validate JSON params.
  LspJsonHandler<P> get jsonHandler;

  FutureOr<ErrorOr<R>> handle(P params, CancellationToken token);

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<ErrorOr<R>> handleMessage(
      IncomingMessage message, CancellationToken token) {
    final reporter = LspJsonReporter('params');
    if (!jsonHandler.validateParams(message.params, reporter)) {
      return error(
        ErrorCodes.InvalidParams,
        'Invalid params for ${message.method}:\n'
                '${reporter.errors.isNotEmpty ? reporter.errors.first : ''}'
            .trim(),
        null,
      );
    }

    final params = jsonHandler.convertParams(message.params);
    return handle(params, token);
  }
}

class NotCancelableToken extends CancellationToken {
  @override
  bool get isCancellationRequested => false;
}

/// A message handler that handles all messages for a given server state.
abstract class ServerStateMessageHandler {
  final LspAnalysisServer server;
  final Map<Method, MessageHandler> _messageHandlers = {};
  final CancelRequestHandler _cancelHandler;
  final NotCancelableToken _notCancelableToken = NotCancelableToken();

  ServerStateMessageHandler(this.server)
      : _cancelHandler = CancelRequestHandler(server) {
    registerHandler(_cancelHandler);
  }

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<ErrorOr<Object>> handleMessage(IncomingMessage message) async {
    final handler = _messageHandlers[message.method];
    if (handler == null) {
      return handleUnknownMessage(message);
    }

    if (message is! RequestMessage) {
      return handler.handleMessage(message, _notCancelableToken);
    }

    // Create a cancellation token that will allow us to cancel this request if
    // requested to save processing (the handler will need to specifically
    // check the token after `await` points).
    final token = _cancelHandler.createToken(message);
    try {
      final result = await handler.handleMessage(message, token);
      // Do a final check before returning the result, because if the request was
      // cancelled we can save the overhead of serialising everything to JSON
      // and the client to deserialising the same in order to read the ID to see
      // that it was a request it didn't need (in the case of completions this
      // can be quite large).
      await Future.delayed(Duration.zero);
      return token.isCancellationRequested ? cancelled() : result;
    } finally {
      _cancelHandler.clearToken(message);
    }
  }

  FutureOr<ErrorOr<Object>> handleUnknownMessage(IncomingMessage message) {
    // If it's an optional *Notification* we can ignore it (return success).
    // Otherwise respond with failure. Optional Requests must still be responded
    // to so they don't leave open requests on the client.
    return _isOptionalNotification(message)
        ? success()
        : error(ErrorCodes.MethodNotFound, 'Unknown method ${message.method}');
  }

  void registerHandler(MessageHandler handler) {
    assert(
        handler.handlesMessage != null,
        'Unable to register handler ${handler.runtimeType} because it does '
        'not declare which messages it can handle');

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
