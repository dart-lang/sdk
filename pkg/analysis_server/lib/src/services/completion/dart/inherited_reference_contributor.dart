// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.inherited_ref;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A contributor for calculating suggestions for inherited references.
 */
class InheritedReferenceContributor extends DartCompletionContributor
    with ElementSuggestionBuilder {
  @override
  LibraryElement containingLibrary;

  @override
  CompletionSuggestionKind kind;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    if (!request.includeIdentifiers) {
      return EMPTY_LIST;
    }
    ClassDeclaration classDecl = _enclosingClass(request.target);
    if (classDecl == null || classDecl.element == null) {
      return EMPTY_LIST;
    }

    containingLibrary = request.libraryElement;
    bool isFunctionalArgument = request.target.isFunctionalArgument();
    kind = isFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : CompletionSuggestionKind.INVOCATION;
    OpType optype = (request as DartCompletionRequestImpl).opType;
    for (InterfaceType type in classDecl.element.allSupertypes) {
      if (!isFunctionalArgument) {
        for (PropertyAccessorElement elem in type.accessors) {
          if (elem.isGetter) {
            if (optype.includeReturnValueSuggestions) {
              addSuggestion(elem);
            }
          } else {
            if (optype.includeVoidReturnSuggestions) {
              addSuggestion(elem);
            }
          }
        }
      }
      for (MethodElement elem in type.methods) {
        if (elem.returnType == null) {
          addSuggestion(elem);
        } else if (!elem.returnType.isVoid) {
          if (optype.includeReturnValueSuggestions) {
            addSuggestion(elem);
          }
        } else {
          if (optype.includeVoidReturnSuggestions) {
            addSuggestion(elem);
          }
        }
      }
    }
    return suggestions;
  }
}

/**
 * Return the class containing the target
 * or `null` if the target is in a static method or field
 * or not in a class.
 */
ClassDeclaration _enclosingClass(CompletionTarget target) {
  AstNode node = target.containingNode;
  while (node != null) {
    if (node is ClassDeclaration) {
      return node;
    }
    if (node is MethodDeclaration) {
      if (node.isStatic) {
        return null;
      }
    }
    if (node is FieldDeclaration) {
      if (node.isStatic) {
        return null;
      }
    }
    node = node.parent;
  }
  return null;
}
