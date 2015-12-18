// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.library_member;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/ast.dart';

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
    if (request.dotTarget is! SimpleIdentifier) {
      return EMPTY_LIST;
    }

    // Resolve the expression and the containing library
    await request.resolveExpression(request.dotTarget);

    // Recompute the target since resolution may have changed it
    Expression targetId = request.dotTarget;
    if (targetId is SimpleIdentifier && !request.target.isCascade) {
      Element elem = targetId.bestElement;
      if (elem is PrefixElement) {
        List<Directive> directives = await request.resolveDirectives();
        LibraryElement containingLibrary = request.libraryElement;
        // Gracefully degrade if the library or directives
        // could not be determined (e.g. detached part file or source change)
        if (containingLibrary != null && directives != null) {
          return _buildSuggestions(
              request, elem, containingLibrary, directives);
        }
      }
    }
    return EMPTY_LIST;
  }

  List<CompletionSuggestion> _buildSuggestions(
      DartCompletionRequest request,
      PrefixElement elem,
      LibraryElement containingLibrary,
      List<Directive> directives) {
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (Directive directive in directives) {
      if (directive is ImportDirective) {
        if (directive.prefix != null) {
          if (directive.prefix.name == elem.name) {
            LibraryElement library = directive.uriElement;

            // Suggest elements from the imported library
            if (library != null) {
              AstNode parent = request.target.containingNode.parent;
              bool isConstructor = parent.parent is ConstructorName;
              bool typesOnly = parent is TypeName;
              bool instCreation = typesOnly && isConstructor;
              LibraryElementSuggestionBuilder builder =
                  new LibraryElementSuggestionBuilder(
                      containingLibrary,
                      CompletionSuggestionKind.INVOCATION,
                      typesOnly,
                      instCreation);
              library.visitChildren(builder);
              suggestions.addAll(builder.suggestions);

              // If the import is 'deferred' then suggest 'loadLibrary'
              if (directive.deferredKeyword != null) {
                FunctionElement loadLibFunct = library.loadLibraryFunction;
                suggestions.add(createSuggestion(loadLibFunct));
              }
            }
          }
        }
      }
    }
    return suggestions;
  }
}
