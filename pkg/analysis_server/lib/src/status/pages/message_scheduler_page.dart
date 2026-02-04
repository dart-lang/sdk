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
    var listener = server.messageScheduler.listener;

    buf.writeln('<style> .container { max-width: 1600px; } </style>');

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

    var lines = listener.getMessageLog();
    if (lines.isNotEmpty) {
      h3('Messages');
      buf.writeln('<table>');
      buf.writeln(
        '<tr><th>Message</th><th>Pending (on pending)</th><th>Active (on pending)</th><th>Pending (on active)</th><th>Active (on active)</th><th>Queue Time</th><th>Process Time</th><th>Cancelled</th></tr>',
      );
      for (var line in lines) {
        var data = jsonDecode(line) as Map<String, dynamic>;
        buf.writeln('<tr>');
        buf.writeln('<td>${data['message']}</td>');
        _writeCollapsibleList(
          data['pendingMessageCount'] as int,
          (data['pendingMessages'] as List?)?.cast<String>() ?? [],
        );
        _writeCollapsibleList(
          data['activeOnPendingMessageCount'] as int,
          (data['activeOnPendingMessages'] as List?)?.cast<String>() ?? [],
        );
        _writeCollapsibleList(
          data['pendingOnActiveMessageCount'] as int,
          (data['pendingOnActiveMessages'] as List?)?.cast<String>() ?? [],
        );
        _writeCollapsibleList(
          data['activeOnActiveMessageCount'] as int,
          (data['activeOnActiveMessages'] as List?)?.cast<String>() ?? [],
        );
        buf.writeln('<td>${data['queueTime']}</td>');
        buf.writeln('<td>${data['processTime']}</td>');
        buf.writeln('<td>${data['wasCancelled']}</td>');
        buf.writeln('</tr>');
      }
      buf.writeln('</table>');
    }
  }

  void _writeCollapsibleList(int count, List<String> messages) {
    if (count > 0) {
      buf.writeln('<td>');
      buf.writeln('<details>');
      buf.writeln('<summary>$count</summary>');
      for (var message in messages) {
        buf.writeln('$message<br>');
      }
      buf.writeln('</details>');
      buf.writeln('</td>');
    } else {
      buf.writeln('<td>$count</td>');
    }
  }
}
