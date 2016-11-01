// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart'
    show AnalysisError;
import 'package:analysis_server/src/analysis_server.dart' show AnalysisServer;
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';

void new_sendErrorNotification(
    AnalysisServer analysisServer, AnalysisResult result) {
  List<AnalysisError> serverErrors = <AnalysisError>[];
  for (var error in result.errors) {
    serverErrors
        .add(protocol.newAnalysisError_fromEngine(new LineInfo([0]), error));
  }
  var params = new protocol.AnalysisErrorsParams(result.path, serverErrors);
  analysisServer.sendNotification(params.toNotification());
}
