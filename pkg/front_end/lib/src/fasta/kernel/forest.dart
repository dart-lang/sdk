// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.forest;

import 'package:kernel/ast.dart' as kernel
    show
        Arguments, // TODO(ahe): Remove this import.
        DartType,
        Member,
        Name,
        Procedure;

import 'body_builder.dart' show Identifier, LabelTarget;

import 'expression_generator.dart' show Generator;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'kernel_builder.dart'
    show LoadLibraryBuilder, PrefixBuilder, TypeDeclarationBuilder;

export 'body_builder.dart' show Identifier, Operator;

export 'expression_generator.dart' show Generator;

export 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

export 'kernel_builder.dart'
    show LoadLibraryBuilder, PrefixBuilder, TypeDeclarationBuilder;

/// A tree factory.
///
/// For now, the [Location] is always a token.
abstract class Forest<Expression, Statement, Location, Arguments> {
  const Forest();

  Arguments arguments(List<Expression> positional, Location location,
      {covariant List types, covariant List named});

  Arguments argumentsEmpty(Location location);

  List argumentsNamed(Arguments arguments);

  List<Expression> argumentsPositional(Arguments arguments);

  List argumentsTypeArguments(Arguments arguments);

  void argumentsSetTypeArguments(Arguments arguments, covariant List types);

  Expression asLiteralString(Expression value);

  /// Return a representation of a boolean literal at the given [location]. The
  /// literal has the given [value].
  Expression literalBool(bool value, Location location);

  /// Return a representation of a double literal at the given [location]. The
  /// literal has the given [value].
  Expression literalDouble(double value, Location location);

  /// Return a representation of an integer literal at the given [location]. The
  /// literal has the given [value].
  Expression literalInt(int value, Location location);

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
      Location constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Location leftBracket,
      List<Expression> expressions,
      Location rightBracket);

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
  /// `null` if there are no type arguments. The [leftBracket] is the location
  /// of the `{`. The list of [entries] is a list of the representations of the
  /// map entries. The [rightBracket] is the location of the `}`.
  Expression literalMap(
      Location constKeyword,
      bool isConst,
      covariant keyType,
      covariant valueType,
      Object typeArguments,
      Location leftBracket,
      covariant List entries,
      Location rightBracket);

  /// Return a representation of a null literal at the given [location].
  Expression literalNull(Location location);

  /// Return a representation of a simple string literal at the given
  /// [location]. The literal has the given [value]. This does not include
  /// either adjacent strings or interpolated strings.
  Expression literalString(String value, Location location);

  /// Return a representation of a symbol literal defined by the [hash] and the
  /// list of [components]. The [value] is the string value of the symbol.
  Expression literalSymbolMultiple(
      String value, Location hash, List<Identifier> components);

  /// Return a representation of a symbol literal defined by the [hash] and the
  /// single [component]. The component can be either an [Identifier] or an
  /// [Operator]. The [value] is the string value of the symbol.
  Expression literalSymbolSingluar(
      String value, Location hash, Object component);

  Expression literalType(covariant type, Location location);

  /// Return a representation of a key/value pair in a literal map. The [key] is
  /// the representation of the expression used to compute the key. The [colon]
  /// is the location of the colon separating the key and the value. The [value]
  /// is the representation of the expression used to compute the value.
  Object mapEntry(Expression key, Location colon, Expression value);

  /// Return a list that can hold [length] representations of map entries, as
  /// returned from [mapEntry].
  List mapEntryList(int length);

  int readOffset(covariant node);

  /// Given a representation of a list of [typeArguments], return the number of
  /// type arguments in the list.
  int getTypeCount(covariant typeArguments);

  /// Given a representation of a list of [typeArguments], return the type
  /// associated with the argument at the given [index].
  kernel.DartType getTypeAt(covariant typeArguments, int index);

  Expression loadLibrary(covariant dependency);

  Expression checkLibraryIsLoaded(covariant dependency);

  Expression asExpression(
      Expression expression, covariant type, Location location);

  /// Return a representation of an assert that appears in a constructor's
  /// initializer list.
  Object assertInitializer(Location assertKeyword, Location leftParenthesis,
      Expression condition, Location comma, Expression message);

  /// Return a representation of an assert that appears as a statement.
  Statement assertStatement(
      Location assertKeyword,
      Location leftParenthesis,
      Expression condition,
      Location comma,
      Expression message,
      Location semicolon);

  Expression awaitExpression(Expression operand, Location location);

  /// Return a representation of a block of [statements] enclosed between the
  /// [openBracket] and [closeBracket].
  Statement block(
      Location openBrace, List<Statement> statements, Location closeBrace);

  /// Return a representation of a break statement.
  Statement breakStatement(
      Location breakKeyword, Identifier label, Location semicolon);

  /// Return a representation of a catch clause.
  Object catchClause(
      Location onKeyword,
      covariant exceptionType,
      Location catchKeyword,
      covariant exceptionParameter,
      covariant stackTraceParameter,
      covariant stackTraceType,
      Statement body);

  /// Return a representation of a conditional expression. The [condition] is
  /// the expression preceding the question mark. The [question] is the `?`. The
  /// [thenExpression] is the expression following the question mark. The
  /// [colon] is the `:`. The [elseExpression] is the expression following the
  /// colon.
  Expression conditionalExpression(Expression condition, Location question,
      Expression thenExpression, Location colon, Expression elseExpression);

  /// Return a representation of a continue statement.
  Statement continueStatement(
      Location continueKeyword, Identifier label, Location semicolon);

  /// Return a representation of a do statement.
  Statement doStatement(
      Location doKeyword,
      Statement body,
      Location whileKeyword,
      covariant Expression condition,
      Location semicolon);

  /// Return a representation of an expression statement composed from the
  /// [expression] and [semicolon].
  Statement expressionStatement(Expression expression, Location semicolon);

  /// Return a representation of an empty statement consisting of the given
  /// [semicolon].
  Statement emptyStatement(Location semicolon);

  /// Return a representation of a for statement.
  Statement forStatement(
      Location forKeyword,
      Location leftParenthesis,
      covariant variableList,
      covariant initialization,
      Location leftSeparator,
      Expression condition,
      Statement conditionStatement,
      List<Expression> updaters,
      Location rightParenthesis,
      Statement body);

  /// Return a representation of an `if` statement.
  Statement ifStatement(Location ifKeyword, covariant Expression condition,
      Statement thenStatement, Location elseKeyword, Statement elseStatement);

  /// Return a representation of an `is` expression. The [operand] is the
  /// representation of the left operand. The [isOperator] is the `is` operator.
  /// The [notOperator] is either the `!` or `null` if the test is not negated.
  /// The [type] is a representation of the type that is the right operand.
  Expression isExpression(Expression operand, Location isOperator,
      Location notOperator, covariant type);

  /// Return a representation of the label consisting of the given [identifer]
  /// followed by the given [colon].
  Object label(Location identifier, Location colon);

  /// Return a representation of a [statement] that has one or more labels (from
  /// the [target]) associated with it.
  Statement labeledStatement(
      LabelTarget<Statement> target, Statement statement);

  /// Return a representation of a logical expression having the [leftOperand],
  /// [rightOperand] and the [operator] (either `&&` or `||`).
  Expression logicalExpression(
      Expression leftOperand, Location operator, Expression rightOperand);

  Expression notExpression(Expression operand, Location location);

  /// Return a representation of a parenthesized condition consisting of the
  /// given [expression] between the [leftParenthesis] and [rightParenthesis].
  Object parenthesizedCondition(Location leftParenthesis, Expression expression,
      Location rightParenthesis);

  /// Return a representation of a rethrow statement consisting of the
  /// [rethrowKeyword] followed by the [semicolon].
  Statement rethrowStatement(Location rethrowKeyword, Location semicolon);

  /// Return a representation of a return statement.
  Statement returnStatement(
      Location returnKeyword, Expression expression, Location semicolon);

  Expression stringConcatenationExpression(
      List<Expression> expressions, Location location);

  /// The given [statement] is being used as the target of either a break or
  /// continue statement. Return the statement that should be used as the actual
  /// target.
  Statement syntheticLabeledStatement(Statement statement);

  Expression thisExpression(Location location);

  /// Return a representation of a throw expression consisting of the
  /// [throwKeyword].
  Expression throwExpression(Location throwKeyword, Expression expression);

  /// Return a representation of a try statement. The statement is introduced by
  /// the [tryKeyword] and the given [body]. If catch clauses were included,
  /// then the [catchClauses] will represent them, otherwise it will be `null`.
  /// Similarly, if a finally block was included, then the [finallyKeyword] and
  /// [finallyBlock] will be non-`null`, otherwise both will be `null`. If there
  /// was an error in some part of the try statement, then an [errorReplacement]
  /// might be provided, in which case it could be returned instead of the
  /// representation of the try statement.
  Statement tryStatement(Location tryKeyword, Statement body,
      covariant catchClauses, Location finallyKeyword, Statement finallyBlock);

  Statement variablesDeclaration(covariant List declarations, Uri uri);

  Object variablesDeclarationExtractDeclarations(
      covariant Statement variablesDeclaration);

  Statement wrapVariables(Statement statement);

  /// Return a representation of a while statement introduced by the
  /// [whileKeyword] and consisting of the given [condition] and [body].
  Statement whileStatement(
      Location whileKeyword, covariant Expression condition, Statement body);

  /// Return a representation of a yield statement consisting of the
  /// [yieldKeyword], [star], [expression], and [semicolon]. The [star] is null
  /// when no star was included in the source code.
  Statement yieldStatement(Location yieldKeyword, Location star,
      Expression expression, Location semicolon);

  /// Return the expression from the given expression [statement].
  Expression getExpressionFromExpressionStatement(Statement statement);

  /// Return the name of the given [label].
  String getLabelName(covariant label);

  /// Return the offset of the given [label].
  int getLabelOffset(covariant label);

  /// Return the name of the given variable [declaration].
  String getVariableDeclarationName(covariant declaration);

  bool isBlock(Object node);

  /// Return `true` if the given [statement] is the representation of an empty
  /// statement.
  bool isEmptyStatement(Statement statement);

  bool isErroneousNode(Object node);

  /// Return `true` if the given [statement] is the representation of an
  /// expression statement.
  bool isExpressionStatement(Statement statement);

  /// Return `true` if the given [node] is a label.
  bool isLabel(covariant node);

  bool isThisExpression(Object node);

  bool isVariablesDeclaration(Object node);

  /// Record that the [user] (a break statement) is associated with the [target]
  /// statement.
  void resolveBreak(covariant Statement target, covariant Statement user);

  /// Record that the [user] (a continue statement) is associated with the
  /// [target] statement.
  void resolveContinue(covariant Statement target, covariant Statement user);

  /// Record that the [user] (a continue statement inside a switch case) is
  /// associated with the [target] statement.
  void resolveContinueInSwitch(
      covariant Object target, covariant Statement user);

  /// Set the type of the [parameter] to the given [type].
  void setParameterType(covariant parameter, covariant type);

  Generator<Expression, Statement, Arguments> variableUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      covariant variable,
      kernel.DartType promotedType);

  Generator<Expression, Statement, Arguments> propertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      Expression receiver,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter);

  Generator<Expression, Statement, Arguments> thisPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter);

  Generator<Expression, Statement, Arguments> nullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      Expression receiverExpression,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter,
      kernel.DartType type);

  Generator<Expression, Statement, Arguments> superPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter);

  Generator<Expression, Statement, Arguments> indexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      Expression receiver,
      Expression index,
      kernel.Procedure getter,
      kernel.Procedure setter);

  Generator<Expression, Statement, Arguments> thisIndexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      Expression index,
      kernel.Procedure getter,
      kernel.Procedure setter);

  Generator<Expression, Statement, Arguments> superIndexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      Expression index,
      kernel.Member getter,
      kernel.Member setter);

  Generator<Expression, Statement, Arguments> staticAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      kernel.Member getter,
      kernel.Member setter);

  Generator<Expression, Statement, Arguments> loadLibraryGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      LoadLibraryBuilder builder);

  Generator<Expression, Statement, Arguments> deferredAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      PrefixBuilder builder,
      Generator<Expression, Statement, Arguments> generator);

  Generator<Expression, Statement, Arguments> typeUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      PrefixBuilder prefix,
      int declarationReferenceOffset,
      TypeDeclarationBuilder declaration,
      String plainNameForRead);

  Generator<Expression, Statement, Arguments> readOnlyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      Expression expression,
      String plainNameForRead);

  Generator<Expression, Statement, Arguments> largeIntAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location);

  Generator<Expression, Statement, Arguments> unresolvedNameGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Location location,
      kernel.Name name);

  // TODO(ahe): Remove this method when all users are moved here.
  kernel.Arguments castArguments(Arguments arguments) {
    dynamic a = arguments;
    return a;
  }
}
