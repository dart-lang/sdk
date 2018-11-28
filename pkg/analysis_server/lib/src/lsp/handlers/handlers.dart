// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handler_exit.dart';
import 'package:analysis_server/src/lsp/handlers/handler_reject.dart';
import 'package:analysis_server/src/lsp/handlers/handler_shutdown.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analyzer/dart/analysis/results.dart';

/// An object that can handle messages and produce responses for requests.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MessageHandler<P, R> {
  LspAnalysisServer server;

  MessageHandler(this.server);

  /// The method that this handler can handle.
  Method get handlesMessage;

  P convertParams(Map<String, dynamic> json);

  FutureOr<R> handle(P params);

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<R> handleMessage(IncomingMessage message) {
    // TODO: Change the return type here to something that can be an R or an error
    // and stop throwing ResponseError's but return them instead.

    final params = convertParams(message.params);
    return handle(params);
  }

  /// Converts an iterable using the provided function and skipping over any
  /// null values.
  Iterable<T> convert<T, E>(Iterable<E> items, T Function(E) converter) {
    return items.map(converter).where((item) => item != null);
  }

  Future<ResolvedUnitResult> requireUnit(String path) async {
    final result = await server.getResolvedUnit(path);
    if (result?.state != ResultState.VALID) {
      throw new ResponseError(
          ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
    }
    return result;
  }
}

/// A message handler that handles all messages for a given server state.
abstract class ServerStateMessageHandler {
  final LspAnalysisServer server;
  Map<Method, MessageHandler> _messageHandlers = {};

  ServerStateMessageHandler(this.server) {
    // All server states support shutdown and exit.
    registerHandler(new ShutdownMessageHandler(server));
    registerHandler(new ExitMessageHandler(server));
  }

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<Object> handleMessage(IncomingMessage message) async {
    final handler = _messageHandlers[message.method];
    return handler != null
        ? handler.handleMessage(message)
        : handleUnknownMessage(message);
  }

  bool _isOptionalRequest(IncomingMessage message) {
    // Messages that start with $/ are optional and can be silently ignored
    // if we don't know how to handle them.
    final stringValue = message.method.toJson();
    return stringValue is String && stringValue.startsWith(r'$/');
  }

  FutureOr<Object> handleUnknownMessage(IncomingMessage message) {
    // TODO(dantup): How should we handle unknown notifications that do
    // *not* start with $/?
    // https://github.com/Microsoft/language-server-protocol/issues/608
    if (!_isOptionalRequest(message)) {
      throw new ResponseError(
          ErrorCodes.MethodNotFound, 'Unknown method ${message.method}', null);
    }
    return null;
  }

  registerHandler(MessageHandler handler) {
    if (handler.handlesMessage == null) {
      throw 'Unable to register handler ${handler.runtimeType} because it does '
          'not declare which messages it can handle';
    }
    _messageHandlers[handler.handlesMessage] = handler;
  }

  reject(Method method, ErrorCodes code, String message) {
    registerHandler(new RejectMessageHandler(server, method, code, message));
  }
}
