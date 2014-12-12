// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.completion;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

export 'package:analysis_server/src/services/completion/completion_manager.dart'
    show CompletionPerformance, CompletionRequest, OperationPerformance;

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
   * The completion manager for most recent [Source] and [AnalysisContext],
   * or `null` if none.
   */
  CompletionManager _manager;

  /**
   * The subscription for the cached context's source change stream.
   */
  StreamSubscription<SourcesChangedEvent> _sourcesChangedSubscription;

  /**
   * Code completion peformance for the last completion operation.
   */
  CompletionPerformance performance;

  /**
   * A list of code completion peformance measurements for the latest
   * completion operation up to [performanceListMaxLength] measurements.
   */
  final List<CompletionPerformance> performanceList =
      new List<CompletionPerformance>();

  /**
   * The maximum number of performance measurements to keep.
   * This defaults to zero for efficiency, but clients may change this.
   */
  int performanceListMaxLength = 0;

  /**
   * Performance for the last priority change event.
   */
  CompletionPerformance priorityChangedPerformance;

  /**
   * Initialize a new request handler for the given [server].
   */
  CompletionDomainHandler(this.server) {
    server.onContextsChanged.listen(contextsChanged);
    server.onPriorityChange.listen(priorityChanged);
  }

  /**
   * Return the completion manager for most recent [Source] and [AnalysisContext],
   * or `null` if none.
   */
  CompletionManager get manager => _manager;

  /**
   * Return the [CompletionManager] for the given [context] and [source],
   * creating a new manager or returning an existing manager as necessary.
   */
  CompletionManager completionManagerFor(AnalysisContext context,
      Source source) {
    if (_manager != null) {
      if (_manager.context == context && _manager.source == source) {
        return _manager;
      }
      _discardManager();
    }
    _manager = createCompletionManager(context, source, server.searchEngine);
    if (context != null) {
      _sourcesChangedSubscription =
          context.onSourcesChanged.listen(sourcesChanged);
    }
    return _manager;
  }

  /**
   * If the context associated with the cache has changed or been removed
   * then discard the cache.
   */
  void contextsChanged(ContextsChangedEvent event) {
    if (_manager != null) {
      AnalysisContext context = _manager.context;
      if (event.changed.contains(context) || event.removed.contains(context)) {
        _discardManager();
      }
    }
  }

  CompletionManager createCompletionManager(AnalysisContext context,
      Source source, SearchEngine searchEngine) {
    return new CompletionManager.create(context, source, searchEngine);
  }

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
   * If the set the priority files has changed, then pre-cache completion
   * information related to the first priority file.
   */
  void priorityChanged(PriorityChangeEvent event) {
    Source source = event.firstSource;
    priorityChangedPerformance = new CompletionPerformance();
    priorityChangedPerformance.source = source;
    if (source != null) {
      AnalysisContext context = server.getAnalysisContextForSource(source);
      if (context != null) {
        String computeTag = 'computeCache';
        priorityChangedPerformance.logStartTime(computeTag);
        CompletionManager manager = completionManagerFor(context, source);
        manager.computeCache().then((bool success) {
          priorityChangedPerformance.logElapseTime(computeTag);
          priorityChangedPerformance.complete(
              'priorityChanged caching: $success');
        });
        return;
      }
    }
    priorityChangedPerformance.complete();
  }

  /**
   * Process a `completion.getSuggestions` request.
   */
  Response processRequest(Request request) {
    performance = new CompletionPerformance();
    // extract params
    CompletionGetSuggestionsParams params =
        new CompletionGetSuggestionsParams.fromRequest(request);
    // schedule completion analysis
    String completionId = (_nextCompletionId++).toString();
    AnalysisContext context = server.getAnalysisContext(params.file);
    Source source = server.getSource(params.file);
    recordRequest(performance, context, source, params.offset);
    CompletionManager manager = completionManagerFor(context, source);
    CompletionRequest completionRequest =
        new CompletionRequest(params.offset, performance);
    int notificationCount = 0;
    manager.results(completionRequest).listen((CompletionResult result) {
      ++notificationCount;
      performance.logElapseTime("notification $notificationCount", () {
        sendCompletionNotification(
            completionId,
            result.replacementOffset,
            result.replacementLength,
            result.suggestions,
            result.last);
      });
      if (result.last) {
        performance.notificationCount = notificationCount;
        performance.suggestionCount = result.suggestions.length;
        performance.complete();
      }
    });
    // initial response without results
    return new CompletionGetSuggestionsResult(
        completionId).toResponse(request.id);
  }

  /**
   * If tracking code completion performance over time, then
   * record addition information about the request in the performance record.
   */
  void recordRequest(CompletionPerformance performance, AnalysisContext context,
      Source source, int offset) {
    performance.source = source;
    performance.offset = offset;
    if (priorityChangedPerformance != null &&
        priorityChangedPerformance.source != source) {
      priorityChangedPerformance = null;
    }
    if (performanceListMaxLength == 0 || context == null || source == null) {
      return;
    }
    TimestampedData<String> data = context.getContents(source);
    if (data == null) {
      return;
    }
    performance.contents = data.data;
    while (performanceList.length >= performanceListMaxLength) {
      performanceList.removeAt(0);
    }
    performanceList.add(performance);
  }

  /**
   * Send completion notification results.
   */
  void sendCompletionNotification(String completionId, int replacementOffset,
      int replacementLength, Iterable<CompletionSuggestion> results, bool isLast) {
    server.sendNotification(
        new CompletionResultsParams(
            completionId,
            replacementOffset,
            replacementLength,
            results,
            isLast).toNotification());
  }

  /**
   * Discard the cache if a source other than the source referenced by
   * the cache changes or if any source is added, removed, or deleted.
   */
  void sourcesChanged(SourcesChangedEvent event) {

    bool shouldDiscardManager(SourcesChangedEvent event) {
      if (_manager == null) {
        return false;
      }
      if (event.wereSourcesAdded || event.wereSourcesRemovedOrDeleted) {
        return true;
      }
      var changedSources = event.changedSources;
      return changedSources.length > 2 ||
          (changedSources.length == 1 && !changedSources.contains(_manager.source));
    }

    if (shouldDiscardManager(event)) {
      _discardManager();
    }
  }

  /**
   * Discard the sourcesChanged subscription if any
   */
  void _discardManager() {
    if (_sourcesChangedSubscription != null) {
      _sourcesChangedSubscription.cancel();
      _sourcesChangedSubscription = null;
    }
    _manager = null;
  }
}
