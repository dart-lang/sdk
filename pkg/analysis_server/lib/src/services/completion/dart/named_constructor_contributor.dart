// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;

/**
 * A contributor for calculating named constructor suggestions
 * such as suggesting `bar` in `new Foo.bar()`.
 */
class NamedConstructorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    AstNode node = request.target.containingNode;
    LibraryElement libElem = request.libraryElement;
    if (libElem == null) {
      return EMPTY_LIST;
    }

    // Build the list of suggestions
    if (node is ConstructorName) {
      TypeName typeName = node.type;
      if (typeName != null) {
        DartType type = typeName.type;
        if (type != null) {
          Element classElem = type.element;
          if (classElem is ClassElement) {
            return _buildSuggestions(libElem, classElem);
          }
        }
      }
    }
    return EMPTY_LIST;
  }

  List<CompletionSuggestion> _buildSuggestions(
      LibraryElement libElem, ClassElement classElem) {
    bool isLocalClassDecl = classElem.library == libElem;
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (ConstructorElement elem in classElem.constructors) {
      if (isLocalClassDecl || !elem.isPrivate) {
        String name = elem.name;
        if (name != null) {
          CompletionSuggestion s = createSuggestion(elem, completion: name);
          if (s != null) {
            suggestions.add(s);
          }
        }
      }
    }
    return suggestions;
  }
}
