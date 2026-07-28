// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper library for creating external AST nodes during inference.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/names.dart';

import '../source/check_helper.dart';
import 'internal_ast.dart';

/// Returns a clone of [node].
///
/// This assumes that `isPureExpression(node)` is `true`.
Expression clonePureExpression(Expression node) {
  if (node is ThisExpression) {
    return createThisExpression(fileOffset: node.fileOffset);
  } else if (node is VariableGet) {
    assert(
      node.variable.isFinal && !node.variable.isLate,
      "Trying to clone VariableGet of non-final variable"
      " ${node.variable}.",
    );
    return createVariableGet(
      node.variable,
      promotedType: node.promotedType,
      fileOffset: node.fileOffset,
    );
  }
  // Coverage-ignore-block(suite): Not run.
  throw new UnsupportedError("Clone not supported for ${node.runtimeType}.");
}

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

AndPattern createAndPattern({
  required Pattern left,
  required Pattern right,
  required int fileOffset,
}) {
  return new AndPattern(left, right)..fileOffset = fileOffset;
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

AssertInitializer createAssertInitializer(
  AssertStatement statement, {
  required int fileOffset,
}) {
  return new AssertInitializer(statement)..fileOffset = fileOffset;
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

AssignedVariablePattern createAssignedVariablePattern({
  required Variable variable,
  required Variable? setter,
  required DartType matchedValueType,
  required bool needsCast,
  required bool hasObservableEffect,
  required int fileOffset,
}) {
  return new AssignedVariablePattern(variable)
    ..setter = setter
    ..matchedValueType = matchedValueType
    ..needsCast = needsCast
    ..hasObservableEffect = hasObservableEffect
    ..fileOffset = fileOffset;
}

Expression createAwaitExpression(
  Expression operand, {
  required DartType? runtimeCheckType,
  required int fileOffset,
}) {
  return new AwaitExpression(operand)
    ..runtimeCheckType = runtimeCheckType
    ..fileOffset = fileOffset;
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
  // TODO(johnniwinther,cstefantsova): This should be required.
  Scope? scope,
  required int fileOffset,
}) {
  return new BlockExpression(body, value)
    ..scope = scope
    ..fileOffset = fileOffset;
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

CastPattern createCastPattern({
  required Pattern pattern,
  required DartType type,
  required int fileOffset,
}) {
  return new CastPattern(pattern, type)..fileOffset = fileOffset;
}

Catch createCatch({
  required DartType guard,
  required CatchVariable? exception,
  required CatchVariable? stackTrace,
  required Statement body,
  required Scope? scope,
  required int fileOffset,
}) {
  return new Catch(exception, body, guard: guard, stackTrace: stackTrace)
    ..scope = scope
    ..fileOffset = fileOffset;
}

CatchVariable createCatchVariable({
  required String name,
  required DartType? type,
  required bool isFinal,
  required bool isWildcard,
  required int fileOffset,
}) {
  return new CatchVariable(
    name: name,
    type: type,
    isWildcard: isWildcard,
    isFinal: isFinal,
  )..fileOffset = fileOffset;
}

Expression createCheckLibraryIsLoaded({
  required LibraryDependency dependency,
  required int fileOffset,
}) {
  return new CheckLibraryIsLoaded(dependency)..fileOffset = fileOffset;
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

ConstantPattern createConstantPattern({
  required Expression expression,
  required DartType expressionType,
  required Procedure equalsTarget,
  required FunctionType equalsType,
  required int fileOffset,
}) {
  return new ConstantPattern(expression)
    ..expressionType = expressionType
    ..equalsTarget = equalsTarget
    ..equalsType = equalsType
    ..fileOffset = fileOffset;
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

ConstructorTearOff createConstructorTearOff(
  Member target, {
  required int fileOffset,
}) {
  return new ConstructorTearOff(target)..fileOffset = fileOffset;
}

ConstVariable createConstVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isWildcard = false,
  required int fileOffset,
  bool hasDeclaredInitializer = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new ConstVariable(
      name: name,
      type: type,
      isFinal: isFinal,
      isWildcard: isWildcard,
      hasDeclaredInitializer: hasDeclaredInitializer,
    )
    ..fileOffset = fileOffset
    ..fileEqualsOffset = fileEqualsOffset;
}

ContinueSwitchStatement createContinueSwitchStatement({
  required int fileOffset,
}) {
  return new ContinueSwitchStatement(dummySwitchCase)..fileOffset = fileOffset;
}

AsExpression createCovarianceCheckedInstanceGet(
  InstanceAccessKind kind,
  Expression receiver,
  Name name, {
  required Member interfaceTarget,
  required DartType checkedType,
  required DartType operandStaticType,
  required int fileOffset,
}) {
  return new AsExpression(
      new InstanceGet(
        kind,
        receiver,
        name,
        interfaceTarget: interfaceTarget,
        resultType: operandStaticType,
      )..fileOffset = fileOffset,
      checkedType,
    )
    ..isTypeError = true
    ..isCovarianceCheck = true
    ..fileOffset = fileOffset;
}

AsExpression createCovarianceCheckedInstanceInvocation(
  InstanceAccessKind kind,
  Expression receiver,
  Name name,
  Arguments arguments, {
  required Procedure interfaceTarget,
  required FunctionType functionType,
  required DartType checkedType,
  required DartType operandStaticType,
  required int fileOffset,
}) {
  return new AsExpression(
      new InstanceInvocation(
        kind,
        receiver,
        name,
        arguments,
        interfaceTarget: interfaceTarget,
        functionType: functionType,
        resultType: operandStaticType,
      )..fileOffset = fileOffset,
      checkedType,
    )
    ..isTypeError = true
    ..isCovarianceCheck = true
    ..fileOffset = fileOffset;
}

AsExpression createCovarianceCheckedInstanceTearOff(
  InstanceAccessKind kind,
  Expression receiver,
  Name name, {
  required Procedure interfaceTarget,
  required DartType checkedType,
  required DartType operandStaticType,
  required int fileOffset,
}) {
  return new AsExpression(
      new InstanceTearOff(
        kind,
        receiver,
        name,
        interfaceTarget: interfaceTarget,
        resultType: operandStaticType,
      )..fileOffset = fileOffset,
      checkedType,
    )
    ..isTypeError = true
    ..isCovarianceCheck = true
    ..fileOffset = fileOffset;
}

AsExpression createCovarianceCheckedVariableGet(
  Variable variable, {
  required DartType operandStaticType,
  required DartType checkedType,
  required int fileOffset,
}) {
  return new AsExpression(
      new VariableGet(variable)
        ..fileOffset = fileOffset
        ..promotedType = operandStaticType,
      checkedType,
    )
    ..isTypeError = true
    ..isCovarianceCheck = true
    ..fileOffset = fileOffset;
}

Statement createDoStatement(
  Statement body,
  Expression condition, {
  required int fileOffset,
}) {
  return new DoStatement(body, condition)..fileOffset = fileOffset;
}

DoubleLiteral createDoubleLiteral(double value, {required int fileOffset}) {
  return new DoubleLiteral(value)..fileOffset = fileOffset;
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
/// [expression] for the file offset of the statement, unless provided directly
/// through [fileOffset].
ExpressionStatement createExpressionStatement(
  Expression expression, {
  int? fileOffset,
}) {
  return new ExpressionStatement(expression)
    ..fileOffset = fileOffset ?? expression.fileOffset;
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

ForStatement createForStatement({
  required List<VariableDeclaration> variables,
  required Expression? condition,
  required List<Expression> updates,
  required Statement body,
  required Scope? scope,
  required int fileOffset,
}) {
  return new ForStatement(variables, condition, updates, body)
    ..scope = scope
    ..fileOffset = fileOffset;
}

FunctionDeclaration createFunctionDeclaration({
  required LocalFunctionVariable variable,
  required FunctionNode function,
  required int fileOffset,
}) {
  return new FunctionDeclaration(variable, function)..fileOffset = fileOffset;
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
  List<PositionalParameter>? positionalParameters,
  List<NamedParameter>? namedParameters,
  int? requiredParameterCount,
  DartType returnType = const DynamicType(),
  required int fileOffset,
  int? fileEndOffset,
  AsyncMarker asyncMarker = AsyncMarker.Sync,
  AsyncMarker? dartAsyncMarker,
  DartType? emittedValueType,
  Scope? scope,
  List<VariableContext>? capturedContexts,
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
    ..emittedValueType = emittedValueType
    ..scope = scope
    ..capturedContexts = capturedContexts
    ..fileOffset = fileOffset
    ..fileEndOffset = fileEndOffset ?? fileOffset;
}

IfCaseStatement createIfCaseStatement({
  required Expression expression,
  required PatternGuard patternGuard,
  required Statement then,
  required Statement? otherwise,
  required DartType matchedValueType,
  required int fileOffset,
}) {
  return new IfCaseStatement(expression, patternGuard, then, otherwise)
    ..matchedValueType = matchedValueType
    ..fileOffset = fileOffset;
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

/// Creates an initialized (but mutable) [Variable] of the static
/// [type].
VariableDeclaration createInitializedVariableDeclaration({
  required Expression expression,
  required DartType type,
  required int fileOffset,
  String? name,
}) {
  return createVariableDeclaration(
    new SyntheticVariable(
      cosmeticName: name,
      initializer: expression,
      type: type,
      hasDeclaredInitializer: true,
    )..fileOffset = fileOffset,
  );
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

InstanceTearOff createInstanceTearOff(
  InstanceAccessKind kind,
  Expression receiver,
  Name name, {
  required Procedure interfaceTarget,
  required DartType resultType,
  required int fileOffset,
}) {
  return new InstanceTearOff(
    kind,
    receiver,
    name,
    interfaceTarget: interfaceTarget,
    resultType: resultType,
  )..fileOffset = fileOffset;
}

Instantiation createInstantiation(
  Expression expression,
  List<DartType> typeArguments, {
  required int fileOffset,
}) {
  return new Instantiation(expression, typeArguments)..fileOffset = fileOffset;
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

InvalidExpression createInvalidExpressionFromErrorText(
  ErrorText errorText, {
  Expression? expression,
}) {
  return new InvalidExpression(errorText.message, expression)
    ..fileOffset = errorText.fileOffset;
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

InvalidInitializer createInvalidInitializerFromErrorText(
  ErrorText errorText, {
  bool isSuperInitializer = false,
  bool isRedirectingInitializer = false,
}) {
  return new InvalidInitializer(errorText.message)
    ..fileOffset = errorText.fileOffset
    ..isSuperInitializer = isSuperInitializer
    ..isRedirectingInitializer = isRedirectingInitializer;
}

InvalidInitializer createInvalidInitializerFromMessage(
  String message, {
  required int fileOffset,
  required bool isSuperInitializer,
  required bool isRedirectingInitializer,
}) {
  return new InvalidInitializer(message)
    ..fileOffset = fileOffset
    ..isSuperInitializer = isSuperInitializer
    ..isRedirectingInitializer = isRedirectingInitializer;
}

InvalidPattern createInvalidPattern({
  required Expression error,
  required List<InternalDeclaredVariable> declaredVariables,
  int? fileOffset,
}) {
  return new InvalidPattern(
    error,
    declaredVariables: declaredVariables
        .map((InternalDeclaredVariable variable) => variable.astVariable)
        .toList(),
  )..fileOffset = fileOffset ?? error.fileOffset;
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

LateVariable createLateVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isWildcard = false,
  required int fileOffset,
  bool hasDeclaredInitializer = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new LateVariable(
      name: name,
      type: type,
      isFinal: isFinal,
      isWildcard: isWildcard,
      hasDeclaredInitializer: hasDeclaredInitializer,
    )
    ..fileOffset = fileOffset
    ..fileEqualsOffset = fileEqualsOffset;
}

/// Creates a [Let] of [variable] with the given [body] using
/// `variable.fileOffset` as the file offset for the let.
Let createLet({
  required SyntheticVariable variable,
  Expression? value,
  required Expression body,
  int? fileOffset,
}) {
  if (value != null) {
    variable.initializer = value..parent = variable;
  }
  return new Let(variable, body)
    ..fileOffset = fileOffset ?? variable.fileOffset;
}

/// Creates a [Let] with the [effect] as the variable initializer and the
/// [result] as the body of the [Let] expression and using
/// `effect.fileOffset` as the file offset for the let.
Let createLetEffect({required Expression effect, required Expression result}) {
  return new Let(createVariableCache(effect, const DynamicType()), result)
    ..fileOffset = effect.fileOffset;
}

ListPattern createListPattern({
  required DartType? typeArgument,
  required List<Pattern> patterns,
  required DartType requiredType,
  required DartType matchedValueType,
  required bool needsCheck,
  required DartType lookupType,
  required bool hasRestPattern,
  required Member lengthTarget,
  required DartType lengthType,
  required Procedure lengthCheckTarget,
  required FunctionType lengthCheckType,
  required Procedure sublistTarget,
  required FunctionType sublistType,
  required Procedure minusTarget,
  required FunctionType minusType,
  required Procedure indexGetTarget,
  required FunctionType indexGetType,
  required int fileOffset,
}) {
  return new ListPattern(typeArgument, patterns)
    ..requiredType = requiredType
    ..matchedValueType = matchedValueType
    ..needsCheck = needsCheck
    ..lookupType = lookupType
    ..hasRestPattern = hasRestPattern
    ..lengthTarget = lengthTarget
    ..lengthType = lengthType
    ..lengthCheckTarget = lengthCheckTarget
    ..lengthCheckType = lengthCheckType
    ..sublistTarget = sublistTarget
    ..sublistType = sublistType
    ..minusTarget = minusTarget
    ..minusType = minusType
    ..indexGetTarget = indexGetTarget
    ..indexGetType = indexGetType
    ..fileOffset = fileOffset;
}

LoadLibrary createLoadLibrary(
  LibraryDependency dependency, {
  required int fileOffset,
}) {
  return new LoadLibrary(dependency)..fileOffset = fileOffset;
}

/// Creates an invocation of the local function [variable] with the provided
/// [arguments].
LocalFunctionInvocation createLocalFunctionInvocation(
  LocalFunctionVariable variable, {
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

LocalFunctionVariable createLocalFunctionVariable({
  required String name,
  required DartType? type,
  bool isWildcard = false,
  required int fileOffset,
  required bool isLowered,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new LocalFunctionVariable(
      name: name,
      type: type,
      isWildcard: isWildcard,
      isLowered: isLowered,
    )
    ..fileOffset = fileOffset
    ..fileEqualsOffset = fileEqualsOffset;
}

LocalInitializer createLocalInitializer({
  required SyntheticVariable variable,
  required int fileOffset,
}) {
  return new LocalInitializer(variable)..fileOffset = fileOffset;
}

LocalVariable createLocalVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isWildcard = false,
  required int fileOffset,
  bool hasDeclaredInitializer = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new LocalVariable(
      name: name,
      type: type,
      isFinal: isFinal,
      isWildcard: isWildcard,
      hasDeclaredInitializer: hasDeclaredInitializer,
    )
    ..fileOffset = fileOffset
    ..fileEqualsOffset = fileEqualsOffset;
}

Expression createLogicalExpression({
  required Expression left,
  required LogicalExpressionOperator operator,
  required Expression right,
  required int fileOffset,
}) {
  return new LogicalExpression(left, operator, right)..fileOffset = fileOffset;
}

MapLiteralEntry createMapLiteralEntry(
  Expression key,
  Expression value, {
  required int fileOffset,
}) {
  return new MapLiteralEntry(key, value)..fileOffset = fileOffset;
}

MapPattern createMapPattern({
  required DartType? keyType,
  required DartType? valueType,
  required List<MapPatternEntry> entries,
  required DartType requiredType,
  required DartType matchedValueType,
  required bool needsCheck,
  required DartType lookupType,
  required Procedure containsKeyTarget,
  required FunctionType containsKeyType,
  required Procedure indexGetTarget,
  required FunctionType indexGetType,
  required int fileOffset,
}) {
  return new MapPattern(keyType, valueType, entries)
    ..requiredType = requiredType
    ..matchedValueType = matchedValueType
    ..needsCheck = needsCheck
    ..lookupType = lookupType
    ..containsKeyTarget = containsKeyTarget
    ..containsKeyType = containsKeyType
    ..indexGetTarget = indexGetTarget
    ..indexGetType = indexGetType
    ..fileOffset = fileOffset;
}

MapPatternEntry createMapPatternEntry({
  required Expression key,
  required DartType keyType,
  required Pattern value,
  required int fileOffset,
}) {
  return new MapPatternEntry(key, value)
    ..keyType = keyType
    ..fileOffset = fileOffset;
}

MapPatternRestEntry createMapPatternRestEntry({required int fileOffset}) {
  return new MapPatternRestEntry()..fileOffset = fileOffset;
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
  bool isCovariantByClass = false,
  bool isRequired = false,
  bool isInitializingFormal = false,
  bool isSuperInitializingFormal = false,
  bool isFinal = false,
  bool hasDeclaredDefaultValue = false,
  bool isLowered = false,
  bool isSynthesized = false,
  bool isWildcard = false,
  bool isRenamedPrivateNamedParameter = false,
  required int fileOffset,
}) {
  return new NamedParameter(
    parameterName: parameterName,
    type: type,
    defaultValue: defaultValue,
    isCovariantByDeclaration: isCovariantByDeclaration,
    isCovariantByClass: isCovariantByClass,
    isRequired: isRequired,
    isInitializingFormal: isInitializingFormal,
    isSuperInitializingFormal: isSuperInitializingFormal,
    isFinal: isFinal,
    hasDeclaredDefaultValue: hasDeclaredDefaultValue,
    isLowered: isLowered,
    isSynthesized: isSynthesized,
    isWildcard: isWildcard,
    isRenamedPrivateNamedParameter: isRenamedPrivateNamedParameter,
  )..fileOffset = fileOffset;
}

NamedPattern createNamedPattern({
  required String name,
  Name? fieldName,
  required Pattern pattern,
  required int fileOffset,
}) {
  NamedPattern result = new NamedPattern(name, pattern)
    ..fileOffset = fileOffset;
  if (fieldName != null) {
    result.fieldName = fieldName;
  }
  return result;
}

/// Creates a [Not] of [operand].
Not createNot(Expression operand, {int? fileOffset}) {
  return new Not(operand)..fileOffset = fileOffset ?? operand.fileOffset;
}

NullAssertPattern createNullAssertPattern({
  required Pattern pattern,
  required int fileOffset,
}) {
  return new NullAssertPattern(pattern)..fileOffset = fileOffset;
}

/// Creates a [NullCheck] of [expression].
NullCheck createNullCheck(Expression expression, {required int fileOffset}) {
  return new NullCheck(expression)..fileOffset = fileOffset;
}

NullCheckPattern createNullCheckPattern({
  required Pattern pattern,
  required int fileOffset,
}) {
  return new NullCheckPattern(pattern)..fileOffset = fileOffset;
}

/// Creates a null literal.
NullLiteral createNullLiteral({required int fileOffset}) {
  return new NullLiteral()..fileOffset = fileOffset;
}

ObjectPattern createObjectPattern({
  required DartType requiredType,
  required List<NamedPattern> fields,
  required DartType matchedValueType,
  required bool needsCheck,
  required DartType lookupType,
  required int fileOffset,
}) {
  return new ObjectPattern(requiredType, fields)
    ..matchedValueType = matchedValueType
    ..needsCheck = needsCheck
    ..lookupType = lookupType
    ..fileOffset = fileOffset;
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

OrPattern createOrPattern({
  required Pattern left,
  required Pattern right,
  required List<DeclaredVariable> orPatternJointVariables,
  required int fileOffset,
}) {
  return new OrPattern(
    left,
    right,
    orPatternJointVariables: orPatternJointVariables,
  )..fileOffset = fileOffset;
}

PatternAssignment createPatternAssignment({
  required Pattern pattern,
  required Expression expression,
  required DartType matchedValueType,
  required int fileOffset,
}) {
  return new PatternAssignment(pattern, expression)
    ..matchedValueType = matchedValueType
    ..fileOffset = fileOffset;
}

PatternGuard createPatternGuard({
  required Pattern pattern,
  required Expression? guard,
  required int fileOffset,
}) {
  return new PatternGuard(pattern, guard)..fileOffset = fileOffset;
}

PatternSwitchCase createPatternSwitchCase({
  required List<int> caseOffsets,
  required List<PatternGuard> patternGuards,
  required Statement body,
  required bool isDefault,
  required bool hasLabel,
  required List<DeclaredVariable> jointVariables,
  required List<int>? jointVariableFirstUseOffsets,
  required int fileOffset,
}) {
  return new PatternSwitchCase(
    caseOffsets,
    patternGuards,
    body,
    isDefault: isDefault,
    hasLabel: hasLabel,
    jointVariables: jointVariables,
    jointVariableFirstUseOffsets: jointVariableFirstUseOffsets,
  )..fileOffset = fileOffset;
}

PatternSwitchStatement createPatternSwitchStatement({
  required Expression expression,
  required List<PatternSwitchCase> cases,
  required DartType expressionType,
  required bool lastCaseTerminates,
  required int fileOffset,
}) {
  return new PatternSwitchStatement(expression, cases)
    ..expressionType = expressionType
    ..lastCaseTerminates = lastCaseTerminates
    ..fileOffset = fileOffset;
}

PatternVariableDeclaration createPatternVariableDeclaration({
  required Pattern pattern,
  required Expression initializer,
  required bool isFinal,
  required DartType matchedValueType,
  required int fileOffset,
}) {
  return new PatternVariableDeclaration(pattern, initializer, isFinal: isFinal)
    ..matchedValueType = matchedValueType
    ..fileOffset = fileOffset;
}

PositionalParameter createPositionalParameter({
  String? cosmeticName,
  required DartType type,
  Expression? defaultValue,
  bool isCovariantByDeclaration = false,
  bool isCovariantByClass = false,
  bool isRequired = false,
  bool isInitializingFormal = false,
  bool isSuperInitializingFormal = false,
  bool isFinal = false,
  bool hasDeclaredDefaultValue = false,
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
    isCovariantByClass: isCovariantByClass,
    isRequired: isRequired,
    isInitializingFormal: isInitializingFormal,
    isSuperInitializingFormal: isSuperInitializingFormal,
    isFinal: isFinal,
    hasDeclaredDefaultValue: hasDeclaredDefaultValue,
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

RecordPattern createRecordPattern({
  required List<Pattern> patterns,
  required RecordType requiredType,
  required DartType matchedValueType,
  required bool needsCheck,
  required RecordType lookupType,

  required int fileOffset,
}) {
  return new RecordPattern(patterns)
    ..requiredType = requiredType
    ..matchedValueType = matchedValueType
    ..needsCheck = needsCheck
    ..lookupType = lookupType
    ..fileOffset = fileOffset;
}

RedirectingFactoryTearOff createRedirectingFactoryTearOff(
  Procedure procedure, {
  required int fileOffset,
}) {
  assert(procedure.isRedirectingFactory);
  return new RedirectingFactoryTearOff(procedure)..fileOffset = fileOffset;
}

RelationalPattern createRelationalPattern({
  required RelationalPatternKind kind,
  required Expression expression,
  required DartType expressionType,
  required DartType matchedValueType,
  required RelationalAccessKind accessKind,
  required Name? name,
  required Procedure? target,
  required List<DartType>? typeArguments,
  required FunctionType? functionType,
  required int fileOffset,
}) {
  return new RelationalPattern(kind, expression)
    ..expressionType = expressionType
    ..matchedValueType = matchedValueType
    ..accessKind = accessKind
    ..name = name
    ..target = target
    ..typeArguments = typeArguments
    ..functionType = functionType
    ..fileOffset = fileOffset;
}

RestPattern createRestPattern({
  required Pattern? subPattern,
  required int fileOffset,
}) {
  return new RestPattern(subPattern)..fileOffset;
}

Expression createRethrow({required int fileOffset}) {
  return new Rethrow()..fileOffset = fileOffset;
}

ReturnStatement createReturnStatement(
  Expression? expression, {
  int? fileOffset,
}) {
  return new ReturnStatement(expression)
    ..fileOffset = fileOffset ?? expression!.fileOffset;
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

Expression createStringConcatenation(
  List<Expression> expressions, {
  required int fileOffset,
}) {
  return new StringConcatenation(expressions)..fileOffset = fileOffset;
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
SwitchCase createSwitchCase({
  required List<Expression> expressions,
  required List<int> expressionOffsets,
  required Statement body,
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

SwitchExpression createSwitchExpression({
  required Expression expression,
  required List<SwitchExpressionCase> cases,
  required DartType expressionType,
  required DartType staticType,
  required int fileOffset,
}) {
  return new SwitchExpression(expression, cases)
    ..expressionType = expressionType
    ..staticType = staticType
    ..fileOffset = fileOffset;
}

SwitchExpressionCase createSwitchExpressionCase({
  required PatternGuard patternGuard,
  required Expression expression,
  required int fileOffset,
}) {
  return new SwitchExpressionCase(patternGuard, expression)
    ..fileOffset = fileOffset;
}

/// Create a switch statement on the [expression] with the given [cases]. If
/// the switch is known to be exhaustive and without a default case,
/// [isExplicitlyExhaustive] should be set to `true`.
///
/// The [expressionType] is the static type of the switch expression.
SwitchStatement createSwitchStatement({
  required Expression expression,
  required List<SwitchCase> cases,
  required bool isExplicitlyExhaustive,
  required DartType expressionType,
  required int fileOffset,
}) {
  return new SwitchStatement(
      expression,
      cases,
      isExplicitlyExhaustive: isExplicitlyExhaustive,
    )
    ..expressionType = expressionType
    ..fileOffset = fileOffset;
}

SymbolLiteral createSymbolLiteral({
  required String value,
  required int fileOffset,
}) {
  return new SymbolLiteral(value)..fileOffset = fileOffset;
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

TypedefTearOff createTypedefTearOff({
  required List<StructuralParameter> structuralParameters,
  required Expression expression,
  required List<DartType> typeArguments,
  required int fileOffset,
}) {
  return new TypedefTearOff(structuralParameters, expression, typeArguments)
    ..fileOffset = fileOffset;
}

TypeLiteral createTypeLiteral(DartType type, {required int fileOffset}) {
  return new TypeLiteral(type)..fileOffset = fileOffset;
}

TypeParameter createTypeParameter(String? name, {required int fileOffset}) {
  return new TypeParameter(name)..fileOffset = fileOffset;
}

/// Creates an uninitialized [Variable] of the static [type].
SyntheticVariable createUninitializedVariable({
  required DartType type,
  String? name,
  required int fileOffset,
  bool isFinal = false,
  bool isLowered = false,
  bool isSynthesized = true,
  bool hasDeclaredInitializer = false,
}) {
  return new SyntheticVariable(
    cosmeticName: name,
    type: type,
    isFinal: isFinal,
    isLowered: isLowered,
    hasDeclaredInitializer: hasDeclaredInitializer,
    isSynthesized: isSynthesized,
  )..fileOffset = fileOffset;
}

/// Creates a declaration of an uninitialized [Variable] of the static [type].
VariableDeclaration createUninitializedVariableDeclaration({
  required DartType type,
  String? name,
  required int fileOffset,
  bool isFinal = false,
}) {
  return createVariableDeclaration(
    createUninitializedVariable(
      type: type,
      name: name,
      fileOffset: fileOffset,
      isFinal: isFinal,
    ),
  );
}

/// Creates a [Variable] for [expression] with the static [type]
/// using `expression.fileOffset` as the file offset for the declaration.
// TODO(johnniwinther): Merge the use of this with [createVariableCache].
SyntheticVariable createVariable(
  Expression expression,
  DartType type, {
  String? cosmeticName,
  int? fileOffset,
  bool isLowered = false,
  bool isSynthesized = true,
  bool isFinal = true,
}) {
  assert(expression is! ThisExpression);
  return new SyntheticVariable(
    cosmeticName: cosmeticName,
    initializer: expression,
    type: type,
    isLowered: isLowered,
    isFinal: isFinal,
    isSynthesized: isSynthesized,
    hasDeclaredInitializer: true,
  )..fileOffset = fileOffset ?? expression.fileOffset;
}

/// Creates a [Variable] for caching [expression] of the static
/// [type] using `expression.fileOffset` as the file offset for the declaration.
SyntheticVariable createVariableCache(
  Expression expression,
  DartType type, {
  int? fileOffset,
}) {
  return new SyntheticVariable(
    initializer: expression,
    type: type,
    isFinal: true,
    hasDeclaredInitializer: true,
  )..fileOffset = fileOffset ?? expression.fileOffset;
}

VariableDeclaration createVariableDeclaration(
  DeclaredVariable variable, {
  // TODO(johnniwinther): Make this required.
  Expression? initializer,
  List<VariableContext>? capturedContexts,
  int? fileOffset,
}) {
  if (initializer != null) {
    variable.initializer = initializer..parent = variable;
  }
  return new VariableDeclaration(variable)
    ..capturedContexts = capturedContexts
    ..fileOffset = fileOffset ?? variable.fileOffset;
}

/// Creates a [VariableGet] of [variable] using `variable.fileOffset` as the
/// file offset for the expression.
VariableGet createVariableGet(
  Variable variable, {
  DartType? promotedType,
  int? fileOffset,
}) {
  return new VariableGet(variable)
    ..fileOffset = fileOffset ?? variable.fileOffset
    ..promotedType = promotedType != variable.type ? promotedType : null;
}

VariablePattern createVariablePattern({
  required DartType? type,
  required DeclaredVariable variable,
  required DartType matchedValueType,
  required int fileOffset,
}) {
  return new VariablePattern(type, variable)
    ..matchedValueType = matchedValueType
    ..fileOffset = fileOffset;
}

/// Creates a [VariableSet] of [variable] with the [value].
Expression createVariableSet(
  Variable variable,
  Expression value, {
  bool allowFinalAssignment = false,
  required int fileOffset,
}) {
  if (variable is LocalFunctionVariable) {
    return createLocalFunctionInvocation(
      variable,
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

VariableStatement createVariableStatement(
  VariableDeclaration declaration, {
  int? fileOffset,
}) {
  return new VariableStatement(declaration)
    ..fileOffset = fileOffset ?? declaration.fileOffset;
}

Statement createWhileStatement(
  Expression condition,
  Statement body, {
  required Scope? scope,
  required int fileOffset,
}) {
  return new WhileStatement(condition, body)
    ..scope = scope
    ..fileOffset = fileOffset;
}

WildcardPattern createWildcardPattern({
  required DartType? type,
  required int fileOffset,
}) {
  return new WildcardPattern(type)..fileOffset = fileOffset;
}

YieldStatement createYieldStatement(
  Expression expression, {
  required bool isYieldStar,
  required int fileOffset,
}) {
  return new YieldStatement(expression, isYieldStar: isYieldStar)
    ..fileOffset = fileOffset;
}

/// Returns `true` if [node] is a pure expression.
///
/// A pure expression is an expression that is deterministic and side effect
/// free, such as `this` or a variable get of a final variable.
bool isPureExpression(Expression node) {
  if (node is ThisExpression) {
    return true;
  } else if (node is VariableGet) {
    return node.variable.isFinal && !node.variable.isLate;
  }
  return false;
}
