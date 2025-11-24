// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:path/path.dart' as path;

class CodeCompletionPage extends DiagnosticPageWithNav
    with PerformanceChartMixin {
  CodeCompletionPage(DiagnosticsSite site)
    : super(
        site,
        'code-completion',
        'Code Completion',
        description: 'Latency statistics for code completion.',
        indentInNav: true,
      );

  path.Context get pathContext => server.resourceProvider.pathContext;

  List<CompletionPerformance> get performanceItems =>
      server.recentPerformance.completion.items.toList();

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var completions = performanceItems;

    if (completions.isEmpty) {
      blankslate('No completions recorded.');
      return;
    }

    var fastCount = completions
        .where((c) => c.elapsedInMilliseconds <= 100)
        .length;
    p(
      '${completions.length} results; ${printPercentage(fastCount / completions.length)} within 100ms.',
    );

    drawChart(completions);

    // emit the data as a table
    buf.writeln('<table>');
    buf.writeln(
      '<tr><th>Time</th><th>Computed Results</th><th>Transmitted Results</th><th>Source</th><th>Snippet</th></tr>',
    );
    for (var completion in completions) {
      var shortName = pathContext.basename(completion.path);
      buf.writeln(
        '<tr>'
        '<td class="pre right"><a href="timing?id=${completion.id}&kind=completion">'
        '${formatLatencyTiming(completion.elapsedInMilliseconds, completion.requestLatency)}'
        '</a></td>'
        '<td class="right">${completion.computedSuggestionCountStr}</td>'
        '<td class="right">${completion.transmittedSuggestionCountStr}</td>'
        '<td>${escape(shortName)}</td>'
        '<td><code>${escape(completion.snippet)}</code></td>'
        '</tr>',
      );
    }
    buf.writeln('</table>');
  }
}
