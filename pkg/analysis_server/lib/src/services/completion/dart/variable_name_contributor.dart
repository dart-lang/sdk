// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.variableName;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';

CompletionSuggestion _createNameSuggestion(String name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  return new CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
      DART_RELEVANCE_DEFAULT, name, name.length, 0, false, false);
}

String _getStringName(Identifier id) {
  if (id == null) {
    return null;
  }
  if (id is SimpleIdentifier) {
    return id.name;
  } else if (id is PrefixedIdentifier) {
    return id.identifier.name;
  }
  return id.name;
}

/**
 * A contributor for calculating suggestions for variable names.
 */
class VariableNameContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    OpType optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    if (optype.includeVarNameSuggestions) {
      // Resolution not needed for this completion

      AstNode node = request.target.containingNode;
      String strName = null;
      if (node is ExpressionStatement) {
        if (node.expression is Identifier) {
          strName = _getStringName(node.expression as Identifier);
        }
      } else if (node is VariableDeclarationList) {
        TypeAnnotation typeAnnotation = node.type;
        if (typeAnnotation is TypeName) {
          strName = _getStringName(typeAnnotation.name);
        }
      } else if (node is TopLevelVariableDeclaration) {
        // The parser parses 'Foo ' and 'Foo ;' differently, resulting in the
        // following.
        // 'Foo ': handled above
        // 'Foo ;': TopLevelVariableDeclaration with type null, and a first
        // variable of 'Foo'
        VariableDeclarationList varDeclarationList = node.variables;
        TypeAnnotation typeAnnotation = varDeclarationList.type;
        if (typeAnnotation != null) {
          if (typeAnnotation is TypeName) {
            strName = _getStringName(typeAnnotation.name);
          }
        } else {
          NodeList<VariableDeclaration> varDeclarations =
              varDeclarationList.variables;
          if (varDeclarations.length == 1) {
            VariableDeclaration varDeclaration = varDeclarations.first;
            strName = _getStringName(varDeclaration.name);
          }
        }
      }
      if (strName == null) {
        return EMPTY_LIST;
      }

      List<String> variableNameSuggestions = getCamelWordCombinations(strName);
      variableNameSuggestions.remove(strName);
      List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
      for (String varName in variableNameSuggestions) {
        CompletionSuggestion suggestion = _createNameSuggestion(varName);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      }
      return suggestions;
    }
    return EMPTY_LIST;
  }
}
