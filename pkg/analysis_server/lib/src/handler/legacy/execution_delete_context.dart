// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/execution/execution_context.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// The handler for the `execution.deleteContext` request.
class ExecutionDeleteContextHandler extends LegacyHandler {
  /// The context used by the execution domain handlers.
  final ExecutionContext executionContext;

  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  ExecutionDeleteContextHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken, this.executionContext)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var contextId = ExecutionDeleteContextParams.fromRequest(request).id;
    executionContext.contextMap.remove(contextId);
    sendResult(ExecutionDeleteContextResult());
  }
}
