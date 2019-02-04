// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
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
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    AstNode node = request.target.containingNode;
    if (node is! Combinator) {
      return const <CompletionSuggestion>[];
    }

    // Build list of suggestions
    var directive = node.thisOrAncestorOfType<NamespaceDirective>();
    if (directive is NamespaceDirective) {
      LibraryElement library = directive.uriElement;
      if (library != null) {
        LibraryElementSuggestionBuilder builder =
            new LibraryElementSuggestionBuilder(request.libraryElement,
                CompletionSuggestionKind.IDENTIFIER, false, false);
        for (var element in library.exportNamespace.definedNames.values) {
          element.accept(builder);
        }
        return builder.suggestions;
      }
    }
    return const <CompletionSuggestion>[];
  }
}
