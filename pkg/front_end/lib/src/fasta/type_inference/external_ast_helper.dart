// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper library for creating external AST nodes during inference.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../names.dart';
import 'inference_results.dart';
import 'inference_visitor_base.dart';
import 'object_access_target.dart';

/// Creates an invocation of the [target] constructor with the given
/// [arguments].
ConstructorInvocation createConstructorInvocation(
    Constructor target, Arguments arguments,
    {required int fileOffset}) {
  return new ConstructorInvocation(target, arguments)..fileOffset = fileOffset;
}

/// Creates a static invocation of [target] with the given arguments.
StaticInvocation createStaticInvocation(Procedure target, Arguments arguments,
    {required int fileOffset}) {
  return new StaticInvocation(target, arguments)..fileOffset = fileOffset;
}

/// Creates a statically resolved instance invocation of the operator
/// [operatorName] on [left] of type [leftType] with argument [right]. For
/// instance for creating `left + right`.
InstanceInvocation createOperatorInvocation(InferenceVisitorBase base,
    DartType leftType, Expression left, Name operatorName, Expression right,
    {required int fileOffset}) {
  ObjectAccessTarget target = base.findInterfaceMember(
      leftType, operatorName, fileOffset,
      callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
  return new InstanceInvocation(InstanceAccessKind.Instance, left, operatorName,
      createArguments([right], fileOffset: fileOffset),
      functionType: target.getFunctionType(base),
      interfaceTarget: target.member as Procedure)
    ..fileOffset = fileOffset;
}

/// Creates a statically resolved getter/field access of [name] on [receiver] of
/// type [receiverType].
InstanceGet createInstanceGet(InferenceVisitorBase base, DartType receiverType,
    Expression receiver, Name name,
    {required int fileOffset}) {
  ObjectAccessTarget target = base.findInterfaceMember(
      receiverType, name, fileOffset,
      callSiteAccessKind: CallSiteAccessKind.getterInvocation);
  Member? member = target.member;
  assert(member is Field || member is Procedure && member.isGetter);
  return new InstanceGet(InstanceAccessKind.Instance, receiver, name,
      resultType: target.getGetterType(base), interfaceTarget: member!)
    ..fileOffset = fileOffset;
}

/// Creates a statically resolved method invocation of [name] on [receiver] of
/// type [receiverType] with the given [positionalArguments].
InstanceInvocation createInstanceInvocation(
    InferenceVisitorBase base,
    DartType receiverType,
    Expression receiver,
    Name name,
    List<Expression> positionalArguments,
    {required int fileOffset}) {
  ObjectAccessTarget target = base.findInterfaceMember(
      receiverType, name, fileOffset,
      callSiteAccessKind: CallSiteAccessKind.methodInvocation);
  return new InstanceInvocation(InstanceAccessKind.Instance, receiver, name,
      createArguments(positionalArguments, fileOffset: fileOffset),
      functionType: target.getFunctionType(base),
      interfaceTarget: target.member as Procedure)
    ..fileOffset = fileOffset;
}

/// Creates a call to `==` on [left] of type [leftType] with argument [right].
EqualsCall createEqualsCall(InferenceVisitorBase base, DartType leftType,
    Expression left, Expression right,
    {required int fileOffset}) {
  ObjectAccessTarget target = base.findInterfaceMember(
      leftType, equalsName, fileOffset,
      callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
  return new EqualsCall(left, right,
      functionType: target.getFunctionType(base),
      interfaceTarget: target.member as Procedure)
    ..fileOffset = fileOffset;
}

/// Creates a `== null` test on [expression].
EqualsNull createEqualsNull(Expression expression, {required int fileOffset}) {
  return new EqualsNull(expression)..fileOffset = fileOffset;
}

/// Creates a boolean literal of [value].
BoolLiteral createBoolLiteral(bool value, {required int fileOffset}) {
  return new BoolLiteral(value)..fileOffset = fileOffset;
}

/// Creates an integer literal of [value].
Expression createIntLiteral(CoreTypes coreTypes, int value,
    {required int fileOffset}) {
  if (value < 0) {
    /// The web backends need this to be encoded as a unary minus on the
    /// positive value.
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        new IntLiteral(-value)..fileOffset = fileOffset,
        unaryMinusName,
        new Arguments([])..fileOffset = fileOffset,
        interfaceTarget: coreTypes.intUnaryMinus,
        functionType: coreTypes.intUnaryMinus.getterType as FunctionType)
      ..fileOffset = fileOffset;
  } else {
    return new IntLiteral(value)..fileOffset = fileOffset;
  }
}

/// Creates a string literal of [value].
StringLiteral createStringLiteral(String value, {required int fileOffset}) {
  return new StringLiteral(value)..fileOffset = fileOffset;
}

/// Creates a null literal.
NullLiteral createNullLiteral({required int fileOffset}) {
  return new NullLiteral()..fileOffset = fileOffset;
}

/// Creates a conditional expression of the [condition] and the [then] and
/// [otherwise] branches with the given [staticType] of the resulting
/// expression.
ConditionalExpression createConditionalExpression(
    Expression condition, Expression then, Expression otherwise,
    {required DartType staticType, required int fileOffset}) {
  return new ConditionalExpression(condition, then, otherwise, staticType)
    ..fileOffset = fileOffset;
}

/// Creates a [Let] of [variable] with the given [body] using
/// `variable.fileOffset` as the file offset for the let.
Let createLet(VariableDeclaration variable, Expression body) {
  return new Let(variable, body)..fileOffset = variable.fileOffset;
}

/// Creates a [Let] with the [effect] as the variable initializer and the
/// [result] as the body of the [Let] expression and using
/// `effect.fileOffset` as the file offset for the let.
Let createLetEffect({required Expression effect, required Expression result}) {
  return new Let(createVariableCache(effect, const DynamicType()), result)
    ..fileOffset = effect.fileOffset;
}

/// Creates a [VariableDeclaration] for caching [expression] of the static
/// [type] using `expression.fileOffset` as the file offset for the declaration.
VariableDeclaration createVariableCache(Expression expression, DartType type) {
  return new VariableDeclaration.forValue(expression, type: type)
    ..fileOffset = expression.fileOffset;
}

/// Creates an uninitialized [VariableDeclaration] of the static [type].
VariableDeclaration createUninitializedVariable(DartType type,
    {required int fileOffset}) {
  return new VariableDeclaration(null, type: type, isSynthesized: true)
    ..fileOffset = fileOffset;
}

/// Creates an initialized (but mutable) [VariableDeclaration] of the static
/// [type].
VariableDeclaration createInitializedVariable(
    Expression expression, DartType type,
    {required int fileOffset, String? name}) {
  return new VariableDeclaration(name,
      initializer: expression, type: type, isSynthesized: true)
    ..fileOffset = fileOffset;
}

/// Creates a [VariableDeclaration] for [expression] with the static [type]
/// using `expression.fileOffset` as the file offset for the declaration.
// TODO(johnniwinther): Merge the use of this with [createVariableCache].
VariableDeclaration createVariable(Expression expression, DartType type) {
  assert(expression is! ThisExpression);
  return new VariableDeclaration.forValue(expression, type: type)
    ..fileOffset = expression.fileOffset;
}

/// Creates a [VariableDeclaration] for the expression inference [result]
/// using `result.expression.fileOffset` as the file offset for the declaration.
VariableDeclaration createVariableForResult(ExpressionInferenceResult result) {
  return createVariable(result.expression, result.inferredType);
}

/// Creates a [VariableGet] of [variable] using `variable.fileOffset` as the
/// file offset for the expression.
VariableGet createVariableGet(VariableDeclaration variable,
    {DartType? promotedType}) {
  return new VariableGet(variable)
    ..fileOffset = variable.fileOffset
    ..promotedType = promotedType;
}

/// Creates a [VariableSet] of [variable] with the [value].
VariableSet createVariableSet(VariableDeclaration variable, Expression value,
    {bool allowFinalAssignment = false, required int fileOffset}) {
  assert(allowFinalAssignment || variable.isAssignable,
      "Cannot assign to variable $variable");
  return new VariableSet(variable, value)..fileOffset = fileOffset;
}

/// Creates an invocation of the local function [variable] with the provided
/// [arguments].
LocalFunctionInvocation createLocalFunctionInvocation(
    VariableDeclaration variable,
    {Arguments? arguments,
    required int fileOffset}) {
  return new LocalFunctionInvocation(
      variable,
      arguments ?? createArguments([], fileOffset: fileOffset)
        ..fileOffset = fileOffset,
      functionType: variable.type as FunctionType)
    ..fileOffset = fileOffset;
}

/// Creates a [Not] of [operand].
Not createNot(Expression operand) {
  return new Not(operand)..fileOffset = operand.fileOffset;
}

/// Creates a logical and expression of [left] and [right].
LogicalExpression createAndExpression(Expression left, Expression right,
    {required int fileOffset}) {
  return new LogicalExpression(left, LogicalExpressionOperator.AND, right)
    ..fileOffset = fileOffset;
}

/// Creates a logical or expression of [left] and [right].
LogicalExpression createOrExpression(Expression left, Expression right,
    {required int fileOffset}) {
  return new LogicalExpression(left, LogicalExpressionOperator.OR, right)
    ..fileOffset = fileOffset;
}

/// Creates an is-test on [operand] against [type].
IsExpression createIsExpression(Expression operand, DartType type,
    {required bool forNonNullableByDefault, required int fileOffset}) {
  return new IsExpression(operand, type)
    ..fileOffset = fileOffset
    ..isForNonNullableByDefault = forNonNullableByDefault;
}

/// Creates an as-cast on [operand] against [type].
AsExpression createAsExpression(Expression operand, DartType type,
    {required bool forNonNullableByDefault,
    bool isUnchecked = false,
    bool isCovarianceCheck = false,
    required int fileOffset}) {
  return new AsExpression(operand, type)
    ..fileOffset = fileOffset
    ..isForNonNullableByDefault = forNonNullableByDefault
    ..isUnchecked = isUnchecked
    ..isCovarianceCheck = isCovarianceCheck;
}

/// Creates a [NullCheck] of [expression].
NullCheck createNullCheck(Expression expression, {required int fileOffset}) {
  return new NullCheck(expression)..fileOffset = fileOffset;
}

/// Creates a record indexed access of [index] on [receiver] of type
/// [receiverType].
RecordIndexGet createRecordIndexGet(
    RecordType receiverType, Expression receiver, int index,
    {required int fileOffset}) {
  return new RecordIndexGet(receiver, receiverType, index)
    ..fileOffset = fileOffset;
}

/// Creates a record named access of [name] on [receiver] of type
/// [receiverType].
RecordNameGet createRecordNameGet(
    RecordType receiverType, Expression receiver, String name,
    {required int fileOffset}) {
  return new RecordNameGet(receiver, receiverType, name)
    ..fileOffset = fileOffset;
}

/// Creates a [StringConcatenation] of the [parts].
StringConcatenation createStringConcatenation(List<Expression> parts,
    {required int fileOffset}) {
  return new StringConcatenation(parts)..fileOffset = fileOffset;
}

/// Creates a block expression using [body] as the body and [value] as the
/// resulting value.
BlockExpression createBlockExpression(Block body, Expression value,
    {required int fileOffset}) {
  return new BlockExpression(body, value)..fileOffset = fileOffset;
}

/// Creates a throw of [expression] using the file offset of [expression] for
/// the throw expression.
Throw createThrow(Expression expression) {
  return new Throw(expression)..fileOffset = expression.fileOffset;
}

/// Creates an [ExpressionStatement] of [expression] using the file offset of
/// [expression] for the file offset of the statement.
ExpressionStatement createExpressionStatement(Expression expression) {
  return new ExpressionStatement(expression)
    ..fileOffset = expression.fileOffset;
}

/// Creates an if statement with the [condition], [then] branch and [otherwise]
/// as the optional else branch.
IfStatement createIfStatement(Expression condition, Statement then,
    {Statement? otherwise, required int fileOffset}) {
  return new IfStatement(condition, then, otherwise)..fileOffset = fileOffset;
}

/// Creates a break statement with the given [target].
BreakStatement createBreakStatement(LabeledStatement target,
    {required int fileOffset}) {
  return new BreakStatement(target)..fileOffset = fileOffset;
}

/// Creates a block containing the [statements].
Block createBlock(List<Statement> statements, {required int fileOffset}) {
  return new Block(statements)
    ..fileOffset = fileOffset
    ..fileEndOffset = fileOffset;
}

/// Creates an [Arguments] object for the [positional] and [named] arguments,
/// and [types] as the type arguments.
Arguments createArguments(List<Expression> positional,
    {List<DartType>? types,
    List<NamedExpression>? named,
    required int fileOffset}) {
  return new Arguments(positional, types: types, named: named)
    ..fileOffset = fileOffset;
}

/// Creates a switch case for the case [expressions] and their corresponding
/// file offsets in [expressionOffsets] with the given [body].
SwitchCase createSwitchCase(
    List<Expression> expressions, List<int> expressionOffsets, Statement body,
    {required bool isDefault, required int fileOffset}) {
  return new SwitchCase(expressions, expressionOffsets, body,
      isDefault: isDefault)
    ..fileOffset = fileOffset;
}

/// Create a switch statement on the [expression] with the given [cases]. If
/// the switch is known to be exhaustive and without a default case,
/// [isExplicitlyExhaustive] should be set to `true`.
///
/// The [expressionType] is the static type of the switch expression.
SwitchStatement createSwitchStatement(
    Expression expression, List<SwitchCase> cases,
    {required bool isExplicitlyExhaustive,
    required int fileOffset,
    required DartType expressionType}) {
  return new SwitchStatement(expression, cases,
      isExplicitlyExhaustive: isExplicitlyExhaustive)
    ..expressionType = expressionType
    ..fileOffset = fileOffset;
}

/// Creates a labeled statement that serves as a label for [statement].
LabeledStatement createLabeledStatement(Statement statement,
    {required int fileOffset}) {
  return new LabeledStatement(statement)..fileOffset = fileOffset;
}

/// Creates a return statement of [expression].
ReturnStatement createReturnStatement(Expression expression,
    {required int fileOffset}) {
  return new ReturnStatement(expression)..fileOffset = fileOffset;
}
