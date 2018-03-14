// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';

void sendFlutterNotificationOutline(AnalysisServer server, String file,
    String content, LineInfo lineInfo, CompilationUnit dartUnit) {
  _sendNotification(server, () {
    var computer =
        new FlutterOutlineComputer(file, content, lineInfo, dartUnit);
    protocol.FlutterOutline outline = computer.compute();
    // send notification
    var params = new protocol.FlutterOutlineParams(file, outline,
        instrumentedCode: computer.instrumentedCode);
    server.sendNotification(params.toNotification());
  });
}

/**
 * Runs the given notification producing function [f], catching exceptions.
 */
void _sendNotification(AnalysisServer server, f()) {
  ServerPerformanceStatistics.notices.makeCurrentWhile(() {
    try {
      f();
    } catch (exception, stackTrace) {
      server.sendServerErrorNotification(
          'Failed to send notification', exception, stackTrace);
    }
  });
}
