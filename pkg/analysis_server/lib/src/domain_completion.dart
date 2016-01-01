// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.completion;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Instances of the class [CompletionDomainHandler] implement a [RequestHandler]
 * that handles requests in the search domain.
 */
class CompletionDomainHandler implements RequestHandler {
  /**
   * The maximum number of performance measurements to keep.
   */
  static const int performanceListMaxLength = 50;

  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * The next completion response id.
   */
  int _nextCompletionId = 0;

  /**
   * Code completion performance for the last completion operation.
   */
  CompletionPerformance performance;

  /**
   * A list of code completion performance measurements for the latest
   * completion operation up to [performanceListMaxLength] measurements.
   */
  final List<CompletionPerformance> performanceList =
      new List<CompletionPerformance>();

  /**
   * Performance for the last priority change event.
   */
  CompletionPerformance computeCachePerformance;

  /**
   * Initialize a new request handler for the given [server].
   */
  CompletionDomainHandler(this.server);

  /**
   * Compute completion results for the given reqeust and append them to the stream.
   * Clients should not call this method directly as it is automatically called
   * when a client listens to the stream returned by [results].
   * Subclasses should override this method, append at least one result
   * to the [controller], and close the controller stream once complete.
   */
  Future<CompletionResult> computeSuggestions(
      CompletionRequestImpl request) async {
    Iterable<CompletionContributor> newContributors =
        server.serverPlugin.completionContributors;
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

    const COMPUTE_SUGGESTIONS_TAG = 'computeSuggestions';
    performance.logStartTime(COMPUTE_SUGGESTIONS_TAG);

    for (CompletionContributor contributor in newContributors) {
      String contributorTag = 'computeSuggestions - ${contributor.runtimeType}';
      performance.logStartTime(contributorTag);
      suggestions.addAll(await contributor.computeSuggestions(request));
      performance.logElapseTime(contributorTag);
    }

    performance.logElapseTime(COMPUTE_SUGGESTIONS_TAG);

    // TODO (danrubel) if request is obsolete
    // (processAnalysisRequest returns false)
    // then send empty results

    return new CompletionResult(
        request.replacementOffset, request.replacementLength, suggestions);
  }

  @override
  Response handleRequest(Request request) {
    if (server.searchEngine == null) {
      return new Response.noIndexGenerated(request);
    }
    return runZoned(() {
      try {
        String requestName = request.method;
        if (requestName == COMPLETION_GET_SUGGESTIONS) {
          return processRequest(request);
        }
      } on RequestFailure catch (exception) {
        return exception.response;
      }
      return null;
    }, onError: (exception, stackTrace) {
      server.sendServerErrorNotification(
          'Failed to handle completion domain request: ${request.toJson()}',
          exception,
          stackTrace);
    });
  }

  /**
   * Process a `completion.getSuggestions` request.
   */
  Response processRequest(Request request) {
    performance = new CompletionPerformance();

    // extract and validate params
    CompletionGetSuggestionsParams params =
        new CompletionGetSuggestionsParams.fromRequest(request);
    ContextSourcePair contextSource = server.getContextSourcePair(params.file);
    AnalysisContext context = contextSource.context;
    Source source = contextSource.source;
    if (context == null || !context.exists(source)) {
      return new Response.unknownSource(request);
    }
    TimestampedData<String> contents = context.getContents(source);
    if (params.offset < 0 || params.offset > contents.data.length) {
      return new Response.invalidParameter(
          request,
          'params.offset',
          'Expected offset between 0 and source length inclusive,'
          ' but found ${params.offset}');
    }

    recordRequest(performance, context, source, params.offset);

    CompletionRequest completionRequest = new CompletionRequestImpl(
        context,
        server.resourceProvider,
        server.searchEngine,
        source,
        params.offset,
        performance);
    String completionId = (_nextCompletionId++).toString();

    // Compute suggestions in the background
    computeSuggestions(completionRequest).then((CompletionResult result) {
      const SEND_NOTIFICATION_TAG = 'send notification';
      performance.logStartTime(SEND_NOTIFICATION_TAG);
      sendCompletionNotification(completionId, result.replacementOffset,
          result.replacementLength, result.suggestions);
      performance.logElapseTime(SEND_NOTIFICATION_TAG);

      performance.notificationCount = 1;
      performance.logFirstNotificationComplete('notification 1 complete');
      performance.suggestionCountFirst = result.suggestions.length;
      performance.suggestionCountLast = result.suggestions.length;
      performance.complete();
    });

    // initial response without results
    return new CompletionGetSuggestionsResult(completionId)
        .toResponse(request.id);
  }

  /**
   * If tracking code completion performance over time, then
   * record addition information about the request in the performance record.
   */
  void recordRequest(CompletionPerformance performance, AnalysisContext context,
      Source source, int offset) {
    performance.source = source;
    if (performanceListMaxLength == 0 || context == null || source == null) {
      return;
    }
    TimestampedData<String> data = context.getContents(source);
    if (data == null) {
      return;
    }
    performance.setContentsAndOffset(data.data, offset);
    while (performanceList.length >= performanceListMaxLength) {
      performanceList.removeAt(0);
    }
    performanceList.add(performance);
  }

  /**
   * Send completion notification results.
   */
  void sendCompletionNotification(String completionId, int replacementOffset,
      int replacementLength, Iterable<CompletionSuggestion> results) {
    server.sendNotification(new CompletionResultsParams(
            completionId, replacementOffset, replacementLength, results, true)
        .toNotification());
  }
}

/**
 * The result of computing suggestions for code completion.
 */
class CompletionResult {
  /**
   * The length of the text to be replaced if the remainder of the identifier
   * containing the cursor is to be replaced when the suggestion is applied
   * (that is, the number of characters in the existing identifier).
   */
  final int replacementLength;

  /**
   * The offset of the start of the text to be replaced. This will be different
   * than the offset used to request the completion suggestions if there was a
   * portion of an identifier before the original offset. In particular, the
   * replacementOffset will be the offset of the beginning of said identifier.
   */
  final int replacementOffset;

  /**
   * The suggested completions.
   */
  final List<CompletionSuggestion> suggestions;

  CompletionResult(
      this.replacementOffset, this.replacementLength, this.suggestions);
}
