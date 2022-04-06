// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// The handler for the `analysis.getErrors` request.
class AnalysisGetErrorsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisGetErrorsHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var file = AnalysisGetErrorsParams.fromRequest(request).file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var result = await server.getResolvedUnit(file);

    if (result == null) {
      sendResponse(Response.getErrorsInvalidFile(request));
      return;
    }

    var protocolErrors = doAnalysisError_listFromEngine(result);
    sendResult(AnalysisGetErrorsResult(protocolErrors));
  }
}
