// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart' show Catch, DartType, FunctionType, Node;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'factory.dart' show Factory;

import 'kernel_shadow_ast.dart'
    show ExpressionJudgment, InitializerJudgment, StatementJudgment;

/// Implementation of [Factory] for use during top level type inference, when
/// no representation of the code semantics needs to be created (only the type
/// needs to be inferred).
class ToplevelInferenceFactory implements Factory<void, void, void, void> {
  const ToplevelInferenceFactory();

  @override
  void asExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void expression,
      Token asOperator,
      void literalType,
      DartType inferredType) {}

  @override
  void assertInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis) {}

  @override
  void assertStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis,
      Token semicolon) {}

  @override
  void awaitExpression(ExpressionJudgment judgment, int fileOffset,
      Token awaitKeyword, void expression, DartType inferredType) {}

  @override
  void block(StatementJudgment judgment, int fileOffset, Token leftBracket,
      void statements, Token rightBracket) {}

  @override
  void boolLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      DartType inferredType) {}

  @override
  void breakStatement(StatementJudgment judgment, int fileOffset,
      Token breakKeyword, void label, Token semicolon) {}

  @override
  void cascadeExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  Object catchStatement(
      Catch judgment,
      int fileOffset,
      DartType guardType,
      int exceptionOffset,
      DartType exceptionType,
      int stackTraceOffset,
      DartType stackTraceType) {
    return judgment;
  }

  @override
  void conditionalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void condition,
      Token question,
      void thenExpression,
      Token colon,
      void elseExpression,
      DartType inferredType) {}

  @override
  void constructorInvocation(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType) {}

  @override
  void continueSwitchStatement(StatementJudgment judgment, int fileOffset) {}

  @override
  void deferredCheck(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void doStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token doKeyword,
      void body,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      Token semicolon) {}

  @override
  void doubleLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      DartType inferredType) {}

  @override
  void expressionStatement(StatementJudgment judgment, int fileOffset,
      void expression, Token semicolon) {}

  @override
  void fieldInitializer(
      InitializerJudgment judgment, int fileOffset, Node initializerField) {}

  @override
  void forInStatement(
      StatementJudgment judgment,
      int fileOffset,
      int variableOffset,
      DartType variableType,
      int writeOffset,
      DartType writeVariableType,
      int writeVariableDeclarationOffset,
      Node writeTarget) {}

  @override
  void forStatement(StatementJudgment judgment, int fileOffset) {}

  @override
  void functionDeclaration(
      StatementJudgment judgment, int fileOffset, FunctionType inferredType) {}

  @override
  void functionExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void ifNull(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void ifStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token ifKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void thenStatement,
      Token elseKeyword,
      void elseStatement) {}

  @override
  void indexAssign(ExpressionJudgment judgment, int fileOffset,
      Node writeMember, Node combiner, DartType inferredType) {}

  @override
  void intLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      DartType inferredType) {}

  @override
  void invalidInitializer(InitializerJudgment judgment, int fileOffset) {}

  @override
  void isExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void expression,
      Token isOperator,
      void literalType,
      DartType testedType,
      DartType inferredType) {}

  @override
  void isNotExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void expression,
      Token isOperator,
      Token notOperator,
      void literalType,
      DartType testedType,
      DartType inferredType) {}

  @override
  void labeledStatement(StatementJudgment judgment, int fileOffset) {}

  @override
  void listLiteral(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void logicalExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void mapLiteral(
      ExpressionJudgment judgment, int fileOffset, DartType typeContext) {}

  @override
  void methodInvocation(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Node interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void methodInvocationCall(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void namedFunctionExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void not(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void nullLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      bool isSynthetic, DartType inferredType) {}

  @override
  void propertyAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {}

  @override
  void propertyGet(ExpressionJudgment judgment, int fileOffset, Node member,
      DartType inferredType) {}

  @override
  void propertyGetCall(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void propertySet(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void redirectingInitializer(
      InitializerJudgment judgment, int fileOffset, Node initializerTarget) {}

  @override
  void rethrow_(ExpressionJudgment judgment, int fileOffset,
      Token rethrowKeyword, DartType inferredType) {}

  @override
  void returnStatement(StatementJudgment judgment, int fileOffset,
      Token returnKeyword, void expression, Token semicolon) {}

  @override
  void staticAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {}

  @override
  void staticGet(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType) {}

  @override
  void staticInvocation(
      ExpressionJudgment judgment,
      int fileOffset,
      Node expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void storeClassReference(int fileOffset, Node reference, DartType rawType) {}

  @override
  void storePrefixInfo(int fileOffset, int prefixImportIndex) {}

  @override
  void stringConcatenation(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void stringLiteral(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void superInitializer(InitializerJudgment judgment, int fileOffset) {}

  @override
  void switchStatement(StatementJudgment judgment, int fileOffset) {}

  @override
  void symbolLiteral(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void thisExpression(ExpressionJudgment judgment, int fileOffset,
      Token thisKeyword, DartType inferredType) {}

  @override
  void throw_(ExpressionJudgment judgment, int fileOffset, Token throwKeyword,
      void expression, DartType inferredType) {}

  @override
  void tryCatch(StatementJudgment judgment, int fileOffset) {}

  @override
  void tryFinally(StatementJudgment judgment, int fileOffset) {}

  @override
  void typeLiteral(ExpressionJudgment judgment, int fileOffset,
      Node expressionType, DartType inferredType) {}

  @override
  void variableAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      DartType writeContext,
      int writeVariableDeclarationOffset,
      Node combiner,
      DartType inferredType) {}

  @override
  void variableDeclaration(StatementJudgment judgment, int fileOffset,
      DartType statementType, DartType inferredType) {}

  @override
  void variableGet(
      ExpressionJudgment judgment,
      int fileOffset,
      bool isInCascade,
      int expressionVariableDeclarationOffset,
      DartType inferredType) {}

  @override
  void variableSet(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void whileStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void body) {}

  @override
  void yieldStatement(StatementJudgment judgment, int fileOffset,
      Token yieldKeyword, Token star, void expression, Token semicolon) {}
}

const toplevelInferenceFactory = const ToplevelInferenceFactory();
