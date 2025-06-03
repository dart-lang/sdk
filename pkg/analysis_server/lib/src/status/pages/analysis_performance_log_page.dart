// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/utilities/stream_string_stink.dart';

class AnalysisPerformanceLogPage extends WebSocketLoggingPage {
  AnalysisPerformanceLogPage(DiagnosticsSite site)
    : super(
        site,
        'analysis-performance-log',
        'Analysis performance log',
        description: 'Real-time logging from the analysis performance log',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    writeWebSocketLogPanel();
  }

  @override
  Future<void> handleWebSocket(WebSocket socket) async {
    var logger = server.analysisPerformanceLogger;

    // We were able to attach our temporary sink. Forward all data over the
    // WebSocket and wait for it to close (this is done by the user clicking
    // the Stop button or navigating away from the page).
    var controller = StreamController<String>();
    var sink = StreamStringSink(controller.sink);
    try {
      unawaited(socket.addStream(controller.stream));
      logger.sink.addSink(sink);

      // Wait for the socket to be closed so we can remove the secondary sink.
      var completer = Completer<void>();
      socket.listen(
        null,
        onDone: completer.complete,
        onError: completer.complete,
      );
      await completer.future;
    } finally {
      logger.sink.removeSink(sink);
    }
  }
}
