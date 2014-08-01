// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.completion;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/constants.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';

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
    // extract param
    String file = request.getRequiredParameter(FILE).asString();
    int offset = request.getRequiredParameter(OFFSET).asInt();
    // schedule completion analysis
    String completionId = (_nextCompletionId++).toString();
    Source source = server.getSource(file);
    CompletionManager manager =
        CompletionManager.create(source, offset, server.searchEngine);
    manager.generate().then((List<CompletionComputer> computers) {
      int count = computers.length;
      List<CompletionSuggestion> results = new List<CompletionSuggestion>();
      computers.forEach((CompletionComputer c) {
        c.compute().then((List<CompletionSuggestion> partialResults) {
          // send aggregate results as we compute them
          results.addAll(partialResults);
          sendCompletionNotification(
              manager.replacementOffset,
              manager.replacementLength,
              completionId,
              --count == 0,
              results);
        });
      });
    });
    // initial response without results
    return new Response(request.id)..setResult(ID, completionId);
  }

  /**
   * Send completion notification results.
   */
  void sendCompletionNotification(int replacementOffset, int replacementLength,
      String completionId, bool isLast, Iterable<CompletionSuggestion> results) {
    Notification notification = new Notification(COMPLETION_RESULTS);
    notification.setParameter(ID, completionId);
    notification.setParameter(REPLACEMENT_OFFSET, replacementOffset);
    notification.setParameter(REPLACEMENT_LENGTH, replacementLength);
    notification.setParameter(RESULTS, results);
    notification.setParameter(LAST, isLast);
    server.sendNotification(notification);
  }
}
