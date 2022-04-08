// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// The handler for the `execution.createContext` request.
class ExecutionCreateContextHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  ExecutionCreateContextHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var file = ExecutionCreateContextParams.fromRequest(request).contextRoot;
    var executionContext = server.executionContext;
    var contextId = (executionContext.nextContextId++).toString();
    executionContext.contextMap[contextId] = file;
    sendResult(ExecutionCreateContextResult(contextId));
  }
}
