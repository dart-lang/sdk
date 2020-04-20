// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;

/// A contributor that produces suggestions based on the named constructors
/// defined on a given class. More concretely, this class produces suggestions
/// for expressions of the form `C.^` or `C<E>.^`, where `C` is the name of a
/// class.
class NamedConstructorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var node = request.target.containingNode;
    var libraryElement = request.libraryElement;
    if (libraryElement == null) {
      return const <CompletionSuggestion>[];
    }

    // Build the list of suggestions
    if (node is ConstructorName) {
      var typeName = node.type;
      if (typeName != null) {
        var type = typeName.type;
        if (type != null) {
          var element = type.element;
          if (element is ClassElement) {
            return _buildSuggestions(
                request, libraryElement, element, request.useNewRelevance);
          }
        }
      }
    }
    return const <CompletionSuggestion>[];
  }

  List<CompletionSuggestion> _buildSuggestions(DartCompletionRequest request,
      LibraryElement libElem, ClassElement classElem, bool useNewRelevance) {
    var isLocalClassDecl = classElem.library == libElem;
    var suggestions = <CompletionSuggestion>[];
    for (var constructor in classElem.constructors) {
      if (isLocalClassDecl || !constructor.isPrivate) {
        var name = constructor.name;
        if (name != null) {
          var relevance = useNewRelevance
              ? Relevance.namedConstructor
              : DART_RELEVANCE_DEFAULT;
          var suggestion = createSuggestion(request, constructor,
              completion: name,
              relevance: relevance,
              useNewRelevance: useNewRelevance);
          if (suggestion != null) {
            suggestions.add(suggestion);
          }
        }
      }
    }
    return suggestions;
  }
}
