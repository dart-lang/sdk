// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/scanner/token.dart' show Token;
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:kernel/ast.dart';

import '../builder/ast_factory.dart';
import 'kernel_shadow_ast.dart';

/// Concrete implementation of [builder.AstFactory] for building a kernel AST.
class KernelAstFactory implements AstFactory<VariableDeclaration> {
  @override
  KernelBlock block(List<Statement> statements, Token beginToken) {
    return new KernelBlock(statements)..fileOffset = offsetForToken(beginToken);
  }

  @override
  ExpressionStatement expressionStatement(Expression expression) {
    return new KernelExpressionStatement(expression);
  }

  @override
  Field field(Name name, int charOffset, {String fileUri}) {
    return new KernelField(name, fileUri: fileUri)..fileOffset = charOffset;
  }

  @override
  FunctionExpression functionExpression(FunctionNode function, Token token) {
    return new KernelFunctionExpression(function)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Statement ifStatement(
      Expression condition, Statement thenPart, Statement elsePart) {
    return new KernelIfStatement(condition, thenPart, elsePart);
  }

  @override
  KernelIntLiteral intLiteral(value, Token token) {
    return new KernelIntLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  Expression isExpression(
      Expression expression, DartType type, Token token, bool isInverted) {
    if (isInverted) {
      return new KernelIsNotExpression(expression, type, offsetForToken(token));
    } else {
      return new KernelIsExpression(expression, type)
        ..fileOffset = offsetForToken(token);
    }
  }

  @override
  KernelListLiteral listLiteral(List<Expression> expressions,
      DartType typeArgument, bool isConst, Token token) {
    return new KernelListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offsetForToken(token);
  }

  @override
  KernelNullLiteral nullLiteral(Token token) {
    return new KernelNullLiteral()..fileOffset = offsetForToken(token);
  }

  @override
  KernelReturnStatement returnStatement(Expression expression, Token token) {
    return new KernelReturnStatement(expression)
      ..fileOffset = offsetForToken(token);
  }

  @override
  StaticGet staticGet(Member readTarget, Token token) {
    return new KernelStaticGet(readTarget)..fileOffset = offsetForToken(token);
  }

  @override
  VariableDeclaration variableDeclaration(
      String name, Token token, int functionNestingLevel,
      {DartType type,
      Expression initializer,
      Token equalsToken,
      bool isFinal: false,
      bool isConst: false}) {
    return new KernelVariableDeclaration(name, functionNestingLevel,
        type: type,
        initializer: initializer,
        isFinal: isFinal,
        isConst: isConst)
      ..fileOffset = offsetForToken(token)
      ..fileEqualsOffset = offsetForToken(equalsToken);
  }

  @override
  VariableGet variableGet(
      VariableDeclaration variable,
      TypePromotionFact<VariableDeclaration> fact,
      TypePromotionScope scope,
      Token token) {
    return new KernelVariableGet(variable, fact, scope)
      ..fileOffset = offsetForToken(token);
  }
}
