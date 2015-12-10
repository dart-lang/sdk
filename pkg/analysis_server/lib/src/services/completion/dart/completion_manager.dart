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
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart'
    show AnalysisFutureHelper, AnalysisContextImpl;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
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
      CompletionRequest request) {
    if (AnalysisEngine.isDartFileName(request.source.shortName)) {
      return _computeDartSuggestions(
          new DartCompletionRequestImpl.forRequest(request));
    }
    return new Future.value();
  }

  /**
   * Return a [Future] that completes with a list of suggestions
   * for the given completion [request].
   */
  Future<List<CompletionSuggestion>> _computeDartSuggestions(
      DartCompletionRequest request) async {
    // Request Dart specific completions from each contributor
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (DartCompletionContributor c in dartCompletionPlugin.contributors) {
      suggestions.addAll(await c.computeSuggestions(request));
    }
    return suggestions;
  }
}

/**
 * The information about a requested list of completions within a Dart file.
 */
class DartCompletionRequestImpl extends CompletionRequestImpl
    implements DartCompletionRequest {
  /**
   * The source for the library containing the completion request.
   * This may be different from the source in which the completion is requested
   * if the completion is being requested in a part file.
   * This may be `null` if the library for a part file cannot be determined.
   */
  Source _librarySource;

  /**
   * The [DartType] for Object in dart:core
   */
  InterfaceType _objectType;

  /**
   * `true` if [resolveDeclarationsInScope] has partially resolved the unit
   * referenced by [target], else `false`.
   */
  bool _haveResolveDeclarationsInScope = false;

  @override
  Expression dotTarget;

  @override
  CompletionTarget target;

  /**
   * Initialize a newly created completion request based on the given request.
   */
  factory DartCompletionRequestImpl.forRequest(CompletionRequest request) {
    return new DartCompletionRequestImpl._(
        request.context,
        request.resourceProvider,
        request.searchEngine,
        request.source,
        request.offset);
  }

  DartCompletionRequestImpl._(
      AnalysisContext context,
      ResourceProvider resourceProvider,
      SearchEngine searchEngine,
      Source source,
      int offset)
      : super(context, resourceProvider, searchEngine, source, offset) {
    _updateTargets(context.computeResult(source, PARSED_UNIT));
    if (target.unit.directives.any((d) => d is PartOfDirective)) {
      List<Source> libraries = context.getLibrariesContaining(source);
      if (libraries.isNotEmpty) {
        _librarySource = libraries[0];
      }
    } else {
      _librarySource = source;
    }
  }

  @override
  Future<LibraryElement> get libraryElement async {
    //TODO(danrubel) build the library element rather than all the declarations
    CompilationUnit unit = await resolveDeclarationsInScope();
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
      Source coreUri = context.sourceFactory.forUri('dart:core');
      LibraryElement coreLib = context.getLibraryElement(coreUri);
      _objectType = coreLib.getType('Object').type;
    }
    return _objectType;
  }

  @override
  Future<CompilationUnit> resolveDeclarationsInScope() async {
    CompilationUnit unit = target.unit;
    if (_haveResolveDeclarationsInScope) {
      return unit;
    }

    // Gracefully degrade if librarySource cannot be determined
    if (_librarySource == null) {
      return null;
    }

    // Resolve declarations in the target unit
    CompilationUnit resolvedUnit =
        await new AnalysisFutureHelper<CompilationUnit>(context,
                new LibrarySpecificUnit(_librarySource, source), RESOLVED_UNIT3)
            .computeAsync();

    // TODO(danrubel) determine if the underlying source has been modified
    // in a way that invalidates the completion request
    // and return null

    // Gracefully degrade if unit cannot be resolved
    if (resolvedUnit == null) {
      return null;
    }

    // Recompute the target for the newly resolved unit
    _updateTargets(resolvedUnit);
    _haveResolveDeclarationsInScope = true;
    return resolvedUnit;
  }

  @override
  Future<List<Directive>> resolveDirectives() async {
    CompilationUnit libUnit;
    if (_librarySource == source) {
      libUnit = await resolveDeclarationsInScope();
    } else if (_librarySource != null) {
      libUnit = await new AnalysisFutureHelper<CompilationUnit>(
              context,
              new LibrarySpecificUnit(_librarySource, _librarySource),
              RESOLVED_UNIT3)
          .computeAsync();
    }
    return libUnit?.directives;
  }

  @override
  Future resolveExpression(Expression expression) async {
    //TODO(danrubel) resolve the expression or containing method
    // rather than the entire complilation unit

    // Gracefully degrade if librarySource cannot be determined
    if (_librarySource == null) {
      return null;
    }

    // Resolve declarations in the target unit
    CompilationUnit resolvedUnit =
        await new AnalysisFutureHelper<CompilationUnit>(context,
                new LibrarySpecificUnit(_librarySource, source), RESOLVED_UNIT)
            .computeAsync();

    // TODO(danrubel) determine if the underlying source has been modified
    // in a way that invalidates the completion request
    // and return null

    // Gracefully degrade if unit cannot be resolved
    if (resolvedUnit == null) {
      return null;
    }

    // Recompute the target for the newly resolved unit
    _updateTargets(resolvedUnit);
    _haveResolveDeclarationsInScope = true;
  }

  /**
   * Update the completion [target] and [dotTarget] based on the given [unit].
   */
  void _updateTargets(CompilationUnit unit) {
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
}
