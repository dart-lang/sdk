// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// The handler for the `execution.getSuggestions` request.
class ExecutionGetSuggestionsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  ExecutionGetSuggestionsHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
//    var params = new ExecutionGetSuggestionsParams.fromRequest(request);
//    var computer = new RuntimeCompletionComputer(
//        server.resourceProvider,
//        server.fileContentOverlay,
//        server.getAnalysisDriver(params.contextFile),
//        params.code,
//        params.offset,
//        params.contextFile,
//        params.contextOffset,
//        params.variables,
//        params.expressions);
//    RuntimeCompletionResult completionResult = await computer.compute();
//
//    // Send the response.
//    var result = new ExecutionGetSuggestionsResult(
//        suggestions: completionResult.suggestions,
//        expressions: completionResult.expressions);
    // TODO(brianwilkerson) Re-enable this functionality after implementing a
    // way of computing suggestions that is compatible with AnalysisSession.
    var result = ExecutionGetSuggestionsResult(
        suggestions: <CompletionSuggestion>[],
        expressions: <RuntimeCompletionExpression>[]);
    sendResponse(result.toResponse(request.id));
  }
}
