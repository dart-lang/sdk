// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../builder/declaration_builders.dart';
import '../source/check_helper.dart';
import 'body_builder.dart';
import 'external_ast_helper.dart' as extern;
import 'internal_ast.dart';

InternalPattern createAndPattern(
  int fileOffset,
  InternalPattern left,
  InternalPattern right,
) {
  return new InternalAndPattern(left, right, fileOffset: fileOffset);
}

AnonymousMethodBlock createAnonymousMethodBlock({
  required InternalAnonymousMethodParameter variable,
  required InternalExpression receiver,
  required InternalStatement body,
  required bool isImplicitlyTyped,
  required bool isNullAware,
  required bool isCascade,
  required int typeOffset,
  required int fileOffset,
}) {
  return new AnonymousMethodBlock(
    variable: variable,
    receiver: receiver,
    body: body,
    isImplicitlyTyped: isImplicitlyTyped,
    isNullAware: isNullAware,
    isCascade: isCascade,
    typeOffset: typeOffset,
    fileOffset: fileOffset,
  );
}

AnonymousMethodExpression createAnonymousMethodExpression({
  required InternalAnonymousMethodParameter variable,
  required InternalExpression receiver,
  required InternalExpression body,
  required bool isImplicitlyTyped,
  required bool isNullAware,
  required bool isCascade,
  required int typeOffset,
  required int fileOffset,
}) {
  return new AnonymousMethodExpression(
    variable: variable,
    receiver: receiver,
    body: body,
    isImplicitlyTyped: isImplicitlyTyped,
    isNullAware: isNullAware,
    isCascade: isCascade,
    typeOffset: typeOffset,
    fileOffset: fileOffset,
  );
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
    name: name,
    type: type,
    isSynthesized: isSynthesized,
    isFinal: isFinal,
    isImplicitlyTyped: isImplicitlyTyped,
    isWildcard: isWildcard,
    fileOffset: fileOffset,
  );
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
    fileOffset: fileOffset,
  );
}

ActualArguments createArgumentsEmpty(int fileOffset) {
  return createArguments(
    fileOffset,
    arguments: [],
    hasNamedBeforePositional: false,
    positionalCount: 0,
  );
}

InternalExpression createAsExpression(
  int fileOffset,
  InternalExpression expression,
  DartType type,
) {
  return new InternalAsExpression(expression, type, fileOffset: fileOffset);
}

/// Return a representation of an assert that appears in a constructor's
/// initializer list.
InternalAssertInitializer createAssertInitializer(
  InternalAssertStatement assertStatement, {
  required int fileOffset,
}) {
  return new InternalAssertInitializer(assertStatement, fileOffset: fileOffset);
}

/// Return a representation of an assert that appears as a statement.
InternalAssertStatement createAssertStatement(
  int fileOffset,
  InternalExpression condition,
  InternalExpression? message,
  int conditionStartOffset,
  int conditionEndOffset,
) {
  return new InternalAssertStatement(
    condition,
    conditionStartOffset: conditionStartOffset,
    conditionEndOffset: conditionEndOffset,
    message: message,
    fileOffset: fileOffset,
  );
}

InternalPattern createAssignedVariablePattern(
  int fileOffset,
  InternalVariable variable,
) {
  return new InternalAssignedVariablePattern(variable, fileOffset: fileOffset);
}

InternalExpression createAwaitExpression(
  int fileOffset,
  InternalExpression operand,
) {
  return new InternalAwaitExpression(operand, fileOffset: fileOffset);
}

BinaryExpression createBinary(
  int fileOffset,
  InternalExpression left,
  Name binaryName,
  InternalExpression right,
) {
  return new BinaryExpression(left, binaryName, right, fileOffset: fileOffset);
}

/// Return a representation of a block of [statements] at the given
/// [fileOffset].
InternalBlock createBlock(
  List<InternalStatement> statements, {
  required int fileOffset,
  required int fileEndOffset,
}) {
  List<InternalStatement>? copy;
  for (int i = 0; i < statements.length; i++) {
    InternalStatement statement = statements[i];
    if (statement is MultiVariableDeclaration) {
      copy ??= new List<InternalStatement>.of(statements.getRange(0, i));
      for (InternalVariableDeclaration declaration in statement.declarations) {
        copy.add(createVariableStatement(declaration));
      }
    } else if (copy != null) {
      copy.add(statement);
    }
  }
  return new InternalBlock(
    copy ?? statements,
    fileOffset: fileOffset,
    fileEndOffset: fileEndOffset,
  );
}

InternalBlockExpression createBlockExpression(
  InternalBlock body,
  InternalExpression value, {
  required int fileOffset,
}) {
  return new InternalBlockExpression(body, value, fileOffset: fileOffset);
}

/// Return a representation of a boolean literal at the given [fileOffset].
/// The literal has the given [value].
InternalExpression createBoolLiteral(bool value, {required int fileOffset}) {
  return new InternalBoolLiteral(value, fileOffset: fileOffset);
}

/// Return a representation of a break statement.
InternalBreakStatement createBreakStatement(int fileOffset, String? label) {
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
  InternalStatement body,
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
    name: name,
    type: type,
    isWildcard: isWildcard,
    isFinal: isFinal,
    isImplicitlyTyped: isImplicitlyTyped,
    fileOffset: fileOffset,
  );
}

InternalExpression createCompoundIndexSet({
  required InternalExpression receiver,
  required InternalExpression index,
  required Name binaryName,
  required InternalExpression value,
  required int readOffset,
  required int binaryOffset,
  required int writeOffset,
  required bool forEffect,
  required bool forPostIncDec,
  required bool isNullAware,
}) {
  return new CompoundIndexSet(
    receiver: receiver,
    index: index,
    binaryName: binaryName,
    value: value,
    readOffset: readOffset,
    binaryOffset: binaryOffset,
    writeOffset: writeOffset,
    forEffect: forEffect,
    forPostIncDec: forPostIncDec,
    isNullAware: isNullAware,
  );
}

InternalExpression createCompoundPropertySet({
  required InternalExpression receiver,
  required Name propertyName,
  required Name binaryName,
  required InternalExpression value,
  required bool forEffect,
  required int readOffset,
  required int binaryOffset,
  required int writeOffset,
  required bool isNullAware,
}) {
  return new CompoundPropertySet(
    receiver: receiver,
    propertyName: propertyName,
    binaryName: binaryName,
    value: value,
    forEffect: forEffect,
    readOffset: readOffset,
    binaryOffset: binaryOffset,
    writeOffset: writeOffset,
    isNullAware: isNullAware,
  );
}

/// Return a representation of a conditional expression at the given
/// [fileOffset]. The [condition] is the expression preceding the question
/// mark. The [thenExpression] is the expression following the question mark.
/// The [elseExpression] is the expression following the colon.
InternalExpression createConditionalExpression(
  int fileOffset,
  InternalExpression condition,
  InternalExpression thenExpression,
  InternalExpression elseExpression,
) {
  return new InternalConditionalExpression(
    condition,
    thenExpression,
    elseExpression,
    fileOffset: fileOffset,
  );
}

InternalPattern createConstantPattern(InternalExpression expression) {
  return new InternalConstantPattern(
    expression: expression,
    fileOffset: expression.fileOffset,
  );
}

InternalExpression createConstructorInvocation({
  required Constructor target,
  required TypeArguments? typeArguments,
  required ActualArguments arguments,
  required bool isConst,
  required int fileOffset,
}) {
  return new InternalConstructorInvocation(
    target: target,
    typeArguments: typeArguments,
    arguments: arguments,
    isConst: isConst,
    fileOffset: fileOffset,
  );
}

InternalExpression createConstructorTearOff(int fileOffset, Member target) {
  assert(
    target is Constructor || (target is Procedure && target.isFactory),
    "Unexpected constructor tear off target: $target",
  );
  return new InternalConstructorTearOff(target, fileOffset: fileOffset);
}

InternalConstVariable createConstVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isWildcard = false,
  required int fileOffset,
  bool hasDeclaredInitializer = false,
  bool forSyntheticToken = false,
  bool isImplicitlyTyped = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new InternalConstVariable(
    name: name,
    type: type,
    isFinal: isFinal,
    isWildcard: isWildcard,
    hasDeclaredInitializer: hasDeclaredInitializer,
    fileOffset: fileOffset,
    fileEqualsOffset: fileEqualsOffset,
    forSyntheticToken: forSyntheticToken,
    isImplicitlyTyped: isImplicitlyTyped,
  );
}

/// Return a representation of a continue statement.
InternalContinueStatement createContinueStatement(
  int fileOffset,
  String? label,
) {
  return new InternalContinueStatement(label: label, fileOffset: fileOffset);
}

InternalContinueSwitchStatement createContinueSwitchStatement({
  required int fileOffset,
}) {
  return new InternalContinueSwitchStatement(fileOffset: fileOffset);
}

/// Return a representation of a do statement.
InternalLoopStatement createDoStatement(
  int fileOffset,
  InternalStatement body,
  InternalExpression condition,
) {
  return new InternalDoStatement(body, condition, fileOffset: fileOffset);
}

DotShorthand createDotShorthandContext(
  int fileOffset,
  InternalExpression innerExpression,
) {
  return new DotShorthand(innerExpression, fileOffset: fileOffset);
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
    fileOffset: fileOffset,
  );
}

DotShorthandPropertyGet createDotShorthandPropertyGet(
  int fileOffset,
  Name name, {
  required int nameOffset,
}) {
  return new DotShorthandPropertyGet(
    name,
    nameOffset: nameOffset,
    fileOffset: fileOffset,
  );
}

/// Return a representation of a double literal at the given [fileOffset]. The
/// literal has the given [value].
InternalExpression createDoubleLiteral(int fileOffset, double value) {
  return new InternalDoubleLiteral(value, fileOffset: fileOffset);
}

/// Return a representation of an empty statement  at the given [fileOffset].
InternalStatement createEmptyStatement(int fileOffset) {
  return new InternalEmptyStatement(fileOffset: fileOffset);
}

EqualsExpression createEquals(
  int fileOffset,
  InternalExpression left,
  InternalExpression right, {
  required bool isNot,
}) {
  return new EqualsExpression(
    left,
    right,
    isNot: isNot,
    fileOffset: fileOffset,
  );
}

InternalElement createExpressionElement(InternalExpression expression) {
  return new ExpressionElement(
    expression: expression,
    fileOffset: expression.fileOffset,
  );
}

InternalExpression createExpressionInvocation(
  int fileOffset,
  InternalExpression expression,
  TypeArguments? typeArguments,
  ActualArguments arguments,
) {
  return new ExpressionInvocation(
    expression,
    typeArguments,
    arguments,
    fileOffset: fileOffset,
  );
}

/// Return a representation of an expression statement at the given
/// [fileOffset] containing the [expression].
InternalStatement createExpressionStatement(
  InternalExpression expression, {
  required int fileOffset,
}) {
  return new InternalExpressionStatement(expression, fileOffset: fileOffset);
}

ExtensionTypeRedirectingInitializer createExtensionTypeRedirectingInitializer({
  required Procedure target,
  required ActualArguments arguments,
  required int fileOffset,
}) {
  return new ExtensionTypeRedirectingInitializer(
    target,
    arguments,
    fileOffset: fileOffset,
  );
}

// Coverage-ignore(suite): Not run.
InternalExpression createFactoryConstructorInvocation({
  required Procedure target,
  required TypeArguments? typeArguments,
  required ActualArguments arguments,
  required bool isConst,
  required int fileOffset,
}) {
  return new FactoryConstructorInvocation(
    target: target,
    typeArguments: typeArguments,
    arguments: arguments,
    isConst: isConst,
    fileOffset: fileOffset,
  );
}

InternalFieldInitializer createFieldInitializer(
  Field field,
  InternalExpression value, {
  required int fileOffset,
  required bool isSynthetic,
}) {
  return new InternalFieldInitializer(
    field,
    value,
    isSynthetic: isSynthetic,
    fileOffset: fileOffset,
  );
}

InternalExpression createFileUriExpression({
  required InternalExpression expression,
  required Uri fileUri,
  required int fileOffset,
}) {
  return new InternalFileUriExpression(
    expression: expression,
    fileUri: fileUri,
    fileOffset: fileOffset,
  );
}

InternalElement createForElement({
  required List<InternalVariableDeclaration> variables,
  required InternalExpression? condition,
  required List<InternalExpression> updates,
  required InternalElement body,
  required int fileOffset,
}) {
  return new ForElement(
    variables: variables,
    condition: condition,
    updates: updates,
    body: body,
    fileOffset: fileOffset,
  );
}

ForInElement createForInElement({
  required InternalForInElement element,
  required InternalExpression iterable,
  required InternalElement body,
  required bool isAsync,
  required int forOffset,
  required int fileOffset,
}) {
  return new ForInElement(
    element: element,
    iterable: iterable,
    body: body,
    isAsync: isAsync,
    forOffset: forOffset,
    fileOffset: fileOffset,
  );
}

/// Return a representation of a for statement.
InternalLoopStatement createForStatement(
  int fileOffset,
  List<InternalVariableDeclaration>? variables,
  InternalExpression? condition,
  List<InternalExpression> updaters,
  InternalStatement body,
) {
  return new InternalForStatement(
    variables ?? // Coverage-ignore(suite): Not run.
        [],
    condition,
    updaters,
    body,
    fileOffset: fileOffset,
  );
}

InternalStatement createFunctionDeclaration({
  required InternalLocalFunctionVariable variable,
  required int fileOffset,
}) {
  return new InternalFunctionDeclaration(
    variable: variable,
    fileOffset: fileOffset,
  );
}

InternalExpression createFunctionExpression({
  required InternalFunctionNode function,
  required int fileOffset,
}) {
  return new InternalFunctionExpression(
    function: function,
    fileOffset: fileOffset,
  );
}

InternalFunctionNode createFunctionNode({
  required InternalStatement? body,
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

InternalElement createIfCaseElement({
  required InternalExpression expression,
  required InternalPatternGuard patternGuard,
  required InternalElement then,
  required InternalElement? otherwise,
  required int fileOffset,
}) {
  return new IfCaseElement(
    expression: expression,
    patternGuard: patternGuard,
    then: then,
    otherwise: otherwise,
    fileOffset: fileOffset,
  );
}

InternalStatement createIfCaseStatement(
  int fileOffset,
  InternalExpression expression,
  InternalPatternGuard patternGuard,
  InternalStatement then,
  InternalStatement? otherwise,
) {
  return new InternalIfCaseStatement(
    expression: expression,
    patternGuard: patternGuard,
    then: then,
    otherwise: otherwise,
    fileOffset: fileOffset,
  );
}

InternalElement createIfElement({
  required InternalExpression condition,
  required InternalElement then,
  required InternalElement? otherwise,
  required int fileOffset,
}) {
  return new IfElement(
    condition: condition,
    then: then,
    otherwise: otherwise,
    fileOffset: fileOffset,
  );
}

InternalExpression createIfNullExpression({
  required InternalExpression left,
  required InternalExpression right,
  required int fileOffset,
}) {
  return new IfNullExpression(left, right, fileOffset: fileOffset);
}

InternalExpression createIfNullIndexSet({
  required InternalExpression receiver,
  required InternalExpression index,
  required InternalExpression value,
  required int readOffset,
  required int testOffset,
  required int writeOffset,
  required bool forEffect,
  required bool isNullAware,
}) {
  return new IfNullIndexSet(
    receiver: receiver,
    index: index,
    value: value,
    readOffset: readOffset,
    testOffset: testOffset,
    writeOffset: writeOffset,
    forEffect: forEffect,
    isNullAware: isNullAware,
  );
}

InternalExpression createIfNullPropertySet({
  required InternalExpression receiver,
  required Name propertyName,
  required InternalExpression rhs,
  required bool forEffect,
  required int readOffset,
  required int writeOffset,
  required bool isNullAware,
  required int fileOffset,
}) {
  return new IfNullPropertySet(
    receiver: receiver,
    propertyName: propertyName,
    rhs: rhs,
    forEffect: forEffect,
    readOffset: readOffset,
    writeOffset: writeOffset,
    isNullAware: isNullAware,
    fileOffset: fileOffset,
  );
}

InternalExpression createIfNullSet({
  required InternalExpression read,
  required InternalExpression write,
  required bool forEffect,
  required int fileOffset,
}) {
  return new IfNullSet(
    read: read,
    write: write,
    forEffect: forEffect,
    fileOffset: fileOffset,
  );
}

InternalExpression createIfNullSuperIndexSet({
  required Member? getter,
  required Member? setter,
  required InternalExpression index,
  required InternalExpression value,
  required int readOffset,
  required int testOffset,
  required int writeOffset,
  required bool forEffect,
}) {
  return new IfNullSuperIndexSet(
    getter: getter,
    setter: setter,
    index: index,
    value: value,
    readOffset: readOffset,
    testOffset: testOffset,
    writeOffset: writeOffset,
    forEffect: forEffect,
  );
}

/// Return a representation of an `if` statement.
InternalStatement createIfStatement(
  int fileOffset,
  InternalExpression condition,
  InternalStatement thenStatement,
  InternalStatement? elseStatement,
) {
  return new InternalIfStatement(
    condition,
    thenStatement,
    elseStatement,
    fileOffset: fileOffset,
  );
}

IndexGet createIndexGet(
  int fileOffset,
  InternalExpression receiver,
  InternalExpression index, {
  required bool isNullAware,
}) {
  return new IndexGet(
    receiver,
    index,
    isNullAware: isNullAware,
    fileOffset: fileOffset,
  );
}

IndexSet createIndexSet(
  int fileOffset,
  InternalExpression receiver,
  InternalExpression index,
  InternalExpression value, {
  required bool forEffect,
  required bool isNullAware,
}) {
  return new IndexSet(
    receiver,
    index,
    value,
    forEffect: forEffect,
    isNullAware: isNullAware,
    fileOffset: fileOffset,
  );
}

InternalExpression createInstantiation(
  InternalExpression expression,
  List<DartType> typeArguments, {
  required int fileOffset,
}) {
  return new InternalInstantiation(
    expression,
    typeArguments,
    fileOffset: fileOffset,
  );
}

/// Return a representation of an integer literal at the given [fileOffset].
/// The literal has the given [value].
InternalExpression createIntLiteral({
  required int fileOffset,
  required int value,
  String? literal,
}) {
  return new InternalIntLiteral(value, literal, fileOffset: fileOffset);
}

InternalExpression createIntLiteralLarge(
  int fileOffset,
  String strippedLiteral,
  String literal,
) {
  return new LargeIntLiteral(strippedLiteral, literal, fileOffset: fileOffset);
}

InternalInvalidExpression createInvalidExpression(
  String message, {
  InternalExpression? expression,
  required int fileOffset,
}) {
  return new InternalInvalidExpression(
    message,
    expression: expression,
    fileOffset: fileOffset,
  );
}

InternalInvalidExpression createInvalidExpressionFromErrorText(
  ErrorText errorText, {
  InternalExpression? expression,
}) {
  return new InternalInvalidExpression(
    errorText.message,
    expression: expression,
    fileOffset: errorText.fileOffset,
  );
}

InternalInvalidInitializer createInvalidInitializer(
  InternalInvalidExpression expression, {
  bool isSuperInitializer = false,
  bool isRedirectingInitializer = false,
}) {
  return new InternalInvalidInitializer(
    expression.message,
    fileOffset: expression.fileOffset,
    isSuperInitializer: isSuperInitializer,
    isRedirectingInitializer: isRedirectingInitializer,
  );
}

InternalInvalidInitializer createInvalidInitializerFromErrorText(
  ErrorText errorText, {
  bool isSuperInitializer = false,
  bool isRedirectingInitializer = false,
}) {
  return new InternalInvalidInitializer(
    errorText.message,
    fileOffset: errorText.fileOffset,
    isSuperInitializer: isSuperInitializer,
    isRedirectingInitializer: isRedirectingInitializer,
  );
}

InternalPattern createInvalidPattern(
  InternalInvalidExpression expression, {
  required List<InternalDeclaredVariable> declaredVariables,
}) {
  return new InternalInvalidPattern(
    invalidExpression: expression,
    declaredVariables: declaredVariables,
    fileOffset: expression.fileOffset,
  );
}

// Coverage-ignore(suite): Not run.
InternalPattern createInvalidPatternFromErrorText(
  ErrorText errorText, {
  required List<InternalDeclaredVariable> declaredVariables,
}) {
  return new InternalInvalidPattern(
    invalidExpression: createInvalidExpressionFromErrorText(errorText),
    declaredVariables: declaredVariables,
    fileOffset: errorText.fileOffset,
  );
}

/// Return a representation of an `is` expression at the given [fileOffset].
/// The [operand] is the representation of the left operand. The [type] is a
/// representation of the type that is the right operand. If [notFileOffset]
/// is non-null the test is negated the that file offset.
InternalExpression createIsExpression(
  int fileOffset,
  InternalExpression operand,
  DartType type, {
  int? notFileOffset,
}) {
  return new InternalIsExpression(
    operand,
    type,
    notFileOffset: notFileOffset,
    fileOffset: fileOffset,
  );
}

/// The given [statement] is being used as the target of either a break or
/// continue statement. Return the statement that should be used as the actual
/// target.
InternalLabeledStatement createLabeledStatement(InternalStatement statement) {
  return new InternalLabeledStatement(
    statement,
    fileOffset: statement.fileOffset,
  );
}

InternalLateVariable createLateVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isWildcard = false,
  required int fileOffset,
  bool hasDeclaredInitializer = false,
  bool forSyntheticToken = false,
  bool isImplicitlyTyped = false,
  bool isStaticLate = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new InternalLateVariable(
    name: name,
    type: type,
    isFinal: isFinal,
    isWildcard: isWildcard,
    hasDeclaredInitializer: hasDeclaredInitializer,
    fileOffset: fileOffset,
    fileEqualsOffset: fileEqualsOffset,
    forSyntheticToken: forSyntheticToken,
    isImplicitlyTyped: isImplicitlyTyped,
    isStaticLate: isStaticLate,
  );
}

InternalLet createLetForEffect({
  required InternalExpression effect,
  required DartType effectType,
  required InternalExpression expression,
}) {
  return new InternalLet(
    valueType: effectType,
    value: effect,
    body: expression,
    fileOffset: effect.fileOffset,
  );
}

InternalExpression createListLiteral({
  required DartType? typeArgument,
  required List<InternalElement> elements,
  required bool isConst,
  required int fileOffset,
}) {
  return new InternalListLiteral(
    elements: elements,
    typeArgument: typeArgument,
    isConst: isConst,
    fileOffset: fileOffset,
  );
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

InternalLoadLibrary createLoadLibrary({
  required LibraryDependency import,
  required ActualArguments? arguments,
  required int fileOffset,
}) {
  return new InternalLoadLibrary(import, arguments, fileOffset: fileOffset);
}

InternalLocalFunctionVariable createLocalFunctionVariable({
  required String name,
  required DartType? type,
  bool isWildcard = false,
  required int fileOffset,
  bool forSyntheticToken = false,
  bool isImplicitlyTyped = false,
  bool isStaticLate = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new InternalLocalFunctionVariable(
    name: name,
    type: type,
    isWildcard: isWildcard,
    forSyntheticToken: forSyntheticToken,
    isImplicitlyTyped: isImplicitlyTyped,
    fileOffset: fileOffset,
    fileEqualsOffset: fileEqualsOffset,
  );
}

InternalExpression createLocalIncDec({
  required InternalVariable variable,
  required bool forEffect,
  required bool isPost,
  required bool isInc,
  required int nameOffset,
  required int operatorOffset,
}) {
  return new LocalIncDec(
    variable: variable,
    forEffect: forEffect,
    isPost: isPost,
    isInc: isInc,
    nameOffset: nameOffset,
    operatorOffset: operatorOffset,
  );
}

InternalLocalVariable createLocalVariable({
  required String name,
  required DartType? type,
  bool isFinal = false,
  bool isWildcard = false,
  required int fileOffset,
  bool hasDeclaredInitializer = false,
  bool forSyntheticToken = false,
  bool isImplicitlyTyped = false,
  bool isStaticLate = false,
  int fileEqualsOffset = TreeNode.noOffset,
}) {
  return new InternalLocalVariable(
    name: name,
    type: type,
    isFinal: isFinal,
    isWildcard: isWildcard,
    hasDeclaredInitializer: hasDeclaredInitializer,
    forSyntheticToken: forSyntheticToken,
    isImplicitlyTyped: isImplicitlyTyped,
    fileOffset: fileOffset,
    isStaticLate: isStaticLate,
    fileEqualsOffset: fileEqualsOffset,
  );
}

/// Return a representation of a logical expression at the given [fileOffset]
/// having the [leftOperand], [rightOperand] and the [operatorString]
/// (either `&&` or `||`).
InternalExpression createLogicalExpression(
  int fileOffset,
  InternalExpression leftOperand,
  String operatorString,
  InternalExpression rightOperand,
) {
  LogicalExpressionOperator operator;
  if (operatorString == '&&') {
    operator = LogicalExpressionOperator.AND;
  } else if (operatorString == '||') {
    operator = LogicalExpressionOperator.OR;
  } else {
    throw new UnsupportedError("Unhandled logical operator '$operatorString'");
  }

  return new InternalLogicalExpression(
    leftOperand,
    operator,
    rightOperand,
    fileOffset: fileOffset,
  );
}

InternalElement createMapEntryElement({
  required bool isKeyNullAware,
  required InternalExpression key,
  required bool isValueNullAware,
  required InternalExpression value,
  required int fileOffset,
}) {
  return new MapEntryElement(
    isKeyNullAware: isKeyNullAware,
    key: key,
    isValueNullAware: isValueNullAware,
    value: value,
    fileOffset: fileOffset,
  );
}

InternalExpression createMapOrSetLiteral({
  required List<DartType>? typeArguments,
  required List<InternalElement> elements,
  required bool isConst,
  required int fileOffset,
}) {
  return new MapOrSetLiteral(
    elements: elements,
    typeArguments: typeArguments,
    isConst: isConst,
    fileOffset: fileOffset,
  );
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
  InternalExpression key,
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

InternalExpression createMethodInvocation(
  int fileOffset,
  InternalExpression expression,
  Name name,
  TypeArguments? typeArguments,
  ActualArguments arguments, {
  required bool isNullAware,
  required bool isImplicitThis,
}) {
  return new MethodInvocation(
    expression,
    name,
    typeArguments,
    arguments,
    isNullAware: isNullAware,
    isImplicitThis: isImplicitThis,
    fileOffset: fileOffset,
  );
}

MultiVariableDeclaration createMultiVariableDeclaration(
  List<InternalVariableDeclaration> declarations, {
  required int fileOffset,
}) {
  return new MultiVariableDeclaration(declarations, fileOffset: fileOffset);
}

InternalNamedExpression createNamedExpression(
  String name,
  InternalExpression value, {
  required int fileOffset,
}) {
  return new InternalNamedExpression(
    name: name,
    value: value,
    fileOffset: fileOffset,
  );
}

InternalNamedParameter createNamedParameter({
  required String parameterName,
  required DartType type,
  InternalExpression? defaultValue,
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
    defaultValue: defaultValue,
    astVariable: extern.createNamedParameter(
      parameterName: parameterName,
      type: type,
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

InternalExpression createNot(int fileOffset, InternalExpression operand) {
  return new InternalNot(operand, fileOffset: fileOffset);
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

InternalElement createNullAwareElement({
  required InternalExpression expression,
  required int fileOffset,
}) {
  return new NullAwareElement(expression: expression, fileOffset: fileOffset);
}

InternalExpression createNullCheck(
  int fileOffset,
  InternalExpression expression,
) {
  return new InternalNullCheck(expression, fileOffset: fileOffset);
}

InternalPattern createNullCheckPattern(
  int fileOffset,
  InternalPattern pattern,
) {
  return new InternalNullCheckPattern(pattern: pattern, fileOffset: fileOffset);
}

/// Return a representation of a null literal at the given [fileOffset].
InternalExpression createNullLiteral(int fileOffset) {
  return new InternalNullLiteral(fileOffset: fileOffset);
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

InternalPattern createOrPattern(
  int fileOffset,
  InternalPattern left,
  InternalPattern right, {
  required List<InternalDeclaredVariable> orPatternJointVariables,
}) {
  return new InternalOrPattern(
    left,
    right,
    orPatternJointVariables: orPatternJointVariables,
    fileOffset: fileOffset,
  );
}

ParenthesizedExpression createParenthesized(
  int fileOffset,
  InternalExpression expression,
) {
  return new ParenthesizedExpression(expression, fileOffset: fileOffset);
}

InternalExpression createPatternAssignment(
  int fileOffset,
  InternalPattern pattern,
  InternalExpression expression,
) {
  return new InternalPatternAssignment(
    pattern: pattern,
    expression: expression,
    fileOffset: fileOffset,
  );
}

InternalElement createPatternForElement({
  required InternalPatternVariableDeclaration patternVariableDeclaration,
  required List<InternalVariableDeclaration> intermediateVariables,
  required List<InternalVariableDeclaration> variables,
  required InternalExpression? condition,
  required List<InternalExpression> updates,
  required InternalElement body,
  required int fileOffset,
}) {
  return new PatternForElement(
    patternVariableDeclaration: patternVariableDeclaration,
    intermediateVariables: intermediateVariables,
    variables: variables,
    condition: condition,
    updates: updates,
    body: body,
    fileOffset: fileOffset,
  );
}

InternalPatternGuard createPatternGuard(
  int fileOffset,
  InternalPattern pattern, [
  InternalExpression? guard,
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
  InternalStatement body, {
  required bool isDefault,
  required List<Label>? labels,
  required List<InternalDeclaredVariable>? jointVariables,
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

InternalSwitchStatement createPatternSwitchStatement(
  int fileOffset,
  InternalExpression expression,
  List<InternalPatternSwitchCase> cases,
) {
  return new InternalPatternSwitchStatement(
    expression: expression,
    cases: cases,
    fileOffset: fileOffset,
  );
}

InternalPatternVariableDeclaration createPatternVariableDeclaration(
  int fileOffset,
  InternalPattern pattern,
  InternalExpression initializer, {
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
  InternalExpression? defaultValue,
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
    defaultValue: defaultValue,
    astVariable: extern.createPositionalParameter(
      cosmeticName: cosmeticName,
      type: type,
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

InternalExpression createPropertyGet(
  int fileOffset,
  InternalExpression receiver,
  Name name, {
  required bool isNullAware,
  required bool isImplicitThis,
}) {
  return new PropertyGet(
    receiver,
    name,
    isNullAware: isNullAware,
    isImplicitThis: isImplicitThis,
    fileOffset: fileOffset,
  );
}

InternalExpression createPropertyIncDec({
  required InternalExpression receiver,
  required Name name,
  required bool forEffect,
  required bool isPost,
  required bool isInc,
  required bool isNullAware,
  required int nameOffset,
  required int operatorOffset,
  required bool isImplicitThis,
}) {
  return new PropertyIncDec(
    receiver: receiver,
    name: name,
    forEffect: forEffect,
    isPost: isPost,
    isInc: isInc,
    isNullAware: isNullAware,
    nameOffset: nameOffset,
    operatorOffset: operatorOffset,
    isImplicitThis: isImplicitThis,
  );
}

InternalExpression createPropertySet(
  int fileOffset,
  InternalExpression receiver,
  Name name,
  InternalExpression value, {
  required bool forEffect,
  bool readOnlyReceiver = false,
  required bool isNullAware,
  required isImplicitThis,
}) {
  return new PropertySet(
    receiver,
    name,
    value,
    forEffect: forEffect,
    readOnlyReceiver: readOnlyReceiver,
    isNullAware: isNullAware,
    isImplicitThis: isImplicitThis,
    fileOffset: fileOffset,
  );
}

// Coverage-ignore(suite): Not run.
InternalExpression createRecordLiteral({
  required List<PositionalRecordField> fields,
  required Map<String, NamedRecordField>? namedFields,
  required bool isConst,
  required int fileOffset,
}) {
  return new InternalRecordLiteral(
    fields: fields,
    namedFields: namedFields,
    isConst: isConst,
    fileOffset: fileOffset,
  );
}

InternalPattern createRecordPattern(
  int fileOffset,
  List<InternalPattern> patterns,
) {
  return new InternalRecordPattern(patterns: patterns, fileOffset: fileOffset);
}

InternalExpression createRedirectingFactoryTearOff(
  int fileOffset,
  Procedure procedure,
) {
  assert(procedure.isRedirectingFactory);
  return new InternalRedirectingFactoryTearOff(
    procedure,
    fileOffset: fileOffset,
  );
}

InternalRedirectingInitializer createRedirectingInitializer({
  required Constructor target,
  required ActualArguments arguments,
  required int fileOffset,
}) {
  return new InternalRedirectingInitializer(
    target,
    arguments,
    fileOffset: fileOffset,
  );
}

InternalPattern createRelationalPattern(
  int fileOffset,
  RelationalPatternKind kind,
  InternalExpression expression,
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

InternalExpression createRethrow({required int fileOffset}) {
  return new InternalRethrow(fileOffset: fileOffset);
}

/// Return a representation of a rethrow statement consisting of the
/// rethrow at [rethrowFileOffset] and the statement at [statementFileOffset].
InternalStatement createRethrowStatement(
  int rethrowFileOffset,
  int statementFileOffset,
) {
  return new InternalExpressionStatement(
    createRethrow(fileOffset: rethrowFileOffset),
    fileOffset: statementFileOffset,
  );
}

/// Return a representation of a return statement.
InternalReturnStatement createReturnStatement({
  InternalExpression? expression,
  bool isArrow = true,
  required int fileOffset,
}) {
  return new InternalReturnStatement(
    expression: expression,
    isArrow: isArrow,
    fileOffset: fileOffset,
  );
}

InternalElement createSpreadElement({
  required InternalExpression expression,
  required bool isNullAware,
  required int fileOffset,
}) {
  return new SpreadElement(
    expression: expression,
    isNullAware: isNullAware,
    fileOffset: fileOffset,
  );
}

InternalExpression createStaticGet(int fileOffset, Member target) {
  assert(target is Field || (target is Procedure && target.isGetter));
  return new InternalStaticGet(target, fileOffset: fileOffset);
}

InternalExpression createStaticIncDec({
  required Member getter,
  required Member setter,
  required Name name,
  required bool forEffect,
  required bool isPost,
  required bool isInc,
  required int nameOffset,
  required int operatorOffset,
}) {
  return new StaticIncDec(
    getter: getter,
    setter: setter,
    name: name,
    forEffect: forEffect,
    isPost: isPost,
    isInc: isInc,
    nameOffset: nameOffset,
    operatorOffset: operatorOffset,
  );
}

InternalExpression createStaticSet(
  Member target,
  InternalExpression value, {
  required int fileOffset,
}) {
  assert(
    target is Field || (target is Procedure && target.isSetter),
    "Unexpected static set target $target",
  );
  return new InternalStaticSet(target, value, fileOffset: fileOffset);
}

InternalExpression createStaticTearOff(int fileOffset, Procedure procedure) {
  assert(
    procedure.kind == ProcedureKind.Method,
    "Unexpected static tear off target: $procedure",
  );
  assert(
    !procedure.isRedirectingFactory,
    "Unexpected static tear off target: $procedure",
  );
  return new InternalStaticTearOff(procedure, fileOffset: fileOffset);
}

InternalExpression createStringConcatenation(
  int fileOffset,
  List<InternalExpression> expressions,
) {
  assert(fileOffset != TreeNode.noOffset);
  return new InternalStringConcatenation(expressions, fileOffset: fileOffset);
}

/// Return a representation of a simple string literal at the given
/// [fileOffset]. The literal has the given [value]. This does not include
/// either adjacent strings or interpolated strings.
InternalExpression createStringLiteral(int fileOffset, String value) {
  return new InternalStringLiteral(value, fileOffset: fileOffset);
}

InternalExpression createSuperIncDec({
  required InternalThisExpression receiver,
  required Member getter,
  required Member setter,
  required Name name,
  required bool forEffect,
  required bool isPost,
  required bool isInc,
  required int nameOffset,
  required int operatorOffset,
}) {
  return new SuperIncDec(
    receiver: receiver,
    getter: getter,
    setter: setter,
    name: name,
    forEffect: forEffect,
    isPost: isPost,
    isInc: isInc,
    nameOffset: nameOffset,
    operatorOffset: operatorOffset,
  );
}

InternalExpression createSuperIndexSet({
  required Member setter,
  required InternalExpression index,
  required InternalExpression value,
  required int fileOffset,
}) {
  return new SuperIndexSet(
    setter: setter,
    index: index,
    value: value,
    fileOffset: fileOffset,
  );
}

InternalSuperInitializer createSuperInitializer({
  required Constructor target,
  required ActualArguments arguments,
  required bool isSynthetic,
  required int fileOffset,
}) {
  return new InternalSuperInitializer(
    target,
    arguments,
    isSynthetic: isSynthetic,
    fileOffset: fileOffset,
  );
}

InternalExpression createSuperMethodInvocation({
  required Name name,
  required Procedure procedure,
  required TypeArguments? typeArguments,
  required ActualArguments arguments,
  required int fileOffset,
}) {
  return new InternalSuperMethodInvocation(
    name,
    typeArguments,
    arguments,
    procedure,
    fileOffset: fileOffset,
  );
}

InternalExpression createSuperPropertyGet(
  InternalThisExpression receiver,
  Name name,
  Member target, {
  required int fileOffset,
}) {
  return new InternalSuperPropertyGet(
    receiver: receiver,
    name: name,
    interfaceTarget: target,
    fileOffset: fileOffset,
  );
}

InternalExpression createSuperPropertySet(
  InternalThisExpression receiver,
  Name name,
  Member target,
  InternalExpression value, {
  required int fileOffset,
}) {
  return new InternalSuperPropertySet(
    receiver: receiver,
    name: name,
    value: value,
    interfaceTarget: target,
    fileOffset: fileOffset,
  );
}

InternalExpression createSwitchExpression(
  int fileOffset,
  InternalExpression expression,
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
  InternalExpression expression,
) {
  return new InternalSwitchExpressionCase(
    patternGuard: patternGuard,
    expression: expression,
    fileOffset: fileOffset,
  );
}

InternalSwitchStatement createSwitchStatement(
  InternalExpression expression,
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
  required List<InternalExpression> expressions,
  required List<int> expressionOffsets,
  required InternalStatement body,
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
InternalExpression createSymbolLiteral(int fileOffset, String value) {
  return new InternalSymbolLiteral(value, fileOffset: fileOffset);
}

InternalSyntheticVariable createSyntheticVariable({
  String? name,
  DartType? type,
  required int fileOffset,
  bool isFinal = false,
  bool isLowered = false,
  bool isSynthesized = true,
}) {
  return new InternalSyntheticVariable(
    name: name,
    type: type ?? const DynamicType(),
    isFinal: isFinal,
    isLowered: isLowered,
    isSynthesized: isSynthesized,
    isImplicitlyTyped: type == null,
    fileOffset: fileOffset,
  );
}

InternalThisExpression createThisExpression({required int fileOffset}) {
  return new InternalThisExpression(fileOffset: fileOffset);
}

InternalThisVariable createThisVariable({
  required DartType type,
  required int fileOffset,
}) {
  return new InternalThisVariable(type: type, fileOffset: fileOffset);
}

/// Return a representation of a throw expression at the given [fileOffset].
InternalExpression createThrow(int fileOffset, InternalExpression expression) {
  return new InternalThrow(expression, fileOffset: fileOffset);
}

InternalStatement createTryStatement(
  int fileOffset,
  InternalStatement tryBlock,
  List<InternalCatch>? catchBlocks,
  InternalStatement? finallyBlock,
) {
  return new TryStatement(
    tryBlock,
    catchBlocks ?? [],
    finallyBlock,
    fileOffset: fileOffset,
  );
}

InternalExpression createTypeAliasedConstructorInvocation({
  required TypeAliasBuilder typeAliasBuilder,
  required Constructor target,
  required TypeArguments? typeArguments,
  required ActualArguments arguments,
  required bool isConst,
  required int fileOffset,
}) {
  return new TypeAliasedConstructorInvocation(
    typeAliasBuilder: typeAliasBuilder,
    target: target,
    typeArguments: typeArguments,
    arguments: arguments,
    isConst: isConst,
    fileOffset: fileOffset,
  );
}

InternalExpression createTypeAliasedFactoryInvocation({
  required TypeAliasBuilder typeAliasBuilder,
  required Procedure target,
  required TypeArguments? typeArguments,
  required ActualArguments arguments,
  required bool isConst,
  required int fileOffset,
}) {
  return new TypeAliasedFactoryInvocation(
    typeAliasBuilder: typeAliasBuilder,
    target: target,
    typeArguments: typeArguments,
    arguments: arguments,
    isConst: isConst,
    fileOffset: fileOffset,
  );
}

InternalExpression createTypedefTearOff(
  int fileOffset,
  List<StructuralParameter> structuralParameters,
  InternalExpression expression,
  List<DartType> typeArguments,
) {
  return new InternalTypedefTearOff(
    structuralParameters: structuralParameters,
    expression: expression,
    typeArguments: typeArguments,
    fileOffset: fileOffset,
  );
}

InternalExpression createTypeLiteral(int fileOffset, DartType type) {
  return new InternalTypeLiteral(type, fileOffset: fileOffset);
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
  InternalExpression expression,
) {
  return new UnaryExpression(unaryName, expression, fileOffset: fileOffset);
}

InternalVariableDeclaration createVariableDeclaration(
  InternalDeclaredVariable variable, {
  required InternalExpression? initializer,
  int? nameOffset,
  int? equalsOffset,
}) {
  return new InternalVariableDeclaration(
    variable,
    initializer: initializer,
    nameOffset: nameOffset ?? variable.fileOffset,
  );
}

InternalVariableGet createVariableGet(
  InternalVariable variable, {
  required int fileOffset,
}) {
  return new InternalVariableGet(variable, fileOffset: fileOffset);
}

InternalPattern createVariablePattern(
  int fileOffset,
  DartType? type,
  InternalDeclaredVariable variable,
) {
  return new InternalVariablePattern(
    type: type,
    variable: variable,
    fileOffset: fileOffset,
  );
}

InternalVariableSet createVariableSet(
  InternalVariable variable,
  InternalExpression value, {
  required int fileOffset,
}) {
  return new InternalVariableSet(variable, value, fileOffset: fileOffset);
}

InternalVariableStatement createVariableStatement(
  InternalVariableDeclaration declaration, {
  int? fileOffset,
}) {
  return new InternalVariableStatement(
    declaration,
    fileOffset: fileOffset ?? declaration.fileOffset,
  );
}

/// Return a representation of a while statement at the given [fileOffset]
/// consisting of the given [condition] and [body].
InternalLoopStatement createWhileStatement(
  int fileOffset,
  InternalExpression condition,
  InternalStatement body,
) {
  return new InternalWhileStatement(condition, body, fileOffset: fileOffset);
}

InternalPattern createWildcardPattern(int fileOffset, DartType? type) {
  return new InternalWildcardPattern(type: type, fileOffset: fileOffset);
}

/// Return a representation of a yield statement at the given [fileOffset]
/// of the given [expression]. If [isYieldStar] is `true` the created
/// statement is a yield* statement.
InternalStatement createYieldStatement(
  int fileOffset,
  InternalExpression expression, {
  required bool isYieldStar,
}) {
  return new InternalYieldStatement(
    expression,
    isYieldStar: isYieldStar,
    fileOffset: fileOffset,
  );
}

// TODO(johnniwinther): This has been broken for some time. Do we need it?
bool isThisExpression(Object node) => false;

InternalStatement wrapVariables(InternalStatement statement) {
  if (statement is MultiVariableDeclaration) {
    return createBlock(
      new List<InternalStatement>.generate(
        statement.declarations.length,
        (int index) => createVariableStatement(statement.declarations[index]),
        growable: true,
      ),
      fileOffset: statement.fileOffset,
      fileEndOffset: TreeNode.noOffset,
    );
  } else if (statement is InternalVariableStatement) {
    return createBlock(
      <InternalStatement>[statement],
      fileOffset: statement.fileOffset,
      fileEndOffset: TreeNode.noOffset,
    );
  } else {
    return statement;
  }
}
