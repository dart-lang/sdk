// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart'
    show
        AnalysisRequest,
        CompletionContributor,
        CompletionRequest,
        CompletionResult;
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Manages code completion for a given Dart file completion request.
 */
class DartCompletionManager extends CompletionManager {
  final SearchEngine searchEngine;
  Iterable<CompletionContributor> newContributors;

  DartCompletionManager(
      AnalysisContext context, this.searchEngine, Source source,
      [this.newContributors])
      : super(context, source) {
    if (newContributors == null) {
      newContributors = <CompletionContributor>[];
    }
  }

  /**
   * Create a new initialized Dart source completion manager
   */
  factory DartCompletionManager.create(
      AnalysisContext context,
      SearchEngine searchEngine,
      Source source,
      Iterable<CompletionContributor> newContributors) {
    return new DartCompletionManager(
        context, searchEngine, source, newContributors);
  }

  @override
  Future<CompletionResult> computeSuggestions(
      CompletionRequestImpl request) async {
    CompletionPerformance performance = new CompletionPerformance();
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

    return new CompletionResultImpl(
        request.replacementOffset, request.replacementLength, suggestions);
  }
}
