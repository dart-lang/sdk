// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/refactoring_performance.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:path/path.dart' as path;

class RefactoringsPage extends DiagnosticPageWithNav
    with PerformanceChartMixin {
  RefactoringsPage(DiagnosticsSite site)
    : super(
        site,
        'getRefactorings',
        'Refactorings',
        description: 'Latency and timing statistics for getting refactorings.',
        indentInNav: true,
      );

  path.Context get pathContext => server.resourceProvider.pathContext;

  List<GetRefactoringsPerformance> get performanceItems =>
      server.recentPerformance.getRefactorings.items.toList();

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var requests = performanceItems;

    if (requests.isEmpty) {
      blankslate('No refactoring requests recorded.');
      return;
    }

    var fastCount = requests
        .where((c) => c.elapsedInMilliseconds <= 100)
        .length;
    p(
      '${requests.length} results; ${printPercentage(fastCount / requests.length)} within 100ms.',
    );

    drawChart(requests);

    // Emit the data as a table
    buf.writeln('<table>');
    buf.writeln(
      '<tr><th>Time</th><th align = "left" title="Time in refactoring producer `compute()` calls">Producer.compute()</th><th align = "left">Source</th><th>Snippet</th></tr>',
    );

    for (var request in requests) {
      var shortName = pathContext.basename(request.path);
      var (:time, :details) = producerTimeAndDetails(request);
      buf.writeln(
        '<tr>'
        '<td class="pre right"><a href="timing?id=${request.id}&kind=getRefactorings">'
        '${formatLatencyTiming(request.elapsedInMilliseconds, request.requestLatency)}'
        '</a></td>'
        '<td><abbr title="$details">${printMilliseconds(time)}</abbr></td>'
        '<td>${escape(shortName)}</td>'
        '<td><code>${escape(request.snippet)}</code></td>'
        '</tr>',
      );
    }
    buf.writeln('</table>');
  }
}
