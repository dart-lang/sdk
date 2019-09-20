// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../names.dart';

import '../parser.dart' show offsetForToken, optional;

import '../problems.dart' show unsupported;

import '../scanner.dart' show Token;

import 'collections.dart'
    show
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfElement,
        IfMapEntry,
        SpreadElement;

import 'kernel_shadow_ast.dart'
    show
        ArgumentsImpl,
        IntJudgment,
        LoadLibraryImpl,
        MethodInvocationImpl,
        ReturnStatementImpl,
        ShadowLargeIntLiteral,
        SyntheticExpressionJudgment,
        VariableDeclarationImpl;

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
      List<DartType> typeArguments = const <DartType>[],
      List<Expression> positionalArguments = const <Expression>[],
      List<NamedExpression> namedArguments = const <NamedExpression>[]}) {
    return new ArgumentsImpl.forExtensionMethod(
        extensionTypeParameterCount, typeParameterCount, receiver,
        extensionTypeArguments: extensionTypeArguments,
        typeArguments: typeArguments,
        positionalArguments: positionalArguments,
        namedArguments: namedArguments)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  Arguments createArgumentsEmpty(int fileOffset) {
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

  StringLiteral asLiteralString(Expression value) => value;

  /// Return a representation of a boolean literal at the given [location]. The
  /// literal has the given [value].
  BoolLiteral createBoolLiteral(bool value, Token token) {
    return new BoolLiteral(value)..fileOffset = offsetForToken(token);
  }

  /// Return a representation of a double literal at the given [location]. The
  /// literal has the given [value].
  DoubleLiteral createDoubleLiteral(double value, Token token) {
    return new DoubleLiteral(value)..fileOffset = offsetForToken(token);
  }

  /// Return a representation of an integer literal at the given [location]. The
  /// literal has the given [value].
  IntLiteral createIntLiteral(int value, Token token) {
    return new IntJudgment(value, token?.lexeme)
      ..fileOffset = offsetForToken(token);
  }

  IntLiteral createIntLiteralLarge(String literal, Token token) {
    return new ShadowLargeIntLiteral(literal, offsetForToken(token));
  }

  /// Return a representation of a list literal. The [constKeyword] is the
  /// location of the `const` keyword, or `null` if there is no keyword. The
  /// [isConst] is `true` if the literal is either explicitly or implicitly a
  /// constant. The [typeArgument] is the representation of the single valid
  /// type argument preceding the list literal, or `null` if there is no type
  /// argument, there is more than one type argument, or if the type argument
  /// cannot be resolved. The [typeArguments] is the representation of all of
  /// the type arguments preceding the list literal, or `null` if there are no
  /// type arguments. The [leftBracket] is the location of the `[`. The list of
  /// [expressions] is a list of the representations of the list elements. The
  /// [rightBracket] is the location of the `]`.
  ListLiteral createListLiteral(
      Token constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Token leftBracket,
      List<Expression> expressions,
      Token rightBracket) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new ListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBracket);
  }

  /// Return a representation of a set literal. The [constKeyword] is the
  /// location of the `const` keyword, or `null` if there is no keyword. The
  /// [isConst] is `true` if the literal is either explicitly or implicitly a
  /// constant. The [typeArgument] is the representation of the single valid
  /// type argument preceding the set literal, or `null` if there is no type
  /// argument, there is more than one type argument, or if the type argument
  /// cannot be resolved. The [typeArguments] is the representation of all of
  /// the type arguments preceding the set literal, or `null` if there are no
  /// type arguments. The [leftBrace] is the location of the `{`. The list of
  /// [expressions] is a list of the representations of the set elements. The
  /// [rightBrace] is the location of the `}`.
  SetLiteral createSetLiteral(
      Token constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Token leftBrace,
      List<Expression> expressions,
      Token rightBrace) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new SetLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBrace);
  }

  /// Return a representation of a map literal. The [constKeyword] is the
  /// location of the `const` keyword, or `null` if there is no keyword. The
  /// [isConst] is `true` if the literal is either explicitly or implicitly a
  /// constant. The [keyType] is the representation of the first type argument
  /// preceding the map literal, or `null` if there are not exactly two type
  /// arguments or if the first type argument cannot be resolved. The
  /// [valueType] is the representation of the second type argument preceding
  /// the map literal, or `null` if there are not exactly two type arguments or
  /// if the second type argument cannot be resolved. The [typeArguments] is the
  /// representation of all of the type arguments preceding the map literal, or
  /// `null` if there are no type arguments. The [leftBrace] is the location
  /// of the `{`. The list of [entries] is a list of the representations of the
  /// map entries. The [rightBrace] is the location of the `}`.
  MapLiteral createMapLiteral(
      Token constKeyword,
      bool isConst,
      DartType keyType,
      DartType valueType,
      Object typeArguments,
      Token leftBrace,
      List<MapEntry> entries,
      Token rightBrace) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new MapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBrace);
  }

  /// Return a representation of a null literal at the given [fileOffset].
  NullLiteral createNullLiteral(int fileOffset) {
    return new NullLiteral()..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  /// Return a representation of a simple string literal at the given
  /// [location]. The literal has the given [value]. This does not include
  /// either adjacent strings or interpolated strings.
  StringLiteral createStringLiteral(String value, Token token) {
    return new StringLiteral(value)..fileOffset = offsetForToken(token);
  }

  /// Return a representation of a symbol literal defined by [value].
  SymbolLiteral createSymbolLiteral(String value, Token token) {
    return new SymbolLiteral(value)..fileOffset = offsetForToken(token);
  }

  TypeLiteral createTypeLiteral(DartType type, Token token) {
    return new TypeLiteral(type)..fileOffset = offsetForToken(token);
  }

  /// Return a representation of a key/value pair in a literal map. The [key] is
  /// the representation of the expression used to compute the key. The [colon]
  /// is the location of the colon separating the key and the value. The [value]
  /// is the representation of the expression used to compute the value.
  MapEntry createMapEntry(Expression key, Token colon, Expression value) {
    return new MapEntry(key, value)..fileOffset = offsetForToken(colon);
  }

  int readOffset(TreeNode node) => node.fileOffset;

  Expression createLoadLibrary(
      LibraryDependency dependency, Arguments arguments) {
    return new LoadLibraryImpl(dependency, arguments);
  }

  Expression checkLibraryIsLoaded(LibraryDependency dependency) {
    return new CheckLibraryIsLoaded(dependency);
  }

  Expression createAsExpression(
      Expression expression, DartType type, Token token) {
    return new AsExpression(expression, type)
      ..fileOffset = offsetForToken(token);
  }

  Expression createSpreadElement(Expression expression, Token token) {
    return new SpreadElement(expression, token.lexeme == '...?')
      ..fileOffset = offsetForToken(token);
  }

  Expression createIfElement(Expression condition, Expression then,
      Expression otherwise, Token token) {
    return new IfElement(condition, then, otherwise)
      ..fileOffset = offsetForToken(token);
  }

  MapEntry createIfMapEntry(
      Expression condition, MapEntry then, MapEntry otherwise, Token token) {
    return new IfMapEntry(condition, then, otherwise)
      ..fileOffset = offsetForToken(token);
  }

  Expression createForElement(
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      Expression body,
      Token token) {
    return new ForElement(variables, condition, updates, body)
      ..fileOffset = offsetForToken(token);
  }

  MapEntry createForMapEntry(
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      MapEntry body,
      Token token) {
    return new ForMapEntry(variables, condition, updates, body)
      ..fileOffset = offsetForToken(token);
  }

  Expression createForInElement(
      VariableDeclaration variable,
      Expression iterable,
      Statement prologue,
      Expression body,
      Expression problem,
      Token token,
      {bool isAsync: false}) {
    return new ForInElement(variable, iterable, prologue, body, problem,
        isAsync: isAsync)
      ..fileOffset = offsetForToken(token);
  }

  MapEntry createForInMapEntry(
      VariableDeclaration variable,
      Expression iterable,
      Statement prologue,
      MapEntry body,
      Expression problem,
      Token token,
      {bool isAsync: false}) {
    return new ForInMapEntry(variable, iterable, prologue, body, problem,
        isAsync: isAsync)
      ..fileOffset = offsetForToken(token);
  }

  /// Return a representation of an assert that appears in a constructor's
  /// initializer list.
  AssertInitializer createAssertInitializer(
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message) {
    return new AssertInitializer(createAssertStatement(
        assertKeyword, leftParenthesis, condition, comma, message, null));
  }

  /// Return a representation of an assert that appears as a statement.
  Statement createAssertStatement(Token assertKeyword, Token leftParenthesis,
      Expression condition, Token comma, Expression message, Token semicolon) {
    // Compute start and end offsets for the condition expression.
    // This code is a temporary workaround because expressions don't carry
    // their start and end offsets currently.
    //
    // The token that follows leftParenthesis is considered to be the
    // first token of the condition.
    // TODO(ahe): this really should be condition.fileOffset.
    int startOffset = leftParenthesis.next.offset;
    int endOffset;
    {
      // Search forward from leftParenthesis to find the last token of
      // the condition - which is a token immediately followed by a commaToken,
      // right parenthesis or a trailing comma.
      Token conditionBoundary = comma ?? leftParenthesis.endGroup;
      Token conditionLastToken = leftParenthesis;
      while (!conditionLastToken.isEof) {
        Token nextToken = conditionLastToken.next;
        if (nextToken == conditionBoundary) {
          break;
        } else if (optional(',', nextToken) &&
            nextToken.next == conditionBoundary) {
          // The next token is trailing comma, which means current token is
          // the last token of the condition.
          break;
        }
        conditionLastToken = nextToken;
      }
      if (conditionLastToken.isEof) {
        endOffset = startOffset = -1;
      } else {
        endOffset = conditionLastToken.offset + conditionLastToken.length;
      }
    }
    return new AssertStatement(condition,
        conditionStartOffset: startOffset,
        conditionEndOffset: endOffset,
        message: message);
  }

  Expression createAwaitExpression(Expression operand, Token token) {
    return new AwaitExpression(operand)..fileOffset = offsetForToken(token);
  }

  /// Return a representation of a block of [statements] enclosed between the
  /// [openBracket] and [closeBracket].
  Statement createBlock(
      Token openBrace, List<Statement> statements, Token closeBrace) {
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
      ..fileOffset = offsetForToken(openBrace);
  }

  /// Return a representation of a break statement.
  Statement createBreakStatement(
      Token breakKeyword, Object label, Token semicolon) {
    return new BreakStatement(null)..fileOffset = breakKeyword.charOffset;
  }

  /// Return a representation of a catch clause.
  Catch createCatch(
      Token onKeyword,
      DartType exceptionType,
      Token catchKeyword,
      VariableDeclaration exceptionParameter,
      VariableDeclaration stackTraceParameter,
      DartType stackTraceType,
      Statement body) {
    return new Catch(exceptionParameter, body,
        guard: exceptionType, stackTrace: stackTraceParameter)
      ..fileOffset = offsetForToken(onKeyword ?? catchKeyword);
  }

  /// Return a representation of a conditional expression. The [condition] is
  /// the expression preceding the question mark. The [question] is the `?`. The
  /// [thenExpression] is the expression following the question mark. The
  /// [colon] is the `:`. The [elseExpression] is the expression following the
  /// colon.
  Expression createConditionalExpression(Expression condition, Token question,
      Expression thenExpression, Token colon, Expression elseExpression) {
    return new ConditionalExpression(
        condition, thenExpression, elseExpression, null)
      ..fileOffset = offsetForToken(question);
  }

  /// Return a representation of a continue statement.
  Statement createContinueStatement(
      Token continueKeyword, Object label, Token semicolon) {
    return new BreakStatement(null)..fileOffset = continueKeyword.charOffset;
  }

  /// Return a representation of a do statement.
  Statement createDoStatement(Token doKeyword, Statement body,
      Token whileKeyword, Expression condition, Token semicolon) {
    return new DoStatement(body, condition)..fileOffset = doKeyword.charOffset;
  }

  /// Return a representation of an expression statement composed from the
  /// [expression] and [semicolon].
  Statement createExpressionStatement(Expression expression, Token semicolon) {
    return new ExpressionStatement(expression);
  }

  /// Return a representation of an empty statement consisting of the given
  /// [semicolon].
  Statement createEmptyStatement(Token semicolon) {
    return new EmptyStatement();
  }

  /// Return a representation of a for statement.
  Statement createForStatement(
      Token forKeyword,
      Token leftParenthesis,
      List<VariableDeclaration> variables,
      Token leftSeparator,
      Expression condition,
      Statement conditionStatement,
      List<Expression> updaters,
      Token rightParenthesis,
      Statement body) {
    return new ForStatement(variables ?? [], condition, updaters, body)
      ..fileOffset = forKeyword.charOffset;
  }

  /// Return a representation of an `if` statement.
  Statement createIfStatement(Token ifKeyword, Expression condition,
      Statement thenStatement, Token elseKeyword, Statement elseStatement) {
    return new IfStatement(condition, thenStatement, elseStatement)
      ..fileOffset = ifKeyword.charOffset;
  }

  /// Return a representation of an `is` expression. The [operand] is the
  /// representation of the left operand. The [isOperator] is the `is` operator.
  /// The [notOperator] is either the `!` or `null` if the test is not negated.
  /// The [type] is a representation of the type that is the right operand.
  Expression createIsExpression(
      Expression operand, Token isOperator, Token notOperator, DartType type) {
    Expression result = new IsExpression(operand, type)
      ..fileOffset = offsetForToken(isOperator);
    if (notOperator != null) {
      result = createNot(result, notOperator, false);
    }
    return result;
  }

  /// Return a representation of a logical expression having the [leftOperand],
  /// [rightOperand] and the [operator] (either `&&` or `||`).
  Expression createLogicalExpression(
      Expression leftOperand, Token operator, Expression rightOperand) {
    return new LogicalExpression(
        leftOperand, operator.stringValue, rightOperand)
      ..fileOffset = offsetForToken(operator);
  }

  Expression createNot(Expression operand, Token token, bool isSynthetic) {
    return new Not(operand)..fileOffset = offsetForToken(token);
  }

  /// Return a representation of a parenthesized condition consisting of the
  /// given [expression] between the [leftParenthesis] and [rightParenthesis].
  Expression createParenthesizedCondition(
      Token leftParenthesis, Expression expression, Token rightParenthesis) {
    return expression;
  }

  /// Return a representation of a rethrow statement consisting of the
  /// [rethrowKeyword] followed by the [semicolon].
  Statement createRethrowStatement(Token rethrowKeyword, Token semicolon) {
    return new ExpressionStatement(
        new Rethrow()..fileOffset = offsetForToken(rethrowKeyword));
  }

  /// Return a representation of a return statement.
  Statement createReturnStatement(int fileOffset, Expression expression,
      {bool isArrow: true}) {
    return new ReturnStatementImpl(isArrow, expression)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  Expression createStringConcatenation(
      List<Expression> expressions, Token token) {
    return new StringConcatenation(expressions)
      ..fileOffset = offsetForToken(token);
  }

  /// The given [statement] is being used as the target of either a break or
  /// continue statement. Return the statement that should be used as the actual
  /// target.
  Statement createLabeledStatement(Statement statement) {
    return new LabeledStatement(statement);
  }

  Expression createThisExpression(int offset) {
    assert(offset != null);
    return new ThisExpression()..fileOffset = offset;
  }

  /// Return a representation of a throw expression consisting of the
  /// [throwKeyword].
  Expression createThrow(Token throwKeyword, Expression expression) {
    return new Throw(expression)..fileOffset = offsetForToken(throwKeyword);
  }

  bool isThrow(Object o) => o is Throw;

  /// Return a representation of a try statement. The statement is introduced by
  /// the [tryKeyword] and the given [body]. If catch clauses were included,
  /// then the [catchClauses] will represent them, otherwise it will be `null`.
  /// Similarly, if a finally block was included, then the [finallyKeyword] and
  /// [finallyBlock] will be non-`null`, otherwise both will be `null`. If there
  /// was an error in some part of the try statement, then an [errorReplacement]
  /// might be provided, in which case it could be returned instead of the
  /// representation of the try statement.
  Statement createTryStatement(Token tryKeyword, Statement body,
      List<Catch> catchClauses, Token finallyKeyword, Statement finallyBlock) {
    Statement result = body;
    if (catchClauses != null) {
      result = new TryCatch(result, catchClauses);
    }
    if (finallyBlock != null) {
      result = new TryFinally(result, finallyBlock);
    }
    return result;
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

  /// Return a representation of a while statement introduced by the
  /// [whileKeyword] and consisting of the given [condition] and [body].
  Statement createWhileStatement(
      Token whileKeyword, Expression condition, Statement body) {
    return new WhileStatement(condition, body)
      ..fileOffset = whileKeyword.charOffset;
  }

  /// Return a representation of a yield statement consisting of the
  /// [yieldKeyword], [star], [expression], and [semicolon]. The [star] is null
  /// when no star was included in the source code.
  Statement createYieldStatement(
      Token yieldKeyword, Token star, Expression expression, Token semicolon) {
    return new YieldStatement(expression, isYieldStar: star != null)
      ..fileOffset = yieldKeyword.charOffset;
  }

  /// Return the expression from the given expression [statement].
  Expression getExpressionFromExpressionStatement(Statement statement) {
    return (statement as ExpressionStatement).expression;
  }

  bool isBlock(Object node) => node is Block;

  /// Return `true` if the given [statement] is the representation of an empty
  /// statement.
  bool isEmptyStatement(Statement statement) => statement is EmptyStatement;

  bool isErroneousNode(Object node) {
    if (node is ExpressionStatement) {
      ExpressionStatement statement = node;
      node = statement.expression;
    }
    if (node is VariableDeclaration) {
      VariableDeclaration variable = node;
      node = variable.initializer;
    }
    if (node is SyntheticExpressionJudgment) {
      SyntheticExpressionJudgment synth = node;
      node = synth.desugared;
    }
    if (node is Let) {
      Let let = node;
      node = let.variable.initializer;
    }
    return node is InvalidExpression;
  }

  /// Return `true` if the given [statement] is the representation of an
  /// expression statement.
  bool isExpressionStatement(Statement statement) =>
      statement is ExpressionStatement;

  bool isThisExpression(Object node) => node is ThisExpression;

  bool isVariablesDeclaration(Object node) => node is _VariablesDeclaration;

  /// Creates [VariableDeclaration] for a variable named [name] at the given
  /// [functionNestingLevel].
  VariableDeclaration createVariableDeclaration(
      String name, int functionNestingLevel,
      {Expression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isCovariant: false,
      bool isLocalFunction: false}) {
    return new VariableDeclarationImpl(name, functionNestingLevel,
        type: type,
        initializer: initializer,
        isFinal: isFinal,
        isConst: isConst,
        isFieldFormal: isFieldFormal,
        isCovariant: isCovariant,
        isLocalFunction: isLocalFunction);
  }

  VariableDeclaration createVariableDeclarationForValue(
      int fileOffset, Expression initializer,
      {DartType type = const DynamicType()}) {
    return new VariableDeclarationImpl.forValue(initializer)
      ..type = type
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  Let createLet(VariableDeclaration variable, Expression body) {
    return new Let(variable, body);
  }

  FunctionNode createFunctionNode(Statement body,
      {List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      DartType returnType: const DynamicType(),
      AsyncMarker asyncMarker: AsyncMarker.Sync,
      AsyncMarker dartAsyncMarker}) {
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

  TypeParameterType createTypeParameterType(TypeParameter typeParameter) {
    return new TypeParameterType(typeParameter);
  }

  FunctionExpression createFunctionExpression(
      int fileOffset, FunctionNode function) {
    return new FunctionExpression(function)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  MethodInvocation createFunctionInvocation(
      int fileOffset, Expression expression, Arguments arguments) {
    return new MethodInvocationImpl(expression, callName, arguments)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
  }

  MethodInvocation createMethodInvocation(
      int fileOffset, Expression expression, Name name, Arguments arguments,
      {bool isImplicitCall: false, Member interfaceTarget}) {
    return new MethodInvocationImpl(expression, name, arguments,
        isImplicitCall: isImplicitCall)
      ..fileOffset = fileOffset ?? TreeNode.noOffset
      ..interfaceTarget = interfaceTarget;
  }

  NamedExpression createNamedExpression(String name, Expression expression) {
    return new NamedExpression(name, expression);
  }

  StaticInvocation createStaticInvocation(
      int fileOffset, Procedure procedure, Arguments arguments) {
    return new StaticInvocation(procedure, arguments)
      ..fileOffset = fileOffset ?? TreeNode.noOffset;
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
}
