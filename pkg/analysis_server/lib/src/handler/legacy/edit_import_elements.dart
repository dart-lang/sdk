// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/import_elements_computer.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// The handler for the `edit.importElements` request.
class EditImportElementsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditImportElementsHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = EditImportElementsParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    //
    // Prepare the resolved unit.
    //
    var result = await server.getResolvedUnit(file);
    if (result == null) {
      sendResponse(Response.importElementsInvalidFile(request));
      return;
    }
    var libraryUnit = result.libraryElement.definingCompilationUnit;
    if (libraryUnit != result.unit.declaredElement) {
      // The file in the request is a part of a library. We need to pass the
      // defining compilation unit to the computer, not the part.
      result = await server.getResolvedUnit(libraryUnit.source.fullName);
      if (result == null) {
        sendResponse(Response.importElementsInvalidFile(request));
        return;
      }
    }
    //
    // Compute the edits required to import the required elements.
    //
    var computer = ImportElementsComputer(server.resourceProvider, result);
    var change = await computer.createEdits(params.elements);
    var edits = change.edits;
    var edit = edits.isEmpty ? null : edits[0];
    //
    // Send the response.
    //
    sendResult(EditImportElementsResult(edit: edit));
  }
}
