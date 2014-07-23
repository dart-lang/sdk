// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.completion;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';

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
   * The [SearchEngine] for this server.
   */
  SearchEngine searchEngine;

  /**
   * The next completion response id.
   */
  int _nextCompletionId = 0;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  CompletionDomainHandler(this.server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == COMPLETION_GET_SUGGESTIONS) {
        return getSuggestions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Response getSuggestions(Request request) {
    // extract param
    String file = request.getRequiredParameter(FILE).asString();
    int offset = request.getRequiredParameter(OFFSET).asInt();
    // schedule completion analysis
    String completionId = (_nextCompletionId++).toString();
    var computer = new TopLevelSuggestionsComputer(server.searchEngine);
    var future = computer.compute();
    future.then((List<CompletionSuggestion> results) {
      _sendCompletionNotification(completionId, true, results);
    });
    // respond
    return new Response(request.id)..setResult(ID, completionId);
  }

  void _sendCompletionNotification(String completionId, bool isLast,
      Iterable<CompletionSuggestion> results) {
    Notification notification = new Notification(COMPLETION_RESULTS);
    notification.setParameter(ID, completionId);
    notification.setParameter(LAST, isLast);
    notification.setParameter(RESULTS, results);
    server.sendNotification(notification);
  }
}

/**
 * A computer for `completion.getSuggestions` request results.
 */
class TopLevelSuggestionsComputer {
  final SearchEngine searchEngine;

  TopLevelSuggestionsComputer(this.searchEngine);

  /**
   * Computes [CompletionSuggestion]s for the specified position in the source.
   */
  Future<List<CompletionSuggestion>> compute() {
    var future = searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {
      return matches.map((SearchMatch match) {
        Element element = match.element;
        String completion = element.displayName;
        return new CompletionSuggestion(
            CompletionSuggestionKind.fromElementKind(element.kind),
            CompletionRelevance.DEFAULT,
            completion,
            completion.length,
            0,
            element.isDeprecated,
            false // isPotential
            );
      }).toList();
    });
  }
}
