// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/imported_elements_computer.dart';
import 'package:analysis_server/src/domain_analysis_flags.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// The handler for the `analysis.getImportedElements` request.
class AnalysisGetImportedElementsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisGetImportedElementsHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = AnalysisGetImportedElementsParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    //
    // Prepare the resolved unit.
    //
    var result = await server.getResolvedUnit(file);
    if (result == null) {
      sendResponse(Response.getImportedElementsInvalidFile(request));
      return;
    }

    List<ImportedElements> elements;

    //
    // Compute the list of imported elements.
    //
    if (disableManageImportsOnPaste) {
      elements = <ImportedElements>[];
    } else {
      elements =
          ImportedElementsComputer(result.unit, params.offset, params.length)
              .compute();
    }

    sendResult(AnalysisGetImportedElementsResult(elements));
  }
}
