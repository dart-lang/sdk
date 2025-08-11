// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analysis_server/src/scheduler/scheduled_message.dart';

class MessageSchedulerTestView implements MessageSchedulerListener {
  List<String> messageLog = <String>[];

  @override
  void addActiveMessage(ScheduledMessage message) {
    messageLog.add('  Start ${message.runtimeType}: ${message.toString()}');
  }

  @override
  void addPendingMessage(ScheduledMessage message) {
    var messageType =
        message is LspMessage
            ? message.message.runtimeType
            : message.runtimeType;
    messageLog.add('Incoming $messageType: ${message.toString()}');
  }

  @override
  void cancelActiveMessage(ScheduledMessage message) {
    _cancelMessage(message, 'active');
  }

  @override
  void cancelPendingMessage(ScheduledMessage message) {
    _cancelMessage(message, 'pending');
  }

  @override
  void endProcessingMessages() {
    messageLog.add('Exit process messages loop');
  }

  @override
  void messageCompleted(ScheduledMessage message) {
    messageLog.add('  Complete ${message.runtimeType}: ${message.toString()}');
  }

  @override
  void pauseProcessingMessages(int newPauseCount) {
    messageLog.add('Pause requested - there are now $newPauseCount pauses');
  }

  @override
  void resumeProcessingMessages(int newPauseCount) {
    messageLog.add('Resume requested - there are now $newPauseCount pauses');
  }

  @override
  void startProcessingMessages() {
    messageLog.add('Entering process messages loop');
  }

  void _cancelMessage(ScheduledMessage message, String kind) {
    var method = switch (message) {
      LegacyMessage() => message.request.method,
      LspMessage(message: lsp.RequestMessage lspMessage) => lspMessage.method,
      _ => 'Unknown message of type ${message.runtimeType}',
    };
    messageLog.add('Canceled $kind request $method');
  }
}
