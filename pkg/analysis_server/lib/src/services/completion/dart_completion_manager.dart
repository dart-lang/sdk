// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/arglist_computer.dart';
import 'package:analysis_server/src/services/completion/combinator_computer.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/imported_computer.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:analysis_server/src/services/completion/keyword_computer.dart';
import 'package:analysis_server/src/services/completion/local_computer.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The base class for computing code completion suggestions.
 */
abstract class DartCompletionComputer {
  /**
   * Computes the initial set of [CompletionSuggestion]s based on
   * the given completion context. The compilation unit and completion node
   * in the given completion context may not be resolved.
   * This method should execute quickly and not block waiting for any analysis.
   * Returns `true` if the computer's work is complete
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
  final SearchEngine searchEngine;
  final DartCompletionCache cache;
  List<DartCompletionComputer> computers;

  DartCompletionManager(AnalysisContext context, this.searchEngine,
      Source source, this.cache)
      : super(context, source),
        computers = [
          new KeywordComputer(),
          new LocalComputer(),
          new ArgListComputer(),
          new CombinatorComputer(),
          new ImportedComputer(),
          new InvocationComputer()];

  /**
   * Create a new initialized Dart source completion manager
   */
  factory DartCompletionManager.create(AnalysisContext context,
      SearchEngine searchEngine, Source source) {
    return new DartCompletionManager(
        context,
        searchEngine,
        source,
        new DartCompletionCache(context, source));
  }

  @override
  Future<bool> computeCache() {
    return waitForAnalysis().then((CompilationUnit unit) {
      if (unit != null && !cache.isImportInfoCached(unit)) {
        return cache.computeImportInfo(unit, searchEngine);
      } else {
        return new Future.value(false);
      }
    });
  }

  /**
   * Compute suggestions based upon cached information only
   * then send an initial response to the client.
   * Return a list of computers for which [computeFull] should be called
   */
  List<DartCompletionComputer> computeFast(DartCompletionRequest request) {
    return request.performance.logElapseTime('computeFast', () {
      CompilationUnit unit = context.parseCompilationUnit(source);
      request.unit = unit;
      request.node = new NodeLocator.con1(request.offset).searchWithin(unit);
      request.node.accept(new _ReplacementOffsetBuilder(request));
      List<DartCompletionComputer> todo = new List.from(computers);
      todo.removeWhere((DartCompletionComputer c) {
        return request.performance.logElapseTime(
            'computeFast ${c.runtimeType}',
            () {
          return c.computeFast(request);
        });
      });
      sendResults(request, todo.isEmpty);
      return todo;
    });
  }

  /**
   * If there is remaining work to be done, then wait for the unit to be
   * resolved and request that each remaining computer finish their work.
   */
  void computeFull(DartCompletionRequest request,
      List<DartCompletionComputer> todo) {
    request.performance.logStartTime('waitForAnalysis');
    waitForAnalysis().then((CompilationUnit unit) {
      if (controller.isClosed) {
        return;
      }
      request.performance.logElapseTime('waitForAnalysis');
      if (unit == null) {
        sendResults(request, true);
        return;
      }
      request.performance.logElapseTime('computeFull', () {
        request.unit = unit;
        request.node = new NodeLocator.con1(request.offset).searchWithin(unit);
        int count = todo.length;
        todo.forEach((DartCompletionComputer c) {
          String name = c.runtimeType.toString();
          String completeTag = 'computeFull $name complete';
          request.performance.logStartTime(completeTag);
          request.performance.logElapseTime('computeFull $name', () {
            c.computeFull(request).then((bool changed) {
              request.performance.logElapseTime(completeTag);
              bool last = --count == 0;
              if (changed || last) {
                sendResults(request, last);
              }
            });
          });
        });
      });
    });
  }

  @override
  void computeSuggestions(CompletionRequest completionRequest) {
    DartCompletionRequest request = new DartCompletionRequest(
        context,
        searchEngine,
        source,
        completionRequest.offset,
        cache,
        completionRequest.performance);
    request.performance.logElapseTime('compute', () {
      List<DartCompletionComputer> todo = computeFast(request);
      if (!todo.isEmpty) {
        computeFull(request, todo);
      }
    });
  }

  /**
   * Send the current list of suggestions to the client.
   */
  void sendResults(DartCompletionRequest request, bool last) {
    if (controller.isClosed) {
      return;
    }
    controller.add(
        new CompletionResult(
            request.replacementOffset,
            request.replacementLength,
            request.suggestions,
            last));
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
    return context.getResolvedCompilationUnitFuture(
        source,
        source).catchError((_) {
      // This source file is not scheduled for analysis, so a resolved
      // compilation unit is never going to get computed.
      return null;
    }, test: (e) => e is AnalysisNotScheduledError);
  }
}

/**
 * The context in which the completion is requested.
 */
class DartCompletionRequest extends CompletionRequest {
  /**
   * The analysis context in which the completion is requested.
   */
  final AnalysisContext context;

  /**
   * The search engine for use when building suggestions.
   */
  final SearchEngine searchEngine;

  /**
   * The source in which the completion is requested.
   */
  final Source source;

  /**
   * Cached information from a prior code completion operation.
   */
  final DartCompletionCache cache;

  /**
   * The compilation unit in which the completion was requested. This unit
   * may or may not be resolved when [DartCompletionComputer.computeFast]
   * is called but is resolved when [DartCompletionComputer.computeFull].
   */
  CompilationUnit unit;

  /**
   * The node in which the completion occurred. This node
   * may or may not be resolved when [DartCompletionComputer.computeFast]
   * is called but is resolved when [DartCompletionComputer.computeFull].
   */
  AstNode node;

  /**
   * The offset of the start of the text to be replaced.
   * This will be different than the offset used to request the completion
   * suggestions if there was a portion of an identifier before the original
   * offset. In particular, the replacementOffset will be the offset of the
   * beginning of said identifier.
   */
  int replacementOffset;

  /**
   * The length of the text to be replaced if the remainder of the identifier
   * containing the cursor is to be replaced when the suggestion is applied
   * (that is, the number of characters in the existing identifier).
   */
  int replacementLength;

  /**
   * The list of suggestions to be sent to the client.
   */
  final List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  DartCompletionRequest(this.context, this.searchEngine, this.source,
      int offset, this.cache, CompletionPerformance performance)
      : super(offset, performance);

  /**
   * Return the original text from the [replacementOffset] to the [offset]
   * that can be used to filter the suggestions on the server side.
   */
  String get filterText {
    return context.getContents(
        source).data.substring(replacementOffset, offset);
  }
}

/**
 * Visitor used to determine the replacement offset and length
 * based upon the cursor location.
 */
class _ReplacementOffsetBuilder extends SimpleAstVisitor {
  final DartCompletionRequest request;

  _ReplacementOffsetBuilder(this.request) {
    request.replacementOffset = request.offset;
    request.replacementLength = 0;
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    request.replacementOffset = node.offset;
    request.replacementLength = node.length;
  }
}
