// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

/// A contributor that produces suggestions for variable names based on the
/// static type of the variable.
class VariableNameContributor extends DartCompletionContributor {
  @override
  Future<void> computeSuggestions(
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
        return;
      }

      var doIncludePrivateVersion =
          opType.inFieldDeclaration || opType.inTopLevelVariableDeclaration;

      var variableNameSuggestions = getCamelWordCombinations(strName);
      variableNameSuggestions.remove(strName);
      for (var varName in variableNameSuggestions) {
        _createNameSuggestion(builder, varName);
        if (doIncludePrivateVersion) {
          _createNameSuggestion(builder, '_' + varName);
        }
      }
    }
  }

  /// Given some [name], add a suggestion with the name (unless the name is
  /// `null` or empty).
  void _createNameSuggestion(SuggestionBuilder builder, String name) {
    if (name != null && name.isNotEmpty) {
      builder.suggestName(name);
    }
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
