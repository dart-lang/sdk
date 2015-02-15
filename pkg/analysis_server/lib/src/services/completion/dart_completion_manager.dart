// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/arglist_computer.dart';
import 'package:analysis_server/src/services/completion/combinator_computer.dart';
import 'package:analysis_server/src/services/completion/common_usage_computer.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/imported_computer.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:analysis_server/src/services/completion/keyword_computer.dart';
import 'package:analysis_server/src/services/completion/local_computer.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';

const int DART_RELEVANCE_COMMON_USAGE = 1200;
const int DART_RELEVANCE_DEFAULT = 1000;
const int DART_RELEVANCE_HIGH = 2000;
const int DART_RELEVANCE_INHERITED_ACCESSOR = 1057;
const int DART_RELEVANCE_INHERITED_FIELD = 1058;
const int DART_RELEVANCE_INHERITED_METHOD = 1057;
const int DART_RELEVANCE_KEYWORD = 1055;
const int DART_RELEVANCE_LOCAL_ACCESSOR = 1057;
const int DART_RELEVANCE_LOCAL_FIELD = 1058;
const int DART_RELEVANCE_LOCAL_FUNCTION = 1056;
const int DART_RELEVANCE_LOCAL_METHOD = 1057;
const int DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE = 1056;
const int DART_RELEVANCE_LOCAL_VARIABLE = 1059;
const int DART_RELEVANCE_LOW = 500;
const int DART_RELEVANCE_PARAMETER = 1059;

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
  CommonUsageComputer commonUsageComputer;

  DartCompletionManager(AnalysisContext context, this.searchEngine,
      Source source, this.cache, [this.computers, this.commonUsageComputer])
      : super(context, source) {
    if (computers == null) {
      computers = [
          new KeywordComputer(),
          new LocalComputer(),
          new ArgListComputer(),
          new CombinatorComputer(),
          new ImportedComputer(),
          new InvocationComputer()];
    }
    if (commonUsageComputer == null) {
      commonUsageComputer = new CommonUsageComputer();
    }
  }

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
        return cache.computeImportInfo(unit, searchEngine, true);
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
      request.target = new CompletionTarget.forOffset(unit, request.offset);
      if (request.node == null) {
        return [];
      }

      request.replacementOffset = request.offset;
      request.replacementLength = 0;
      var entity = request.target.entity;
      Token token = entity is AstNode ? entity.beginToken : entity;
      if (token != null &&
          token.offset <= request.offset &&
          (token.type == TokenType.KEYWORD || token.type == TokenType.IDENTIFIER)) {
        request.replacementOffset = token.offset;
        request.replacementLength = token.length;
      }

      List<DartCompletionComputer> todo = new List.from(computers);
      todo.removeWhere((DartCompletionComputer c) {
        return request.performance.logElapseTime(
            'computeFast ${c.runtimeType}',
            () {
          return c.computeFast(request);
        });
      });
      commonUsageComputer.computeFast(request);
      sendResults(request, todo.isEmpty);
      return todo;
    });
  }

  /**
   * If there is remaining work to be done, then wait for the unit to be
   * resolved and request that each remaining computer finish their work.
   * Return a [Future] that completes when the last notification has been sent.
   */
  Future computeFull(DartCompletionRequest request,
      List<DartCompletionComputer> todo) {
    request.performance.logStartTime('waitForAnalysis');
    return waitForAnalysis().then((CompilationUnit unit) {
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
        // TODO(paulberry): Do we need to invoke _ReplacementOffsetBuilder
        // again?
        request.target = new CompletionTarget.forOffset(unit, request.offset);
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
                commonUsageComputer.computeFull(request);
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
    if (controller == null || controller.isClosed) {
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
    List<Source> libraries = context.getLibrariesContaining(source);
    assert(libraries != null);
    if (libraries.length == 0) {
      return new Future.value(null);
    }
    Source libSource = libraries[0];
    assert(libSource != null);
    return context.computeResolvedCompilationUnitAsync(
        source,
        libSource).catchError((_) {
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
   * The completion target.  This determines what part of the parse tree
   * will receive the newly inserted text.
   *
   * TODO(paulberry) gradually transition code over to using this rather than
   * [node].
   */
  CompletionTarget target;

  /**
   * Information about the types of suggestions that should be included.
   */
  OpType _optype;

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

  /**
   * Information about the types of suggestions that should be included.
   * The [target] must be set first.
   */
  OpType get optype {
    if (_optype == null) {
      _optype = new OpType.forCompletion(target, offset);
    }
    return _optype;
  }
}
