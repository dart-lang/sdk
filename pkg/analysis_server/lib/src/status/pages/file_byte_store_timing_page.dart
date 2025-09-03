// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';

class FileByteStoreTimingPage extends DiagnosticPageWithNav
    with PerformanceChartMixin {
  FileByteStoreTimingPage(DiagnosticsSite site)
    : super(
        site,
        'file-byte-store-timing',
        'FileByteStore timing',
        description: 'FileByteStore timing statistics.',
        indentInNav: true,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    h3('FileByteStore Timings');

    var byteStoreTimings = server.byteStoreTimings
        ?.where(
          (timing) => timing.readCount != 0 || timing.readTime != Duration.zero,
        )
        .toList();
    if (byteStoreTimings == null || byteStoreTimings.isEmpty) {
      p(
        'There are currently no timings. '
        'Try refreshing after the server has performed initial analysis.',
      );
      return;
    }

    buf.writeln('<table>');
    buf.writeln(
      '<tr><th>Files Read</th><th>Time Taken</th><th>&nbsp;</th></tr>',
    );
    for (var i = 0; i < byteStoreTimings.length; i++) {
      var timing = byteStoreTimings[i];
      if (timing.readCount == 0) {
        continue;
      }

      var nextTiming = i + 1 < byteStoreTimings.length
          ? byteStoreTimings[i + 1]
          : null;
      var duration = (nextTiming?.time ?? DateTime.now()).difference(
        timing.time,
      );
      var description =
          'Between <em>${timing.reason}</em> and <em>${nextTiming?.reason ?? 'now'} (${printMilliseconds(duration.inMilliseconds)})</em>.';
      buf.writeln(
        '<tr>'
        '<td class="right">${timing.readCount} files</td>'
        '<td class="right">${printMilliseconds(timing.readTime.inMilliseconds)}</td>'
        '<td>$description</td>'
        '</tr>',
      );
    }
    buf.writeln('</table>');
  }
}
