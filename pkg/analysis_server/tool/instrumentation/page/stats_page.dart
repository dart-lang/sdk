// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import '../log/log.dart';
import 'page_writer.dart';

/**
 * A page writer that will produce the page containing statistics about an
 * instrumentation log.
 */
class StatsPage extends PageWriter {
  /**
   * The instrumentation log to be written.
   */
  final InstrumentationLog log;

  /**
   * A table mapping the kinds of entries in the log to the number of each kind.
   */
  final Map<String, int> entryCounts = new HashMap<String, int>();

  /**
   * The number of responses that returned an error.
   */
  int errorCount = 0;

  /**
   * A table mapping request method names to a list of the latencies associated
   * with those requests, where the latency is defined to be the time between
   * when the request was sent by the client and when the server started
   * processing the request.
   */
  final Map<String, List<int>> latencyData = new HashMap<String, List<int>>();

  /**
   * A list of the number of milliseconds between a completion request and the
   * first event for that request.
   */
  final List<int> completionResponseTimes = <int>[];

  /**
   * Initialize a newly created page writer to write information about the given
   * instrumentation [log].
   */
  StatsPage(this.log) {
    _processEntries(log.logEntries);
  }

  @override
  void writeBody(StringSink sink) {
    writeMenu(sink);
    writeTwoColumns(
        sink, 'leftColumn', _writeLeftColumn, 'rightColumn', _writeRightColumn);
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
   * Return the mean of the values in the given list of [values].
   */
  int _mean(List<int> values) {
    int sum = values.fold(0, (int sum, int latency) => sum + latency);
    return sum ~/ values.length;
  }

  /**
   * Return a table mapping the kinds of the given [entries] to the number of
   * each kind.
   */
  void _processEntries(List<LogEntry> entries) {
    void increment/*<K>*/(Map<dynamic/*=K*/, int> map, dynamic/*=K*/ key) {
      map[key] = (map[key] ?? 0) + 1;
    }

    for (LogEntry entry in entries) {
      String kind = entry.kind;
      increment(entryCounts, kind);
      if (entry is ResponseEntry) {
        if (entry.result('error') != null) {
          errorCount++;
        }
      }

      if (entry is RequestEntry) {
        String method = entry.method;
        int latency = entry.timeStamp - entry.clientRequestTime;
        latencyData.putIfAbsent(method, () => new List<int>()).add(latency);
        if (method == 'completion.getSuggestions') {
          ResponseEntry response = log.responseFor(entry);
          if (response != null) {
            String id = response.result('id');
            if (id != null) {
              List<NotificationEntry> events = log.completionEventsWithId(id);
              if (events != null && events.length > 0) {
                completionResponseTimes
                    .add(events[0].timeStamp - entry.timeStamp);
              }
            }
          }
        }
      }
    }
  }

  void _writeLeftColumn(StringSink sink) {
    List<String> filePaths = log.logFilePaths;
    List<LogEntry> entries = log.logEntries;
    DateTime startDate = entries[0].toTime;
    DateTime endDate = entries[entries.length - 1].toTime;
    Duration duration = endDate.difference(startDate);
    List<String> entryKinds = entryCounts.keys.toList()..sort();

    sink.writeln('<h3>General</h3>');
    sink.writeln('<p>');
    if (filePaths.length == 1) {
      sink.write('<span class="label">Log file:</span> ');
      sink.write(filePaths[0]);
    } else {
      sink.write('<span class="label">Log files:</span> ');
      bool needsSeparator = false;
      for (String path in filePaths) {
        if (needsSeparator) {
          sink.write(', ');
        } else {
          needsSeparator = true;
        }
        sink.write(path);
      }
    }
    sink.writeln('<br>');
    sink.write('<span class="label">Start time:</span> ');
    writeDate(sink, startDate);
    sink.writeln('<br>');
    sink.write('<span class="label">End time:</span> ');
    writeDate(sink, endDate);
    sink.writeln('<br>');
    sink.write('<span class="label">Duration:</span> ');
    sink.write(duration.toString());
    sink.writeln('</p>');

    sink.writeln('<h3>Entries</h3>');
    sink.write('<p>');
    sink.write('<span class="label">Number of entries:</span> ');
    sink.write(entries.length);
    sink.writeln('</p>');
    sink.writeln('<table>');
    sink.writeln('<tr><th>count</th><th>kind</th></tr>');
    for (String kind in entryKinds) {
      sink.write('<tr><td class="int">');
      sink.write(entryCounts[kind]);
      sink.write('</td><td>');
      sink.write(kind);
      sink.writeln('</td></tr>');
    }
    sink.write('<tr><td class="int">');
    sink.write(entries.length);
    sink.writeln('</td><td>Total</td></tr>');
    sink.writeln('</table>');
  }

  void _writeRightColumn(StringSink sink) {
    List<String> methodNames = latencyData.keys.toList()..sort();
    completionResponseTimes.sort();

    sink.writeln('<h3>Latency</h3>');
    sink.write('<p>');
    sink.write('<span class="label">Latency by method</span>');
    sink.writeln('</p>');
    sink.writeln('<table>');
    sink.writeln(
        '<tr><th>min</th><th>mean</th><th>max</th><th>method</th></tr>');
    for (String method in methodNames) {
      List<int> latencies = latencyData[method]..sort();
      // TODO(brianwilkerson) Add a spark-line distribution graph.
      sink.write('<tr><td class="int">');
      sink.write(latencies[0]);
      sink.write('</td><td class="int">');
      sink.write(_mean(latencies));
      sink.write('</td><td class="int">');
      sink.write(latencies[latencies.length - 1]);
      sink.write('</td><td>');
      sink.write(method);
      sink.writeln('</td></tr>');
    }
    sink.writeln('</table>');

    sink.writeln('<h3>Completion</h3>');
    sink.write('<p>');
    sink.write('<span class="label">Time to first notification:</span> ');
    sink.write(completionResponseTimes[0]);
    sink.write(', ');
    sink.write(_mean(completionResponseTimes));
    sink.write(', ');
    sink.write(completionResponseTimes[completionResponseTimes.length - 1]);
    sink.writeln('</p>');
  }
}
