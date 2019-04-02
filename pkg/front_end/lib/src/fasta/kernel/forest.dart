// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.forest;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Catch,
        DartType,
        Expression,
        LibraryDependency,
        MapEntry,
        Member,
        Name,
        NamedExpression,
        Procedure,
        Statement,
        TreeNode,
        VariableDeclaration;

import 'body_builder.dart' show LabelTarget;

import 'expression_generator.dart' show Generator, PrefixUseGenerator;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'kernel_builder.dart'
    show
        Identifier,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder,
        UnlinkedDeclaration;

import '../fasta_codes.dart' show Message;

import '../scanner.dart' show Token;

export '../fasta_codes.dart' show Message;

export 'body_builder.dart' show Operator;

export 'constness.dart' show Constness;

export 'expression_generator.dart' show Generator, PrefixUseGenerator;

export 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

export 'kernel_builder.dart'
    show
        Identifier,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder,
        UnlinkedDeclaration;

/// A tree factory.
abstract class Forest {
  const Forest();

  Arguments arguments(List<Expression> positional, Token location,
      {List<DartType> types, List<NamedExpression> named});

  Arguments argumentsEmpty(Token location);

  List<Object> argumentsNamed(Arguments arguments);

  List<Expression> argumentsPositional(Arguments arguments);

  List argumentsTypeArguments(Arguments arguments);

  void argumentsSetTypeArguments(Arguments arguments, List<DartType> types);

  Expression asLiteralString(Expression value);

  /// Return a representation of a boolean literal at the given [location]. The
  /// literal has the given [value].
  Expression literalBool(bool value, Token location);

  /// Return a representation of a double literal at the given [location]. The
  /// literal has the given [value].
  Expression literalDouble(double value, Token location);

  /// Return a representation of an integer literal at the given [location]. The
  /// literal has the given [value].
  Expression literalInt(int value, Token location);

  Expression literalLargeInt(String literal, Token location);

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
  Expression literalList(
      Token constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Token leftBracket,
      List<Expression> expressions,
      Token rightBracket);

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
  Expression literalSet(
      Token constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Token leftBrace,
      List<Expression> expressions,
      Token rightBrace);

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
  Expression literalMap(
      Token constKeyword,
      bool isConst,
      DartType keyType,
      DartType valueType,
      Object typeArguments,
      Token leftBrace,
      List<MapEntry> entries,
      Token rightBrace);

  /// Return a representation of a null literal at the given [location].
  Expression literalNull(Token location);

  /// Return a representation of a simple string literal at the given
  /// [location]. The literal has the given [value]. This does not include
  /// either adjacent strings or interpolated strings.
  Expression literalString(String value, Token location);

  /// Return a representation of a symbol literal defined by the [hash] and the
  /// list of [components]. The [value] is the string value of the symbol.
  Expression literalSymbolMultiple(
      String value, Token hash, List<Identifier> components);

  /// Return a representation of a symbol literal defined by the [hash] and the
  /// single [component]. The component can be either an [Identifier] or an
  /// [Operator]. The [value] is the string value of the symbol.
  Expression literalSymbolSingluar(String value, Token hash, Object component);

  Expression literalType(DartType type, Token location);

  /// Return a representation of a key/value pair in a literal map. The [key] is
  /// the representation of the expression used to compute the key. The [colon]
  /// is the location of the colon separating the key and the value. The [value]
  /// is the representation of the expression used to compute the value.
  Object mapEntry(Expression key, Token colon, Expression value);

  int readOffset(TreeNode node);

  Expression loadLibrary(LibraryDependency dependency, Arguments arguments);

  Expression checkLibraryIsLoaded(LibraryDependency dependency);

  Expression asExpression(Expression expression, DartType type, Token location);

  Expression spreadElement(Expression expression, Token token);

  Expression ifElement(
      Expression condition, Expression then, Expression otherwise, Token token);

  MapEntry ifMapEntry(
      Expression condition, MapEntry then, MapEntry otherwise, Token token);

  Expression forElement(
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      Expression body,
      Token token);

  MapEntry forMapEntry(
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      MapEntry body,
      Token token);

  Expression forInElement(VariableDeclaration variable, Expression iterable,
      Statement prologue, Expression body, Expression problem, Token token,
      {bool isAsync: false});

  MapEntry forInMapEntry(VariableDeclaration variable, Expression iterable,
      Statement prologue, MapEntry body, Expression problem, Token token,
      {bool isAsync: false});

  /// Return a representation of an assert that appears in a constructor's
  /// initializer list.
  Object assertInitializer(Token assertKeyword, Token leftParenthesis,
      Expression condition, Token comma, Expression message);

  /// Return a representation of an assert that appears as a statement.
  Statement assertStatement(Token assertKeyword, Token leftParenthesis,
      Expression condition, Token comma, Expression message, Token semicolon);

  Expression awaitExpression(Expression operand, Token location);

  /// Return a representation of a block of [statements] enclosed between the
  /// [openBracket] and [closeBracket].
  Statement block(
      Token openBrace, List<Statement> statements, Token closeBrace);

  /// Return a representation of a break statement.
  Statement breakStatement(
      Token breakKeyword, Identifier label, Token semicolon);

  /// Return a representation of a catch clause.
  Object catchClause(
      Token onKeyword,
      DartType exceptionType,
      Token catchKeyword,
      VariableDeclaration exceptionParameter,
      VariableDeclaration stackTraceParameter,
      DartType stackTraceType,
      Statement body);

  /// Return a representation of a conditional expression. The [condition] is
  /// the expression preceding the question mark. The [question] is the `?`. The
  /// [thenExpression] is the expression following the question mark. The
  /// [colon] is the `:`. The [elseExpression] is the expression following the
  /// colon.
  Expression conditionalExpression(Expression condition, Token question,
      Expression thenExpression, Token colon, Expression elseExpression);

  /// Return a representation of a continue statement.
  Statement continueStatement(
      Token continueKeyword, Identifier label, Token semicolon);

  /// Return a representation of a do statement.
  Statement doStatement(Token doKeyword, Statement body, Token whileKeyword,
      Expression condition, Token semicolon);

  /// Return a representation of an expression statement composed from the
  /// [expression] and [semicolon].
  Statement expressionStatement(Expression expression, Token semicolon);

  /// Return a representation of an empty statement consisting of the given
  /// [semicolon].
  Statement emptyStatement(Token semicolon);

  /// Return a representation of a for statement.
  Statement forStatement(
      Token forKeyword,
      Token leftParenthesis,
      List<VariableDeclaration> variables,
      Token leftSeparator,
      Expression condition,
      Statement conditionStatement,
      List<Expression> updaters,
      Token rightParenthesis,
      Statement body);

  /// Return a representation of an `if` statement.
  Statement ifStatement(Token ifKeyword, Expression condition,
      Statement thenStatement, Token elseKeyword, Statement elseStatement);

  /// Return a representation of an `is` expression. The [operand] is the
  /// representation of the left operand. The [isOperator] is the `is` operator.
  /// The [notOperator] is either the `!` or `null` if the test is not negated.
  /// The [type] is a representation of the type that is the right operand.
  Expression isExpression(
      Expression operand, Token isOperator, Token notOperator, DartType type);

  /// Return a representation of a [statement] that has one or more labels (from
  /// the [target]) associated with it.
  Statement labeledStatement(LabelTarget target, Statement statement);

  /// Return a representation of a logical expression having the [leftOperand],
  /// [rightOperand] and the [operator] (either `&&` or `||`).
  Expression logicalExpression(
      Expression leftOperand, Token operator, Expression rightOperand);

  Expression notExpression(
      Expression operand, Token location, bool isSynthetic);

  /// Return a representation of a parenthesized condition consisting of the
  /// given [expression] between the [leftParenthesis] and [rightParenthesis].
  Object parenthesizedCondition(
      Token leftParenthesis, Expression expression, Token rightParenthesis);

  /// Return a representation of a rethrow statement consisting of the
  /// [rethrowKeyword] followed by the [semicolon].
  Statement rethrowStatement(Token rethrowKeyword, Token semicolon);

  /// Return a representation of a return statement.
  Statement returnStatement(
      Token returnKeyword, Expression expression, Token semicolon);

  Expression stringConcatenationExpression(
      List<Expression> expressions, Token location);

  /// The given [statement] is being used as the target of either a break or
  /// continue statement. Return the statement that should be used as the actual
  /// target.
  Statement syntheticLabeledStatement(Statement statement);

  Expression thisExpression(Token location);

  /// Return a representation of a throw expression consisting of the
  /// [throwKeyword].
  Expression throwExpression(Token throwKeyword, Expression expression);

  bool isThrow(Object o);

  /// Return a representation of a try statement. The statement is introduced by
  /// the [tryKeyword] and the given [body]. If catch clauses were included,
  /// then the [catchClauses] will represent them, otherwise it will be `null`.
  /// Similarly, if a finally block was included, then the [finallyKeyword] and
  /// [finallyBlock] will be non-`null`, otherwise both will be `null`. If there
  /// was an error in some part of the try statement, then an [errorReplacement]
  /// might be provided, in which case it could be returned instead of the
  /// representation of the try statement.
  Statement tryStatement(Token tryKeyword, Statement body,
      List<Catch> catchClauses, Token finallyKeyword, Statement finallyBlock);

  Statement variablesDeclaration(
      List<VariableDeclaration> declarations, Uri uri);

  List<VariableDeclaration> variablesDeclarationExtractDeclarations(
      covariant Statement variablesDeclaration);

  Statement wrapVariables(Statement statement);

  /// Return a representation of a while statement introduced by the
  /// [whileKeyword] and consisting of the given [condition] and [body].
  Statement whileStatement(
      Token whileKeyword, Expression condition, Statement body);

  /// Return a representation of a yield statement consisting of the
  /// [yieldKeyword], [star], [expression], and [semicolon]. The [star] is null
  /// when no star was included in the source code.
  Statement yieldStatement(
      Token yieldKeyword, Token star, Expression expression, Token semicolon);

  /// Return the expression from the given expression [statement].
  Expression getExpressionFromExpressionStatement(Statement statement);

  bool isBlock(Object node);

  /// Return `true` if the given [statement] is the representation of an empty
  /// statement.
  bool isEmptyStatement(Statement statement);

  bool isErroneousNode(Object node);

  /// Return `true` if the given [statement] is the representation of an
  /// expression statement.
  bool isExpressionStatement(Statement statement);

  bool isThisExpression(Object node);

  bool isVariablesDeclaration(Object node);

  Generator variableUseGenerator(ExpressionGeneratorHelper helper,
      Token location, VariableDeclaration variable, DartType promotedType);

  Generator propertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token location,
      Expression receiver,
      Name name,
      Member getter,
      Member setter);

  Generator thisPropertyAccessGenerator(ExpressionGeneratorHelper helper,
      Token location, Name name, Member getter, Member setter);

  Generator nullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token location,
      Expression receiverExpression,
      Name name,
      Member getter,
      Member setter,
      DartType type);

  Generator superPropertyAccessGenerator(ExpressionGeneratorHelper helper,
      Token location, Name name, Member getter, Member setter);

  Generator indexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token location,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter);

  Generator thisIndexedAccessGenerator(ExpressionGeneratorHelper helper,
      Token location, Expression index, Procedure getter, Procedure setter);

  Generator superIndexedAccessGenerator(ExpressionGeneratorHelper helper,
      Token location, Expression index, Member getter, Member setter);

  Generator staticAccessGenerator(ExpressionGeneratorHelper helper,
      Token location, Member getter, Member setter);

  Generator loadLibraryGenerator(ExpressionGeneratorHelper helper,
      Token location, LoadLibraryBuilder builder);

  Generator deferredAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token location,
      PrefixUseGenerator prefixGenerator,
      Generator suffixGenerator);

  Generator typeUseGenerator(ExpressionGeneratorHelper helper, Token location,
      TypeDeclarationBuilder declaration, String plainNameForRead);

  Generator readOnlyAccessGenerator(ExpressionGeneratorHelper helper,
      Token location, Expression expression, String plainNameForRead);

  Generator unresolvedNameGenerator(
      ExpressionGeneratorHelper helper, Token location, Name name);

  Generator unlinkedGenerator(ExpressionGeneratorHelper helper, Token location,
      UnlinkedDeclaration declaration);

  Generator delayedAssignment(ExpressionGeneratorHelper helper, Token location,
      Generator generator, Expression value, String assignmentOperator);

  Generator delayedPostfixIncrement(
      ExpressionGeneratorHelper helper,
      Token location,
      Generator generator,
      Name binaryOperator,
      Procedure interfaceTarget);

  Generator prefixUseGenerator(
      ExpressionGeneratorHelper helper, Token location, PrefixBuilder prefix);

  Generator unexpectedQualifiedUseGenerator(ExpressionGeneratorHelper helper,
      Token token, Generator prefixGenerator, bool isUnresolved);

  Generator parserErrorGenerator(
      ExpressionGeneratorHelper helper, Token token, Message message);

  // TODO(ahe): Remove this method when all users are moved here.
  Arguments castArguments(Arguments arguments) {
    return arguments;
  }
}
