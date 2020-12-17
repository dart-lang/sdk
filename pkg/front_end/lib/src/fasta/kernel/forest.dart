// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

import '../problems.dart' show unsupported;

import 'collections.dart'
    show
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfElement,
        IfMapEntry,
        SpreadElement;

import 'internal_ast.dart';

/// A shadow tree factory.
class Forest {
  const Forest();

  Arguments createArguments(int fileOffset, List<Expression> positional,
      {List<DartType> types, List<NamedExpression> named}) {
    return new ArgumentsImpl(positional, types: types, named: named)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  Arguments createArgumentsForExtensionMethod(
      int fileOffset,
      int extensionTypeParameterCount,
      int typeParameterCount,
      Expression receiver,
      {List<DartType> extensionTypeArguments = const <DartType>[],
      int extensionTypeArgumentOffset,
      List<DartType> typeArguments = const <DartType>[],
      List<Expression> positionalArguments = const <Expression>[],
      List<NamedExpression> namedArguments = const <NamedExpression>[]}) {
    assert(fileOffset != null);
    return new ArgumentsImpl.forExtensionMethod(
        extensionTypeParameterCount, typeParameterCount, receiver,
        extensionTypeArguments: extensionTypeArguments,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
        typeArguments: typeArguments,
        positionalArguments: positionalArguments,
        namedArguments: namedArguments)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  Arguments createArgumentsEmpty(int fileOffset) {
    assert(fileOffset != null);
    return createArguments(fileOffset, <Expression>[]);
  }

  List<NamedExpression> argumentsNamed(Arguments arguments) {
    return arguments.named;
  }

  List<Expression> argumentsPositional(Arguments arguments) {
    return arguments.positional;
  }

  List<DartType> argumentsTypeArguments(Arguments arguments) {
    return arguments.types;
  }

  void argumentsSetTypeArguments(Arguments arguments, List<DartType> types) {
    ArgumentsImpl.setNonInferrableArgumentTypes(arguments, types);
  }

  /// Return a representation of a boolean literal at the given [fileOffset].
  /// The literal has the given [value].
  BoolLiteral createBoolLiteral(int fileOffset, bool value) {
    assert(fileOffset != null);
    return new BoolLiteral(value)..fileOffset = fileOffset;
  }

  /// Return a representation of a double literal at the given [fileOffset]. The
  /// literal has the given [value].
  DoubleLiteral createDoubleLiteral(int fileOffset, double value) {
    assert(fileOffset != null);
    return new DoubleLiteral(value)..fileOffset = fileOffset;
  }

  /// Return a representation of an integer literal at the given [fileOffset].
  /// The literal has the given [value].
  IntLiteral createIntLiteral(int fileOffset, int value, [String literal]) {
    assert(fileOffset != null);
    return new IntJudgment(value, literal)..fileOffset = fileOffset;
  }

  IntLiteral createIntLiteralLarge(int fileOffset, String literal) {
    assert(fileOffset != null);
    return new ShadowLargeIntLiteral(literal, fileOffset);
  }

  /// Return a representation of a list literal at the given [fileOffset]. The
  /// [isConst] is `true` if the literal is either explicitly or implicitly a
  /// constant. The [typeArgument] is the representation of the single valid
  /// type argument preceding the list literal, or `null` if there is no type
  /// argument, there is more than one type argument, or if the type argument
  /// cannot be resolved. The list of [expressions] is a list of the
  /// representations of the list elements.
  ListLiteral createListLiteral(
      int fileOffset, DartType typeArgument, List<Expression> expressions,
      {bool isConst}) {
    assert(fileOffset != null);
    assert(isConst != null);
    return new ListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a set literal at the given [fileOffset]. The
  /// [isConst] is `true` if the literal is either explicitly or implicitly a
  /// constant. The [typeArgument] is the representation of the single valid
  /// type argument preceding the set literal, or `null` if there is no type
  /// argument, there is more than one type argument, or if the type argument
  /// cannot be resolved. The list of [expressions] is a list of the
  /// representations of the set elements.
  SetLiteral createSetLiteral(
      int fileOffset, DartType typeArgument, List<Expression> expressions,
      {bool isConst}) {
    assert(fileOffset != null);
    assert(isConst != null);
    return new SetLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = fileOffset;
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
  MapLiteral createMapLiteral(int fileOffset, DartType keyType,
      DartType valueType, List<MapEntry> entries,
      {bool isConst}) {
    assert(fileOffset != null);
    assert(isConst != null);
    return new MapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a null literal at the given [fileOffset].
  NullLiteral createNullLiteral(int fileOffset) {
    assert(fileOffset != null);
    return new NullLiteral()..fileOffset = fileOffset;
  }

  /// Return a representation of a simple string literal at the given
  /// [fileOffset]. The literal has the given [value]. This does not include
  /// either adjacent strings or interpolated strings.
  StringLiteral createStringLiteral(int fileOffset, String value) {
    assert(fileOffset != null);
    return new StringLiteral(value)..fileOffset = fileOffset;
  }

  /// Return a representation of a symbol literal defined by [value] at the
  /// given [fileOffset].
  SymbolLiteral createSymbolLiteral(int fileOffset, String value) {
    assert(fileOffset != null);
    return new SymbolLiteral(value)..fileOffset = fileOffset;
  }

  TypeLiteral createTypeLiteral(int fileOffset, DartType type) {
    assert(fileOffset != null);
    return new TypeLiteral(type)..fileOffset = fileOffset;
  }

  /// Return a representation of a key/value pair in a literal map at the given
  /// [fileOffset]. The [key] is the representation of the expression used to
  /// compute the key. The [value] is the representation of the expression used
  /// to compute the value.
  MapEntry createMapEntry(int fileOffset, Expression key, Expression value) {
    assert(fileOffset != null);
    return new MapEntry(key, value)..fileOffset = fileOffset;
  }

  Expression createLoadLibrary(
      int fileOffset, LibraryDependency dependency, Arguments arguments) {
    assert(fileOffset != null);
    return new LoadLibraryImpl(dependency, arguments)..fileOffset = fileOffset;
  }

  Expression checkLibraryIsLoaded(
      int fileOffset, LibraryDependency dependency) {
    assert(fileOffset != null);
    return new CheckLibraryIsLoaded(dependency)..fileOffset = fileOffset;
  }

  Expression createAsExpression(
      int fileOffset, Expression expression, DartType type,
      {bool forNonNullableByDefault}) {
    assert(forNonNullableByDefault != null);
    assert(fileOffset != null);
    return new AsExpression(expression, type)
      ..fileOffset = fileOffset
      ..isForNonNullableByDefault = forNonNullableByDefault;
  }

  Expression createSpreadElement(int fileOffset, Expression expression,
      {bool isNullAware}) {
    assert(fileOffset != null);
    assert(isNullAware != null);
    return new SpreadElement(expression, isNullAware)..fileOffset = fileOffset;
  }

  Expression createIfElement(
      int fileOffset, Expression condition, Expression then,
      [Expression otherwise]) {
    assert(fileOffset != null);
    return new IfElement(condition, then, otherwise)..fileOffset = fileOffset;
  }

  MapEntry createIfMapEntry(int fileOffset, Expression condition, MapEntry then,
      [MapEntry otherwise]) {
    assert(fileOffset != null);
    return new IfMapEntry(condition, then, otherwise)..fileOffset = fileOffset;
  }

  Expression createForElement(
      int fileOffset,
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      Expression body) {
    assert(fileOffset != null);
    return new ForElement(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  MapEntry createForMapEntry(
      int fileOffset,
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      MapEntry body) {
    assert(fileOffset != null);
    return new ForMapEntry(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  Expression createForInElement(
      int fileOffset,
      VariableDeclaration variable,
      Expression iterable,
      Expression synthesizedAssignment,
      Statement expressionEffects,
      Expression body,
      Expression problem,
      {bool isAsync: false}) {
    assert(fileOffset != null);
    return new ForInElement(variable, iterable, synthesizedAssignment,
        expressionEffects, body, problem,
        isAsync: isAsync)
      ..fileOffset = fileOffset;
  }

  MapEntry createForInMapEntry(
      int fileOffset,
      VariableDeclaration variable,
      Expression iterable,
      Expression synthesizedAssignment,
      Statement expressionEffects,
      MapEntry body,
      Expression problem,
      {bool isAsync: false}) {
    assert(fileOffset != null);
    return new ForInMapEntry(variable, iterable, synthesizedAssignment,
        expressionEffects, body, problem,
        isAsync: isAsync)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of an assert that appears in a constructor's
  /// initializer list.
  AssertInitializer createAssertInitializer(
      int fileOffset, AssertStatement assertStatement) {
    assert(fileOffset != null);
    return new AssertInitializer(assertStatement)..fileOffset = fileOffset;
  }

  /// Return a representation of an assert that appears as a statement.
  Statement createAssertStatement(int fileOffset, Expression condition,
      Expression message, int conditionStartOffset, int conditionEndOffset) {
    assert(fileOffset != null);
    return new AssertStatement(condition,
        conditionStartOffset: conditionStartOffset,
        conditionEndOffset: conditionEndOffset,
        message: message)
      ..fileOffset = fileOffset;
  }

  Expression createAwaitExpression(int fileOffset, Expression operand) {
    assert(fileOffset != null);
    return new AwaitExpression(operand)..fileOffset = fileOffset;
  }

  /// Return a representation of a block of [statements] at the given
  /// [fileOffset].
  Statement createBlock(
      int fileOffset, int fileEndOffset, List<Statement> statements) {
    assert(fileOffset != null);
    List<Statement> copy;
    for (int i = 0; i < statements.length; i++) {
      Statement statement = statements[i];
      if (statement is _VariablesDeclaration) {
        copy ??= new List<Statement>.from(statements.getRange(0, i));
        copy.addAll(statement.declarations);
      } else if (copy != null) {
        copy.add(statement);
      }
    }
    return new Block(copy ?? statements)
      ..fileOffset = fileOffset
      ..fileEndOffset = fileEndOffset;
  }

  /// Return a representation of a break statement.
  Statement createBreakStatement(int fileOffset, Object label) {
    assert(fileOffset != null);
    // TODO(johnniwinther): Use [label]?
    return new BreakStatementImpl(isContinue: false)..fileOffset = fileOffset;
  }

  /// Return a representation of a catch clause.
  Catch createCatch(
      int fileOffset,
      DartType exceptionType,
      VariableDeclaration exceptionParameter,
      VariableDeclaration stackTraceParameter,
      DartType stackTraceType,
      Statement body) {
    assert(fileOffset != null);
    return new Catch(exceptionParameter, body,
        guard: exceptionType, stackTrace: stackTraceParameter)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a conditional expression at the given
  /// [fileOffset]. The [condition] is the expression preceding the question
  /// mark. The [thenExpression] is the expression following the question mark.
  /// The [elseExpression] is the expression following the colon.
  Expression createConditionalExpression(int fileOffset, Expression condition,
      Expression thenExpression, Expression elseExpression) {
    return new ConditionalExpression(
        condition, thenExpression, elseExpression, null)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a continue statement.
  Statement createContinueStatement(int fileOffset, Object label) {
    assert(fileOffset != null);
    // TODO(johnniwinther): Use [label]?
    return new BreakStatementImpl(isContinue: true)..fileOffset = fileOffset;
  }

  /// Return a representation of a do statement.
  Statement createDoStatement(
      int fileOffset, Statement body, Expression condition) {
    assert(fileOffset != null);
    return new DoStatement(body, condition)..fileOffset = fileOffset;
  }

  /// Return a representation of an expression statement at the given
  /// [fileOffset] containing the [expression].
  Statement createExpressionStatement(int fileOffset, Expression expression) {
    assert(fileOffset != null);
    return new ExpressionStatement(expression)..fileOffset = fileOffset;
  }

  /// Return a representation of an empty statement  at the given [fileOffset].
  Statement createEmptyStatement(int fileOffset) {
    assert(fileOffset != null);
    return new EmptyStatement()..fileOffset = fileOffset;
  }

  /// Return a representation of a for statement.
  Statement createForStatement(
      int fileOffset,
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updaters,
      Statement body) {
    assert(fileOffset != null);
    return new ForStatement(variables ?? [], condition, updaters, body)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of an `if` statement.
  Statement createIfStatement(int fileOffset, Expression condition,
      Statement thenStatement, Statement elseStatement) {
    assert(fileOffset != null);
    return new IfStatement(condition, thenStatement, elseStatement)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of an `is` expression at the given [fileOffset].
  /// The [operand] is the representation of the left operand. The [type] is a
  /// representation of the type that is the right operand. If [notFileOffset]
  /// is non-null the test is negated the that file offset.
  Expression createIsExpression(
      int fileOffset, Expression operand, DartType type,
      {bool forNonNullableByDefault, int notFileOffset}) {
    assert(forNonNullableByDefault != null);
    assert(fileOffset != null);
    Expression result = new IsExpression(operand, type)
      ..fileOffset = fileOffset
      ..isForNonNullableByDefault = forNonNullableByDefault;
    if (notFileOffset != null) {
      result = createNot(notFileOffset, result);
    }
    return result;
  }

  /// Return a representation of a logical expression at the given [fileOffset]
  /// having the [leftOperand], [rightOperand] and the [operatorString]
  /// (either `&&` or `||`).
  Expression createLogicalExpression(int fileOffset, Expression leftOperand,
      String operatorString, Expression rightOperand) {
    assert(fileOffset != null);
    LogicalExpressionOperator operator;
    if (operatorString == '&&') {
      operator = LogicalExpressionOperator.AND;
    } else if (operatorString == '||') {
      operator = LogicalExpressionOperator.OR;
    } else {
      throw new UnsupportedError(
          "Unhandled logical operator '$operatorString'");
    }

    return new LogicalExpression(leftOperand, operator, rightOperand)
      ..fileOffset = fileOffset;
  }

  Expression createNot(int fileOffset, Expression operand) {
    assert(fileOffset != null);
    return new Not(operand)..fileOffset = fileOffset;
  }

  /// Return a representation of a rethrow statement consisting of the
  /// rethrow at [rethrowFileOffset] and the statement at [statementFileOffset].
  Statement createRethrowStatement(
      int rethrowFileOffset, int statementFileOffset) {
    assert(rethrowFileOffset != null);
    assert(statementFileOffset != null);
    return new ExpressionStatement(
        new Rethrow()..fileOffset = rethrowFileOffset)
      ..fileOffset = statementFileOffset;
  }

  /// Return a representation of a return statement.
  Statement createReturnStatement(int fileOffset, Expression expression,
      {bool isArrow: true}) {
    assert(fileOffset != null);
    return new ReturnStatementImpl(isArrow, expression)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  Expression createStringConcatenation(
      int fileOffset, List<Expression> expressions) {
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new StringConcatenation(expressions)..fileOffset = fileOffset;
  }

  /// The given [statement] is being used as the target of either a break or
  /// continue statement. Return the statement that should be used as the actual
  /// target.
  Statement createLabeledStatement(Statement statement) {
    return new LabeledStatement(statement)..fileOffset = statement.fileOffset;
  }

  Expression createThisExpression(int fileOffset) {
    assert(fileOffset != null);
    return new ThisExpression()..fileOffset = fileOffset;
  }

  /// Return a representation of a throw expression at the given [fileOffset].
  Expression createThrow(int fileOffset, Expression expression) {
    assert(fileOffset != null);
    return new Throw(expression)..fileOffset = fileOffset;
  }

  bool isThrow(Object o) => o is Throw;

  Statement createTryStatement(int fileOffset, Statement tryBlock,
      List<Catch> catchBlocks, Statement finallyBlock) {
    assert(fileOffset != null);
    return new TryStatement(tryBlock, catchBlocks ?? <Catch>[], finallyBlock)
      ..fileOffset = fileOffset;
  }

  _VariablesDeclaration variablesDeclaration(
      List<VariableDeclaration> declarations, Uri uri) {
    return new _VariablesDeclaration(declarations, uri);
  }

  List<VariableDeclaration> variablesDeclarationExtractDeclarations(
      _VariablesDeclaration variablesDeclaration) {
    return variablesDeclaration.declarations;
  }

  Statement wrapVariables(Statement statement) {
    if (statement is _VariablesDeclaration) {
      return new Block(
          new List<Statement>.from(statement.declarations, growable: true))
        ..fileOffset = statement.fileOffset;
    } else if (statement is VariableDeclaration) {
      return new Block(<Statement>[statement])
        ..fileOffset = statement.fileOffset;
    } else {
      return statement;
    }
  }

  /// Return a representation of a while statement at the given [fileOffset]
  /// consisting of the given [condition] and [body].
  Statement createWhileStatement(
      int fileOffset, Expression condition, Statement body) {
    assert(fileOffset != null);
    return new WhileStatement(condition, body)..fileOffset = fileOffset;
  }

  /// Return a representation of a yield statement at the given [fileOffset]
  /// of the given [expression]. If [isYieldStar] is `true` the created
  /// statement is a yield* statement.
  Statement createYieldStatement(int fileOffset, Expression expression,
      {bool isYieldStar}) {
    assert(fileOffset != null);
    assert(isYieldStar != null);
    return new YieldStatement(expression, isYieldStar: isYieldStar)
      ..fileOffset = fileOffset;
  }

  bool isBlock(Object node) => node is Block;

  bool isErroneousNode(Object node) {
    if (node is ExpressionStatement) {
      ExpressionStatement statement = node;
      node = statement.expression;
    }
    if (node is VariableDeclaration) {
      VariableDeclaration variable = node;
      node = variable.initializer;
    }
    if (node is Let) {
      Let let = node;
      node = let.variable.initializer;
    }
    return node is InvalidExpression;
  }

  bool isThisExpression(Object node) => node is ThisExpression;

  bool isVariablesDeclaration(Object node) => node is _VariablesDeclaration;

  /// Creates [VariableDeclaration] for a variable named [name] at the given
  /// [functionNestingLevel].
  VariableDeclaration createVariableDeclaration(
      int fileOffset, String name, int functionNestingLevel,
      {Expression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isCovariant: false,
      bool isLocalFunction: false}) {
    assert(fileOffset != null);
    return new VariableDeclarationImpl(name, functionNestingLevel,
        type: type,
        initializer: initializer,
        isFinal: isFinal,
        isConst: isConst,
        isFieldFormal: isFieldFormal,
        isCovariant: isCovariant,
        isLocalFunction: isLocalFunction,
        hasDeclaredInitializer: initializer != null);
  }

  VariableDeclaration createVariableDeclarationForValue(Expression initializer,
      {DartType type = const DynamicType()}) {
    return new VariableDeclarationImpl.forValue(initializer)
      ..type = type
      ..fileOffset = initializer.fileOffset;
  }

  Let createLet(VariableDeclaration variable, Expression body) {
    return new Let(variable, body);
  }

  FunctionNode createFunctionNode(int fileOffset, Statement body,
      {List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      DartType returnType: const DynamicType(),
      AsyncMarker asyncMarker: AsyncMarker.Sync,
      AsyncMarker dartAsyncMarker}) {
    assert(fileOffset != null);
    return new FunctionNode(body,
        typeParameters: typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount,
        returnType: returnType,
        asyncMarker: asyncMarker,
        dartAsyncMarker: dartAsyncMarker);
  }

  TypeParameter createTypeParameter(String name) {
    return new TypeParameter(name);
  }

  TypeParameterType createTypeParameterType(
      TypeParameter typeParameter, Nullability nullability) {
    return new TypeParameterType(typeParameter, nullability);
  }

  TypeParameterType createTypeParameterTypeWithDefaultNullabilityForLibrary(
      TypeParameter typeParameter, Library library) {
    return new TypeParameterType.withDefaultNullabilityForLibrary(
        typeParameter, library);
  }

  FunctionExpression createFunctionExpression(
      int fileOffset, FunctionNode function) {
    assert(fileOffset != null);
    return new FunctionExpression(function)..fileOffset = fileOffset;
  }

  Expression createExpressionInvocation(
      int fileOffset, Expression expression, Arguments arguments) {
    assert(fileOffset != null);
    return new ExpressionInvocation(expression, arguments)
      ..fileOffset = fileOffset;
  }

  MethodInvocation createMethodInvocation(
      int fileOffset, Expression expression, Name name, Arguments arguments) {
    assert(fileOffset != null);
    return new MethodInvocation(expression, name, arguments)
      ..fileOffset = fileOffset;
  }

  NamedExpression createNamedExpression(
      int fileOffset, String name, Expression expression) {
    assert(fileOffset != null);
    return new NamedExpression(name, expression)..fileOffset = fileOffset;
  }

  StaticInvocation createStaticInvocation(
      int fileOffset, Procedure procedure, Arguments arguments) {
    assert(fileOffset != null);
    return new StaticInvocation(procedure, arguments)..fileOffset = fileOffset;
  }

  SuperMethodInvocation createSuperMethodInvocation(
      int fileOffset, Name name, Procedure procedure, Arguments arguments) {
    assert(fileOffset != null);
    return new SuperMethodInvocation(name, arguments, procedure)
      ..fileOffset = fileOffset;
  }

  NullCheck createNullCheck(int fileOffset, Expression expression) {
    assert(fileOffset != null);
    return new NullCheck(expression)..fileOffset = fileOffset;
  }

  PropertyGet createPropertyGet(int fileOffset, Expression receiver, Name name,
      {Member interfaceTarget}) {
    assert(fileOffset != null);
    return new PropertyGet(receiver, name, interfaceTarget)
      ..fileOffset = fileOffset;
  }

  PropertySet createPropertySet(
      int fileOffset, Expression receiver, Name name, Expression value,
      {Member interfaceTarget, bool forEffect, bool readOnlyReceiver: false}) {
    assert(fileOffset != null);
    return new PropertySetImpl(receiver, name, value,
        interfaceTarget: interfaceTarget,
        forEffect: forEffect,
        readOnlyReceiver: readOnlyReceiver)
      ..fileOffset = fileOffset;
  }

  IndexGet createIndexGet(
      int fileOffset, Expression receiver, Expression index) {
    assert(fileOffset != null);
    return new IndexGet(receiver, index)..fileOffset = fileOffset;
  }

  IndexSet createIndexSet(
      int fileOffset, Expression receiver, Expression index, Expression value,
      {bool forEffect}) {
    assert(fileOffset != null);
    assert(forEffect != null);
    return new IndexSet(receiver, index, value, forEffect: forEffect)
      ..fileOffset = fileOffset;
  }

  EqualsExpression createEquals(
      int fileOffset, Expression left, Expression right,
      {bool isNot}) {
    assert(fileOffset != null);
    assert(isNot != null);
    return new EqualsExpression(left, right, isNot: isNot)
      ..fileOffset = fileOffset;
  }

  BinaryExpression createBinary(
      int fileOffset, Expression left, Name binaryName, Expression right) {
    assert(fileOffset != null);
    return new BinaryExpression(left, binaryName, right)
      ..fileOffset = fileOffset;
  }

  UnaryExpression createUnary(
      int fileOffset, Name unaryName, Expression expression) {
    assert(fileOffset != null);
    return new UnaryExpression(unaryName, expression)..fileOffset = fileOffset;
  }

  ParenthesizedExpression createParenthesized(
      int fileOffset, Expression expression) {
    assert(fileOffset != null);
    return new ParenthesizedExpression(expression)..fileOffset = fileOffset;
  }
}

class _VariablesDeclaration extends Statement {
  final List<VariableDeclaration> declarations;
  final Uri uri;

  _VariablesDeclaration(this.declarations, this.uri) {
    setParents(declarations, this);
  }

  R accept<R>(v) {
    throw unsupported("accept", fileOffset, uri);
  }

  R accept1<R, A>(v, arg) {
    throw unsupported("accept1", fileOffset, uri);
  }

  visitChildren(v) {
    throw unsupported("visitChildren", fileOffset, uri);
  }

  transformChildren(v) {
    throw unsupported("transformChildren", fileOffset, uri);
  }

  @override
  String toString() {
    return "_VariablesDeclaration(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < declarations.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(declarations[index],
          includeModifiersAndType: index == 0);
    }
    printer.write(';');
  }
}
