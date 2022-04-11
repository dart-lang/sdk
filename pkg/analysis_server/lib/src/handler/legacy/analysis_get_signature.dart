// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_signature.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// The handler for the `analysis.getSignature` request.
class AnalysisGetSignatureHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisGetSignatureHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = AnalysisGetSignatureParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    // Prepare the resolved units.
    var result = await server.getResolvedUnit(file);

    if (result == null || !result.exists) {
      sendResponse(Response.getSignatureInvalidFile(request));
      return;
    }

    // Ensure the offset provided is a valid location in the file.
    final unit = result.unit;
    final computer = DartUnitSignatureComputer(
        server.getDartdocDirectiveInfoFor(result), unit, params.offset);
    if (!computer.offsetIsValid) {
      sendResponse(Response.getSignatureInvalidOffset(request));
      return;
    }

    // Try to get a signature.
    final signature = computer.compute();
    if (signature == null) {
      sendResponse(Response.getSignatureUnknownFunction(request));
      return;
    }

    sendResult(signature);
  }
}
