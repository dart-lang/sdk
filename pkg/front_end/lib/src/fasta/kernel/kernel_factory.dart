// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart'
    show
        Catch,
        DartType,
        Expression,
        FunctionType,
        Initializer,
        LabeledStatement,
        Node,
        Statement,
        SwitchCase,
        VariableDeclaration;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'factory.dart' show Factory;

import 'kernel_shadow_ast.dart'
    show
        ExpressionJudgment,
        InitializerJudgment,
        StatementJudgment,
        SwitchCaseJudgment;

/// Implementation of [Factory] that builds source code into a kernel
/// representation.
class KernelFactory
    implements Factory<Expression, Statement, Initializer, void> {
  @override
  Expression asExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token asOperator,
      void literalType,
      DartType inferredType) {
    return judgment;
  }

  @override
  Initializer assertInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis) {
    return judgment;
  }

  @override
  Statement assertStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis,
      Token semicolon) {
    return judgment;
  }

  @override
  Expression awaitExpression(ExpressionJudgment judgment, int fileOffset,
      Token awaitKeyword, Expression expression, DartType inferredType) {
    return judgment;
  }

  @override
  Statement block(StatementJudgment judgment, int fileOffset, Token leftBracket,
      List<Statement> statements, Token rightBracket) {
    return judgment;
  }

  @override
  Expression boolLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, bool value, DartType inferredType) {
    return judgment;
  }

  @override
  Statement breakStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token breakKeyword,
      Expression label,
      Token semicolon,
      covariant LabeledStatement labelBinder) {
    return judgment;
  }

  @override
  Expression cascadeExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {
    return judgment;
  }

  @override
  Object catchStatement(
      Catch judgment,
      int fileOffset,
      Token onKeyword,
      void type,
      Token catchKeyword,
      Token leftParenthesis,
      Token exceptionParameter,
      Token comma,
      Token stackTraceParameter,
      Token rightParenthesis,
      Statement body,
      DartType guardType,
      covariant VariableDeclaration exceptionBinder,
      DartType exceptionType,
      covariant VariableDeclaration stackTraceBinder,
      DartType stackTraceType) {
    return judgment;
  }

  @override
  Expression conditionalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression condition,
      Token question,
      Expression thenExpression,
      Token colon,
      Expression elseExpression,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression constructorInvocation(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType) {
    return judgment;
  }

  @override
  Statement continueStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token continueKeyword,
      Expression label,
      Token semicolon,
      covariant LabeledStatement labelBinder) {
    return judgment;
  }

  @override
  Statement continueSwitchStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token continueKeyword,
      Expression label,
      Token semicolon,
      covariant LabeledStatement labelBinder) {
    return judgment;
  }

  @override
  Expression deferredCheck(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {
    return judgment;
  }

  @override
  Statement doStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token doKeyword,
      Statement body,
      Token whileKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Token semicolon) {
    return judgment;
  }

  @override
  Expression doubleLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, double value, DartType inferredType) {
    return judgment;
  }

  @override
  Statement emptyStatement(Token semicolon) {
    return null;
  }

  @override
  Statement expressionStatement(StatementJudgment judgment, int fileOffset,
      Expression expression, Token semicolon) {
    return judgment;
  }

  @override
  Initializer fieldInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token thisKeyword,
      Token period,
      Token fieldName,
      Token equals,
      Expression expression,
      Node initializerField) {
    return judgment;
  }

  @override
  Statement forInStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      Object loopVariable,
      Token identifier,
      Token inKeyword,
      Expression iterator,
      Token rightParenthesis,
      Statement body,
      covariant Object loopVariableBinder,
      DartType loopVariableType,
      int writeOffset,
      DartType writeVariableType,
      covariant Object writeVariableBinder,
      Node writeTarget) {
    return judgment;
  }

  @override
  Statement forStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token forKeyword,
      Token leftParenthesis,
      Object variableDeclarationList,
      Expression initialization,
      Token leftSeparator,
      Expression condition,
      Token rightSeparator,
      List<Expression> updaters,
      Token rightParenthesis,
      Statement body) {
    return judgment;
  }

  @override
  Statement functionDeclaration(
      covariant VariableDeclaration binder, FunctionType inferredType) {
    return binder;
  }

  @override
  Object binderForFunctionDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {
    return judgment;
  }

  @override
  Expression functionExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {
    return judgment;
  }

  @override
  Expression ifNull(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression leftOperand,
      Token operator,
      Expression rightOperand,
      DartType inferredType) {
    return judgment;
  }

  @override
  Statement ifStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token ifKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Statement thenStatement,
      Token elseKeyword,
      Statement elseStatement) {
    return judgment;
  }

  @override
  Expression indexAssign(ExpressionJudgment judgment, int fileOffset,
      Node writeMember, Node combiner, DartType inferredType) {
    return judgment;
  }

  @override
  Expression intLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, num value, DartType inferredType) {
    return judgment;
  }

  @override
  Initializer invalidInitializer(InitializerJudgment judgment, int fileOffset) {
    return judgment;
  }

  @override
  Expression isExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token isOperator,
      void literalType,
      DartType testedType,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression isNotExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token isOperator,
      Token notOperator,
      void literalType,
      DartType testedType,
      DartType inferredType) {
    return judgment;
  }

  @override
  Statement labeledStatement(List<Object> labels, Statement statement) {
    return labels[0];
  }

  Object statementLabel(
      covariant StatementJudgment binder, Token label, Token colon) {
    return binder;
  }

  @override
  Object binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name) {
    return judgment;
  }

  @override
  Expression listLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token constKeyword,
      Object typeArguments,
      Token leftBracket,
      List<Expression> elements,
      Token rightBracket,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression logicalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression leftOperand,
      Token operator,
      Expression rightOperand,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression mapLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token constKeyword,
      Object typeArguments,
      Token leftBracket,
      List<Object> entries,
      Token rightBracket,
      DartType inferredType) {
    return judgment;
  }

  @override
  Object mapLiteralEntry(Object judgment, int fileOffset, Expression key,
      Token separator, Expression value) {
    return judgment;
  }

  @override
  Expression methodInvocation(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Node interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression methodInvocationCall(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression namedFunctionExpression(ExpressionJudgment judgment,
      covariant VariableDeclaration binder, DartType inferredType) {
    return judgment;
  }

  @override
  Expression not(ExpressionJudgment judgment, int fileOffset, Token operator,
      Expression operand, DartType inferredType) {
    return judgment;
  }

  @override
  Expression nullLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, bool isSynthetic, DartType inferredType) {
    return judgment;
  }

  @override
  Expression propertyAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression propertyGet(ExpressionJudgment judgment, int fileOffset,
      Node member, DartType inferredType) {
    return judgment;
  }

  @override
  Expression propertyGetCall(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {
    return judgment;
  }

  @override
  Expression propertySet(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {
    return judgment;
  }

  @override
  Initializer redirectingInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token thisKeyword,
      Token period,
      Token constructorName,
      Object argumentList,
      Node initializerTarget) {
    return judgment;
  }

  @override
  Expression rethrow_(ExpressionJudgment judgment, int fileOffset,
      Token rethrowKeyword, DartType inferredType) {
    return judgment;
  }

  @override
  Statement returnStatement(StatementJudgment judgment, int fileOffset,
      Token returnKeyword, Expression expression, Token semicolon) {
    return judgment;
  }

  @override
  Expression staticAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression staticGet(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType) {
    return judgment;
  }

  @override
  Expression staticInvocation(
      ExpressionJudgment judgment,
      int fileOffset,
      Node expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    return judgment;
  }

  @override
  void storeClassReference(int fileOffset, Node reference, DartType rawType) {}

  @override
  void storePrefixInfo(int fileOffset, int prefixImportIndex) {}

  @override
  Expression stringConcatenation(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {
    return judgment;
  }

  @override
  Expression stringLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, String value, DartType inferredType) {
    return judgment;
  }

  @override
  Initializer superInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token superKeyword,
      Token period,
      Token constructorName,
      Object argumentList) {
    return judgment;
  }

  SwitchCase switchCase(
      SwitchCaseJudgment judgment,
      List<Object> labels,
      Token keyword,
      Expression expression,
      Token colon,
      List<Statement> statements) {
    return judgment;
  }

  SwitchCase switchLabel(
      covariant SwitchCase binder, Token label, Token colon) {
    return binder;
  }

  SwitchCase binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name) {
    return judgment;
  }

  @override
  Statement switchStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token switchKeyword,
      Token leftParenthesis,
      Expression expression,
      Token rightParenthesis,
      Token leftBracket,
      List<Object> members,
      Token rightBracket) {
    return judgment;
  }

  @override
  Expression symbolLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token poundSign,
      List<Token> components,
      String value,
      DartType inferredType) {
    return judgment;
  }

  @override
  Expression thisExpression(ExpressionJudgment judgment, int fileOffset,
      Token thisKeyword, DartType inferredType) {
    return judgment;
  }

  @override
  Expression throw_(ExpressionJudgment judgment, int fileOffset,
      Token throwKeyword, Expression expression, DartType inferredType) {
    return judgment;
  }

  @override
  Statement tryCatch(StatementJudgment judgment, int fileOffset) {
    return judgment;
  }

  @override
  Statement tryFinally(
      StatementJudgment judgment,
      int fileOffset,
      Token tryKeyword,
      Statement body,
      List<Object> catchClauses,
      Token finallyKeyword,
      Statement finallyBlock) {
    return judgment;
  }

  @override
  Expression typeLiteral(ExpressionJudgment judgment, int fileOffset,
      Node expressionType, DartType inferredType) {
    return judgment;
  }

  @override
  Expression variableAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      DartType writeContext,
      covariant VariableDeclaration writeVariableBinder,
      Node combiner,
      DartType inferredType) {
    return judgment;
  }

  @override
  Statement variableDeclaration(covariant VariableDeclaration binder,
      DartType statementType, DartType inferredType) {
    return binder;
  }

  @override
  Object binderForVariableDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {
    return judgment;
  }

  @override
  Expression variableGet(
      ExpressionJudgment judgment,
      int fileOffset,
      bool isInCascade,
      covariant VariableDeclaration variableBinder,
      DartType inferredType) {
    return judgment;
  }

  @override
  Statement whileStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token whileKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Statement body) {
    return judgment;
  }

  @override
  Statement yieldStatement(StatementJudgment judgment, int fileOffset,
      Token yieldKeyword, Token star, Expression expression, Token semicolon) {
    return judgment;
  }
}
