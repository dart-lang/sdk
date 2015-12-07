// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.provisional.completion.completion_dart;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

export 'package:analysis_server/src/provisional/completion/completion_core.dart'
    show EMPTY_LIST;

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
   * Return a [Future] that completes with the library element
   * which contains the unit in which the completion is occurring.
   * The [Future] may return `null` if the library cannot be determined
   * (e.g. unlinked part file).
   * Any information obtained from [target] prior to calling this method
   * should be discarded as it may have changed.
   */
  Future<LibraryElement> get libraryElement;

  /**
   * Return the completion target.  This determines what part of the parse tree
   * will receive the newly inserted text.
   */
  CompletionTarget get target;

  /**
   * Return a [Future] that completes with a compilation unit in which
   * all declarations in all scopes containing [target] have been resolved.
   * The [Future] may return `null` if the unit cannot be resolved
   * (e.g. unlinked part file).
   * Any information obtained from [target] prior to calling this method
   * should be discarded as it may have changed.
   */
  Future<CompilationUnit> resolveDeclarationsInScope();

  /**
   * Return a [Future] that completes when the element associated with
   * the given [identifier] is available or if the identifier cannot be resolved
   * (e.g. unknown identifier, completion aborted, etc).
   * Any information obtained from [target] prior to calling this method
   * should be discarded as it may have changed.
   */
  Future resolveIdentifier(SimpleIdentifier identifier);
}
