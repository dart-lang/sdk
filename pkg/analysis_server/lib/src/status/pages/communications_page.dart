// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';

class CommunicationsPage extends DiagnosticPageWithNav {
  CommunicationsPage(DiagnosticsSite site)
    : super(
        site,
        'communications',
        'Communications',
        description: 'Latency statistics for analysis server communications.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    void writeRow(List<String> data, {List<String?>? classes}) {
      buf.write('<tr>');
      for (var i = 0; i < data.length; i++) {
        var c = classes == null ? null : classes[i];
        if (c != null) {
          buf.write('<td class="$c">${escape(data[i])}</td>');
        } else {
          buf.write('<td>${escape(data[i])}</td>');
        }
      }
      buf.writeln('</tr>');
    }

    buf.writeln('<div class="columns">');

    var performanceAfterStartup = server.performanceAfterStartup;
    if (performanceAfterStartup != null) {
      buf.writeln('<div class="column one-half">');

      h3('Current');
      _writePerformanceTable(performanceAfterStartup, writeRow);

      var time = server.uptime.toString();
      if (time.contains('.')) {
        time = time.substring(0, time.indexOf('.'));
      }
      buf.writeln(writeOption('Uptime', time));

      buf.write('</div>');
    }

    buf.writeln('<div class="column one-half">');

    h3('Startup');
    _writePerformanceTable(server.performanceDuringStartup, writeRow);

    if (performanceAfterStartup != null) {
      var startupTime =
          performanceAfterStartup.startTime -
          server.performanceDuringStartup.startTime;
      buf.writeln(
        writeOption('Initial analysis time', printMilliseconds(startupTime)),
      );
    }

    buf.write('</div>');

    buf.write('</div>');
  }

  void _writePerformanceTable(
    ServerPerformance perf,
    void Function(List<String> data, {List<String?> classes}) writeRow,
  ) {
    var requestCount = perf.requestCount;
    var latencyCount = perf.latencyCount;
    var averageLatency =
        latencyCount > 0 ? (perf.requestLatency ~/ latencyCount) : 0;
    var maximumLatency = perf.maxLatency;
    var slowRequestPercent =
        latencyCount > 0 ? (perf.slowRequestCount / latencyCount) : 0.0;

    buf.write('<table>');
    writeRow(['$requestCount', 'requests'], classes: ['right', null]);
    writeRow(
      ['$latencyCount', 'requests with latency information'],
      classes: ['right', null],
    );
    if (latencyCount > 0) {
      writeRow(
        [printMilliseconds(averageLatency), 'average latency'],
        classes: ['right', null],
      );
      writeRow(
        [printMilliseconds(maximumLatency), 'maximum latency'],
        classes: ['right', null],
      );
      writeRow(
        [printPercentage(slowRequestPercent), '> 150 ms latency'],
        classes: ['right', null],
      );
    }
    buf.write('</table>');
  }
}
