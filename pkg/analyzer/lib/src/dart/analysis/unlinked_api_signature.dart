// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/summary/api_signature.dart';

/// Return the bytes of the unlinked API signature of the given [unit].
///
/// If API signatures of two units are different, they may have different APIs.
List<int> computeUnlinkedApiSignature(CompilationUnit unit) {
  var computer = _UnitApiSignatureComputer();
  computer.compute(unit);
  return computer.signature.toByteList();
}

class _UnitApiSignatureComputer {
  final ApiSignature signature = ApiSignature();

  void addClassOrMixin(ClassOrMixinDeclaration node) {
    addTokens(node.beginToken, node.leftBracket);

    bool hasConstConstructor = node.members
        .any((m) => m is ConstructorDeclaration && m.constKeyword != null);

    signature.addInt(node.members.length);
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        addTokens(member.beginToken, member.parameters.endToken);
        if (member.constKeyword != null) {
          addNodeList(member.initializers);
        }
        addNode(member.redirectedConstructor);
      } else if (member is FieldDeclaration) {
        var variableList = member.fields;
        addVariables(
          member,
          variableList,
          !member.isStatic && variableList.isFinal && hasConstConstructor,
        );
      } else if (member is MethodDeclaration) {
        addTokens(
          member.beginToken,
          (member.parameters ?? member.name).endToken,
        );
        signature.addBool(member.body is EmptyFunctionBody);
        addFunctionBodyModifiers(member.body);
      } else {
        addNode(member);
      }
    }

    addToken(node.rightBracket);
  }

  void addFunctionBodyModifiers(FunctionBody node) {
    signature.addBool(node.isSynchronous);
    signature.addBool(node.isGenerator);
  }

  void addNode(AstNode node) {
    if (node != null) {
      addTokens(node.beginToken, node.endToken);
    }
  }

  void addNodeList(List<AstNode> nodes) {
    for (var node in nodes) {
      addNode(node);
    }
  }

  void addToken(Token token) {
    signature.addString(token.lexeme);
  }

  /// Appends tokens from [begin] (including), to [end] (also including).
  void addTokens(Token begin, Token end) {
    if (begin is CommentToken) {
      begin = (begin as CommentToken).parent;
    }

    Token token = begin;
    while (token != null) {
      addToken(token);

      if (token == end) {
        break;
      }

      var nextToken = token.next;

      // Stop if EOF.
      if (nextToken == token) {
        break;
      }

      token = nextToken;
    }
  }

  void addVariables(
    AstNode node,
    VariableDeclarationList variableList,
    bool includeInitializers,
  ) {
    if (variableList.type == null ||
        variableList.isConst ||
        includeInitializers) {
      addTokens(node.beginToken, node.endToken);
    } else {
      addTokens(node.beginToken, variableList.type.endToken);

      signature.addInt(variableList.variables.length);
      for (var variable in variableList.variables) {
        addTokens(variable.beginToken, variable.name.endToken);
        signature.addBool(variable.initializer != null);
        addToken(variable.endToken.next); // `,` or `;`
      }
    }
  }

  void compute(CompilationUnit unit) {
    signature.addFeatureSet(unit.featureSet);

    signature.addInt(unit.directives.length);
    unit.directives.forEach(addNode);

    signature.addInt(unit.declarations.length);
    for (var declaration in unit.declarations) {
      if (declaration is ClassOrMixinDeclaration) {
        addClassOrMixin(declaration);
      } else if (declaration is FunctionDeclaration) {
        var functionExpression = declaration.functionExpression;
        addTokens(
          declaration.beginToken,
          (functionExpression.parameters ?? declaration.name).endToken,
        );
        addFunctionBodyModifiers(functionExpression.body);
      } else if (declaration is TopLevelVariableDeclaration) {
        addVariables(declaration, declaration.variables, false);
      } else {
        addNode(declaration);
      }
    }
  }
}
