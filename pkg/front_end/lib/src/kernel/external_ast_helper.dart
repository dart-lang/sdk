// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper library for creating external AST nodes during inference.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/names.dart';

import 'internal_ast.dart';

/// Returns a block like this:
///
///     {
///       statement;
///       body;
///     }
///
/// If [body] is a [Block], it's returned with [statement] prepended to it.
Block combineStatements(Statement statement, Statement body) {
  if (body is Block) {
    if (statement is Block) {
      body.statements.insertAll(0, statement.statements);
      setParents(statement.statements, body);
    } else {
      body.statements.insert(0, statement);
      statement.parent = body;
    }
    return body;
  } else {
    return createBlock(
      [if (statement is Block) ...statement.statements else statement, body],
      fileOffset: statement.fileOffset,
      fileEndOffset: body.fileOffset,
    );
  }
}

/// Creates a logical and expression of [left] and [right].
LogicalExpression createAndExpression(
  Expression left,
  Expression right, {
  required int fileOffset,
}) {
  return new LogicalExpression(left, LogicalExpressionOperator.AND, right)
    ..fileOffset = fileOffset;
}

/// Creates an [Arguments] object for the [positional] and [named] arguments,
/// and [types] as the type arguments.
Arguments createArguments(
  List<Expression> positional, {
  List<DartType>? types,
  List<NamedExpression>? named,
  required int fileOffset,
}) {
  return new Arguments(positional, types: types, named: named)
    ..fileOffset = fileOffset;
}

Arguments createArgumentsForwarded(
  FunctionNode function, {
  required int fileOffset,
}) {
  return new Arguments.forwarded(function)..fileOffset = fileOffset;
}

/// Creates an as-cast on [operand] against [type].
AsExpression createAsExpression(
  Expression operand,
  DartType type, {
  bool isUnchecked = false,
  bool isCovarianceCheck = false,
  bool isTypeError = false,
  bool isForDynamic = false,
  required int fileOffset,
}) {
  return new AsExpression(operand, type)
    ..fileOffset = fileOffset
    ..isUnchecked = isUnchecked
    ..isCovarianceCheck = isCovarianceCheck
    ..isTypeError = isTypeError
    ..isForDynamic = isForDynamic;
}

AssertStatement createAssertStatement(
  Expression condition, {
  Expression? message,
  required int conditionStartOffset,
  required int conditionEndOffset,
  required int fileOffset,
}) {
  return new AssertStatement(
    condition,
    message: message,
    conditionStartOffset: conditionStartOffset,
    conditionEndOffset: conditionEndOffset,
  )..fileOffset = fileOffset;
}

/// Creates a block containing the [statements].
Block createBlock(
  List<Statement> statements, {
  required int fileOffset,
  int? fileEndOffset,
}) {
  return new Block(statements)
    ..fileOffset = fileOffset
    ..fileEndOffset = fileEndOffset ?? fileOffset;
}

/// Creates a block expression using [body] as the body and [value] as the
/// resulting value.
BlockExpression createBlockExpression(
  Block body,
  Expression value, {
  required int fileOffset,
}) {
  return new BlockExpression(body, value)..fileOffset = fileOffset;
}

/// Creates a boolean literal of [value].
BoolLiteral createBoolLiteral(bool value, {required int fileOffset}) {
  return new BoolLiteral(value)..fileOffset = fileOffset;
}

/// Creates a break statement with the given [target].
BreakStatement createBreakStatement(
  LabeledStatement target, {
  required int fileOffset,
}) {
  return new BreakStatement(target)..fileOffset = fileOffset;
}

CatchVariable createCatchVariable({
  required String name,
  required DartType? type,
  bool isWildcard = false,
  required int fileOffset,
}) {
  return new CatchVariable(name: name, type: type, isWildcard: isWildcard)
    ..fileOffset = fileOffset;
}

/// Creates a conditional expression of the [condition] and the [then] and
/// [otherwise] branches with the given [staticType] of the resulting
/// expression.
ConditionalExpression createConditionalExpression(
  Expression condition,
  Expression then,
  Expression otherwise, {
  required DartType staticType,
  required int fileOffset,
}) {
  return new ConditionalExpression(condition, then, otherwise, staticType)
    ..fileOffset = fileOffset;
}

ConstantExpression createConstantExpression(
  Constant constant,
  DartType type, {
  required int fileOffset,
}) {
  return new ConstantExpression(constant, type)..fileOffset = fileOffset;
}

Constructor createConstructor(
  FunctionNode function, {
  required Name name,
  Reference? reference,
  bool isSynthetic = false,
  required Uri fileUri,
  required int fileOffset,
  required int fileStartOffset,
  required int fileEndOffset,
}) {
  return new Constructor(
      function,
      name: name,
      reference: reference,
      fileUri: fileUri,
      isSynthetic: isSynthetic,
    )
    ..fileOffset = fileOffset
    ..startFileOffset = fileStartOffset
    ..fileEndOffset = fileEndOffset;
}

/// Creates an invocation of the [target] constructor with the given
/// [arguments].
ConstructorInvocation createConstructorInvocation(
  Constructor target,
  Arguments arguments, {
  required int fileOffset,
  bool isConst = false,
}) {
  return new ConstructorInvocation(target, arguments, isConst: isConst)
    ..fileOffset = fileOffset;
}

// Coverage-ignore(suite): Not run.
ConstructorTearOff createConstructorTearOff(
  Member target, {
  required int fileOffset,
}) {
  return new ConstructorTearOff(target)..fileOffset = fileOffset;
}

// Coverage-ignore(suite): Not run.
DynamicInvocation createDynamicInvocation(
  DynamicAccessKind kind,
  Expression receiver,
  Name name,
  Arguments arguments, {
  int flags = 0,
  required int fileOffset,
}) {
  return new DynamicInvocation(kind, receiver, name, arguments)
    ..flags = flags
    ..fileOffset = fileOffset;
}

// TODO(johnniwinther): Should [fileOffset] be required?
Statement createEmptyStatement({int fileOffset = TreeNode.noOffset}) {
  return new EmptyStatement()..fileOffset = fileOffset;
}

// Coverage-ignore(suite): Not run.
EqualsCall createEqualsCall(
  Expression left,
  Expression right, {
  required FunctionType functionType,
  required Procedure interfaceTarget,
  required int fileOffset,
}) {
  return new EqualsCall(
    left,
    right,
    functionType: functionType,
    interfaceTarget: interfaceTarget,
  )..fileOffset = fileOffset;
}

/// Creates a `== null` test on [expression].
EqualsNull createEqualsNull(Expression expression, {required int fileOffset}) {
  return new EqualsNull(expression)..fileOffset = fileOffset;
}

/// Creates an [ExpressionStatement] of [expression] using the file offset of
/// [expression] for the file offset of the statement.
ExpressionStatement createExpressionStatement(Expression expression) {
  return new ExpressionStatement(expression)
    ..fileOffset = expression.fileOffset;
}

FieldInitializer createFieldInitializer(
  Field field,
  Expression value, {
  required int fileOffset,
  required bool isSynthetic,
}) {
  return new FieldInitializer(field, value)
    ..fileOffset = fileOffset
    ..isSynthetic = isSynthetic;
}

FileUriConstantExpression createFileUriConstantExpression(
  Constant constant, {
  DartType type = const DynamicType(),
  required Uri fileUri,
  required int fileOffset,
}) {
  return new FileUriConstantExpression(constant, type: type, fileUri: fileUri)
    ..fileOffset = fileOffset;
}

FileUriExpression createFileUriExpression({
  required Expression expression,
  required Uri fileUri,
  required int fileOffset,
}) {
  return new FileUriExpression(expression, fileUri)..fileOffset = fileOffset;
}

FunctionExpression createFunctionExpression(
  FunctionNode function, {
  required int fileOffset,
}) {
  return new FunctionExpression(function)..fileOffset = fileOffset;
}

FunctionNode createFunctionNode(
  Statement? body, {
  List<TypeParameter>? typeParameters,
  List<VariableDeclaration>? positionalParameters,
  List<VariableDeclaration>? namedParameters,
  int? requiredParameterCount,
  DartType returnType = const DynamicType(),
  required int fileOffset,
  int? fileEndOffset,
  AsyncMarker asyncMarker = AsyncMarker.Sync,
  AsyncMarker? dartAsyncMarker,
}) {
  return new FunctionNode(
      body,
      typeParameters: typeParameters,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      returnType: returnType,
      requiredParameterCount: requiredParameterCount,
      asyncMarker: asyncMarker,
      dartAsyncMarker: dartAsyncMarker,
    )
    ..fileOffset = fileOffset
    ..fileEndOffset = fileEndOffset ?? fileOffset;
}

/// Creates an if statement with the [condition], [then] branch and [otherwise]
/// as the optional else branch.
IfStatement createIfStatement(
  Expression condition,
  Statement then, {
  Statement? otherwise,
  required int fileOffset,
}) {
  return new IfStatement(condition, then, otherwise)..fileOffset = fileOffset;
}

Field createImmutableField(
  Name name, {
  required DartType type,
  bool isLate = false,
  bool isFinal = false,
  bool isConst = false,
  bool isStatic = false,
  required Uri fileUri,
  Reference? fieldReference,
  Reference? getterReference,
  bool isEnumElement = false,
  required int fileOffset,
  required int fileEndOffset,
}) {
  return new Field.immutable(
      name,
      type: type,
      isLate: isLate,
      isFinal: isFinal,
      isConst: isConst,
      isStatic: isStatic,
      fileUri: fileUri,
      fieldReference: fieldReference,
      getterReference: getterReference,
      isEnumElement: isEnumElement,
    )
    ..fileOffset = fileOffset
    ..fileEndOffset = fileEndOffset;
}

/// Creates an initialized (but mutable) [VariableDeclaration] of the static
/// [type].
VariableDeclaration createInitializedVariable(
  Expression expression,
  DartType type, {
  required int fileOffset,
  String? name,
}) {
  return new VariableDeclaration(
    name,
    initializer: expression,
    type: type,
    isSynthesized: true,
  )..fileOffset = fileOffset;
}

InstanceGet createInstanceGet(
  InstanceAccessKind kind,
  Expression receiver,
  Name name, {
  required Member interfaceTarget,
  required DartType resultType,
  required int fileOffset,
}) {
  return new InstanceGet(
    kind,
    receiver,
    name,
    interfaceTarget: interfaceTarget,
    resultType: resultType,
  )..fileOffset = fileOffset;
}

InstanceInvocation createInstanceInvocation(
  InstanceAccessKind kind,
  Expression receiver,
  Name name,
  Arguments arguments, {
  required Procedure interfaceTarget,
  required FunctionType functionType,
  required int fileOffset,
}) {
  return new InstanceInvocation(
    kind,
    receiver,
    name,
    arguments,
    interfaceTarget: interfaceTarget,
    functionType: functionType,
  )..fileOffset = fileOffset;
}

InstanceSet createInstanceSet(
  InstanceAccessKind kind,
  Expression receiver,
  Name name,
  Expression value, {
  required Member interfaceTarget,
  required int fileOffset,
}) {
  return new InstanceSet(
    kind,
    receiver,
    name,
    value,
    interfaceTarget: interfaceTarget,
  )..fileOffset = fileOffset;
}

/// Creates an integer literal of [value].
///
/// If [encodeForWeb] is `true`, negative values are encoded using unary-. This
/// should be done if the [value] isn't known to be a valid negative number in
/// the web encoding.
Expression createIntLiteral(
  CoreTypes coreTypes,
  int value, {
  required int fileOffset,
  bool encodeForWeb = true,
}) {
  if (encodeForWeb && value < 0) {
    /// The web backends need this to be encoded as a unary minus on the
    /// positive value.
    return new InstanceInvocation(
      InstanceAccessKind.Instance,
      new IntLiteral(-value)..fileOffset = fileOffset,
      unaryMinusName,
      new Arguments([])..fileOffset = fileOffset,
      interfaceTarget: coreTypes.intUnaryMinus,
      functionType: coreTypes.intUnaryMinus.getterType as FunctionType,
    )..fileOffset = fileOffset;
  } else {
    return new IntLiteral(value)..fileOffset = fileOffset;
  }
}

InvalidExpression createInvalidExpression(
  String message, {
  Expression? expression,
  required int fileOffset,
}) {
  return new InvalidExpression(message, expression)..fileOffset = fileOffset;
}

InvalidInitializer createInvalidInitializer(
  InvalidExpression expression, {
  bool isSuperInitializer = false,
  bool isRedirectingInitializer = false,
}) {
  return new InvalidInitializer(expression.message)
    ..fileOffset = expression.fileOffset
    ..isSuperInitializer = isSuperInitializer
    ..isRedirectingInitializer = isRedirectingInitializer;
}

/// Creates an is-test on [operand] against [type].
IsExpression createIsExpression(
  Expression operand,
  DartType type, {
  required int fileOffset,
}) {
  return new IsExpression(operand, type)..fileOffset = fileOffset;
}

/// Creates a labeled statement that serves as a label for [statement].
LabeledStatement createLabeledStatement(
  Statement statement, {
  required int fileOffset,
}) {
  return new LabeledStatement(statement)..fileOffset = fileOffset;
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

/// Creates an invocation of the local function [variable] with the provided
/// [arguments].
LocalFunctionInvocation createLocalFunctionInvocation(
  VariableDeclaration variable, {
  Arguments? arguments,
  required int fileOffset,
}) {
  return new LocalFunctionInvocation(
    variable,
    arguments ?? // Coverage-ignore(suite): Not run.
          createArguments([], fileOffset: fileOffset)
      ..fileOffset = fileOffset,
    functionType: variable.type as FunctionType,
  )..fileOffset = fileOffset;
}

// Coverage-ignore(suite): Not run.
MapLiteralEntry createMapLiteralEntry(
  Expression key,
  Expression value, {
  required int fileOffset,
}) {
  return new MapLiteralEntry(key, value)..fileOffset = fileOffset;
}

Field createMutableField(
  Name name, {
  DartType type = const DynamicType(),
  bool isLate = false,
  bool isFinal = false,
  bool isStatic = false,
  required Uri fileUri,
  Reference? fieldReference,
  Reference? getterReference,
  Reference? setterReference,
  required int fileOffset,
  required int fileEndOffset,
  bool isInternalImplementation = false,
}) {
  return new Field.mutable(
      name,
      type: type,
      isLate: isLate,
      isFinal: isFinal,
      isStatic: isStatic,
      fileUri: fileUri,
      fieldReference: fieldReference,
      getterReference: getterReference,
      setterReference: setterReference,
    )
    ..fileOffset = fileOffset
    ..fileEndOffset = fileEndOffset
    ..isInternalImplementation = isInternalImplementation;
}

NamedExpression createNamedExpression(
  String name,
  Expression expression, {
  int? fileOffset,
}) {
  return new NamedExpression(name, expression)
    ..fileOffset = fileOffset ?? expression.fileOffset;
}

NamedParameter createNamedParameter({
  required String parameterName,
  required DartType type,
  Expression? defaultValue,
  bool isCovariantByDeclaration = false,
  bool isRequired = false,
  bool isInitializingFormal = false,
  bool isSuperInitializingFormal = false,
  bool isFinal = false,
  bool hasDeclaredDefaultType = false,
  bool isLowered = false,
  bool isSynthesized = false,
  bool isWildcard = false,
  required int fileOffset,
}) {
  return new NamedParameter(
    parameterName: parameterName,
    type: type,
    defaultValue: defaultValue,
    isCovariantByDeclaration: isCovariantByDeclaration,
    isRequired: isRequired,
    isInitializingFormal: isInitializingFormal,
    isSuperInitializingFormal: isSuperInitializingFormal,
    isFinal: isFinal,
    hasDeclaredDefaultType: hasDeclaredDefaultType,
    isLowered: isLowered,
    isSynthesized: isSynthesized,
    isWildcard: isWildcard,
  )..fileOffset = fileOffset;
}

/// Creates a [Not] of [operand].
Not createNot(Expression operand) {
  return new Not(operand)..fileOffset = operand.fileOffset;
}

/// Creates a [NullCheck] of [expression].
NullCheck createNullCheck(Expression expression, {required int fileOffset}) {
  return new NullCheck(expression)..fileOffset = fileOffset;
}

/// Creates a null literal.
NullLiteral createNullLiteral({required int fileOffset}) {
  return new NullLiteral()..fileOffset = fileOffset;
}

/// Creates a logical or expression of [left] and [right].
LogicalExpression createOrExpression(
  Expression left,
  Expression right, {
  required int fileOffset,
}) {
  return new LogicalExpression(left, LogicalExpressionOperator.OR, right)
    ..fileOffset = fileOffset;
}

// TODO(johnniwinther): Should this require a type?
VariableDeclaration createParameterVariable(
  String? name, {
  DartType type = const DynamicType(),
  required int fileOffset,
  bool isCovariantByDeclaration = false,
  bool isCovariantByClass = false,
  bool isLowered = false,
  bool isSynthesized = false,
  bool isFinal = false,
  bool isRequired = false,
  Expression? initializer,
  bool hasDeclaredInitializer = false,
}) {
  return new VariableDeclaration(
      name,
      type: type,
      isCovariantByDeclaration: isCovariantByDeclaration,
      isLowered: isLowered,
      isSynthesized: isSynthesized,
      isFinal: isFinal,
      isRequired: isRequired,
      initializer: initializer,
      hasDeclaredInitializer: hasDeclaredInitializer,
    )
    ..fileOffset = fileOffset
    ..isCovariantByClass = isCovariantByClass;
}

PositionalParameter createPositionalParameter({
  String? cosmeticName,
  required DartType type,
  Expression? defaultValue,
  bool isCovariantByDeclaration = false,
  bool isRequired = false,
  bool isInitializingFormal = false,
  bool isSuperInitializingFormal = false,
  bool isFinal = false,
  bool hasDeclaredDefaultType = false,
  bool isLowered = false,
  bool isSynthesized = false,
  bool isWildcard = false,
  required int fileOffset,
}) {
  return new PositionalParameter(
    cosmeticName: cosmeticName,
    type: type,
    defaultValue: defaultValue,
    isCovariantByDeclaration: isCovariantByDeclaration,
    isRequired: isRequired,
    isInitializingFormal: isInitializingFormal,
    isSuperInitializingFormal: isSuperInitializingFormal,
    isFinal: isFinal,
    hasDeclaredDefaultType: hasDeclaredDefaultType,
    isLowered: isLowered,
    isSynthesized: isSynthesized,
    isWildcard: isWildcard,
  )..fileOffset = fileOffset;
}

Procedure createProcedure(
  Name name,
  ProcedureKind kind,
  FunctionNode function, {
  Reference? reference,
  ProcedureStubKind stubKind = ProcedureStubKind.Regular,
  Member? stubTarget,
  required Uri fileUri,
  required int fileOffset,
  int fileStartOffset = TreeNode.noOffset,
  required int fileEndOffset,
  bool isAbstract = false,
  bool isExternal = false,
  bool isStatic = false,
  bool isConst = false,
  bool isExtensionMember = false,
  bool isExtensionTypeMember = false,
  bool isSynthetic = false,
}) {
  return new Procedure(
      name,
      kind,
      function,
      stubKind: stubKind,
      stubTarget: stubTarget,
      fileUri: fileUri,
      reference: reference,
      isAbstract: isAbstract,
      isExternal: isExternal,
      isConst: isConst,
      isStatic: isStatic,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
      isSynthetic: isSynthetic,
    )
    ..fileStartOffset = fileStartOffset
    ..fileOffset = fileOffset
    ..fileEndOffset = fileEndOffset;
}

ReturnStatement createReturnStatement(
  Expression expression, {
  int? fileOffset,
}) {
  return new ReturnStatement(expression)
    ..fileOffset = fileOffset ?? expression.fileOffset;
}

StaticGet createStaticGet(Member member, {required int fileOffset}) {
  return new StaticGet(member)..fileOffset = fileOffset;
}

/// Creates a static invocation of [target] with the given arguments.
StaticInvocation createStaticInvocation(
  Procedure target,
  Arguments arguments, {
  required int fileOffset,
  bool isConst = false,
}) {
  return new StaticInvocation(target, arguments, isConst: isConst)
    ..fileOffset = fileOffset;
}

StaticSet createStaticSet(
  Member member,
  Expression value, {
  required int fileOffset,
}) {
  return new StaticSet(member, value)..fileOffset = fileOffset;
}

StaticTearOff createStaticTearOff(Procedure target, {required int fileOffset}) {
  return new StaticTearOff(target)..fileOffset = fileOffset;
}

/// Creates a string literal of [value].
StringLiteral createStringLiteral(String value, {required int fileOffset}) {
  return new StringLiteral(value)..fileOffset = fileOffset;
}

/// Creates a super method invocation of [target] with the given arguments.
SuperMethodInvocation createSuperMethodInvocation(
  Expression receiver,
  Name name,
  Procedure target,
  Arguments arguments, {
  required int fileOffset,
}) {
  return new SuperMethodInvocation(receiver, name, arguments, target)
    ..fileOffset = fileOffset;
}

SuperPropertyGet createSuperPropertyGet(
  Expression receiver,
  Name name,
  Member target, {
  required int fileOffset,
}) {
  return new SuperPropertyGet(receiver, name, target)..fileOffset = fileOffset;
}

SuperPropertySet createSuperPropertySet(
  Expression receiver,
  Name name,
  Member target,
  Expression value, {
  required int fileOffset,
}) {
  return new SuperPropertySet(receiver, name, value, target)
    ..fileOffset = fileOffset;
}

/// Creates a switch case for the case [expressions] and their corresponding
/// file offsets in [expressionOffsets] with the given [body].
SwitchCase createSwitchCase(
  List<Expression> expressions,
  List<int> expressionOffsets,
  Statement body, {
  required bool isDefault,
  required int fileOffset,
}) {
  return new SwitchCase(
    expressions,
    expressionOffsets,
    body,
    isDefault: isDefault,
  )..fileOffset = fileOffset;
}

/// Create a switch statement on the [expression] with the given [cases]. If
/// the switch is known to be exhaustive and without a default case,
/// [isExplicitlyExhaustive] should be set to `true`.
///
/// The [expressionType] is the static type of the switch expression.
SwitchStatement createSwitchStatement(
  Expression expression,
  List<SwitchCase> cases, {
  required bool isExplicitlyExhaustive,
  required int fileOffset,
  required DartType expressionType,
}) {
  return new SwitchStatement(
      expression,
      cases,
      isExplicitlyExhaustive: isExplicitlyExhaustive,
    )
    ..expressionType = expressionType
    ..fileOffset = fileOffset;
}

ThisExpression createThisExpression({required int fileOffset}) {
  return new ThisExpression()..fileOffset = fileOffset;
}

/// Creates a throw of [expression] using the file offset of [expression] for
/// the throw expression.
Throw createThrow(
  Expression expression, {
  bool forErrorHandling = false,
  int? fileOffset,
}) {
  return new Throw(expression)
    ..fileOffset = fileOffset ?? expression.fileOffset
    ..forErrorHandling = forErrorHandling;
}

TypeParameter createTypeParameter(String? name, {required int fileOffset}) {
  return new TypeParameter(name)..fileOffset = fileOffset;
}

/// Creates an uninitialized [VariableDeclaration] of the static [type].
VariableDeclaration createUninitializedVariable(
  DartType type, {
  required int fileOffset,
  bool isFinal = false,
}) {
  return new VariableDeclaration(
    null,
    type: type,
    isSynthesized: true,
    isFinal: isFinal,
  )..fileOffset = fileOffset;
}

/// Creates a [VariableDeclaration] for [expression] with the static [type]
/// using `expression.fileOffset` as the file offset for the declaration.
// TODO(johnniwinther): Merge the use of this with [createVariableCache].
VariableDeclaration createVariable(Expression expression, DartType type) {
  assert(expression is! ThisExpression);
  return new VariableDeclaration.forValue(expression, type: type)
    ..fileOffset = expression.fileOffset;
}

/// Creates a [VariableDeclaration] for caching [expression] of the static
/// [type] using `expression.fileOffset` as the file offset for the declaration.
VariableDeclaration createVariableCache(Expression expression, DartType type) {
  return new VariableDeclaration.forValue(expression, type: type)
    ..fileOffset = expression.fileOffset;
}

/// Creates a [VariableGet] of [variable] using `variable.fileOffset` as the
/// file offset for the expression.
VariableGet createVariableGet(
  VariableDeclaration variable, {
  DartType? promotedType,
  int? fileOffset,
}) {
  return new VariableGet(variable)
    ..fileOffset = fileOffset ?? variable.fileOffset
    ..promotedType = promotedType != variable.type ? promotedType : null;
}

/// Creates a [VariableSet] of [variable] with the [value].
Expression createVariableSet(
  VariableDeclaration variable,
  Expression value, {
  bool allowFinalAssignment = false,
  required int fileOffset,
}) {
  if (variable is VariableDeclarationImpl && variable.lateSetter != null) {
    return createLocalFunctionInvocation(
      variable.lateSetter!,
      arguments: createArguments([value], fileOffset: fileOffset),
      fileOffset: fileOffset,
    );
  } else {
    assert(
      allowFinalAssignment || variable.isAssignable,
      "Cannot assign to variable $variable",
    );
    return new VariableSet(variable, value)..fileOffset = fileOffset;
  }
}
