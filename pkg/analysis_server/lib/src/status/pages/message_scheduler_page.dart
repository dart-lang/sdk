// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analysis_server/src/scheduler/scheduler_tracking_listener.dart';
import 'package:analysis_server/src/status/diagnostics.dart';

class MessageSchedulerPage extends DiagnosticPageWithNav {
  MessageSchedulerPage(DiagnosticsSite site)
    : super(
        site,
        'messageScheduler',
        'Message Scheduler',
        description: 'The state of the message scheduler.',
        indentInNav: true,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var now = DateTime.now().millisecondsSinceEpoch;
    var listener = server.messageScheduler.listener;

    h3('Status');
    buf.writeln(
      writeOption(
        'Allows overlapping message handlers:',
        MessageScheduler.allowOverlappingHandlers,
      ),
    );
    if (listener is! SchedulerTrackingListener) {
      buf.writeln(writeOption('Tracking listener:', 'none'));
      return;
    }

    void writeData(MessageData data, {required bool isActive}) {
      p(data.message.id);
      buf.write('<blockquote>');
      p('Pending messages ahead of this: ${data.pendingMessageCount}');
      var pendingDuration = (data.activeTime ?? now) - data.pendingTime;
      p('Time spent on pending queue: $pendingDuration');
      if (isActive) {
        p('Active messages ahead of this: ${data.activeMessageCount}');
        p('Time spent running: ${now - data.activeTime!}');
      }
      buf.write('</blockquote>');
    }

    var (:pending, :active) = listener.pendingAndActiveMessages;

    h3('Pending messages');
    if (pending.isEmpty) {
      p('none');
    } else {
      pending.sort(
        (first, second) => first.pendingTime.compareTo(second.pendingTime),
      );
      for (var data in pending) {
        writeData(data, isActive: false);
      }
    }

    h3('Active messages');
    if (active.isEmpty) {
      p('none');
    } else {
      active.sort(
        (first, second) => first.activeTime!.compareTo(second.activeTime!),
      );
      for (var data in active) {
        writeData(data, isActive: true);
      }
    }

    var lines = listener.completedMessageLog;
    if (lines.isNotEmpty) {
      h3('Completed messages');
      p(lines.join('\n'), style: 'white-space: pre');
    }
  }
}
