// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AssertInitializer,
        Block,
        BreakStatement,
        Catch,
        ContinueSwitchStatement,
        DartType,
        DynamicType,
        EmptyStatement,
        Expression,
        ExpressionStatement,
        InvalidExpression,
        LabeledStatement,
        Let,
        LibraryDependency,
        MapEntry,
        Member,
        Name,
        NamedExpression,
        Procedure,
        Statement,
        SwitchCase,
        ThisExpression,
        TreeNode,
        VariableDeclaration,
        setParents;

import '../parser.dart' show endOffsetForToken, offsetForToken, optional;

import '../problems.dart' show unsupported;

import '../scanner.dart' show Token;

import 'body_builder.dart' show LabelTarget;

import 'kernel_expression_generator.dart'
    show
        KernelDeferredAccessGenerator,
        KernelDelayedAssignment,
        KernelDelayedPostfixIncrement,
        KernelIndexedAccessGenerator,
        KernelLargeIntAccessGenerator,
        KernelLoadLibraryGenerator,
        KernelNullAwarePropertyAccessGenerator,
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
        AsJudgment,
        AssertInitializerJudgment,
        AssertStatementJudgment,
        AwaitJudgment,
        BlockJudgment,
        BoolJudgment,
        BreakJudgment,
        CatchJudgment,
        CheckLibraryIsLoadedJudgment,
        ConditionalJudgment,
        ContinueJudgment,
        DoJudgment,
        DoubleJudgment,
        EmptyStatementJudgment,
        ExpressionStatementJudgment,
        ForJudgment,
        IfJudgment,
        IntJudgment,
        IsJudgment,
        IsNotJudgment,
        LabeledStatementJudgment,
        ListLiteralJudgment,
        LoadLibraryJudgment,
        LogicalJudgment,
        MapEntryJudgment,
        MapLiteralJudgment,
        NotJudgment,
        NullJudgment,
        RethrowJudgment,
        ReturnJudgment,
        StringConcatenationJudgment,
        StringLiteralJudgment,
        SymbolLiteralJudgment,
        SyntheticExpressionJudgment,
        ThisJudgment,
        ThrowJudgment,
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
        PrefixBuilder,
        PrefixUseGenerator,
        TypeDeclarationBuilder,
        UnlinkedDeclaration;

import '../type_inference/type_inference_listener.dart'
    show TypeInferenceTokensSaver;

/// A shadow tree factory.
class Fangorn extends Forest {
  TypeInferenceTokensSaver typeInferenceTokensSaver;

  Fangorn(this.typeInferenceTokensSaver);

  @override
  ArgumentsJudgment arguments(
      List<Expression> positional, Token beginToken, Token endToken,
      {List<DartType> types, List<NamedExpression> named}) {
    return new ArgumentsJudgment(
        offsetForToken(beginToken), endOffsetForToken(endToken), positional,
        types: types, named: named);
  }

  @override
  ArgumentsJudgment argumentsEmpty(Token beginToken, Token endToken) {
    return arguments(<Expression>[], beginToken, endToken);
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
  StringLiteralJudgment asLiteralString(Expression value) => value;

  @override
  BoolJudgment literalBool(bool value, Token token) {
    return new BoolJudgment(
        typeInferenceTokensSaver?.boolLiteralTokens(token), value)
      ..fileOffset = offsetForToken(token);
  }

  @override
  DoubleJudgment literalDouble(double value, Token token) {
    return new DoubleJudgment(
        typeInferenceTokensSaver?.doubleLiteralTokens(token), value)
      ..fileOffset = offsetForToken(token);
  }

  @override
  IntJudgment literalInt(int value, Token token, {Expression desugaredError}) {
    return new IntJudgment(
        typeInferenceTokensSaver?.intLiteralTokens(token), value,
        desugaredError: desugaredError)
      ..fileOffset = offsetForToken(token);
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
    return new ListLiteralJudgment(
        typeInferenceTokensSaver?.listLiteralTokens(
            constKeyword, leftBracket, rightBracket),
        expressions,
        typeArgument: typeArgument,
        isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBracket);
  }

  @override
  MapLiteralJudgment literalMap(
      Token constKeyword,
      bool isConst,
      DartType keyType,
      DartType valueType,
      Object typeArguments,
      Token leftBracket,
      List<MapEntry> entries,
      Token rightBracket) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new MapLiteralJudgment(
        typeInferenceTokensSaver?.mapLiteralTokens(
            constKeyword, leftBracket, rightBracket),
        entries,
        keyType: keyType,
        valueType: valueType,
        isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBracket);
  }

  @override
  NullJudgment literalNull(Token token) {
    return new NullJudgment(typeInferenceTokensSaver?.nullLiteralTokens(token))
      ..fileOffset = offsetForToken(token);
  }

  @override
  StringLiteralJudgment literalString(String value, Token token) {
    return new StringLiteralJudgment(
        typeInferenceTokensSaver?.stringLiteralTokens(token), value)
      ..fileOffset = offsetForToken(token);
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
    return new MapEntryJudgment(key, value)..fileOffset = offsetForToken(colon);
  }

  @override
  List<MapEntry> mapEntryList(int length) {
    return new List<MapEntryJudgment>.filled(length, null, growable: true);
  }

  @override
  int readOffset(TreeNode node) => node.fileOffset;

  @override
  int getTypeCount(List typeArguments) => typeArguments.length;

  @override
  DartType getTypeAt(List typeArguments, int index) => typeArguments[index];

  @override
  Expression loadLibrary(LibraryDependency dependency, Arguments arguments) {
    return new LoadLibraryJudgment(dependency, arguments);
  }

  @override
  Expression checkLibraryIsLoaded(LibraryDependency dependency) {
    return new CheckLibraryIsLoadedJudgment(dependency);
  }

  @override
  Expression asExpression(Expression expression, covariant type, Token token,
      {Expression desugaredError}) {
    return new AsJudgment(
        expression, typeInferenceTokensSaver?.asExpressionTokens(token), type,
        desugaredError: desugaredError)
      ..fileOffset = offsetForToken(token);
  }

  @override
  AssertInitializer assertInitializer(
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message) {
    return new AssertInitializerJudgment(
        assertStatement(
            assertKeyword, leftParenthesis, condition, comma, message, null),
        typeInferenceTokensSaver?.assertInitializerTokens(
            assertKeyword, leftParenthesis, comma, leftParenthesis.endGroup));
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
    return new AssertStatementJudgment(
        typeInferenceTokensSaver?.assertStatementTokens(assertKeyword,
            leftParenthesis, comma, leftParenthesis.endGroup, semicolon),
        condition,
        conditionStartOffset: startOffset,
        conditionEndOffset: endOffset,
        message: message);
  }

  @override
  Expression awaitExpression(Expression operand, Token token) {
    return new AwaitJudgment(
        typeInferenceTokensSaver?.awaitExpressionTokens(token), operand)
      ..fileOffset = offsetForToken(token);
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
    return new BlockJudgment(
        typeInferenceTokensSaver?.blockTokens(openBrace, closeBrace),
        copy ?? statements)
      ..fileOffset = offsetForToken(openBrace);
  }

  @override
  Statement breakStatement(Token breakKeyword, Object label, Token semicolon) {
    return new BreakJudgment(
        typeInferenceTokensSaver?.breakStatementTokens(breakKeyword, semicolon),
        null)
      ..fileOffset = breakKeyword.charOffset;
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
    exceptionType ??= const DynamicType();
    // TODO(brianwilkerson) Get the left and right parentheses and the comma.
    return new CatchJudgment(
        typeInferenceTokensSaver?.catchStatementTokens(
            onKeyword, catchKeyword, null, null, null),
        exceptionParameter,
        body,
        guard: exceptionType,
        stackTrace: stackTraceParameter)
      ..fileOffset = offsetForToken(onKeyword ?? catchKeyword);
  }

  @override
  Expression conditionalExpression(Expression condition, Token question,
      Expression thenExpression, Token colon, Expression elseExpression) {
    return new ConditionalJudgment(
        condition,
        typeInferenceTokensSaver?.conditionalExpressionTokens(question, colon),
        thenExpression,
        elseExpression)
      ..fileOffset = offsetForToken(question);
  }

  @override
  Statement continueStatement(
      Token continueKeyword, Object label, Token semicolon) {
    return new ContinueJudgment(
        typeInferenceTokensSaver?.continueStatementTokens(
            continueKeyword, semicolon),
        null)
      ..fileOffset = continueKeyword.charOffset;
  }

  @override
  Statement doStatement(Token doKeyword, Statement body, Token whileKeyword,
      Expression condition, Token semicolon) {
    // TODO(brianwilkerson): Plumb through the left-and right parentheses.
    return new DoJudgment(
        typeInferenceTokensSaver?.doStatementTokens(
            doKeyword, whileKeyword, null, null, semicolon),
        body,
        condition)
      ..fileOffset = doKeyword.charOffset;
  }

  Statement expressionStatement(Expression expression, Token semicolon) {
    return new ExpressionStatementJudgment(expression,
        typeInferenceTokensSaver?.expressionStatementTokens(semicolon));
  }

  @override
  Statement emptyStatement(Token semicolon) {
    return new EmptyStatementJudgment(
        typeInferenceTokensSaver?.emptyStatementTokens(semicolon));
  }

  @override
  Statement forStatement(
      Token forKeyword,
      Token leftParenthesis,
      List<VariableDeclaration> variableList,
      List<Expression> initializers,
      Token leftSeparator,
      Expression condition,
      Statement conditionStatement,
      List<Expression> updaters,
      Token rightParenthesis,
      Statement body) {
    // TODO(brianwilkerson): Plumb through the right separator.
    return new ForJudgment(
        typeInferenceTokensSaver?.forStatementTokens(forKeyword,
            leftParenthesis, leftSeparator, null, leftParenthesis.endGroup),
        variableList,
        initializers,
        condition,
        updaters,
        body)
      ..fileOffset = forKeyword.charOffset;
  }

  @override
  Statement ifStatement(Token ifKeyword, Expression condition,
      Statement thenStatement, Token elseKeyword, Statement elseStatement) {
    // TODO(brianwilkerson) Plumb through the left and right parentheses.
    return new IfJudgment(
        typeInferenceTokensSaver?.ifStatementTokens(
            ifKeyword, null, null, elseKeyword),
        condition,
        thenStatement,
        elseStatement)
      ..fileOffset = ifKeyword.charOffset;
  }

  @override
  Expression isExpression(
      Expression operand, isOperator, Token notOperator, covariant type) {
    int offset = offsetForToken(isOperator);
    if (notOperator != null) {
      return new IsNotJudgment(
          operand,
          typeInferenceTokensSaver?.isNotExpressionTokens(
              isOperator, notOperator),
          type,
          offset)
        ..fileOffset = offset;
    }
    return new IsJudgment(
        operand, typeInferenceTokensSaver?.isExpressionTokens(isOperator), type)
      ..fileOffset = offset;
  }

  @override
  Label label(Token identifier, Token colon) {
    return new Label(identifier.lexeme, identifier.charOffset);
  }

  @override
  Statement labeledStatement(LabelTarget target, Statement statement) =>
      statement;

  @override
  Expression logicalExpression(
      Expression leftOperand, Token operator, Expression rightOperand) {
    return new LogicalJudgment(
        leftOperand,
        typeInferenceTokensSaver?.logicalExpressionTokens(operator),
        operator.stringValue,
        rightOperand)
      ..fileOffset = offsetForToken(operator);
  }

  @override
  Expression notExpression(Expression operand, Token token, bool isSynthetic) {
    return new NotJudgment(
        isSynthetic, typeInferenceTokensSaver?.notTokens(token), operand)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression parenthesizedCondition(
      Token leftParenthesis, Expression expression, Token rightParenthesis) {
    return expression;
  }

  @override
  Statement rethrowStatement(Token rethrowKeyword, Token semicolon) {
    return new ExpressionStatementJudgment(
        new RethrowJudgment(
            typeInferenceTokensSaver?.rethrowTokens(rethrowKeyword), null)
          ..fileOffset = offsetForToken(rethrowKeyword),
        typeInferenceTokensSaver?.expressionStatementTokens(semicolon));
  }

  @override
  Statement returnStatement(
      Token returnKeyword, Expression expression, Token semicolon) {
    return new ReturnJudgment(
        typeInferenceTokensSaver?.returnStatementTokens(
            returnKeyword, semicolon),
        returnKeyword?.lexeme,
        expression)
      ..fileOffset = returnKeyword.charOffset;
  }

  @override
  Expression stringConcatenationExpression(
      List<Expression> expressions, Token token) {
    return new StringConcatenationJudgment(expressions)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Statement syntheticLabeledStatement(Statement statement) {
    return new LabeledStatementJudgment(statement);
  }

  @override
  Expression thisExpression(Token token) {
    return new ThisJudgment(
        typeInferenceTokensSaver?.thisExpressionTokens(token))
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression throwExpression(Token throwKeyword, Expression expression) {
    return new ThrowJudgment(
        typeInferenceTokensSaver?.throwTokens(throwKeyword), expression)
      ..fileOffset = offsetForToken(throwKeyword);
  }

  @override
  Statement tryStatement(Token tryKeyword, Statement body,
      List<Catch> catchClauses, Token finallyKeyword, Statement finallyBlock) {
    if (finallyBlock != null) {
      return new TryFinallyJudgment(
          typeInferenceTokensSaver?.tryFinallyTokens(
              tryKeyword, finallyKeyword),
          body,
          catchClauses,
          finallyBlock);
    }
    return new TryCatchJudgment(body, catchClauses ?? const <CatchJudgment>[]);
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
      return new BlockJudgment(null, statement.declarations)
        ..fileOffset = statement.fileOffset;
    } else if (statement is VariableDeclaration) {
      return new BlockJudgment(null, <Statement>[statement])
        ..fileOffset = statement.fileOffset;
    } else {
      return statement;
    }
  }

  @override
  Statement whileStatement(
      Token whileKeyword, Expression condition, Statement body) {
    // TODO(brianwilkerson) Plumb through the left and right parentheses.
    return new WhileJudgment(
        typeInferenceTokensSaver?.whileStatementTokens(
            whileKeyword, null, null),
        condition,
        body)
      ..fileOffset = whileKeyword.charOffset;
  }

  @override
  Statement yieldStatement(
      Token yieldKeyword, Token star, Expression expression, Token semicolon) {
    return new YieldJudgment(
        typeInferenceTokensSaver?.yieldStatementTokens(
            yieldKeyword, star, semicolon),
        star != null,
        expression)
      ..fileOffset = yieldKeyword.charOffset;
  }

  @override
  Expression getExpressionFromExpressionStatement(Statement statement) {
    return (statement as ExpressionStatement).expression;
  }

  @override
  String getLabelName(Label label) => label.name;

  @override
  int getLabelOffset(Label label) => label.charOffset;

  @override
  String getVariableDeclarationName(VariableDeclaration declaration) {
    return declaration.name;
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
  bool isLabel(covariant node) => node is Label;

  @override
  bool isThisExpression(Object node) => node is ThisExpression;

  @override
  bool isVariablesDeclaration(Object node) => node is _VariablesDeclaration;

  @override
  void resolveBreak(LabeledStatement target, BreakStatement user) {
    user.target = target;
  }

  @override
  void resolveContinue(LabeledStatement target, BreakStatement user) {
    user.target = target;
  }

  @override
  void resolveContinueInSwitch(
      SwitchCase target, ContinueSwitchStatement user) {
    user.target = target;
  }

  @override
  void setParameterType(VariableDeclaration parameter, DartType type) {
    parameter.type = type ?? const DynamicType();
  }

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
      Token openSquareBracket,
      Token closeSquareBracket,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return new KernelIndexedAccessGenerator.internal(helper, openSquareBracket,
        closeSquareBracket, receiver, index, getter, setter);
  }

  @override
  KernelThisIndexedAccessGenerator thisIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token openSquareBracket,
      Token closeSquareBracket,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return new KernelThisIndexedAccessGenerator(
        helper, openSquareBracket, closeSquareBracket, index, getter, setter);
  }

  @override
  KernelSuperIndexedAccessGenerator superIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token openSquareBracket,
      Token closeSquareBracket,
      Expression index,
      Member getter,
      Member setter) {
    return new KernelSuperIndexedAccessGenerator(
        helper, openSquareBracket, closeSquareBracket, index, getter, setter);
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
  KernelLargeIntAccessGenerator largeIntAccessGenerator(
      ExpressionGeneratorHelper helper, Token token) {
    return new KernelLargeIntAccessGenerator(helper, token);
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

/// A data holder used to hold the information about a label that is pushed on
/// the stack.
class Label {
  String name;
  int charOffset;

  Label(this.name, this.charOffset);

  String toString() => "label($name)";
}
