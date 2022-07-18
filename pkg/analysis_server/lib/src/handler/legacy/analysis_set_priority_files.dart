// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/plugin/request_converter.dart';

/// The handler for the `analysis.setPriorityFiles` request.
class AnalysisSetPriorityFilesHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisSetPriorityFilesHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params = AnalysisSetPriorityFilesParams.fromRequest(request);

    server.analyticsManager.startedSetPriorityFiles(params);

    for (var file in params.files) {
      if (!server.isAbsoluteAndNormalized(file)) {
        sendResponse(Response.invalidFilePathFormat(request, file));
        return;
      }
    }

    server.setPriorityFiles(request.id, params.files);
    //
    // Forward the request to the plugins.
    //
    var converter = RequestConverter();
    server.pluginManager.setAnalysisSetPriorityFilesParams(
        converter.convertAnalysisSetPriorityFilesParams(params));
    //
    // Send the response.
    //
    sendResult(AnalysisSetPriorityFilesResult());
  }
}
