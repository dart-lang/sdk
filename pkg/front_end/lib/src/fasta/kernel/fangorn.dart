// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsExpression,
        AssertInitializer,
        AwaitExpression,
        Block,
        BoolLiteral,
        BreakStatement,
        Catch,
        CheckLibraryIsLoaded,
        ConditionalExpression,
        DartType,
        EmptyStatement,
        Expression,
        ExpressionStatement,
        InvalidExpression,
        IsExpression,
        LabeledStatement,
        Let,
        LibraryDependency,
        LogicalExpression,
        MapEntry,
        Member,
        Name,
        NamedExpression,
        Not,
        NullLiteral,
        Procedure,
        Rethrow,
        Statement,
        StringConcatenation,
        StringLiteral,
        ThisExpression,
        Throw,
        TreeNode,
        VariableDeclaration,
        setParents;

import '../parser.dart' show offsetForToken, optional;

import '../problems.dart' show unsupported;

import '../scanner.dart' show Token;

import 'body_builder.dart' show LabelTarget;

import 'collections.dart'
    show
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfElement,
        IfMapEntry,
        SpreadElement;

import 'kernel_expression_generator.dart'
    show
        KernelDeferredAccessGenerator,
        KernelDelayedAssignment,
        KernelDelayedPostfixIncrement,
        KernelIndexedAccessGenerator,
        KernelLoadLibraryGenerator,
        KernelNullAwarePropertyAccessGenerator,
        KernelParserErrorGenerator,
        KernelPrefixUseGenerator,
        KernelPropertyAccessGenerator,
        KernelReadOnlyAccessGenerator,
        KernelStaticAccessGenerator,
        KernelSuperIndexedAccessGenerator,
        KernelSuperPropertyAccessGenerator,
        KernelThisIndexedAccessGenerator,
        KernelThisPropertyAccessGenerator,
        KernelTypeUseGenerator,
        KernelUnexpectedQualifiedUseGenerator,
        KernelUnlinkedGenerator,
        KernelUnresolvedNameGenerator,
        KernelVariableUseGenerator;

import 'kernel_shadow_ast.dart'
    show
        ArgumentsJudgment,
        AssertInitializerJudgment,
        AssertStatementJudgment,
        BlockJudgment,
        CatchJudgment,
        DoJudgment,
        DoubleJudgment,
        EmptyStatementJudgment,
        ExpressionStatementJudgment,
        ForJudgment,
        IfJudgment,
        IntJudgment,
        ListLiteralJudgment,
        LoadLibraryJudgment,
        MapLiteralJudgment,
        ReturnJudgment,
        SetLiteralJudgment,
        ShadowLargeIntLiteral,
        SymbolLiteralJudgment,
        SyntheticExpressionJudgment,
        TryCatchJudgment,
        TryFinallyJudgment,
        TypeLiteralJudgment,
        WhileJudgment,
        YieldJudgment;

import 'forest.dart'
    show
        ExpressionGeneratorHelper,
        Forest,
        Generator,
        LoadLibraryBuilder,
        Message,
        PrefixBuilder,
        PrefixUseGenerator,
        TypeDeclarationBuilder,
        UnlinkedDeclaration;

/// A shadow tree factory.
class Fangorn extends Forest {
  const Fangorn();

  @override
  ArgumentsJudgment arguments(List<Expression> positional, Token token,
      {List<DartType> types, List<NamedExpression> named}) {
    return new ArgumentsJudgment(positional, types: types, named: named)
      ..fileOffset = offsetForToken(token);
  }

  @override
  ArgumentsJudgment argumentsEmpty(Token token) {
    return arguments(<Expression>[], token);
  }

  @override
  List<NamedExpression> argumentsNamed(Arguments arguments) {
    return arguments.named;
  }

  @override
  List<Expression> argumentsPositional(Arguments arguments) {
    return arguments.positional;
  }

  @override
  List<DartType> argumentsTypeArguments(Arguments arguments) {
    return arguments.types;
  }

  @override
  void argumentsSetTypeArguments(Arguments arguments, List<DartType> types) {
    ArgumentsJudgment.setNonInferrableArgumentTypes(arguments, types);
  }

  @override
  StringLiteral asLiteralString(Expression value) => value;

  @override
  BoolLiteral literalBool(bool value, Token token) {
    return new BoolLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  DoubleJudgment literalDouble(double value, Token token) {
    return new DoubleJudgment(value)..fileOffset = offsetForToken(token);
  }

  @override
  IntJudgment literalInt(int value, Token token) {
    return new IntJudgment(value, token?.lexeme)
      ..fileOffset = offsetForToken(token);
  }

  @override
  ShadowLargeIntLiteral literalLargeInt(String literal, Token token) {
    return new ShadowLargeIntLiteral(literal, offsetForToken(token));
  }

  @override
  ListLiteralJudgment literalList(
      Token constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Token leftBracket,
      List<Expression> expressions,
      Token rightBracket) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new ListLiteralJudgment(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBracket);
  }

  @override
  SetLiteralJudgment literalSet(
      Token constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Token leftBrace,
      List<Expression> expressions,
      Token rightBrace) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new SetLiteralJudgment(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBrace);
  }

  @override
  MapLiteralJudgment literalMap(
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
    return new MapLiteralJudgment(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBrace);
  }

  @override
  NullLiteral literalNull(Token token) {
    return new NullLiteral()..fileOffset = offsetForToken(token);
  }

  @override
  StringLiteral literalString(String value, Token token) {
    return new StringLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  SymbolLiteralJudgment literalSymbolMultiple(String value, Token hash, _) {
    return new SymbolLiteralJudgment(value)..fileOffset = offsetForToken(hash);
  }

  @override
  SymbolLiteralJudgment literalSymbolSingluar(String value, Token hash, _) {
    return new SymbolLiteralJudgment(value)..fileOffset = offsetForToken(hash);
  }

  @override
  TypeLiteralJudgment literalType(DartType type, Token token) {
    return new TypeLiteralJudgment(type)..fileOffset = offsetForToken(token);
  }

  @override
  MapEntry mapEntry(Expression key, Token colon, Expression value) {
    return new MapEntry(key, value)..fileOffset = offsetForToken(colon);
  }

  @override
  int readOffset(TreeNode node) => node.fileOffset;

  @override
  Expression loadLibrary(LibraryDependency dependency, Arguments arguments) {
    return new LoadLibraryJudgment(dependency, arguments);
  }

  @override
  Expression checkLibraryIsLoaded(LibraryDependency dependency) {
    return new CheckLibraryIsLoaded(dependency);
  }

  @override
  Expression asExpression(Expression expression, DartType type, Token token) {
    return new AsExpression(expression, type)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression spreadElement(Expression expression, Token token) {
    return new SpreadElement(expression, token.lexeme == '...?')
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression ifElement(Expression condition, Expression then,
      Expression otherwise, Token token) {
    return new IfElement(condition, then, otherwise)
      ..fileOffset = offsetForToken(token);
  }

  @override
  MapEntry ifMapEntry(
      Expression condition, MapEntry then, MapEntry otherwise, Token token) {
    return new IfMapEntry(condition, then, otherwise)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression forElement(
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      Expression body,
      Token token) {
    return new ForElement(variables, condition, updates, body)
      ..fileOffset = offsetForToken(token);
  }

  @override
  MapEntry forMapEntry(
      List<VariableDeclaration> variables,
      Expression condition,
      List<Expression> updates,
      MapEntry body,
      Token token) {
    return new ForMapEntry(variables, condition, updates, body)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression forInElement(VariableDeclaration variable, Expression iterable,
      Statement prologue, Expression body, Expression problem, Token token,
      {bool isAsync: false}) {
    return new ForInElement(variable, iterable, prologue, body, problem,
        isAsync: isAsync)
      ..fileOffset = offsetForToken(token);
  }

  @override
  MapEntry forInMapEntry(VariableDeclaration variable, Expression iterable,
      Statement prologue, MapEntry body, Expression problem, Token token,
      {bool isAsync: false}) {
    return new ForInMapEntry(variable, iterable, prologue, body, problem,
        isAsync: isAsync)
      ..fileOffset = offsetForToken(token);
  }

  @override
  AssertInitializer assertInitializer(
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message) {
    return new AssertInitializerJudgment(assertStatement(
        assertKeyword, leftParenthesis, condition, comma, message, null));
  }

  @override
  Statement assertStatement(Token assertKeyword, Token leftParenthesis,
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
    return new AssertStatementJudgment(condition,
        conditionStartOffset: startOffset,
        conditionEndOffset: endOffset,
        message: message);
  }

  @override
  Expression awaitExpression(Expression operand, Token token) {
    return new AwaitExpression(operand)..fileOffset = offsetForToken(token);
  }

  @override
  Statement block(
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
    return new BlockJudgment(copy ?? statements)
      ..fileOffset = offsetForToken(openBrace);
  }

  @override
  Statement breakStatement(Token breakKeyword, Object label, Token semicolon) {
    return new BreakStatement(null)..fileOffset = breakKeyword.charOffset;
  }

  @override
  Catch catchClause(
      Token onKeyword,
      DartType exceptionType,
      Token catchKeyword,
      VariableDeclaration exceptionParameter,
      VariableDeclaration stackTraceParameter,
      DartType stackTraceType,
      Statement body) {
    return new CatchJudgment(exceptionParameter, body,
        guard: exceptionType, stackTrace: stackTraceParameter)
      ..fileOffset = offsetForToken(onKeyword ?? catchKeyword);
  }

  @override
  Expression conditionalExpression(Expression condition, Token question,
      Expression thenExpression, Token colon, Expression elseExpression) {
    return new ConditionalExpression(
        condition, thenExpression, elseExpression, null)
      ..fileOffset = offsetForToken(question);
  }

  @override
  Statement continueStatement(
      Token continueKeyword, Object label, Token semicolon) {
    return new BreakStatement(null)..fileOffset = continueKeyword.charOffset;
  }

  @override
  Statement doStatement(Token doKeyword, Statement body, Token whileKeyword,
      Expression condition, Token semicolon) {
    return new DoJudgment(body, condition)..fileOffset = doKeyword.charOffset;
  }

  Statement expressionStatement(Expression expression, Token semicolon) {
    return new ExpressionStatementJudgment(expression);
  }

  @override
  Statement emptyStatement(Token semicolon) {
    return new EmptyStatementJudgment();
  }

  @override
  Statement forStatement(
      Token forKeyword,
      Token leftParenthesis,
      List<VariableDeclaration> variables,
      Token leftSeparator,
      Expression condition,
      Statement conditionStatement,
      List<Expression> updaters,
      Token rightParenthesis,
      Statement body) {
    return new ForJudgment(variables, condition, updaters, body)
      ..fileOffset = forKeyword.charOffset;
  }

  @override
  Statement ifStatement(Token ifKeyword, Expression condition,
      Statement thenStatement, Token elseKeyword, Statement elseStatement) {
    return new IfJudgment(condition, thenStatement, elseStatement)
      ..fileOffset = ifKeyword.charOffset;
  }

  @override
  Expression isExpression(
      Expression operand, Token isOperator, Token notOperator, DartType type) {
    Expression result = new IsExpression(operand, type)
      ..fileOffset = offsetForToken(isOperator);
    if (notOperator != null) {
      result = notExpression(result, notOperator, false);
    }
    return result;
  }

  @override
  Statement labeledStatement(LabelTarget target, Statement statement) =>
      statement;

  @override
  Expression logicalExpression(
      Expression leftOperand, Token operator, Expression rightOperand) {
    return new LogicalExpression(
        leftOperand, operator.stringValue, rightOperand)
      ..fileOffset = offsetForToken(operator);
  }

  @override
  Expression notExpression(Expression operand, Token token, bool isSynthetic) {
    return new Not(operand)..fileOffset = offsetForToken(token);
  }

  @override
  Expression parenthesizedCondition(
      Token leftParenthesis, Expression expression, Token rightParenthesis) {
    return expression;
  }

  @override
  Statement rethrowStatement(Token rethrowKeyword, Token semicolon) {
    return new ExpressionStatementJudgment(
        new Rethrow()..fileOffset = offsetForToken(rethrowKeyword));
  }

  @override
  Statement returnStatement(
      Token returnKeyword, Expression expression, Token semicolon) {
    return new ReturnJudgment(returnKeyword?.lexeme, expression)
      ..fileOffset = returnKeyword.charOffset;
  }

  @override
  Expression stringConcatenationExpression(
      List<Expression> expressions, Token token) {
    return new StringConcatenation(expressions)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Statement syntheticLabeledStatement(Statement statement) {
    return new LabeledStatement(statement);
  }

  @override
  Expression thisExpression(Token token) {
    return new ThisExpression()..fileOffset = offsetForToken(token);
  }

  @override
  Expression throwExpression(Token throwKeyword, Expression expression) {
    return new Throw(expression)..fileOffset = offsetForToken(throwKeyword);
  }

  @override
  bool isThrow(Object o) => o is Throw;

  @override
  Statement tryStatement(Token tryKeyword, Statement body,
      List<Catch> catchClauses, Token finallyKeyword, Statement finallyBlock) {
    Statement result = body;
    if (catchClauses != null) {
      result = new TryCatchJudgment(result, catchClauses);
    }
    if (finallyBlock != null) {
      result = new TryFinallyJudgment(result, finallyBlock);
    }
    return result;
  }

  @override
  _VariablesDeclaration variablesDeclaration(
      List<VariableDeclaration> declarations, Uri uri) {
    return new _VariablesDeclaration(declarations, uri);
  }

  @override
  List<VariableDeclaration> variablesDeclarationExtractDeclarations(
      _VariablesDeclaration variablesDeclaration) {
    return variablesDeclaration.declarations;
  }

  @override
  Statement wrapVariables(Statement statement) {
    if (statement is _VariablesDeclaration) {
      return new BlockJudgment(
          new List<Statement>.from(statement.declarations, growable: true))
        ..fileOffset = statement.fileOffset;
    } else if (statement is VariableDeclaration) {
      return new BlockJudgment(<Statement>[statement])
        ..fileOffset = statement.fileOffset;
    } else {
      return statement;
    }
  }

  @override
  Statement whileStatement(
      Token whileKeyword, Expression condition, Statement body) {
    return new WhileJudgment(condition, body)
      ..fileOffset = whileKeyword.charOffset;
  }

  @override
  Statement yieldStatement(
      Token yieldKeyword, Token star, Expression expression, Token semicolon) {
    return new YieldJudgment(star != null, expression)
      ..fileOffset = yieldKeyword.charOffset;
  }

  @override
  Expression getExpressionFromExpressionStatement(Statement statement) {
    return (statement as ExpressionStatement).expression;
  }

  @override
  bool isBlock(Object node) => node is Block;

  @override
  bool isEmptyStatement(Statement statement) => statement is EmptyStatement;

  @override
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

  @override
  bool isExpressionStatement(Statement statement) =>
      statement is ExpressionStatement;

  @override
  bool isThisExpression(Object node) => node is ThisExpression;

  @override
  bool isVariablesDeclaration(Object node) => node is _VariablesDeclaration;

  @override
  KernelVariableUseGenerator variableUseGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      VariableDeclaration variable,
      DartType promotedType) {
    return new KernelVariableUseGenerator(
        helper, token, variable, promotedType);
  }

  @override
  KernelPropertyAccessGenerator propertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiver,
      Name name,
      Member getter,
      Member setter) {
    return new KernelPropertyAccessGenerator.internal(
        helper, token, receiver, name, getter, setter);
  }

  @override
  KernelThisPropertyAccessGenerator thisPropertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Name name,
      Member getter,
      Member setter) {
    return new KernelThisPropertyAccessGenerator(
        helper, token, name, getter, setter);
  }

  @override
  KernelNullAwarePropertyAccessGenerator nullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiverExpression,
      Name name,
      Member getter,
      Member setter,
      DartType type) {
    return new KernelNullAwarePropertyAccessGenerator(
        helper, token, receiverExpression, name, getter, setter, type);
  }

  @override
  KernelSuperPropertyAccessGenerator superPropertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Name name,
      Member getter,
      Member setter) {
    return new KernelSuperPropertyAccessGenerator(
        helper, token, name, getter, setter);
  }

  @override
  KernelIndexedAccessGenerator indexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return new KernelIndexedAccessGenerator.internal(
        helper, token, receiver, index, getter, setter);
  }

  @override
  KernelThisIndexedAccessGenerator thisIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return new KernelThisIndexedAccessGenerator(
        helper, token, index, getter, setter);
  }

  @override
  KernelSuperIndexedAccessGenerator superIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression index,
      Member getter,
      Member setter) {
    return new KernelSuperIndexedAccessGenerator(
        helper, token, index, getter, setter);
  }

  @override
  KernelStaticAccessGenerator staticAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Member getter,
      Member setter) {
    return new KernelStaticAccessGenerator(helper, token, getter, setter);
  }

  @override
  KernelLoadLibraryGenerator loadLibraryGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      LoadLibraryBuilder builder) {
    return new KernelLoadLibraryGenerator(helper, token, builder);
  }

  @override
  KernelDeferredAccessGenerator deferredAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      PrefixUseGenerator prefixGenerator,
      Generator suffixGenerator) {
    return new KernelDeferredAccessGenerator(
        helper, token, prefixGenerator, suffixGenerator);
  }

  @override
  KernelTypeUseGenerator typeUseGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      TypeDeclarationBuilder declaration,
      String plainNameForRead) {
    return new KernelTypeUseGenerator(
        helper, token, declaration, plainNameForRead);
  }

  @override
  KernelReadOnlyAccessGenerator readOnlyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression expression,
      String plainNameForRead) {
    return new KernelReadOnlyAccessGenerator(
        helper, token, expression, plainNameForRead);
  }

  @override
  KernelUnresolvedNameGenerator unresolvedNameGenerator(
      ExpressionGeneratorHelper helper, Token token, Name name) {
    return new KernelUnresolvedNameGenerator(helper, token, name);
  }

  @override
  KernelUnlinkedGenerator unlinkedGenerator(ExpressionGeneratorHelper helper,
      Token token, UnlinkedDeclaration declaration) {
    return new KernelUnlinkedGenerator(helper, token, declaration);
  }

  @override
  KernelDelayedAssignment delayedAssignment(
      ExpressionGeneratorHelper helper,
      Token token,
      Generator generator,
      Expression value,
      String assignmentOperator) {
    return new KernelDelayedAssignment(
        helper, token, generator, value, assignmentOperator);
  }

  @override
  KernelDelayedPostfixIncrement delayedPostfixIncrement(
      ExpressionGeneratorHelper helper,
      Token token,
      Generator generator,
      Name binaryOperator,
      Procedure interfaceTarget) {
    return new KernelDelayedPostfixIncrement(
        helper, token, generator, binaryOperator, interfaceTarget);
  }

  @override
  KernelPrefixUseGenerator prefixUseGenerator(
      ExpressionGeneratorHelper helper, Token token, PrefixBuilder prefix) {
    return new KernelPrefixUseGenerator(helper, token, prefix);
  }

  @override
  KernelUnexpectedQualifiedUseGenerator unexpectedQualifiedUseGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Generator prefixGenerator,
      bool isUnresolved) {
    return new KernelUnexpectedQualifiedUseGenerator(
        helper, token, prefixGenerator, isUnresolved);
  }

  @override
  KernelParserErrorGenerator parserErrorGenerator(
      ExpressionGeneratorHelper helper, Token token, Message message) {
    return new KernelParserErrorGenerator(helper, token, message);
  }
}

class _VariablesDeclaration extends Statement {
  final List<VariableDeclaration> declarations;
  final Uri uri;

  _VariablesDeclaration(this.declarations, this.uri) {
    setParents(declarations, this);
  }

  @override
  accept(v) {
    unsupported("accept", fileOffset, uri);
  }

  @override
  accept1(v, arg) {
    unsupported("accept1", fileOffset, uri);
  }

  @override
  visitChildren(v) {
    unsupported("visitChildren", fileOffset, uri);
  }

  @override
  transformChildren(v) {
    unsupported("transformChildren", fileOffset, uri);
  }
}
