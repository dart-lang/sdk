// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/protocol/protocol.dart' as legacy;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:watcher/watcher.dart';

/// Represents a message from DTD (Dart Tooling Daemon).
final class DtdMessage extends ScheduledMessage {
  /// The message that was received.
  final lsp.IncomingMessage message;

  /// The completer to be signalled when a response to the message has been
  /// computed.
  final Completer<Map<String, Object?>> responseCompleter;

  /// The object used to gather performance data.
  final OperationPerformanceImpl performance;

  DtdMessage({
    required this.message,
    required this.responseCompleter,
    required this.performance,
  });

  @override
  String get id => 'dtd:${message.method}';
}

/// Represents a message in the Legacy protocol format.
final class LegacyMessage extends ScheduledMessage {
  /// The Legacy message that was received.
  final legacy.Request request;

  /// The token used to cancel the request, or `null` if the message is not a
  /// request.
  CancelableToken? cancellationToken;

  LegacyMessage({required this.request, this.cancellationToken});

  @override
  String get id => 'legacy:${request.method}';
}

/// Represents a message in the LSP protocol format.
final class LspMessage extends ScheduledMessage {
  /// The LSP message that was received.
  final lsp.Message message;

  /// The token used to cancel the request, or `null` if the message is not a
  /// request.
  CancelableToken? cancellationToken;

  LspMessage({required this.message, this.cancellationToken});

  @override
  String get id {
    var msg = message;
    return switch (msg) {
      RequestMessage() => '${msg.method}: ${msg.id}',
      NotificationMessage() => '${msg.method}',
      ResponseMessage() => 'ResponseMessage:${msg.id}',
      Message() => 'Message',
    };
  }

  bool get isRequest => message is lsp.RequestMessage;
}

/// A message from a client.
///
/// The message can be either a request, a notification, or a response.
///
/// The client can be an IDE, a command-line tool, or DTD.
sealed class ScheduledMessage {
  /// An identifier that identifies this particular kind of message.
  String get id;

  @override
  String toString() => id;
}

/// Represents a message from the file watcher.
///
/// This is always a notification.
final class WatcherMessage extends ScheduledMessage {
  /// The event that was received.
  final WatchEvent event;

  WatcherMessage(this.event);

  @override
  String get id => 'watch:${event.type} ${event.path}';
}
