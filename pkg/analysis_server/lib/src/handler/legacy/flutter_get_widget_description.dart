// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/dart/analysis/session.dart';

/// The handler for the `flutter.getWidgetDescription` request.
class FlutterGetWidgetDescriptionHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  FlutterGetWidgetDescriptionHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params = FlutterGetWidgetDescriptionParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var resolvedUnit = await server.getResolvedUnit(file);
    if (resolvedUnit == null) {
      sendResponse(Response.fileNotAnalyzed(request, file));
      return;
    }

    var computer = server.flutterWidgetDescriptions;

    FlutterGetWidgetDescriptionResult? result;
    try {
      result = await computer.getDescription(
        resolvedUnit,
        offset,
      );
    } on InconsistentAnalysisException {
      sendResponse(
        Response(
          request.id,
          error: RequestError(
            RequestErrorCode.FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED,
            'Concurrent modification detected.',
          ),
        ),
      );
      return;
    }

    if (result == null) {
      sendResponse(
        Response(
          request.id,
          error: RequestError(
            RequestErrorCode.FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET,
            'No Flutter widget at the given location.',
          ),
        ),
      );
      return;
    }

    sendResult(result);
  }
}
