// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// A contributor that produces suggestions based on the named constructors
/// defined on a given class. More concretely, this class produces suggestions
/// for expressions of the form `C.^` or `C<E>.^`, where `C` is the name of a
/// class.
class NamedConstructorContributor extends DartCompletionContributor {
  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var node = request.target.containingNode;
    if (node is ConstructorName) {
      var libraryElement = request.libraryElement;
      if (libraryElement == null) {
        return;
      }
      var typeName = node.type;
      if (typeName != null) {
        var type = typeName.type;
        if (type != null) {
          var element = type.element;
          if (element is ClassElement) {
            _buildSuggestions(request, builder, libraryElement, element);
          }
        }
      }
    }
  }

  void _buildSuggestions(
      DartCompletionRequest request,
      SuggestionBuilder builder,
      LibraryElement libElem,
      ClassElement classElem) {
    var isLocalClassDecl = classElem.library == libElem;
    for (var constructor in classElem.constructors) {
      if (isLocalClassDecl || !constructor.isPrivate) {
        var name = constructor.name;
        if (name != null) {
          builder.suggestConstructor(constructor, hasClassName: true);
        }
      }
    }
  }
}
