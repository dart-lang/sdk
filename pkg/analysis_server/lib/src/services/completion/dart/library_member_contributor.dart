// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A contributor for calculating prefixed import library member suggestions
 * `completion.getSuggestions` request results.
 */
class LibraryMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // Determine if the target looks like a library prefix
    Expression targetId = request.dotTarget;
    if (targetId is SimpleIdentifier && !request.target.isCascade) {
      Element elem = targetId.bestElement;
      if (elem is PrefixElement && !elem.isSynthetic) {
        LibraryElement containingLibrary = request.libraryElement;
        // Gracefully degrade if the library or directives
        // could not be determined (e.g. detached part file or source change)
        if (containingLibrary != null) {
          List<ImportElement> imports = containingLibrary.imports;
          if (imports != null) {
            return _buildSuggestions(request, elem, containingLibrary, imports);
          }
        }
      }
    }
    return EMPTY_LIST;
  }

  List<CompletionSuggestion> _buildSuggestions(
      DartCompletionRequest request,
      PrefixElement elem,
      LibraryElement containingLibrary,
      List<ImportElement> imports) {
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (ImportElement importElem in imports) {
      if (importElem.prefix?.name == elem.name) {
        LibraryElement library = importElem.importedLibrary;
        if (library != null) {
          // Suggest elements from the imported library
          AstNode parent = request.target.containingNode.parent;
          bool isConstructor = parent.parent is ConstructorName;
          bool typesOnly = parent is TypeName;
          bool instCreation = typesOnly && isConstructor;
          LibraryElementSuggestionBuilder builder =
              new LibraryElementSuggestionBuilder(
                  containingLibrary,
                  CompletionSuggestionKind.INVOCATION,
                  typesOnly,
                  instCreation,
                  request.ideOptions);
          library.visitChildren(builder);
          suggestions.addAll(builder.suggestions);

          // If the import is 'deferred' then suggest 'loadLibrary'
          if (importElem.isDeferred) {
            FunctionElement loadLibFunct = library.loadLibraryFunction;
            suggestions.add(createSuggestion(loadLibFunct, request.ideOptions));
          }
        }
      }
    }
    return suggestions;
  }
}
