// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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

    void writeRow(MessageData data, {required bool isActive}) {
      var pendingDuration = (data.activeTime ?? now) - data.pendingTime;
      buf.writeln('<tr>');
      buf.writeln('<td>${data.message.id}</td>');
      buf.writeln('<td>${data.pendingMessageCount}</td>');
      buf.writeln('<td>$pendingDuration</td>');
      if (isActive) {
        buf.writeln('<td>${data.activeMessageCount}</td>');
        buf.writeln('<td>${now - data.activeTime!}</td>');
      } else {
        buf.writeln('<td>-</td>');
        buf.writeln('<td>-</td>');
      }
      buf.writeln('</tr>');
    }

    var (:pending, :active) = listener.pendingAndActiveMessages;

    h3('Pending messages');
    if (pending.isEmpty) {
      p('none');
    } else {
      pending.sort(
        (first, second) => first.pendingTime.compareTo(second.pendingTime),
      );
      buf.writeln('<table>');
      buf.writeln(
        '<tr><th>Message ID</th><th>Pending Ahead</th><th>Time in Pending</th><th>Active Ahead</th><th>Time Running</th></tr>',
      );
      for (var data in pending) {
        writeRow(data, isActive: false);
      }
      buf.writeln('</table>');
    }

    h3('Active messages');
    if (active.isEmpty) {
      p('none');
    } else {
      active.sort(
        (first, second) => first.activeTime!.compareTo(second.activeTime!),
      );
      buf.writeln('<table>');
      buf.writeln(
        '<tr><th>Message ID</th><th>Pending Ahead</th><th>Time in Pending</th><th>Active Ahead</th><th>Time Running</th></tr>',
      );
      for (var data in active) {
        writeRow(data, isActive: true);
      }
      buf.writeln('</table>');
    }

    var lines = listener.completedMessageLog;
    if (lines.isNotEmpty) {
      h3('Completed messages');
      buf.writeln('<table>');
      buf.writeln(
        '<tr><th>Message</th><th>Pending Count</th><th>Active Count</th><th>Pending Duration</th><th>Active Duration</th><th>Cancelled</th></tr>',
      );
      for (var line in lines) {
        var data = jsonDecode(line) as Map<String, dynamic>;
        buf.writeln('<tr>');
        buf.writeln('<td>${data['message']}</td>');
        buf.writeln('<td>${data['pendingMessageCount']}</td>');
        buf.writeln('<td>${data['activeMessageCount']}</td>');
        buf.writeln('<td>${data['pendingDuration']}</td>');
        buf.writeln('<td>${data['activeDuration']}</td>');
        buf.writeln('<td>${data['wasCancelled']}</td>');
        buf.writeln('</tr>');
      }
      buf.writeln('</table>');
    }
  }
}
