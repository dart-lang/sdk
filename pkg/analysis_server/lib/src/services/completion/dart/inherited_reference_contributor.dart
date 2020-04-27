// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
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
  MemberSuggestionBuilder memberBuilder;

  /// The kind of suggestion to make.
  CompletionSuggestionKind kind;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
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
      memberBuilder = MemberSuggestionBuilder(request, builder);
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
            memberBuilder.addSuggestionForAccessor(
                accessor: accessor, inheritanceDistance: inheritanceDistance);
          }
        } else {
          if (opType.includeVoidReturnSuggestions) {
            memberBuilder.addSuggestionForAccessor(
                accessor: accessor, inheritanceDistance: inheritanceDistance);
          }
        }
      }
    }
    for (var method in type.methods) {
      if (method.returnType == null) {
        memberBuilder.addSuggestionForMethod(
            method: method,
            inheritanceDistance: inheritanceDistance,
            kind: kind);
      } else if (!method.returnType.isVoid) {
        if (opType.includeReturnValueSuggestions) {
          memberBuilder.addSuggestionForMethod(
              method: method,
              inheritanceDistance: inheritanceDistance,
              kind: kind);
        }
      } else {
        if (opType.includeVoidReturnSuggestions) {
          memberBuilder.addSuggestionForMethod(
              method: method,
              inheritanceDistance: inheritanceDistance,
              kind: kind);
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
    return memberBuilder.suggestions.toList();
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
      } else if (node is ConstructorDeclaration) {
        return node;
      }
      node = node.parent;
    }
    return null;
  }
}
