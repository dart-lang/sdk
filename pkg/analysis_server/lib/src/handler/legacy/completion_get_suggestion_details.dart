// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// The handler for the `completion.getSuggestionDetails` request.
class CompletionGetSuggestionDetailsHandler extends CompletionHandler {
  /// The identifiers of the latest `getSuggestionDetails` request.
  /// We use it to abort previous requests.
  int _latestGetSuggestionDetailsId = 0;

  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  CompletionGetSuggestionDetailsHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    if (completionIsDisabled) {
      return;
    }

    var params = CompletionGetSuggestionDetailsParams.fromRequest(request);

    var file = params.file;
    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var libraryId = params.id;
    var declarationsTracker = server.declarationsTracker;
    if (declarationsTracker == null) {
      sendResponse(Response.unsupportedFeature(
          request.id, 'Completion is not enabled.'));
      return;
    }
    var library = declarationsTracker.getLibrary(libraryId);
    if (library == null) {
      sendResponse(Response.invalidParameter(
        request,
        'libraryId',
        'No such library: $libraryId',
      ));
      return;
    }

    // The label might be `MyEnum.myValue`, but we import only `MyEnum`.
    var requestedName = params.label;
    if (requestedName.contains('.')) {
      requestedName = requestedName.substring(
        0,
        requestedName.indexOf('.'),
      );
    }

    const timeout = Duration(milliseconds: 1000);
    var timer = Stopwatch()..start();
    var id = ++_latestGetSuggestionDetailsId;
    while (id == _latestGetSuggestionDetailsId && timer.elapsed < timeout) {
      try {
        var session = await server.getAnalysisSession(file);
        if (session == null) {
          sendResponse(Response.fileNotAnalyzed(request, 'libraryId'));
          return;
        }

        var completion = params.label;
        var builder = ChangeBuilder(session: session);
        await builder.addDartFileEdit(file, (builder) {
          var result = builder.importLibraryElement(library.uri);
          if (result.prefix != null) {
            completion = '${result.prefix}.$completion';
          }
        });

        sendResult(CompletionGetSuggestionDetailsResult(completion,
            change: builder.sourceChange));
        return;
      } on InconsistentAnalysisException {
        // Loop around to try again.
      }
    }

    // Timeout or abort, send the empty response.
    sendResult(CompletionGetSuggestionDetailsResult(''));
  }
}
