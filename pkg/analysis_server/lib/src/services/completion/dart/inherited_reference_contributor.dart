// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/flutter.dart' as flutter;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

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

  _addSuggestionsForType(InterfaceType type, DartCompletionRequest request,
      {bool isFunctionalArgument: false}) {
    OpType opType = request.opType;
    if (!isFunctionalArgument) {
      for (PropertyAccessorElement elem in type.accessors) {
        if (elem.isGetter) {
          if (opType.includeReturnValueSuggestions) {
            addSuggestion(elem);
          }
        } else {
          if (opType.includeVoidReturnSuggestions) {
            addSuggestion(elem);
          }
        }
      }
    }
    for (MethodElement elem in type.methods) {
      if (elem.returnType == null) {
        addSuggestion(elem);
      } else if (!elem.returnType.isVoid) {
        if (opType.includeReturnValueSuggestions) {
          addSuggestion(elem);
        }
      } else {
        if (opType.includeVoidReturnSuggestions) {
          CompletionSuggestion suggestion = addSuggestion(elem);
          _updateFlutterSuggestions(request, elem, suggestion);
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
    if (!skipChildClass) {
      _addSuggestionsForType(classElement.type, request,
          isFunctionalArgument: isFunctionalArgument);
    }

    for (InterfaceType type in classElement.allSupertypes) {
      _addSuggestionsForType(type, request,
          isFunctionalArgument: isFunctionalArgument);
    }
    return suggestions;
  }

  void _updateFlutterSuggestions(DartCompletionRequest request, Element element,
      CompletionSuggestion suggestion) {
    if (suggestion == null) {
      return;
    }
    if (element is MethodElement &&
        element.name == 'setState' &&
        flutter.isExactState(element.enclosingElement)) {
      // Find the line indentation.
      String content = request.result.content;
      int lineStartOffset = request.offset;
      int notWhitespaceOffset = request.offset;
      for (; lineStartOffset > 0; lineStartOffset--) {
        var char = content.substring(lineStartOffset - 1, lineStartOffset);
        if (char == '\n') {
          break;
        }
        if (char != ' ' && char != '\t') {
          notWhitespaceOffset = lineStartOffset - 1;
        }
      }
      String indent = content.substring(lineStartOffset, notWhitespaceOffset);

      // Let the user know that we are going to insert a complete statement.
      suggestion.displayText = 'setState(() {});';

      // Build the completion and the selection offset.
      var buffer = new StringBuffer();
      buffer.writeln('setState(() {');
      buffer.write('$indent  ');
      suggestion.selectionOffset = buffer.length;
      buffer.writeln();
      buffer.write('$indent});');
      suggestion.completion = buffer.toString();

      // There are no arguments to fill.
      suggestion.parameterNames = null;
      suggestion.parameterTypes = null;
      suggestion.requiredParameterCount = null;
      suggestion.hasNamedParameters = null;
    }
  }
}
