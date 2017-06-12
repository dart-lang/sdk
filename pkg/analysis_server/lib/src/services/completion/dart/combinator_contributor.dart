// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

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

    // Build list of suggestions
    var directive = node.getAncestor((parent) => parent is NamespaceDirective);
    if (directive is NamespaceDirective) {
      LibraryElement library = directive.uriElement;
      if (library != null) {
        LibraryElementSuggestionBuilder builder =
            new LibraryElementSuggestionBuilder(
                request.libraryElement,
                CompletionSuggestionKind.IDENTIFIER,
                false,
                false,
                request.ideOptions);
        library.visitChildren(builder);
        return builder.suggestions;
      }
    }
    return EMPTY_LIST;
  }
}
