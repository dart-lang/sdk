// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// The handler for the `server.getVersion` request.
class ServerGetVersionHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  ServerGetVersionHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    sendResult(ServerGetVersionResult(
      server.options.reportProtocolVersion ?? PROTOCOL_VERSION,
    ));
  }
}
