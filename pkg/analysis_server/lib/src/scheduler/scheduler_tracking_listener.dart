// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp show Either2;
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analysis_server/src/scheduler/scheduled_message.dart';
import 'package:analysis_server/src/status/performance_logger.dart';

/// The current time represented as milliseconds since the beginning of the
/// epoch.
int get _now => DateTime.now().millisecondsSinceEpoch;

/// Information about a scheduled message's journey through the message
/// scheduler.
class MessageData {
  /// The message for which data is being collected.
  final ScheduledMessage message;

  /// The number of pending messages already on the active queue when the [message] was
  /// added to the pending queue.
  final int activeOnPendingMessageCount;

  /// The ids of the messages in the active message queue when this message was
  /// added to the pending queue.
  final List<String> activeOnPendingMessages;

  /// The number of pending messages already on the queue when the [message] was
  /// added to the pending queue.
  final int pendingOnPendingMessageCount;

  /// The ids of the messages in the pending message queue when this message was
  /// added to the pending queue.
  final List<String> pendingOnPendingMessages;

  /// The number of pending messages on the queue when the [message] was moved
  /// to the active queue.
  int pendingOnActiveMessageCount = 0;

  /// The ids of the messages in the pending message queue when this message was
  /// moved to the active queue.
  List<String> pendingOnActiveMessages = [];

  /// The number of active messages on the queue when the [message] was moved
  /// to the active queue.
  int activeOnActiveMessageCount = 0;

  /// The ids of the messages in the active message queue when this message was
  /// moved to the active queue.
  List<String> activeOnActiveMessages = [];

  /// The time at which the [message] was added to the pending queue.
  final int pendingTime;

  /// The time at which the [message] was added to the active queue.
  int? activeTime;

  /// Whether the [message] was cancelled.
  bool wasCancelled = false;

  /// The time at which the [message] was completed.
  int? completeTime;

  /// The id of the message that was completed, if any.
  lsp.Either2<int, String>? cancelledMessageId;

  MessageData({
    required this.message,
    required this.pendingOnPendingMessageCount,
    required this.pendingOnPendingMessages,
    required this.activeOnPendingMessageCount,
    required this.activeOnPendingMessages,
  }) : pendingTime = _now;
}

/// A message scheduler listener that will gather data for reporting purposes.
///
/// The data will be included in the reports sent to track down performance
/// issues, and aggregated data will be reported to the analytics manager.
class SchedulerTrackingListener extends MessageSchedulerListener {
  /// The number of messages to keep in the [_receivedMessageData] list.
  static const int logLength = 100;

  /// The analytics manager through which analytics are to be sent.
  final AnalyticsManager analyticsManager;

  /// A map from scheduled messages to the [MessageData] object
  /// being collected about them.
  final Map<ScheduledMessage, MessageData> _messageDataMap = {};

  /// A list of [MessageData] objects for messages as they are received.
  final List<MessageData> _receivedMessageData = [];

  /// The index into [_receivedMessageData] for the next message.
  int _nextMessageIndex = 0;

  /// The number of messages in the active message queue.
  int _activeMessageCount = 0;

  /// The number of messages in the pending message queue.
  int _pendingMessageCount = 0;

  /// The time at which processing last started.
  int processingStartTime = 0;

  /// The time at which processing last ended, or `-1` if processing hasn't yet
  /// ended.
  int processingEndTime = -1;

  /// The performance logger to which data is to be written.
  final PerformanceLogger? performanceLogger;

  /// Returns a newly created listener that will report to the
  /// [analyticsManager].
  SchedulerTrackingListener(this.analyticsManager, this.performanceLogger);

  @override
  void addActiveMessage(ScheduledMessage message) {
    var messageData = _messageDataMap[message];
    if (messageData == null) {
      return;
    }
    messageData.activeTime = _now;

    var (:pending, :active) = _getCurrentActiveAndPendingMessages(
      exclude: message,
    );
    messageData.pendingOnActiveMessageCount = _pendingMessageCount - 1;
    messageData.pendingOnActiveMessages = pending;
    messageData.activeOnActiveMessageCount = active.length;
    messageData.activeOnActiveMessages = active;
    _pendingMessageCount--;
    _activeMessageCount++;
  }

  @override
  void addPendingMessage(ScheduledMessage message) {
    var (:pending, :active) = _getCurrentActiveAndPendingMessages();
    var newMessageData = MessageData(
      message: message,
      pendingOnPendingMessageCount: _pendingMessageCount,
      pendingOnPendingMessages: pending,
      activeOnPendingMessageCount: _activeMessageCount,
      activeOnPendingMessages: active,
    );
    _messageDataMap[message] = newMessageData;
    if (_receivedMessageData.length < SchedulerTrackingListener.logLength) {
      _receivedMessageData.add(newMessageData);
    } else {
      _receivedMessageData[_nextMessageIndex] = newMessageData;
      _nextMessageIndex =
          (_nextMessageIndex + 1) % SchedulerTrackingListener.logLength;
    }
    _pendingMessageCount++;
  }

  @override
  void cancelActiveMessage(ScheduledMessage message) {
    var messageData = _messageDataMap[message];
    if (messageData == null) {
      return;
    }
    messageData.completeTime = _now;
    messageData.wasCancelled = true;
    // Don't decrement counts or report message data yet because
    // cancelled messages still complete and call messageCompleted().
  }

  @override
  void cancelPendingMessage(ScheduledMessage message) {
    var messageData = _messageDataMap[message];
    if (messageData == null) {
      return;
    }
    messageData.completeTime = _now;
    messageData.wasCancelled = true;
    // Don't decrement counts or report message data yet because
    // cancelled messages still complete and call messageCompleted().
  }

  /// Report that the loop that processes messages has stopped running.
  @override
  void endProcessingMessages() {
    processingEndTime = _now;
    // var processingDuration = processingEndTime - processingStartTime;
    // TODO(brianwilkerson): Record [processingDuration].
  }

  /// Returns a list of the most recent messages.
  List<String> getMessageLog() {
    var log = <String>[];
    if (_receivedMessageData.isEmpty) {
      return log;
    }

    var startIndex = _receivedMessageData.length < logLength
        ? 0
        : _nextMessageIndex;
    var count = _receivedMessageData.length;

    for (var i = 0; i < count; i++) {
      var index = (startIndex + i) % count;
      var messageData = _receivedMessageData[index];

      Map<String, Object> jsonData = _getJsonMessageData(messageData);
      log.add(jsonEncode(jsonData));
    }
    return log;
  }

  @override
  void messageCompleted(
    ScheduledMessage message, {
    lsp.Either2<int, String>? id,
  }) {
    var messageData = _messageDataMap[message];
    if (messageData == null) {
      return;
    }
    messageData.completeTime = _now;
    messageData.cancelledMessageId = id;
    if (performanceLogger != null) {
      performanceLogger!.logMap(_getJsonMessageData(messageData));
    }
    _activeMessageCount--;
    _messageDataMap.remove(message);
  }

  @override
  void pauseProcessingMessages(int newPauseCount) {
    // TODO(dantup): Consider tracking the pause start time if newPauseCount=1.
  }

  @override
  void resumeProcessingMessages(int newPauseCount) {
    // TODO(dantup): Consider recording the pause duration if newPauseCount=0.
  }

  @override
  void startProcessingMessages() {
    processingStartTime = _now;
    // var idleDuration = processingStartTime - processingEndTime;
    // TODO(brianwilkerson): Record [idleDuration].
  }

  ({List<String> pending, List<String> active})
  _getCurrentActiveAndPendingMessages({ScheduledMessage? exclude}) {
    var pendingMessages = <String>[];
    var activeMessages = <String>[];
    for (var messageData in _messageDataMap.values) {
      if (messageData.message == exclude) {
        continue;
      }
      if (messageData.activeTime != null) {
        activeMessages.add(messageData.message.id);
      } else {
        pendingMessages.add(messageData.message.id);
      }
    }
    return (pending: pendingMessages, active: activeMessages);
  }

  Map<String, Object> _getJsonMessageData(MessageData messageData) {
    var now = _now;
    var pendingTime = messageData.pendingTime;
    var activeTime = messageData.activeTime ?? now;
    var completeTime = messageData.completeTime ?? now;
    var id = messageData.cancelledMessageId;
    var message = id != null
        ? '${messageData.message.id}:$id'
        : messageData.message.id;

    var jsonData = {
      'message': message,
      'pendingMessageCount': messageData.pendingOnPendingMessageCount,
      'pendingMessages': messageData.pendingOnPendingMessages,
      'activeOnPendingMessageCount': messageData.activeOnPendingMessageCount,
      'activeOnPendingMessages': messageData.activeOnPendingMessages,
      'pendingOnActiveMessageCount': messageData.pendingOnActiveMessageCount,
      'pendingOnActiveMessages': messageData.pendingOnActiveMessages,
      'activeOnActiveMessageCount': messageData.activeOnActiveMessageCount,
      'activeOnActiveMessages': messageData.activeOnActiveMessages,
      'queueTime': activeTime - pendingTime,
      'processTime': completeTime - activeTime,
      'wasCancelled': messageData.wasCancelled,
      'completed': messageData.completeTime != null,
    };
    return jsonData;
  }
}
