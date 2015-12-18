// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart'
    show AnalysisRequest, CompletionContributor, CompletionRequest;
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
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

  /**
   * If there is remaining work to be done, then wait for the unit to be
   * resolved and request that each remaining contributor finish their work.
   * Return a [Future] that completes when the last notification has been sent.
   */
  Future computeFull(
      CompletionRequestImpl request, CompletionPerformance performance) async {
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

    performance.logStartTime('computeSuggestions');
    for (CompletionContributor contributor in newContributors) {
      String contributorTag = 'computeSuggestions - ${contributor.runtimeType}';
      performance.logStartTime(contributorTag);
      suggestions.addAll(await contributor.computeSuggestions(request));
      performance.logElapseTime(contributorTag);
    }
    performance.logElapseTime('computeSuggestions');

    // TODO (danrubel) if request is obsolete
    // (processAnalysisRequest returns false)
    // then send empty results

    if (controller != null && !controller.isClosed) {
      controller.add(new CompletionResultImpl(request.replacementOffset,
          request.replacementLength, suggestions, true));
      controller.close();
    }
  }

  @override
  void computeSuggestions(CompletionRequest request) {
    CompletionPerformance performance = new CompletionPerformance();
    performance.logElapseTime('compute', () {
      computeFull(request, performance);
    });
  }

  /**
   * Return a future that either (a) completes with the resolved compilation
   * unit when analysis is complete, or (b) completes with null if the
   * compilation unit is never going to be resolved.
   */
  Future<CompilationUnit> waitForAnalysis() {
    List<Source> libraries = context.getLibrariesContaining(source);
    assert(libraries != null);
    if (libraries.length == 0) {
      return new Future.value(null);
    }
    Source libSource = libraries[0];
    assert(libSource != null);
    return context
        .computeResolvedCompilationUnitAsync(source, libSource)
        .catchError((_) {
      // This source file is not scheduled for analysis, so a resolved
      // compilation unit is never going to get computed.
      return null;
    }, test: (e) => e is AnalysisNotScheduledError);
  }
}
