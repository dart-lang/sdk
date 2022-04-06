// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// The handler for the `analysis.setAnalysisRoots` request.
class AnalysisSetAnalysisRootsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisSetAnalysisRootsHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = AnalysisSetAnalysisRootsParams.fromRequest(request);
    var includedPathList = params.included;
    var excludedPathList = params.excluded;

    server.options.analytics?.sendEvent('analysis', 'setAnalysisRoots',
        value: includedPathList.length);

    // validate
    for (var path in includedPathList) {
      if (!server.isValidFilePath(path)) {
        sendResponse(Response.invalidFilePathFormat(request, path));
        return;
      }
    }
    for (var path in excludedPathList) {
      if (!server.isValidFilePath(path)) {
        sendResponse(Response.invalidFilePathFormat(request, path));
        return;
      }
    }

    var detachableFileSystemManager = server.detachableFileSystemManager;
    if (detachableFileSystemManager != null) {
      // TODO(scheglov) remove the last argument
      detachableFileSystemManager
          .setAnalysisRoots(request.id, includedPathList, excludedPathList, {});
    } else {
      await server.setAnalysisRoots(
          request.id, includedPathList, excludedPathList);
    }
    sendResult(AnalysisSetAnalysisRootsResult());
  }
}
