// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart;

import 'dart:async';

import 'package:analysis_server/completion/completion_core.dart'
    show CompletionRequest;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/arglist_contributor.dart';
import 'package:analysis_server/src/services/completion/combinator_contributor.dart';
import 'package:analysis_server/src/services/completion/common_usage_computer.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/import_uri_contributor.dart';
import 'package:analysis_server/src/services/completion/imported_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/keyword_contributor.dart';
import 'package:analysis_server/src/services/completion/local_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analysis_server/src/services/completion/prefixed_element_contributor.dart';
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
const int DART_RELEVANCE_NAMED_PARAMETER = 1060;
const int DART_RELEVANCE_PARAMETER = 1059;

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
  final SearchEngine searchEngine;
  final DartCompletionCache cache;
  List<DartCompletionContributor> contributors;
  CommonUsageComputer commonUsageComputer;

  DartCompletionManager(
      AnalysisContext context, this.searchEngine, Source source, this.cache,
      [this.contributors, this.commonUsageComputer])
      : super(context, source) {
    if (contributors == null) {
      contributors = [
        // LocalReferenceContributor before ImportedReferenceContributor
        // because local suggestions take precedence
        // and can hide other suggestions with the same name
        new LocalReferenceContributor(),
        new ImportedReferenceContributor(),
        new KeywordContributor(),
        new ArgListContributor(),
        new CombinatorContributor(),
        new PrefixedElementContributor(),
        new ImportUriContributor(),
      ];
    }
    if (commonUsageComputer == null) {
      commonUsageComputer = new CommonUsageComputer();
    }
  }

  /**
   * Create a new initialized Dart source completion manager
   */
  factory DartCompletionManager.create(
      AnalysisContext context, SearchEngine searchEngine, Source source) {
    return new DartCompletionManager(context, searchEngine, source,
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
   * Return a list of contributors for which [computeFull] should be called
   */
  List<DartCompletionContributor> computeFast(
      DartCompletionRequest request, CompletionPerformance performance) {
    return performance.logElapseTime('computeFast', () {
      CompilationUnit unit = context.parseCompilationUnit(source);
      request.unit = unit;
      request.target = new CompletionTarget.forOffset(unit, request.offset);
      request.replacementOffset = request.offset;
      request.replacementLength = 0;
      if (request.offset < 0 || request.offset > unit.end) {
        sendResults(request, true);
        return [];
      }

      var entity = request.target.entity;
      Token token = entity is AstNode ? entity.beginToken : entity;
      if (token != null &&
          token.offset <= request.offset &&
          (token.type == TokenType.KEYWORD ||
              token.type == TokenType.IDENTIFIER)) {
        request.replacementOffset = token.offset;
        request.replacementLength = token.length;
      }

      List<DartCompletionContributor> todo = new List.from(contributors);
      todo.removeWhere((DartCompletionContributor c) {
        return performance.logElapseTime('computeFast ${c.runtimeType}', () {
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
   * resolved and request that each remaining contributor finish their work.
   * Return a [Future] that completes when the last notification has been sent.
   */
  Future computeFull(DartCompletionRequest request,
      CompletionPerformance performance, List<DartCompletionContributor> todo) {
    performance.logStartTime('waitForAnalysis');
    return waitForAnalysis().then((CompilationUnit unit) {
      if (controller.isClosed) {
        return;
      }
      performance.logElapseTime('waitForAnalysis');
      if (unit == null) {
        sendResults(request, true);
        return;
      }
      performance.logElapseTime('computeFull', () {
        request.unit = unit;
        // TODO(paulberry): Do we need to invoke _ReplacementOffsetBuilder
        // again?
        request.target = new CompletionTarget.forOffset(unit, request.offset);
        int count = todo.length;
        todo.forEach((DartCompletionContributor c) {
          String name = c.runtimeType.toString();
          String completeTag = 'computeFull $name complete';
          performance.logStartTime(completeTag);
          performance.logElapseTime('computeFull $name', () {
            c.computeFull(request).then((bool changed) {
              performance.logElapseTime(completeTag);
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
    DartCompletionRequest request =
        new DartCompletionRequest.from(completionRequest, cache);
    CompletionPerformance performance = new CompletionPerformance();
    performance.logElapseTime('compute', () {
      List<DartCompletionContributor> todo = computeFast(request, performance);
      if (!todo.isEmpty) {
        computeFull(request, performance, todo);
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
   * Cached information from a prior code completion operation.
   */
  final DartCompletionCache cache;

  /**
   * The compilation unit in which the completion was requested. This unit
   * may or may not be resolved when [DartCompletionContributor.computeFast]
   * is called but is resolved when [DartCompletionContributor.computeFull].
   */
  CompilationUnit unit;

  /**
   * The completion target.  This determines what part of the parse tree
   * will receive the newly inserted text.
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
  final List<CompletionSuggestion> _suggestions = <CompletionSuggestion>[];

  /**
   * The set of completions used to prevent duplicates
   */
  final Set<String> _completions = new Set<String>();

  DartCompletionRequest(AnalysisServer server, AnalysisContext context,
      Source source, int offset, this.cache)
      : super(server, context, source, offset);

  factory DartCompletionRequest.from(CompletionRequestImpl request,
      DartCompletionCache cache) => new DartCompletionRequest(
      request.server, request.context, request.source, request.offset, cache);

  /**
   * Return the original text from the [replacementOffset] to the [offset]
   * that can be used to filter the suggestions on the server side.
   */
  String get filterText {
    return context.getContents(source).data.substring(
        replacementOffset, offset);
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

  /**
   * The search engine for use when building suggestions.
   */
  SearchEngine get searchEngine => server.searchEngine;

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

  /**
   * Convert all [CompletionSuggestionKind.INVOCATION] suggestions
   * to [CompletionSuggestionKind.IDENTIFIER] suggestions.
   */
  void convertInvocationsToIdentifiers() {
    for (int index = _suggestions.length - 1; index >= 0; --index) {
      CompletionSuggestion suggestion = _suggestions[index];
      if (suggestion.kind == CompletionSuggestionKind.INVOCATION) {
        // Create a copy rather than just modifying the existing suggestion
        // because [DartCompletionCache] may be caching that suggestion
        // for future completion requests
        _suggestions[index] = new CompletionSuggestion(
            CompletionSuggestionKind.IDENTIFIER, suggestion.relevance,
            suggestion.completion, suggestion.selectionOffset,
            suggestion.selectionLength, suggestion.isDeprecated,
            suggestion.isPotential,
            declaringType: suggestion.declaringType,
            parameterNames: suggestion.parameterNames,
            parameterTypes: suggestion.parameterTypes,
            requiredParameterCount: suggestion.requiredParameterCount,
            hasNamedParameters: suggestion.hasNamedParameters,
            returnType: suggestion.returnType,
            element: suggestion.element);
      }
    }
  }
}
