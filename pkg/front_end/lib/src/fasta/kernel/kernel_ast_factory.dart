// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:kernel/ast.dart';

import '../builder/ast_factory.dart';
import 'kernel_shadow_ast.dart';

/// Concrete implementation of [builder.AstFactory] for building a kernel AST.
class KernelAstFactory implements AstFactory<VariableDeclaration> {
  @override
  KernelBlock block(List<Statement> statements, int charOffset) {
    return new KernelBlock(statements)..fileOffset = charOffset;
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
  FunctionExpression functionExpression(FunctionNode function, int charOffset) {
    return new KernelFunctionExpression(function)..fileOffset = charOffset;
  }

  @override
  Statement ifStatement(
      Expression condition, Statement thenPart, Statement elsePart) {
    return new KernelIfStatement(condition, thenPart, elsePart);
  }

  @override
  KernelIntLiteral intLiteral(value, int charOffset) {
    return new KernelIntLiteral(value)..fileOffset = charOffset;
  }

  @override
  Expression isExpression(
      Expression expression, DartType type, int charOffset, bool isInverted) {
    if (isInverted) {
      return new KernelIsNotExpression(expression, type, charOffset);
    } else {
      return new KernelIsExpression(expression, type)..fileOffset = charOffset;
    }
  }

  @override
  KernelListLiteral listLiteral(List<Expression> expressions,
      DartType typeArgument, bool isConst, int charOffset) {
    return new KernelListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = charOffset;
  }

  @override
  KernelNullLiteral nullLiteral(int charOffset) {
    return new KernelNullLiteral()..fileOffset = charOffset;
  }

  @override
  KernelReturnStatement returnStatement(Expression expression, int charOffset) {
    return new KernelReturnStatement(expression)..fileOffset = charOffset;
  }

  @override
  StaticGet staticGet(Member readTarget, int offset) {
    return new KernelStaticGet(readTarget)..fileOffset = offset;
  }

  @override
  VariableDeclaration variableDeclaration(
      String name, int charOffset, int functionNestingLevel,
      {DartType type,
      Expression initializer,
      int equalsCharOffset = TreeNode.noOffset,
      bool isFinal: false,
      bool isConst: false}) {
    return new KernelVariableDeclaration(name, functionNestingLevel,
        type: type,
        initializer: initializer,
        isFinal: isFinal,
        isConst: isConst)
      ..fileOffset = charOffset
      ..fileEqualsOffset = equalsCharOffset;
  }

  @override
  VariableGet variableGet(
      VariableDeclaration variable,
      TypePromotionFact<VariableDeclaration> fact,
      TypePromotionScope scope,
      int charOffset) {
    return new KernelVariableGet(variable, fact, scope)
      ..fileOffset = charOffset;
  }
}
