// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/scanner/token.dart' show Token;
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:kernel/ast.dart';

import '../builder/ast_factory.dart';
import 'kernel_shadow_ast.dart';

/// Concrete implementation of [builder.AstFactory] for building a kernel AST.
class KernelAstFactory implements AstFactory<VariableDeclaration> {
  @override
  Arguments arguments(List<Expression> positional,
      {List<DartType> types, List<NamedExpression> named}) {
    return new KernelArguments(positional, types: types, named: named);
  }

  @override
  AsExpression asExpression(Expression operand, Token operator, DartType type) {
    return new KernelAsExpression(operand, type)
      ..fileOffset = offsetForToken(operator);
  }

  @override
  AwaitExpression awaitExpression(Token keyword, Expression operand) {
    return new KernelAwaitExpression(operand)
      ..fileOffset = offsetForToken(keyword);
  }

  @override
  KernelBlock block(List<Statement> statements, Token beginToken) {
    return new KernelBlock(statements)..fileOffset = offsetForToken(beginToken);
  }

  @override
  KernelBoolLiteral boolLiteral(bool value, Token token) {
    return new KernelBoolLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  ConditionalExpression conditionalExpression(Expression condition,
      Expression thenExpression, Expression elseExpression) {
    return new KernelConditionalExpression(
        condition, thenExpression, elseExpression);
  }

  @override
  ConstructorInvocation constructorInvocation(
      Constructor target, Arguments arguments,
      {bool isConst: false}) {
    return new KernelConstructorInvocation(target, arguments, isConst: isConst);
  }

  @override
  DirectMethodInvocation directMethodInvocation(
      Expression receiver, Procedure target, Arguments arguments) {
    return new KernelDirectMethodInvocation(receiver, target, arguments);
  }

  @override
  DirectPropertyGet directPropertyGet(Expression receiver, Member target) {
    return new KernelDirectPropertyGet(receiver, target);
  }

  @override
  DirectPropertySet directPropertySet(
      Expression receiver, Member target, Expression value) {
    return new KernelDirectPropertySet(receiver, target, value);
  }

  @override
  KernelDoubleLiteral doubleLiteral(double value, Token token) {
    return new KernelDoubleLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  ExpressionStatement expressionStatement(Expression expression) {
    return new KernelExpressionStatement(expression);
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
  KernelIntLiteral intLiteral(int value, Token token) {
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
  LogicalExpression logicalExpression(
      Expression left, String operator, Expression right) {
    return new KernelLogicalExpression(left, operator, right);
  }

  @override
  MapLiteral mapLiteral(
      Token beginToken, Token constKeyword, List<MapEntry> entries,
      {DartType keyType: const DynamicType(),
      DartType valueType: const DynamicType()}) {
    return new KernelMapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: constKeyword != null)
      ..fileOffset = constKeyword?.charOffset ?? offsetForToken(beginToken);
  }

  @override
  MethodInvocation methodInvocation(
      Expression receiver, Name name, Arguments arguments,
      [Procedure interfaceTarget]) {
    return new KernelMethodInvocation(receiver, name, arguments);
  }

  @override
  Not not(Token token, Expression operand) {
    return new KernelNot(operand)..fileOffset = offsetForToken(token);
  }

  @override
  KernelNullLiteral nullLiteral(Token token) {
    return new KernelNullLiteral()..fileOffset = offsetForToken(token);
  }

  @override
  PropertyGet propertyGet(Expression receiver, Name name,
      [Member interfaceTarget]) {
    return new KernelPropertyGet(receiver, name, interfaceTarget);
  }

  @override
  PropertySet propertySet(Expression receiver, Name name, Expression value,
      [Member interfaceTarget]) {
    return new KernelPropertySet(receiver, name, value, interfaceTarget);
  }

  @override
  Rethrow rethrowExpression(Token keyword) {
    return new KernelRethrow()..fileOffset = offsetForToken(keyword);
  }

  @override
  KernelReturnStatement returnStatement(Expression expression, Token token) {
    return new KernelReturnStatement(expression)
      ..fileOffset = offsetForToken(token);
  }

  @override
  void setExplicitArgumentTypes(Arguments arguments, List<DartType> types) {
    KernelArguments.setExplicitArgumentTypes(arguments, types);
  }

  @override
  StaticGet staticGet(Member readTarget, Token token) {
    return new KernelStaticGet(readTarget)..fileOffset = offsetForToken(token);
  }

  @override
  StaticInvocation staticInvocation(Procedure target, Arguments arguments,
      {bool isConst: false}) {
    if (target.kind == ProcedureKind.Factory) {
      return new KernelFactoryConstructorInvocation(target, arguments,
          isConst: isConst);
    }
    return new KernelStaticInvocation(target, arguments, isConst: isConst);
  }

  @override
  StringConcatenation stringConcatenation(
      List<Expression> expressions, Token token) {
    return new KernelStringConcatenation(expressions)
      ..fileOffset = offsetForToken(token);
  }

  @override
  StringLiteral stringLiteral(String value, Token token) {
    return new KernelStringLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  SuperMethodInvocation superMethodInvocation(
      Token beginToken, Name name, Arguments arguments,
      [Procedure interfaceTarget]) {
    return new KernelSuperMethodInvocation(name, arguments, interfaceTarget);
  }

  @override
  SuperPropertyGet superPropertyGet(Name name, [Member interfaceTarget]) {
    return new KernelSuperPropertyGet(name, interfaceTarget);
  }

  @override
  SymbolLiteral symbolLiteral(Token hashToken, String value) {
    return new KernelSymbolLiteral(value)
      ..fileOffset = offsetForToken(hashToken);
  }

  @override
  ThisExpression thisExpression(Token keyword) {
    return new KernelThisExpression()..fileOffset = offsetForToken(keyword);
  }

  @override
  Throw throwExpression(Token keyword, Expression expression) {
    return new KernelThrow(expression)..fileOffset = offsetForToken(keyword);
  }

  @override
  TypeLiteral typeLiteral(DartType type) {
    return new KernelTypeLiteral(type);
  }

  @override
  VariableDeclaration variableDeclaration(
      String name, Token token, int functionNestingLevel,
      {DartType type,
      Expression initializer,
      Token equalsToken,
      bool isFinal: false,
      bool isConst: false,
      bool isLocalFunction: false}) {
    return new KernelVariableDeclaration(name, functionNestingLevel,
        type: type,
        initializer: initializer,
        isFinal: isFinal,
        isConst: isConst,
        isLocalFunction: isLocalFunction)
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

  @override
  VariableSet variableSet(VariableDeclaration variable, Expression value) {
    return new KernelVariableSet(variable, value);
  }
}
