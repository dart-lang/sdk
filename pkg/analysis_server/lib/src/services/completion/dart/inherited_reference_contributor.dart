// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

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
    return _computeSuggestionsForClass2(
        resolutionMap.elementDeclaredByClassDeclaration(classDecl), request);
  }

  List<CompletionSuggestion> computeSuggestionsForClass(
      ClassElement classElement, DartCompletionRequest request,
      {bool skipChildClass: true}) {
    if (!request.includeIdentifiers) {
      return EMPTY_LIST;
    }
    containingLibrary = request.libraryElement;

    return _computeSuggestionsForClass2(classElement, request,
        skipChildClass: skipChildClass);
  }

  _addSuggestionsForType(
      InterfaceType type, OpType optype, IdeOptions ideOptions,
      {bool isFunctionalArgument: false}) {
    if (!isFunctionalArgument) {
      for (PropertyAccessorElement elem in type.accessors) {
        if (elem.isGetter) {
          if (optype.includeReturnValueSuggestions) {
            addSuggestion(elem, ideOptions);
          }
        } else {
          if (optype.includeVoidReturnSuggestions) {
            addSuggestion(elem, ideOptions);
          }
        }
      }
    }
    for (MethodElement elem in type.methods) {
      if (elem.returnType == null) {
        addSuggestion(elem, ideOptions);
      } else if (!elem.returnType.isVoid) {
        if (optype.includeReturnValueSuggestions) {
          addSuggestion(elem, ideOptions);
        }
      } else {
        if (optype.includeVoidReturnSuggestions) {
          addSuggestion(elem, ideOptions);
        }
      }
    }
  }

  List<CompletionSuggestion> _computeSuggestionsForClass2(
      ClassElement classElement, DartCompletionRequest request,
      {bool skipChildClass: true}) {
    bool isFunctionalArgument = request.target.isFunctionalArgument();
    kind = isFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : CompletionSuggestionKind.INVOCATION;
    OpType optype = request.opType;

    if (!skipChildClass) {
      _addSuggestionsForType(classElement.type, optype, request.ideOptions,
          isFunctionalArgument: isFunctionalArgument);
    }

    for (InterfaceType type in classElement.allSupertypes) {
      _addSuggestionsForType(type, optype, request.ideOptions,
          isFunctionalArgument: isFunctionalArgument);
    }
    return suggestions;
  }
}
