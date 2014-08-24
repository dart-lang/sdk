// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.completion;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart' show
    CompletionGetSuggestionsParams, CompletionGetSuggestionsResult,
    CompletionSuggestion;
import 'package:analysis_server/src/services/completion/completion_manager.dart';

/**
 * Instances of the class [CompletionDomainHandler] implement a [RequestHandler]
 * that handles requests in the search domain.
 */
class CompletionDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * The next completion response id.
   */
  int _nextCompletionId = 0;

  /**
   * Initialize a new request handler for the given [server].
   */
  CompletionDomainHandler(this.server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == COMPLETION_GET_SUGGESTIONS) {
        return processRequest(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Process a `completion.getSuggestions` request.
   */
  Response processRequest(Request request) {
    // extract params
    var params = new CompletionGetSuggestionsParams.fromRequest(request);
    // schedule completion analysis
    String completionId = (_nextCompletionId++).toString();
    CompletionManager.create(
        server.getAnalysisContext(params.file),
        server.getSource(params.file),
        params.offset,
        server.searchEngine).results().listen((CompletionResult result) {
      sendCompletionNotification(
          completionId,
          result.replacementOffset,
          result.replacementLength,
          result.suggestions,
          result.last);
    });
    // initial response without results
    return new CompletionGetSuggestionsResult(completionId).toResponse(
        request.id);
  }

  /**
   * Send completion notification results.
   */
  void sendCompletionNotification(String completionId, int replacementOffset,
      int replacementLength, Iterable<CompletionSuggestion> results, bool isLast) {
    Notification notification = new Notification(COMPLETION_RESULTS);
    notification.setParameter(ID, completionId);
    notification.setParameter(REPLACEMENT_OFFSET, replacementOffset);
    notification.setParameter(REPLACEMENT_LENGTH, replacementLength);
    notification.setParameter(RESULTS, results);
    notification.setParameter(LAST, isLast);
    server.sendNotification(notification);
  }
}
