// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

/// Given some [String] name "foo", return a [CompletionSuggestion] with the
/// [String].
///
/// If the passed [String] is null or empty, null is returned.
CompletionSuggestion _createNameSuggestion(String name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  return CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
      DART_RELEVANCE_DEFAULT, name, name.length, 0, false, false);
}

/// Convert some [Identifier] to its [String] name.
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

/// A contributor for calculating suggestions for variable names.
class VariableNameContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    OpType optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    if (optype.includeVarNameSuggestions) {
      // Resolution not needed for this completion

      AstNode node = request.target.containingNode;
      int offset = request.target.offset;

      // Use the refined node.
      if (node is FormalParameterList) {
        node = CompletionTarget.findFormalParameter(node, offset);
      }

      String strName;
      if (node is ExpressionStatement) {
        var expression = node.expression;
        if (expression is Identifier) {
          strName = _getStringName(expression);
        }
      } else if (node is SimpleFormalParameter) {
        var identifier = _formalParameterTypeIdentifier(node);
        strName = _getStringName(identifier);
      } else if (node is VariableDeclarationList) {
        var identifier = _typeAnnotationIdentifier(node.type);
        strName = _getStringName(identifier);
      } else if (node is TopLevelVariableDeclaration) {
        // The parser parses 'Foo ' and 'Foo ;' differently, resulting in the
        // following.
        // 'Foo ': handled above
        // 'Foo ;': TopLevelVariableDeclaration with type null, and a first
        // variable of 'Foo'
        VariableDeclarationList varDeclarationList = node.variables;
        TypeAnnotation typeAnnotation = varDeclarationList.type;
        if (typeAnnotation != null) {
          var identifier = _typeAnnotationIdentifier(typeAnnotation);
          strName = _getStringName(identifier);
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
        return const <CompletionSuggestion>[];
      }

      var doIncludePrivateVersion =
          optype.inFieldDeclaration || optype.inTopLevelVariableDeclaration;

      List<String> variableNameSuggestions = getCamelWordCombinations(strName);
      variableNameSuggestions.remove(strName);
      List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
      for (String varName in variableNameSuggestions) {
        CompletionSuggestion suggestion = _createNameSuggestion(varName);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
        if (doIncludePrivateVersion) {
          CompletionSuggestion privateSuggestion =
              _createNameSuggestion('_' + varName);
          if (privateSuggestion != null) {
            suggestions.add(privateSuggestion);
          }
        }
      }
      return suggestions;
    }
    return const <CompletionSuggestion>[];
  }

  static Identifier _formalParameterTypeIdentifier(FormalParameter node) {
    if (node is SimpleFormalParameter) {
      var type = node.type;
      if (type != null) {
        return _typeAnnotationIdentifier(type);
      }
      return node.identifier;
    }
    return null;
  }

  static Identifier _typeAnnotationIdentifier(TypeAnnotation type) {
    if (type is TypeName) {
      return type.name;
    }
    return null;
  }
}
