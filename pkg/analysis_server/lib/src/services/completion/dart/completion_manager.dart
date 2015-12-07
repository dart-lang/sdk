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
   * The cached completion target or `null` if not computed yet.
   */
  CompletionTarget _target;

  /**
   * `true` if [resolveDeclarationsInScope] has partially resolved the unit
   * referenced by [target], else `false`.
   */
  bool _haveResolveDeclarationsInScope = false;

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
      : super(context, resourceProvider, searchEngine, source, offset);

  @override
  CompletionTarget get target {
    if (_target == null) {
      CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
      _target = new CompletionTarget.forOffset(unit, offset);
    }
    return _target;
  }

  @override
  Future<CompilationUnit> resolveDeclarationsInScope() async {
    CompilationUnit unit = target.unit;
    if (_haveResolveDeclarationsInScope) {
      return unit;
    }

    // Determine the library source
    Source librarySource;
    if (unit.directives.any((d) => d is PartOfDirective)) {
      List<Source> libraries = context.getLibrariesContaining(source);
      if (libraries.isEmpty) {
        return null;
      }
      librarySource = libraries[0];
    } else {
      librarySource = source;
    }

    // Resolve declarations in the target unit
    CompilationUnit resolvedUnit =
        await new AnalysisFutureHelper<CompilationUnit>(
            context,
            new LibrarySpecificUnit(librarySource, source),
            RESOLVED_UNIT3).computeAsync();

    // TODO(danrubel) determine if the underlying source has been modified
    // in a way that invalidates the completion request
    // and return null

    // Gracefully degrade if unit cannot be resolved
    if (resolvedUnit == null) {
      return null;
    }

    // Recompute the target for the newly resolved unit
    _target = new CompletionTarget.forOffset(resolvedUnit, offset);
    _haveResolveDeclarationsInScope = true;
    return resolvedUnit;
  }

  @override
  Future resolveIdentifier(SimpleIdentifier identifier) async {
    if (identifier.bestElement != null) {
      return;
    }

    //TODO(danrubel) resolve the expression or containing method
    // rather than the entire complilation unit

    CompilationUnit unit = target.unit;

    // Determine the library source
    Source librarySource;
    if (unit.directives.any((d) => d is PartOfDirective)) {
      List<Source> libraries = context.getLibrariesContaining(source);
      if (libraries.isEmpty) {
        return;
      }
      librarySource = libraries[0];
    } else {
      librarySource = source;
    }

    // Resolve declarations in the target unit
    CompilationUnit resolvedUnit =
        await new AnalysisFutureHelper<CompilationUnit>(
            context,
            new LibrarySpecificUnit(librarySource, source),
            RESOLVED_UNIT).computeAsync();

    // TODO(danrubel) determine if the underlying source has been modified
    // in a way that invalidates the completion request
    // and return null

    // Gracefully degrade if unit cannot be resolved
    if (resolvedUnit == null) {
      return;
    }

    // Recompute the target for the newly resolved unit
    _target = new CompletionTarget.forOffset(resolvedUnit, offset);
    _haveResolveDeclarationsInScope = true;
  }
}
