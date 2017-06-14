// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/element_suggestion_builder.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';

/**
 * A contributor for calculating suggestions for inherited references.
 *
 * Plugin developers should extend this function and primarily
 * overload `computeSuggestions` (if needed).
 */
class InheritedReferenceContributor extends Object
    with ElementSuggestionBuilder
    implements CompletionContributor {
  @override
  LibraryElement containingLibrary;

  @override
  CompletionSuggestionKind kind;

  @override
  ResourceProvider resourceProvider;

  /**
   * Plugin contributors should primarily overload this function.
   * Should more parameters be needed for autocompletion needs, the
   * overloaded function should define those parameters and
   * call on `computeSuggestionsForClass`.
   */
  @override
  Future<Null> computeSuggestions(
      CompletionRequest request, CompletionCollector collector) async {
    CompletionTarget target =
        new CompletionTarget.forOffset(request.result.unit, request.offset);
    OpType optype = new OpType.forCompletion(target, request.offset);
    if (!optype.includeIdentifiers) {
      return;
    }
    ClassDeclaration classDecl = _enclosingClass(target);
    if (classDecl == null || classDecl.element == null) {
      return;
    }
    containingLibrary = request.result.libraryElement;
    _computeSuggestionsForClass2(collector, target,
        resolutionMap.elementDeclaredByClassDeclaration(classDecl), optype);
  }

  /**
   * Clients should not overload this function.
   */
  Future<Null> computeSuggestionsForClass(
    CompletionRequest request,
    CompletionCollector collector,
    ClassElement classElement, {
    AstNode entryPoint,
    bool skipChildClass,
    CompletionTarget target,
    OpType optype,
  }) async {
    target ??= new CompletionTarget.forOffset(
        request.result.unit, request.offset,
        entryPoint: entryPoint);
    optype ??= new OpType.forCompletion(target, request.offset);
    if (!optype.includeIdentifiers) {
      return;
    }
    if (classElement == null) {
      ClassDeclaration classDecl = _enclosingClass(target);
      if (classDecl == null || classDecl.element == null) {
        return;
      }
      classElement = resolutionMap.elementDeclaredByClassDeclaration(classDecl);
    }
    containingLibrary = request.result.libraryElement;
    _computeSuggestionsForClass2(collector, target, classElement, optype,
        skipChildClass: skipChildClass);
  }

  _addSuggestionsForType(InterfaceType type, OpType optype,
      {bool isFunctionalArgument: false}) {
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

  void _computeSuggestionsForClass2(CompletionCollector collector,
      CompletionTarget target, ClassElement classElement, OpType optype,
      {bool skipChildClass: true}) {
    bool isFunctionalArgument = target.isFunctionalArgument();
    kind = isFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : CompletionSuggestionKind.INVOCATION;

    if (!skipChildClass) {
      _addSuggestionsForType(classElement.type, optype,
          isFunctionalArgument: isFunctionalArgument);
    }

    for (InterfaceType type in classElement.allSupertypes) {
      _addSuggestionsForType(type, optype,
          isFunctionalArgument: isFunctionalArgument);
    }
    for (CompletionSuggestion suggestion in suggestions) {
      collector.addSuggestion(suggestion);
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
}
