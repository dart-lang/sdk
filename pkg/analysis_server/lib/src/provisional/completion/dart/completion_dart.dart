// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.provisional.completion.completion_dart;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';

export 'package:analysis_server/src/provisional/completion/completion_core.dart'
    show EMPTY_LIST;

const int DART_RELEVANCE_COMMON_USAGE = 1200;
const int DART_RELEVANCE_DEFAULT = 1000;
const int DART_RELEVANCE_HIGH = 2000;
const int DART_RELEVANCE_INCREMENT = 100;
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
 * An object used to instantiate a [DartCompletionContributor] instance
 * for each 'completion.getSuggestions' request.
 * Contributors should *not* be cached between requests.
 */
typedef DartCompletionContributor DartCompletionContributorFactory();

/**
 * An object used to produce completions
 * at a specific location within a Dart file.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class DartCompletionContributor {
  /**
   * Return a [Future] that completes with a list of suggestions
   * for the given completion [request].
   */
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request);
}

/**
 * The information about a requested list of completions within a Dart file.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartCompletionRequest extends CompletionRequest {
  /**
   * Return the dart:core library element
   */
  LibraryElement get coreLib;

  /**
   * Return the expression to the right of the "dot" or "dot dot",
   * or `null` if this is not a "dot" completion (e.g. `foo.b`).
   */
  Expression get dotTarget;

  /**
   * Return `true` if free standing identifiers should be suggested
   */
  bool get includeIdentifiers;

  /**
   * Return the library element which contains the unit in which the completion
   * is occurring. This may return `null` if the library cannot be determined
   * (e.g. unlinked part file).
   */
  LibraryElement get libraryElement;

  /**
   * The source for the library containing the completion request.
   * This may be different from the source in which the completion is requested
   * if the completion is being requested in a part file.
   * This may be `null` if the library for a part file cannot be determined.
   */
  Source get librarySource;

  /**
   * Answer the [DartType] for Object in dart:core
   */
  DartType get objectType;

  /**
   * The [OpType] which describes which types of suggestions would fit the
   * request.
   */
  OpType get opType;

  /**
   * Return the [SourceFactory] of the request.
   */
  SourceFactory get sourceFactory;

  /**
   * Return the completion target.  This determines what part of the parse tree
   * will receive the newly inserted text.
   * At a minimum, all declarations in the completion scope in [target.unit]
   * will be resolved if they can be resolved.
   */
  CompletionTarget get target;

  /**
   * Return a [Future] that completes when the element associated with
   * the given [expression] in the target compilation unit is available.
   * It may also complete if the expression cannot be resolved
   * (e.g. unknown identifier, completion aborted, etc).
   * Any information obtained from [target] prior to calling this method
   * should be discarded as it may have changed.
   */
  Future resolveContainingExpression(AstNode node);

  /**
   * Return a [Future] that completes when the element associated with
   * the given [statement] in the target compilation unit is available.
   * It may also complete if the statement cannot be resolved
   * (e.g. unknown identifier, completion aborted, etc).
   * Any information obtained from [target] prior to calling this method
   * should be discarded as it may have changed.
   */
  Future resolveContainingStatement(AstNode node);

  /**
     * Return a [Future] that completes with a list of [ImportElement]s
     * for the library in which in which the completion is occurring.
     * The [Future] may return `null` if the library unit cannot be determined
     * (e.g. unlinked part file).
     * Any information obtained from [target] prior to calling this method
     * should be discarded as it may have changed.
     */
  Future<List<ImportElement>> resolveImports();

  /**
   * Return a [Future] that completes with a list of [CompilationUnitElement]s
   * comprising the library in which in which the completion is occurring.
   * The [Future] may return `null` if the library unit cannot be determined
   * (e.g. unlinked part file).
   * Any information obtained from [target] prior to calling this method
   * should be discarded as it may have changed.
   */
  Future<List<CompilationUnitElement>> resolveUnits();
}
