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
    show CompletionPerformance, OperationPerformance;

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
   * Cached information from a prior completion operation.
   * The type of cached information depends upon the completion operation.
   */
  CompletionCache _cache;

  /**
   * The subscription for the cached context's source change stream.
   */
  StreamSubscription<SourcesChangedEvent> _sourcesChangedSubscription;

  /**
   * Code completion peformance for the last completion operation.
   */
  CompletionPerformance performance;

  /**
   * Initialize a new request handler for the given [server].
   */
  CompletionDomainHandler(this.server) {
    server.onContextsChanged.listen(contextsChanged);
  }

  /**
   * If the context associated with the cache has changed or been removed
   * then discard the cache.
   */
  void contextsChanged(ContextsChangedEvent event) {
    if (_cache != null) {
      AnalysisContext context = _cache.context;
      if (event.changed.contains(context) || event.removed.contains(context)) {
        _discardCache();
      }
    }
  }

  CompletionManager createCompletionManager(AnalysisContext context,
      Source source, int offset, SearchEngine searchEngine, CompletionCache cache,
      CompletionPerformance performance) {
    return new CompletionManager.create(
        context,
        source,
        offset,
        searchEngine,
        cache,
        performance);
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
   * Process a `completion.getSuggestions` request.
   */
  Response processRequest(Request request) {
    performance = new CompletionPerformance();
    // extract params
    CompletionGetSuggestionsParams params =
        new CompletionGetSuggestionsParams.fromRequest(request);
    // schedule completion analysis
    String completionId = (_nextCompletionId++).toString();
    CompletionManager manager = createCompletionManager(
        server.getAnalysisContext(params.file),
        server.getSource(params.file),
        params.offset,
        server.searchEngine,
        _cache,
        performance);
    manager.results().listen((CompletionResult result) {
      sendCompletionNotification(
          completionId,
          result.replacementOffset,
          result.replacementLength,
          result.suggestions,
          result.last);
      if (result.last) {
        performance.complete();
        CompletionCache newCache = manager.completionCache;
        if (_cache != newCache) {
          if (_cache != null) {
            _discardCache();
          }
          _cache = newCache;
          if (_cache.context != null) {
            _sourcesChangedSubscription =
                _cache.context.onSourcesChanged.listen(sourcesChanged);
          }
        }
      }
    });
    // initial response without results
    return new CompletionGetSuggestionsResult(
        completionId).toResponse(request.id);
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

    bool shouldDiscardCache(SourcesChangedEvent event) {
      if (_cache == null) {
        return false;
      }
      if (event.wereSourcesAdded || event.wereSourcesRemovedOrDeleted) {
        return true;
      }
      var changedSources = event.changedSources;
      return changedSources.length > 2 ||
          (changedSources.length == 1 && !changedSources.contains(_cache.source));
    }

    if (shouldDiscardCache(event)) {
      _discardCache();
    }
  }

  /**
   * Discard the sourcesChanged subscription if any
   */
  void _discardCache() {
    if (_sourcesChangedSubscription != null) {
      _sourcesChangedSubscription.cancel();
      _sourcesChangedSubscription = null;
    }
    _cache = null;
  }
}
