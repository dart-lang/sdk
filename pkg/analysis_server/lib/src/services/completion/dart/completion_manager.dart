// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/completion_core.dart'
    show CompletionContributor, CompletionRequest;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_plugin.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/common_usage_sorter.dart';
import 'package:analysis_server/src/services/completion/dart/contribution_sorter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/model.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

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
    request.checkAborted();
    if (!AnalysisEngine.isDartFileName(request.source.shortName)) {
      return EMPTY_LIST;
    }

    CompletionPerformance performance =
        (request as CompletionRequestImpl).performance;
    DartCompletionRequestImpl dartRequest =
        await DartCompletionRequestImpl.from(request);

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
      request.checkAborted();

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
    request.checkAborted();
    return suggestions;
  }
}

/**
 * The information about a requested list of completions within a Dart file.
 */
class DartCompletionRequestImpl implements DartCompletionRequest {
  @override
  final AnalysisResult result;

  @override
  final ResourceProvider resourceProvider;

  @override
  final InterfaceType objectType;

  @override
  final Source source;

  @override
  final int offset;

  @override
  Expression dotTarget;

  @override
  Source librarySource;

  @override
  CompletionTarget target;

  OpType _opType;

  final CompletionRequest _originalRequest;

  final CompletionPerformance performance;

  DartCompletionRequestImpl._(
      this.result,
      this.resourceProvider,
      this.objectType,
      this.librarySource,
      this.source,
      this.offset,
      CompilationUnit unit,
      this._originalRequest,
      this.performance) {
    _updateTargets(unit);
  }

  @override
  bool get includeIdentifiers {
    return opType.includeIdentifiers;
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

  OpType get opType {
    if (_opType == null) {
      _opType = new OpType.forCompletion(target, offset);
    }
    return _opType;
  }

  @override
  String get sourceContents => result.content;

  @override
  SourceFactory get sourceFactory => result.sourceFactory;

  /**
   * Throw [AbortCompletion] if the completion request has been aborted.
   */
  void checkAborted() {
    _originalRequest.checkAborted();
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
   * based on the given [request]. This method will throw [AbortCompletion]
   * if the completion request has been aborted.
   */
  static Future<DartCompletionRequest> from(CompletionRequest request,
      {ResultDescriptor resultDescriptor}) async {
    request.checkAborted();
    CompletionPerformance performance =
        (request as CompletionRequestImpl).performance;
    const BUILD_REQUEST_TAG = 'build DartCompletionRequest';
    performance.logStartTime(BUILD_REQUEST_TAG);

    CompilationUnit unit = request.result.unit;
    Source libSource = unit.element.library.source;
    InterfaceType objectType = request.result.typeProvider.objectType;

    DartCompletionRequestImpl dartRequest = new DartCompletionRequestImpl._(
        request.result,
        request.resourceProvider,
        objectType,
        libSource,
        request.source,
        request.offset,
        unit,
        request,
        performance);

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
        token.type.isKeyword || token.type == TokenType.IDENTIFIER;

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
        SimpleStringLiteral uri =
            astFactory.simpleStringLiteral(token, token.lexeme);
        Keyword keyword = token.previous?.keyword;
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
    return new ReplacementRange(requestOffset, 0);
  }
}
