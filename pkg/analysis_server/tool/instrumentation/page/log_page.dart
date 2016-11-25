// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../log/log.dart';
import '../server.dart';
import 'page_writer.dart';

/**
 * A page writer that will produce the page containing access to the full
 * content of the log.
 */
class LogPage extends PageWriter {
  /**
   * The instrumentation log to be written.
   */
  InstrumentationLog log;

  /**
   * The id of the entry groups to be displayed.
   */
  EntryGroup selectedGroup;

  /**
   * The entries in the selected group.
   */
  List<LogEntry> entries;

  /**
   * The index of the first entry to be written.
   */
  int pageStart = 0;

  /**
   * The number of entries to be written, or `null` if all of the entries should
   * be written.
   */
  int pageLength = null;

  /**
   * The number of digits in the event stamps that are the same for every entry.
   */
  int prefixLength;

  /**
   * Initialize a newly created writer to write the content of the given
   * [instrumentationLog].
   */
  LogPage(this.log);

  @override
  void writeBody(StringSink sink) {
    entries = log.entriesInGroup(selectedGroup);
    prefixLength = computePrefixLength(entries);

    writeMenu(sink);
    writeTwoColumns(
        sink, 'leftColumn', _writeLeftColumn, 'rightColumn', _writeRightColumn);
  }

  @override
  void writeScripts(StringSink sink) {
    super.writeScripts(sink);
    sink.writeln(r'''
var highlightedRows = [];
function clearHighlight() {
  for (i = 0; i < highlightedRows.length; i++) {
    setFontWeight(highlightedRows[i], "normal");
  }
}
function highlight(requestId, responseId) {
  clearHighlight();
  setFontWeight(requestId, "bold");
  setFontWeight(responseId, "bold");
  highlightedRows = [requestId, responseId];
}
function setFontWeight(id, weight) {
  var element = document.getElementById(id);
  if (element != null) {
    element.style.fontWeight = weight;
  }
}
function setDetails(detailsContent) {
  var element = document.getElementById("details");
  if (element != null) {
    element.innerHTML = detailsContent;
  }
}
function selectEntryGroup(pageStart) {
  var element = document.getElementById("entryGroup");
  var url = "/log?group=" + element.value;
  window.location.assign(url);
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
   * Return the number of milliseconds elapsed between the [startEntry] and the
   * [endEntry], or a question .
   */
  String _getDuration(LogEntry startEntry, LogEntry endEntry) {
    if (startEntry != null && endEntry != null) {
      return (endEntry.timeStamp - startEntry.timeStamp).toString();
    }
    return '?';
  }

  /**
   * Write the given log [entry] to the given [sink].
   */
  void _writeEntry(StringSink sink, LogEntry entry) {
    String id = null;
    String clickHandler = 'clearHighlight()';
    String icon = '';
    String description = entry.kindName;
    if (entry is RequestEntry) {
      String entryId = entry.id;
      id = 'req$entryId';
      clickHandler = 'highlight(\'req$entryId\', \'res$entryId\')';
      icon = '&rarr;';
      description = entry.method;
    } else if (entry is ResponseEntry) {
      String entryId = entry.id;
      RequestEntry request = log.requestFor(entry);
      id = 'res$entryId';
      clickHandler = 'highlight(\'req$entryId\', \'res$entryId\')';
      icon = '&larr;';
      if (request != null) {
        int latency = entry.timeStamp - request.timeStamp;
        description =
            '${request.method} <span class="gray">($latency ms)</span>';
      }
    } else if (entry is NotificationEntry) {
      id = 'e${entry.index}';
      LogEntry pairedEntry = log.pairedEntry(entry);
      if (pairedEntry != null) {
        String pairedId = 'e${pairedEntry.index}';
        clickHandler = 'highlight(\'$id\', \'$pairedId\')';
      }
      icon = '&larr;';
      description = entry.event;
      if (entry.isServerStatus) {
        var analysisStatus = entry.param('analysis');
        if (analysisStatus is Map) {
          if (analysisStatus['isAnalyzing']) {
            description =
                '$description <span class="gray">(analysis)</span> (<a href="${WebServer.taskPath}?analysisStart=${entry.index}">tasks</a>)';
          } else {
            String duration = _getDuration(pairedEntry, entry);
            description =
                '$description <span class="gray">(analysis - $duration ms)</span>';
          }
        }
        var pubStatus = entry.param('pub');
        if (pubStatus is Map) {
          if (pubStatus['isListingPackageDirs']) {
            description = '$description <span class="gray">(pub)</span>';
          } else {
            String duration = _getDuration(pairedEntry, entry);
            description =
                '$description <span class="gray">(pub - $duration ms)</span>';
          }
        }
      }
    } else if (entry is TaskEntry) {
      description = entry.description;
    } else if (entry is ErrorEntry) {
      description = '<span class="error">$description</span>';
    } else if (entry is ExceptionEntry) {
      description = '<span class="error">$description</span>';
    } else if (entry is MalformedLogEntry) {
      description = '<span class="error">$description</span>';
    }
    id = id == null ? '' : 'id="$id" ';
    clickHandler = '$clickHandler; setDetails(\'${escape(entry.details())}\')';
    String timeStamp = entry.timeStamp.toString();
    if (prefixLength > 0) {
      timeStamp = timeStamp.substring(prefixLength);
    }

    sink.writeln('<tr ${id}onclick="$clickHandler">');
    sink.writeln('<td>$icon</td>');
    sink.writeln('<td>');
    sink.writeln(timeStamp);
    sink.writeln('</td>');
    sink.writeln('<td style="white-space:nowrap;">');
    sink.writeln(description);
    sink.writeln('</td>');
    sink.writeln('</tr>');
  }

  /**
   * Write the entries in the instrumentation log to the given [sink].
   */
  void _writeLeftColumn(StringSink sink) {
    int length = entries.length;
    int pageEnd =
        pageLength == null ? length : math.min(pageStart + pageLength, length);
    //
    // Write the header of the column.
    //
    sink.writeln('<div class="columnHeader">');
    sink.writeln('<div style="float: left">');
    sink.writeln('<select id="entryGroup" onchange="selectEntryGroup()">');
    for (EntryGroup group in EntryGroup.groups) {
      sink.write('<option value="');
      sink.write(group.id);
      sink.write('"');
      if (group == selectedGroup) {
        sink.write(' selected');
      }
      sink.write('>');
      sink.write(group.name);
      sink.writeln('</option>');
    }
    sink.writeln('</select>');
    if (length == 0) {
      sink.writeln('No matching events');
    } else {
      sink.writeln('Events $pageStart - ${pageEnd - 1} of $length');
    }
    sink.writeln('</div>');

    sink.writeln('<div style="float: right">');
    if (pageStart == 0) {
      sink.writeln('<button type="button" disabled><b>&lt;</b></button>');
    } else {
      sink.write('<button type="button">');
      sink.write(
          '<a href="${WebServer.logPath}?group=${selectedGroup.id}&start=${pageStart - pageLength}">');
      sink.write('<b>&lt;</b>');
      sink.writeln('</a></button>');
    }
    // TODO(brianwilkerson) Add a text field for selecting the start index.
    if (pageEnd == length) {
      sink.writeln('<button type="button" disabled><b>&gt;</b></button>');
    } else {
      sink.write('<button type="button">');
      sink.write(
          '<a href="${WebServer.logPath}?group=${selectedGroup.id}&start=${pageStart + pageLength}">');
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
    sink.writeln('<th class="narrow"></th>');
    sink.writeln('<th>Time</th>');
    sink.writeln('<th>Kind</th>');
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
    sink.writeln('<p><b>Entry Details</b></p>');
    sink.writeln('</div>');
    sink.writeln('<div id="details"></div>');
  }
}
