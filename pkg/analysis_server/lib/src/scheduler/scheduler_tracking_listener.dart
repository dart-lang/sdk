// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analysis_server/src/scheduler/scheduled_message.dart';

/// The current time represented as milliseconds since the beginning of the
/// epoch.
int get _now => DateTime.now().millisecondsSinceEpoch;

/// Information about a scheduled message's journey through the message
/// scheduler.
class MessageData {
  /// The message for which data is being collected.
  final ScheduledMessage message;

  /// The number of pending messages already on the queue when the [message] was
  /// added to the queue.
  final int pendingMessageCount;

  /// The number of active messages already on the queue when the [message] was
  /// added to the queue.
  final int activeMessageCount;

  /// The time at which the [message] was added to the pending queue.
  final int pendingTime;

  /// The time at which the [message] was added to the active queue.
  int? activeTime;

  /// Whether the [message] was cancelled.
  bool wasCancelled = false;

  /// The time at which the [message] was completed.
  int? completeTime;

  MessageData({
    required this.message,
    required this.pendingMessageCount,
    required this.activeMessageCount,
  }) : pendingTime = _now;
}

/// A message scheduler listener that will gather data for reporting purposes.
///
/// The data will be included in the reports sent to track down performance
/// issues, and aggregated data will be reported to the analytics manager.
class SchedulerTrackingListener extends MessageSchedulerListener {
  /// The number of lines of data to be kept in the [completedMessageLog].
  static const int logLength = 100;

  /// The analytics manager through which analytics are to be sent.
  final AnalyticsManager analyticsManager;

  /// A map from scheduled messages to the data being collected about them.
  final Map<ScheduledMessage, MessageData> _messageDataMap = {};

  /// The number of messages in the active message queue.
  int _activeMessageCount = 0;

  /// The number of messages in the pending message queue.
  int _pendingMessageCount = 0;

  /// The time at which processing last started.
  int processingStartTime = 0;

  /// The time at which processing last ended, or `-1` if processing hasn't yet
  /// ended.
  int processingEndTime = -1;

  /// A list of data about the [logLength] most recently completed messages.
  List<String> completedMessageLog = [];

  /// Returns a newly created listener that will report to the
  /// [analyticsManager].
  SchedulerTrackingListener(this.analyticsManager);

  ({List<MessageData> pending, List<MessageData> active})
  get pendingAndActiveMessages {
    var pendingMessages = <MessageData>[];
    var activeMessages = <MessageData>[];
    for (var messageData in _messageDataMap.values) {
      if (messageData.activeTime != null) {
        activeMessages.add(messageData);
      } else {
        pendingMessages.add(messageData);
      }
    }
    return (pending: pendingMessages, active: activeMessages);
  }

  @override
  void addActiveMessage(ScheduledMessage message) {
    var messageData = _messageDataMap[message]!;
    messageData.activeTime = _now;
    _pendingMessageCount--;
    _activeMessageCount++;
  }

  @override
  void addPendingMessage(ScheduledMessage message) {
    _messageDataMap[message] = MessageData(
      message: message,
      pendingMessageCount: _pendingMessageCount,
      activeMessageCount: _activeMessageCount,
    );
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

  @override
  void messageCompleted(ScheduledMessage message) {
    var messageData = _messageDataMap.remove(message)!;
    messageData.completeTime = _now;
    _activeMessageCount--;
    _reportMessageData(messageData);
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

  /// Reports information about a completed message.
  void _reportMessageData(MessageData messageData) {
    var now = _now;
    var pendingTime = messageData.pendingTime;
    var activeTime = messageData.activeTime ?? now;
    var completeTime = messageData.completeTime ?? now;

    var jsonData = {
      'message': messageData.message.id,
      'pendingMessageCount': messageData.pendingMessageCount,
      'activeMessageCount': messageData.activeMessageCount,
      'pendingDuration': activeTime - pendingTime,
      'activeDuration': completeTime - activeTime,
      'wasCancelled': messageData.wasCancelled,
    };

    if (completedMessageLog.length >= logLength) {
      completedMessageLog.removeAt(0);
    }
    completedMessageLog.add(jsonEncode(jsonData));

    // TODO(brianwilkerson): Report the [messageDataData] to the analytics manager.
    // analyticsManager;
  }
}
