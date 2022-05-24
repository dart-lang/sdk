// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// The handler for the `completion.getSuggestionDetails2` request.
class CompletionGetSuggestionDetails2Handler extends LegacyHandler {
  /// The identifiers of the latest `getSuggestionDetails2` request.
  /// We use it to abort previous requests.
  int _latestGetSuggestionDetailsId = 0;

  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  CompletionGetSuggestionDetails2Handler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params = CompletionGetSuggestionDetails2Params.fromRequest(request);

    var file = params.file;
    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var libraryUri = Uri.tryParse(params.libraryUri);
    if (libraryUri == null) {
      sendResponse(
        Response.invalidParameter(request, 'libraryUri', 'Cannot parse'),
      );
      return;
    }

    var budget = CompletionBudget(
      const Duration(milliseconds: 1000),
    );
    var id = ++_latestGetSuggestionDetailsId;
    while (id == _latestGetSuggestionDetailsId && !budget.isEmpty) {
      try {
        var session = await server.getAnalysisSession(file);
        if (session == null) {
          sendResponse(Response.fileNotAnalyzed(request, file));
          return;
        }

        var completion = params.completion;
        var builder = ChangeBuilder(session: session);
        await builder.addDartFileEdit(file, (builder) {
          var result = builder.importLibraryElement(libraryUri);
          if (result.prefix != null) {
            completion = '${result.prefix}.$completion';
          }
        });

        sendResult(CompletionGetSuggestionDetails2Result(
          completion,
          builder.sourceChange,
        ));
        return;
      } on InconsistentAnalysisException {
        // Loop around to try again.
      }
    }

    // Timeout or abort, send the empty response.
    sendResult(CompletionGetSuggestionDetailsResult(''));
  }
}
