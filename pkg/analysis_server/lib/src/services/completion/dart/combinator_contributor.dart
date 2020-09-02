// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// A contributor that produces suggestions based on the members of a library
/// when the completion is in a show or hide combinator of an import or export.
class CombinatorContributor extends DartCompletionContributor {
  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var node = request.target.containingNode;
    if (node is! Combinator) {
      return;
    }
    // Build the list of suggestions.
    var directive = node.thisOrAncestorOfType<NamespaceDirective>();
    if (directive is NamespaceDirective) {
      var library = directive.uriElement as LibraryElement;
      if (library != null) {
        var existingNames = _getCombinatorNames(directive);
        for (var element in library.exportNamespace.definedNames.values) {
          if (!existingNames.contains(element.name)) {
            builder.suggestElement(element,
                kind: CompletionSuggestionKind.IDENTIFIER);
          }
        }
      }
    }
  }

  List<String> _getCombinatorNames(NamespaceDirective directive) {
    var combinatorNameList = <String>[];
    for (var combinator in directive.combinators) {
      if (combinator is ShowCombinator) {
        for (var simpleId in combinator.shownNames) {
          if (!simpleId.isSynthetic) {
            combinatorNameList.add(simpleId.name);
          }
        }
      } else if (combinator is HideCombinator) {
        for (var simpleId in combinator.hiddenNames) {
          if (!simpleId.isSynthetic) {
            combinatorNameList.add(simpleId.name);
          }
        }
      }
    }
    return combinatorNameList;
  }
}
