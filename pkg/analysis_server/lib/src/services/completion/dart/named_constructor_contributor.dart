// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.named_constructor;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/**
 * A contributor for calculating named constructor suggestions
 * such as suggesting `bar` in `new Foo.bar()`.
 */
class NamedConstructorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // Determine if the target looks like a named constructor.
    AstNode parsedNode = request.target.containingNode;
    SimpleIdentifier targetId;
    if (parsedNode is ConstructorName) {
      TypeName type = parsedNode.type;
      if (type != null) {
        targetId = type.name;
      }
    } else if (parsedNode is PrefixedIdentifier) {
      // Some PrefixedIdentifier nodes are transformed into
      // ConstructorName nodes during the resolution process.
      targetId = parsedNode.prefix;
    }
    if (targetId == null) {
      return EMPTY_LIST;
    }

    // Resolve the target to determine the type
    await request.resolveContainingExpression(targetId);

    // Recompute the target since resolution may have changed it
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
            return _buildSuggestions(libElem, classElem, request.ideOptions);
          }
        }
      }
    }
    return EMPTY_LIST;
  }

  List<CompletionSuggestion> _buildSuggestions(
      LibraryElement libElem, ClassElement classElem, IdeOptions options) {
    bool isLocalClassDecl = classElem.library == libElem;
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (ConstructorElement elem in classElem.constructors) {
      if (isLocalClassDecl || !elem.isPrivate) {
        String name = elem.name;
        if (name != null) {
          CompletionSuggestion s =
              createSuggestion(elem, options, completion: name);
          if (s != null) {
            suggestions.add(s);
          }
        }
      }
    }
    return suggestions;
  }
}
