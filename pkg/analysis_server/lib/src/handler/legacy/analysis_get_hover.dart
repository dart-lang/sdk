// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// The handler for the `analysis.getHover` request.
class AnalysisGetHoverHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisGetHoverHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = AnalysisGetHoverParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    // Prepare the resolved units.
    var result = await server.getResolvedUnit(file);
    if (result is! ResolvedUnitResult) {
      sendResponse(Response.fileNotAnalyzed(request, file));
      return;
    }
    var unit = result.unit;

    // Prepare the hovers.
    var hovers = <HoverInformation>[];
    var computer = DartUnitHoverComputer(
        server.getDartdocDirectiveInfoFor(result), unit, params.offset);
    var hoverInformation = computer.compute();
    if (hoverInformation != null) {
      hovers.add(hoverInformation);
    }

    // Send the response.
    sendResult(AnalysisGetHoverResult(hovers));
  }
}
