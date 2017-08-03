// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:kernel/ast.dart';

/// Base class for [TypeInferenceListener] that defines the API for debugging.
///
/// By default no debug info is printed.  To enable debug printing, mix in
/// [TypeInferenceDebugging].
class TypeInferenceBase {
  void debugDependency(AccessorNode accessorNode) {}

  bool genericExpressionEnter(
      String expressionType, Expression expression, DartType typeContext) {
    return false;
  }

  void genericExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {}

  void genericInitializerEnter(
      String initializerType, Initializer initializer) {}

  void genericInitializerExit(
      String initializerType, Initializer initializer) {}

  void genericStatementEnter(String statementType, Statement statement) {}

  void genericStatementExit(String statementType, Statement statement) {}
}

/// Mixin which can be applied to [TypeInferenceListener] to cause debug info to
/// be printed.
class TypeInferenceDebugging implements TypeInferenceBase {
  void debugDependency(AccessorNode accessorNode) {
    print('Dependency $accessorNode');
  }

  bool genericExpressionEnter(
      String expressionType, Expression expression, DartType typeContext) {
    print('Enter $expressionType($expression) (context=$typeContext)');
    return true;
  }

  void genericExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {
    print('Exit $expressionType($expression) (type=$inferredType)');
  }

  void genericInitializerEnter(
      String initializerType, Initializer initializer) {
    print('Enter $initializerType($initializer)');
  }

  void genericInitializerExit(String initializerType, Initializer initializer) {
    print('Exit $initializerType($initializer)');
  }

  void genericStatementEnter(String statementType, Statement statement) {
    print('Enter $statementType($statement)');
  }

  void genericStatementExit(String statementType, Statement statement) {
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
      genericExpressionEnter("asExpression", expression, typeContext);

  void asExpressionExit(AsExpression expression, DartType inferredType) =>
      genericExpressionExit("asExpression", expression, inferredType);

  void assertStatementEnter(AssertStatement statement) =>
      genericStatementEnter('assertStatement', statement);

  void assertStatementExit(AssertStatement statement) =>
      genericStatementExit('assertStatement', statement);

  bool awaitExpressionEnter(AwaitExpression expression, DartType typeContext) =>
      genericExpressionEnter("awaitExpression", expression, typeContext);

  void awaitExpressionExit(AwaitExpression expression, DartType inferredType) =>
      genericExpressionExit("awaitExpression", expression, inferredType);

  void blockEnter(Block statement) => genericStatementEnter('block', statement);

  void blockExit(Block statement) => genericStatementExit('block', statement);

  bool boolLiteralEnter(BoolLiteral expression, DartType typeContext) =>
      genericExpressionEnter("boolLiteral", expression, typeContext);

  void boolLiteralExit(BoolLiteral expression, DartType inferredType) =>
      genericExpressionExit("boolLiteral", expression, inferredType);

  void breakStatementEnter(BreakStatement statement) =>
      genericStatementEnter('breakStatement', statement);

  void breakStatementExit(BreakStatement statement) =>
      genericStatementExit('breakStatement', statement);

  bool cascadeExpressionEnter(Let expression, DartType typeContext) =>
      genericExpressionEnter("cascade", expression, typeContext);

  void cascadeExpressionExit(Let expression, DartType inferredType) =>
      genericExpressionExit("cascade", expression, inferredType);

  bool conditionalExpressionEnter(
          ConditionalExpression expression, DartType typeContext) =>
      genericExpressionEnter("conditionalExpression", expression, typeContext);

  void conditionalExpressionExit(
          ConditionalExpression expression, DartType inferredType) =>
      genericExpressionExit("conditionalExpression", expression, inferredType);

  bool constructorInvocationEnter(
          InvocationExpression expression, DartType typeContext) =>
      genericExpressionEnter("constructorInvocation", expression, typeContext);

  void constructorInvocationExit(
          InvocationExpression expression, DartType inferredType) =>
      genericExpressionExit("constructorInvocation", expression, inferredType);

  void continueSwitchStatementEnter(ContinueSwitchStatement statement) =>
      genericStatementEnter('continueSwitchStatement', statement);

  void continueSwitchStatementExit(ContinueSwitchStatement statement) =>
      genericStatementExit('continueSwitchStatement', statement);

  void doStatementEnter(DoStatement statement) =>
      genericStatementEnter("doStatement", statement);

  void doStatementExit(DoStatement statement) =>
      genericStatementExit("doStatement", statement);

  bool doubleLiteralEnter(DoubleLiteral expression, DartType typeContext) =>
      genericExpressionEnter("doubleLiteral", expression, typeContext);

  void doubleLiteralExit(DoubleLiteral expression, DartType inferredType) =>
      genericExpressionExit("doubleLiteral", expression, inferredType);

  void dryRunEnter(Expression expression) =>
      genericExpressionEnter("dryRun", expression, null);

  void dryRunExit(Expression expression) =>
      genericExpressionExit("dryRun", expression, null);

  void expressionStatementEnter(ExpressionStatement statement) =>
      genericStatementEnter('expressionStatement', statement);

  void expressionStatementExit(ExpressionStatement statement) =>
      genericStatementExit('expressionStatement', statement);

  void fieldInitializerEnter(FieldInitializer initializer) =>
      genericInitializerEnter("fieldInitializer", initializer);

  void fieldInitializerExit(FieldInitializer initializer) =>
      genericInitializerExit("fieldInitializer", initializer);

  void forInStatementEnter(ForInStatement statement) =>
      genericStatementEnter('forInStatement', statement);

  void forInStatementExit(ForInStatement statement) =>
      genericStatementExit('forInStatement', statement);

  void forStatementEnter(ForStatement statement) =>
      genericStatementEnter('forStatement', statement);

  void forStatementExit(ForStatement statement) =>
      genericStatementExit('forStatement', statement);

  void functionDeclarationEnter(FunctionDeclaration statement) =>
      genericStatementEnter('functionDeclaration', statement);

  void functionDeclarationExit(FunctionDeclaration statement) =>
      genericStatementExit('functionDeclaration', statement);

  bool functionExpressionEnter(
          FunctionExpression expression, DartType typeContext) =>
      genericExpressionEnter("functionExpression", expression, typeContext);

  void functionExpressionExit(
          FunctionExpression expression, DartType inferredType) =>
      genericExpressionExit("functionExpression", expression, inferredType);

  bool ifNullEnter(Expression expression, DartType typeContext) =>
      genericExpressionEnter('ifNull', expression, typeContext);

  void ifNullExit(Expression expression, DartType inferredType) =>
      genericExpressionExit('ifNull', expression, inferredType);

  void ifStatementEnter(IfStatement statement) =>
      genericStatementEnter('ifStatement', statement);

  void ifStatementExit(IfStatement statement) =>
      genericStatementExit('ifStatement', statement);

  bool indexAssignEnter(Expression expression, DartType typeContext) =>
      genericExpressionEnter("indexAssign", expression, typeContext);

  void indexAssignExit(Expression expression, DartType inferredType) =>
      genericExpressionExit("indexAssign", expression, inferredType);

  bool intLiteralEnter(IntLiteral expression, DartType typeContext) =>
      genericExpressionEnter("intLiteral", expression, typeContext);

  void intLiteralExit(IntLiteral expression, DartType inferredType) =>
      genericExpressionExit("intLiteral", expression, inferredType);

  bool isExpressionEnter(IsExpression expression, DartType typeContext) =>
      genericExpressionEnter("isExpression", expression, typeContext);

  void isExpressionExit(IsExpression expression, DartType inferredType) =>
      genericExpressionExit("isExpression", expression, inferredType);

  bool isNotExpressionEnter(Not expression, DartType typeContext) =>
      genericExpressionEnter("isNotExpression", expression, typeContext);

  void isNotExpressionExit(Not expression, DartType inferredType) =>
      genericExpressionExit("isNotExpression", expression, inferredType);

  void labeledStatementEnter(LabeledStatement statement) =>
      genericStatementEnter('labeledStatement', statement);

  void labeledStatementExit(LabeledStatement statement) =>
      genericStatementExit('labeledStatement', statement);

  bool listLiteralEnter(ListLiteral expression, DartType typeContext) =>
      genericExpressionEnter("listLiteral", expression, typeContext);

  void listLiteralExit(ListLiteral expression, DartType inferredType) =>
      genericExpressionExit("listLiteral", expression, inferredType);

  bool logicalExpressionEnter(
          LogicalExpression expression, DartType typeContext) =>
      genericExpressionEnter("logicalExpression", expression, typeContext);

  void logicalExpressionExit(
          LogicalExpression expression, DartType inferredType) =>
      genericExpressionExit("logicalExpression", expression, inferredType);

  bool mapLiteralEnter(MapLiteral expression, DartType typeContext) =>
      genericExpressionEnter("mapLiteral", expression, typeContext);

  void mapLiteralExit(MapLiteral expression, DartType typeContext) =>
      genericExpressionExit("mapLiteral", expression, typeContext);

  void methodInvocationBeforeArgs(Expression expression, bool isImplicitCall) {}

  bool methodInvocationEnter(Expression expression, DartType typeContext) =>
      genericExpressionEnter("methodInvocation", expression, typeContext);

  void methodInvocationExit(Expression expression, Arguments arguments,
          bool isImplicitCall, DartType inferredType) =>
      genericExpressionExit("methodInvocation", expression, inferredType);

  bool notEnter(Not expression, DartType typeContext) =>
      genericExpressionEnter("not", expression, typeContext);

  void notExit(Not expression, DartType inferredType) =>
      genericExpressionExit("not", expression, inferredType);

  bool nullLiteralEnter(NullLiteral expression, DartType typeContext) =>
      genericExpressionEnter("nullLiteral", expression, typeContext);

  void nullLiteralExit(NullLiteral expression, DartType inferredType) =>
      genericExpressionExit("nullLiteral", expression, inferredType);

  bool propertyAssignEnter(Expression expression, DartType typeContext) =>
      genericExpressionEnter("propertyAssign", expression, typeContext);

  void propertyAssignExit(Expression expression, DartType inferredType) =>
      genericExpressionExit("propertyAssign", expression, inferredType);

  bool propertyGetEnter(Expression expression, DartType typeContext) =>
      genericExpressionEnter("propertyGet", expression, typeContext);

  void propertyGetExit(Expression expression, DartType inferredType) =>
      genericExpressionExit("propertyGet", expression, inferredType);

  bool propertySetEnter(PropertySet expression, DartType typeContext) =>
      genericExpressionEnter("propertySet", expression, typeContext);

  void propertySetExit(PropertySet expression, DartType inferredType) =>
      genericExpressionExit("propertySet", expression, inferredType);

  void recordDependency(AccessorNode accessorNode) =>
      debugDependency(accessorNode);

  void redirectingInitializerEnter(RedirectingInitializer initializer) =>
      genericInitializerEnter("redirectingInitializer", initializer);

  void redirectingInitializerExit(RedirectingInitializer initializer) =>
      genericInitializerExit("redirectingInitializer", initializer);

  bool rethrowEnter(Rethrow expression, DartType typeContext) =>
      genericExpressionEnter('rethrow', expression, typeContext);

  void rethrowExit(Rethrow expression, DartType inferredType) =>
      genericExpressionExit('rethrow', expression, inferredType);

  void returnStatementEnter(ReturnStatement statement) =>
      genericStatementEnter('returnStatement', statement);

  void returnStatementExit(ReturnStatement statement) =>
      genericStatementExit('returnStatement', statement);

  bool staticAssignEnter(Expression expression, DartType typeContext) =>
      genericExpressionEnter("staticAssign", expression, typeContext);

  void staticAssignExit(Expression expression, DartType inferredType) =>
      genericExpressionExit("staticAssign", expression, inferredType);

  bool staticGetEnter(StaticGet expression, DartType typeContext) =>
      genericExpressionEnter("staticGet", expression, typeContext);

  void staticGetExit(StaticGet expression, DartType inferredType) =>
      genericExpressionExit("staticGet", expression, inferredType);

  bool staticInvocationEnter(
          StaticInvocation expression, DartType typeContext) =>
      genericExpressionEnter("staticInvocation", expression, typeContext);

  void staticInvocationExit(
          StaticInvocation expression, DartType inferredType) =>
      genericExpressionExit("staticInvocation", expression, inferredType);

  bool stringConcatenationEnter(
          StringConcatenation expression, DartType typeContext) =>
      genericExpressionEnter("stringConcatenation", expression, typeContext);

  void stringConcatenationExit(
          StringConcatenation expression, DartType inferredType) =>
      genericExpressionExit("stringConcatenation", expression, inferredType);

  bool stringLiteralEnter(StringLiteral expression, DartType typeContext) =>
      genericExpressionEnter("StringLiteral", expression, typeContext);

  void stringLiteralExit(StringLiteral expression, DartType inferredType) =>
      genericExpressionExit("StringLiteral", expression, inferredType);

  void switchStatementEnter(SwitchStatement statement) =>
      genericStatementEnter('switchStatement', statement);

  void switchStatementExit(SwitchStatement statement) =>
      genericStatementExit('switchStatement', statement);

  bool symbolLiteralEnter(SymbolLiteral expression, DartType typeContext) =>
      genericExpressionEnter("symbolLiteral", expression, typeContext);

  void symbolLiteralExit(SymbolLiteral expression, DartType inferredType) =>
      genericExpressionExit("symbolLiteral", expression, inferredType);

  bool thisExpressionEnter(ThisExpression expression, DartType typeContext) =>
      genericExpressionEnter("thisExpression", expression, typeContext);

  void thisExpressionExit(ThisExpression expression, DartType inferredType) =>
      genericExpressionExit("thisExpression", expression, inferredType);

  bool throwEnter(Throw expression, DartType typeContext) =>
      genericExpressionEnter('throw', expression, typeContext);

  void throwExit(Throw expression, DartType inferredType) =>
      genericExpressionExit('throw', expression, inferredType);

  void tryCatchEnter(TryCatch statement) =>
      genericStatementEnter('tryCatch', statement);

  void tryCatchExit(TryCatch statement) =>
      genericStatementExit('tryCatch', statement);

  void tryFinallyEnter(TryFinally statement) =>
      genericStatementEnter('tryFinally', statement);

  void tryFinallyExit(TryFinally statement) =>
      genericStatementExit('tryFinally', statement);

  bool typeLiteralEnter(TypeLiteral expression, DartType typeContext) =>
      genericExpressionEnter("typeLiteral", expression, typeContext);

  void typeLiteralExit(TypeLiteral expression, DartType inferredType) =>
      genericExpressionExit("typeLiteral", expression, inferredType);

  bool variableAssignEnter(Expression expression, DartType typeContext) =>
      genericExpressionEnter("variableAssign", expression, typeContext);

  void variableAssignExit(Expression expression, DartType inferredType) =>
      genericExpressionExit("variableAssign", expression, inferredType);

  void variableDeclarationEnter(VariableDeclaration statement) =>
      genericStatementEnter('variableDeclaration', statement);

  void variableDeclarationExit(VariableDeclaration statement) =>
      genericStatementExit('variableDeclaration', statement);

  bool variableGetEnter(VariableGet expression, DartType typeContext) =>
      genericExpressionEnter("variableGet", expression, typeContext);

  void variableGetExit(VariableGet expression, DartType inferredType) =>
      genericExpressionExit("variableGet", expression, inferredType);

  bool variableSetEnter(VariableSet expression, DartType typeContext) =>
      genericExpressionEnter("variableSet", expression, typeContext);

  void variableSetExit(VariableSet expression, DartType inferredType) =>
      genericExpressionExit("variableSet", expression, inferredType);

  void whileStatementEnter(WhileStatement statement) =>
      genericStatementEnter("whileStatement", statement);

  void whileStatementExit(WhileStatement statement) =>
      genericStatementExit("whileStatement", statement);

  void yieldStatementEnter(YieldStatement statement) =>
      genericStatementEnter('yieldStatement', statement);

  void yieldStatementExit(YieldStatement statement) =>
      genericStatementExit('yieldStatement', statement);
}
