// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/protocol/protocol.dart' as legacy;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:meta/meta.dart';

/// Represents a message from DTD (Dart Tooling Daemon).
final class DtdMessage extends MessageObject {
  final lsp.IncomingMessage message;
  final Completer<Map<String, Object?>> completer;
  final OperationPerformanceImpl performance;

  DtdMessage(
      {required this.message,
      required this.completer,
      required this.performance});
}

/// Represents a message in the Legacy protocol format.
final class LegacyMessage extends MessageObject {
  final legacy.Request request;

  LegacyMessage({required this.request});
}

/// Represents a message in the LSP protocol format.
final class LspMessage extends MessageObject {
  final lsp.Message message;
  CancelableToken? cancellationToken;

  LspMessage({required this.message, this.cancellationToken});
}

/// Represents a message from a client, can be an IDE, DTD etc.
sealed class MessageObject {}

/// The [MessageScheduler] receives messages from all clients of the
/// [AnalysisServer]. Clients can include IDE's (LSP and Legacy protocol), DTD,
/// and the Diagnostic server. The [MessageScheduler] acts as a hub for all
/// incoming messages and forwards the messages to the appropriate handlers.
final class MessageScheduler {
  /// The [AnalysisServer] associated with the scheduler.
  late final AnalysisServer server;

  /// A queue of incoming messages from all the clients of the [AnalysisServer].
  final ListQueue<MessageObject> _incomingMessages = ListQueue<MessageObject>();

  @visibleForTesting
  ListQueue<MessageObject> get incomingMessages => _incomingMessages;

  /// Add a message to the end of the incoming messages queue.
  void add(MessageObject message) {
    _incomingMessages.addLast(message);
  }

  /// Notify the [MessageScheduler] to process the messages queue.
  void notify() async {
    processMessages();
  }

  /// Dispatch the first message in the queue to be executed.
  void processMessages() {
    if (_incomingMessages.isEmpty) {
      return;
    }
    var message = _incomingMessages.removeFirst();
    switch (message) {
      case LspMessage():
        var lspMessage = message.message;
        (server as LspAnalysisServer).handleMessage(lspMessage,
            cancellationToken: message.cancellationToken);
      case LegacyMessage():
        var request = message.request;
        (server as LegacyAnalysisServer).handleRequest(request);
      case DtdMessage():
        server.dtd!.processMessage(
            message.message, message.performance, message.completer);
    }
  }

  /// Set the [AnalysisServer].
  void setServer(AnalysisServer analysisServer) {
    server = analysisServer;
  }
}
