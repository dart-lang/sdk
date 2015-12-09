// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.combinator;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A contributor for calculating `completion.getSuggestions` request results
 * for the import combinators show and hide.
 */
class CombinatorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    AstNode node = request.target.containingNode;
    if (node is! Combinator) {
      return EMPTY_LIST;
    }

    // Partially resolve the compilation unit
    CompilationUnit unit = await request.resolveDeclarationsInScope();
    // Gracefully degrade if the compilation unit could not be resolved
    // e.g. detached part file or source change
    if (unit == null) {
      return EMPTY_LIST;
    }

    // Check the target since resolution may have changed it
    node = request.target.containingNode;
    if (node is! Combinator) {
      return EMPTY_LIST;
    }

    // Build list of suggestions
    var directive = node.getAncestor((parent) => parent is NamespaceDirective);
    if (directive is NamespaceDirective) {
      LibraryElement library = directive.uriElement;
      if (library != null) {
        LibraryElementSuggestionBuilder builder =
            new LibraryElementSuggestionBuilder(
                library, CompletionSuggestionKind.IDENTIFIER, false, false);
        library.visitChildren(builder);
        return builder.suggestions;
      }
    }
    return EMPTY_LIST;
  }
}
