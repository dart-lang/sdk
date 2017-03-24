// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.field_formal;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/**
 * A contributor for calculating invocation / access suggestions
 * `completion.getSuggestions` request results.
 */
class FieldFormalContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    AstNode node = request.target.containingNode;
    if (node is! FieldFormalParameter) {
      return EMPTY_LIST;
    }

    // If this is a constructor declaration
    // then compute fields already referenced
    ConstructorDeclaration constructorDecl =
        node.getAncestor((p) => p is ConstructorDeclaration);
    if (constructorDecl == null) {
      return EMPTY_LIST;
    }

    // Compute the list of fields already referenced in the constructor
    List<String> referencedFields = new List<String>();
    for (FormalParameter param in constructorDecl.parameters.parameters) {
      if (param is DefaultFormalParameter &&
          param.parameter is FieldFormalParameter) {
        param = (param as DefaultFormalParameter).parameter;
      }
      if (param is FieldFormalParameter) {
        SimpleIdentifier fieldId = param.identifier;
        if (fieldId != null && fieldId != request.target.entity) {
          String fieldName = fieldId.name;
          if (fieldName != null && fieldName.length > 0) {
            referencedFields.add(fieldName);
          }
        }
      }
    }

    // Add suggestions for fields that are not already referenced
    ClassDeclaration classDecl =
        constructorDecl.getAncestor((p) => p is ClassDeclaration);
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (ClassMember member in classDecl.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (VariableDeclaration varDecl in member.fields.variables) {
          SimpleIdentifier fieldId = varDecl.name;
          if (fieldId != null) {
            String fieldName = fieldId.name;
            if (fieldName != null && fieldName.length > 0) {
              if (!referencedFields.contains(fieldName)) {
                CompletionSuggestion suggestion = createSuggestion(
                    fieldId.bestElement, request.ideOptions,
                    relevance: DART_RELEVANCE_LOCAL_FIELD);
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
