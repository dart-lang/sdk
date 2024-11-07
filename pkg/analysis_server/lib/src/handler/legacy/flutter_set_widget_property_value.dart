// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';

/// The handler for the `flutter.setWidgetPropertyValue` request.
class FlutterSetWidgetPropertyValueHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  FlutterSetWidgetPropertyValueHandler(
    super.server,
    super.request,
    super.cancellationToken,
    super.performance,
  );

  @override
  Future<void> handle() async {
    var params = FlutterSetWidgetPropertyValueParams.fromRequest(
      request,
      clientUriConverter: server.uriConverter,
    );

    var result = await server.flutterWidgetDescriptions.setPropertyValue(
      params.id,
      params.value,
    );

    var errorCode = result.errorCode;
    if (errorCode != null) {
      sendResponse(Response(request.id, error: RequestError(errorCode, '')));
    }

    sendResult(FlutterSetWidgetPropertyValueResult(result.change!));
  }
}
