// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart' show Catch, DartType, FunctionType, Node;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'kernel_shadow_ast.dart'
    show ExpressionJudgment, InitializerJudgment, StatementJudgment;

/// Abstract base class for factories that can construct trees of expressions,
/// statements, initializers, and literal types based on tokens, inferred types,
/// and invocation targets.
abstract class Factory<Expression, Statement, Initializer, Type> {
  Expression asExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token asOperator,
      Type literalType,
      DartType inferredType);

  Initializer assertInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis);

  Statement assertStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis,
      Token semicolon);

  Expression awaitExpression(ExpressionJudgment judgment, int fileOffset,
      Token awaitKeyword, Expression expression, DartType inferredType);

  Statement block(StatementJudgment judgment, int fileOffset, Token leftBracket,
      List<Statement> statements, Token rightBracket);

  Expression boolLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, bool value, DartType inferredType);

  Statement breakStatement(StatementJudgment judgment, int fileOffset,
      Token breakKeyword, Expression label, Token semicolon);

  Expression cascadeExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Object catchStatement(
      Catch judgment,
      int fileOffset,
      DartType guardType,
      int exceptionOffset,
      DartType exceptionType,
      int stackTraceOffset,
      DartType stackTraceType);

  Expression conditionalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression condition,
      Token question,
      Expression thenExpression,
      Token colon,
      Expression elseExpression,
      DartType inferredType);

  Expression constructorInvocation(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType);

  Statement continueStatement(StatementJudgment judgment, int fileOffset,
      Token continueKeyword, Expression label, Token semicolon);

  Statement continueSwitchStatement(StatementJudgment judgment, int fileOffset,
      Token continueKeyword, Expression label, Token semicolon);

  Expression deferredCheck(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Statement doStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token doKeyword,
      Statement body,
      Token whileKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Token semicolon);

  Expression doubleLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, double value, DartType inferredType);

  Statement expressionStatement(StatementJudgment judgment, int fileOffset,
      Expression expression, Token semicolon);

  Initializer fieldInitializer(
      InitializerJudgment judgment, int fileOffset, Node initializerField);

  Statement forInStatement(
      StatementJudgment judgment,
      int fileOffset,
      int variableOffset,
      DartType variableType,
      int writeOffset,
      DartType writeVariableType,
      int writeVariableDeclarationOffset,
      Node writeTarget);

  Statement forStatement(StatementJudgment judgment, int fileOffset);

  Statement functionDeclaration(
      StatementJudgment judgment, int fileOffset, FunctionType inferredType);

  Expression functionExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Expression ifNull(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression leftOperand,
      Token operator,
      Expression rightOperand,
      DartType inferredType);

  Statement ifStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token ifKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Statement thenStatement,
      Token elseKeyword,
      Statement elseStatement);

  Expression indexAssign(ExpressionJudgment judgment, int fileOffset,
      Node writeMember, Node combiner, DartType inferredType);

  Expression intLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, num value, DartType inferredType);

  Initializer invalidInitializer(InitializerJudgment judgment, int fileOffset);

  Expression isExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token isOperator,
      Type literalType,
      DartType testedType,
      DartType inferredType);

  Expression isNotExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token isOperator,
      Token notOperator,
      Type literalType,
      DartType testedType,
      DartType inferredType);

  Statement labeledStatement(StatementJudgment judgment, int fileOffset);

  Expression listLiteral(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Expression logicalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression leftOperand,
      Token operator,
      Expression rightOperand,
      DartType inferredType);

  Expression mapLiteral(
      ExpressionJudgment judgment, int fileOffset, DartType typeContext);

  Expression methodInvocation(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Node interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  Expression methodInvocationCall(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  Expression namedFunctionExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Expression not(ExpressionJudgment judgment, int fileOffset, Token operator,
      Expression operand, DartType inferredType);

  Expression nullLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, bool isSynthetic, DartType inferredType);

  Expression propertyAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType);

  Expression propertyGet(ExpressionJudgment judgment, int fileOffset,
      Node member, DartType inferredType);

  Expression propertyGetCall(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Expression propertySet(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Initializer redirectingInitializer(
      InitializerJudgment judgment, int fileOffset, Node initializerTarget);

  Expression rethrow_(ExpressionJudgment judgment, int fileOffset,
      Token rethrowKeyword, DartType inferredType);

  Statement returnStatement(StatementJudgment judgment, int fileOffset,
      Token returnKeyword, Expression expression, Token semicolon);

  Expression staticAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType);

  Expression staticGet(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType);

  Expression staticInvocation(
      ExpressionJudgment judgment,
      int fileOffset,
      Node expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  Expression stringConcatenation(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Expression stringLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, String value, DartType inferredType);

  Initializer superInitializer(InitializerJudgment judgment, int fileOffset);

  Statement switchStatement(StatementJudgment judgment, int fileOffset);

  Expression symbolLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token poundSign,
      List<Token> components,
      String value,
      DartType inferredType);

  Expression thisExpression(ExpressionJudgment judgment, int fileOffset,
      Token thisKeyword, DartType inferredType);

  Expression throw_(ExpressionJudgment judgment, int fileOffset,
      Token throwKeyword, Expression expression, DartType inferredType);

  Statement tryCatch(StatementJudgment judgment, int fileOffset);

  Statement tryFinally(StatementJudgment judgment, int fileOffset);

  Expression typeLiteral(ExpressionJudgment judgment, int fileOffset,
      Node expressionType, DartType inferredType);

  Expression variableAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      DartType writeContext,
      int writeVariableDeclarationOffset,
      Node combiner,
      DartType inferredType);

  Statement variableDeclaration(StatementJudgment judgment, int fileOffset,
      DartType statementType, DartType inferredType);

  Expression variableGet(
      ExpressionJudgment judgment,
      int fileOffset,
      bool isInCascade,
      int expressionVariableDeclarationOffset,
      DartType inferredType);

  Expression variableSet(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Statement whileStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token whileKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Statement body);

  Statement yieldStatement(StatementJudgment judgment, int fileOffset,
      Token yieldKeyword, Token star, Expression expression, Token semicolon);

  /// TODO(paulberry): this isn't really shaped properly for a factory class.
  void storePrefixInfo(int fileOffset, int prefixImportIndex);

  /// TODO(paulberry): this isn't really shaped properly for a factory class.
  void storeClassReference(int fileOffset, Node reference, DartType rawType);
}
