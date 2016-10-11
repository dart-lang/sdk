// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../log/log.dart';
import '../server.dart';
import 'page_writer.dart';

/**
 * A class used to write a human-readable version of the tasks executed within a
 * single analysis step.
 */
class TaskPage extends PageWriter {
  /**
   * The instrumentation log to be written.
   */
  final InstrumentationLog log;

  /**
   * The index of the entry representing the start of an analysis session.
   */
  int analysisStart = 0;

  /**
   * The index of the first task to be written.
   */
  int pageStart = 0;

  /**
   * The number of tasks to be written, or `null` if all of the tasks should
   * be written.
   */
  int pageLength = null;

  /**
   * The number of digits in the event stamps that are the same for every task.
   */
  int prefixLength;

  /**
   * Initialize a newly created page writer to write a single page worth of
   * tasks.
   */
  TaskPage(this.log);

  @override
  void writeBody(StringSink sink) {
    writeMenu(sink);
    writeTwoColumns(
        sink, 'leftColumn', _writeLeftColumn, 'rightColumn', _writeRightColumn);
  }

  @override
  void writeScripts(StringSink sink) {
    super.writeScripts(sink);
    sink.writeln(r'''
function setDetails(detailsContent) {
  var element = document.getElementById("details");
  if (element != null) {
    element.innerHTML = detailsContent;
  }
}
''');
  }

  /**
   * Write the content of the style sheet (without the 'script' tag) for the
   * page to the given [sink].
   */
  void writeStyleSheet(StringSink sink) {
    super.writeStyleSheet(sink);
    writeTwoColumnStyles(sink, 'leftColumn', 'rightColumn');
  }

  /**
   * Write the given log [entry] to the given [sink].
   */
  void _writeEntry(StringSink sink, TaskEntry entry) {
    String clickHandler = 'setDetails(\'${escape(entry.details())}\')';
    String timeStamp = entry.timeStamp.toString();
    if (prefixLength > 0) {
      timeStamp = timeStamp.substring(prefixLength);
    }

    sink.writeln('<tr onclick="$clickHandler">');
    sink.writeln('<td>');
    sink.writeln(timeStamp);
    sink.writeln('</td>');
    sink.writeln('<td>');
    sink.writeln(entry.taskName);
    sink.writeln('</td>');
    sink.writeln('<td style="white-space:nowrap;">');
    sink.writeln(entry.target);
    sink.writeln('</td>');
    sink.writeln('</tr>');
  }

  /**
   * Write the entries in the instrumentation log to the given [sink].
   */
  void _writeLeftColumn(StringSink sink) {
    List<TaskEntry> entries = log.taskEntriesFor(analysisStart);
    prefixLength = computePrefixLength(entries);
    int length = entries.length;
    int pageEnd =
        pageLength == null ? length : math.min(pageStart + pageLength, length);
    //
    // Write the header of the column.
    //
    sink.writeln('<div class="columnHeader">');
    sink.writeln('<div style="float: left">');
    sink.writeln('Tasks $pageStart - ${pageEnd - 1} of ${length - 1}');
    sink.writeln('</div>');

    sink.writeln('<div style="float: right">');
    if (pageStart == 0) {
      sink.writeln('<button type="button" disabled><b>&lt;</b></button>');
    } else {
      sink.write('<button type="button">');
      sink.write(
          '<a href="${WebServer.taskPath}?analysisStart=$analysisStart&start=${pageStart - pageLength}">');
      sink.write('<b>&lt;</b>');
      sink.writeln('</a></button>');
    }
    // TODO(brianwilkerson) Add a text field for selecting the start index.
    if (pageEnd == length) {
      sink.writeln('<button type="button" disabled><b>&gt;</b></button>');
    } else {
      sink.write('<button type="button">');
      sink.write(
          '<a href="${WebServer.taskPath}?analysisStart=$analysisStart&start=${pageStart + pageLength}">');
      sink.write('<b>&gt;</b>');
      sink.writeln('</a></button>');
    }
    sink.writeln('</div>');
    sink.writeln('</div>');
    //
    // Write the main body of the column.
    //
    sink.writeln('<table class="fullWidth">');
    sink.writeln('<tr>');
    sink.writeln('<th>Time</th>');
    sink.writeln('<th>Task</th>');
    sink.writeln('<th>Target</th>');
    sink.writeln('</tr>');
    for (int i = pageStart; i < pageEnd; i++) {
      LogEntry entry = entries[i];
      _writeEntry(sink, entry);
    }
    sink.writeln('</table>');
  }

  /**
   * Write a placeholder to the given [sink] where the details of a selected
   * entry can be displayed.
   */
  void _writeRightColumn(StringSink sink) {
    //
    // Write the header of the column.
    //
    sink.writeln('<div class="columnHeader">');
    sink.writeln('<p><b>Task Details</b></p>');
    sink.writeln('</div>');
    sink.writeln('<div id="details"></div>');
  }
}
