// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';

/// Instances of the class [DiagnosticDomainHandler] implement a
/// [RequestHandler] that handles requests in the `diagnostic` domain.
class DiagnosticDomainHandler implements RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  DiagnosticDomainHandler(this.server);

  /// Answer the `diagnostic.getDiagnostics` request.
  Response computeDiagnostics(Request request) {
    var contexts = server.driverMap.values.map(extractDataFromDriver).toList();
    return DiagnosticGetDiagnosticsResult(contexts).toResponse(request.id);
  }

  /// Extract context data from the given [driver].
  ContextData extractDataFromDriver(AnalysisDriver driver) {
    var explicitFileCount = driver.addedFiles.length;
    var knownFileCount = driver.knownFiles.length;
    return ContextData(driver.name, explicitFileCount,
        knownFileCount - explicitFileCount, driver.numberOfFilesToAnalyze, []);
  }

  /// Answer the `diagnostic.getServerPort` request.
  Future handleGetServerPort(Request request) async {
    try {
      // Open a port (or return the existing one).
      var port = await server.diagnosticServer.getServerPort();
      server.sendResponse(
          DiagnosticGetServerPortResult(port).toResponse(request.id));
    } catch (error) {
      server.sendResponse(Response.debugPortCouldNotBeOpened(request, error));
    }
  }

  @override
  Response handleRequest(Request request) {
    try {
      var requestName = request.method;
      if (requestName == DIAGNOSTIC_REQUEST_GET_DIAGNOSTICS) {
        return computeDiagnostics(request);
      } else if (requestName == DIAGNOSTIC_REQUEST_GET_SERVER_PORT) {
        handleGetServerPort(request);
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}

class MemoryCpuSample {
  final DateTime time;
  final double cpuPercentage;
  final int memoryKB;

  MemoryCpuSample(this.time, this.cpuPercentage, this.memoryKB);
}
