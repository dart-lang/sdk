// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

/// A contributor that produces suggestions based on the instance members from
/// the supertypes of a given type. More concretely, this class produces
/// suggestions for places where an inherited instance member might be invoked
/// via an implicit target of `this`.
class InheritedReferenceContributor extends DartCompletionContributor {
  /// The builder used to build the suggestions.
  MemberSuggestionBuilder builder;

  /// The kind of suggestion to make.
  CompletionSuggestionKind kind;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    if (!request.includeIdentifiers) {
      return const <CompletionSuggestion>[];
    }

    var member = _enclosingMember(request.target);
    if (member == null) {
      return const <CompletionSuggestion>[];
    }
    var classOrMixin = member.parent;
    if (classOrMixin is ClassOrMixinDeclaration &&
        classOrMixin.declaredElement != null) {
      builder = MemberSuggestionBuilder(request);
      return _computeSuggestionsForClass(classOrMixin.declaredElement, request);
    }
    return const <CompletionSuggestion>[];
  }

  void _addSuggestionsForType(InterfaceType type, DartCompletionRequest request,
      double inheritanceDistance,
      {bool isFunctionalArgument = false}) {
    var opType = request.opType;
    if (!isFunctionalArgument) {
      for (var accessor in type.accessors) {
        if (accessor.isGetter) {
          if (opType.includeReturnValueSuggestions) {
            builder.addSuggestionForAccessor(
                accessor: accessor, inheritanceDistance: inheritanceDistance);
          }
        } else {
          if (opType.includeVoidReturnSuggestions) {
            builder.addSuggestionForAccessor(
                accessor: accessor, inheritanceDistance: inheritanceDistance);
          }
        }
      }
    }
    for (var method in type.methods) {
      if (method.returnType == null) {
        builder.addSuggestionForMethod(
            method: method,
            inheritanceDistance: inheritanceDistance,
            kind: kind);
      } else if (!method.returnType.isVoid) {
        if (opType.includeReturnValueSuggestions) {
          builder.addSuggestionForMethod(
              method: method,
              inheritanceDistance: inheritanceDistance,
              kind: kind);
        }
      } else {
        if (opType.includeVoidReturnSuggestions) {
          var suggestion = builder.addSuggestionForMethod(
              method: method,
              inheritanceDistance: inheritanceDistance,
              kind: kind);
          _updateFlutterSuggestions(request, method, suggestion);
        }
      }
    }
  }

  List<CompletionSuggestion> _computeSuggestionsForClass(
      ClassElement classElement, DartCompletionRequest request) {
    var isFunctionalArgument = request.target.isFunctionalArgument();
    kind = isFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : CompletionSuggestionKind.INVOCATION;
    for (var type in classElement.allSupertypes) {
      double inheritanceDistance;
      if (request.useNewRelevance) {
        inheritanceDistance = request.featureComputer
            .inheritanceDistanceFeature(classElement, type.element);
      }
      _addSuggestionsForType(type, request, inheritanceDistance,
          isFunctionalArgument: isFunctionalArgument);
    }
    return builder.suggestions.toList();
  }

  /// Return the class member containing the target or `null` if the target is
  /// in a static method or static field or not in a class member.
  ClassMember _enclosingMember(CompletionTarget target) {
    var node = target.containingNode;
    while (node != null) {
      if (node is MethodDeclaration) {
        if (!node.isStatic) {
          return node;
        }
      } else if (node is FieldDeclaration) {
        if (!node.isStatic) {
          return node;
        }
      }
      node = node.parent;
    }
    return null;
  }

  void _updateFlutterSuggestions(DartCompletionRequest request, Element element,
      CompletionSuggestion suggestion) {
    if (suggestion == null) {
      return;
    }
    if (element is MethodElement &&
        element.name == 'setState' &&
        Flutter.of(request.result).isExactState(element.enclosingElement)) {
      // Find the line indentation.
      var indent = getRequestLineIndent(request);

      // Let the user know that we are going to insert a complete statement.
      suggestion.displayText = 'setState(() {});';

      // Build the completion and the selection offset.
      var buffer = StringBuffer();
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
