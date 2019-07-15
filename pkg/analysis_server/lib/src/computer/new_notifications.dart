// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/analysis_server.dart' show AnalysisServer;
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/domains/analysis/occurrences.dart';
import 'package:analysis_server/src/domains/analysis/occurrences_dart.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';

void new_sendDartNotificationNavigation(
    AnalysisServer analysisServer, ResolvedUnitResult result) {
  var unit = result.unit;
  if (unit != null) {
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    computeDartNavigation(
        analysisServer.resourceProvider, collector, unit, null, null);
    collector.createRegions();
    var params = new protocol.AnalysisNavigationParams(
        result.path, collector.regions, collector.targets, collector.files);
    analysisServer.sendNotification(params.toNotification());
  }
}

void new_sendDartNotificationOccurrences(
    AnalysisServer analysisServer, ResolvedUnitResult result) {
  var unit = result.unit;
  if (unit != null) {
    OccurrencesCollectorImpl collector = new OccurrencesCollectorImpl();
    addDartOccurrences(collector, unit);
    var params = new protocol.AnalysisOccurrencesParams(
        result.path, collector.allOccurrences);
    analysisServer.sendNotification(params.toNotification());
  }
}

void new_sendErrorNotification(
    AnalysisServer analysisServer, ResolvedUnitResult result) {
  var serverErrors = protocol.doAnalysisError_listFromEngine(result);
  var params = new protocol.AnalysisErrorsParams(result.path, serverErrors);
  analysisServer.sendNotification(params.toNotification());
}
