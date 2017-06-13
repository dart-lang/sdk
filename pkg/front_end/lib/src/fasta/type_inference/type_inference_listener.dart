// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart';

/// Base class for [TypeInferenceListener] that defines the API for debugging.
///
/// By default no debug info is printed.  To enable debug printing, mix in
/// [TypeInferenceDebugging].
class TypeInferenceBase {
  bool debugExpressionEnter(
      String expressionType, Expression expression, DartType typeContext) {
    return false;
  }

  void debugExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {}

  void debugInitializerEnter(String initializerType, Initializer initializer) {}

  void debugInitializerExit(String initializerType, Initializer initializer) {}

  void debugStatementEnter(String statementType, Statement statement) {}

  void debugStatementExit(String statementType, Statement statement) {}
}

/// Mixin which can be applied to [TypeInferenceListener] to cause debug info to
/// be printed.
class TypeInferenceDebugging implements TypeInferenceBase {
  bool debugExpressionEnter(
      String expressionType, Expression expression, DartType typeContext) {
    print('Enter $expressionType($expression) (context=$typeContext)');
    return true;
  }

  void debugExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {
    print('Exit $expressionType($expression) (type=$inferredType)');
  }

  void debugInitializerEnter(String initializerType, Initializer initializer) {
    print('Enter $initializerType($initializer)');
  }

  void debugInitializerExit(String initializerType, Initializer initializer) {
    print('Exit $initializerType($initializer)');
  }

  void debugStatementEnter(String statementType, Statement statement) {
    print('Enter $statementType($statement)');
  }

  void debugStatementExit(String statementType, Statement statement) {
    print('Exit $statementType($statement)');
  }
}

/// Callback interface used by [TypeInferrer] to report the results of type
/// inference to a client.
///
/// The interface is structured as a set of enter/exit methods.  The enter
/// methods are called as the inferrer recurses down through the AST, and the
/// exit methods are called on the way back up.  The enter methods take a
/// [DartType] argument representing the downwards inference context, and return
/// a bool indicating whether the TypeInferenceListener needs to know the final
/// inferred type; the exit methods take [DartType] argument representing the
/// final inferred type.
///
/// The default implementation (in this base class) does nothing, however it can
/// be used to debug type inference by uncommenting the
/// "with TypeInferenceDebugging" clause below.
class TypeInferenceListener
    extends TypeInferenceBase // with TypeInferenceDebugging
{
  bool asExpressionEnter(AsExpression expression, DartType typeContext) =>
      debugExpressionEnter("asExpression", expression, typeContext);

  void asExpressionExit(AsExpression expression, DartType inferredType) =>
      debugExpressionExit("asExpression", expression, inferredType);

  bool awaitExpressionEnter(AwaitExpression expression, DartType typeContext) =>
      debugExpressionEnter("awaitExpression", expression, typeContext);

  void awaitExpressionExit(AwaitExpression expression, DartType inferredType) =>
      debugExpressionExit("awaitExpression", expression, inferredType);

  void blockEnter(Block statement) => debugStatementEnter('block', statement);

  void blockExit(Block statement) => debugStatementExit('block', statement);

  bool boolLiteralEnter(BoolLiteral expression, DartType typeContext) =>
      debugExpressionEnter("boolLiteral", expression, typeContext);

  void boolLiteralExit(BoolLiteral expression, DartType inferredType) =>
      debugExpressionExit("boolLiteral", expression, inferredType);

  bool cascadeExpressionEnter(Let expression, DartType typeContext) =>
      debugExpressionEnter("cascade", expression, typeContext);

  void cascadeExpressionExit(Let expression, DartType inferredType) =>
      debugExpressionExit("cascade", expression, inferredType);

  bool conditionalExpressionEnter(
          ConditionalExpression expression, DartType typeContext) =>
      debugExpressionEnter("conditionalExpression", expression, typeContext);

  void conditionalExpressionExit(
          ConditionalExpression expression, DartType inferredType) =>
      debugExpressionExit("conditionalExpression", expression, inferredType);

  bool constructorInvocationEnter(
          InvocationExpression expression, DartType typeContext) =>
      debugExpressionEnter("constructorInvocation", expression, typeContext);

  void constructorInvocationExit(
          InvocationExpression expression, DartType inferredType) =>
      debugExpressionExit("constructorInvocation", expression, inferredType);

  bool doubleLiteralEnter(DoubleLiteral expression, DartType typeContext) =>
      debugExpressionEnter("doubleLiteral", expression, typeContext);

  void doubleLiteralExit(DoubleLiteral expression, DartType inferredType) =>
      debugExpressionExit("doubleLiteral", expression, inferredType);

  void expressionStatementEnter(ExpressionStatement statement) =>
      debugStatementEnter('expressionStatement', statement);

  void expressionStatementExit(ExpressionStatement statement) =>
      debugStatementExit('expressionStatement', statement);

  void forInStatementEnter(ForInStatement statement) =>
      debugStatementEnter('forInStatement', statement);

  void forInStatementExit(ForInStatement statement) =>
      debugStatementExit('forInStatement', statement);

  void functionDeclarationEnter(FunctionDeclaration statement) =>
      debugStatementEnter('functionDeclaration', statement);

  void functionDeclarationExit(FunctionDeclaration statement) =>
      debugStatementExit('functionDeclaration', statement);

  bool functionExpressionEnter(
          FunctionExpression expression, DartType typeContext) =>
      debugExpressionEnter("functionExpression", expression, typeContext);

  void functionExpressionExit(
          FunctionExpression expression, DartType inferredType) =>
      debugExpressionExit("functionExpression", expression, inferredType);

  void ifStatementEnter(IfStatement statement) =>
      debugStatementEnter('ifStatement', statement);

  void ifStatementExit(IfStatement statement) =>
      debugStatementExit('ifStatement', statement);

  bool indexAssignEnter(Expression expression, DartType typeContext) =>
      debugExpressionEnter("indexAssign", expression, typeContext);

  void indexAssignExit(Expression expression, DartType inferredType) =>
      debugExpressionExit("indexAssign", expression, inferredType);

  bool intLiteralEnter(IntLiteral expression, DartType typeContext) =>
      debugExpressionEnter("intLiteral", expression, typeContext);

  void intLiteralExit(IntLiteral expression, DartType inferredType) =>
      debugExpressionExit("intLiteral", expression, inferredType);

  bool isExpressionEnter(IsExpression expression, DartType typeContext) =>
      debugExpressionEnter("isExpression", expression, typeContext);

  void isExpressionExit(IsExpression expression, DartType inferredType) =>
      debugExpressionExit("isExpression", expression, inferredType);

  bool isNotExpressionEnter(Not expression, DartType typeContext) =>
      debugExpressionEnter("isNotExpression", expression, typeContext);

  void isNotExpressionExit(Not expression, DartType inferredType) =>
      debugExpressionExit("isNotExpression", expression, inferredType);

  bool listLiteralEnter(ListLiteral expression, DartType typeContext) =>
      debugExpressionEnter("listLiteral", expression, typeContext);

  void listLiteralExit(ListLiteral expression, DartType inferredType) =>
      debugExpressionExit("listLiteral", expression, inferredType);

  bool mapLiteralEnter(MapLiteral expression, DartType typeContext) =>
      debugExpressionEnter("mapLiteral", expression, typeContext);

  void mapLiteralExit(MapLiteral expression, DartType typeContext) =>
      debugExpressionExit("mapLiteral", expression, typeContext);

  bool methodInvocationEnter(
          MethodInvocation expression, DartType typeContext) =>
      debugExpressionEnter("methodInvocation", expression, typeContext);

  void methodInvocationExit(
          MethodInvocation expression, DartType inferredType) =>
      debugExpressionExit("methodInvocation", expression, inferredType);

  bool notEnter(Not expression, DartType typeContext) =>
      debugExpressionEnter("not", expression, typeContext);

  void notExit(Not expression, DartType inferredType) =>
      debugExpressionExit("not", expression, inferredType);

  bool nullLiteralEnter(NullLiteral expression, DartType typeContext) =>
      debugExpressionEnter("nullLiteral", expression, typeContext);

  void nullLiteralExit(NullLiteral expression, DartType inferredType) =>
      debugExpressionExit("nullLiteral", expression, inferredType);

  bool propertyAssignEnter(Expression expression, DartType typeContext) =>
      debugExpressionEnter("propertyAssign", expression, typeContext);

  void propertyAssignExit(Expression expression, DartType inferredType) =>
      debugExpressionExit("propertyAssign", expression, inferredType);

  bool propertyGetEnter(PropertyGet expression, DartType typeContext) =>
      debugExpressionEnter("propertyGet", expression, typeContext);

  void propertyGetExit(PropertyGet expression, DartType inferredType) =>
      debugExpressionExit("propertyGet", expression, inferredType);

  bool propertySetEnter(PropertySet expression, DartType typeContext) =>
      debugExpressionEnter("propertySet", expression, typeContext);

  void propertySetExit(PropertySet expression, DartType inferredType) =>
      debugExpressionExit("propertySet", expression, inferredType);

  void redirectingInitializerEnter(RedirectingInitializer initializer) =>
      debugInitializerEnter("redirectingInitializer", initializer);

  void redirectingInitializerExit(RedirectingInitializer initializer) =>
      debugInitializerExit("redirectingInitializer", initializer);

  void returnStatementEnter(ReturnStatement statement) =>
      debugStatementEnter('returnStatement', statement);

  void returnStatementExit(ReturnStatement statement) =>
      debugStatementExit('returnStatement', statement);

  bool staticAssignEnter(Expression expression, DartType typeContext) =>
      debugExpressionEnter("staticAssign", expression, typeContext);

  void staticAssignExit(Expression expression, DartType inferredType) =>
      debugExpressionExit("staticAssign", expression, inferredType);

  bool staticGetEnter(StaticGet expression, DartType typeContext) =>
      debugExpressionEnter("staticGet", expression, typeContext);

  void staticGetExit(StaticGet expression, DartType inferredType) =>
      debugExpressionExit("staticGet", expression, inferredType);

  bool staticInvocationEnter(
          StaticInvocation expression, DartType typeContext) =>
      debugExpressionEnter("staticInvocation", expression, typeContext);

  void staticInvocationExit(
          StaticInvocation expression, DartType inferredType) =>
      debugExpressionExit("staticInvocation", expression, inferredType);

  bool stringConcatenationEnter(
          StringConcatenation expression, DartType typeContext) =>
      debugExpressionEnter("stringConcatenation", expression, typeContext);

  void stringConcatenationExit(
          StringConcatenation expression, DartType inferredType) =>
      debugExpressionExit("stringConcatenation", expression, inferredType);

  bool stringLiteralEnter(StringLiteral expression, DartType typeContext) =>
      debugExpressionEnter("StringLiteral", expression, typeContext);

  void stringLiteralExit(StringLiteral expression, DartType inferredType) =>
      debugExpressionExit("StringLiteral", expression, inferredType);

  bool variableAssignEnter(Expression expression, DartType typeContext) =>
      debugExpressionEnter("variableAssign", expression, typeContext);

  void variableAssignExit(Expression expression, DartType inferredType) =>
      debugExpressionExit("variableAssign", expression, inferredType);

  void variableDeclarationEnter(VariableDeclaration statement) =>
      debugStatementEnter('variableDeclaration', statement);

  void variableDeclarationExit(VariableDeclaration statement) =>
      debugStatementExit('variableDeclaration', statement);

  bool variableGetEnter(VariableGet expression, DartType typeContext) =>
      debugExpressionEnter("variableGet", expression, typeContext);

  void variableGetExit(VariableGet expression, DartType inferredType) =>
      debugExpressionExit("variableGet", expression, inferredType);

  bool variableSetEnter(VariableSet expression, DartType typeContext) =>
      debugExpressionEnter("variableSet", expression, typeContext);

  void variableSetExit(VariableSet expression, DartType inferredType) =>
      debugExpressionExit("variableSet", expression, inferredType);

  void yieldStatementEnter(YieldStatement statement) =>
      debugStatementEnter('yieldStatement', statement);

  void yieldStatementExit(YieldStatement statement) =>
      debugStatementExit('yieldStatement', statement);
}
