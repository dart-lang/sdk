// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

import '../problems.dart' show unsupported;

import '../type_inference/type_schema.dart';

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

  ArgumentsImpl createArguments(int fileOffset, List<Expression> positional,
      {List<DartType>? types,
      List<NamedExpression>? named,
      bool hasExplicitTypeArguments = true,
      List<Object?>? argumentsOriginalOrder}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    if (!hasExplicitTypeArguments) {
      ArgumentsImpl arguments = new ArgumentsImpl(positional,
          types: <DartType>[],
          named: named,
          argumentsOriginalOrder: argumentsOriginalOrder);
      arguments.types.addAll(types!);
      return arguments;
    } else {
      return new ArgumentsImpl(positional,
          types: types,
          named: named,
          argumentsOriginalOrder: argumentsOriginalOrder)
        ..fileOffset = fileOffset;
    }
  }

  Arguments createArgumentsForExtensionMethod(
      int fileOffset,
      int extensionTypeParameterCount,
      int typeParameterCount,
      Expression receiver,
      {List<DartType> extensionTypeArguments = const <DartType>[],
      int? extensionTypeArgumentOffset,
      List<DartType> typeArguments = const <DartType>[],
      List<Expression> positionalArguments = const <Expression>[],
      List<NamedExpression> namedArguments = const <NamedExpression>[],
      List<Object?>? argumentsOriginalOrder}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ArgumentsImpl.forExtensionMethod(
        extensionTypeParameterCount, typeParameterCount, receiver,
        extensionTypeArguments: extensionTypeArguments,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
        typeArguments: typeArguments,
        positionalArguments: positionalArguments,
        namedArguments: namedArguments,
        argumentsOriginalOrder: argumentsOriginalOrder)
      ..fileOffset = fileOffset;
  }

  ArgumentsImpl createArgumentsEmpty(int fileOffset) {
    // ignore: unnecessary_null_comparison
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
    ArgumentsImpl.setNonInferrableArgumentTypes(
        arguments as ArgumentsImpl, types);
  }

  /// Return a representation of a boolean literal at the given [fileOffset].
  /// The literal has the given [value].
  BoolLiteral createBoolLiteral(int fileOffset, bool value) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new BoolLiteral(value)..fileOffset = fileOffset;
  }

  /// Return a representation of a double literal at the given [fileOffset]. The
  /// literal has the given [value].
  DoubleLiteral createDoubleLiteral(int fileOffset, double value) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new DoubleLiteral(value)..fileOffset = fileOffset;
  }

  /// Return a representation of an integer literal at the given [fileOffset].
  /// The literal has the given [value].
  IntLiteral createIntLiteral(int fileOffset, int value, [String? literal]) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new IntJudgment(value, literal)..fileOffset = fileOffset;
  }

  IntLiteral createIntLiteralLarge(int fileOffset, String literal) {
    // ignore: unnecessary_null_comparison
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
      {required bool isConst}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
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
      {required bool isConst}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
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
      DartType valueType, List<MapLiteralEntry> entries,
      {required bool isConst}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
    assert(isConst != null);
    return new MapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a null literal at the given [fileOffset].
  NullLiteral createNullLiteral(int fileOffset) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new NullLiteral()..fileOffset = fileOffset;
  }

  /// Return a representation of a simple string literal at the given
  /// [fileOffset]. The literal has the given [value]. This does not include
  /// either adjacent strings or interpolated strings.
  StringLiteral createStringLiteral(int fileOffset, String value) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new StringLiteral(value)..fileOffset = fileOffset;
  }

  /// Return a representation of a symbol literal defined by [value] at the
  /// given [fileOffset].
  SymbolLiteral createSymbolLiteral(int fileOffset, String value) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new SymbolLiteral(value)..fileOffset = fileOffset;
  }

  TypeLiteral createTypeLiteral(int fileOffset, DartType type) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new TypeLiteral(type)..fileOffset = fileOffset;
  }

  /// Return a representation of a key/value pair in a literal map at the given
  /// [fileOffset]. The [key] is the representation of the expression used to
  /// compute the key. The [value] is the representation of the expression used
  /// to compute the value.
  MapLiteralEntry createMapEntry(
      int fileOffset, Expression key, Expression value) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new MapLiteralEntry(key, value)..fileOffset = fileOffset;
  }

  LoadLibrary createLoadLibrary(
      int fileOffset, LibraryDependency dependency, Arguments? arguments) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new LoadLibraryImpl(dependency, arguments)..fileOffset = fileOffset;
  }

  Expression checkLibraryIsLoaded(
      int fileOffset, LibraryDependency dependency) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new CheckLibraryIsLoaded(dependency)..fileOffset = fileOffset;
  }

  Expression createAsExpression(
      int fileOffset, Expression expression, DartType type,
      {required bool forNonNullableByDefault, bool forDynamic = false}) {
    // ignore: unnecessary_null_comparison
    assert(forNonNullableByDefault != null);
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new AsExpression(expression, type)
      ..fileOffset = fileOffset
      ..isForNonNullableByDefault = forNonNullableByDefault
      ..isForDynamic = forDynamic;
  }

  Expression createSpreadElement(int fileOffset, Expression expression,
      {required bool isNullAware}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
    assert(isNullAware != null);
    return new SpreadElement(expression, isNullAware: isNullAware)
      ..fileOffset = fileOffset;
  }

  Expression createIfElement(
      int fileOffset, Expression condition, Expression then,
      [Expression? otherwise]) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new IfElement(condition, then, otherwise)..fileOffset = fileOffset;
  }

  Expression createIfCaseElement(int fileOffset,
      {required List<Statement> prelude,
      required Expression expression,
      required PatternGuard patternGuard,
      required Expression then,
      Expression? otherwise}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new IfCaseElement(
        prelude: prelude,
        expression: expression,
        patternGuard: patternGuard,
        then: then,
        otherwise: otherwise)
      ..fileOffset = fileOffset;
  }

  MapLiteralEntry createIfMapEntry(
      int fileOffset, Expression condition, MapLiteralEntry then,
      [MapLiteralEntry? otherwise]) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new IfMapEntry(condition, then, otherwise)..fileOffset = fileOffset;
  }

  MapLiteralEntry createIfCaseMapEntry(int fileOffset,
      {required List<Statement> prelude,
      required Expression expression,
      required PatternGuard patternGuard,
      required MapLiteralEntry then,
      MapLiteralEntry? otherwise}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new IfCaseMapEntry(
        prelude: prelude,
        expression: expression,
        patternGuard: patternGuard,
        then: then,
        otherwise: otherwise)
      ..fileOffset = fileOffset;
  }

  ForElement createForElement(
      int fileOffset,
      List<VariableDeclaration> variables,
      Expression? condition,
      List<Expression> updates,
      Expression body) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ForElement(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  PatternForElement createPatternForElement(int fileOffset,
      {required PatternVariableDeclaration patternVariableDeclaration,
      required List<VariableDeclaration> intermediateVariables,
      required List<VariableDeclaration> variables,
      required Expression? condition,
      required List<Expression> updates,
      required Expression body}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new PatternForElement(
        patternVariableDeclaration: patternVariableDeclaration,
        intermediateVariables: intermediateVariables,
        variables: variables,
        condition: condition,
        updates: updates,
        body: body)
      ..fileOffset = fileOffset;
  }

  ForMapEntry createForMapEntry(
      int fileOffset,
      List<VariableDeclaration> variables,
      Expression? condition,
      List<Expression> updates,
      MapLiteralEntry body) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ForMapEntry(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  PatternForMapEntry createPatternForMapEntry(int fileOffset,
      {required PatternVariableDeclaration patternVariableDeclaration,
      required List<VariableDeclaration> intermediateVariables,
      required List<VariableDeclaration> variables,
      required Expression? condition,
      required List<Expression> updates,
      required MapLiteralEntry body}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new PatternForMapEntry(
        patternVariableDeclaration: patternVariableDeclaration,
        intermediateVariables: intermediateVariables,
        variables: variables,
        condition: condition,
        updates: updates,
        body: body)
      ..fileOffset = fileOffset;
  }

  ForInElement createForInElement(
      int fileOffset,
      VariableDeclaration variable,
      Expression iterable,
      Expression? synthesizedAssignment,
      Statement? expressionEffects,
      Expression body,
      Expression? problem,
      {bool isAsync = false}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ForInElement(variable, iterable, synthesizedAssignment,
        expressionEffects, body, problem,
        isAsync: isAsync)
      ..fileOffset = fileOffset;
  }

  ForInMapEntry createForInMapEntry(
      int fileOffset,
      VariableDeclaration variable,
      Expression iterable,
      Expression? synthesizedAssignment,
      Statement? expressionEffects,
      MapLiteralEntry body,
      Expression? problem,
      {bool isAsync = false}) {
    // ignore: unnecessary_null_comparison
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
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new AssertInitializer(assertStatement)..fileOffset = fileOffset;
  }

  /// Return a representation of an assert that appears as a statement.
  AssertStatement createAssertStatement(int fileOffset, Expression condition,
      Expression? message, int conditionStartOffset, int conditionEndOffset) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new AssertStatement(condition,
        conditionStartOffset: conditionStartOffset,
        conditionEndOffset: conditionEndOffset,
        message: message)
      ..fileOffset = fileOffset;
  }

  Expression createAwaitExpression(int fileOffset, Expression operand) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new AwaitExpression(operand)..fileOffset = fileOffset;
  }

  /// Return a representation of a block of [statements] at the given
  /// [fileOffset].
  Block createBlock(
      int fileOffset, int fileEndOffset, List<Statement> statements) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    List<Statement>? copy;
    for (int i = 0; i < statements.length; i++) {
      Statement statement = statements[i];
      if (statement is _VariablesDeclaration) {
        copy ??= new List<Statement>.of(statements.getRange(0, i));
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
  Statement createBreakStatement(int fileOffset, Object? label) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // TODO(johnniwinther): Use [label]?
    return new BreakStatementImpl(isContinue: false)
      ..fileOffset = fileOffset
      ..target = label is LabeledStatement ? label : dummyLabeledStatement;
  }

  /// Return a representation of a catch clause.
  Catch createCatch(
      int fileOffset,
      DartType exceptionType,
      VariableDeclaration? exceptionParameter,
      VariableDeclaration? stackTraceParameter,
      DartType stackTraceType,
      Statement body) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new Catch(exceptionParameter, body,
        guard: exceptionType, stackTrace: stackTraceParameter)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a conditional expression at the given
  /// [fileOffset]. The [condition] is the expression preceding the question
  /// mark. The [thenExpression] is the expression following the question mark.
  /// The [elseExpression] is the expression following the colon.
  ConditionalExpression createConditionalExpression(
      int fileOffset,
      Expression condition,
      Expression thenExpression,
      Expression elseExpression) {
    return new ConditionalExpression(
        condition, thenExpression, elseExpression, const UnknownType())
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a continue statement.
  Statement createContinueStatement(int fileOffset, Object? label) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // TODO(johnniwinther): Use [label]?
    return new BreakStatementImpl(isContinue: true)..fileOffset = fileOffset;
  }

  /// Return a representation of a do statement.
  Statement createDoStatement(
      int fileOffset, Statement body, Expression condition) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new DoStatement(body, condition)..fileOffset = fileOffset;
  }

  /// Return a representation of an expression statement at the given
  /// [fileOffset] containing the [expression].
  Statement createExpressionStatement(int fileOffset, Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ExpressionStatement(expression)..fileOffset = fileOffset;
  }

  /// Return a representation of an empty statement  at the given [fileOffset].
  Statement createEmptyStatement(int fileOffset) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new EmptyStatement()..fileOffset = fileOffset;
  }

  /// Return a representation of a for statement.
  Statement createForStatement(
      int fileOffset,
      List<VariableDeclaration>? variables,
      Expression? condition,
      List<Expression> updaters,
      Statement body) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ForStatement(variables ?? [], condition, updaters, body)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of an `if` statement.
  Statement createIfStatement(int fileOffset, Expression condition,
      Statement thenStatement, Statement? elseStatement) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new IfStatement(condition, thenStatement, elseStatement)
      ..fileOffset = fileOffset;
  }

  /// Return a representation of a `switch` statement.
  Statement createSwitchStatement(
      int fileOffset, Expression expression, List<SwitchCase> cases) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new SwitchStatement(expression, cases)..fileOffset = fileOffset;
  }

  /// Return a representation of an `is` expression at the given [fileOffset].
  /// The [operand] is the representation of the left operand. The [type] is a
  /// representation of the type that is the right operand. If [notFileOffset]
  /// is non-null the test is negated the that file offset.
  Expression createIsExpression(
      int fileOffset, Expression operand, DartType type,
      {required bool forNonNullableByDefault, int? notFileOffset}) {
    // ignore: unnecessary_null_comparison
    assert(forNonNullableByDefault != null);
    // ignore: unnecessary_null_comparison
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
    // ignore: unnecessary_null_comparison
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
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new Not(operand)..fileOffset = fileOffset;
  }

  /// Return a representation of a rethrow statement consisting of the
  /// rethrow at [rethrowFileOffset] and the statement at [statementFileOffset].
  Statement createRethrowStatement(
      int rethrowFileOffset, int statementFileOffset) {
    // ignore: unnecessary_null_comparison
    assert(rethrowFileOffset != null);
    // ignore: unnecessary_null_comparison
    assert(statementFileOffset != null);
    return new ExpressionStatement(
        new Rethrow()..fileOffset = rethrowFileOffset)
      ..fileOffset = statementFileOffset;
  }

  /// Return a representation of a return statement.
  Statement createReturnStatement(int fileOffset, Expression? expression,
      {bool isArrow = true}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ReturnStatementImpl(isArrow, expression)
      ..fileOffset = fileOffset;
  }

  Expression createStringConcatenation(
      int fileOffset, List<Expression> expressions) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new StringConcatenation(expressions)..fileOffset = fileOffset;
  }

  /// The given [statement] is being used as the target of either a break or
  /// continue statement. Return the statement that should be used as the actual
  /// target.
  LabeledStatement createLabeledStatement(Statement statement) {
    return new LabeledStatement(statement)..fileOffset = statement.fileOffset;
  }

  Expression createThisExpression(int fileOffset) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ThisExpression()..fileOffset = fileOffset;
  }

  /// Return a representation of a throw expression at the given [fileOffset].
  Expression createThrow(int fileOffset, Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new Throw(expression)..fileOffset = fileOffset;
  }

  bool isThrow(Object? o) => o is Throw;

  Statement createTryStatement(int fileOffset, Statement tryBlock,
      List<Catch>? catchBlocks, Statement? finallyBlock) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new TryStatement(tryBlock, catchBlocks ?? <Catch>[], finallyBlock)
      ..fileOffset = fileOffset;
  }

  _VariablesDeclaration variablesDeclaration(
      List<VariableDeclaration> declarations, Uri uri) {
    return new _VariablesDeclaration(declarations, uri);
  }

  List<VariableDeclaration> variablesDeclarationExtractDeclarations(
      Object? variablesDeclaration) {
    return (variablesDeclaration as _VariablesDeclaration).declarations;
  }

  Statement wrapVariables(Statement statement) {
    if (statement is _VariablesDeclaration) {
      return new Block(
          new List<Statement>.of(statement.declarations, growable: true))
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
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new WhileStatement(condition, body)..fileOffset = fileOffset;
  }

  /// Return a representation of a yield statement at the given [fileOffset]
  /// of the given [expression]. If [isYieldStar] is `true` the created
  /// statement is a yield* statement.
  Statement createYieldStatement(int fileOffset, Expression expression,
      {required bool isYieldStar}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
    assert(isYieldStar != null);
    return new YieldStatement(expression, isYieldStar: isYieldStar)
      ..fileOffset = fileOffset;
  }

  bool isErroneousNode(Object? node) {
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

  bool isVariablesDeclaration(Object? node) => node is _VariablesDeclaration;

  /// Creates [VariableDeclaration] for a variable named [name] at the given
  /// [functionNestingLevel].
  VariableDeclaration createVariableDeclaration(int fileOffset, String? name,
      {Expression? initializer,
      DartType? type,
      bool isFinal = false,
      bool isConst = false,
      bool isInitializingFormal = false,
      bool isCovariantByDeclaration = false,
      bool isLocalFunction = false,
      bool isSynthesized = false}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new VariableDeclarationImpl(name,
        type: type,
        initializer: initializer,
        isFinal: isFinal,
        isConst: isConst,
        isInitializingFormal: isInitializingFormal,
        isCovariantByDeclaration: isCovariantByDeclaration,
        isLocalFunction: isLocalFunction,
        isSynthesized: isSynthesized,
        hasDeclaredInitializer: initializer != null)
      ..fileOffset = fileOffset;
  }

  VariableDeclarationImpl createVariableDeclarationForValue(
      Expression initializer,
      {DartType type = const DynamicType()}) {
    return new VariableDeclarationImpl.forValue(initializer)
      ..type = type
      ..fileOffset = initializer.fileOffset;
  }

  VariableDeclarationImpl createVariableDeclarationForHoisting(
      Expression expression) {
    return new VariableDeclarationImpl.forValue(expression)
      ..fileOffset = expression.fileOffset;
  }

  FunctionNode createFunctionNode(int fileOffset, Statement body,
      {List<TypeParameter>? typeParameters,
      List<VariableDeclaration>? positionalParameters,
      List<VariableDeclaration>? namedParameters,
      int? requiredParameterCount,
      DartType returnType = const DynamicType(),
      AsyncMarker asyncMarker = AsyncMarker.Sync,
      AsyncMarker? dartAsyncMarker}) {
    // ignore: unnecessary_null_comparison
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
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new FunctionExpression(function)..fileOffset = fileOffset;
  }

  Expression createExpressionInvocation(
      int fileOffset, Expression expression, Arguments arguments) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ExpressionInvocation(expression, arguments)
      ..fileOffset = fileOffset;
  }

  Expression createMethodInvocation(
      int fileOffset, Expression expression, Name name, Arguments arguments) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new MethodInvocation(expression, name, arguments)
      ..fileOffset = fileOffset;
  }

  NamedExpression createNamedExpression(
      int fileOffset, String name, Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new NamedExpression(name, expression)..fileOffset = fileOffset;
  }

  StaticInvocation createStaticInvocation(
      int fileOffset, Procedure procedure, Arguments arguments) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new StaticInvocation(procedure, arguments)..fileOffset = fileOffset;
  }

  SuperMethodInvocation createSuperMethodInvocation(
      int fileOffset, Name name, Procedure procedure, Arguments arguments) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new SuperMethodInvocation(name, arguments, procedure)
      ..fileOffset = fileOffset;
  }

  NullCheck createNullCheck(int fileOffset, Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new NullCheck(expression)..fileOffset = fileOffset;
  }

  Expression createPropertyGet(int fileOffset, Expression receiver, Name name) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new PropertyGet(receiver, name)..fileOffset = fileOffset;
  }

  Expression createPropertySet(
      int fileOffset, Expression receiver, Name name, Expression value,
      {required bool forEffect, bool readOnlyReceiver = false}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new PropertySet(receiver, name, value,
        forEffect: forEffect, readOnlyReceiver: readOnlyReceiver)
      ..fileOffset = fileOffset;
  }

  IndexGet createIndexGet(
      int fileOffset, Expression receiver, Expression index) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new IndexGet(receiver, index)..fileOffset = fileOffset;
  }

  IndexSet createIndexSet(
      int fileOffset, Expression receiver, Expression index, Expression value,
      {required bool forEffect}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
    assert(forEffect != null);
    return new IndexSet(receiver, index, value, forEffect: forEffect)
      ..fileOffset = fileOffset;
  }

  VariableGet createVariableGet(int fileOffset, VariableDeclaration variable) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new VariableGetImpl(variable, forNullGuardedAccess: false)
      ..fileOffset = fileOffset;
  }

  EqualsExpression createEquals(
      int fileOffset, Expression left, Expression right,
      {required bool isNot}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
    assert(isNot != null);
    return new EqualsExpression(left, right, isNot: isNot)
      ..fileOffset = fileOffset;
  }

  BinaryExpression createBinary(
      int fileOffset, Expression left, Name binaryName, Expression right) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new BinaryExpression(left, binaryName, right)
      ..fileOffset = fileOffset;
  }

  UnaryExpression createUnary(
      int fileOffset, Name unaryName, Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new UnaryExpression(unaryName, expression)..fileOffset = fileOffset;
  }

  ParenthesizedExpression createParenthesized(
      int fileOffset, Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new ParenthesizedExpression(expression)..fileOffset = fileOffset;
  }

  ConstructorTearOff createConstructorTearOff(int fileOffset, Member target) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(target is Constructor || (target is Procedure && target.isFactory),
        "Unexpected constructor tear off target: $target");
    return new ConstructorTearOff(target)..fileOffset = fileOffset;
  }

  StaticTearOff createStaticTearOff(int fileOffset, Procedure procedure) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(procedure.kind == ProcedureKind.Method,
        "Unexpected static tear off target: $procedure");
    assert(!procedure.isRedirectingFactory,
        "Unexpected static tear off target: $procedure");
    return new StaticTearOff(procedure)..fileOffset = fileOffset;
  }

  StaticGet createStaticGet(int fileOffset, Member target) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(target is Field || (target is Procedure && target.isGetter));
    return new StaticGet(target)..fileOffset = fileOffset;
  }

  RedirectingFactoryTearOff createRedirectingFactoryTearOff(
      int fileOffset, Procedure procedure) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(procedure.isRedirectingFactory);
    return new RedirectingFactoryTearOff(procedure)..fileOffset = fileOffset;
  }

  Instantiation createInstantiation(
      int fileOffset, Expression expression, List<DartType> typeArguments) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new Instantiation(expression, typeArguments)
      ..fileOffset = fileOffset;
  }

  TypedefTearOff createTypedefTearOff(
      int fileOffset,
      List<TypeParameter> typeParameters,
      Expression expression,
      List<DartType> typeArguments) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    return new TypedefTearOff(typeParameters, expression, typeArguments)
      ..fileOffset = fileOffset;
  }

  AndPattern createAndPattern(int fileOffset, Pattern left, Pattern right) {
    return new AndPattern(left, right)..fileOffset = fileOffset;
  }

  AssignedVariablePattern createAssignedVariablePattern(
      int fileOffset, VariableDeclaration variable) {
    return new AssignedVariablePattern(variable)..fileOffset = fileOffset;
  }

  CastPattern createCastPattern(
      int fileOffset, Pattern pattern, DartType type) {
    return new CastPattern(pattern, type)..fileOffset = fileOffset;
  }

  ConstantPattern createConstantPattern(Expression expression) {
    return new ConstantPattern(expression)..fileOffset = expression.fileOffset;
  }

  InvalidPattern createInvalidPattern(Expression expression,
      {required List<VariableDeclaration> declaredVariables}) {
    return new InvalidPattern(expression, declaredVariables: declaredVariables)
      ..fileOffset = expression.fileOffset;
  }

  ListPattern createListPattern(
      int fileOffset, DartType? typeArgument, List<Pattern> patterns) {
    return new ListPattern(typeArgument, patterns)..fileOffset = fileOffset;
  }

  MapPattern createMapPattern(int fileOffset, DartType? keyType,
      DartType? valueType, List<MapPatternEntry> entries) {
    return new MapPattern(keyType, valueType, entries)..fileOffset = fileOffset;
  }

  MapPatternEntry createMapPatternEntry(
      int fileOffset, Expression key, Pattern value) {
    return new MapPatternEntry(key, value)..fileOffset = fileOffset;
  }

  MapPatternRestEntry createMapPatternRestEntry(int fileOffset) {
    return new MapPatternRestEntry()..fileOffset = fileOffset;
  }

  NamedPattern createNamedPattern(
      int fileOffset, String name, Pattern pattern) {
    return new NamedPattern(name, pattern)..fileOffset = fileOffset;
  }

  NullAssertPattern createNullAssertPattern(int fileOffset, Pattern pattern) {
    return new NullAssertPattern(pattern)..fileOffset = fileOffset;
  }

  NullCheckPattern createNullCheckPattern(int fileOffset, Pattern pattern) {
    return new NullCheckPattern(pattern)..fileOffset = fileOffset;
  }

  OrPattern createOrPattern(int fileOffset, Pattern left, Pattern right,
      {required List<VariableDeclaration> orPatternJointVariables}) {
    return new OrPattern(left, right,
        orPatternJointVariables: orPatternJointVariables)
      ..fileOffset = fileOffset;
  }

  RecordPattern createRecordPattern(int fileOffset, List<Pattern> patterns) {
    return new RecordPattern(patterns)..fileOffset = fileOffset;
  }

  RelationalPattern createRelationalPattern(
      int fileOffset, RelationalPatternKind kind, Expression expression) {
    return new RelationalPattern(kind, expression)..fileOffset = fileOffset;
  }

  RestPattern createRestPattern(int fileOffset, Pattern? subPattern) {
    return new RestPattern(subPattern)..fileOffset = fileOffset;
  }

  VariablePattern createVariablePattern(
      int fileOffset, DartType? type, VariableDeclaration variable) {
    return new VariablePattern(type, variable)..fileOffset = fileOffset;
  }

  WildcardPattern createWildcardPattern(int fileOffset, DartType? type) {
    return new WildcardPattern(type)..fileOffset = fileOffset;
  }

  PatternGuard createPatternGuard(int fileOffset, Pattern pattern,
      [Expression? guard]) {
    return new PatternGuard(pattern, guard)..fileOffset = fileOffset;
  }

  PatternSwitchCase createPatternSwitchCase(int fileOffset,
      List<int> caseOffsets, List<PatternGuard> patternGuards, Statement body,
      {required bool isDefault,
      required bool hasLabel,
      required List<VariableDeclaration> jointVariables,
      required List<int>? jointVariableFirstUseOffsets}) {
    return new PatternSwitchCase(caseOffsets, patternGuards, body,
        isDefault: isDefault,
        hasLabel: hasLabel,
        jointVariables: jointVariables,
        jointVariableFirstUseOffsets: jointVariableFirstUseOffsets)
      ..fileOffset = fileOffset;
  }

  PatternSwitchStatement createPatternSwitchStatement(
      int fileOffset, Expression expression, List<PatternSwitchCase> cases) {
    return new PatternSwitchStatement(expression, cases)
      ..fileOffset = fileOffset;
  }

  SwitchExpressionCase createSwitchExpressionCase(
      int fileOffset, PatternGuard patternGuard, Expression expression) {
    return new SwitchExpressionCase(patternGuard, expression)
      ..fileOffset = fileOffset;
  }

  SwitchExpression createSwitchExpression(
      int fileOffset, Expression expression, List<SwitchExpressionCase> cases) {
    return new SwitchExpression(expression, cases)..fileOffset = fileOffset;
  }

  PatternVariableDeclaration createPatternVariableDeclaration(
      int fileOffset, Pattern pattern, Expression initializer,
      {required bool isFinal}) {
    return new PatternVariableDeclaration(pattern, initializer,
        isFinal: isFinal)
      ..fileOffset = fileOffset;
  }

  PatternAssignment createPatternAssignment(
      int fileOffset, Pattern pattern, Expression expression) {
    return new PatternAssignment(pattern, expression)..fileOffset = fileOffset;
  }

  IfCaseStatement createIfCaseStatement(int fileOffset, Expression expression,
      PatternGuard patternGuard, Statement then, Statement? otherwise) {
    return new IfCaseStatement(expression, patternGuard, then, otherwise)
      ..fileOffset = fileOffset;
  }
}

class _VariablesDeclaration extends Statement {
  final List<VariableDeclaration> declarations;
  final Uri uri;

  _VariablesDeclaration(this.declarations, this.uri) {
    setParents(declarations, this);
  }

  @override
  R accept<R>(v) {
    throw unsupported("accept", fileOffset, uri);
  }

  @override
  R accept1<R, A>(v, arg) {
    throw unsupported("accept1", fileOffset, uri);
  }

  @override
  Never visitChildren(v) {
    throw unsupported("visitChildren", fileOffset, uri);
  }

  @override
  Never transformChildren(v) {
    throw unsupported("transformChildren", fileOffset, uri);
  }

  @override
  Never transformOrRemoveChildren(v) {
    throw unsupported("transformOrRemoveChildren", fileOffset, uri);
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
