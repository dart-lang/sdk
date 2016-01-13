// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart.manager;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart'
    show CompletionContributor, CompletionRequest;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_plugin.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/common_usage_sorter.dart';
import 'package:analysis_server/src/services/completion/dart/contribution_sorter.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart'
    show AnalysisFutureHelper, AnalysisContextImpl;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisContextImpl;
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';

/**
 * [DartCompletionManager] determines if a completion request is Dart specific
 * and forwards those requests to all [DartCompletionContributor]s.
 */
class DartCompletionManager implements CompletionContributor {
  /**
   * The [contributionSorter] is a long-lived object that isn't allowed
   * to maintain state between calls to [DartContributionSorter#sort(...)].
   */
  static DartContributionSorter contributionSorter = new CommonUsageSorter();

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      CompletionRequest request) async {
    if (!AnalysisEngine.isDartFileName(request.source.shortName)) {
      return EMPTY_LIST;
    }

    CompletionPerformance performance =
        (request as CompletionRequestImpl).performance;
    const BUILD_REQUEST_TAG = 'build DartCompletionRequestImpl';
    performance.logStartTime(BUILD_REQUEST_TAG);
    DartCompletionRequestImpl dartRequest =
        await DartCompletionRequestImpl.from(request);
    performance.logElapseTime(BUILD_REQUEST_TAG);

    // Don't suggest in comments.
    if (dartRequest.target.isCommentText) {
      return EMPTY_LIST;
    }

    ReplacementRange range =
        new ReplacementRange.compute(dartRequest.offset, dartRequest.target);
    (request as CompletionRequestImpl)
      ..replacementOffset = range.offset
      ..replacementLength = range.length;

    // Request Dart specific completions from each contributor
    Map<String, CompletionSuggestion> suggestionMap =
        <String, CompletionSuggestion>{};
    for (DartCompletionContributor contributor
        in dartCompletionPlugin.contributors) {
      String contributorTag =
          'DartCompletionManager - ${contributor.runtimeType}';
      performance.logStartTime(contributorTag);
      List<CompletionSuggestion> contributorSuggestions =
          await contributor.computeSuggestions(dartRequest);
      performance.logElapseTime(contributorTag);

      for (CompletionSuggestion newSuggestion in contributorSuggestions) {
        var oldSuggestion = suggestionMap.putIfAbsent(
            newSuggestion.completion, () => newSuggestion);
        if (newSuggestion != oldSuggestion &&
            newSuggestion.relevance > oldSuggestion.relevance) {
          suggestionMap[newSuggestion.completion] = newSuggestion;
        }
      }
    }

    // Adjust suggestion relevance before returning
    List<CompletionSuggestion> suggestions = suggestionMap.values.toList();
    const SORT_TAG = 'DartCompletionManager - sort';
    performance.logStartTime(SORT_TAG);
    await contributionSorter.sort(dartRequest, suggestions);
    performance.logElapseTime(SORT_TAG);
    return suggestions;
  }
}

/**
 * The information about a requested list of completions within a Dart file.
 */
class DartCompletionRequestImpl implements DartCompletionRequest {
  @override
  final AnalysisContext context;

  @override
  final Source source;

  @override
  final int offset;

  @override
  Expression dotTarget;

  @override
  Source librarySource;

  @override
  final ResourceProvider resourceProvider;

  @override
  final SearchEngine searchEngine;

  @override
  CompletionTarget target;

  /**
   * The [LibraryElement] representing dart:core
   */
  LibraryElement _coreLib;

  /**
   * The [DartType] for Object in dart:core
   */
  InterfaceType _objectType;

  OpType _opType;

  final CompletionPerformance performance;

  DartCompletionRequestImpl._(
      this.context,
      this.resourceProvider,
      this.searchEngine,
      this.librarySource,
      this.source,
      this.offset,
      CompilationUnit unit,
      this.performance) {
    _updateTargets(unit);
  }

  @override
  LibraryElement get coreLib {
    if (_coreLib == null) {
      Source coreUri = context.sourceFactory.forUri('dart:core');
      _coreLib = context.computeLibraryElement(coreUri);
    }
    return _coreLib;
  }

  @override
  bool get includeIdentifiers {
    opType; // <<< ensure _opType is initialized
    return !_opType.isPrefixed &&
        (_opType.includeReturnValueSuggestions ||
            _opType.includeTypeNameSuggestions ||
            _opType.includeVoidReturnSuggestions ||
            _opType.includeConstructorSuggestions);
  }

  @override
  LibraryElement get libraryElement {
    //TODO(danrubel) build the library element rather than all the declarations
    CompilationUnit unit = target.unit;
    if (unit != null) {
      CompilationUnitElement elem = unit.element;
      if (elem != null) {
        return elem.library;
      }
    }
    return null;
  }

  @override
  InterfaceType get objectType {
    if (_objectType == null) {
      _objectType = coreLib.getType('Object').type;
    }
    return _objectType;
  }

  OpType get opType {
    if (_opType == null) {
      _opType = new OpType.forCompletion(target, offset);
    }
    return _opType;
  }

  // For internal use only
  @override
  Future<List<Directive>> resolveDirectives() async {
    CompilationUnit libUnit;
    if (librarySource != null) {
      // TODO(danrubel) only resolve the directives
      const RESOLVE_DIRECTIVES_TAG = 'resolve directives';
      performance.logStartTime(RESOLVE_DIRECTIVES_TAG);
      libUnit = await new AnalysisFutureHelper<CompilationUnit>(
              context,
              new LibrarySpecificUnit(librarySource, librarySource),
              RESOLVED_UNIT3)
          .computeAsync();
      performance.logElapseTime(RESOLVE_DIRECTIVES_TAG);
    }
    return libUnit?.directives;
  }

  @override
  Future resolveExpression(Expression expression) async {
    // Return immediately if the expression has already been resolved
    if (expression.propagatedType != null) {
      return;
    }

    // Gracefully degrade if librarySource cannot be determined
    if (librarySource == null) {
      return;
    }

    // Resolve declarations in the target unit
    // TODO(danrubel) resolve the expression or containing method
    // rather than the entire complilation unit
    const RESOLVE_EXPRESSION_TAG = 'resolve expression';
    performance.logStartTime(RESOLVE_EXPRESSION_TAG);
    CompilationUnit resolvedUnit =
        await new AnalysisFutureHelper<CompilationUnit>(context,
                new LibrarySpecificUnit(librarySource, source), RESOLVED_UNIT)
            .computeAsync();
    performance.logElapseTime(RESOLVE_EXPRESSION_TAG);

    // TODO(danrubel) determine if the underlying source has been modified
    // in a way that invalidates the completion request
    // and return null

    // Gracefully degrade if unit cannot be resolved
    if (resolvedUnit == null) {
      return;
    }

    // Recompute the target for the newly resolved unit
    _updateTargets(resolvedUnit);
  }

  /**
   * Update the completion [target] and [dotTarget] based on the given [unit].
   */
  void _updateTargets(CompilationUnit unit) {
    _opType = null;
    dotTarget = null;
    target = new CompletionTarget.forOffset(unit, offset);
    AstNode node = target.containingNode;
    if (node is MethodInvocation) {
      if (identical(node.methodName, target.entity)) {
        dotTarget = node.realTarget;
      } else if (node.isCascaded && node.operator.offset + 1 == target.offset) {
        dotTarget = node.realTarget;
      }
    }
    if (node is PropertyAccess) {
      if (identical(node.propertyName, target.entity)) {
        dotTarget = node.realTarget;
      } else if (node.isCascaded && node.operator.offset + 1 == target.offset) {
        dotTarget = node.realTarget;
      }
    }
    if (node is PrefixedIdentifier) {
      if (identical(node.identifier, target.entity)) {
        dotTarget = node.prefix;
      }
    }
  }

  /**
   * Return a [Future] that completes with a newly created completion request
   * based on the given [request].
   */
  static Future<DartCompletionRequest> from(CompletionRequest request) async {
    CompletionPerformance performance =
        (request as CompletionRequestImpl).performance;
    const BUILD_REQUEST_TAG = 'build DartCompletionRequest';
    performance.logStartTime(BUILD_REQUEST_TAG);

    Source source = request.source;
    AnalysisContext context = request.context;

    const PARSE_TAG = 'parse unit';
    performance.logStartTime(PARSE_TAG);
    CompilationUnit unit = request.context.computeResult(source, PARSED_UNIT);
    performance.logElapseTime(PARSE_TAG);

    Source libSource;
    if (unit.directives.any((d) => d is PartOfDirective)) {
      List<Source> libraries = context.getLibrariesContaining(source);
      if (libraries.isNotEmpty) {
        libSource = libraries[0];
      }
    } else {
      libSource = source;
    }

    // Most (all?) contributors need declarations in scope to be resolved
    if (libSource != null) {
      const RESOLVE_DECLARATIONS_TAG = 'resolve declarations';
      performance.logStartTime(RESOLVE_DECLARATIONS_TAG);
      unit = await new AnalysisFutureHelper<CompilationUnit>(context,
              new LibrarySpecificUnit(libSource, source), RESOLVED_UNIT3)
          .computeAsync();
      performance.logElapseTime(RESOLVE_DECLARATIONS_TAG);
    }

    DartCompletionRequestImpl dartRequest = new DartCompletionRequestImpl._(
        request.context,
        request.resourceProvider,
        request.searchEngine,
        libSource,
        request.source,
        request.offset,
        unit,
        performance);

    // Resolve the expression in which the completion occurs
    // to properly determine if identifiers should be suggested
    // rather than invocations.
    if (dartRequest.target.maybeFunctionalArgument()) {
      AstNode node = dartRequest.target.containingNode.parent;
      if (node is Expression) {
        const FUNCTIONAL_ARG_TAG = 'resolve expression for isFunctionalArg';
        performance.logStartTime(FUNCTIONAL_ARG_TAG);
        await dartRequest.resolveExpression(node);
        performance.logElapseTime(FUNCTIONAL_ARG_TAG);
      }
    }

    performance.logElapseTime(BUILD_REQUEST_TAG);
    return dartRequest;
  }
}

/**
 * Utility class for computing the code completion replacement range
 */
class ReplacementRange {
  int offset;
  int length;

  ReplacementRange(this.offset, this.length);

  factory ReplacementRange.compute(int requestOffset, CompletionTarget target) {
    bool isKeywordOrIdentifier(Token token) =>
        token.type == TokenType.KEYWORD || token.type == TokenType.IDENTIFIER;

    //TODO(danrubel) Ideally this needs to be pushed down into the contributors
    // but that implies that each suggestion can have a different
    // replacement offsent/length which would mean an API change

    var entity = target.entity;
    Token token = entity is AstNode ? entity.beginToken : entity;
    if (token != null && requestOffset < token.offset) {
      token = token.previous;
    }
    if (token != null) {
      if (requestOffset == token.offset && !isKeywordOrIdentifier(token)) {
        // If the insertion point is at the beginning of the current token
        // and the current token is not an identifier
        // then check the previous token to see if it should be replaced
        token = token.previous;
      }
      if (token != null && isKeywordOrIdentifier(token)) {
        if (token.offset <= requestOffset && requestOffset <= token.end) {
          // Replacement range for typical identifier completion
          return new ReplacementRange(token.offset, token.length);
        }
      }
      if (token is StringToken) {
        SimpleStringLiteral uri = new SimpleStringLiteral(token, token.lexeme);
        Token previous = token.previous;
        if (previous is KeywordToken) {
          Keyword keyword = previous.keyword;
          if (keyword == Keyword.IMPORT ||
              keyword == Keyword.EXPORT ||
              keyword == Keyword.PART) {
            int start = uri.contentsOffset;
            var end = uri.contentsEnd;
            if (start <= requestOffset && requestOffset <= end) {
              // Replacement range for import URI
              return new ReplacementRange(start, end - start);
            }
          }
        }
      }
    }
    return new ReplacementRange(requestOffset, 0);
  }
}
