// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A contributor that produces suggestions for field formal parameters that are
/// based on the fields declared directly by the enclosing class that are not
/// already initialized. More concretely, this class produces suggestions for
/// expressions of the form `this.^` in a constructor's parameter list.
class FieldFormalContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    var node = request.target.containingNode;
    if (node is! FieldFormalParameter) {
      return const <CompletionSuggestion>[];
    }

    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return const <CompletionSuggestion>[];
    }

    // Compute the list of fields already referenced in the constructor.
    var referencedFields = <String>[];
    for (var param in constructor.parameters.parameters) {
      if (param is DefaultFormalParameter &&
          param.parameter is FieldFormalParameter) {
        param = (param as DefaultFormalParameter).parameter;
      }
      if (param is FieldFormalParameter) {
        var fieldId = param.identifier;
        if (fieldId != null && fieldId != request.target.entity) {
          var fieldName = fieldId.name;
          if (fieldName != null && fieldName.isNotEmpty) {
            referencedFields.add(fieldName);
          }
        }
      }
    }

    var enclosingClass = constructor.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) {
      return const <CompletionSuggestion>[];
    }

    // Add suggestions for fields that are not already referenced.
    var relevance = request.useNewRelevance
        ? Relevance.fieldFormalParameter
        : DART_RELEVANCE_LOCAL_FIELD;
    var suggestions = <CompletionSuggestion>[];
    for (var member in enclosingClass.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (var variable in member.fields.variables) {
          var fieldId = variable.name;
          if (fieldId != null) {
            var fieldName = fieldId.name;
            if (fieldName != null && fieldName.isNotEmpty) {
              if (!referencedFields.contains(fieldName)) {
                var suggestion = createSuggestion(
                    request, fieldId.staticElement,
                    relevance: relevance);
                if (suggestion != null) {
                  suggestions.add(suggestion);
                }
              }
            }
          }
        }
      }
    }
    return suggestions;
  }
}
