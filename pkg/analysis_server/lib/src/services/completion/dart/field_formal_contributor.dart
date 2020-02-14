// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A contributor for calculating invocation / access suggestions
/// `completion.getSuggestions` request results.
class FieldFormalContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    AstNode node = request.target.containingNode;
    if (node is! FieldFormalParameter) {
      return const <CompletionSuggestion>[];
    }

    ConstructorDeclaration constructor = node.thisOrAncestorOfType();
    if (constructor == null) {
      return const <CompletionSuggestion>[];
    }

    // Compute the list of fields already referenced in the constructor
    List<String> referencedFields = <String>[];
    for (FormalParameter param in constructor.parameters.parameters) {
      if (param is DefaultFormalParameter &&
          param.parameter is FieldFormalParameter) {
        param = (param as DefaultFormalParameter).parameter;
      }
      if (param is FieldFormalParameter) {
        SimpleIdentifier fieldId = param.identifier;
        if (fieldId != null && fieldId != request.target.entity) {
          String fieldName = fieldId.name;
          if (fieldName != null && fieldName.isNotEmpty) {
            referencedFields.add(fieldName);
          }
        }
      }
    }

    ClassDeclaration class_ = constructor.thisOrAncestorOfType();
    if (class_ == null) {
      return const <CompletionSuggestion>[];
    }

    // Add suggestions for fields that are not already referenced
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (ClassMember member in class_.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (VariableDeclaration varDecl in member.fields.variables) {
          SimpleIdentifier fieldId = varDecl.name;
          if (fieldId != null) {
            String fieldName = fieldId.name;
            if (fieldName != null && fieldName.isNotEmpty) {
              if (!referencedFields.contains(fieldName)) {
                CompletionSuggestion suggestion = createSuggestion(
                    fieldId.staticElement,
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
