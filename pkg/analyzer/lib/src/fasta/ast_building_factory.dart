// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' hide Identifier;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/fasta/analyzer_expression_generator.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:front_end/src/fasta/kernel/body_builder.dart' show LabelTarget;
import 'package:front_end/src/fasta/kernel/forest.dart';
import 'package:kernel/ast.dart' as kernel;

/// A data holder used to conform to the [Forest] API.
class Arguments {
  List<TypeAnnotation> typeArguments = <TypeAnnotation>[];
  List<Expression> positionalArguments = <Expression>[];
  List<Expression> namedArguments = <Expression>[];
}

/// An implementation of a [Forest] that can be used to build an AST structure.
class AstBuildingForest
    implements Forest<Expression, Statement, Token, Arguments> {
  /// The type provider used to resolve the types of literal nodes, or `null` if
  /// type resolution is not being performed.
  final TypeProvider _typeProvider;

  /// The factory used to create AST nodes.
  AstFactoryImpl astFactory = new AstFactoryImpl();

  /// Initialize a newly created AST-building forest.
  AstBuildingForest(this._typeProvider);

  @override
  Arguments arguments(List<Expression> positional, Token location,
      {covariant List types, covariant List named}) {
    Arguments arguments = new Arguments();
    if (types != null) {
      arguments.typeArguments = types.cast<TypeAnnotation>();
    }
    arguments.positionalArguments = positional.cast<Expression>();
    if (named != null) {
      arguments.namedArguments = named.cast<Expression>();
    }
    return arguments;
  }

  @override
  Arguments argumentsEmpty(Token location) => new Arguments();

  @override
  List argumentsNamed(Arguments arguments) => arguments.namedArguments;

  @override
  List<Expression> argumentsPositional(Arguments arguments) =>
      arguments.positionalArguments;

  @override
  void argumentsSetTypeArguments(Arguments arguments, covariant List types) {
    arguments.typeArguments = types.cast<TypeAnnotation>();
  }

  @override
  List argumentsTypeArguments(Arguments arguments) => arguments.typeArguments;

  @override
  Expression asExpression(Expression expression, type, Token location) =>
      astFactory.asExpression(expression, location, type);

  @override
  Expression asLiteralString(Expression value) => value;

  @override
  ConstructorInitializer assertInitializer(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token comma,
          Expression message) =>
      astFactory.assertInitializer(assertKeyword, leftParenthesis, condition,
          comma, message, leftParenthesis.endGroup);

  @override
  Statement assertStatement(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token comma,
          Expression message,
          Token semicolon) =>
      astFactory.assertStatement(assertKeyword, leftParenthesis, condition,
          comma, message, leftParenthesis.endGroup, semicolon);

  @override
  Expression awaitExpression(Expression operand, Token awaitKeyword) =>
      astFactory.awaitExpression(awaitKeyword, operand);

  @override
  Block block(Token openBrace, List<Statement> statements, Token closeBrace) =>
      astFactory.block(openBrace, statements, closeBrace);

  @override
  Statement breakStatement(
          Token breakKeyword, Identifier label, Token semicolon) =>
      astFactory.breakStatement(
          breakKeyword,
          label == null ? null : astFactory.simpleIdentifier(label.token),
          semicolon);

  @override
  kernel.Arguments castArguments(Arguments arguments) {
    // TODO(brianwilkerson) Implement this or remove it from the API.
    throw new UnimplementedError();
  }

  @override
  CatchClause catchClause(
      Token onKeyword,
      TypeAnnotation exceptionType,
      Token catchKeyword,
      SimpleIdentifier exceptionParameter,
      SimpleIdentifier stackTraceParameter,
      TypeAnnotation stackTraceType,
      Statement body) {
    // TODO(brianwilkerson) The following is not reliable in the presence of
    // recovery. Consider passing the required tokens from the Parser to the
    // BodyBuilder to here.
    Token leftParenthesis;
    if (catchKeyword != null) {
      leftParenthesis = catchKeyword.next;
    }
    Token comma;
    if (stackTraceParameter != null) {
      comma = exceptionParameter.endToken.next;
    }
    Token rightParenthesis;
    if (catchKeyword != null) {
      if (stackTraceParameter != null) {
        rightParenthesis = stackTraceParameter.endToken.next;
      } else if (comma != null) {
        rightParenthesis = comma.next;
      } else {
        rightParenthesis = exceptionParameter.endToken.next;
      }
    }
    return astFactory.catchClause(
        onKeyword,
        exceptionType,
        catchKeyword,
        leftParenthesis,
        exceptionParameter,
        comma,
        stackTraceParameter,
        rightParenthesis,
        body);
  }

  @override
  Expression checkLibraryIsLoaded(dependency) {
    // TODO(brianwilkerson) Implement this.
    throw new UnimplementedError();
  }

  @override
  Expression conditionalExpression(Expression condition, Token question,
          Expression thenExpression, Token colon, Expression elseExpression) =>
      astFactory.conditionalExpression(
          condition, question, thenExpression, colon, elseExpression);

  @override
  Statement continueStatement(
          Token continueKeyword, Identifier label, Token semicolon) =>
      astFactory.continueStatement(
          continueKeyword,
          label == null ? null : astFactory.simpleIdentifier(label.token),
          semicolon);

  @override
  Generator<Expression, Statement, Arguments> deferredAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      PrefixBuilder builder,
      Generator<Expression, Statement, Arguments> generator) {
    return new AnalyzerDeferredAccessGenerator(
        helper, astFactory, token, builder, generator);
  }

  @override
  Statement doStatement(Token doKeyword, Statement body, Token whileKeyword,
          ParenthesizedExpression condition, Token semicolon) =>
      astFactory.doStatement(
          doKeyword,
          body,
          whileKeyword,
          condition.leftParenthesis,
          condition.expression,
          condition.rightParenthesis,
          semicolon);

  @override
  Statement emptyStatement(Token semicolon) =>
      astFactory.emptyStatement(semicolon);

  @override
  Statement expressionStatement(Expression expression, Token semicolon) =>
      astFactory.expressionStatement(expression, semicolon);

  @override
  Statement forStatement(
          Token forKeyword,
          Token leftParenthesis,
          covariant variableList,
          covariant initialization,
          Token leftSeparator,
          Expression condition,
          Statement conditionStatement,
          List<Expression> updaters,
          Token rightParenthesis,
          Statement body) =>
      astFactory.forStatement(
          forKeyword,
          leftParenthesis,
          variableList,
          initialization,
          leftSeparator,
          condition,
          getSemicolon(conditionStatement),
          updaters,
          rightParenthesis,
          body);

  @override
  Expression getExpressionFromExpressionStatement(Statement statement) =>
      (statement as ExpressionStatement).expression;

  String getLabelName(Label label) => label.label.name;

  @override
  int getLabelOffset(Label label) => label.offset;

  /// Return the semicolon at the end of the given [statement], or `null` if the
  /// statement is not terminated by a semicolon.
  Token getSemicolon(Statement statement) {
    if (statement is ExpressionStatement) {
      return statement.semicolon;
    }
    if (statement is EmptyStatement) {
      return statement.semicolon;
    }
    return null;
  }

  @override
  kernel.DartType getTypeAt(TypeArgumentList typeArguments, int index) {
    return null; // typeArguments.arguments[index].type.kernelType;
  }

  @override
  int getTypeCount(TypeArgumentList typeArguments) =>
      typeArguments.arguments.length;

  @override
  String getVariableDeclarationName(VariableDeclaration declaration) {
    return declaration.name.name;
  }

  @override
  Statement ifStatement(
          Token ifKeyword,
          ParenthesizedExpression condition,
          Statement thenStatement,
          Token elseKeyword,
          Statement elseStatement) =>
      astFactory.ifStatement(
          ifKeyword,
          condition.leftParenthesis,
          condition.expression,
          condition.rightParenthesis,
          thenStatement,
          elseKeyword,
          elseStatement);

  @override
  Generator<Expression, Statement, Arguments> indexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression receiver,
      Expression index,
      kernel.Procedure getter,
      kernel.Procedure setter) {
    return new AnalyzerIndexedAccessGenerator(
        helper, astFactory, receiver, token, index, token.endGroup);
  }

  @override
  bool isBlock(Object node) => node is Block;

  @override
  bool isEmptyStatement(Statement statement) => statement is EmptyStatement;

  @override
  bool isErroneousNode(Object node) => false /* ??? */;

  @override
  Expression isExpression(Expression expression, Token isOperator,
          Token notOperator, Object type) =>
      astFactory.isExpression(expression, isOperator, notOperator, type);

  @override
  bool isExpressionStatement(Statement statement) =>
      statement is ExpressionStatement;

  @override
  bool isLabel(covariant node) => node is Label;

  @override
  bool isThisExpression(Object node) => node is ThisExpression;

  @override
  bool isVariablesDeclaration(Object node) =>
      node is VariableDeclarationStatement && node.variables != 1;

  @override
  Label label(Token identifier, Token colon) => astFactory.label(
      astFactory.simpleIdentifier(identifier, isDeclaration: true), colon);

  @override
  Statement labeledStatement(
          LabelTarget<Statement> target, Statement statement) =>
      astFactory.labeledStatement(target.labels.cast<Label>(), statement);

  @override
  Generator<Expression, Statement, Arguments> largeIntAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token) {
    return new AnalyzerLargeIntAccessGenerator(helper, astFactory, token);
  }

  @override
  Expression literalBool(bool value, Token location) =>
      astFactory.booleanLiteral(location, value)
        ..staticType = _typeProvider?.boolType;

  @override
  Expression literalDouble(double value, Token location) =>
      astFactory.doubleLiteral(location, value)
        ..staticType = _typeProvider?.doubleType;

  @override
  Expression literalInt(int value, Token location) =>
      astFactory.integerLiteral(location, value)
        ..staticType = _typeProvider?.intType;

  @override
  Expression literalList(
          Token constKeyword,
          bool isConst,
          Object typeArgument,
          Object typeArguments,
          Token leftBracket,
          List<Expression> expressions,
          Token rightBracket) =>
      astFactory.listLiteral(
          constKeyword, typeArguments, leftBracket, expressions, rightBracket);

  @override
  Expression literalMap(
          Token constKeyword,
          bool isConst,
          covariant keyType,
          covariant valueType,
          Object typeArguments,
          Token leftBracket,
          covariant List entries,
          Token rightBracket) =>
      astFactory.mapLiteral(
          constKeyword, typeArguments, leftBracket, entries, rightBracket);

  @override
  Expression literalNull(Token location) =>
      astFactory.nullLiteral(location)..staticType = _typeProvider?.nullType;

  @override
  Expression literalString(String value, Token location) =>
      astFactory.simpleStringLiteral(location, value)
        ..staticType = _typeProvider?.stringType;

  @override
  Expression literalSymbolMultiple(
          String value, Token hash, List<Identifier> components) =>
      astFactory.symbolLiteral(
          hash, components.map((identifier) => identifier.token).toList())
        ..staticType = _typeProvider?.symbolType;

  @override
  Expression literalSymbolSingluar(String value, Token hash, Object component) {
    Token token;
    if (component is Identifier) {
      token = component.token;
    } else if (component is Operator) {
      token = component.token;
    } else {
      throw new ArgumentError(
          'Unexpected class of component: ${component.runtimeType}');
    }
    return astFactory.symbolLiteral(hash, <Token>[token])
      ..staticType = _typeProvider?.symbolType;
  }

  @override
  Expression literalType(covariant type, Token location) {
    // TODO(brianwilkerson) Capture the type information.
    return astFactory.simpleIdentifier(location)
      ..staticType = _typeProvider?.typeType;
  }

  @override
  Expression loadLibrary(dependency) {
    // TODO(brianwilkerson) Implement this.
    throw new UnimplementedError();
  }

  @override
  Generator<Expression, Statement, Arguments> loadLibraryGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      LoadLibraryBuilder builder) {
    return new AnalyzerLoadLibraryGenerator(helper, astFactory, token, builder);
  }

  @override
  Expression logicalExpression(
          Expression leftOperand, Token operator, Expression rightOperand) =>
      astFactory.binaryExpression(leftOperand, operator, rightOperand);

  @override
  Object mapEntry(Expression key, Token colon, Expression value) =>
      astFactory.mapLiteralEntry(key, colon, value);

  @override
  List mapEntryList(int length) => new List<MapLiteralEntry>(length);

  @override
  Expression notExpression(Expression operand, Token operator) =>
      astFactory.prefixExpression(operator, operand)
        ..staticType = _typeProvider?.boolType;

  @override
  Generator<Expression, Statement, Arguments> nullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression receiverExpression,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter,
      kernel.DartType type) {
    return new AnalyzerNullAwarePropertyAccessGenerator(
        helper, astFactory, receiverExpression, token, null /*name*/);
  }

  @override
  Object parenthesizedCondition(Token leftParenthesis, Expression expression,
          Token rightParenthesis) =>
      astFactory.parenthesizedExpression(
          leftParenthesis, expression, rightParenthesis);

  @override
  Generator<Expression, Statement, Arguments> propertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression receiver,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter) {
    return new AnalyzerPropertyAccessGenerator(
        helper, astFactory, token, receiver, name, getter, setter);
  }

  @override
  int readOffset(AstNode node) => node.offset;

  @override
  Generator<Expression, Statement, Arguments> readOnlyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression expression,
      String plainNameForRead) {
    return new AnalyzerReadOnlyAccessGenerator(
        helper, astFactory, token, expression, plainNameForRead);
  }

  @override
  void resolveBreak(Statement target, BreakStatement user) {
    user.target = target;
  }

  @override
  void resolveContinue(Statement target, ContinueStatement user) {
    user.target = target;
  }

  @override
  void resolveContinueInSwitch(SwitchStatement target, ContinueStatement user) {
    user.target = target;
  }

  @override
  Statement rethrowStatement(Token rethrowKeyword, Token semicolon) =>
      astFactory.expressionStatement(
          astFactory.rethrowExpression(rethrowKeyword), semicolon);

  @override
  Statement returnStatement(
          Token returnKeyword, Expression expression, Token semicolon) =>
      astFactory.returnStatement(returnKeyword, expression, semicolon);

  @override
  void setParameterType(FormalParameter parameter, TypeAnnotation type) {
    parameter.identifier.staticType = type.type;
  }

  @override
  Generator<Expression, Statement, Arguments> staticAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      kernel.Member getter,
      kernel.Member setter) {
    return new AnalyzerStaticAccessGenerator(
        helper, astFactory, token, getter, setter);
  }

  @override
  Expression stringConcatenationExpression(
          List<Expression> strings, Token location) =>
      astFactory.adjacentStrings(strings.cast<StringLiteral>());

  @override
  Generator<Expression, Statement, Arguments> superIndexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression index,
      kernel.Member getter,
      kernel.Member setter) {
    // TODO(brianwilkerson) Figure out how to get the token for `super`.
    return new AnalyzerIndexedAccessGenerator(
        helper, astFactory, null, token, index, token.endGroup);
  }

  @override
  Generator<Expression, Statement, Arguments> superPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter) {
    // TODO(brianwilkerson) Figure out how to get the token for the name.
    return new AnalyzerSuperPropertyAccessGenerator(
        helper, astFactory, null, null, null /*name*/);
  }

  @override
  Statement syntheticLabeledStatement(Statement statement) => statement;

  @override
  Expression thisExpression(Token thisKeyword) =>
      astFactory.thisExpression(thisKeyword);

  @override
  Generator<Expression, Statement, Arguments> thisIndexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression index,
      kernel.Procedure getter,
      kernel.Procedure setter) {
    // TODO(brianwilkerson) Figure out how to get the token for `this`.
    return new AnalyzerIndexedAccessGenerator(
        helper, astFactory, null, token, index, token.endGroup);
  }

  @override
  Generator<Expression, Statement, Arguments> thisPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token location,
      kernel.Name name,
      kernel.Member getter,
      kernel.Member setter) {
    // TODO(brianwilkerson) Figure out how to get the token for the name.
    return new AnalyzerThisPropertyAccessGenerator(
        helper, astFactory, location, name, getter, setter);
  }

  @override
  Expression throwExpression(Token throwKeyword, Expression expression) =>
      astFactory.throwExpression(throwKeyword, expression);

  @override
  Statement tryStatement(
          Token tryKeyword,
          Statement body,
          List<CatchClause> catchClauses,
          Token finallyKeyword,
          Statement finallyBlock) =>
      astFactory.tryStatement(
          tryKeyword, body, catchClauses, finallyKeyword, finallyBlock);

  @override
  Generator<Expression, Statement, Arguments> typeUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      PrefixBuilder prefix,
      int declarationReferenceOffset,
      TypeDeclarationBuilder declaration,
      String plainNameForRead) {
    return new AnalyzerTypeUseGenerator(helper, astFactory, token, prefix,
        declarationReferenceOffset, declaration, plainNameForRead);
  }

  @override
  Generator<Expression, Statement, Arguments> unlinkedGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      UnlinkedDeclaration declaration) {
    return new AnalyzerUnlinkedNameGenerator(
        helper, astFactory, token, declaration);
  }

  @override
  Generator<Expression, Statement, Arguments> unresolvedNameGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      kernel.Name name) {
    return new AnalyzerUnresolvedNameGenerator(helper, astFactory, token, name);
  }

  @override
  VariableDeclarationStatement variablesDeclaration(
      List<VariableDeclaration> declarations, Uri uri) {
    // TODO(brianwilkerson) Implement this.
    throw new UnimplementedError();
  }

  @override
  NodeList<VariableDeclaration> variablesDeclarationExtractDeclarations(
          VariableDeclarationStatement variablesDeclaration) =>
      variablesDeclaration.variables.variables;

  @override
  Generator<Expression, Statement, Arguments> variableUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      VariableDeclarationStatement variable,
      kernel.DartType promotedType) {
    return new AnalyzerVariableUseGenerator(helper, astFactory, token);
  }

  Statement whileStatement(Token whileKeyword,
          ParenthesizedExpression condition, Statement body) =>
      astFactory.whileStatement(whileKeyword, condition.leftParenthesis,
          condition.expression, condition.rightParenthesis, body);

  @override
  Statement wrapVariables(Statement statement) => statement;

  @override
  Statement yieldStatement(Token yieldKeyword, Token star,
          Expression expression, Token semicolon) =>
      astFactory.yieldStatement(yieldKeyword, star, expression, semicolon);
}
