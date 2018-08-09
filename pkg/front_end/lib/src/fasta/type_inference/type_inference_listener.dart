// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show Catch, DartType, FunctionType, Node, TypeParameter;
import 'package:kernel/ast.dart' show Catch, DartType, FunctionType, Node;
import 'package:kernel/type_algebra.dart' show Substitution;

import '../../scanner/token.dart' show Token;
import '../kernel/kernel_shadow_ast.dart'
    show
        ExpressionJudgment,
        InitializerJudgment,
        LoadLibraryJudgment,
        LoadLibraryTearOffJudgment,
        StatementJudgment,
        SwitchCaseJudgment;
import '../kernel/kernel_type_variable_builder.dart'
    show KernelTypeVariableBuilder;

class AsExpressionTokens {
  final Token asOperator;

  AsExpressionTokens(this.asOperator);
}

class AssertInitializerTokens {
  final Token assertKeyword;
  final Token leftParenthesis;
  final Token comma;
  final Token rightParenthesis;

  AssertInitializerTokens(this.assertKeyword, this.leftParenthesis, this.comma,
      this.rightParenthesis);
}

class AssertStatementTokens {
  final Token assertKeyword;
  final Token leftParenthesis;
  final Token comma;
  final Token rightParenthesis;
  final Token semicolon;

  AssertStatementTokens(this.assertKeyword, this.leftParenthesis, this.comma,
      this.rightParenthesis, this.semicolon);
}

class AwaitExpressionTokens {
  final Token awaitKeyword;

  AwaitExpressionTokens(this.awaitKeyword);
}

class BlockTokens {
  final Token leftBracket;
  final Token rightBracket;

  BlockTokens(this.leftBracket, this.rightBracket);
}

class BoolLiteralTokens {
  final Token literal;

  BoolLiteralTokens(this.literal);
}

class BreakStatementTokens {
  final Token breakKeyword;
  final Token semicolon;

  BreakStatementTokens(this.breakKeyword, this.semicolon);
}

class ContinueStatementTokens {
  final Token continueKeyword;
  final Token semicolon;

  ContinueStatementTokens(this.continueKeyword, this.semicolon);
}

class ConditionalExpressionTokens {
  final Token question;
  final Token colon;

  ConditionalExpressionTokens(this.question, this.colon);
}

class ContinueSwitchStatementTokens {
  final Token continueKeyword;
  final Token semicolon;

  ContinueSwitchStatementTokens(this.continueKeyword, this.semicolon);
}

class DoStatementTokens {
  final Token doKeyword;
  final Token whileKeyword;
  final Token leftParenthesis;
  final Token rightParenthesis;
  final Token semicolon;

  DoStatementTokens(this.doKeyword, this.whileKeyword, this.leftParenthesis,
      this.rightParenthesis, this.semicolon);
}

class DoubleLiteralTokens {
  final Token literal;

  DoubleLiteralTokens(this.literal);
}

class EmptyStatementTokens {
  final Token semicolon;

  EmptyStatementTokens(this.semicolon);
}

class ExpressionStatementTokens {
  final Token semicolon;

  ExpressionStatementTokens(this.semicolon);
}

class ForInStatementTokens {
  final Token awaitKeyword;
  final Token forKeyword;
  final Token leftParenthesis;
  final Token inKeyword;
  final Token rightParenthesis;

  ForInStatementTokens(this.awaitKeyword, this.forKeyword, this.leftParenthesis,
      this.inKeyword, this.rightParenthesis);
}

class ForStatementTokens {
  final Token forKeyword;
  final Token leftParenthesis;
  final Token leftSeparator;
  final Token rightSeparator;
  final Token rightParenthesis;

  ForStatementTokens(this.forKeyword, this.leftParenthesis, this.leftSeparator,
      this.rightSeparator, this.rightParenthesis);
}

class IfNullTokens {
  final Token operator;

  IfNullTokens(this.operator);
}

class IfStatementTokens {
  final Token ifKeyword;
  final Token leftParenthesis;
  final Token rightParenthesis;
  final Token elseKeyword;

  IfStatementTokens(this.ifKeyword, this.leftParenthesis, this.rightParenthesis,
      this.elseKeyword);
}

class IntLiteralTokens {
  final Token literal;

  IntLiteralTokens(this.literal);
}

class IsExpressionTokens {
  final Token isOperator;

  IsExpressionTokens(this.isOperator);
}

class IsNotExpressionTokens {
  final Token isOperator;
  final Token notOperator;

  IsNotExpressionTokens(this.isOperator, this.notOperator);
}

class ListLiteralTokens {
  final Token constKeyword;
  final Token leftBracket;
  final Token rightBracket;

  ListLiteralTokens(this.constKeyword, this.leftBracket, this.rightBracket);
}

class LogicalExpressionTokens {
  final Token operatorToken;

  LogicalExpressionTokens(this.operatorToken);
}

class MapLiteralTokens {
  final Token constKeyword;
  final Token leftBracket;
  final Token rightBracket;

  MapLiteralTokens(this.constKeyword, this.leftBracket, this.rightBracket);
}

class NotTokens {
  final Token operator;

  NotTokens(this.operator);
}

class NullLiteralTokens {
  final Token literal;

  NullLiteralTokens(this.literal);
}

class RethrowTokens {
  final Token rethrowKeyword;

  RethrowTokens(this.rethrowKeyword);
}

class ReturnStatementTokens {
  final Token returnKeyword;
  final Token semicolon;

  ReturnStatementTokens(this.returnKeyword, this.semicolon);
}

class StringLiteralTokens {
  final Token literal;

  StringLiteralTokens(this.literal);
}

class SuperInitializerTokens {
  final Token superKeyword;
  final Token period;
  final Token constructorName;

  SuperInitializerTokens(this.superKeyword, this.period, this.constructorName);
}

class SwitchCaseTokens {
  final Token keyword;
  final Token colon;

  SwitchCaseTokens(this.keyword, this.colon);
}

class SwitchStatementTokens {
  final Token switchKeyword;
  final Token leftParenthesis;
  final Token rightParenthesis;
  final Token leftBracket;
  final Token rightBracket;

  SwitchStatementTokens(this.switchKeyword, this.leftParenthesis,
      this.rightParenthesis, this.leftBracket, this.rightBracket);
}

class ThisExpressionTokens {
  final Token thisKeyword;

  ThisExpressionTokens(this.thisKeyword);
}

class ThrowTokens {
  final Token throwKeyword;

  ThrowTokens(this.throwKeyword);
}

class CatchStatementTokens {
  final Token onKeyword;
  final Token catchKeyword;
  final Token leftParenthesis;
  final Token comma;
  final Token rightParenthesis;

  CatchStatementTokens(this.onKeyword, this.catchKeyword, this.leftParenthesis,
      this.comma, this.rightParenthesis);
}

class TryFinallyTokens {
  final Token tryKeyword;
  final Token finallyKeyword;

  TryFinallyTokens(this.tryKeyword, this.finallyKeyword);
}

class WhileStatementTokens {
  final Token whileKeyword;
  final Token leftParenthesis;
  final Token rightParenthesis;

  WhileStatementTokens(
      this.whileKeyword, this.leftParenthesis, this.rightParenthesis);
}

class YieldStatementTokens {
  final Token yieldKeyword;
  final Token star;
  final Token semicolon;

  YieldStatementTokens(this.yieldKeyword, this.star, this.semicolon);
}

class NamedExpressionTokens {
  final Token nameToken;
  final Token colon;

  NamedExpressionTokens(this.nameToken, this.colon);
}

abstract class TypeInferenceTokensSaver {
  AsExpressionTokens asExpressionTokens(Token asOperator);
  AssertInitializerTokens assertInitializerTokens(Token assertKeyword,
      Token leftParenthesis, Token comma, Token rightParenthesis);
  AssertStatementTokens assertStatementTokens(
      Token assertKeyword,
      Token leftParenthesis,
      Token comma,
      Token rightParenthesis,
      Token semicolon);
  AwaitExpressionTokens awaitExpressionTokens(Token awaitKeyword);
  BlockTokens blockTokens(Token leftBracket, Token rightBracket);
  BoolLiteralTokens boolLiteralTokens(Token literal);
  BreakStatementTokens breakStatementTokens(
      Token breakKeyword, Token semicolon);
  ContinueStatementTokens continueStatementTokens(
      Token continueKeyword, Token semicolon);
  ConditionalExpressionTokens conditionalExpressionTokens(
      Token question, Token colon);
  ContinueSwitchStatementTokens continueSwitchStatementTokens(
      Token continueKeyword, Token semicolon);
  DoStatementTokens doStatementTokens(Token doKeyword, Token whileKeyword,
      Token leftParenthesis, Token rightParenthesis, Token semicolon);
  DoubleLiteralTokens doubleLiteralTokens(Token literal);
  EmptyStatementTokens emptyStatementTokens(Token semicolon);
  ExpressionStatementTokens expressionStatementTokens(Token semicolon);
  ForInStatementTokens forInStatementTokens(
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      Token inKeyword,
      Token rightParenthesis);
  ForStatementTokens forStatementTokens(Token forKeyword, Token leftParenthesis,
      Token leftSeparator, Token rightSeparator, Token rightParenthesis);
  IfNullTokens ifNullTokens(Token operator);
  IfStatementTokens ifStatementTokens(Token ifKeyword, Token leftParenthesis,
      Token rightParenthesis, Token elseKeyword);
  IntLiteralTokens intLiteralTokens(Token literal);
  IsExpressionTokens isExpressionTokens(Token isOperator);
  IsNotExpressionTokens isNotExpressionTokens(
      Token isOperator, Token notOperator);
  ListLiteralTokens listLiteralTokens(
      Token constKeyword, Token leftBracket, Token rightBracket);
  LogicalExpressionTokens logicalExpressionTokens(Token operatorToken);
  MapLiteralTokens mapLiteralTokens(
      Token constKeyword, Token leftBracket, Token rightBracket);
  NotTokens notTokens(Token operator);
  NullLiteralTokens nullLiteralTokens(Token literal);
  RethrowTokens rethrowTokens(Token rethrowKeyword);
  ReturnStatementTokens returnStatementTokens(
      Token returnKeyword, Token semicolon);
  StringLiteralTokens stringLiteralTokens(Token literal);
  SuperInitializerTokens superInitializerTokens(
      Token superKeyword, Token period, Token constructorName);
  SwitchCaseTokens switchCaseTokens(Token keyword, Token colon);
  SwitchStatementTokens switchStatementTokens(
      Token switchKeyword,
      Token leftParenthesis,
      Token rightParenthesis,
      Token leftBracket,
      Token rightBracket);
  ThisExpressionTokens thisExpressionTokens(Token thisKeyword);
  ThrowTokens throwTokens(Token throwKeyword);
  CatchStatementTokens catchStatementTokens(Token onKeyword, Token catchKeyword,
      Token leftParenthesis, Token comma, Token rightParenthesis);
  TryFinallyTokens tryFinallyTokens(Token tryKeyword, Token finallyKeyword);
  WhileStatementTokens whileStatementTokens(
      Token whileKeyword, Token leftParenthesis, Token rightParenthesis);
  YieldStatementTokens yieldStatementTokens(
      Token yieldKeyword, Token star, Token semicolon);
  NamedExpressionTokens namedExpressionTokens(Token nameToken, Token colon);
}

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
  TypeInferenceTokensSaver get typeInferenceTokensSaver;

  void asExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      AsExpressionTokens tokens,
      void literalType,
      DartType inferredType);

  void assertInitializer(InitializerJudgment judgment, Location location,
      AssertInitializerTokens tokens, void condition, void message);

  void assertStatement(StatementJudgment judgment, Location location,
      AssertStatementTokens tokens, void condition, void message);

  void awaitExpression(ExpressionJudgment judgment, Location location,
      AwaitExpressionTokens tokens, void expression, DartType inferredType);

  Object binderForFunctionDeclaration(
      StatementJudgment judgment, Location location, String name);

  Object binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name);

  Object binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name);

  Object binderForTypeVariable(
      KernelTypeVariableBuilder builder, int fileOffset, String name);

  Object binderForVariableDeclaration(StatementJudgment judgment,
      int fileOffset, String name, bool forSyntheticToken);

  void block(StatementJudgment judgment, Location location, BlockTokens tokens,
      List<void> statements);

  void boolLiteral(ExpressionJudgment judgment, Location location,
      BoolLiteralTokens tokens, bool value, DartType inferredType);

  void breakStatement(StatementJudgment judgment, Location location,
      BreakStatementTokens tokens, void label, covariant Object labelBinder);

  void cascadeExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void catchStatement(
      Catch judgment,
      Location location,
      CatchStatementTokens tokens,
      void type,
      void body,
      covariant Object exceptionBinder,
      DartType exceptionType,
      covariant Object stackTraceBinder,
      DartType stackTraceType);

  void conditionalExpression(
      ExpressionJudgment judgment,
      Location location,
      void condition,
      ConditionalExpressionTokens tokens,
      void thenExpression,
      void elseExpression,
      DartType inferredType);

  void constructorInvocation(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType);

  void continueStatement(StatementJudgment judgment, Location location,
      ContinueStatementTokens tokens, void label, covariant Object labelBinder);

  void continueSwitchStatement(
      StatementJudgment judgment,
      Location location,
      ContinueSwitchStatementTokens tokens,
      void label,
      covariant Object labelBinder);

  void deferredCheck(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void doStatement(StatementJudgment judgment, Location location,
      DoStatementTokens tokens, void body, void condition);

  void doubleLiteral(ExpressionJudgment judgment, Location location,
      DoubleLiteralTokens tokens, double value, DartType inferredType);

  void emptyStatement(EmptyStatementTokens tokens);

  void expressionStatement(StatementJudgment judgment, Location location,
      void expression, ExpressionStatementTokens tokens);

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
      ForInStatementTokens tokens,
      Object loopVariable,
      void iterator,
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
      ForStatementTokens tokens,
      List<Object> variableList,
      void initialization,
      void condition,
      void updaters,
      void body);

  void functionDeclaration(covariant Object binder, FunctionType inferredType);

  void functionExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void functionType(Location location, DartType type);

  void functionTypedFormalParameter(Location location, DartType type);

  void ifNull(ExpressionJudgment judgment, Location location, void leftOperand,
      IfNullTokens tokens, void rightOperand, DartType inferredType);

  void ifStatement(
      StatementJudgment judgment,
      Location location,
      IfStatementTokens tokens,
      void condition,
      void thenStatement,
      void elseStatement);

  void indexAssign(
      ExpressionJudgment judgment,
      Location location,
      DartType receiverType,
      Reference writeMember,
      Reference combiner,
      DartType inferredType);

  void intLiteral(ExpressionJudgment judgment, Location location,
      IntLiteralTokens tokens, num value, DartType inferredType);

  void invalidAssignment(ExpressionJudgment judgment, Location location);

  void invalidInitializer(InitializerJudgment judgment, Location location);

  void isExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      IsExpressionTokens tokens,
      void literalType,
      DartType inferredType);

  void isNotExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      IsNotExpressionTokens tokens,
      void literalType,
      DartType inferredType);

  void labeledStatement(List<Object> labels, void statement);

  void listLiteral(
      ExpressionJudgment judgment,
      Location location,
      ListLiteralTokens tokens,
      covariant Object typeArguments,
      void elements,
      DartType inferredType);

  void loadLibrary(LoadLibraryJudgment judgment, Location location,
      Reference library, FunctionType calleeType, DartType inferredType);

  void loadLibraryTearOff(LoadLibraryTearOffJudgment judgment,
      Location location, Reference library, DartType inferredType);

  void logicalExpression(
      ExpressionJudgment judgment,
      Location location,
      void leftOperand,
      LogicalExpressionTokens tokens,
      void rightOperand,
      DartType inferredType);

  void mapLiteral(
      ExpressionJudgment judgment,
      Location location,
      MapLiteralTokens tokens,
      covariant Object typeArguments,
      List<Object> entries,
      DartType inferredType);

  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value);

  void methodInvocation(
      ExpressionJudgment judgment,
      Location resultOffset,
      DartType receiverType,
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

  void not(ExpressionJudgment judgment, Location location, NotTokens tokens,
      void operand, DartType inferredType);

  void nullLiteral(ExpressionJudgment judgment, Location location,
      NullLiteralTokens tokens, bool isSynthetic, DartType inferredType);

  void propertyAssign(
      ExpressionJudgment judgment,
      Location location,
      DartType receiverType,
      Reference writeMember,
      DartType writeContext,
      Reference combiner,
      DartType inferredType);

  void propertyGet(
      ExpressionJudgment judgment,
      Location location,
      bool forSyntheticToken,
      DartType receiverType,
      Reference member,
      DartType inferredType);

  void propertyGetCall(
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
      RethrowTokens tokens, DartType inferredType);

  void returnStatement(StatementJudgment judgment, Location location,
      ReturnStatementTokens tokens, void expression);

  Object statementLabel(covariant Object binder, Token label, Token colon);

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

  void storeClassReference(
      Location location, Reference reference, DartType rawType);

  void storePrefixInfo(Location location, PrefixInfo prefixInfo);

  void storeUnresolved(Location location);

  void stringConcatenation(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void stringLiteral(ExpressionJudgment judgment, Location location,
      StringLiteralTokens tokens, String value, DartType inferredType);

  void superInitializer(InitializerJudgment judgment, Location location,
      SuperInitializerTokens tokens, covariant Object argumentList);

  Object switchCase(SwitchCaseJudgment switchCase, List<Object> labels,
      Token keyword, void expression, Token colon, List<void> statements);

  Object switchLabel(covariant Object binder, Token label, Token colon);

  void switchStatement(StatementJudgment judgment, Location location,
      SwitchStatementTokens tokens, void expression, void members);

  void symbolLiteral(
      ExpressionJudgment judgment,
      Location location,
      Token poundSign,
      List<Token> components,
      String value,
      DartType inferredType);

  void thisExpression(ExpressionJudgment judgment, Location location,
      ThisExpressionTokens tokens, DartType inferredType);

  void throw_(ExpressionJudgment judgment, Location location,
      ThrowTokens tokens, void expression, DartType inferredType);

  void tryCatch(StatementJudgment judgment, Location location);

  void tryFinally(StatementJudgment judgment, Location location,
      TryFinallyTokens tokens, void body, void catchClauses, void finallyBlock);

  void typeLiteral(ExpressionJudgment judgment, Location location,
      Reference expressionType, DartType inferredType);

  void typeReference(
      Location location,
      bool forSyntheticToken,
      Token leftBracket,
      List<void> typeArguments,
      Token rightBracket,
      Reference reference,
      covariant Object binder,
      DartType type);

  void typeVariableDeclaration(
      Location location, covariant Object binder, TypeParameter typeParameter);

  void variableAssign(
      ExpressionJudgment judgment,
      Location location,
      DartType writeContext,
      covariant Object writeVariableBinder,
      Reference combiner,
      DartType inferredType);

  void variableDeclaration(covariant Object binder, DartType inferredType);

  void variableGet(
      ExpressionJudgment judgment,
      Location location,
      bool forSyntheticToken,
      bool isInCascade,
      covariant Object variableBinder,
      DartType inferredType);

  void voidType(Location location, Token token, DartType type);

  void whileStatement(StatementJudgment judgment, Location location,
      WhileStatementTokens tokens, void condition, void body);

  void yieldStatement(StatementJudgment judgment, Location location,
      YieldStatementTokens tokens, void expression);
}

/// Kernel implementation of TypeInferenceListener; does nothing.
///
/// TODO(paulberry): fuse this with KernelFactory.
class KernelTypeInferenceListener
    implements TypeInferenceListener<int, Node, int> {
  @override
  TypeInferenceTokensSaver get typeInferenceTokensSaver => null;

  @override
  void asExpression(ExpressionJudgment judgment, location, void expression,
      AsExpressionTokens tokens, void literalType, DartType inferredType) {}

  @override
  void assertInitializer(InitializerJudgment judgment, location,
      AssertInitializerTokens tokens, void condition, void message) {}

  @override
  void assertStatement(StatementJudgment judgment, location,
      AssertStatementTokens tokens, void condition, void message) {}

  @override
  void awaitExpression(ExpressionJudgment judgment, location,
      AwaitExpressionTokens tokens, void expression, DartType inferredType) {}

  @override
  void binderForFunctionDeclaration(
      StatementJudgment judgment, location, String name) {}

  @override
  void binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name) {}

  @override
  void binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name) {}

  @override
  void binderForTypeVariable(
      KernelTypeVariableBuilder builder, int fileOffset, String name) {}

  @override
  void binderForVariableDeclaration(StatementJudgment judgment, int fileOffset,
      String name, bool forSyntheticToken) {}

  @override
  void block(StatementJudgment judgment, location, BlockTokens tokens,
      List<void> statements) {}

  @override
  void boolLiteral(ExpressionJudgment judgment, location,
      BoolLiteralTokens tokens, bool value, DartType inferredType) {}

  @override
  void breakStatement(StatementJudgment judgment, location,
      BreakStatementTokens tokens, void label, covariant void labelBinder) {}

  @override
  void cascadeExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void catchStatement(
      Catch judgment,
      location,
      CatchStatementTokens tokens,
      void type,
      void body,
      covariant void exceptionBinder,
      DartType exceptionType,
      covariant void stackTraceBinder,
      DartType stackTraceType) {}

  @override
  void conditionalExpression(
      ExpressionJudgment judgment,
      location,
      void condition,
      ConditionalExpressionTokens tokens,
      void thenExpression,
      void elseExpression,
      DartType inferredType) {}

  @override
  void constructorInvocation(ExpressionJudgment judgment, location,
      expressionTarget, DartType inferredType) {}

  @override
  void continueStatement(StatementJudgment judgment, location,
      ContinueStatementTokens tokens, void label, covariant void labelBinder) {}

  @override
  void continueSwitchStatement(
      StatementJudgment judgment,
      location,
      ContinueSwitchStatementTokens tokens,
      void label,
      covariant void labelBinder) {}

  @override
  void deferredCheck(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void doStatement(StatementJudgment judgment, location,
      DoStatementTokens tokens, void body, void condition) {}

  @override
  void doubleLiteral(ExpressionJudgment judgment, location,
      DoubleLiteralTokens tokens, double value, DartType inferredType) {}

  @override
  void emptyStatement(EmptyStatementTokens tokens) {}

  @override
  void expressionStatement(StatementJudgment judgment, location,
      void expression, ExpressionStatementTokens tokens) {}

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
      ForInStatementTokens tokens,
      covariant Object loopVariable,
      void iterator,
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
      ForStatementTokens tokens,
      Object variableDeclarationList,
      void initialization,
      void condition,
      void updaters,
      void body) {}

  @override
  void functionDeclaration(covariant void binder, FunctionType inferredType) {}

  @override
  void functionExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  void functionType(int location, DartType type) {}

  void functionTypedFormalParameter(int location, DartType type) {}

  @override
  void ifNull(ExpressionJudgment judgment, location, void leftOperand,
      IfNullTokens tokens, void rightOperand, DartType inferredType) {}

  @override
  void ifStatement(
      StatementJudgment judgment,
      location,
      IfStatementTokens tokens,
      void condition,
      void thenStatement,
      void elseStatement) {}

  @override
  void indexAssign(ExpressionJudgment judgment, location, receiverType,
      writeMember, combiner, DartType inferredType) {}

  @override
  void intLiteral(ExpressionJudgment judgment, location,
      IntLiteralTokens tokens, num value, DartType inferredType) {}

  @override
  void invalidAssignment(ExpressionJudgment judgment, int location) {}

  @override
  void invalidInitializer(InitializerJudgment judgment, location) {}

  @override
  void isExpression(ExpressionJudgment judgment, location, void expression,
      IsExpressionTokens tokens, void literalType, DartType inferredType) {}

  @override
  void isNotExpression(ExpressionJudgment judgment, location, void expression,
      IsNotExpressionTokens tokens, void literalType, DartType inferredType) {}

  @override
  void labeledStatement(List<Object> labels, void statement) {}

  @override
  void listLiteral(
      ExpressionJudgment judgment,
      location,
      ListLiteralTokens tokens,
      covariant Object typeArguments,
      void elements,
      DartType inferredType) {}

  @override
  void loadLibrary(LoadLibraryJudgment judgment, location, library,
      FunctionType calleeType, DartType inferredType) {}

  @override
  void loadLibraryTearOff(LoadLibraryTearOffJudgment judgment, location,
      library, DartType inferredType) {}

  @override
  void logicalExpression(
      ExpressionJudgment judgment,
      location,
      void leftOperand,
      LogicalExpressionTokens tokens,
      void rightOperand,
      DartType inferredType) {}

  @override
  void mapLiteral(
      ExpressionJudgment judgment,
      location,
      MapLiteralTokens tokens,
      Object typeArguments,
      List<Object> entries,
      DartType inferredType) {}

  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value) {}

  @override
  void methodInvocation(
      ExpressionJudgment judgment,
      resultOffset,
      DartType receiverType,
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
  void not(ExpressionJudgment judgment, location, NotTokens tokens,
      void operand, DartType inferredType) {}

  @override
  void nullLiteral(ExpressionJudgment judgment, location,
      NullLiteralTokens tokens, bool isSynthetic, DartType inferredType) {}

  @override
  void propertyAssign(ExpressionJudgment judgment, location, receiverType,
      writeMember, DartType writeContext, combiner, DartType inferredType) {}

  @override
  void propertyGet(ExpressionJudgment judgment, location,
      bool forSyntheticToken, receiverType, member, DartType inferredType) {}

  @override
  void propertyGetCall(
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
  void rethrow_(ExpressionJudgment judgment, location, RethrowTokens tokens,
      DartType inferredType) {}

  @override
  void returnStatement(StatementJudgment judgment, location,
      ReturnStatementTokens tokens, void expression) {}

  @override
  void statementLabel(covariant void binder, Token label, Token colon) {}

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
  void storeUnresolved(int location) {}

  @override
  void stringConcatenation(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void stringLiteral(ExpressionJudgment judgment, location,
      StringLiteralTokens tokens, String value, DartType inferredType) {}

  @override
  void superInitializer(InitializerJudgment judgment, location,
      SuperInitializerTokens tokens, covariant Object argumentList) {}

  @override
  void switchCase(SwitchCaseJudgment switchCase, covariant List<Object> labels,
      Token keyword, void expression, Token colon, List<void> statements) {}

  @override
  void switchLabel(covariant void binder, Token label, Token colon) {}

  @override
  void switchStatement(StatementJudgment judgment, location,
      SwitchStatementTokens tokens, void expression, void members) {}

  @override
  void symbolLiteral(ExpressionJudgment judgment, location, Token poundSign,
      List<Token> components, String value, DartType inferredType) {}

  @override
  void thisExpression(ExpressionJudgment judgment, location,
      ThisExpressionTokens tokns, DartType inferredType) {}

  @override
  void throw_(ExpressionJudgment judgment, location, ThrowTokens tokens,
      void expression, DartType inferredType) {}

  @override
  void tryCatch(StatementJudgment judgment, location) {}

  @override
  void tryFinally(StatementJudgment judgment, location, TryFinallyTokens tokens,
      void body, void catchClauses, void finallyBlock) {}

  @override
  void typeLiteral(ExpressionJudgment judgment, location, expressionType,
      DartType inferredType) {}

  @override
  void typeReference(
      location,
      bool forSyntheticToken,
      Token leftBracket,
      List<void> typeArguments,
      Token rightBracket,
      reference,
      covariant void binder,
      DartType type) {}

  @override
  void typeVariableDeclaration(
      location, covariant void binder, TypeParameter typeParameter) {}

  @override
  void variableAssign(
      ExpressionJudgment judgment,
      location,
      DartType writeContext,
      covariant void writeVariableBinder,
      combiner,
      DartType inferredType) {}

  @override
  void variableDeclaration(covariant void binder, DartType inferredType) {}

  @override
  void variableGet(
      ExpressionJudgment judgment,
      location,
      bool forSyntheticToken,
      bool isInCascade,
      expressionVariable,
      DartType inferredType) {}

  @override
  void voidType(location, Token token, DartType type) {}

  @override
  void whileStatement(StatementJudgment judgment, location,
      WhileStatementTokens toknes, void condition, void body) {}

  @override
  void yieldStatement(StatementJudgment judgment, location,
      YieldStatementTokens tokens, void expression) {}
}
