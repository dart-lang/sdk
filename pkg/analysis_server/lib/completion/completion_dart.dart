// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.completion.completion_dart;

import 'package:analysis_server/completion/completion_core.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An object used to produce completions for a specific error within a Dart
 * file. Completion contributors are long-lived objects and must not retain any
 * state between invocations of [computeSuggestions].
 *
 * Clients are expected to subtype this class when implementing plugins.
 */
abstract class DartCompletionContributor extends CompletionContributor {
  @override
  CompletionResult computeSuggestions(CompletionRequest request) {
    if (request is DartCompletionRequest) {
      return internalComputeSuggestions(request);
    }
    AnalysisContext context = request.context;
    Source source = request.source;
    List<Source> libraries = context.getLibrariesContaining(source);
    if (libraries.length < 1) {
      return null;
    }
//    CompilationUnit unit =
//        context.getResolvedCompilationUnit2(source, libraries[0]);
//    bool isResolved = true;
//    if (unit == null) {
//      // TODO(brianwilkerson) Implement a method for getting a parsed
//      // compilation unit without parsing the unit if it hasn't been parsed.
//      unit = context.getParsedCompilationUnit(source);
//      if (unit == null) {
//        return null;
//      }
//      isResolved = false;
//    }
//    DartCompletionRequest dartRequest =
//        new DartCompletionRequestImpl(request, unit, isResolved);
//    return internalComputeSuggestions(dartRequest);
    return null;
  }

  /**
   * Compute a list of completion suggestions based on the given completion
   * [request] and return a result that includes those suggestions. This method
   * is called after specific phases of analysis until the contributor indicates
   * computation is complete by setting [CompletionResult.isLast] to `true`.
   */
  CompletionResult internalComputeSuggestions(DartCompletionRequest request);
}

/**
 * The information about a requested list of completions within a Dart file.
 */
abstract class DartCompletionRequest extends CompletionRequest {
  /**
   * Return `true` if the compilation [unit] is resolved.
   */
  bool get isResolved;

  /**
   * Return the compilation unit in which the completion was requested.
   */
  CompilationUnit get unit;

  /**
   * Cached information from a prior code completion operation.
   */
  //DartCompletionCache get cache;

  /**
   * Return the completion target.  This determines what part of the parse tree
   * will receive the newly inserted text.
   */
  //CompletionTarget get target;

  /**
   * Information about the types of suggestions that should be included.
   */
  //OpType get _optype;
}
