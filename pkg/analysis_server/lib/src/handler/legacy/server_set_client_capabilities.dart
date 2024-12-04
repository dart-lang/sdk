// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';

/// The handler for the `server.setClientCapabilities` request.
class ServerSetClientCapabilitiesHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  ServerSetClientCapabilitiesHandler(
    super.server,
    super.request,
    super.cancellationToken,
    super.performance,
  );

  @override
  Future<void> handle() async {
    try {
      server.clientCapabilities = ServerSetClientCapabilitiesParams.fromRequest(
        request,
        clientUriConverter: server.uriConverter,
      );
    } on RequestFailure catch (exception) {
      sendResponse(exception.response);
      return;
    }
    sendResult(ServerSetClientCapabilitiesResult());
  }
}
