// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol;
import 'package:analysis_server/src/analysis_server.dart' show AnalysisServer;
import 'package:analysis_server/src/domains/analysis/navigation.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';

void new_sendDartNotificationNavigation(
    AnalysisServer analysisServer, AnalysisResult result) {
  var unit = result.unit;
  if (unit != null) {
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    computeSimpleDartNavigation(collector, unit);
    collector.createRegions();
    var params = new protocol.AnalysisNavigationParams(
        result.path, collector.regions, collector.targets, collector.files);
    analysisServer.sendNotification(params.toNotification());
  }
}

void new_sendErrorNotification(
    AnalysisServer analysisServer, AnalysisResult result) {
  var serverErrors = <protocol.AnalysisError>[];
  for (AnalysisError error in result.errors) {
    serverErrors
        .add(protocol.newAnalysisError_fromEngine(result.lineInfo, error));
  }
  var params = new protocol.AnalysisErrorsParams(result.path, serverErrors);
  analysisServer.sendNotification(params.toNotification());
}
