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

/// An object that can handle messages and produce responses for requests.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MessageHandler<P, R> with LspParamsConverterMixin {
  /// The message types that this handler can handle.
  String get handlesMessage;

  // TODO(dantup): Change this to an abstract method instead of putting it here.
  final P Function(Map<String, dynamic>) fromJson;

  MessageHandler(this.fromJson);

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<R> handleMessage(IncomingMessage message) {
    // TODO: Change the return type here to something that can be an R or an error
    // and stop throwing ResponseError's but return them instead.

    // TODO(dantup): This should become simpler onces fromJson becomes an
    // abstract method.
    final params = fromJson != null ? convertParams(message, fromJson) : null;
    return handle(params);
  }

  FutureOr<R> handle(P params);
}

/// A message handler that handles all messages for a given server state.
abstract class ServerStateMessageHandler with LspParamsConverterMixin {
  final LspAnalysisServer server;
  Map<String, MessageHandler> _messageHandlers = {};

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

  FutureOr<Object> handleUnknownMessage(IncomingMessage message) {
    // Messages that start with $/ are optional and can be silently ignored
    // if we don't know how to handle them.
    final isOptionalRequest = message.method.startsWith(r'$/');
    // TODO(dantup): How should we handle unknown notifications that do
    // *not* start with $/?
    // https://github.com/Microsoft/language-server-protocol/issues/608
    if (!isOptionalRequest) {
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

  reject(String type, ErrorCodes code, String message) {
    registerHandler(new RejectMessageHandler(type, code, message));
  }
}

mixin LspParamsConverterMixin {
  T convertParams<T>(
      IncomingMessage message, T Function(Map<String, dynamic>) constructor) {
    return message.params.map(
      (_) => throw 'Expected dynamic, got List<dynamic>',
      (params) => constructor(params),
    );
  }

  List<T> convertParamsList<T>(
      IncomingMessage message, T Function(Map<String, dynamic>) constructor) {
    return message.params.map(
      (params) => params.map((p) => constructor(p)).toList(),
      (_) => throw 'Expected List<dynamic>, got dynamic',
    );
  }
}
