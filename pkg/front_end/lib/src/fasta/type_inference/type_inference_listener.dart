// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' show DartType, FunctionType;

import 'package:kernel/type_algebra.dart' show Substitution;

/// Base class for [TypeInferenceListener] that defines the API for debugging.
///
/// By default no debug info is printed.  To enable debug printing, mix in
/// [TypeInferenceDebugging].
class TypeInferenceBase<Location> {
  void genericExpressionEnter(
      String expressionType, Location location, DartType typeContext) {}

  void genericExpressionExit(
      String expressionType, Location location, DartType inferredType) {}

  void genericInitializerEnter(String initializerType, Location location) {}

  void genericInitializerExit(String initializerType, Location location) {}

  void genericStatementEnter(String statementType, Location location) {}

  void genericStatementExit(String statementType, Location location) {}
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
class TypeInferenceListener<Location, Declaration, Reference, PrefixInfo>
    extends TypeInferenceBase<Location> {
  void asExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("asExpression", location, typeContext);

  void asExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("asExpression", location, inferredType);

  void assertInitializerEnter(Location location) =>
      genericInitializerEnter("assertInitializer", location);

  void assertInitializerExit(Location location) =>
      genericInitializerExit("assertInitializer", location);

  void assertStatementEnter(Location location) =>
      genericStatementEnter('assertStatement', location);

  void assertStatementExit(Location location) =>
      genericStatementExit('assertStatement', location);

  void awaitExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("awaitExpression", location, typeContext);

  void awaitExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("awaitExpression", location, inferredType);

  void blockEnter(Location location) =>
      genericStatementEnter('block', location);

  void blockExit(Location location) => genericStatementExit('block', location);

  void boolLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("boolLiteral", location, typeContext);

  void boolLiteralExit(Location location, DartType inferredType) =>
      genericExpressionExit("boolLiteral", location, inferredType);

  void breakStatementEnter(Location location) =>
      genericStatementEnter('breakStatement', location);

  void breakStatementExit(Location location) =>
      genericStatementExit('breakStatement', location);

  void cascadeExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("cascade", location, typeContext);

  void cascadeExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("cascade", location, inferredType);

  void catchStatementEnter(
      Location location,
      DartType guardType,
      Location exceptionLocation,
      DartType exceptionType,
      Location stackTraceLocation,
      DartType stackTraceType) {}

  void catchStatementExit(Location location) {}

  void conditionalExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("conditionalExpression", location, typeContext);

  void conditionalExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("conditionalExpression", location, inferredType);

  void constructorInvocationEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("constructorInvocation", location, typeContext);

  void constructorInvocationExit(Location location, Reference expressionTarget,
          DartType inferredType) =>
      genericExpressionExit("constructorInvocation", location, inferredType);

  void continueSwitchStatementEnter(Location location) =>
      genericStatementEnter('continueSwitchStatement', location);

  void continueSwitchStatementExit(Location location) =>
      genericStatementExit('continueSwitchStatement', location);

  void deferredCheckEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("deferredCheck", location, typeContext);

  void deferredCheckExit(Location location, DartType inferredType) =>
      genericExpressionExit("deferredCheck", location, inferredType);

  void doStatementEnter(Location location) =>
      genericStatementEnter("doStatement", location);

  void doStatementExit(Location location) =>
      genericStatementExit("doStatement", location);

  void doubleLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("doubleLiteral", location, typeContext);

  void doubleLiteralExit(Location location, DartType inferredType) =>
      genericExpressionExit("doubleLiteral", location, inferredType);

  void dryRunEnter(Location location) =>
      genericExpressionEnter("dryRun", location, null);

  void dryRunExit(Location location) =>
      genericExpressionExit("dryRun", location, null);

  void expressionStatementEnter(Location location) =>
      genericStatementEnter('expressionStatement', location);

  void expressionStatementExit(Location location) =>
      genericStatementExit('expressionStatement', location);

  void fieldInitializerEnter(Location location, Reference initializerField) =>
      genericInitializerEnter("fieldInitializer", location);

  void fieldInitializerExit(Location location) =>
      genericInitializerExit("fieldInitializer", location);

  void forInStatementEnter(
          Location location,
          Location variableLocation,
          Location writeLocation,
          DartType writeVariableType,
          Declaration writeVariable,
          Reference writeTarget) =>
      genericStatementEnter('forInStatement', location);

  void forInStatementExit(
          Location location, bool variablePresent, DartType variableType) =>
      genericStatementExit('forInStatement', location);

  void forStatementEnter(Location location) =>
      genericStatementEnter('forStatement', location);

  void forStatementExit(Location location) =>
      genericStatementExit('forStatement', location);

  void functionDeclarationEnter(Location location) =>
      genericStatementEnter('functionDeclaration', location);

  void functionDeclarationExit(Location location, FunctionType inferredType) =>
      genericStatementExit('functionDeclaration', location);

  void functionExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("functionExpression", location, typeContext);

  void functionExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("functionExpression", location, inferredType);

  void ifNullBeforeRhs(Location location) {}

  void ifNullEnter(Location location, DartType typeContext) =>
      genericExpressionEnter('ifNull', location, typeContext);

  void ifNullExit(Location location, DartType inferredType) =>
      genericExpressionExit('ifNull', location, inferredType);

  void ifStatementEnter(Location location) =>
      genericStatementEnter('ifStatement', location);

  void ifStatementExit(Location location) =>
      genericStatementExit('ifStatement', location);

  void indexAssignAfterReceiver(Location location, DartType typeContext) {}

  void indexAssignEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("indexAssign", location, typeContext);

  void indexAssignExit(Location location, Reference writeMember,
          Reference combiner, DartType inferredType) =>
      genericExpressionExit("indexAssign", location, inferredType);

  void intLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("intLiteral", location, typeContext);

  void intLiteralExit(Location location, DartType inferredType) =>
      genericExpressionExit("intLiteral", location, inferredType);

  void invalidInitializerEnter(Location location) =>
      genericInitializerEnter("invalidInitializer", location);

  void invalidInitializerExit(Location location) =>
      genericInitializerExit("invalidInitializer", location);

  void isExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("isExpression", location, typeContext);

  void isExpressionExit(
          Location location, DartType testedType, DartType inferredType) =>
      genericExpressionExit("isExpression", location, inferredType);

  void isNotExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("isNotExpression", location, typeContext);

  void isNotExpressionExit(
          Location location, DartType type, DartType inferredType) =>
      genericExpressionExit("isNotExpression", location, inferredType);

  void labeledStatementEnter(Location location) =>
      genericStatementEnter('labeledStatement', location);

  void labeledStatementExit(Location location) =>
      genericStatementExit('labeledStatement', location);

  void listLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("listLiteral", location, typeContext);

  void listLiteralExit(Location location, DartType inferredType) =>
      genericExpressionExit("listLiteral", location, inferredType);

  void logicalExpressionBeforeRhs(Location location) {}

  void logicalExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("logicalExpression", location, typeContext);

  void logicalExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("logicalExpression", location, inferredType);

  void mapLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("mapLiteral", location, typeContext);

  void mapLiteralExit(Location location, DartType typeContext) =>
      genericExpressionExit("mapLiteral", location, typeContext);

  void methodInvocationBeforeArgs(Location location, bool isImplicitCall) {}

  void methodInvocationEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("methodInvocation", location, typeContext);

  void methodInvocationExit(
          Location resultOffset,
          List<DartType> argumentsTypes,
          bool isImplicitCall,
          Reference interfaceMember,
          FunctionType calleeType,
          Substitution substitution,
          DartType inferredType) =>
      genericExpressionExit("methodInvocation", resultOffset, inferredType);

  void methodInvocationExitCall(
          Location resultOffset,
          List<DartType> argumentsTypes,
          bool isImplicitCall,
          FunctionType calleeType,
          Substitution substitution,
          DartType inferredType) =>
      genericExpressionExit("methodInvocation", resultOffset, inferredType);

  void namedFunctionExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("namedFunctionExpression", location, typeContext);

  void namedFunctionExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("namedFunctionExpression", location, inferredType);

  void notEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("not", location, typeContext);

  void notExit(Location location, DartType inferredType) =>
      genericExpressionExit("not", location, inferredType);

  void nullLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("nullLiteral", location, typeContext);

  void nullLiteralExit(
          Location location, bool isSynthetic, DartType inferredType) =>
      genericExpressionExit("nullLiteral", location, inferredType);

  void propertyAssignEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("propertyAssign", location, typeContext);

  void propertyAssignExit(Location location, Reference writeMember,
          DartType writeContext, Reference combiner, DartType inferredType) =>
      genericExpressionExit("propertyAssign", location, inferredType);

  void propertyGetEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("propertyGet", location, typeContext);

  void propertyGetExit(
          Location location, Reference member, DartType inferredType) =>
      genericExpressionExit("propertyGet", location, inferredType);

  void propertyGetExitCall(Location location, DartType inferredType) =>
      genericExpressionExit("propertyGet", location, inferredType);

  void propertySetEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("propertySet", location, typeContext);

  void propertySetExit(Location location, DartType inferredType) =>
      genericExpressionExit("propertySet", location, inferredType);

  void redirectingInitializerEnter(
          Location location, Reference initializerTarget) =>
      genericInitializerEnter("redirectingInitializer", location);

  void redirectingInitializerExit(Location location) =>
      genericInitializerExit("redirectingInitializer", location);

  void rethrowEnter(Location location, DartType typeContext) =>
      genericExpressionEnter('rethrow', location, typeContext);

  void rethrowExit(Location location, DartType inferredType) =>
      genericExpressionExit('rethrow', location, inferredType);

  void returnStatementEnter(Location location) =>
      genericStatementEnter('returnStatement', location);

  void returnStatementExit(Location location) =>
      genericStatementExit('returnStatement', location);

  void staticAssignEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("staticAssign", location, typeContext);

  void staticAssignExit(Location location, Reference writeMember,
          DartType writeContext, Reference combiner, DartType inferredType) =>
      genericExpressionExit("staticAssign", location, inferredType);

  void staticGetEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("staticGet", location, typeContext);

  void staticGetExit(Location location, Reference expressionTarget,
          DartType inferredType) =>
      genericExpressionExit("staticGet", location, inferredType);

  void staticInvocationEnter(Location location,
          Location expressionArgumentsLocation, DartType typeContext) =>
      genericExpressionEnter("staticInvocation", location, typeContext);

  void staticInvocationExit(
          Location location,
          Reference expressionTarget,
          List<DartType> expressionArgumentsTypes,
          FunctionType calleeType,
          Substitution substitution,
          DartType inferredType) =>
      genericExpressionExit("staticInvocation", location, inferredType);

  void stringConcatenationEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("stringConcatenation", location, typeContext);

  void stringConcatenationExit(Location location, DartType inferredType) =>
      genericExpressionExit("stringConcatenation", location, inferredType);

  void stringLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("StringLiteral", location, typeContext);

  void stringLiteralExit(Location location, DartType inferredType) =>
      genericExpressionExit("StringLiteral", location, inferredType);

  void superInitializerEnter(Location location) =>
      genericInitializerEnter("superInitializer", location);

  void superInitializerExit(Location location) =>
      genericInitializerExit("superInitializer", location);

  void switchStatementEnter(Location location) =>
      genericStatementEnter('switchStatement', location);

  void switchStatementExit(Location location) =>
      genericStatementExit('switchStatement', location);

  void symbolLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("symbolLiteral", location, typeContext);

  void symbolLiteralExit(Location location, DartType inferredType) =>
      genericExpressionExit("symbolLiteral", location, inferredType);

  void thisExpressionEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("thisExpression", location, typeContext);

  void thisExpressionExit(Location location, DartType inferredType) =>
      genericExpressionExit("thisExpression", location, inferredType);

  void throwEnter(Location location, DartType typeContext) =>
      genericExpressionEnter('throw', location, typeContext);

  void throwExit(Location location, DartType inferredType) =>
      genericExpressionExit('throw', location, inferredType);

  void tryCatchEnter(Location location) =>
      genericStatementEnter('tryCatch', location);

  void tryCatchExit(Location location) =>
      genericStatementExit('tryCatch', location);

  void tryFinallyEnter(Location location) =>
      genericStatementEnter('tryFinally', location);

  void tryFinallyExit(Location location) =>
      genericStatementExit('tryFinally', location);

  void typeLiteralEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("typeLiteral", location, typeContext);

  void typeLiteralExit(
          Location location, Reference expressionType, DartType inferredType) =>
      genericExpressionExit("typeLiteral", location, inferredType);

  void variableAssignEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("variableAssign", location, typeContext);

  void variableAssignExit(
          Location location,
          DartType writeContext,
          Declaration writeVariable,
          Reference combiner,
          DartType inferredType) =>
      genericExpressionExit("variableAssign", location, inferredType);

  void variableDeclarationEnter(Location location) =>
      genericStatementEnter('variableDeclaration', location);

  void variableDeclarationExit(
          Location location, DartType statementType, DartType inferredType) =>
      genericStatementExit('variableDeclaration', location);

  void variableGetEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("variableGet", location, typeContext);

  void variableGetExit(Location location, bool isInCascade,
          Declaration expressionVariable, DartType inferredType) =>
      genericExpressionExit("variableGet", location, inferredType);

  void variableSetEnter(Location location, DartType typeContext) =>
      genericExpressionEnter("variableSet", location, typeContext);

  void variableSetExit(Location location, DartType inferredType) =>
      genericExpressionExit("variableSet", location, inferredType);

  void whileStatementEnter(Location location) =>
      genericStatementEnter("whileStatement", location);

  void whileStatementExit(Location location) =>
      genericStatementExit("whileStatement", location);

  void yieldStatementEnter(Location location) =>
      genericStatementEnter('yieldStatement', location);

  void yieldStatementExit(Location location) =>
      genericStatementExit('yieldStatement', location);

  void storePrefixInfo(Location location, PrefixInfo prefixInfo) {}

  void storeClassReference(
      Location location, Reference reference, DartType rawType) {}
}
