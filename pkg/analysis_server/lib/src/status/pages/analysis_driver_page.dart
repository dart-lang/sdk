// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

class AnalysisDriverPage extends DiagnosticPageWithNav implements PostablePage {
  static const _resetFormId = 'reset-driver-timers';

  AnalysisDriverPage(DiagnosticsSite site)
    : super(
        site,
        'analysis-driver',
        'Analysis driver',
        description:
            'Timing statistics collected by the analysis driver scheduler since the last reset.',
        indentInNav: true,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    // Output the current values.
    var buffer = StringBuffer();
    server.analysisDriverScheduler.accumulatedPerformance.write(buffer: buffer);
    pre(() {
      buf.write('<code>');
      buf.write(escape('$buffer'));
      buf.writeln('</code>');
    });

    // Add a button to reset the timers.
    buf.write('''
<form action="$path?$_resetFormId=true" method="post">
<input type="submit" class="btn btn-danger" value="Reset Timers" />
</form>
''');
  }

  @override
  Future<String> handlePost(Map<String, String> params) async {
    if (params[_resetFormId]?.isNotEmpty ?? false) {
      server.analysisDriverScheduler.accumulatedPerformance =
          OperationPerformanceImpl('<scheduler>');
    }

    return path;
  }
}
