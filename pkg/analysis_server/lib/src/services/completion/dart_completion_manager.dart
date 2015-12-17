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
import 'package:analysis_server/src/services/completion/dart/common_usage_sorter.dart';
import 'package:analysis_server/src/services/completion/dart/contribution_sorter.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The base class for contributing code completion suggestions.
 */
abstract class DartCompletionContributor {
  /**
   * Computes the initial set of [CompletionSuggestion]s based on
   * the given completion context. The compilation unit and completion node
   * in the given completion context may not be resolved.
   * This method should execute quickly and not block waiting for any analysis.
   * Returns `true` if the contributor's work is complete
   * or `false` if [computeFull] should be called to complete the work.
   */
  bool computeFast(DartCompletionRequest request);

  /**
   * Computes the complete set of [CompletionSuggestion]s based on
   * the given completion context.  The compilation unit and completion node
   * in the given completion context are resolved.
   * Returns `true` if the receiver modified the list of suggestions.
   */
  Future<bool> computeFull(DartCompletionRequest request);
}

/**
 * Manages code completion for a given Dart file completion request.
 */
class DartCompletionManager extends CompletionManager {
  /**
   * The [defaultContributionSorter] is a long-lived object that isn't allowed
   * to maintain state between calls to [ContributionSorter#sort(...)].
   */
  static DartContributionSorter defaultContributionSorter =
      new CommonUsageSorter();

  final SearchEngine searchEngine;
  Iterable<CompletionContributor> newContributors;
  DartContributionSorter contributionSorter;

  DartCompletionManager(
      AnalysisContext context, this.searchEngine, Source source,
      [this.newContributors, this.contributionSorter])
      : super(context, source) {
    if (newContributors == null) {
      newContributors = <CompletionContributor>[];
    }
    if (contributionSorter == null) {
      contributionSorter = defaultContributionSorter;
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
   * Compute suggestions based upon cached information only
   * then send an initial response to the client.
   * Return a list of contributors for which [computeFull] should be called
   */
  List<DartCompletionContributor> computeFast(
      DartCompletionRequest request, CompletionPerformance performance) {
    return [];
  }

  /**
   * If there is remaining work to be done, then wait for the unit to be
   * resolved and request that each remaining contributor finish their work.
   * Return a [Future] that completes when the last notification has been sent.
   */
  Future computeFull(
      DartCompletionRequest request,
      CompletionPerformance performance,
      List<DartCompletionContributor> todo) async {
    // Compute suggestions using the new API
    performance.logStartTime('computeSuggestions');
    for (CompletionContributor contributor in newContributors) {
      String contributorTag = 'computeSuggestions - ${contributor.runtimeType}';
      performance.logStartTime(contributorTag);
      List<CompletionSuggestion> newSuggestions =
          await contributor.computeSuggestions(request);
      for (CompletionSuggestion suggestion in newSuggestions) {
        request.addSuggestion(suggestion);
      }
      performance.logElapseTime(contributorTag);
    }
    performance.logElapseTime('computeSuggestions');
    performance.logStartTime('waitForAnalysis');

    // TODO(danrubel) current sorter requires no additional analysis,
    // but need to handle the returned future the same way that futures
    // returned from contributors are handled once this method is refactored
    // to be async.
    /* await */ contributionSorter.sort(request, request.suggestions);
    // TODO (danrubel) if request is obsolete
    // (processAnalysisRequest returns false)
    // then send empty results
    sendResults(request, true);
    return new Future.value();
  }

  @override
  void computeSuggestions(CompletionRequest completionRequest) {
    DartCompletionRequest request =
        new DartCompletionRequest.from(completionRequest);
    CompletionPerformance performance = new CompletionPerformance();
    performance.logElapseTime('compute', () {
      List<DartCompletionContributor> todo = computeFast(request, performance);
      computeFull(request, performance, todo);
    });
  }

  /**
   * Send the current list of suggestions to the client.
   */
  void sendResults(DartCompletionRequest request, bool last) {
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.add(new CompletionResultImpl(request.replacementOffset,
        request.replacementLength, request.suggestions, last));
    if (last) {
      controller.close();
    }
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

/**
 * The context in which the completion is requested.
 */
class DartCompletionRequest extends CompletionRequestImpl {
  /**
   * The list of suggestions to be sent to the client.
   */
  final List<CompletionSuggestion> _suggestions = <CompletionSuggestion>[];

  /**
   * The set of completions used to prevent duplicates
   */
  final Set<String> _completions = new Set<String>();

  DartCompletionRequest(
      AnalysisContext context,
      ResourceProvider resourceProvider,
      SearchEngine searchEngine,
      Source source,
      int offset)
      : super(context, resourceProvider, searchEngine, source, offset);

  factory DartCompletionRequest.from(CompletionRequestImpl request) =>
      new DartCompletionRequest(request.context, request.resourceProvider,
          request.searchEngine, request.source, request.offset);

  /**
   * The list of suggestions to be sent to the client.
   */
  Iterable<CompletionSuggestion> get suggestions => _suggestions;

  /**
   * Add the given suggestion to the list that is returned to the client as long
   * as a suggestion with an identical completion has not already been added.
   */
  void addSuggestion(CompletionSuggestion suggestion) {
    if (_completions.add(suggestion.completion)) {
      _suggestions.add(suggestion);
    }
  }
}
