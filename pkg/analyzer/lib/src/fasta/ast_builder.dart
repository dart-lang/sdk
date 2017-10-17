// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.ast_builder;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast_factory.dart' show AstFactory;
import 'package:analyzer/dart/ast/standard_ast_factory.dart' as standard;
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/src/dart/ast/ast.dart' show NodeListImpl;
import 'package:front_end/src/fasta/parser.dart'
    show
        Assert,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        optional,
        Parser;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/token.dart' show CommentToken;

import 'package:front_end/src/fasta/problems.dart' show unhandled;
import 'package:front_end/src/fasta/messages.dart'
    show
        Code,
        Message,
        codeExpectedExpression,
        codeExpectedFunctionBody,
        messageNativeClauseShouldBeAnnotation;
import 'package:front_end/src/fasta/kernel/kernel_builder.dart'
    show Builder, KernelLibraryBuilder, Scope;
import 'package:front_end/src/fasta/quote.dart';
import 'package:front_end/src/fasta/source/scope_listener.dart'
    show JumpTargetKind, NullValue, ScopeListener;
import 'package:analyzer/src/dart/error/syntactic_errors.dart';

class AstBuilder extends ScopeListener {
  final AstFactory ast = standard.astFactory;

  final ErrorReporter errorReporter;
  final KernelLibraryBuilder library;
  final Builder member;

  ScriptTag scriptTag;
  final List<Directive> directives = <Directive>[];
  final List<CompilationUnitMember> declarations = <CompilationUnitMember>[];

  @override
  final Uri uri;

  /**
   * The [Parser] that uses this listener, used to parse optional parts, e.g.
   * `native` support.
   */
  Parser parser;

  bool parseGenericMethodComments = false;

  /// The name of the class currently being parsed, or `null` if no class is
  /// being parsed.
  String className;

  /// If true, this is building a full AST. Otherwise, only create method
  /// bodies.
  final bool isFullAst;

  /// `true` if the `native` clause is allowed
  /// in class, method, and function declarations.
  ///
  /// This is being replaced by the @native(...) annotation.
  //
  // TODO(danrubel) Move this flag to a better location
  // and should only be true if either:
  // * The current library is a platform library
  // * The current library has an import that uses the scheme "dart-ext".
  bool allowNativeClause = false;

  StringLiteral nativeName;

  AstBuilder(this.errorReporter, this.library, this.member, Scope scope,
      this.isFullAst,
      [Uri uri])
      : uri = uri ?? library.fileUri,
        super(scope);

  createJumpTarget(JumpTargetKind kind, int charOffset) {
    // TODO(ahe): Implement jump targets.
    return null;
  }

  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  void handleNamedArgument(Token colon) {
    debugEvent("NamedArgument");
    Expression expression = pop();
    SimpleIdentifier name = pop();
    push(ast.namedExpression(ast.label(name, colon), expression));
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
    push(NullValue.ConstructorReferenceContinuationAfterTypeArguments);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    SimpleIdentifier constructorName = pop();
    TypeArgumentList typeArguments = pop();
    Identifier typeNameIdentifier = pop();
    push(ast.constructorName(ast.typeName(typeNameIdentifier, typeArguments),
        periodBeforeName, constructorName));
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("ConstExpression");
    _handleInstanceCreation(token);
  }

  @override
  void endConstLiteral(Token token) {
    debugEvent("endConstLiteral");
  }

  void _handleInstanceCreation(Token token) {
    MethodInvocation arguments = pop();
    ConstructorName constructorName = pop();
    push(ast.instanceCreationExpression(
        token, constructorName, arguments.argumentList));
  }

  @override
  void endNewExpression(Token token) {
    debugEvent("NewExpression");
    _handleInstanceCreation(token);
  }

  @override
  void handleParenthesizedExpression(Token token) {
    debugEvent("ParenthesizedExpression");
    Expression expression = pop();
    push(ast.parenthesizedExpression(token, expression, token?.endGroup));
  }

  void handleStringPart(Token token) {
    debugEvent("StringPart");
    push(token);
  }

  void doStringPart(Token token) {
    push(ast.simpleStringLiteral(token, token.lexeme));
  }

  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop();
      String value = unescapeString(token.lexeme);
      push(ast.simpleStringLiteral(token, value));
    } else {
      List parts = popList(1 + interpolationCount * 2);
      Token first = parts.first;
      Token last = parts.last;
      Quote quote = analyzeQuote(first.lexeme);
      List<InterpolationElement> elements = <InterpolationElement>[];
      elements.add(ast.interpolationString(
          first, unescapeFirstStringPart(first.lexeme, quote)));
      for (int i = 1; i < parts.length - 1; i++) {
        var part = parts[i];
        if (part is Token) {
          elements.add(ast.interpolationString(part, part.lexeme));
        } else if (part is Expression) {
          elements.add(ast.interpolationExpression(null, part, null));
        } else {
          unhandled("${part.runtimeType}", "string interpolation",
              first.charOffset, uri);
        }
      }
      elements.add(ast.interpolationString(
          last, unescapeLastStringPart(last.lexeme, quote)));
      push(ast.stringInterpolation(elements));
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      nativeName = pop(); // StringLiteral
    } else {
      nativeName = null;
    }
  }

  void handleScript(Token token) {
    debugEvent("Script");
    scriptTag = ast.scriptTag(token);
  }

  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    push(ast.adjacentStrings(popList(literalCount)));
  }

  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    List expressions = popList(count);
    ArgumentList arguments =
        ast.argumentList(beginToken, expressions, endToken);
    push(ast.methodInvocation(null, null, null, null, arguments));
  }

  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    Token analyzerToken = token;

    if (context.inSymbol) {
      push(analyzerToken);
      return;
    }

    SimpleIdentifier identifier = ast.simpleIdentifier(analyzerToken,
        isDeclaration: context.inDeclaration);
    if (context.inLibraryOrPartOfDeclaration) {
      if (!context.isContinuation) {
        push([identifier]);
      } else {
        push(identifier);
      }
    } else if (context == IdentifierContext.enumValueDeclaration) {
      List<Annotation> metadata = pop();
      Comment comment = _parseDocumentationCommentOpt(token.precedingComments);
      push(ast.enumConstantDeclaration(comment, metadata, identifier));
    } else {
      push(identifier);
    }
  }

  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send");
    MethodInvocation arguments = pop();
    TypeArgumentList typeArguments = pop();
    if (arguments != null) {
      doInvocation(endToken, typeArguments, arguments);
    } else {
      doPropertyGet(endToken);
    }
  }

  void doInvocation(
      Token token, TypeArgumentList typeArguments, MethodInvocation arguments) {
    Expression receiver = pop();
    if (receiver is SimpleIdentifier) {
      arguments.methodName = receiver;
      if (typeArguments != null) {
        arguments.typeArguments = typeArguments;
      }
      push(arguments);
    } else {
      push(ast.functionExpressionInvocation(
          receiver, typeArguments, arguments.argumentList));
    }
  }

  void doPropertyGet(Token token) {}

  void endExpressionStatement(Token token) {
    debugEvent("ExpressionStatement");
    push(ast.expressionStatement(pop(), token));
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBody");
    // TODO(danrubel) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.nativeFunctionBody(nativeToken, nativeName, semicolon));
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    debugEvent("EmptyFunctionBody");
    // TODO(scheglov) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.emptyFunctionBody(semicolon));
  }

  @override
  void handleEmptyStatement(Token token) {
    debugEvent("EmptyStatement");
    push(ast.emptyStatement(token));
  }

  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    debugEvent("BlockFunctionBody");
    List statements = popList(count);
    if (beginToken != null) {
      exitLocalScope();
    }
    Block block = ast.block(beginToken, statements, endToken);
    Token star = pop();
    Token asyncKeyword = pop();
    push(ast.blockFunctionBody(asyncKeyword, star, block));
  }

  void finishFunction(annotations, formals, asyncModifier, FunctionBody body) {
    debugEvent("finishFunction");
    Statement bodyStatement;
    if (body is EmptyFunctionBody) {
      bodyStatement = ast.emptyStatement(body.semicolon);
    } else if (body is NativeFunctionBody) {
      // TODO(danrubel): what do we need to do with NativeFunctionBody?
    } else if (body is ExpressionFunctionBody) {
      bodyStatement = ast.returnStatement(null, body.expression, null);
    } else {
      bodyStatement = (body as BlockFunctionBody).block;
    }
    // TODO(paulberry): what do we need to do with bodyStatement at this point?
    bodyStatement; // Suppress "unused local variable" hint
  }

  void beginCascade(Token token) {
    debugEvent("beginCascade");
    Expression expression = pop();
    push(token);
    if (expression is CascadeExpression) {
      push(expression);
    } else {
      push(ast.cascadeExpression(expression, <Expression>[]));
    }
    push(NullValue.CascadeReceiver);
  }

  void endCascade() {
    debugEvent("Cascade");
    Expression expression = pop();
    CascadeExpression receiver = pop();
    pop(); // Token.
    receiver.cascadeSections.add(expression);
    push(receiver);
  }

  void handleOperator(Token token) {
    debugEvent("Operator");
    push(token);
  }

  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid");
    push(token);
  }

  @override
  void endBinaryExpression(Token token) {
    debugEvent("BinaryExpression");
    if (identical(".", token.stringValue) ||
        identical("?.", token.stringValue) ||
        identical("..", token.stringValue)) {
      doDotExpression(token);
    } else {
      Expression right = pop();
      Expression left = pop();
      push(ast.binaryExpression(left, token, right));
    }
  }

  void doDotExpression(Token token) {
    Expression identifierOrInvoke = pop();
    Expression receiver = pop();
    if (identifierOrInvoke is SimpleIdentifier) {
      if (receiver is SimpleIdentifier && identical('.', token.stringValue)) {
        push(ast.prefixedIdentifier(receiver, token, identifierOrInvoke));
      } else {
        push(ast.propertyAccess(receiver, token, identifierOrInvoke));
      }
    } else if (identifierOrInvoke is MethodInvocation) {
      assert(identifierOrInvoke.target == null);
      identifierOrInvoke
        ..target = receiver
        ..operator = token;
      push(identifierOrInvoke);
    } else {
      unhandled("${identifierOrInvoke.runtimeType}", "property access",
          token.charOffset, uri);
    }
  }

  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    push(ast.integerLiteral(token, int.parse(token.lexeme)));
  }

  void handleExpressionFunctionBody(Token arrowToken, Token endToken) {
    debugEvent("ExpressionFunctionBody");
    Expression expression = pop();
    Token star = pop();
    Token asyncKeyword = pop();
    assert(star == null);
    push(ast.expressionFunctionBody(
        asyncKeyword, arrowToken, expression, endToken));
  }

  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    debugEvent("ReturnStatement");
    Expression expression = hasExpression ? pop() : null;
    push(ast.returnStatement(beginToken, expression, endToken));
  }

  void endIfStatement(Token ifToken, Token elseToken) {
    Statement elsePart = popIfNotNull(elseToken);
    Statement thenPart = pop();
    ParenthesizedExpression condition = pop();
    push(ast.ifStatement(ifToken, condition.leftParenthesis, condition,
        condition.rightParenthesis, thenPart, elseToken, elsePart));
  }

  void handleNoInitializers() {
    debugEvent("NoInitializers");
    if (!isFullAst) return;
    push(NullValue.ConstructorInitializerSeparator);
    push(NullValue.ConstructorInitializers);
  }

  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    List<Object> initializerObjects = popList(count) ?? const [];
    if (!isFullAst) return;

    push(beginToken);

    var initializers = <ConstructorInitializer>[];
    for (Object initializerObject in initializerObjects) {
      if (initializerObject is FunctionExpressionInvocation) {
        Expression function = initializerObject.function;
        if (function is SuperExpression) {
          initializers.add(ast.superConstructorInvocation(function.superKeyword,
              null, null, initializerObject.argumentList));
        } else {
          initializers.add(ast.redirectingConstructorInvocation(
              (function as ThisExpression).thisKeyword,
              null,
              null,
              initializerObject.argumentList));
        }
      } else if (initializerObject is MethodInvocation) {
        Expression target = initializerObject.target;
        if (target is SuperExpression) {
          initializers.add(ast.superConstructorInvocation(
              target.superKeyword,
              initializerObject.operator,
              initializerObject.methodName,
              initializerObject.argumentList));
        } else {
          initializers.add(ast.redirectingConstructorInvocation(
              (target as ThisExpression).thisKeyword,
              initializerObject.operator,
              initializerObject.methodName,
              initializerObject.argumentList));
        }
      } else if (initializerObject is AssignmentExpression) {
        Token thisKeyword;
        Token period;
        SimpleIdentifier fieldName;
        Expression left = initializerObject.leftHandSide;
        if (left is PropertyAccess) {
          var thisExpression = left.target as ThisExpression;
          thisKeyword = thisExpression.thisKeyword;
          period = left.operator;
          fieldName = left.propertyName;
        } else {
          fieldName = left as SimpleIdentifier;
        }
        initializers.add(ast.constructorFieldInitializer(
            thisKeyword,
            period,
            fieldName,
            initializerObject.operator,
            initializerObject.rightHandSide));
      } else if (initializerObject is AssertInitializer) {
        initializers.add(initializerObject);
      }
    }

    push(initializers);
  }

  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer");
    assert(assignmentOperator.stringValue == "=");
    Expression initializer = pop();
    Identifier identifier = pop();
    // TODO(ahe): Don't push initializers, instead install them.
    push(ast.variableDeclaration(identifier, assignmentOperator, initializer));
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    debugEvent("WhileStatement");
    Statement body = pop();
    ParenthesizedExpression condition = pop();
    exitContinueTarget();
    exitBreakTarget();
    push(ast.whileStatement(whileKeyword, condition.leftParenthesis,
        condition.expression, condition.rightParenthesis, body));
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    debugEvent("YieldStatement");
    assert(endToken.lexeme == ';');
    Expression expression = pop();
    push(ast.yieldStatement(yieldToken, starToken, expression, endToken));
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
  }

  void endInitializedIdentifier(Token nameToken) {
    debugEvent("InitializedIdentifier");
    AstNode node = pop();
    VariableDeclaration variable;
    // TODO(paulberry): This seems kludgy.  It would be preferable if we
    // could respond to a "handleNoVariableInitializer" event by converting a
    // SimpleIdentifier into a VariableDeclaration, and then when this code was
    // reached, node would always be a VariableDeclaration.
    if (node is VariableDeclaration) {
      variable = node;
    } else if (node is SimpleIdentifier) {
      variable = ast.variableDeclaration(node, null, null);
    } else {
      unhandled("${node.runtimeType}", "identifier", nameToken.charOffset, uri);
    }
    push(variable);
  }

  void endVariablesDeclaration(int count, Token endToken) {
    debugEvent("VariablesDeclaration");
    List<VariableDeclaration> variables = popList(count);
    TypeAnnotation type = pop();
    _Modifiers modifiers = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata,
        variables[0].beginToken ?? type?.beginToken ?? modifiers.beginToken);
    push(ast.variableDeclarationStatement(
        ast.variableDeclarationList(
            comment, metadata, keyword, type, variables),
        endToken));
  }

  void handleAssignmentExpression(Token token) {
    debugEvent("AssignmentExpression");
    Expression rhs = pop();
    Expression lhs = pop();
    push(ast.assignmentExpression(lhs, token, rhs));
  }

  void endBlock(int count, Token beginToken, Token endToken) {
    debugEvent("Block");
    List<Statement> statements = popList(count) ?? <Statement>[];
    exitLocalScope();
    push(ast.block(beginToken, statements, endToken));
  }

  void endForStatement(Token forKeyword, Token leftParen, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    debugEvent("ForStatement");
    Statement body = pop();
    List<Expression> updates = popList(updateExpressionCount);
    Statement conditionStatement = pop();
    Object initializerPart = pop();
    exitLocalScope();
    exitContinueTarget();
    exitBreakTarget();

    VariableDeclarationList variableList;
    Expression initializer;
    if (initializerPart is VariableDeclarationStatement) {
      variableList = initializerPart.variables;
    } else {
      initializer = initializerPart as Expression;
    }

    Expression condition;
    Token rightSeparator;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
      rightSeparator = conditionStatement.semicolon;
    } else {
      rightSeparator = (conditionStatement as EmptyStatement).semicolon;
    }

    push(ast.forStatement(
        forKeyword,
        leftParen,
        variableList,
        initializer,
        leftSeparator,
        condition,
        rightSeparator,
        updates,
        leftParen?.endGroup,
        body));
  }

  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    debugEvent("LiteralList");
    List<Expression> expressions = popList(count);
    TypeArgumentList typeArguments = pop();
    push(ast.listLiteral(
        constKeyword, typeArguments, beginToken, expressions, endToken));
  }

  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
    push(asyncToken ?? NullValue.FunctionBodyAsyncToken);
    push(starToken ?? NullValue.FunctionBodyStarToken);
  }

  void endAwaitExpression(Token beginToken, Token endToken) {
    debugEvent("AwaitExpression");
    push(ast.awaitExpression(beginToken, pop()));
  }

  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = identical(token.stringValue, "true");
    assert(value || identical(token.stringValue, "false"));
    push(ast.booleanLiteral(token, value));
  }

  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(ast.doubleLiteral(token, double.parse(token.lexeme)));
  }

  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(ast.nullLiteral(token));
  }

  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    debugEvent("LiteralMap");
    List<MapLiteralEntry> entries = popList(count) ?? <MapLiteralEntry>[];
    TypeArgumentList typeArguments = pop();
    push(ast.mapLiteral(
        constKeyword, typeArguments, beginToken, entries, endToken));
  }

  void endLiteralMapEntry(Token colon, Token endToken) {
    debugEvent("LiteralMapEntry");
    Expression value = pop();
    Expression key = pop();
    push(ast.mapLiteralEntry(key, colon, value));
  }

  void endLiteralSymbol(Token hashToken, int tokenCount) {
    debugEvent("LiteralSymbol");
    List<Token> components = popList(tokenCount);
    push(ast.symbolLiteral(hashToken, components));
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    debugEvent("SuperExpression");
    push(ast.superExpression(token));
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression");
    push(ast.thisExpression(token));
  }

  void handleType(Token beginToken, Token endToken) {
    debugEvent("Type");
    TypeArgumentList arguments = pop();
    Identifier name = pop();
    push(ast.typeName(name, arguments));
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token comma, Token semicolon) {
    debugEvent("Assert");
    Expression message = popIfNotNull(comma);
    Expression condition = pop();
    switch (kind) {
      case Assert.Expression:
        throw new UnimplementedError(
            'assert expressions are not yet supported');
        break;
      case Assert.Initializer:
        push(ast.assertInitializer(assertKeyword, leftParenthesis, condition,
            comma, message, leftParenthesis?.endGroup));
        break;
      case Assert.Statement:
        push(ast.assertStatement(assertKeyword, leftParenthesis, condition,
            comma, message, leftParenthesis?.endGroup, semicolon));
        break;
    }
  }

  void handleAsOperator(Token operator, Token endToken) {
    debugEvent("AsOperator");
    TypeAnnotation type = pop();
    Expression expression = pop();
    push(ast.asExpression(expression, operator, type));
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token semicolon) {
    debugEvent("BreakStatement");
    SimpleIdentifier label = hasTarget ? pop() : null;
    push(ast.breakStatement(breakKeyword, label, semicolon));
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token semicolon) {
    debugEvent("ContinueStatement");
    SimpleIdentifier label = hasTarget ? pop() : null;
    push(ast.continueStatement(continueKeyword, label, semicolon));
  }

  void handleIsOperator(Token operator, Token not, Token endToken) {
    debugEvent("IsOperator");
    TypeAnnotation type = pop();
    Expression expression = pop();
    push(ast.isExpression(expression, operator, not, type));
  }

  void endConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = pop();
    Expression thenExpression = pop();
    Expression condition = pop();
    push(ast.conditionalExpression(
        condition, question, thenExpression, colon, elseExpression));
  }

  @override
  void endRedirectingFactoryBody(Token equalToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    ConstructorName constructorName = pop();
    Token starToken = pop();
    Token asyncToken = pop();
    push(new _RedirectingFactoryBody(
        asyncToken, starToken, equalToken, constructorName));
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    debugEvent("RethrowStatement");
    RethrowExpression expression = ast.rethrowExpression(rethrowToken);
    // TODO(scheglov) According to the specification, 'rethrow' is a statement.
    push(ast.expressionStatement(expression, endToken));
  }

  void handleThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    push(ast.throwExpression(throwToken, pop()));
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    push(new _OptionalFormalParameters(popList(count), beginToken, endToken));
  }

  void handleValuedFormalParameter(Token equals, Token token) {
    debugEvent("ValuedFormalParameter");
    Expression value = pop();
    push(new _ParameterDefaultValue(equals, value));
  }

  @override
  void endFunctionType(Token functionToken, Token semicolon) {
    debugEvent("FunctionType");
    FormalParameterList parameters = pop();
    TypeAnnotation returnType = pop();
    TypeParameterList typeParameters = pop();
    push(ast.genericFunctionType(
        returnType, functionToken, typeParameters, parameters));
  }

  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
    push(NullValue.ParameterDefaultValue);
  }

  @override
  void endForInExpression(Token token) {
    debugEvent("ForInExpression");
  }

  @override
  void endForIn(Token awaitToken, Token forToken, Token leftParenthesis,
      Token inKeyword, Token endToken) {
    debugEvent("ForInExpression");
    Statement body = pop();
    Expression iterator = pop();
    Object variableOrDeclaration = pop();
    exitLocalScope();
    exitContinueTarget();
    exitBreakTarget();
    if (variableOrDeclaration is SimpleIdentifier) {
      push(ast.forEachStatementWithReference(
          awaitToken,
          forToken,
          leftParenthesis,
          variableOrDeclaration,
          inKeyword,
          iterator,
          leftParenthesis?.endGroup,
          body));
    } else {
      var statement = variableOrDeclaration as VariableDeclarationStatement;
      VariableDeclarationList variableList = statement.variables;
      push(ast.forEachStatementWithDeclaration(
          awaitToken,
          forToken,
          leftParenthesis,
          ast.declaredIdentifier(
              variableList.documentationComment,
              variableList.metadata,
              variableList.keyword,
              variableList.type,
              variableList.variables.single.name),
          inKeyword,
          iterator,
          leftParenthesis?.endGroup,
          body));
    }
  }

  void endFormalParameter(Token thisKeyword, Token nameToken,
      FormalParameterKind kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    _ParameterDefaultValue defaultValue = pop();

    SimpleIdentifier name = pop();

    AstNode typeOrFunctionTypedParameter = pop();

    _Modifiers modifiers = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    Token covariantKeyword = modifiers?.covariantKeyword;
    List<Annotation> metadata = pop(); // TODO(paulberry): Metadata.
    Comment comment = _findComment(metadata,
        thisKeyword ?? typeOrFunctionTypedParameter?.beginToken ?? nameToken);

    FormalParameter node;
    if (typeOrFunctionTypedParameter is FunctionTypedFormalParameter) {
      // This is a temporary AST node that was constructed in
      // [endFunctionTypedFormalParameter]. We now deconstruct it and create
      // the final AST node.
      if (thisKeyword == null) {
        node = ast.functionTypedFormalParameter2(
            identifier: name,
            comment: comment,
            covariantKeyword: covariantKeyword,
            returnType: typeOrFunctionTypedParameter.returnType,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters);
      } else {
        node = ast.fieldFormalParameter2(
            identifier: name,
            comment: comment,
            covariantKeyword: covariantKeyword,
            type: typeOrFunctionTypedParameter.returnType,
            thisKeyword: thisKeyword,
            period: unsafeToken(thisKeyword.next, TokenType.PERIOD),
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters);
      }
    } else {
      TypeAnnotation type = typeOrFunctionTypedParameter;
      if (thisKeyword == null) {
        node = ast.simpleFormalParameter2(
            comment: comment,
            covariantKeyword: covariantKeyword,
            keyword: keyword,
            type: type,
            identifier: name);
      } else {
        node = ast.fieldFormalParameter2(
            comment: comment,
            covariantKeyword: covariantKeyword,
            keyword: keyword,
            type: type,
            thisKeyword: thisKeyword,
            period: thisKeyword.next,
            identifier: name);
      }
    }

    ParameterKind analyzerKind = _toAnalyzerParameterKind(kind);
    if (analyzerKind != ParameterKind.REQUIRED) {
      node = ast.defaultFormalParameter(
          node, analyzerKind, defaultValue?.separator, defaultValue?.value);
    }
    push(node);
  }

  @override
  void endFunctionTypedFormalParameter() {
    debugEvent("FunctionTypedFormalParameter");

    FormalParameterList formalParameters = pop();
    TypeAnnotation returnType = pop();
    TypeParameterList typeParameters = pop();

    // Create a temporary formal parameter that will be dissected later in
    // [endFormalParameter].
    push(ast.functionTypedFormalParameter2(
        identifier: null,
        returnType: returnType,
        typeParameters: typeParameters,
        parameters: formalParameters));
  }

  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    List rawParameters = popList(count) ?? const <Object>[];
    List<FormalParameter> parameters = <FormalParameter>[];
    Token leftDelimiter;
    Token rightDelimiter;
    for (Object raw in rawParameters) {
      if (raw is _OptionalFormalParameters) {
        parameters.addAll(raw.parameters);
        leftDelimiter = raw.leftDelimiter;
        rightDelimiter = raw.rightDelimiter;
      } else {
        parameters.add(raw as FormalParameter);
      }
    }
    push(ast.formalParameterList(
        beginToken, parameters, leftDelimiter, rightDelimiter, endToken));
  }

  @override
  void endSwitchBlock(int caseCount, Token leftBracket, Token rightBracket) {
    debugEvent("SwitchBlock");
    List<List<SwitchMember>> membersList = popList(caseCount);
    exitBreakTarget();
    exitLocalScope();
    List<SwitchMember> members =
        membersList?.expand((members) => members)?.toList() ?? <SwitchMember>[];
    push(leftBracket);
    push(members);
    push(rightBracket);
  }

  @override
  void endSwitchCase(int labelCount, int expressionCount, Token defaultKeyword,
      int statementCount, Token firstToken, Token endToken) {
    debugEvent("SwitchCase");
    List<Statement> statements = popList(statementCount);
    List<SwitchMember> members = popList(expressionCount) ?? [];
    List<Label> labels = popList(labelCount);
    if (defaultKeyword != null) {
      members.add(ast.switchDefault(
          <Label>[], defaultKeyword, defaultKeyword.next, <Statement>[]));
    }
    members.last.statements.addAll(statements);
    members.first.labels.addAll(labels);
    push(members);
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    debugEvent("CaseMatch");
    Expression expression = pop();
    push(ast.switchCase(
        <Label>[], caseKeyword, expression, colon, <Statement>[]));
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");
    Token rightBracket = pop();
    List<SwitchMember> members = pop();
    Token leftBracket = pop();
    ParenthesizedExpression expression = pop();
    push(ast.switchStatement(
        switchKeyword,
        expression.leftParenthesis,
        expression.expression,
        expression.rightParenthesis,
        leftBracket,
        members,
        rightBracket));
  }

  void handleCatchBlock(Token onKeyword, Token catchKeyword, Token comma) {
    debugEvent("CatchBlock");
    Block body = pop();
    FormalParameterList catchParameterList = popIfNotNull(catchKeyword);
    TypeAnnotation type = popIfNotNull(onKeyword);
    SimpleIdentifier exception;
    SimpleIdentifier stackTrace;
    if (catchParameterList != null) {
      List<FormalParameter> catchParameters = catchParameterList.parameters;
      if (catchParameters.length > 0) {
        exception = catchParameters[0].identifier;
      }
      if (catchParameters.length > 1) {
        stackTrace = catchParameters[1].identifier;
      }
    }
    // TODO(brianwilkerson) The parser needs to pass in the comma token.
    push(ast.catchClause(
        onKeyword,
        type,
        catchKeyword,
        catchParameterList?.leftParenthesis,
        exception,
        comma,
        stackTrace,
        catchParameterList?.rightParenthesis,
        body));
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    debugEvent("FinallyBlock");
    // The finally block is popped in "endTryStatement".
  }

  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    Block finallyBlock = popIfNotNull(finallyKeyword);
    List<CatchClause> catchClauses = popList(catchCount);
    Block body = pop();
    push(ast.tryStatement(
        tryKeyword, body, catchClauses, finallyKeyword, finallyBlock));
  }

  @override
  void handleLabel(Token colon) {
    debugEvent("Label");
    SimpleIdentifier name = pop();
    push(ast.label(name, colon));
  }

  void handleNoExpression(Token token) {
    debugEvent("NoExpression");
    push(NullValue.Expression);
  }

  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    debugEvent("IndexedExpression");
    Expression index = pop();
    Expression target = pop();
    if (target == null) {
      CascadeExpression receiver = pop();
      Token token = peek();
      push(receiver);
      IndexExpression expression = ast.indexExpressionForCascade(
          token, openSquareBracket, index, closeSquareBracket);
      assert(expression.isCascaded);
      push(expression);
    } else {
      push(ast.indexExpressionForTarget(
          target, openSquareBracket, index, closeSquareBracket));
    }
  }

  @override
  void handleInvalidExpression(Token token) {
    debugEvent("InvalidExpression");
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    debugEvent("InvalidFunctionBody");
  }

  @override
  Token handleUnrecoverableError(Token token, Message message) {
    if (message.code == codeExpectedFunctionBody) {
      if (identical('native', token.stringValue) && parser != null) {
        Token nativeKeyword = token;
        Token semicolon = parser.parseLiteralString(token.next);
        // TODO(brianwilkerson) Should this be using ensureSemicolon?
        token = parser.expectSemicolon(semicolon);
        StringLiteral name = pop();
        pop(); // star
        pop(); // async
        push(ast.nativeFunctionBody(nativeKeyword, name, semicolon));
        return token;
      }
    } else if (message.code == codeExpectedExpression) {
      String lexeme = token.lexeme;
      if (identical('async', lexeme) || identical('yield', lexeme)) {
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER,
            token.charOffset,
            token.charCount);
        push(ast.simpleIdentifier(token));
        return token;
      }
    }
    return super.handleUnrecoverableError(token, message);
  }

  void handleUnaryPrefixExpression(Token token) {
    debugEvent("UnaryPrefixExpression");
    push(ast.prefixExpression(token, pop()));
  }

  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression");
    push(ast.prefixExpression(token, pop()));
  }

  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression");
    push(ast.postfixExpression(pop(), token));
  }

  void handleModifier(Token token) {
    debugEvent("Modifier");
    push(token);
  }

  void handleModifiers(int count) {
    debugEvent("Modifiers");
    if (count == 0) {
      push(NullValue.Modifiers);
    } else {
      push(new _Modifiers(popList(count)));
    }
  }

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.
    debugEvent("TopLevelMethod");
    FunctionBody body = pop();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    TypeAnnotation returnType = pop();
    _Modifiers modifiers = pop();
    Token externalKeyword = modifiers?.externalKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    if (getOrSet != null && optional('get', getOrSet)) {
      parameters = null;
    }
    declarations.add(ast.functionDeclaration(
        comment,
        metadata,
        externalKeyword,
        returnType,
        getOrSet,
        name,
        ast.functionExpression(typeParameters, parameters, body)));
  }

  @override
  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration");
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
    // TODO(danrubel): consider creating a AST node
    // representing the invalid declaration to better support code completion,
    // quick fixes, etc, rather than discarding the metadata and token
  }

  @override
  void beginCompilationUnit(Token token) {
    push(token);
  }

  @override
  void endCompilationUnit(int count, Token endToken) {
    debugEvent("CompilationUnit");
    Token beginToken = pop();
    checkEmpty(endToken.charOffset);

    push(ast.compilationUnit(
        beginToken, scriptTag, directives, declarations, endToken));
  }

  @override
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
    debugEvent("ImportPrefix");
    if (asKeyword == null) {
      // If asKeyword is null, then no prefix has been pushed on the stack.
      // Push a placeholder indicating that there is no prefix.
      push(NullValue.Prefix);
      push(NullValue.As);
    } else {
      push(asKeyword);
    }
    push(deferredKeyword ?? NullValue.Deferred);
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    debugEvent("Import");
    List<Combinator> combinators = pop();
    Token deferredKeyword = pop(NullValue.Deferred);
    Token asKeyword = pop(NullValue.As);
    SimpleIdentifier prefix = pop(NullValue.Prefix);
    List<Configuration> configurations = pop();
    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    assert(metadata == null); // TODO(paulberry): fix.
    Comment comment = _findComment(metadata, importKeyword);

    directives.add(ast.importDirective(
        comment,
        metadata,
        importKeyword,
        uri,
        configurations,
        deferredKeyword,
        asKeyword,
        prefix,
        combinators,
        semicolon));
  }

  @override
  void handleRecoverImport(Token semicolon) {
    debugEvent("RecoverImport");
    List<Combinator> combinators = pop();
    Token deferredKeyword = pop(NullValue.Deferred);
    Token asKeyword = pop(NullValue.As);
    SimpleIdentifier prefix = pop(NullValue.Prefix);
    List<Configuration> configurations = pop();

    ImportDirective directive = directives.last;
    if (combinators != null) {
      directive.combinators.addAll(combinators);
    }
    directive.deferredKeyword ??= deferredKeyword;
    if (directive.asKeyword == null && asKeyword != null) {
      directive.asKeyword = asKeyword;
      directive.prefix = prefix;
    }
    if (configurations != null) {
      directive.configurations.addAll(configurations);
    }
    directive.semicolon = semicolon;
  }

  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
    List<Combinator> combinators = pop();
    List<Configuration> configurations = pop();
    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    assert(metadata == null);
    Comment comment = _findComment(metadata, exportKeyword);
    directives.add(ast.exportDirective(comment, metadata, exportKeyword, uri,
        configurations, combinators, semicolon));
  }

  @override
  void endDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    List<SimpleIdentifier> components = popList(count);
    push(ast.dottedName(components));
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token semicolon) {
    debugEvent("DoWhileStatement");
    ParenthesizedExpression condition = pop();
    Statement body = pop();
    exitContinueTarget();
    exitBreakTarget();
    push(ast.doStatement(
        doKeyword,
        body,
        whileKeyword,
        condition.leftParenthesis,
        condition.expression,
        condition.rightParenthesis,
        semicolon));
  }

  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    debugEvent("ConditionalUri");
    StringLiteral libraryUri = pop();
    StringLiteral value = popIfNotNull(equalSign);
    DottedName name = pop();
    push(ast.configuration(ifKeyword, leftParen, name, equalSign, value,
        leftParen?.endGroup, libraryUri));
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");
    push(popList(count) ?? NullValue.ConditionalUris);
  }

  @override
  void endIdentifierList(int count) {
    debugEvent("IdentifierList");
    push(popList(count) ?? NullValue.IdentifierList);
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
    List<SimpleIdentifier> shownNames = pop();
    push(ast.showCombinator(showKeyword, shownNames));
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("Hide");
    List<SimpleIdentifier> hiddenNames = pop();
    push(ast.hideCombinator(hideKeyword, hiddenNames));
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popList(count) ?? NullValue.TypeList);
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
    ClassDeclaration classDeclaration = declarations.last;
    classDeclaration.leftBracket = beginToken;
    NodeListImpl<ClassMember> members = classDeclaration.members;
    members.setLength(memberCount);
    popList(memberCount, members);
    classDeclaration.rightBracket = endToken;
  }

  @override
  void beginClassDeclaration(Token beginToken, Token name) {
    assert(className == null);
    className = name.lexeme;
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    ExtendsClause extendsClause;
    WithClause withClause;
    var supertype = pop();
    if (supertype == null) {
      // No extends clause
    } else if (supertype is TypeName) {
      extendsClause = ast.extendsClause(extendsKeyword, supertype);
    } else if (supertype is _MixinApplication) {
      extendsClause = ast.extendsClause(extendsKeyword, supertype.supertype);
      withClause = ast.withClause(supertype.withKeyword, supertype.mixinTypes);
    } else {
      unhandled("${supertype.runtimeType}", "supertype",
          extendsKeyword.charOffset, uri);
    }
    push(extendsClause ?? NullValue.ExtendsClause);
    push(withClause ?? NullValue.WithClause);
  }

  @override
  void handleClassImplements(Token implementsKeyword, int interfacesCount) {
    if (implementsKeyword != null) {
      List<TypeName> interfaces = popList(interfacesCount);
      push(ast.implementsClause(implementsKeyword, interfaces));
    } else {
      push(NullValue.IdentifierList);
    }
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    debugEvent("ClassHeader");
    NativeClause nativeClause;
    if (nativeToken != null) {
      nativeClause = ast.nativeClause(nativeToken, nativeName);
    }
    ImplementsClause implementsClause = pop(NullValue.IdentifierList);
    WithClause withClause = pop(NullValue.WithClause);
    ExtendsClause extendsClause = pop(NullValue.ExtendsClause);
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    assert(className == name.name);
    _Modifiers modifiers = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, classKeyword);
    // leftBracket, members, and rightBracket are set in [endClassBody].
    ClassDeclaration classDeclaration = ast.classDeclaration(
      comment,
      metadata,
      abstractKeyword,
      classKeyword,
      name,
      typeParameters,
      extendsClause,
      withClause,
      implementsClause,
      null, // leftBracket
      <ClassMember>[],
      null, // rightBracket
    );
    classDeclaration.nativeClause = nativeClause;
    declarations.add(classDeclaration);
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("RecoverClassHeader");
    ImplementsClause implementsClause = pop(NullValue.IdentifierList);
    WithClause withClause = pop(NullValue.WithClause);
    ExtendsClause extendsClause = pop(NullValue.ExtendsClause);
    ClassDeclaration declaration = declarations.last;
    if (extendsClause != null && !extendsClause.extendsKeyword.isSynthetic) {
      if (declaration.extendsClause?.superclass == null) {
        declaration.extendsClause = extendsClause;
      }
    }
    if (withClause != null) {
      if (declaration.withClause == null) {
        declaration.withClause = withClause;
      } else {
        declaration.withClause.mixinTypes.addAll(withClause.mixinTypes);
      }
    }
    if (implementsClause != null) {
      if (declaration.implementsClause == null) {
        declaration.implementsClause = implementsClause;
      } else {
        declaration.implementsClause.interfaces
            .addAll(implementsClause.interfaces);
      }
    }
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("ClassDeclaration");
    className = null;
  }

  @override
  void endMixinApplication(Token withKeyword) {
    debugEvent("MixinApplication");
    List<TypeName> mixinTypes = pop();
    TypeName supertype = pop();
    push(new _MixinApplication(supertype, withKeyword, mixinTypes));
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equalsToken, Token implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication");
    ImplementsClause implementsClause;
    if (implementsKeyword != null) {
      List<TypeName> interfaces = pop();
      implementsClause = ast.implementsClause(implementsKeyword, interfaces);
    }
    _MixinApplication mixinApplication = pop();
    var superclass = mixinApplication.supertype;
    var withClause = ast.withClause(
        mixinApplication.withKeyword, mixinApplication.mixinTypes);
    Token equals = equalsToken;
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    _Modifiers modifiers = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    declarations.add(ast.classTypeAlias(
        comment,
        metadata,
        classKeyword,
        name,
        typeParameters,
        equals,
        abstractKeyword,
        superclass,
        withClause,
        implementsClause,
        endToken));
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");
    Statement statement = pop();
    List<Label> labels = popList(labelCount);
    push(ast.labeledStatement(labels, statement));
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("LibraryName");
    List<SimpleIdentifier> libraryName = pop();
    var name = ast.libraryIdentifier(libraryName);
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, libraryKeyword);
    directives.add(ast.libraryDirective(
        comment, metadata, libraryKeyword, name, semicolon));
  }

  @override
  void handleRecoverableError(Token token, Message message) {
    /// TODO(danrubel): Ignore this error until we deprecate `native` support.
    if (message == messageNativeClauseShouldBeAnnotation && allowNativeClause) {
      return;
    }
    debugEvent("Error: ${message.message}");
    addCompileTimeErrorWithLength(message, token.offset, token.length);
  }

  @override
  void handleQualified(Token period) {
    SimpleIdentifier identifier = pop();
    var prefix = pop();
    if (prefix is List) {
      // We're just accumulating components into a list.
      prefix.add(identifier);
      push(prefix);
    } else if (prefix is SimpleIdentifier) {
      // TODO(paulberry): resolve [identifier].  Note that BodyBuilder handles
      // this situation using SendAccessor.
      push(ast.prefixedIdentifier(prefix, period, identifier));
    } else {
      // TODO(paulberry): implement.
      logEvent('Qualified with >1 dot');
    }
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");
    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, partKeyword);
    directives
        .add(ast.partDirective(comment, metadata, partKeyword, uri, semicolon));
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    debugEvent("PartOf");
    var libraryNameOrUri = pop();
    LibraryIdentifier name;
    StringLiteral uri;
    if (libraryNameOrUri is StringLiteral) {
      uri = libraryNameOrUri;
    } else {
      name = ast.libraryIdentifier(libraryNameOrUri);
    }
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, partKeyword);
    directives.add(ast.partOfDirective(
        comment, metadata, partKeyword, ofKeyword, uri, name, semicolon));
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.  Note that this is tricky due to the handling of initializers
    // in constructors, so the logic should be shared with BodyBuilder as much
    // as possible.
    debugEvent("FunctionExpression");
    FunctionBody body = pop();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    push(ast.functionExpression(typeParameters, parameters, body));
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    SimpleIdentifier name = pop();
    push(ast.variableDeclaration(name, null, null));
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token semicolon) {
    debugEvent("FactoryMethod");

    FunctionBody body;
    Token separator;
    ConstructorName redirectedConstructor;
    Object bodyObject = pop();
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      separator = bodyObject.equalToken;
      redirectedConstructor = bodyObject.constructorName;
      body = ast.emptyFunctionBody(semicolon);
    } else {
      unhandled("${bodyObject.runtimeType}", "bodyObject",
          beginToken.charOffset, uri);
    }

    FormalParameterList parameters = pop();
    ConstructorName constructorName = pop();
    _Modifiers modifiers = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);

    // Decompose the preliminary ConstructorName into the type name and
    // the actual constructor name.
    SimpleIdentifier returnType;
    Token period;
    SimpleIdentifier name;
    Identifier typeName = constructorName.type.name;
    if (typeName is SimpleIdentifier) {
      returnType = typeName;
    } else if (typeName is PrefixedIdentifier) {
      returnType = typeName.prefix;
      period = typeName.period;
      name =
          ast.simpleIdentifier(typeName.identifier.token, isDeclaration: true);
    }

    push(ast.constructorDeclaration(
        comment,
        metadata,
        modifiers?.externalKeyword,
        modifiers?.finalConstOrVarKeyword,
        factoryKeyword,
        ast.simpleIdentifier(returnType.token),
        period,
        name,
        parameters,
        separator,
        null,
        redirectedConstructor,
        body));
  }

  void endFieldInitializer(Token assignment, Token token) {
    debugEvent("FieldInitializer");
    Expression initializer = pop();
    SimpleIdentifier name = pop();
    push(ast.variableDeclaration(name, assignment, initializer));
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    // TODO(scheglov): The logEvent() invocation is commented because it
    // spams to the console. We already know that these test fail, uncomment
    // when you are working on fixing them.
//    logEvent("NamedFunctionExpression");
    unhandled("NamedFunctionExpression", "$runtimeType", -1, uri);
  }

  @override
  void endLocalFunctionDeclaration(Token token) {
    debugEvent("LocalFunctionDeclaration");
    FunctionBody body = pop();
    if (isFullAst) {
      pop(); // constructor initializers
      pop(); // separator before constructor initializers
    }
    FormalParameterList parameters = pop();
    SimpleIdentifier name = pop();
    TypeAnnotation returnType = pop();
    pop(); // modifiers
    TypeParameterList typeParameters = pop();
    FunctionExpression functionExpression =
        ast.functionExpression(typeParameters, parameters, body);
    push(ast.functionDeclarationStatement(ast.functionDeclaration(
        null, null, null, returnType, null, name, functionExpression)));
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
  }

  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("TopLevelFields");
    List<VariableDeclaration> variables = popList(count);
    TypeAnnotation type = pop();
    _Modifiers modifiers = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    var variableList =
        ast.variableDeclarationList(null, null, keyword, type, variables);
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    declarations.add(ast.topLevelVariableDeclaration(
        comment, metadata, variableList, endToken));
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.  Note that this is tricky due to the handling of initializers
    // in constructors, so the logic should be shared with BodyBuilder as much
    // as possible.
    debugEvent("TypeVariable");
    TypeAnnotation bound = pop();
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, name.beginToken);
    push(ast.typeParameter(comment, metadata, name, extendsOrSuper, bound));
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    List<TypeParameter> typeParameters = popList(count);
    push(ast.typeParameterList(beginToken, typeParameters, endToken));
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    debugEvent("Method");
    FunctionBody body = pop();
    ConstructorName redirectedConstructor = null; // TODO(paulberry)
    List<ConstructorInitializer> initializers = pop() ?? const [];
    Token separator = pop();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    var name = pop();
    TypeAnnotation returnType = pop();
    _Modifiers modifiers = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);

    void constructor(
        SimpleIdentifier returnType, Token period, SimpleIdentifier name) {
      push(ast.constructorDeclaration(
          comment,
          metadata,
          modifiers?.externalKeyword,
          modifiers?.finalConstOrVarKeyword,
          null, // TODO(paulberry): factoryKeyword
          ast.simpleIdentifier(returnType.token),
          period,
          name,
          parameters,
          separator,
          initializers,
          redirectedConstructor,
          body));
    }

    void method(Token operatorKeyword, SimpleIdentifier name) {
      push(ast.methodDeclaration(
          comment,
          metadata,
          modifiers?.externalKeyword,
          modifiers?.abstractKeyword ?? modifiers?.staticKeyword,
          returnType,
          getOrSet,
          operatorKeyword,
          name,
          typeParameters,
          parameters,
          body));
    }

    if (name is SimpleIdentifier) {
      if (name.name == className) {
        constructor(name, null, null);
      } else {
        method(null, name);
      }
    } else if (name is _OperatorName) {
      method(name.operatorKeyword, name.name);
    } else if (name is PrefixedIdentifier) {
      constructor(name.prefix, name.period, name.identifier);
    } else {
      throw new UnimplementedError();
    }
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    // TODO(paulberry): is this sufficient, or do we need to hook the "void"
    // keyword up to an element?
    handleIdentifier(token, IdentifierContext.typeReference);
    handleNoTypeArguments(token);
    handleType(token, token);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("FunctionTypeAlias");
    if (equals == null) {
      FormalParameterList parameters = pop();
      TypeParameterList typeParameters = pop();
      SimpleIdentifier name = pop();
      TypeAnnotation returnType = pop();
      List<Annotation> metadata = pop();
      Comment comment = _findComment(metadata, typedefKeyword);
      declarations.add(ast.functionTypeAlias(comment, metadata, typedefKeyword,
          returnType, name, typeParameters, parameters, endToken));
    } else {
      TypeAnnotation type = pop();
      TypeParameterList templateParameters = pop();
      SimpleIdentifier name = pop();
      List<Annotation> metadata = pop();
      Comment comment = _findComment(metadata, typedefKeyword);
      if (type is! GenericFunctionType) {
        // TODO(paulberry) Generate an error and recover (better than
        // this).
        type = null;
      }
      declarations.add(ast.genericTypeAlias(comment, metadata, typedefKeyword,
          name, templateParameters, equals, type, endToken));
    }
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("Enum");
    List<EnumConstantDeclaration> constants = popList(count);
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, enumKeyword);
    declarations.add(ast.enumDeclaration(comment, metadata, enumKeyword, name,
        leftBrace, constants, leftBrace?.endGroup));
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    List<TypeAnnotation> arguments = popList(count);
    push(ast.typeArgumentList(beginToken, arguments, endToken));
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    List<VariableDeclaration> variables = popList(count);
    TypeAnnotation type = pop();
    _Modifiers modifiers = pop();
    var variableList = ast.variableDeclarationList(
        null, null, modifiers?.finalConstOrVarKeyword, type, variables);
    Token covariantKeyword = modifiers?.covariantKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    push(ast.fieldDeclaration2(
        comment: comment,
        metadata: metadata,
        covariantKeyword: covariantKeyword,
        staticKeyword: modifiers?.staticKeyword,
        fieldList: variableList,
        semicolon: endToken));
  }

  @override
  AstNode finishFields() {
    debugEvent("finishFields");
    return declarations.removeLast();
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(new _OperatorName(
        operatorKeyword, ast.simpleIdentifier(token, isDeclaration: true)));
  }

  @override
  void beginMetadataStar(Token token) {
    debugEvent("beginMetadataStar");
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    MethodInvocation invocation = pop();
    SimpleIdentifier constructorName = periodBeforeName != null ? pop() : null;
    pop(); // Type arguments, not allowed.
    Identifier name = pop();
    push(ast.annotation(beginToken, name, periodBeforeName, constructorName,
        invocation?.argumentList));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(popList(count) ?? NullValue.Metadata);
  }

  ParameterKind _toAnalyzerParameterKind(FormalParameterKind type) {
    if (type == FormalParameterKind.optionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (type == FormalParameterKind.optionalNamed) {
      return ParameterKind.NAMED;
    } else {
      return ParameterKind.REQUIRED;
    }
  }

  Comment _findComment(List<Annotation> metadata, Token tokenAfterMetadata) {
    Token commentsOnNext = tokenAfterMetadata?.precedingComments;
    if (commentsOnNext != null) {
      Comment comment = _parseDocumentationCommentOpt(commentsOnNext);
      if (comment != null) {
        return comment;
      }
    }
    if (metadata != null) {
      for (Annotation annotation in metadata) {
        Token commentsBeforeAnnotation =
            annotation.beginToken.precedingComments;
        if (commentsBeforeAnnotation != null) {
          Comment comment =
              _parseDocumentationCommentOpt(commentsBeforeAnnotation);
          if (comment != null) {
            return comment;
          }
        }
      }
    }
    return null;
  }

  /**
   * Parse a documentation comment. Return the documentation comment that was
   * parsed, or `null` if there was no comment.
   */
  Comment _parseDocumentationCommentOpt(CommentToken commentToken) {
    List<Token> tokens = <Token>[];
    while (commentToken != null) {
      if (commentToken.lexeme.startsWith('/**') ||
          commentToken.lexeme.startsWith('///')) {
        if (tokens.isNotEmpty) {
          if (commentToken.type == TokenType.SINGLE_LINE_COMMENT) {
            if (tokens[0].type != TokenType.SINGLE_LINE_COMMENT) {
              tokens.clear();
            }
          } else {
            tokens.clear();
          }
        }
        tokens.add(commentToken);
      }
      commentToken = commentToken.next;
    }
    // TODO(brianwilkerson) Use the code in analyzer's parser to parse the
    // references inside the comment.
    List<CommentReference> references = <CommentReference>[];
    return tokens.isEmpty ? null : ast.documentationComment(tokens, references);
  }

  @override
  void debugEvent(String name) {
    // printEvent('AstBuilder: $name');
  }

  @override
  Token injectGenericCommentTypeAssign(Token token) {
    // TODO(paulberry,scheglov,ahe): figure out how to share these generic
    // comment methods with BodyBuilder.
    return _injectGenericComment(
        token, TokenType.GENERIC_METHOD_TYPE_ASSIGN, 3);
  }

  @override
  Token injectGenericCommentTypeList(Token token) {
    return _injectGenericComment(token, TokenType.GENERIC_METHOD_TYPE_LIST, 2);
  }

  @override
  Token replaceTokenWithGenericCommentTypeAssign(
      Token tokenToStartReplacing, Token tokenWithComment) {
    Token injected = injectGenericCommentTypeAssign(tokenWithComment);
    if (!identical(injected, tokenWithComment)) {
      Token prev = tokenToStartReplacing.previous;
      prev.setNextWithoutSettingPrevious(injected);
      tokenToStartReplacing = injected;
      tokenToStartReplacing.previous = prev;
    }
    return tokenToStartReplacing;
  }

  @override
  void discardTypeReplacedWithCommentTypeAssign() {
    pop();
  }

  /// Check if the given [token] has a comment token with the given [type],
  /// which should be either [TokenType.GENERIC_METHOD_TYPE_ASSIGN] or
  /// [TokenType.GENERIC_METHOD_TYPE_LIST].  If found, parse the comment
  /// into tokens and inject into the token stream before the [token].
  Token _injectGenericComment(Token token, TokenType type, int prefixLen) {
    if (parseGenericMethodComments) {
      CommentToken t = token.precedingComments;
      for (; t != null; t = t.next) {
        if (t.type == type) {
          String code = t.lexeme.substring(prefixLen, t.lexeme.length - 2);
          Token tokens = _scanGenericMethodComment(code, t.offset + prefixLen);
          if (tokens != null) {
            // Remove the token from the comment stream.
            t.remove();
            // Insert the tokens into the stream.
            _injectTokenList(token, tokens);
            return tokens;
          }
        }
      }
    }
    return token;
  }

  void _injectTokenList(Token beforeToken, Token firstToken) {
    // Scanner creates a cyclic EOF token.
    Token lastToken = firstToken;
    while (lastToken.next.type != TokenType.EOF) {
      lastToken = lastToken.next;
    }
    // Inject these new tokens into the stream.
    Token previous = beforeToken.previous;
    lastToken.setNext(beforeToken);
    previous.setNext(firstToken);
    beforeToken = firstToken;
  }

  /// Scans the given [code], and returns the tokens, otherwise returns `null`.
  Token _scanGenericMethodComment(String code, int offset) {
    var scanner = new SubStringScanner(offset, code);
    Token firstToken = scanner.tokenize();
    if (scanner.hasErrors) {
      return null;
    }
    return firstToken;
  }

  @override
  void addCompileTimeError(Message message, int charOffset) {
    addCompileTimeErrorWithLength(message, charOffset, 1);
  }

  void addCompileTimeErrorWithLength(Message message, int offset, int length) {
    Code code = message.code;
    Map<String, dynamic> arguments = message.arguments;

    String stringOrTokenLexeme() {
      var text = arguments['string'];
      if (text == null) {
        Token token = arguments['token'];
        if (token != null) {
          text = token.lexeme;
        }
      }
      return text;
    }

    switch (code.analyzerCode) {
      case "ABSTRACT_CLASS_MEMBER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ABSTRACT_CLASS_MEMBER, offset, length);
        return;
      case "ANNOTATION_ON_ENUM_CONSTANT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ANNOTATION_ON_ENUM_CONSTANT, offset, length);
        return;
      case "ASYNC_FOR_IN_WRONG_CONTEXT":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT, offset, length);
        return;
      case "ASYNC_KEYWORD_USED_AS_IDENTIFIER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, offset, length);
        return;
      case "BUILT_IN_IDENTIFIER_AS_TYPE":
        String name = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE,
            offset,
            length,
            [name]);
        return;
      case "COLON_IN_PLACE_OF_IN":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COLON_IN_PLACE_OF_IN, offset, length);
        return;
      case "CONST_AND_COVARIANT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_AND_COVARIANT, offset, length);
        return;
      case "CONST_AND_FINAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_AND_FINAL, offset, length);
        return;
      case "CONST_AND_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_AND_VAR, offset, length);
        return;
      case "CONST_CLASS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_CLASS, offset, length);
        return;
      case "CONST_NOT_INITIALIZED":
        String name = arguments['name'];
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.CONST_NOT_INITIALIZED, offset, length, [name]);
        return;
      case "COVARIANT_AFTER_FINAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COVARIANT_AFTER_FINAL, offset, length);
        return;
      case "COVARIANT_AFTER_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COVARIANT_AFTER_VAR, offset, length);
        return;
      case "COVARIANT_AND_STATIC":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COVARIANT_AND_STATIC, offset, length);
        return;
      case "DEFAULT_VALUE_IN_FUNCTION_TYPE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, offset, length);
        return;
      case "DEFERRED_AFTER_PREFIX":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DEFERRED_AFTER_PREFIX, offset, length);
        return;
      case "DIRECTIVE_AFTER_DECLARATION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, offset, length);
        return;
      case "DUPLICATE_DEFERRED":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DUPLICATE_DEFERRED, offset, length);
        return;
      case "DUPLICATED_MODIFIER":
        String text = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DUPLICATED_MODIFIER, offset, length, [text]);
        return;
      case "DUPLICATE_PREFIX":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DUPLICATE_PREFIX, offset, length);
        return;
      case "EMPTY_ENUM_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EMPTY_ENUM_BODY, offset, length);
        return;
      case "EXPECTED_EXECUTABLE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_EXECUTABLE, offset, length);
        return;
      case "EXPECTED_STRING_LITERAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_STRING_LITERAL, offset, length);
        return;
      case "EXPECTED_TYPE_NAME":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_TYPE_NAME, offset, length);
        return;
      case "EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
            offset,
            length);
        return;
      case "EXTERNAL_CLASS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_CLASS, offset, length);
        return;
      case "EXTERNAL_ENUM":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_ENUM, offset, length);
        return;
      case "EXTERNAL_METHOD_WITH_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, offset, length);
        return;
      case "EXTERNAL_TYPEDEF":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_TYPEDEF, offset, length);
        return;
      case "EXTRANEOUS_MODIFIER":
        String text = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTRANEOUS_MODIFIER, offset, length, [text]);
        return;
      case "FACTORY_TOP_LEVEL_DECLARATION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, offset, length);
        return;
      case "FINAL_AND_COVARIANT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.FINAL_AND_COVARIANT, offset, length);
        return;
      case "FINAL_AND_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.FINAL_AND_VAR, offset, length);
        return;
      case "FINAL_NOT_INITIALIZED":
        String name = arguments['name'];
        errorReporter?.reportErrorForOffset(
            StaticWarningCode.FINAL_NOT_INITIALIZED, offset, length, [name]);
        return;
      case "GETTER_WITH_PARAMETERS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.GETTER_WITH_PARAMETERS, offset, length);
        return;
      case "ILLEGAL_CHARACTER":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.ILLEGAL_CHARACTER, offset, length);
        return;
      case "INVALID_AWAIT_IN_FOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.INVALID_AWAIT_IN_FOR, offset, length);
        return;
      case "IMPLEMENTS_BEFORE_EXTENDS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS, offset, length);
        return;
      case "IMPLEMENTS_BEFORE_WITH":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.IMPLEMENTS_BEFORE_WITH, offset, length);
        return;
      case "IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
            offset,
            length);
        return;
      case "INVALID_MODIFIER_ON_SETTER":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, offset, length);
        return;
      case "INVALID_OPERATOR_FOR_SUPER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, offset, length);
        return;
      case "LIBRARY_DIRECTIVE_NOT_FIRST":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, offset, length);
        return;
      case "MISSING_CATCH_OR_FINALLY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_CATCH_OR_FINALLY, offset, length);
        return;
      case "MISSING_CLASS_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_CLASS_BODY, offset, length);
        return;
//      case "MISSING_CONST_FINAL_VAR_OR_TYPE":
//        errorReporter?.reportErrorForOffset(
//            ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, offset, length);
//        return;
      case "MISSING_DIGIT":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.MISSING_DIGIT, offset, length);
        return;
      case "MISSING_HEX_DIGIT":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.MISSING_HEX_DIGIT, offset, length);
        return;
      case "MISSING_STAR_AFTER_SYNC":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_STAR_AFTER_SYNC, offset, length);
        return;
      case "MULTIPLE_EXTENDS_CLAUSES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES, offset, length);
        return;
      case "MULTIPLE_IMPLEMENTS_CLAUSES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES, offset, length);
        return;
      case "MULTIPLE_LIBRARY_DIRECTIVES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES, offset, length);
        return;
      case "MULTIPLE_WITH_CLAUSES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_WITH_CLAUSES, offset, length);
        return;
      case "MISSING_FUNCTION_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_FUNCTION_BODY, offset, length);
        return;
      case "MISSING_FUNCTION_PARAMETERS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_FUNCTION_PARAMETERS, offset, length);
        return;
      case "MISSING_IDENTIFIER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_IDENTIFIER, offset, length);
        return;
      case "MISSING_PREFIX_IN_DEFERRED_IMPORT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT, offset, length);
        return;
      case "MULTIPLE_PART_OF_DIRECTIVES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES, offset, length);
        return;
      case "NAMED_FUNCTION_EXPRESSION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.NAMED_FUNCTION_EXPRESSION, offset, length);
        return;
      case "NATIVE_CLAUSE_SHOULD_BE_ANNOTATION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, offset, length);
        return;
      case "NON_PART_OF_DIRECTIVE_IN_PART":
        if (directives.isEmpty) {
          errorReporter?.reportErrorForOffset(
              ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, offset, length);
        } else {
          errorReporter?.reportErrorForOffset(
              ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, offset, length);
        }
        return;
      case "PREFIX_AFTER_COMBINATOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.PREFIX_AFTER_COMBINATOR, offset, length);
        return;
      case "RETURN_IN_GENERATOR":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.RETURN_IN_GENERATOR, offset, length);
        return;
      case "STATIC_AFTER_FINAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.STATIC_AFTER_FINAL, offset, length);
        return;
      case "TOP_LEVEL_OPERATOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.TOP_LEVEL_OPERATOR, offset, length);
        return;
      case "UNEXPECTED_TOKEN":
        String text = stringOrTokenLexeme();
        if (text == ';') {
          errorReporter?.reportErrorForOffset(
              ParserErrorCode.EXPECTED_TOKEN, offset, length, [text]);
        } else {
          errorReporter?.reportErrorForOffset(
              ParserErrorCode.UNEXPECTED_TOKEN, offset, length, [text]);
        }
        return;
      case "UNTERMINATED_MULTI_LINE_COMMENT":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT, offset, length);
        return;
      case "UNTERMINATED_STRING_LITERAL":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.UNTERMINATED_STRING_LITERAL, offset, length);
        return;
      case "VAR_AND_TYPE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.VAR_AND_TYPE, offset, length);
        return;
      case "WITH_BEFORE_EXTENDS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.WITH_BEFORE_EXTENDS, offset, length);
        return;
      case "WITH_WITHOUT_EXTENDS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.WITH_WITHOUT_EXTENDS, offset, length);
        return;
      case "WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
            offset,
            length);
        return;
      case "WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER,
            offset,
            length);
        return;
      case "YIELD_IN_NON_GENERATOR":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.YIELD_IN_NON_GENERATOR, offset, length);
        return;
      default:
      // fall through
    }
  }

  /// A marker method used to mark locations where a token is being located in
  /// an unsafe way. In all such cases the parser needs to be fixed to pass in
  /// the token.
  Token unsafeToken(Token token, TokenType tokenType) {
    // TODO(brianwilkerson) Eliminate the need for this method.
    return token.type == tokenType ? token : null;
  }
}

/// Data structure placed on the stack to represent a mixin application (a
/// structure of the form "A with B, C").
///
/// This is needed because analyzer has no separate AST representation of a
/// mixin application; it simply stores all of the relevant data in the
/// [ClassDeclaration] or [ClassTypeAlias] object.
class _MixinApplication {
  final TypeName supertype;

  final Token withKeyword;

  final List<TypeName> mixinTypes;

  _MixinApplication(this.supertype, this.withKeyword, this.mixinTypes);
}

/// Data structure placed on the stack to represent the default parameter
/// value with the separator token.
class _ParameterDefaultValue {
  final Token separator;
  final Expression value;

  _ParameterDefaultValue(this.separator, this.value);
}

/// Data structure placed on stack to represent the redirected constructor.
class _RedirectingFactoryBody {
  final Token asyncKeyword;
  final Token starKeyword;
  final Token equalToken;
  final ConstructorName constructorName;

  _RedirectingFactoryBody(this.asyncKeyword, this.starKeyword, this.equalToken,
      this.constructorName);
}

/// Data structure placed on the stack as a container for optional parameters.
class _OptionalFormalParameters {
  final List<FormalParameter> parameters;
  final Token leftDelimiter;
  final Token rightDelimiter;

  _OptionalFormalParameters(
      this.parameters, this.leftDelimiter, this.rightDelimiter);
}

/// Data structure placed on the stack to represent the keyword "operator"
/// followed by a token.
class _OperatorName {
  final Token operatorKeyword;
  final SimpleIdentifier name;

  _OperatorName(this.operatorKeyword, this.name);
}

/// Data structure placed on the stack to represent a non-empty sequence
/// of modifiers.
class _Modifiers {
  Token abstractKeyword;
  Token externalKeyword;
  Token finalConstOrVarKeyword;
  Token staticKeyword;
  Token covariantKeyword;

  _Modifiers(List<Token> modifierTokens) {
    // No need to check the order and uniqueness of the modifiers, or that
    // disallowed modifiers are not used; the parser should do that.
    // TODO(paulberry,ahe): implement the necessary logic in the parser.
    for (var token in modifierTokens) {
      var s = token.lexeme;
      if (identical('abstract', s)) {
        abstractKeyword = token;
      } else if (identical('const', s)) {
        finalConstOrVarKeyword = token;
      } else if (identical('external', s)) {
        externalKeyword = token;
      } else if (identical('final', s)) {
        finalConstOrVarKeyword = token;
      } else if (identical('static', s)) {
        staticKeyword = token;
      } else if (identical('var', s)) {
        finalConstOrVarKeyword = token;
      } else if (identical('covariant', s)) {
        covariantKeyword = token;
      } else {
        unhandled("$s", "modifier", token.charOffset, null);
      }
    }
  }

  /// Return the token that is lexically first.
  Token get beginToken {
    Token firstToken = null;
    for (Token token in [
      abstractKeyword,
      externalKeyword,
      finalConstOrVarKeyword,
      staticKeyword,
      covariantKeyword
    ]) {
      if (firstToken == null) {
        firstToken = token;
      } else if (token != null) {
        if (token.offset < firstToken.offset) {
          firstToken = token;
        }
      }
    }
    return firstToken;
  }
}
