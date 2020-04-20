// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

/// A contributor that produces suggestions for variable names based on the
/// static type of the variable.
class VariableNameContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var opType = request.opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    if (opType.includeVarNameSuggestions) {
      // Resolution not needed for this completion.

      var node = request.target.containingNode;
      var offset = request.target.offset;

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
        var varDeclarationList = node.variables;
        var typeAnnotation = varDeclarationList.type;
        if (typeAnnotation != null) {
          var identifier = _typeAnnotationIdentifier(typeAnnotation);
          strName = _getStringName(identifier);
        } else {
          var varDeclarations = varDeclarationList.variables;
          if (varDeclarations.length == 1) {
            var declaration = varDeclarations.first;
            strName = _getStringName(declaration.name);
          }
        }
      }
      if (strName == null) {
        return const <CompletionSuggestion>[];
      }

      var doIncludePrivateVersion =
          opType.inFieldDeclaration || opType.inTopLevelVariableDeclaration;

      var variableNameSuggestions = getCamelWordCombinations(strName);
      variableNameSuggestions.remove(strName);
      var suggestions = <CompletionSuggestion>[];
      for (var varName in variableNameSuggestions) {
        var suggestion = _createNameSuggestion(request, varName);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
        if (doIncludePrivateVersion) {
          var privateSuggestion = _createNameSuggestion(request, '_' + varName);
          if (privateSuggestion != null) {
            suggestions.add(privateSuggestion);
          }
        }
      }
      return suggestions;
    }
    return const <CompletionSuggestion>[];
  }

  /// Given some [name], return a [CompletionSuggestion] with the name.
  ///
  /// If the passed name is `null` or empty, `null` is returned.
  CompletionSuggestion _createNameSuggestion(
      DartCompletionRequest request, String name) {
    if (name == null || name.isEmpty) {
      return null;
    }
    // TODO(brianwilkerson) Explore whether there are any features of the name
    //  that can be used to provide better relevance scores.
    return CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER,
        request.useNewRelevance ? 500 : DART_RELEVANCE_DEFAULT,
        name,
        name.length,
        0,
        false,
        false);
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
