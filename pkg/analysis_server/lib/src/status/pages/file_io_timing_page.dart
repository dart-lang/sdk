// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';

class FileIoTimingPage extends DiagnosticPageWithNav {
  new(DiagnosticsSite site)
    : super(
        site,
        'file-io-timing',
        'File I/O timing',
        description:
            'Resource provider I/O statistics accumulated since startup.',
        indentInNav: true,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    h3('File I/O Timings');
    p(
      'Calls include failed attempts and exclude reads satisfied by editor '
      'overlays or the file content cache. Byte counts are available for byte '
      'reads only. Watch timings cover synchronous watcher creation.',
    );
    var timings = server.timingResourceProvider.timings;
    if (timings.isEmpty) {
      p('There are currently no resource provider I/O timings.');
      return;
    }

    var operations = timings.keys.toList()..sort();
    buf.writeln('<table>');
    buf.writeln(
      '<tr><th>Operation</th><th>Calls</th><th>Time (ms)</th>'
      '<th>Bytes read</th></tr>',
    );
    for (var operation in operations) {
      var timing = timings[operation]!;
      var milliseconds = timing.elapsed.inMicroseconds / 1000;
      var bytes = operation == 'File.readAsBytesSync'
          ? '${timing.bytesRead}'
          : '&mdash;';
      buf.writeln(
        '<tr><td>${escape(operation)}</td>'
        '<td class="right">${timing.count}</td>'
        '<td class="right">${milliseconds.toStringAsFixed(3)}</td>'
        '<td class="right">$bytes</td></tr>',
      );
    }
    buf.writeln('</table>');
  }
}
