// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/session_logger/session_logger_sink.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';

class SessionLogPage extends DiagnosticPageWithNav implements PostablePage {
  static const _captureFormId = 'capture-entries';

  SessionLogPage(DiagnosticsSite site)
    : super(
        site,
        'session-log',
        'Session communications log',
        description:
            'A log containing all of the communications between the analysis '
            'server and other processes.',
        indentInNav: false,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var sink = server.sessionLogger.sink;
    if (sink is! SessionLoggerInMemorySink) {
      buf.write('Internal error.');
      return;
    }
    if (sink.isCapturingEntries) {
      buf.write('''
<form action="$path?$_captureFormId=false" method="post">
<input type="submit" class="btn" value="Stop capturing entries" />
</form>
''');
      h1('Current log contents (in progress)');
    } else {
      buf.write('''
<form action="$path?$_captureFormId=true" method="post">
<input type="submit" class="btn" value="Start capturing entries" />
</form>
''');
      h1('Previous log contents');
    }
    // Output the current entries.
    var buffer = StringBuffer();
    var entries = sink.capturedEntries;
    for (var entry in entries) {
      buffer.writeln(json.encode(entry));
    }
    pre(() {
      buf.write('<code>');
      buf.write(escape('$buffer'));
      buf.writeln('</code>');
    });
  }

  @override
  Future<String> handlePost(Map<String, String> params) async {
    var newCaptureState = params[_captureFormId];
    if (newCaptureState != null) {
      var sink = server.sessionLogger.sink;
      if (sink is SessionLoggerInMemorySink) {
        if (newCaptureState == 'true') {
          sink.startCapture();
        } else {
          sink.stopCapture();
        }
      }
    }
    return path;
  }
}
