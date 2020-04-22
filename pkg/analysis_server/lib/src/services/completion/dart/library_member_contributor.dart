// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/// A contributor that produces suggestions based on the members of a library
/// when the library was imported using a prefix. More concretely, this class
/// produces suggestions for expressions of the form `p.^`, where `p` is a
/// prefix.
class LibraryMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    // Determine if the target looks like a library prefix.
    var targetId = request.dotTarget;
    if (targetId is SimpleIdentifier && !request.target.isCascade) {
      var elem = targetId.staticElement;
      if (elem is PrefixElement && !elem.isSynthetic) {
        var containingLibrary = request.libraryElement;
        // Gracefully degrade if the library or directives could not be
        // determined (e.g. detached part file or source change).
        if (containingLibrary != null) {
          var imports = containingLibrary.imports;
          if (imports != null) {
            return _buildSuggestions(request, elem, imports);
          }
        }
      }
    }
    return const <CompletionSuggestion>[];
  }

  List<CompletionSuggestion> _buildSuggestions(DartCompletionRequest request,
      PrefixElement elem, List<ImportElement> imports) {
    var parent = request.target.containingNode.parent;
    var isConstructor = parent.parent is ConstructorName;
    var typesOnly = parent is TypeName;
    var instCreation = typesOnly && isConstructor;
    var builder = LibraryElementSuggestionBuilder(
        request, CompletionSuggestionKind.INVOCATION, typesOnly, instCreation);
    for (var importElem in imports) {
      if (importElem.prefix?.name == elem.name) {
        var library = importElem.importedLibrary;
        if (library != null) {
          // Suggest elements from the imported library.
          for (var element in importElem.namespace.definedNames.values) {
            element.accept(builder);
          }
          // If the import is 'deferred' then suggest 'loadLibrary'.
          if (importElem.isDeferred) {
            var function = library.loadLibraryFunction;
            var relevance = request.useNewRelevance
                ? Relevance.loadLibrary
                : (function.hasDeprecated
                    ? DART_RELEVANCE_LOW
                    : DART_RELEVANCE_DEFAULT);
            builder.suggestions
                .add(createSuggestion(request, function, relevance: relevance));
          }
        }
      }
    }
    return builder.suggestions;
  }
}
