// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' show Catch, DartType, FunctionType, Node;

import 'package:kernel/type_algebra.dart' show Substitution;

import '../../scanner/token.dart' show Token;

import '../kernel/kernel_shadow_ast.dart'
    show
        ExpressionJudgment,
        InitializerJudgment,
        StatementJudgment,
        SwitchCaseJudgment;

/// Callback interface used by [TypeInferrer] to report the results of type
/// inference to a client.
///
/// The interface is structured as a set of enter/exit methods.  The enter
/// methods are called as the inferrer recurses down through the AST, and the
/// exit methods are called on the way back up.  The enter methods take a
/// [DartType] argument representing the downwards inference context; the exit
/// methods take [DartType] argument representing the final inferred type.
///
/// The default implementation (in this base class) does nothing, however it can
/// be used to debug type inference by uncommenting the
/// "with TypeInferenceDebugging" clause below.
abstract class TypeInferenceListener<Location, Reference, PrefixInfo> {
  void asExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      Token asOperator,
      void literalType,
      DartType inferredType);

  void assertInitializer(
      InitializerJudgment judgment,
      Location location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis);

  void assertStatement(
      StatementJudgment judgment,
      Location location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis,
      Token semicolon);

  void awaitExpression(ExpressionJudgment judgment, Location location,
      Token awaitKeyword, void expression, DartType inferredType);

  void block(StatementJudgment judgment, Location location, Token leftBracket,
      List<void> statements, Token rightBracket);

  void boolLiteral(ExpressionJudgment judgment, Location location,
      Token literal, bool value, DartType inferredType);

  void breakStatement(
      StatementJudgment judgment,
      Location location,
      Token breakKeyword,
      void label,
      Token semicolon,
      covariant Object labelBinder);

  void cascadeExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void catchStatement(
      Catch judgment,
      Location location,
      Token onKeyword,
      void type,
      Token catchKeyword,
      Token leftParenthesis,
      Token exceptionParameter,
      Token comma,
      Token stackTraceParameter,
      Token rightParenthesis,
      void body,
      DartType guardType,
      covariant Object exceptionBinder,
      DartType exceptionType,
      covariant Object stackTraceBinder,
      DartType stackTraceType);

  void conditionalExpression(
      ExpressionJudgment judgment,
      Location location,
      void condition,
      Token question,
      void thenExpression,
      Token colon,
      void elseExpression,
      DartType inferredType);

  void constructorInvocation(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType);

  void continueStatement(
      StatementJudgment judgment,
      Location location,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant Object labelBinder);

  void continueSwitchStatement(
      StatementJudgment judgment,
      Location location,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant Object labelBinder);

  void deferredCheck(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void doStatement(
      StatementJudgment judgment,
      Location location,
      Token doKeyword,
      void body,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      Token semicolon);

  void doubleLiteral(ExpressionJudgment judgment, Location location,
      Token literal, double value, DartType inferredType);

  void emptyStatement(Token semicolon);

  void expressionStatement(StatementJudgment judgment, Location location,
      void expression, Token semicolon);

  void fieldInitializer(
      InitializerJudgment judgment,
      Location location,
      Token thisKeyword,
      Token period,
      Token fieldName,
      Token equals,
      void expression,
      Reference initializerField);

  void forInStatement(
      StatementJudgment judgment,
      Location location,
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      Object loopVariable,
      Token identifier,
      Token inKeyword,
      void iterator,
      Token rightParenthesis,
      void body,
      covariant Object loopVariableBinder,
      DartType loopVariableType,
      Location writeLocation,
      DartType writeVariableType,
      covariant Object writeVariableBinder,
      Reference writeTarget);

  void forStatement(
      StatementJudgment judgment,
      Location location,
      Token forKeyword,
      Token leftParenthesis,
      List<Object> variableList,
      void initialization,
      Token leftSeparator,
      void condition,
      Token rightSeparator,
      void updaters,
      Token rightParenthesis,
      void body);

  void functionDeclaration(covariant Object binder, FunctionType inferredType);

  Object binderForFunctionDeclaration(
      StatementJudgment judgment, Location location, String name);

  void functionExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void ifNull(ExpressionJudgment judgment, Location location, void leftOperand,
      Token operator, void rightOperand, DartType inferredType);

  void ifStatement(
      StatementJudgment judgment,
      Location location,
      Token ifKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void thenStatement,
      Token elseKeyword,
      void elseStatement);

  void indexAssign(ExpressionJudgment judgment, Location location,
      Reference writeMember, Reference combiner, DartType inferredType);

  void intLiteral(ExpressionJudgment judgment, Location location, Token literal,
      num value, DartType inferredType);

  void invalidInitializer(InitializerJudgment judgment, Location location);

  void isExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      Token isOperator,
      void literalType,
      DartType testedType,
      DartType inferredType);

  void isNotExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      Token isOperator,
      Token notOperator,
      void literalType,
      DartType type,
      DartType inferredType);

  void labeledStatement(List<Object> labels, void statement);

  Object statementLabel(covariant Object binder, Token label, Token colon);

  Object binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name);

  void listLiteral(
      ExpressionJudgment judgment,
      Location location,
      Token constKeyword,
      covariant Object typeArguments,
      Token leftBracket,
      void elements,
      Token rightBracket,
      DartType inferredType);

  void logicalExpression(
      ExpressionJudgment judgment,
      Location location,
      void leftOperand,
      Token operator,
      void rightOperand,
      DartType inferredType);

  void mapLiteral(
      ExpressionJudgment judgment,
      Location location,
      Token constKeyword,
      covariant Object typeArguments,
      Token leftBracket,
      List<Object> entries,
      Token rightBracket,
      DartType inferredType);

  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value);

  void methodInvocation(
      ExpressionJudgment judgment,
      Location resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Reference interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  void methodInvocationCall(
      ExpressionJudgment judgment,
      Location resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  void namedFunctionExpression(ExpressionJudgment judgment,
      covariant Object binder, DartType inferredType);

  void not(ExpressionJudgment judgment, Location location, Token operator,
      void operand, DartType inferredType);

  void nullLiteral(ExpressionJudgment judgment, Location location,
      Token literal, bool isSynthetic, DartType inferredType);

  void propertyAssign(
      ExpressionJudgment judgment,
      Location location,
      Reference writeMember,
      DartType writeContext,
      Reference combiner,
      DartType inferredType);

  void propertyGet(ExpressionJudgment judgment, Location location,
      Reference member, DartType inferredType);

  void propertyGetCall(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void propertySet(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void redirectingInitializer(
      InitializerJudgment judgment,
      Location location,
      Token thisKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList,
      Reference initializerTarget);

  void rethrow_(ExpressionJudgment judgment, Location location,
      Token rethrowKeyword, DartType inferredType);

  void returnStatement(StatementJudgment judgment, Location location,
      Token returnKeyword, void expression, Token semicolon);

  void staticAssign(
      ExpressionJudgment judgment,
      Location location,
      Reference writeMember,
      DartType writeContext,
      Reference combiner,
      DartType inferredType);

  void staticGet(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType);

  void staticInvocation(
      ExpressionJudgment judgment,
      Location location,
      Reference expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  void stringConcatenation(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void stringLiteral(ExpressionJudgment judgment, Location location,
      Token literal, String value, DartType inferredType);

  void superInitializer(
      InitializerJudgment judgment,
      Location location,
      Token superKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList);

  Object switchCase(SwitchCaseJudgment switchCase, List<Object> labels,
      Token keyword, void expression, Token colon, List<void> statements);

  Object switchLabel(covariant Object binder, Token label, Token colon);

  Object binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name);

  void switchStatement(
      StatementJudgment judgment,
      Location location,
      Token switchKeyword,
      Token leftParenthesis,
      void expression,
      Token rightParenthesis,
      Token leftBracket,
      void members,
      Token rightBracket);

  void symbolLiteral(
      ExpressionJudgment judgment,
      Location location,
      Token poundSign,
      List<Token> components,
      String value,
      DartType inferredType);

  void thisExpression(ExpressionJudgment judgment, Location location,
      Token thisKeyword, DartType inferredType);

  void throw_(ExpressionJudgment judgment, Location location,
      Token throwKeyword, void expression, DartType inferredType);

  void tryCatch(StatementJudgment judgment, Location location);

  void tryFinally(
      StatementJudgment judgment,
      Location location,
      Token tryKeyword,
      void body,
      void catchClauses,
      Token finallyKeyword,
      void finallyBlock);

  void typeLiteral(ExpressionJudgment judgment, Location location,
      Reference expressionType, DartType inferredType);

  void variableAssign(
      ExpressionJudgment judgment,
      Location location,
      DartType writeContext,
      covariant Object writeVariableBinder,
      Reference combiner,
      DartType inferredType);

  void variableDeclaration(
      covariant Object binder, DartType statementType, DartType inferredType);

  Object binderForVariableDeclaration(
      StatementJudgment judgment, int fileOffset, String name);

  void variableGet(ExpressionJudgment judgment, Location location,
      bool isInCascade, covariant Object variableBinder, DartType inferredType);

  void whileStatement(
      StatementJudgment judgment,
      Location location,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void body);

  void yieldStatement(StatementJudgment judgment, Location location,
      Token yieldKeyword, Token star, void expression, Token semicolon);

  void storePrefixInfo(Location location, PrefixInfo prefixInfo);

  void storeClassReference(
      Location location, Reference reference, DartType rawType);
}

/// Kernel implementation of TypeInferenceListener; does nothing.
///
/// TODO(paulberry): fuse this with KernelFactory.
class KernelTypeInferenceListener
    implements TypeInferenceListener<int, Node, int> {
  @override
  void asExpression(ExpressionJudgment judgment, location, void expression,
      Token asOperator, void literalType, DartType inferredType) {}

  @override
  void assertInitializer(
      InitializerJudgment judgment,
      location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis) {}

  @override
  void assertStatement(
      StatementJudgment judgment,
      location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis,
      Token semicolon) {}

  @override
  void awaitExpression(ExpressionJudgment judgment, location,
      Token awaitKeyword, void expression, DartType inferredType) {}

  @override
  void block(StatementJudgment judgment, location, Token leftBracket,
      List<void> statements, Token rightBracket) {}

  @override
  void boolLiteral(ExpressionJudgment judgment, location, Token literal,
      bool value, DartType inferredType) {}

  @override
  void breakStatement(StatementJudgment judgment, location, Token breakKeyword,
      void label, Token semicolon, covariant void labelBinder) {}

  @override
  void cascadeExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void catchStatement(
      Catch judgment,
      location,
      Token onKeyword,
      void type,
      Token catchKeyword,
      Token leftParenthesis,
      Token exceptionParameter,
      Token comma,
      Token stackTraceParameter,
      Token rightParenthesis,
      void body,
      DartType guardType,
      covariant void exceptionBinder,
      DartType exceptionType,
      covariant void stackTraceBinder,
      DartType stackTraceType) {}

  @override
  void conditionalExpression(
      ExpressionJudgment judgment,
      location,
      void condition,
      Token question,
      void thenExpression,
      Token colon,
      void elseExpression,
      DartType inferredType) {}

  @override
  void constructorInvocation(ExpressionJudgment judgment, location,
      expressionTarget, DartType inferredType) {}

  @override
  void continueStatement(
      StatementJudgment judgment,
      location,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant void labelBinder) {}

  @override
  void continueSwitchStatement(
      StatementJudgment judgment,
      location,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant void labelBinder) {}

  @override
  void deferredCheck(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void doStatement(
      StatementJudgment judgment,
      location,
      Token doKeyword,
      void body,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      Token semicolon) {}

  @override
  void doubleLiteral(ExpressionJudgment judgment, location, Token literal,
      double value, DartType inferredType) {}

  @override
  void emptyStatement(Token semicolon) {}

  @override
  void expressionStatement(
      StatementJudgment judgment, location, void expression, Token semicolon) {}

  @override
  void fieldInitializer(
      InitializerJudgment judgment,
      location,
      Token thisKeyword,
      Token period,
      Token fieldName,
      Token equals,
      void expression,
      initializerField) {}

  @override
  void forInStatement(
      StatementJudgment judgment,
      location,
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      covariant Object loopVariable,
      Token identifier,
      Token inKeyword,
      void iterator,
      Token rightParenthesis,
      void body,
      covariant void loopVariableBinder,
      DartType loopVariableType,
      writeLocation,
      DartType writeVariableType,
      covariant void writeVariableBinder,
      writeTarget) {}

  @override
  void forStatement(
      StatementJudgment judgment,
      location,
      Token forKeyword,
      Token leftParenthesis,
      Object variableDeclarationList,
      void initialization,
      Token leftSeparator,
      void condition,
      Token rightSeparator,
      void updaters,
      Token rightParenthesis,
      void body) {}

  @override
  void functionDeclaration(covariant void binder, FunctionType inferredType) {}

  @override
  void binderForFunctionDeclaration(
      StatementJudgment judgment, location, String name) {}

  @override
  void functionExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void ifNull(ExpressionJudgment judgment, location, void leftOperand,
      Token operator, void rightOperand, DartType inferredType) {}

  @override
  void ifStatement(
      StatementJudgment judgment,
      location,
      Token ifKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void thenStatement,
      Token elseKeyword,
      void elseStatement) {}

  @override
  void indexAssign(ExpressionJudgment judgment, location, writeMember, combiner,
      DartType inferredType) {}

  @override
  void intLiteral(ExpressionJudgment judgment, location, Token literal,
      num value, DartType inferredType) {}

  @override
  void invalidInitializer(InitializerJudgment judgment, location) {}

  @override
  void isExpression(
      ExpressionJudgment judgment,
      location,
      void expression,
      Token isOperator,
      void literalType,
      DartType testedType,
      DartType inferredType) {}

  @override
  void isNotExpression(
      ExpressionJudgment judgment,
      location,
      void expression,
      Token isOperator,
      Token notOperator,
      void literalType,
      DartType type,
      DartType inferredType) {}

  @override
  void labeledStatement(List<Object> labels, void statement) {}

  @override
  void statementLabel(covariant void binder, Token label, Token colon) {}

  @override
  void binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name) {}

  @override
  void listLiteral(
      ExpressionJudgment judgment,
      location,
      Token constKeyword,
      covariant Object typeArguments,
      Token leftBracket,
      void elements,
      Token rightBracket,
      DartType inferredType) {}

  @override
  void logicalExpression(
      ExpressionJudgment judgment,
      location,
      void leftOperand,
      Token operator,
      void rightOperand,
      DartType inferredType) {}

  @override
  void mapLiteral(
      ExpressionJudgment judgment,
      location,
      Token constKeyword,
      Object typeArguments,
      Token leftBracket,
      List<Object> entries,
      Token rightBracket,
      DartType inferredType) {}

  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value) {}

  @override
  void methodInvocation(
      ExpressionJudgment judgment,
      resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void methodInvocationCall(
      ExpressionJudgment judgment,
      resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void namedFunctionExpression(ExpressionJudgment judgment,
      covariant void binder, DartType inferredType) {}

  @override
  void not(ExpressionJudgment judgment, location, Token operator, void operand,
      DartType inferredType) {}

  @override
  void nullLiteral(ExpressionJudgment judgment, location, Token literal,
      bool isSynthetic, DartType inferredType) {}

  @override
  void propertyAssign(ExpressionJudgment judgment, location, writeMember,
      DartType writeContext, combiner, DartType inferredType) {}

  @override
  void propertyGet(
      ExpressionJudgment judgment, location, member, DartType inferredType) {}

  @override
  void propertyGetCall(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void propertySet(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void redirectingInitializer(
      InitializerJudgment judgment,
      location,
      Token thisKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList,
      initializerTarget) {}

  @override
  void rethrow_(ExpressionJudgment judgment, location, Token rethrowKeyword,
      DartType inferredType) {}

  @override
  void returnStatement(StatementJudgment judgment, location,
      Token returnKeyword, void expression, Token semicolon) {}

  @override
  void staticAssign(ExpressionJudgment judgment, location, writeMember,
      DartType writeContext, combiner, DartType inferredType) {}

  @override
  void staticGet(ExpressionJudgment judgment, location, expressionTarget,
      DartType inferredType) {}

  @override
  void staticInvocation(
      ExpressionJudgment judgment,
      location,
      expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void storeClassReference(location, reference, DartType rawType) {}

  @override
  void storePrefixInfo(location, prefixInfo) {}

  @override
  void stringConcatenation(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void stringLiteral(ExpressionJudgment judgment, location, Token literal,
      String value, DartType inferredType) {}

  @override
  void superInitializer(
      InitializerJudgment judgment,
      location,
      Token superKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList) {}

  @override
  void switchCase(SwitchCaseJudgment switchCase, covariant List<Object> labels,
      Token keyword, void expression, Token colon, List<void> statements) {}

  @override
  void switchLabel(covariant void binder, Token label, Token colon) {}

  @override
  void binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name) {}

  @override
  void switchStatement(
      StatementJudgment judgment,
      location,
      Token switchKeyword,
      Token leftParenthesis,
      void expression,
      Token rightParenthesis,
      Token leftBracket,
      void members,
      Token rightBracket) {}

  @override
  void symbolLiteral(ExpressionJudgment judgment, location, Token poundSign,
      List<Token> components, String value, DartType inferredType) {}

  @override
  void thisExpression(ExpressionJudgment judgment, location, Token thisKeyword,
      DartType inferredType) {}

  @override
  void throw_(ExpressionJudgment judgment, location, Token throwKeyword,
      void expression, DartType inferredType) {}

  @override
  void tryCatch(StatementJudgment judgment, location) {}

  @override
  void tryFinally(StatementJudgment judgment, location, Token tryKeyword,
      void body, void catchClauses, Token finallyKeyword, void finallyBlock) {}

  @override
  void typeLiteral(ExpressionJudgment judgment, location, expressionType,
      DartType inferredType) {}

  @override
  void variableAssign(
      ExpressionJudgment judgment,
      location,
      DartType writeContext,
      covariant void writeVariableBinder,
      combiner,
      DartType inferredType) {}

  @override
  void variableDeclaration(
      covariant void binder, DartType statementType, DartType inferredType) {}

  @override
  void binderForVariableDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {}

  @override
  void variableGet(ExpressionJudgment judgment, location, bool isInCascade,
      expressionVariable, DartType inferredType) {}

  @override
  void whileStatement(
      StatementJudgment judgment,
      location,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void body) {}

  @override
  void yieldStatement(StatementJudgment judgment, location, Token yieldKeyword,
      Token star, void expression, Token semicolon) {}
}
