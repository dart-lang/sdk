// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/utilities/progress.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';

/// The handler for the `diagnostic.getDiagnostics` request.
class DiagnosticGetDiagnosticsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  DiagnosticGetDiagnosticsHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var contexts = server.driverMap.values.map(_extractDataFromDriver).toList();
    sendResult(DiagnosticGetDiagnosticsResult(contexts));
  }

  /// Extract context data from the given [driver].
  ContextData _extractDataFromDriver(AnalysisDriver driver) {
    var explicitFileCount = driver.addedFiles.length;
    var knownFileCount = driver.knownFiles.length;
    return ContextData(driver.name, explicitFileCount,
        knownFileCount - explicitFileCount, driver.numberOfFilesToAnalyze, []);
  }
}
