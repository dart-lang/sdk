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
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart'
    show AnalysisFutureHelper, AnalysisContextImpl;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisContextImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';

/**
 * [DartCompletionManager] determines if a completion request is Dart specific
 * and forwards those requests to all [DartCompletionContributor]s.
 */
class DartCompletionManager implements CompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      CompletionRequest request) async {
    if (!AnalysisEngine.isDartFileName(request.source.shortName)) {
      return EMPTY_LIST;
    }

    DartCompletionRequestImpl dartRequest =
        await DartCompletionRequestImpl.from(request);

    // Don't suggest in comments.
    if (dartRequest.target.isCommentText) {
      return EMPTY_LIST;
    }

    // Request Dart specific completions from each contributor
    Map<String, CompletionSuggestion> suggestionMap =
        <String, CompletionSuggestion>{};
    for (DartCompletionContributor contributor
        in dartCompletionPlugin.contributors) {
      for (CompletionSuggestion newSuggestion
          in await contributor.computeSuggestions(dartRequest)) {
        var oldSuggestion = suggestionMap.putIfAbsent(
            newSuggestion.completion, () => newSuggestion);
        if (newSuggestion != oldSuggestion &&
            newSuggestion.relevance > oldSuggestion.relevance) {
          suggestionMap[newSuggestion.completion] = newSuggestion;
        }
      }
    }
    return suggestionMap.values.toList();
  }
}

/**
 * The information about a requested list of completions within a Dart file.
 */
class DartCompletionRequestImpl extends CompletionRequestImpl
    implements DartCompletionRequest {
  /**
   * The [LibraryElement] representing dart:core
   */
  LibraryElement _coreLib;

  /**
   * The [DartType] for Object in dart:core
   */
  InterfaceType _objectType;

  @override
  Expression dotTarget;

  @override
  Source librarySource;

  OpType _opType;

  @override
  CompletionTarget target;

  DartCompletionRequestImpl._(
      AnalysisContext context,
      ResourceProvider resourceProvider,
      SearchEngine searchEngine,
      this.librarySource,
      Source source,
      int offset,
      CompilationUnit unit)
      : super(context, resourceProvider, searchEngine, source, offset) {
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
    if (librarySource == source) {
      libUnit = target.unit;
    } else if (librarySource != null) {
      // TODO(danrubel) only resolve the directives
      libUnit = await new AnalysisFutureHelper<CompilationUnit>(
              context,
              new LibrarySpecificUnit(librarySource, librarySource),
              RESOLVED_UNIT3)
          .computeAsync();
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
    CompilationUnit resolvedUnit =
        await new AnalysisFutureHelper<CompilationUnit>(context,
                new LibrarySpecificUnit(librarySource, source), RESOLVED_UNIT)
            .computeAsync();

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
    Source source = request.source;
    AnalysisContext context = request.context;
    CompilationUnit unit = request.context.computeResult(source, PARSED_UNIT);

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
      unit = await new AnalysisFutureHelper<CompilationUnit>(context,
              new LibrarySpecificUnit(libSource, source), RESOLVED_UNIT3)
          .computeAsync();

    }

    DartCompletionRequestImpl dartRequest = new DartCompletionRequestImpl._(
        request.context,
        request.resourceProvider,
        request.searchEngine,
        libSource,
        request.source,
        request.offset,
        unit);

    // Resolve the expression in which the completion occurs
    // to properly determine if identifiers should be suggested
    // rather than invocations.
    if (dartRequest.target.maybeFunctionalArgument()) {
      AstNode node = dartRequest.target.containingNode.parent;
      if (node is Expression) {
        await dartRequest.resolveExpression(node);
      }
    }

    return dartRequest;
  }
}
