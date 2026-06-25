// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast_helper show isThisExpression;
import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

import '../base/problems.dart' show unsupported;
import '../type_inference/type_schema.dart';
import 'body_builder.dart';
import 'collections.dart'
    show
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfCaseElement,
        IfCaseMapEntry,
        IfElement,
        IfMapEntry,
        NullAwareElement,
        NullAwareMapEntry,
        PatternForElement,
        PatternForMapEntry,
        SpreadElement;
import 'external_ast_helper.dart' as extern;
import 'internal_ast.dart';

Expression checkLibraryIsLoaded(int fileOffset, LibraryDependency dependency) {
  return new CheckLibraryIsLoaded(dependency)..fileOffset = fileOffset;
}

InternalPattern createAndPattern(
  int fileOffset,
  InternalPattern left,
  InternalPattern right,
) {
  return new InternalAndPattern(left, right, fileOffset: fileOffset);
}

ActualArguments createArguments(
  int fileOffset, {
  required List<Argument> arguments,
  required bool hasNamedBeforePositional,
  required int positionalCount,
}) {
  return new ActualArguments(
    argumentList: arguments,
    hasNamedBeforePositional: hasNamedBeforePositional,
    positionalCount: positionalCount,
  )..fileOffset = fileOffset;
}

ActualArguments createArgumentsEmpty(int fileOffset) {
  return createArguments(
    fileOffset,
    arguments: [],
    hasNamedBeforePositional: false,
    positionalCount: 0,
  );
}

Expression createAsExpression(
  int fileOffset,
  Expression expression,
  DartType type, {
  bool forDynamic = false,
}) {
  return new AsExpression(expression, type)
    ..fileOffset = fileOffset
    ..isForDynamic = forDynamic;
}

/// Return a representation of an assert that appears in a constructor's
/// initializer list.
AssertInitializer createAssertInitializer(
  int fileOffset,
  AssertStatement assertStatement,
) {
  return new AssertInitializer(assertStatement)..fileOffset = fileOffset;
}

/// Return a representation of an assert that appears as a statement.
AssertStatement createAssertStatement(
  int fileOffset,
  Expression condition,
  Expression? message,
  int conditionStartOffset,
  int conditionEndOffset,
) {
  return new AssertStatement(
    condition,
    conditionStartOffset: conditionStartOffset,
    conditionEndOffset: conditionEndOffset,
    message: message,
  )..fileOffset = fileOffset;
}

InternalPattern createAssignedVariablePattern(
  int fileOffset,
  InternalVariable variable,
) {
  return new InternalAssignedVariablePattern(variable, fileOffset: fileOffset);
}

Expression createAwaitExpression(int fileOffset, Expression operand) {
  return new AwaitExpression(operand)..fileOffset = fileOffset;
}

BinaryExpression createBinary(
  int fileOffset,
  Expression left,
  Name binaryName,
  Expression right,
) {
  return new BinaryExpression(left, binaryName, right)..fileOffset = fileOffset;
}

/// Return a representation of a block of [statements] at the given
/// [fileOffset].
Block createBlock(
  List<Statement> statements, {
  required int fileOffset,
  required int fileEndOffset,
}) {
  List<Statement>? copy;
  for (int i = 0; i < statements.length; i++) {
    Statement statement = statements[i];
    if (statement is _VariablesDeclaration) {
      copy ??= new List<Statement>.of(statements.getRange(0, i));
      for (InternalVariableDeclaration declaration in statement.declarations) {
        copy.add(createVariableStatement(declaration));
      }
    } else if (copy != null) {
      copy.add(statement);
    }
  }
  return new Block(copy ?? statements)
    ..fileOffset = fileOffset
    ..fileEndOffset = fileEndOffset;
}

BlockExpression createBlockExpression(
  Block body,
  Expression value, {
  required int fileOffset,
}) {
  return new BlockExpression(body, value)..fileOffset = fileOffset;
}

/// Return a representation of a boolean literal at the given [fileOffset].
/// The literal has the given [value].
BoolLiteral createBoolLiteral(int fileOffset, bool value) {
  return new BoolLiteral(value)..fileOffset = fileOffset;
}

/// Return a representation of a break statement.
Statement createBreakStatement(int fileOffset, String? label) {
  return new InternalBreakStatement(label: label, fileOffset: fileOffset);
}

InternalPattern createCastPattern(
  int fileOffset,
  InternalPattern pattern,
  DartType type,
) {
  return new InternalCastPattern(pattern, type, fileOffset: fileOffset);
}

/// Return a representation of a catch clause.
InternalCatch createCatch(
  int fileOffset,
  DartType exceptionType,
  InternalCatchVariable? exceptionParameter,
  InternalCatchVariable? stackTraceParameter,
  DartType stackTraceType,
  Statement body,
) {
  return new InternalCatch(
    exception: exceptionParameter,
    body: body,
    guard: exceptionType,
    stackTrace: stackTraceParameter,
    fileOffset: fileOffset,
  );
}

InternalCatchVariable createCatchVariable({
  required String name,
  required DartType type,
  required bool isImplicitlyTyped,
  required bool isWildcard,
  required bool isFinal,
  required int fileOffset,
}) {
  return new InternalCatchVariable(
    astVariable: extern.createCatchVariable(
      name: name,
      type: type,
      isWildcard: isWildcard,
      isFinal: isFinal,
      fileOffset: fileOffset,
    ),
    isImplicitlyTyped: isImplicitlyTyped,
    fileOffset: fileOffset,
  );
}

/// Return a representation of a conditional expression at the given
/// [fileOffset]. The [condition] is the expression preceding the question
/// mark. The [thenExpression] is the expression following the question mark.
/// The [elseExpression] is the expression following the colon.
ConditionalExpression createConditionalExpression(
  int fileOffset,
  Expression condition,
  Expression thenExpression,
  Expression elseExpression,
) {
  return new ConditionalExpression(
    condition,
    thenExpression,
    elseExpression,
    const UnknownType(),
  )..fileOffset = fileOffset;
}

InternalPattern createConstantPattern(Expression expression) {
  return new InternalConstantPattern(
    expression: expression,
    fileOffset: expression.fileOffset,
  );
}

ConstructorTearOff createConstructorTearOff(int fileOffset, Member target) {
  assert(
    target is Constructor || (target is Procedure && target.isFactory),
    "Unexpected constructor tear off target: $target",
  );
  return new ConstructorTearOff(target)..fileOffset = fileOffset;
}

/// Return a representation of a continue statement.
Statement createContinueStatement(int fileOffset, String? label) {
  return new InternalContinueStatement(label: label, fileOffset: fileOffset);
}

Statement createContinueSwitchStatement({required int fileOffset}) {
  return new InternalContinueSwitchStatement(fileOffset: fileOffset);
}

/// Return a representation of a do statement.
Statement createDoStatement(
  int fileOffset,
  Statement body,
  Expression condition,
) {
  return new DoStatement(body, condition)..fileOffset = fileOffset;
}

DotShorthand createDotShorthandContext(
  int fileOffset,
  Expression innerExpression,
) {
  return new DotShorthand(innerExpression)..fileOffset = fileOffset;
}

DotShorthandInvocation createDotShorthandInvocation(
  int fileOffset,
  Name name,
  TypeArguments? typeArguments,
  ActualArguments arguments, {
  required int nameOffset,
  required bool isConst,
}) {
  return new DotShorthandInvocation(
    name,
    typeArguments,
    arguments,
    nameOffset: nameOffset,
    isConst: isConst,
  )..fileOffset = fileOffset;
}

DotShorthandPropertyGet createDotShorthandPropertyGet(
  int fileOffset,
  Name name, {
  required int nameOffset,
}) {
  return new DotShorthandPropertyGet(name, nameOffset: nameOffset)
    ..fileOffset = fileOffset;
}

/// Return a representation of a double literal at the given [fileOffset]. The
/// literal has the given [value].
DoubleLiteral createDoubleLiteral(int fileOffset, double value) {
  return new DoubleLiteral(value)..fileOffset = fileOffset;
}

/// Return a representation of an empty statement  at the given [fileOffset].
Statement createEmptyStatement(int fileOffset) {
  return new EmptyStatement()..fileOffset = fileOffset;
}

EqualsExpression createEquals(
  int fileOffset,
  Expression left,
  Expression right, {
  required bool isNot,
}) {
  return new EqualsExpression(left, right, isNot: isNot)
    ..fileOffset = fileOffset;
}

Expression createExpressionInvocation(
  int fileOffset,
  Expression expression,
  TypeArguments? typeArguments,
  ActualArguments arguments,
) {
  return new ExpressionInvocation(expression, typeArguments, arguments)
    ..fileOffset = fileOffset;
}

/// Return a representation of an expression statement at the given
/// [fileOffset] containing the [expression].
Statement createExpressionStatement(
  Expression expression, {
  required int fileOffset,
}) {
  return new ExpressionStatement(expression)..fileOffset = fileOffset;
}

ForElement createForElement(
  int fileOffset,
  List<InternalVariableDeclaration> variables,
  Expression? condition,
  List<Expression> updates,
  Expression body,
) {
  return new ForElement(variables, condition, updates, body)
    ..fileOffset = fileOffset;
}

ForInElement createForInElement(
  InternalForInElement element,
  Expression iterable,
  Expression body, {
  required bool isAsync,
  required int forOffset,
  required int fileOffset,
}) {
  return new ForInElement(
    element,
    iterable,
    body,
    isAsync: isAsync,
    forOffset: forOffset,
    fileOffset: fileOffset,
  );
}

ForInMapEntry createForInMapEntry(
  InternalForInElement element,
  Expression iterable,
  MapLiteralEntry body, {
  required bool isAsync,
  required int forOffset,
  required int fileOffset,
}) {
  return new ForInMapEntry(
    element,
    iterable,
    body,
    isAsync: isAsync,
    forOffset: forOffset,
    fileOffset: fileOffset,
  );
}

// Coverage-ignore(suite): Not run.
ForInStatement createForInStatement(
  Variable variable,
  Expression expression,
  Statement body, {
  required bool isAsync,
  required int fileOffset,
  required int bodyOffset,
}) {
  return new ForInStatement(variable, expression, body, isAsync: isAsync)
    ..fileOffset = fileOffset
    ..bodyOffset = bodyOffset;
}

ForMapEntry createForMapEntry(
  int fileOffset,
  List<InternalVariableDeclaration> variables,
  Expression? condition,
  List<Expression> updates,
  MapLiteralEntry body,
) {
  return new ForMapEntry(variables, condition, updates, body)
    ..fileOffset = fileOffset;
}

/// Return a representation of a for statement.
Statement createForStatement(
  int fileOffset,
  List<InternalVariableDeclaration>? variables,
  Expression? condition,
  List<Expression> updaters,
  Statement body,
) {
  return new InternalForStatement(
    variables ?? // Coverage-ignore(suite): Not run.
        [],
    condition,
    updaters,
    body,
  )..fileOffset = fileOffset;
}

InternalFunctionNode createFunctionNode({
  required Statement? body,
  required List<TypeParameter>? typeParameters,
  required List<InternalPositionalParameter> positionalParameters,
  required List<InternalNamedParameter> namedParameters,
  required int? requiredParameterCount,
  required DartType? returnType,
  required int fileOffset,
  required int? fileEndOffset,
  required AsyncMarker asyncMarker,
}) {
  return new InternalFunctionNode(
    returnType: returnType,
    typeParameters: typeParameters ?? [],
    positionalParameters: positionalParameters,
    namedParameters: namedParameters,
    requiredParameterCount: requiredParameterCount ?? 0,
    asyncMarker: asyncMarker,
    body: body,
    fileOffset: fileOffset,
    fileEndOffset: fileEndOffset ?? TreeNode.noOffset,
  );
}

Statement createFunctionDeclaration({
  required InternalVariable variable,
  required int fileOffset,
}) {
  return new InternalFunctionDeclaration(
    variable: variable,
    fileOffset: fileOffset,
  );
}

Expression createFunctionExpression({
  required InternalFunctionNode function,
  required int fileOffset,
}) {
  return new InternalFunctionExpression(
    function: function,
    fileOffset: fileOffset,
  );
}

Expression createIfCaseElement(
  int fileOffset, {
  required List<Statement> prelude,
  required Expression expression,
  required InternalPatternGuard patternGuard,
  required Expression then,
  Expression? otherwise,
}) {
  return new IfCaseElement(
    prelude: prelude,
    expression: expression,
    internalPatternGuard: patternGuard,
    then: then,
    otherwise: otherwise,
  )..fileOffset = fileOffset;
}

MapLiteralEntry createIfCaseMapEntry(
  int fileOffset, {
  required List<Statement> prelude,
  required Expression expression,
  required InternalPatternGuard patternGuard,
  required MapLiteralEntry then,
  MapLiteralEntry? otherwise,
}) {
  return new IfCaseMapEntry(
    prelude: prelude,
    expression: expression,
    internalPatternGuard: patternGuard,
    then: then,
    otherwise: otherwise,
  )..fileOffset = fileOffset;
}

Statement createIfCaseStatement(
  int fileOffset,
  Expression expression,
  InternalPatternGuard patternGuard,
  Statement then,
  Statement? otherwise,
) {
  return new InternalIfCaseStatement(
    expression: expression,
    patternGuard: patternGuard,
    then: then,
    otherwise: otherwise,
    fileOffset: fileOffset,
  );
}

Expression createIfElement(
  int fileOffset,
  Expression condition,
  Expression then, [
  Expression? otherwise,
]) {
  return new IfElement(condition, then, otherwise)..fileOffset = fileOffset;
}

MapLiteralEntry createIfMapEntry(
  int fileOffset,
  Expression condition,
  MapLiteralEntry then, [
  MapLiteralEntry? otherwise,
]) {
  return new IfMapEntry(condition, then, otherwise)..fileOffset = fileOffset;
}

/// Return a representation of an `if` statement.
Statement createIfStatement(
  int fileOffset,
  Expression condition,
  Statement thenStatement,
  Statement? elseStatement,
) {
  return new IfStatement(condition, thenStatement, elseStatement)
    ..fileOffset = fileOffset;
}

IndexGet createIndexGet(
  int fileOffset,
  Expression receiver,
  Expression index, {
  required bool isNullAware,
}) {
  return new IndexGet(receiver, index, isNullAware: isNullAware)
    ..fileOffset = fileOffset;
}

IndexSet createIndexSet(
  int fileOffset,
  Expression receiver,
  Expression index,
  Expression value, {
  required bool forEffect,
  required bool isNullAware,
}) {
  return new IndexSet(
    receiver,
    index,
    value,
    forEffect: forEffect,
    isNullAware: isNullAware,
  )..fileOffset = fileOffset;
}

Instantiation createInstantiation(
  Expression expression,
  List<DartType> typeArguments, {
  required int fileOffset,
}) {
  return new Instantiation(expression, typeArguments)..fileOffset = fileOffset;
}

/// Return a representation of an integer literal at the given [fileOffset].
/// The literal has the given [value].
Expression createIntLiteral(int fileOffset, int value, [String? literal]) {
  return new InternalIntLiteral(value, literal, fileOffset: fileOffset);
}

Expression createIntLiteralLarge(
  int fileOffset,
  String strippedLiteral,
  String literal,
) {
  return new LargeIntLiteral(strippedLiteral, literal, fileOffset: fileOffset);
}

InternalPattern createInvalidPattern(
  Expression expression, {
  required List<InternalVariable> declaredVariables,
}) {
  return new InternalInvalidPattern(
    invalidExpression: expression,
    declaredVariables: declaredVariables,
    fileOffset: expression.fileOffset,
  );
}

/// Return a representation of an `is` expression at the given [fileOffset].
/// The [operand] is the representation of the left operand. The [type] is a
/// representation of the type that is the right operand. If [notFileOffset]
/// is non-null the test is negated the that file offset.
Expression createIsExpression(
  int fileOffset,
  Expression operand,
  DartType type, {
  int? notFileOffset,
}) {
  Expression result = new IsExpression(operand, type)..fileOffset = fileOffset;
  if (notFileOffset != null) {
    result = createNot(notFileOffset, result);
  }
  return result;
}

/// The given [statement] is being used as the target of either a break or
/// continue statement. Return the statement that should be used as the actual
/// target.
LabeledStatement createLabeledStatement(Statement statement) {
  return new LabeledStatement(statement)..fileOffset = statement.fileOffset;
}

InternalVariable createLateVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isConst = false,
  bool isWildcard = false,
  required int fileOffset,
  Expression? initializer,
  bool hasDeclaredInitializer = false,
  bool forSyntheticToken = false,
  bool isImplicitlyTyped = false,
  bool isStaticLate = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new InternalLateVariable(
    astVariable: extern.createLateVariable(
      name: name,
      type: type,
      isFinal: isFinal,
      isConst: isConst,
      isWildcard: isWildcard,
      hasDeclaredInitializer: initializer != null,
      fileOffset: fileOffset,
      initializer: initializer,
      fileEqualsOffset: fileEqualsOffset,
    ),
    forSyntheticToken: forSyntheticToken,
    isImplicitlyTyped: isImplicitlyTyped,
    isStaticLate: isStaticLate,
    fileOffset: fileOffset,
  );
}

InternalLet createLetForEffect({
  required Expression effect,
  required DartType effectType,
  required Expression expression,
}) {
  return new InternalLet(
    createSyntheticVariableForValue(effect, type: effectType),
    expression,
  )..fileOffset = effect.fileOffset;
}

/// Return a representation of a list literal at the given [fileOffset]. The
/// [isConst] is `true` if the literal is either explicitly or implicitly a
/// constant. The [typeArgument] is the representation of the single valid
/// type argument preceding the list literal, or `null` if there is no type
/// argument, there is more than one type argument, or if the type argument
/// cannot be resolved. The list of [expressions] is a list of the
/// representations of the list elements.
ListLiteral createListLiteral(
  int fileOffset,
  DartType typeArgument,
  List<Expression> expressions, {
  required bool isConst,
}) {
  return new ListLiteral(
    expressions,
    typeArgument: typeArgument,
    isConst: isConst,
  )..fileOffset = fileOffset;
}

InternalPattern createListPattern(
  int fileOffset,
  DartType? typeArgument,
  List<InternalPattern> patterns,
) {
  return new InternalListPattern(
    typeArgument: typeArgument,
    patterns: patterns,
    fileOffset: fileOffset,
  );
}

LoadLibrary createLoadLibrary(
  int fileOffset,
  LibraryDependency dependency,
  ActualArguments? arguments,
) {
  return new LoadLibraryImpl(dependency, arguments)..fileOffset = fileOffset;
}

InternalVariable createLocalVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isConst = false,
  bool isWildcard = false,
  required int fileOffset,
  Expression? initializer,
  bool hasDeclaredInitializer = false,
  bool forSyntheticToken = false,
  bool isImplicitlyTyped = false,
  bool isStaticLate = false,
  bool isLocalFunction = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new InternalLocalVariable(
    astVariable: extern.createLocalVariable(
      name: name,
      type: type,
      isFinal: isFinal,
      isConst: isConst,
      isWildcard: isWildcard,
      initializer: initializer,
      hasDeclaredInitializer: hasDeclaredInitializer,
      fileOffset: fileOffset,
      fileEqualsOffset: fileEqualsOffset,
    ),
    forSyntheticToken: forSyntheticToken,
    isImplicitlyTyped: isImplicitlyTyped,
    fileOffset: fileOffset,
    isStaticLate: isStaticLate,
    isLocalFunction: isLocalFunction,
    fileEqualsOffset: fileEqualsOffset,
  );
}

/// Return a representation of a logical expression at the given [fileOffset]
/// having the [leftOperand], [rightOperand] and the [operatorString]
/// (either `&&` or `||`).
Expression createLogicalExpression(
  int fileOffset,
  Expression leftOperand,
  String operatorString,
  Expression rightOperand,
) {
  LogicalExpressionOperator operator;
  if (operatorString == '&&') {
    operator = LogicalExpressionOperator.AND;
  } else if (operatorString == '||') {
    operator = LogicalExpressionOperator.OR;
  } else {
    throw new UnsupportedError("Unhandled logical operator '$operatorString'");
  }

  return new LogicalExpression(leftOperand, operator, rightOperand)
    ..fileOffset = fileOffset;
}

/// Return a representation of a key/value pair in a literal map at the given
/// [fileOffset]. The [key] is the representation of the expression used to
/// compute the key. The [value] is the representation of the expression used
/// to compute the value.
MapLiteralEntry createMapEntry(
  int fileOffset,
  Expression key,
  Expression value,
) {
  return new MapLiteralEntry(key, value)..fileOffset = fileOffset;
}

/// Return a representation of a map literal at the given [fileOffset]. The
/// [isConst] is `true` if the literal is either explicitly or implicitly a
/// constant. The [keyType] is the representation of the first type argument
/// preceding the map literal, or `null` if there are not exactly two type
/// arguments or if the first type argument cannot be resolved. The
/// [valueType] is the representation of the second type argument preceding
/// the map literal, or `null` if there are not exactly two type arguments or
/// if the second type argument cannot be resolved. The list of [entries] is a
/// list of the representations of the map entries.
MapLiteral createMapLiteral(
  int fileOffset,
  DartType keyType,
  DartType valueType,
  List<MapLiteralEntry> entries, {
  required bool isConst,
}) {
  return new MapLiteral(
    entries,
    keyType: keyType,
    valueType: valueType,
    isConst: isConst,
  )..fileOffset = fileOffset;
}

MapLiteralEntry createMapLiteralEntry(
  Expression key,
  Expression value, {
  required int fileOffset,
}) {
  return new MapLiteralEntry(key, value)..fileOffset = fileOffset;
}

InternalPattern createMapPattern(
  int fileOffset,
  DartType? keyType,
  DartType? valueType,
  List<InternalMapPatternEntry> entries,
) {
  return new InternalMapPattern(
    keyType: keyType,
    valueType: valueType,
    entries: entries,
    fileOffset: fileOffset,
  );
}

InternalMapPatternEntry createMapPatternEntry(
  int fileOffset,
  Expression key,
  InternalPattern value,
) {
  return new InternalMapPatternEntry(
    key: key,
    value: value,
    fileOffset: fileOffset,
  );
}

InternalMapPatternRestEntry createMapPatternRestEntry(int fileOffset) {
  return new InternalMapPatternRestEntry(fileOffset: fileOffset);
}

Expression createMethodInvocation(
  int fileOffset,
  Expression expression,
  Name name,
  TypeArguments? typeArguments,
  ActualArguments arguments, {
  required bool isNullAware,
}) {
  return new MethodInvocation(
    expression,
    name,
    typeArguments,
    arguments,
    isNullAware: isNullAware,
  )..fileOffset = fileOffset;
}

NamedExpression createNamedExpression(
  String name,
  Expression value, {
  required int fileOffset,
}) {
  return new NamedExpression(name, value)..fileOffset = fileOffset;
}

InternalNamedParameter createNamedParameter({
  required String parameterName,
  required DartType type,
  Expression? defaultValue,
  bool isCovariantByDeclaration = false,
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
  bool isImplicitlyTyped = false,
  bool forSyntheticToken = false,
}) {
  return new InternalNamedParameter(
    astVariable: extern.createNamedParameter(
      parameterName: parameterName,
      type: type,
      defaultValue: defaultValue,
      isCovariantByDeclaration: isCovariantByDeclaration,
      isRequired: isRequired,
      isInitializingFormal: isInitializingFormal,
      isSuperInitializingFormal: isSuperInitializingFormal,
      isFinal: isFinal,
      hasDeclaredDefaultValue: hasDeclaredDefaultValue,
      isSynthesized: isSynthesized,
      isWildcard: isWildcard,
      isRenamedPrivateNamedParameter: isRenamedPrivateNamedParameter,
      fileOffset: fileOffset,
    ),
    isImplicitlyTyped: isImplicitlyTyped,
    forSyntheticToken: forSyntheticToken,
    fileOffset: fileOffset,
  );
}

InternalPattern createNamedPattern(
  int fileOffset,
  String name,
  InternalPattern pattern,
) {
  return new InternalNamedPattern(
    name: name,
    pattern: pattern,
    fileOffset: fileOffset,
  );
}

Expression createNot(int fileOffset, Expression operand) {
  return new Not(operand)..fileOffset = fileOffset;
}

InternalPattern createNullAssertPattern(
  int fileOffset,
  InternalPattern pattern,
) {
  return new InternalNullAssertPattern(
    pattern: pattern,
    fileOffset: fileOffset,
  );
}

Expression createNullAwareElement(int fileOffset, Expression expression) {
  return new NullAwareElement(expression)..fileOffset = fileOffset;
}

/// Return a representation of a null-aware key/value pair, were either the
/// key or the value might be `null`, in a literal map at the given
/// [fileOffset]. The [key] is the representation of the expression used to
/// compute the key. The [value] is the representation of the expression used
/// to compute the value.
NullAwareMapEntry createNullAwareMapEntry(
  int fileOffset, {
  required bool isKeyNullAware,
  required Expression key,
  required bool isValueNullAware,
  required Expression value,
}) {
  return new NullAwareMapEntry(
    isKeyNullAware: isKeyNullAware,
    key: key,
    isValueNullAware: isValueNullAware,
    value: value,
  )..fileOffset = fileOffset;
}

NullCheck createNullCheck(int fileOffset, Expression expression) {
  return new NullCheck(expression)..fileOffset = fileOffset;
}

InternalPattern createNullCheckPattern(
  int fileOffset,
  InternalPattern pattern,
) {
  return new InternalNullCheckPattern(pattern: pattern, fileOffset: fileOffset);
}

/// Return a representation of a null literal at the given [fileOffset].
NullLiteral createNullLiteral(int fileOffset) {
  return new NullLiteral()..fileOffset = fileOffset;
}

InternalPattern createOrPattern(
  int fileOffset,
  InternalPattern left,
  InternalPattern right, {
  required List<InternalVariable> orPatternJointVariables,
}) {
  return new InternalOrPattern(
    left,
    right,
    orPatternJointVariables: orPatternJointVariables,
    fileOffset: fileOffset,
  );
}

InternalPattern createObjectPattern({
  required DartType requiredType,
  required List<InternalNamedPattern> fields,
  required Typedef? typedef,
  required bool hasExplicitTypeArguments,
  required int fileOffset,
}) {
  return new InternalObjectPattern(
    requiredType: requiredType,
    fields: fields,
    typedef: typedef,
    hasExplicitTypeArguments: hasExplicitTypeArguments,
    fileOffset: fileOffset,
  );
}

ParenthesizedExpression createParenthesized(
  int fileOffset,
  Expression expression,
) {
  return new ParenthesizedExpression(expression)..fileOffset = fileOffset;
}

Expression createPatternAssignment(
  int fileOffset,
  InternalPattern pattern,
  Expression expression,
) {
  return new InternalPatternAssignment(
    pattern: pattern,
    expression: expression,
    fileOffset: fileOffset,
  );
}

PatternForElement createPatternForElement(
  int fileOffset, {
  required InternalPatternVariableDeclaration patternVariableDeclaration,
  required List<InternalVariableDeclaration> intermediateVariables,
  required List<InternalVariableDeclaration> variables,
  required Expression? condition,
  required List<Expression> updates,
  required Expression body,
}) {
  return new PatternForElement(
    internalPatternVariableDeclaration: patternVariableDeclaration,
    intermediateVariables: intermediateVariables,
    internalVariables: variables,
    condition: condition,
    updates: updates,
    body: body,
  )..fileOffset = fileOffset;
}

PatternForMapEntry createPatternForMapEntry(
  int fileOffset, {
  required InternalPatternVariableDeclaration patternVariableDeclaration,
  required List<InternalVariableDeclaration> intermediateVariables,
  required List<InternalVariableDeclaration> variableInitializations,
  required Expression? condition,
  required List<Expression> updates,
  required MapLiteralEntry body,
}) {
  return new PatternForMapEntry(
    internalPatternVariableDeclaration: patternVariableDeclaration,
    intermediateVariables: intermediateVariables,
    internalVariables: variableInitializations,
    condition: condition,
    updates: updates,
    body: body,
  )..fileOffset = fileOffset;
}

InternalPatternGuard createPatternGuard(
  int fileOffset,
  InternalPattern pattern, [
  Expression? guard,
]) {
  return new InternalPatternGuard(
    pattern: pattern,
    guard: guard,
    fileOffset: fileOffset,
  );
}

InternalPatternSwitchCase createPatternSwitchCase(
  int fileOffset,
  List<int> caseOffsets,
  List<InternalPatternGuard> patternGuards,
  Statement body, {
  required bool isDefault,
  required List<Label>? labels,
  required List<InternalVariable>? jointVariables,
  required List<int>? jointVariableFirstUseOffsets,
}) {
  return new InternalPatternSwitchCase(
    caseOffsets: caseOffsets,
    patternGuards: patternGuards,
    body: body,
    isDefault: isDefault,
    labels: labels,
    jointVariables: jointVariables ?? [],
    jointVariableFirstUseOffsets: jointVariableFirstUseOffsets,
    fileOffset: fileOffset,
  );
}

Statement createPatternSwitchStatement(
  int fileOffset,
  Expression expression,
  List<InternalPatternSwitchCase> cases,
) {
  return new InternalPatternSwitchStatement(
    expression: expression,
    cases: cases,
    fileOffset: fileOffset,
  );
}

Statement createPatternVariableDeclaration(
  int fileOffset,
  InternalPattern pattern,
  Expression initializer, {
  required bool isFinal,
}) {
  return new InternalPatternVariableDeclaration(
    pattern: pattern,
    initializer: initializer,
    isFinal: isFinal,
    fileOffset: fileOffset,
  );
}

InternalPositionalParameter createPositionalParameter({
  String? cosmeticName,
  required DartType type,
  bool isImplicitlyTyped = false,
  Expression? defaultValue,
  bool hasDeclaredDefaultValue = false,
  bool isCovariantByDeclaration = false,
  bool isRequired = false,
  bool isInitializingFormal = false,
  bool isSuperInitializingFormal = false,
  bool isFinal = false,
  bool isLowered = false,
  bool isSynthesized = false,
  bool isWildcard = false,
  required int fileOffset,
  bool forSyntheticToken = false,
}) {
  return new InternalPositionalParameter(
    astVariable: extern.createPositionalParameter(
      cosmeticName: cosmeticName,
      type: type,
      defaultValue: defaultValue,
      isCovariantByDeclaration: isCovariantByDeclaration,
      isInitializingFormal: isInitializingFormal,
      isSuperInitializingFormal: isSuperInitializingFormal,
      isFinal: isFinal,
      hasDeclaredDefaultValue: hasDeclaredDefaultValue,
      isLowered: isLowered,
      isSynthesized: isSynthesized,
      isWildcard: isWildcard,
      fileOffset: fileOffset,
    ),
    forSyntheticToken: forSyntheticToken,
    isImplicitlyTyped: isImplicitlyTyped,
    fileOffset: fileOffset,
  );
}

Expression createPropertyGet(
  int fileOffset,
  Expression receiver,
  Name name, {
  required bool isNullAware,
}) {
  return new PropertyGet(receiver, name, isNullAware: isNullAware)
    ..fileOffset = fileOffset;
}

Expression createPropertySet(
  int fileOffset,
  Expression receiver,
  Name name,
  Expression value, {
  required bool forEffect,
  bool readOnlyReceiver = false,
  required bool isNullAware,
}) {
  return new PropertySet(
    receiver,
    name,
    value,
    forEffect: forEffect,
    readOnlyReceiver: readOnlyReceiver,
    isNullAware: isNullAware,
  )..fileOffset = fileOffset;
}

InternalPattern createRecordPattern(
  int fileOffset,
  List<InternalPattern> patterns,
) {
  return new InternalRecordPattern(patterns: patterns, fileOffset: fileOffset);
}

RedirectingFactoryTearOff createRedirectingFactoryTearOff(
  int fileOffset,
  Procedure procedure,
) {
  assert(procedure.isRedirectingFactory);
  return new RedirectingFactoryTearOff(procedure)..fileOffset = fileOffset;
}

InternalPattern createRelationalPattern(
  int fileOffset,
  RelationalPatternKind kind,
  Expression expression,
) {
  return new InternalRelationalPattern(
    kind: kind,
    expression: expression,
    fileOffset: fileOffset,
  );
}

InternalPattern createRestPattern(int fileOffset, InternalPattern? subPattern) {
  return new InternalRestPattern(
    subPattern: subPattern,
    fileOffset: fileOffset,
  );
}

/// Return a representation of a rethrow statement consisting of the
/// rethrow at [rethrowFileOffset] and the statement at [statementFileOffset].
Statement createRethrowStatement(
  int rethrowFileOffset,
  int statementFileOffset,
) {
  return new ExpressionStatement(new Rethrow()..fileOffset = rethrowFileOffset)
    ..fileOffset = statementFileOffset;
}

/// Return a representation of a return statement.
Statement createReturnStatement(
  int fileOffset,
  Expression? expression, {
  bool isArrow = true,
}) {
  return new ReturnStatementImpl(isArrow, expression)..fileOffset = fileOffset;
}

/// Return a representation of a set literal at the given [fileOffset]. The
/// [isConst] is `true` if the literal is either explicitly or implicitly a
/// constant. The [typeArgument] is the representation of the single valid
/// type argument preceding the set literal, or `null` if there is no type
/// argument, there is more than one type argument, or if the type argument
/// cannot be resolved. The list of [expressions] is a list of the
/// representations of the set elements.
SetLiteral createSetLiteral(
  int fileOffset,
  DartType typeArgument,
  List<Expression> expressions, {
  required bool isConst,
}) {
  return new SetLiteral(
    expressions,
    typeArgument: typeArgument,
    isConst: isConst,
  )..fileOffset = fileOffset;
}

Expression createSpreadElement(
  int fileOffset,
  Expression expression, {
  required bool isNullAware,
}) {
  return new SpreadElement(expression, isNullAware: isNullAware)
    ..fileOffset = fileOffset;
}

StaticGet createStaticGet(int fileOffset, Member target) {
  assert(target is Field || (target is Procedure && target.isGetter));
  return new StaticGet(target)..fileOffset = fileOffset;
}

StaticSet createStaticSet(
  Member target,
  Expression value, {
  required int fileOffset,
}) {
  assert(target is Field || (target is Procedure && target.isSetter));
  return new StaticSet(target, value)..fileOffset = fileOffset;
}

StaticTearOff createStaticTearOff(int fileOffset, Procedure procedure) {
  assert(
    procedure.kind == ProcedureKind.Method,
    "Unexpected static tear off target: $procedure",
  );
  assert(
    !procedure.isRedirectingFactory,
    "Unexpected static tear off target: $procedure",
  );
  return new StaticTearOff(procedure)..fileOffset = fileOffset;
}

Expression createStringConcatenation(
  int fileOffset,
  List<Expression> expressions,
) {
  assert(fileOffset != TreeNode.noOffset);
  return new StringConcatenation(expressions)..fileOffset = fileOffset;
}

/// Return a representation of a simple string literal at the given
/// [fileOffset]. The literal has the given [value]. This does not include
/// either adjacent strings or interpolated strings.
StringLiteral createStringLiteral(int fileOffset, String value) {
  return new StringLiteral(value)..fileOffset = fileOffset;
}

Expression createSuperMethodInvocation(
  int fileOffset,
  Name name,
  Procedure procedure,
  TypeArguments? typeArguments,
  ActualArguments arguments,
) {
  return new InternalSuperMethodInvocation(
    name,
    typeArguments,
    arguments,
    procedure,
  )..fileOffset = fileOffset;
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

Expression createSwitchExpression(
  int fileOffset,
  Expression expression,
  List<InternalSwitchExpressionCase> cases,
) {
  return new InternalSwitchExpression(
    expression: expression,
    cases: cases,
    fileOffset: fileOffset,
  );
}

InternalSwitchExpressionCase createSwitchExpressionCase(
  int fileOffset,
  InternalPatternGuard patternGuard,
  Expression expression,
) {
  return new InternalSwitchExpressionCase(
    patternGuard: patternGuard,
    expression: expression,
    fileOffset: fileOffset,
  );
}

Statement createSwitchStatement(
  Expression expression,
  List<InternalSwitchStatementCase> cases, {
  required int fileOffset,
}) {
  return new InternalRegularSwitchStatement(
    expression: expression,
    cases: cases,
    fileOffset: fileOffset,
  );
}

InternalSwitchStatementCase createSwitchStatementCase({
  required List<Expression> expressions,
  required List<int> expressionOffsets,
  required Statement body,
  required bool isDefault,
  required List<int> caseOffsets,
  required List<Label>? labels,
  required int fileOffset,
}) {
  return new InternalSwitchStatementCase(
    caseOffsets: caseOffsets,
    expressions: expressions,
    expressionOffsets: expressionOffsets,
    body: body,
    isDefault: isDefault,
    labels: labels,
    fileOffset: fileOffset,
  );
}

/// Return a representation of a symbol literal defined by [value] at the
/// given [fileOffset].
SymbolLiteral createSymbolLiteral(int fileOffset, String value) {
  return new SymbolLiteral(value)..fileOffset = fileOffset;
}

InternalAnonymousMethodParameter createAnonymousMethodParameter({
  required String name,
  required DartType type,
  required int fileOffset,
  required bool isImplicitlyTyped,
  required bool isWildcard,
  required bool isFinal,
  required bool isSynthesized,
}) {
  return new InternalAnonymousMethodParameter(
    astVariable: new SyntheticVariable(
      cosmeticName: name,
      isFinal: isFinal,
      isSynthesized: isSynthesized,
      type: type,
    )..fileOffset = fileOffset,
    isImplicitlyTyped: isImplicitlyTyped,
    isWildcard: isWildcard,
    fileOffset: fileOffset,
  );
}

InternalSyntheticVariable createSyntheticVariable({
  String? name,
  DartType? type,
  required int fileOffset,
  Expression? initializer,
  bool isFinal = false,
  bool isLowered = false,
  bool isSynthesized = true,
}) {
  return new InternalSyntheticVariable(
    astVariable: new SyntheticVariable(
      cosmeticName: name,
      type: type ?? const DynamicType(),
      isFinal: isFinal,
      isLowered: isLowered,
      isSynthesized: isSynthesized,
      initializer: initializer,
    )..fileOffset = fileOffset,
    isImplicitlyTyped: type == null,
    fileOffset: fileOffset,
  );
}

InternalVariable createSyntheticVariableForEffect(Expression expression) {
  return createSyntheticVariable(
    initializer: expression,
    isFinal: true,
    fileOffset: expression.fileOffset,
    type: const DynamicType(),
    isSynthesized: true,
  );
}

InternalSyntheticVariable createSyntheticVariableForValue(
  Expression initializer, {
  DartType? type,
  String? name,
  int? fileOffset,
}) {
  return createSyntheticVariable(
    name: name,
    initializer: initializer,
    isFinal: true,
    fileOffset: fileOffset ?? initializer.fileOffset,
    type: type,
    isSynthesized: true,
  );
}

Expression createThisExpression({required int fileOffset}) {
  return new ThisExpression()..fileOffset = fileOffset;
}

InternalThisVariable createThisVariable({
  required DartType type,
  required int fileOffset,
}) {
  return new InternalThisVariable(
    astVariable: new ThisVariable(type: type)..fileOffset = fileOffset,
    fileOffset: fileOffset,
  );
}

/// Return a representation of a throw expression at the given [fileOffset].
Expression createThrow(int fileOffset, Expression expression) {
  return new Throw(expression)..fileOffset = fileOffset;
}

Statement createTryStatement(
  int fileOffset,
  Statement tryBlock,
  List<InternalCatch>? catchBlocks,
  Statement? finallyBlock,
) {
  return new TryStatement(tryBlock, catchBlocks ?? [], finallyBlock)
    ..fileOffset = fileOffset;
}

TypedefTearOff createTypedefTearOff(
  int fileOffset,
  List<StructuralParameter> typeParameters,
  Expression expression,
  List<DartType> typeArguments,
) {
  return new TypedefTearOff(typeParameters, expression, typeArguments)
    ..fileOffset = fileOffset;
}

TypeLiteral createTypeLiteral(int fileOffset, DartType type) {
  return new TypeLiteral(type)..fileOffset = fileOffset;
}

TypeParameterType createTypeParameterTypeWithDefaultNullabilityForLibrary(
  TypeParameter typeParameter,
  Library library,
) {
  return new TypeParameterType.withDefaultNullability(typeParameter);
}

UnaryExpression createUnary(
  int fileOffset,
  Name unaryName,
  Expression expression,
) {
  return new UnaryExpression(unaryName, expression)..fileOffset = fileOffset;
}

InternalVariableDeclaration createVariableDeclaration(
  InternalVariable variable, {
  int? fileOffset,
}) {
  return new InternalVariableDeclaration(variable)
    ..fileOffset = fileOffset ?? variable.fileOffset;
}

InternalVariableGet createVariableGet(
  InternalVariable variable, {
  required int fileOffset,
}) {
  return new InternalVariableGet(variable)..fileOffset = fileOffset;
}

InternalPattern createVariablePattern(
  int fileOffset,
  DartType? type,
  InternalVariable variable,
) {
  return new InternalVariablePattern(
    type: type,
    variable: variable,
    fileOffset: fileOffset,
  );
}

InternalVariableSet createVariableSet(
  InternalVariable variable,
  Expression value, {
  required int fileOffset,
}) {
  return new InternalVariableSet(variable, value)..fileOffset = fileOffset;
}

InternalVariableStatement createVariableStatement(
  InternalVariableDeclaration declaration, {
  int? fileOffset,
}) {
  return new InternalVariableStatement(declaration)
    ..fileOffset = fileOffset ?? declaration.fileOffset;
}

/// Return a representation of a while statement at the given [fileOffset]
/// consisting of the given [condition] and [body].
Statement createWhileStatement(
  int fileOffset,
  Expression condition,
  Statement body,
) {
  return new WhileStatement(condition, body)..fileOffset = fileOffset;
}

InternalPattern createWildcardPattern(int fileOffset, DartType? type) {
  return new InternalWildcardPattern(type: type, fileOffset: fileOffset);
}

/// Return a representation of a yield statement at the given [fileOffset]
/// of the given [expression]. If [isYieldStar] is `true` the created
/// statement is a yield* statement.
Statement createYieldStatement(
  int fileOffset,
  Expression expression, {
  required bool isYieldStar,
}) {
  return new YieldStatement(expression, isYieldStar: isYieldStar)
    ..fileOffset = fileOffset;
}

bool isErroneousNode(Object? node) {
  if (node is ExpressionStatement) {
    // Coverage-ignore-block(suite): Not run.
    ExpressionStatement statement = node;
    node = statement.expression;
  }
  if (node is Variable) {
    // Coverage-ignore-block(suite): Not run.
    Variable variable = node;
    node = variable.initializer;
  }
  if (node is Let) {
    // Coverage-ignore-block(suite): Not run.
    Let let = node;
    node = let.variable.initializer;
  }
  return node is InvalidExpression;
}

bool isThisExpression(Object node) =>
    node is Expression && ast_helper.isThisExpression(node);

bool isVariablesDeclaration(Object? node) => node is _VariablesDeclaration;

_VariablesDeclaration variablesDeclaration(
  List<InternalVariableDeclaration> declarations,
  Uri uri,
) {
  return new _VariablesDeclaration(declarations, uri);
}

List<InternalVariableDeclaration> variablesDeclarationExtractDeclarations(
  Object? variablesDeclaration,
) {
  return (variablesDeclaration as _VariablesDeclaration).declarations;
}

Statement wrapVariables(Statement statement) {
  if (statement is _VariablesDeclaration) {
    return new Block(
      new List<Statement>.generate(
        statement.declarations.length,
        (int index) => createVariableStatement(statement.declarations[index]),
        growable: true,
      ),
    )..fileOffset = statement.fileOffset;
  } else if (statement is InternalVariableStatement) {
    return new Block(<Statement>[statement])..fileOffset = statement.fileOffset;
  } else {
    return statement;
  }
}

class _VariablesDeclaration extends AuxiliaryStatement {
  final List<InternalVariableDeclaration> declarations;
  final Uri uri;

  new(this.declarations, this.uri) {
    setParents(declarations, this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(v) {
    throw unsupported("accept", fileOffset, uri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(v, arg) {
    throw unsupported("accept1", fileOffset, uri);
  }

  @override
  String toString() {
    return "_VariablesDeclaration(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < declarations.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableInitialization(
        declarations[index].variable.astVariable,
        includeModifiersAndType: index == 0,
      );
    }
    printer.write(';');
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never transformChildren(v) {
    throw unsupported("transformChildren", fileOffset, uri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never transformOrRemoveChildren(v) {
    throw unsupported("transformOrRemoveChildren", fileOffset, uri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never visitChildren(v) {
    throw unsupported("visitChildren", fileOffset, uri);
  }
}
