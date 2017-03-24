// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart.manager;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/ide_options.dart';
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
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart' show AnalysisFutureHelper;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';

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
  final AnalysisContext context;

  @override
  IdeOptions ideOptions;

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

  /**
   * A list of resolved [ImportElement]s for the imported libraries
   * or `null` if not computed.
   */
  List<ImportElement> _resolvedImports;

  /**
   * The resolved [CompilationUnitElement]s comprising the library
   * or `null` if not computed.
   */
  List<CompilationUnitElement> _resolvedUnits;

  OpType _opType;

  final CompletionRequest _originalRequest;

  final CompletionPerformance performance;

  DartCompletionRequestImpl._(
      this.result,
      this.context,
      this.resourceProvider,
      this.searchEngine,
      this.librarySource,
      this.source,
      this.offset,
      CompilationUnit unit,
      this._originalRequest,
      this.performance,
      this.ideOptions) {
    _updateTargets(unit);
  }

  @override
  LibraryElement get coreLib {
    if (result != null) {
      AnalysisContext context =
          resolutionMap.elementDeclaredByCompilationUnit(result.unit).context;
      _coreLib = context.typeProvider.objectType.element.library;
    } else {
      Source coreUri = sourceFactory.forUri('dart:core');
      _coreLib = context.computeLibraryElement(coreUri);
    }
    return _coreLib;
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

  @override
  String get sourceContents {
    if (result != null) {
      return result.content;
    } else {
      return context.getContents(source)?.data;
    }
  }

  @override
  SourceFactory get sourceFactory {
    return context?.sourceFactory ?? result.sourceFactory;
  }

  /**
   * Throw [AbortCompletion] if the completion request has been aborted.
   */
  void checkAborted() {
    _originalRequest.checkAborted();
  }

  @override
  Future resolveContainingExpression(AstNode node) async {
    // TODO When an Expression can be resolved instead of just an entire unit,
    // this will be revisited with code searching up the parent until an
    // Expression is found.

    return resolveContainingStatement(node);
  }

  @override
  Future resolveContainingStatement(AstNode node) async {
    // TODO When a Statement can be resolved instead of just an entire unit,
    // this will be revisited with code searching up the parent until a
    // Statement is found.

    checkAborted();

    // Return immediately if the expression has already been resolved
    if (node is Expression && node.propagatedType != null) {
      return;
    }

    // Gracefully degrade if librarySource cannot be determined
    if (librarySource == null) {
      return;
    }

    // Resolve declarations in the target unit
    // TODO(danrubel) resolve the expression or containing method
    // rather than the entire compilation unit
    CompilationUnit resolvedUnit;
    if (result != null) {
      resolvedUnit = result.unit;
    } else {
      resolvedUnit = await _computeAsync(
          this,
          new LibrarySpecificUnit(librarySource, source),
          RESOLVED_UNIT,
          performance,
          'resolve expression');
    }

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

  @override
  Future<List<ImportElement>> resolveImports() async {
    checkAborted();
    if (_resolvedImports != null) {
      return _resolvedImports;
    }
    LibraryElement libElem = libraryElement;
    if (libElem == null) {
      return null;
    }
    if (result != null) {
      _resolvedImports = libElem.imports;
    } else {
      _resolvedImports = <ImportElement>[];
      for (ImportElement importElem in libElem.imports) {
        if (importElem.importedLibrary?.exportNamespace == null) {
          await _computeAsync(this, importElem.importedLibrary.source,
              LIBRARY_ELEMENT4, performance, 'resolve imported library');
          checkAborted();
        }
        _resolvedImports.add(importElem);
      }
    }
    return _resolvedImports;
  }

  @override
  Future<List<CompilationUnitElement>> resolveUnits() async {
    checkAborted();
    if (_resolvedUnits != null) {
      return _resolvedUnits;
    }
    if (result != null) {
      _resolvedUnits = resolutionMap
          .elementDeclaredByCompilationUnit(result.unit)
          .library
          .units;
      return _resolvedUnits;
    }
    LibraryElement libElem = libraryElement;
    if (libElem == null) {
      return null;
    }
    _resolvedUnits = <CompilationUnitElement>[];
    for (CompilationUnitElement unresolvedUnit in libElem.units) {
      CompilationUnit unit = await _computeAsync(
          this,
          new LibrarySpecificUnit(libElem.source, unresolvedUnit.source),
          RESOLVED_UNIT5,
          performance,
          'resolve library unit');
      checkAborted();
      CompilationUnitElement resolvedUnit = unit?.element;
      if (resolvedUnit != null) {
        _resolvedUnits.add(resolvedUnit);
      }
    }
    return _resolvedUnits;
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

    Source libSource;
    CompilationUnit unit;
    if (request.context == null) {
      unit = request.result.unit;
      // TODO(scheglov) support for parts
      libSource = resolutionMap.elementDeclaredByCompilationUnit(unit).source;
    } else {
      Source source = request.source;
      AnalysisContext context = request.context;

      const PARSE_TAG = 'parse unit';
      performance.logStartTime(PARSE_TAG);
      unit = request.context.computeResult(source, PARSED_UNIT);
      performance.logElapseTime(PARSE_TAG);

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
        unit = await _computeAsync(
            request,
            new LibrarySpecificUnit(libSource, source),
            resultDescriptor ?? RESOLVED_UNIT5,
            performance,
            'resolve declarations');
      }
    }

    DartCompletionRequestImpl dartRequest = new DartCompletionRequestImpl._(
        request.result,
        request.context,
        request.resourceProvider,
        request.searchEngine,
        libSource,
        request.source,
        request.offset,
        unit,
        request,
        performance,
        request.ideOptions);

    // Resolve the expression in which the completion occurs
    // to properly determine if identifiers should be suggested
    // rather than invocations.
    if (dartRequest.target.maybeFunctionalArgument()) {
      AstNode node = dartRequest.target.containingNode.parent;
      if (node is Expression) {
        const FUNCTIONAL_ARG_TAG = 'resolve expression for isFunctionalArg';
        performance.logStartTime(FUNCTIONAL_ARG_TAG);
        await dartRequest.resolveContainingExpression(node);
        performance.logElapseTime(FUNCTIONAL_ARG_TAG);
        dartRequest.checkAborted();
      }
    }

    performance.logElapseTime(BUILD_REQUEST_TAG);
    return dartRequest;
  }

  static Future _computeAsync(
      CompletionRequest request,
      AnalysisTarget target,
      ResultDescriptor descriptor,
      CompletionPerformance performance,
      String perfTag) async {
    request.checkAborted();
    performance.logStartTime(perfTag);
    var result;
    try {
      result =
          await new AnalysisFutureHelper(request.context, target, descriptor)
              .computeAsync();
    } catch (e, s) {
      if (e is AnalysisNotScheduledError) {
        request.checkAborted();
      }
      throw new AnalysisException(
          'failed to $perfTag', new CaughtException(e, s));
    }
    request.checkAborted();
    return result;
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
