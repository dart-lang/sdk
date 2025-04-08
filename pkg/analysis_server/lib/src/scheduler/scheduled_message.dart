// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/protocol/protocol.dart' as legacy;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';

/// Represents a message from DTD (Dart Tooling Daemon).
final class DtdMessage extends ScheduledMessage {
  final lsp.IncomingMessage message;
  final Completer<Map<String, Object?>> responseCompleter;
  final OperationPerformanceImpl performance;

  DtdMessage({
    required this.message,
    required this.responseCompleter,
    required this.performance,
  });

  @override
  String toString() => message.method.toString();
}

/// Represents a message in the Legacy protocol format.
final class LegacyMessage extends ScheduledMessage {
  final legacy.Request request;
  CancelableToken? cancellationToken;

  LegacyMessage({required this.request, this.cancellationToken});

  @override
  String toString() => request.method;
}

/// Represents a message in the LSP protocol format.
final class LspMessage extends ScheduledMessage {
  final lsp.Message message;
  CancelableToken? cancellationToken;

  LspMessage({required this.message, this.cancellationToken});

  bool get isRequest => message is lsp.RequestMessage;

  @override
  String toString() {
    var msg = message;
    return switch (msg) {
      RequestMessage() => msg.method.toString(),
      NotificationMessage() => msg.method.toString(),
      ResponseMessage() => 'ResponseMessage',
      Message() => 'Message',
    };
  }
}

/// A message from a client.
///
/// The message can be either a request, a notification, or a response.
///
/// The client can be an IDE, a command-line tool, or DTD.
sealed class ScheduledMessage {}
