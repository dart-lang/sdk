// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' show Catch, DartType, FunctionType, Node;

import 'package:kernel/type_algebra.dart' show Substitution;

import '../kernel/kernel_shadow_ast.dart'
    show ExpressionJudgment, InitializerJudgment, StatementJudgment;

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
abstract class TypeInferenceListener<Location, Declaration, Reference,
    PrefixInfo> {
  void asExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void assertInitializer(InitializerJudgment judgment, Location location);

  void assertStatement(StatementJudgment judgment, Location location);

  void awaitExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void block(StatementJudgment judgment, Location location);

  void boolLiteral(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void breakStatement(StatementJudgment judgment, Location location);

  void cascadeExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void catchStatement(
      Catch judgment,
      Location location,
      DartType guardType,
      Location exceptionLocation,
      DartType exceptionType,
      Location stackTraceLocation,
      DartType stackTraceType);

  void conditionalExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void constructorInvocation(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType);

  void continueSwitchStatement(StatementJudgment judgment, Location location);

  void deferredCheck(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void doStatement(StatementJudgment judgment, Location location);

  void doubleLiteral(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void expressionStatement(StatementJudgment judgment, Location location);

  void fieldInitializer(InitializerJudgment judgment, Location location,
      Reference initializerField);

  void forInStatement(
      StatementJudgment judgment,
      Location location,
      Location variableLocation,
      DartType variableType,
      Location writeLocation,
      DartType writeVariableType,
      Declaration writeVariable,
      Reference writeTarget);

  void forStatement(StatementJudgment judgment, Location location);

  void functionDeclaration(
      StatementJudgment judgment, Location location, FunctionType inferredType);

  void functionExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void ifNull(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void ifStatement(StatementJudgment judgment, Location location);

  void indexAssign(ExpressionJudgment judgment, Location location,
      Reference writeMember, Reference combiner, DartType inferredType);

  void intLiteral(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void invalidInitializer(InitializerJudgment judgment, Location location);

  void isExpression(ExpressionJudgment judgment, Location location,
      DartType testedType, DartType inferredType);

  void isNotExpression(ExpressionJudgment judgment, Location location,
      DartType type, DartType inferredType);

  void labeledStatement(StatementJudgment judgment, Location location);

  void listLiteral(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void logicalExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void mapLiteral(
      ExpressionJudgment judgment, Location location, DartType typeContext);

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

  void namedFunctionExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void not(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void nullLiteral(ExpressionJudgment judgment, Location location,
      bool isSynthetic, DartType inferredType);

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

  void redirectingInitializer(InitializerJudgment judgment, Location location,
      Reference initializerTarget);

  void rethrow_(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void returnStatement(StatementJudgment judgment, Location location);

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

  void stringLiteral(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void superInitializer(InitializerJudgment judgment, Location location);

  void switchStatement(StatementJudgment judgment, Location location);

  void symbolLiteral(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void thisExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void throw_(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void tryCatch(StatementJudgment judgment, Location location);

  void tryFinally(StatementJudgment judgment, Location location);

  void typeLiteral(ExpressionJudgment judgment, Location location,
      Reference expressionType, DartType inferredType);

  void variableAssign(
      ExpressionJudgment judgment,
      Location location,
      DartType writeContext,
      Declaration writeVariable,
      Reference combiner,
      DartType inferredType);

  void variableDeclaration(StatementJudgment judgment, Location location,
      DartType statementType, DartType inferredType);

  void variableGet(ExpressionJudgment judgment, Location location,
      bool isInCascade, Declaration expressionVariable, DartType inferredType);

  void variableSet(
      ExpressionJudgment judgment, Location location, DartType inferredType);

  void whileStatement(StatementJudgment judgment, Location location);

  void yieldStatement(StatementJudgment judgment, Location location);

  void storePrefixInfo(Location location, PrefixInfo prefixInfo);

  void storeClassReference(
      Location location, Reference reference, DartType rawType);
}

/// Kernel implementation of TypeInferenceListener; does nothing.
///
/// TODO(paulberry): fuse this with KernelFactory.
class KernelTypeInferenceListener
    implements TypeInferenceListener<int, int, Node, int> {
  @override
  void asExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void assertInitializer(InitializerJudgment judgment, location) {}

  @override
  void assertStatement(StatementJudgment judgment, location) {}

  @override
  void awaitExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void block(StatementJudgment judgment, location) {}

  @override
  void boolLiteral(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void breakStatement(StatementJudgment judgment, location) {}

  @override
  void cascadeExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void catchStatement(
      Catch judgment,
      location,
      DartType guardType,
      exceptionLocation,
      DartType exceptionType,
      stackTraceLocation,
      DartType stackTraceType) {}

  @override
  void conditionalExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void constructorInvocation(ExpressionJudgment judgment, location,
      expressionTarget, DartType inferredType) {}

  @override
  void continueSwitchStatement(StatementJudgment judgment, location) {}

  @override
  void deferredCheck(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void doStatement(StatementJudgment judgment, location) {}

  @override
  void doubleLiteral(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void expressionStatement(StatementJudgment judgment, location) {}

  @override
  void fieldInitializer(
      InitializerJudgment judgment, location, initializerField) {}

  @override
  void forInStatement(
      StatementJudgment judgment,
      location,
      variableLocation,
      DartType variableType,
      writeLocation,
      DartType writeVariableType,
      writeVariable,
      writeTarget) {}

  @override
  void forStatement(StatementJudgment judgment, location) {}

  @override
  void functionDeclaration(
      StatementJudgment judgment, location, FunctionType inferredType) {}

  @override
  void functionExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void ifNull(ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void ifStatement(StatementJudgment judgment, location) {}

  @override
  void indexAssign(ExpressionJudgment judgment, location, writeMember, combiner,
      DartType inferredType) {}

  @override
  void intLiteral(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void invalidInitializer(InitializerJudgment judgment, location) {}

  @override
  void isExpression(ExpressionJudgment judgment, location, DartType testedType,
      DartType inferredType) {}

  @override
  void isNotExpression(ExpressionJudgment judgment, location, DartType type,
      DartType inferredType) {}

  @override
  void labeledStatement(StatementJudgment judgment, location) {}

  @override
  void listLiteral(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void logicalExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void mapLiteral(
      ExpressionJudgment judgment, location, DartType typeContext) {}

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
  void namedFunctionExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void not(ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void nullLiteral(ExpressionJudgment judgment, location, bool isSynthetic,
      DartType inferredType) {}

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
      InitializerJudgment judgment, location, initializerTarget) {}

  @override
  void rethrow_(ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void returnStatement(StatementJudgment judgment, location) {}

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
  void stringLiteral(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void superInitializer(InitializerJudgment judgment, location) {}

  @override
  void switchStatement(StatementJudgment judgment, location) {}

  @override
  void symbolLiteral(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void thisExpression(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void throw_(ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void tryCatch(StatementJudgment judgment, location) {}

  @override
  void tryFinally(StatementJudgment judgment, location) {}

  @override
  void typeLiteral(ExpressionJudgment judgment, location, expressionType,
      DartType inferredType) {}

  @override
  void variableAssign(ExpressionJudgment judgment, location,
      DartType writeContext, writeVariable, combiner, DartType inferredType) {}

  @override
  void variableDeclaration(StatementJudgment judgment, location,
      DartType statementType, DartType inferredType) {}

  @override
  void variableGet(ExpressionJudgment judgment, location, bool isInCascade,
      expressionVariable, DartType inferredType) {}

  @override
  void variableSet(
      ExpressionJudgment judgment, location, DartType inferredType) {}

  @override
  void whileStatement(StatementJudgment judgment, location) {}

  @override
  void yieldStatement(StatementJudgment judgment, location) {}
}
