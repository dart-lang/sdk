// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/ast_factory.dart' show AstFactory;
import 'package:analyzer/dart/ast/standard_ast_factory.dart' as standard;
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/fasta/error_converter.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/fasta/parser.dart'
    show
        Assert,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        optional,
        Parser;
import 'package:front_end/src/fasta/scanner.dart' hide StringToken;
import 'package:front_end/src/scanner/errors.dart' show translateErrorToken;
import 'package:front_end/src/scanner/token.dart'
    show StringToken, SyntheticBeginToken, SyntheticStringToken, SyntheticToken;

import 'package:front_end/src/fasta/problems.dart' show unhandled;
import 'package:front_end/src/fasta/messages.dart'
    show
        Message,
        codeExpectedFunctionBody,
        messageConstConstructorWithBody,
        messageConstMethod,
        messageConstructorWithReturnType,
        messageDirectiveAfterDeclaration,
        messageExpectedStatement,
        messageFieldInitializerOutsideConstructor,
        messageIllegalAssignmentToNonAssignable,
        messageInterpolationInUri,
        messageMissingAssignableSelector,
        messageNativeClauseShouldBeAnnotation,
        messageStaticConstructor,
        templateDuplicateLabelInSwitchStatement,
        templateExpectedType;
import 'package:front_end/src/fasta/kernel/kernel_builder.dart'
    show Builder, KernelLibraryBuilder, Scope;
import 'package:front_end/src/fasta/quote.dart';
import 'package:front_end/src/fasta/scanner/token_constants.dart';
import 'package:front_end/src/fasta/source/scope_listener.dart'
    show JumpTargetKind, NullValue, ScopeListener;
import 'package:kernel/ast.dart' show AsyncMarker;

/// A parser listener that builds the analyzer's AST structure.
class AstBuilder extends ScopeListener {
  final AstFactory ast = standard.astFactory;

  final FastaErrorReporter errorReporter;
  final KernelLibraryBuilder library;
  final Builder member;

  ScriptTag scriptTag;
  final List<Directive> directives = <Directive>[];
  final List<CompilationUnitMember> declarations = <CompilationUnitMember>[];

  @override
  final Uri uri;

  /// The parser that uses this listener, used to parse optional parts, e.g.
  /// `native` support.
  Parser parser;

  bool parseGenericMethodComments = false;

  /// The class currently being parsed, or `null` if no class is being parsed.
  ClassDeclaration classDeclaration;

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

  AstBuilder(ErrorReporter errorReporter, this.library, this.member,
      Scope scope, this.isFullAst,
      [Uri uri])
      : this.errorReporter = new FastaErrorReporter(errorReporter),
        uri = uri ?? library.fileUri,
        super(scope);

  createJumpTarget(JumpTargetKind kind, int charOffset) {
    // TODO(ahe): Implement jump targets.
    return null;
  }

  void beginLiteralString(Token literalString) {
    assert(identical(literalString.kind, STRING_TOKEN));
    debugEvent("beginLiteralString");

    push(literalString);
  }

  void handleNamedArgument(Token colon) {
    assert(optional(':', colon));
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
    assert(optionalOrNull('.', periodBeforeName));
    debugEvent("ConstructorReference");

    SimpleIdentifier constructorName = pop();
    TypeArgumentList typeArguments = pop();
    Identifier typeNameIdentifier = pop();
    push(ast.constructorName(ast.typeName(typeNameIdentifier, typeArguments),
        periodBeforeName, constructorName));
  }

  @override
  void endConstExpression(Token constKeyword) {
    assert(optional('const', constKeyword));
    debugEvent("ConstExpression");

    _handleInstanceCreation(constKeyword);
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
  void endNewExpression(Token newKeyword) {
    assert(optional('new', newKeyword));
    debugEvent("NewExpression");

    _handleInstanceCreation(newKeyword);
  }

  @override
  void handleParenthesizedExpression(Token leftParenthesis) {
    assert(optional('(', leftParenthesis));
    debugEvent("ParenthesizedExpression");

    Expression expression = pop();
    push(ast.parenthesizedExpression(
        leftParenthesis, expression, leftParenthesis?.endGroup));
  }

  @override
  void handleStringPart(Token literalString) {
    assert(identical(literalString.kind, STRING_TOKEN));
    debugEvent("StringPart");

    push(literalString);
  }

  @override
  void handleInterpolationExpression(Token leftBracket, Token rightBracket) {
    Expression expression = pop();
    push(ast.interpolationExpression(leftBracket, expression, rightBracket));
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");

    if (interpolationCount == 0) {
      Token token = pop();
      String value = unescapeString(token.lexeme);
      push(ast.simpleStringLiteral(token, value));
    } else {
      List<Object> parts = popTypedList(1 + interpolationCount * 2);
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
        } else if (part is InterpolationExpression) {
          elements.add(part);
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
    assert(identical(token.type, TokenType.SCRIPT_TAG));
    debugEvent("Script");

    scriptTag = ast.scriptTag(token);
  }

  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");

    push(ast.adjacentStrings(popTypedList(literalCount)));
  }

  void endArguments(int count, Token leftParenthesis, Token rightParenthesis) {
    assert(optional('(', leftParenthesis));
    assert(optional(')', rightParenthesis));
    debugEvent("Arguments");

    List<Expression> expressions = popTypedList(count);
    ArgumentList arguments =
        ast.argumentList(leftParenthesis, expressions, rightParenthesis);
    push(ast.methodInvocation(null, null, null, null, arguments));
  }

  void handleIdentifier(Token token, IdentifierContext context) {
    assert(token.isKeywordOrIdentifier);
    debugEvent("handleIdentifier");

    if (context.inSymbol) {
      push(token);
      return;
    }

    SimpleIdentifier identifier =
        ast.simpleIdentifier(token, isDeclaration: context.inDeclaration);
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
      doInvocation(typeArguments, arguments);
    } else {
      doPropertyGet();
    }
  }

  void doInvocation(
      TypeArgumentList typeArguments, MethodInvocation arguments) {
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

  void doPropertyGet() {}

  void endExpressionStatement(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("ExpressionStatement");
    Expression expression = pop();
    if (expression is SuperExpression) {
      // This error is also reported by the body builder.
      handleRecoverableError(messageMissingAssignableSelector,
          expression.beginToken, expression.endToken);
    }
    if (expression is SimpleIdentifier &&
        expression.token?.keyword?.isBuiltInOrPseudo == false) {
      // This error is also reported by the body builder.
      handleRecoverableError(
          messageExpectedStatement, expression.beginToken, expression.endToken);
    }
    if (expression is AssignmentExpression) {
      if (!expression.leftHandSide.isAssignable) {
        // This error is also reported by the body builder.
        handleRecoverableError(
            messageIllegalAssignmentToNonAssignable,
            expression.leftHandSide.beginToken,
            expression.leftHandSide.endToken);
      }
    }
    push(ast.expressionStatement(expression, semicolon));
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    assert(optional('native', nativeToken));
    assert(optional(';', semicolon));
    debugEvent("NativeFunctionBody");

    // TODO(danrubel) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.nativeFunctionBody(nativeToken, nativeName, semicolon));
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("EmptyFunctionBody");

    // TODO(scheglov) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.emptyFunctionBody(semicolon));
  }

  @override
  void handleEmptyStatement(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("EmptyStatement");

    push(ast.emptyStatement(semicolon));
  }

  void endBlockFunctionBody(int count, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("BlockFunctionBody");

    List<Statement> statements = popTypedList(count);
    if (leftBracket != null) {
      exitLocalScope();
    }
    Block block = ast.block(leftBracket, statements, rightBracket);
    Token star = pop();
    Token asyncKeyword = pop();
    push(ast.blockFunctionBody(asyncKeyword, star, block));
  }

  void finishFunction(
      List annotations, formals, AsyncMarker asyncModifier, FunctionBody body) {
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
    assert(optional('..', token));
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

  void handleOperator(Token operatorToken) {
    assert(operatorToken.isUserDefinableOperator);
    debugEvent("Operator");

    push(operatorToken);
  }

  void handleSymbolVoid(Token voidKeyword) {
    assert(optional('void', voidKeyword));
    debugEvent("SymbolVoid");

    push(voidKeyword);
  }

  @override
  void endBinaryExpression(Token operatorToken) {
    assert(operatorToken.isOperator ||
        optional('.', operatorToken) ||
        optional('?.', operatorToken) ||
        optional('..', operatorToken));
    debugEvent("BinaryExpression");

    if (identical(".", operatorToken.stringValue) ||
        identical("?.", operatorToken.stringValue) ||
        identical("..", operatorToken.stringValue)) {
      doDotExpression(operatorToken);
    } else {
      Expression right = pop();
      Expression left = pop();
      push(ast.binaryExpression(left, operatorToken, right));
    }
  }

  void doDotExpression(Token dot) {
    Expression identifierOrInvoke = pop();
    Expression receiver = pop();
    if (identifierOrInvoke is SimpleIdentifier) {
      if (receiver is SimpleIdentifier && identical('.', dot.stringValue)) {
        push(ast.prefixedIdentifier(receiver, dot, identifierOrInvoke));
      } else {
        push(ast.propertyAccess(receiver, dot, identifierOrInvoke));
      }
    } else if (identifierOrInvoke is MethodInvocation) {
      assert(identifierOrInvoke.target == null);
      identifierOrInvoke
        ..target = receiver
        ..operator = dot;
      push(identifierOrInvoke);
    } else {
      unhandled("${identifierOrInvoke.runtimeType}", "property access",
          dot.charOffset, uri);
    }
  }

  void handleLiteralInt(Token token) {
    assert(identical(token.kind, INT_TOKEN) ||
        identical(token.kind, HEXADECIMAL_TOKEN));
    debugEvent("LiteralInt");

    push(ast.integerLiteral(token, int.parse(token.lexeme)));
  }

  void handleExpressionFunctionBody(Token arrowToken, Token semicolon) {
    assert(optional('=>', arrowToken) || optional('=', arrowToken));
    assert(optionalOrNull(';', semicolon));
    debugEvent("ExpressionFunctionBody");

    Expression expression = pop();
    Token star = pop();
    Token asyncKeyword = pop();
    assert(star == null);
    push(ast.expressionFunctionBody(
        asyncKeyword, arrowToken, expression, semicolon));
  }

  void endReturnStatement(
      bool hasExpression, Token returnKeyword, Token semicolon) {
    assert(optional('return', returnKeyword));
    assert(optional(';', semicolon));
    debugEvent("ReturnStatement");

    Expression expression = hasExpression ? pop() : null;
    push(ast.returnStatement(returnKeyword, expression, semicolon));
  }

  void endIfStatement(Token ifToken, Token elseToken) {
    assert(optional('if', ifToken));
    assert(optionalOrNull('else', elseToken));

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

  void endInitializers(int count, Token colon, Token endToken) {
    assert(optional(':', colon));
    debugEvent("Initializers");

    List<Object> initializerObjects = popTypedList(count) ?? const [];
    if (!isFullAst) return;

    push(colon);

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
    assert(optionalOrNull('=', assignmentOperator));
    debugEvent("VariableInitializer");

    Expression initializer = pop();
    SimpleIdentifier identifier = pop();
    // TODO(ahe): Don't push initializers, instead install them.
    push(ast.variableDeclaration(identifier, assignmentOperator, initializer));
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    assert(optional('while', whileKeyword));
    debugEvent("WhileStatement");

    Statement body = pop();
    ParenthesizedExpression condition = pop();
    exitContinueTarget();
    exitBreakTarget();
    push(ast.whileStatement(whileKeyword, condition.leftParenthesis,
        condition.expression, condition.rightParenthesis, body));
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token semicolon) {
    assert(optional('yield', yieldToken));
    assert(optionalOrNull('*', starToken));
    assert(optional(';', semicolon));
    debugEvent("YieldStatement");

    Expression expression = pop();
    push(ast.yieldStatement(yieldToken, starToken, expression, semicolon));
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

  @override
  void beginVariablesDeclaration(Token token, Token varFinalOrConst) {
    debugEvent("beginVariablesDeclaration");
    if (varFinalOrConst != null) {
      push(new _Modifiers()..finalConstOrVarKeyword = varFinalOrConst);
    } else {
      push(NullValue.Modifiers);
    }
  }

  @override
  void endVariablesDeclaration(int count, Token semicolon) {
    assert(optionalOrNull(';', semicolon));
    debugEvent("VariablesDeclaration");

    List<VariableDeclaration> variables = popTypedList(count);
    _Modifiers modifiers = pop(NullValue.Modifiers);
    TypeAnnotation type = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata,
        variables[0].beginToken ?? type?.beginToken ?? modifiers.beginToken);
    push(ast.variableDeclarationStatement(
        ast.variableDeclarationList(
            comment, metadata, keyword, type, variables),
        semicolon));
  }

  void handleAssignmentExpression(Token token) {
    assert(token.type.isAssignmentOperator);
    debugEvent("AssignmentExpression");

    Expression rhs = pop();
    Expression lhs = pop();
    push(ast.assignmentExpression(lhs, token, rhs));
  }

  void endBlock(int count, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("Block");

    List<Statement> statements = popTypedList(count) ?? <Statement>[];
    exitLocalScope();
    push(ast.block(leftBracket, statements, rightBracket));
  }

  void handleInvalidTopLevelBlock(Token token) {
    // TODO(danrubel): Consider improved recovery by adding this block
    // as part of a synthetic top level function.
    pop(); // block
  }

  void endForStatement(Token forKeyword, Token leftParen, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    assert(optional('for', forKeyword));
    assert(optional('(', leftParen));
    assert(optional(';', leftSeparator));
    debugEvent("ForStatement");

    Statement body = pop();
    List<Expression> updates = popTypedList(updateExpressionCount);
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
      int count, Token leftBracket, Token constKeyword, Token rightBracket) {
    assert(optional('[', leftBracket));
    assert(optionalOrNull('const', constKeyword));
    assert(optional(']', rightBracket));
    debugEvent("LiteralList");

    List<Expression> expressions = popTypedList(count);
    TypeArgumentList typeArguments = pop();
    push(ast.listLiteral(
        constKeyword, typeArguments, leftBracket, expressions, rightBracket));
  }

  void handleAsyncModifier(Token asyncToken, Token starToken) {
    assert(asyncToken == null ||
        optional('async', asyncToken) ||
        optional('sync', asyncToken));
    assert(optionalOrNull('*', starToken));
    debugEvent("AsyncModifier");

    push(asyncToken ?? NullValue.FunctionBodyAsyncToken);
    push(starToken ?? NullValue.FunctionBodyStarToken);
  }

  void endAwaitExpression(Token awaitKeyword, Token endToken) {
    assert(optional('await', awaitKeyword));
    debugEvent("AwaitExpression");

    push(ast.awaitExpression(awaitKeyword, pop()));
  }

  void handleLiteralBool(Token token) {
    bool value = identical(token.stringValue, "true");
    assert(value || identical(token.stringValue, "false"));
    debugEvent("LiteralBool");

    push(ast.booleanLiteral(token, value));
  }

  void handleLiteralDouble(Token token) {
    assert(token.type == TokenType.DOUBLE);
    debugEvent("LiteralDouble");

    push(ast.doubleLiteral(token, double.parse(token.lexeme)));
  }

  void handleLiteralNull(Token token) {
    assert(optional('null', token));
    debugEvent("LiteralNull");

    push(ast.nullLiteral(token));
  }

  void handleLiteralMap(
      int count, Token leftBracket, Token constKeyword, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optionalOrNull('const', constKeyword));
    assert(optional('}', rightBracket));
    debugEvent("LiteralMap");

    List<MapLiteralEntry> entries = popTypedList(count) ?? <MapLiteralEntry>[];
    TypeArgumentList typeArguments = pop();
    push(ast.mapLiteral(
        constKeyword, typeArguments, leftBracket, entries, rightBracket));
  }

  void endLiteralMapEntry(Token colon, Token endToken) {
    assert(optional(':', colon));
    debugEvent("LiteralMapEntry");

    Expression value = pop();
    Expression key = pop();
    push(ast.mapLiteralEntry(key, colon, value));
  }

  void endLiteralSymbol(Token hashToken, int tokenCount) {
    assert(optional('#', hashToken));
    debugEvent("LiteralSymbol");

    List<Token> components = popTypedList(tokenCount);
    push(ast.symbolLiteral(hashToken, components));
  }

  @override
  void handleSuperExpression(Token superKeyword, IdentifierContext context) {
    assert(optional('super', superKeyword));
    debugEvent("SuperExpression");

    push(ast.superExpression(superKeyword));
  }

  @override
  void handleThisExpression(Token thisKeyword, IdentifierContext context) {
    assert(optional('this', thisKeyword));
    debugEvent("ThisExpression");

    push(ast.thisExpression(thisKeyword));
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
    assert(optional('assert', assertKeyword));
    assert(optional('(', leftParenthesis));
    assert(optionalOrNull(',', comma));
    assert(kind != Assert.Statement || optionalOrNull(';', semicolon));
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

  void handleAsOperator(Token asOperator, Token endToken) {
    assert(optional('as', asOperator));
    debugEvent("AsOperator");

    TypeAnnotation type = pop();
    if (type is TypeName) {
      Identifier name = type.name;
      if (name is SimpleIdentifier) {
        if (name.name == 'void') {
          Token token = name.beginToken;
          // TODO(danrubel): This needs to be reported during fasta resolution.
          handleRecoverableError(
              templateExpectedType.withArguments(token), token, token);
        }
      }
    }
    Expression expression = pop();
    push(ast.asExpression(expression, asOperator, type));
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token semicolon) {
    assert(optional('break', breakKeyword));
    assert(optional(';', semicolon));
    debugEvent("BreakStatement");

    SimpleIdentifier label = hasTarget ? pop() : null;
    push(ast.breakStatement(breakKeyword, label, semicolon));
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token semicolon) {
    assert(optional('continue', continueKeyword));
    assert(optional(';', semicolon));
    debugEvent("ContinueStatement");

    SimpleIdentifier label = hasTarget ? pop() : null;
    push(ast.continueStatement(continueKeyword, label, semicolon));
  }

  void handleIsOperator(Token isOperator, Token not, Token endToken) {
    assert(optional('is', isOperator));
    assert(optionalOrNull('!', not));
    debugEvent("IsOperator");

    TypeAnnotation type = pop();
    if (type is TypeName) {
      Identifier name = type.name;
      if (name is SimpleIdentifier) {
        if (name.name == 'void') {
          Token token = name.beginToken;
          // TODO(danrubel): This needs to be reported during fasta resolution.
          handleRecoverableError(
              templateExpectedType.withArguments(token), token, token);
        }
      }
    }
    Expression expression = pop();
    push(ast.isExpression(expression, isOperator, not, type));
  }

  void endConditionalExpression(Token question, Token colon) {
    assert(optional('?', question));
    assert(optional(':', colon));
    debugEvent("ConditionalExpression");

    Expression elseExpression = pop();
    Expression thenExpression = pop();
    Expression condition = pop();
    push(ast.conditionalExpression(
        condition, question, thenExpression, colon, elseExpression));
  }

  @override
  void endRedirectingFactoryBody(Token equalToken, Token endToken) {
    assert(optional('=', equalToken));
    debugEvent("RedirectingFactoryBody");

    ConstructorName constructorName = pop();
    Token starToken = pop();
    Token asyncToken = pop();
    push(new _RedirectingFactoryBody(
        asyncToken, starToken, equalToken, constructorName));
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token semicolon) {
    assert(optional('rethrow', rethrowToken));
    assert(optional(';', semicolon));
    debugEvent("RethrowStatement");

    RethrowExpression expression = ast.rethrowExpression(rethrowToken);
    // TODO(scheglov) According to the specification, 'rethrow' is a statement.
    push(ast.expressionStatement(expression, semicolon));
  }

  void handleThrowExpression(Token throwToken, Token endToken) {
    assert(optional('throw', throwToken));
    debugEvent("ThrowExpression");

    push(ast.throwExpression(throwToken, pop()));
  }

  @override
  void endOptionalFormalParameters(
      int count, Token leftDelimeter, Token rightDelimeter) {
    assert((optional('[', leftDelimeter) && optional(']', rightDelimeter)) ||
        (optional('{', leftDelimeter) && optional('}', rightDelimeter)));
    debugEvent("OptionalFormalParameters");

    push(new _OptionalFormalParameters(
        popTypedList(count), leftDelimeter, rightDelimeter));
  }

  void handleValuedFormalParameter(Token equals, Token token) {
    assert(optional('=', equals) || optional(':', equals));
    debugEvent("ValuedFormalParameter");

    Expression value = pop();
    push(new _ParameterDefaultValue(equals, value));
  }

  @override
  void endFunctionType(Token functionToken, Token semicolon) {
    assert(optional('Function', functionToken));
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
    assert(optionalOrNull('await', awaitToken));
    assert(optional('for', forToken));
    assert(optional('(', leftParenthesis));
    assert(optional('in', inKeyword) || optional(':', inKeyword));
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

  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    assert(optionalOrNull('this', thisKeyword));
    assert(thisKeyword == null
        ? periodAfterThis == null
        : optional('.', periodAfterThis));
    debugEvent("FormalParameter");

    _ParameterDefaultValue defaultValue = pop();
    SimpleIdentifier name = pop();
    AstNode typeOrFunctionTypedParameter = pop();
    _Modifiers modifiers = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    Token covariantKeyword = modifiers?.covariantKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata,
        thisKeyword ?? typeOrFunctionTypedParameter?.beginToken ?? nameToken);

    NormalFormalParameter node;
    if (typeOrFunctionTypedParameter is FunctionTypedFormalParameter) {
      // This is a temporary AST node that was constructed in
      // [endFunctionTypedFormalParameter]. We now deconstruct it and create
      // the final AST node.
      if (thisKeyword == null) {
        node = ast.functionTypedFormalParameter2(
            identifier: name,
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            returnType: typeOrFunctionTypedParameter.returnType,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters);
      } else {
        node = ast.fieldFormalParameter2(
            identifier: name,
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            type: typeOrFunctionTypedParameter.returnType,
            thisKeyword: thisKeyword,
            period: periodAfterThis,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters);
      }
    } else {
      TypeAnnotation type = typeOrFunctionTypedParameter;
      if (thisKeyword == null) {
        node = ast.simpleFormalParameter2(
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            keyword: keyword,
            type: type,
            identifier: name);
      } else {
        node = ast.fieldFormalParameter2(
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            keyword: keyword,
            type: type,
            thisKeyword: thisKeyword,
            period: thisKeyword.next,
            identifier: name);
      }
    }

    ParameterKind analyzerKind = _toAnalyzerParameterKind(kind);
    FormalParameter parameter = node;
    if (analyzerKind != ParameterKind.REQUIRED) {
      parameter = ast.defaultFormalParameter(
          node, analyzerKind, defaultValue?.separator, defaultValue?.value);
    } else if (defaultValue != null) {
      // An error is reported if a required parameter has a default value.
      // Record it as named parameter for recovery.
      parameter = ast.defaultFormalParameter(node, ParameterKind.NAMED,
          defaultValue.separator, defaultValue.value);
    }
    push(parameter);
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
      int count, Token leftParen, Token rightParen, MemberKind kind) {
    assert(optional('(', leftParen));
    assert(optional(')', rightParen));
    debugEvent("FormalParameters");

    List<Object> rawParameters = popTypedList(count) ?? const <Object>[];
    List<FormalParameter> parameters = <FormalParameter>[];
    Token leftDelimiter;
    Token rightDelimiter;
    for (Object raw in rawParameters) {
      if (raw is _OptionalFormalParameters) {
        parameters.addAll(raw.parameters ?? const <FormalParameter>[]);
        leftDelimiter = raw.leftDelimiter;
        rightDelimiter = raw.rightDelimiter;
      } else {
        parameters.add(raw as FormalParameter);
      }
    }
    push(ast.formalParameterList(
        leftParen, parameters, leftDelimiter, rightDelimiter, rightParen));
  }

  @override
  void endSwitchBlock(int caseCount, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("SwitchBlock");

    List<List<SwitchMember>> membersList = popTypedList(caseCount);
    exitBreakTarget();
    exitLocalScope();
    List<SwitchMember> members =
        membersList?.expand((members) => members)?.toList() ?? <SwitchMember>[];

    Set<String> labels = new Set<String>();
    for (SwitchMember member in members) {
      for (Label label in member.labels) {
        if (!labels.add(label.label.name)) {
          handleRecoverableError(
              templateDuplicateLabelInSwitchStatement
                  .withArguments(label.label.name),
              label.beginToken,
              label.beginToken);
        }
      }
    }

    push(leftBracket);
    push(members);
    push(rightBracket);
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      Token colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    assert(optionalOrNull('default', defaultKeyword));
    assert(defaultKeyword == null
        ? colonAfterDefault == null
        : optional(':', colonAfterDefault));
    debugEvent("SwitchCase");

    List<Statement> statements = popTypedList(statementCount);
    List<SwitchMember> members = popTypedList(expressionCount) ?? [];
    List<Label> labels = popTypedList(labelCount);
    if (defaultKeyword != null) {
      members.add(ast.switchDefault(
          <Label>[], defaultKeyword, colonAfterDefault, <Statement>[]));
    }
    if (members.isNotEmpty) {
      members.last.statements.addAll(statements);
      members.first.labels.addAll(labels);
    }
    push(members);
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    assert(optional('case', caseKeyword));
    assert(optional(':', colon));
    debugEvent("CaseMatch");

    Expression expression = pop();
    push(ast.switchCase(
        <Label>[], caseKeyword, expression, colon, <Statement>[]));
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    assert(optional('switch', switchKeyword));
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
    assert(optionalOrNull('on', onKeyword));
    assert(optionalOrNull('catch', catchKeyword));
    assert(optionalOrNull(',', comma));
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
    assert(optional('try', tryKeyword));
    assert(optionalOrNull('finally', finallyKeyword));
    debugEvent("TryStatement");

    Block finallyBlock = popIfNotNull(finallyKeyword);
    List<CatchClause> catchClauses = popTypedList(catchCount);
    Block body = pop();
    push(ast.tryStatement(
        tryKeyword, body, catchClauses, finallyKeyword, finallyBlock));
  }

  @override
  void handleLabel(Token colon) {
    assert(optionalOrNull(':', colon));
    debugEvent("Label");

    SimpleIdentifier name = pop();
    push(ast.label(name, colon));
  }

  void handleNoExpression(Token token) {
    debugEvent("NoExpression");

    push(NullValue.Expression);
  }

  void handleIndexedExpression(Token leftBracket, Token rightBracket) {
    assert(optional('[', leftBracket));
    assert(optional(']', rightBracket));
    debugEvent("IndexedExpression");

    Expression index = pop();
    Expression target = pop();
    if (target == null) {
      CascadeExpression receiver = pop();
      Token token = peek();
      push(receiver);
      IndexExpression expression = ast.indexExpressionForCascade(
          token, leftBracket, index, rightBracket);
      assert(expression.isCascaded);
      push(expression);
    } else {
      push(ast.indexExpressionForTarget(
          target, leftBracket, index, rightBracket));
    }
  }

  @override
  void handleInvalidExpression(Token token) {
    debugEvent("InvalidExpression");
  }

  @override
  void handleInvalidFunctionBody(Token leftBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', leftBracket.endGroup));
    debugEvent("InvalidFunctionBody");
    Block block = ast.block(leftBracket, [], leftBracket.endGroup);
    Token star = pop();
    Token asyncKeyword = pop();
    push(ast.blockFunctionBody(asyncKeyword, star, block));
  }

  @override
  Token handleUnrecoverableError(Token token, Message message) {
    if (message.code == codeExpectedFunctionBody) {
      if (identical('native', token.stringValue) && parser != null) {
        Token nativeKeyword = token;
        Token semicolon = parser.parseLiteralString(token).next;
        // TODO(brianwilkerson) Should this be using ensureSemicolon?
        token = parser.expectSemicolon(semicolon);
        StringLiteral name = pop();
        pop(); // star
        pop(); // async
        push(ast.nativeFunctionBody(nativeKeyword, name, semicolon));
        return token;
      }
    }
    return super.handleUnrecoverableError(token, message);
  }

  void handleUnaryPrefixExpression(Token operator) {
    assert(operator.type.isUnaryPrefixOperator);
    debugEvent("UnaryPrefixExpression");

    push(ast.prefixExpression(operator, pop()));
  }

  void handleUnaryPrefixAssignmentExpression(Token operator) {
    assert(operator.type.isUnaryPrefixOperator);
    debugEvent("UnaryPrefixAssignmentExpression");

    Expression expression = pop();
    if (!expression.isAssignable) {
      // This error is also reported by the body builder.
      handleRecoverableError(messageMissingAssignableSelector,
          expression.endToken, expression.endToken);
    }
    push(ast.prefixExpression(operator, expression));
  }

  void handleUnaryPostfixAssignmentExpression(Token operator) {
    assert(operator.type.isUnaryPostfixOperator);
    debugEvent("UnaryPostfixAssignmentExpression");

    Expression expression = pop();
    if (!expression.isAssignable) {
      // This error is also reported by the body builder.
      handleRecoverableError(
          messageIllegalAssignmentToNonAssignable, operator, operator);
    }
    push(ast.postfixExpression(expression, operator));
  }

  void handleModifier(Token token) {
    assert(token.isModifier);
    debugEvent("Modifier");

    push(token);
  }

  void handleModifiers(int count) {
    debugEvent("Modifiers");

    if (count == 0) {
      push(NullValue.Modifiers);
    } else {
      push(new _Modifiers(popTypedList(count)));
    }
  }

  void beginTopLevelMethod(Token lastConsumed, Token externalToken) {
    push(new _Modifiers()..externalKeyword = externalToken);
  }

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.
    assert(getOrSet == null ||
        optional('get', getOrSet) ||
        optional('set', getOrSet));
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
    assert(optionalOrNull('deferred', deferredKeyword));
    assert(optionalOrNull('as', asKeyword));
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
    assert(optional('import', importKeyword));
    assert(optionalOrNull(';', semicolon));
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
    assert(optionalOrNull(';', semicolon));
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
    assert(optional('export', exportKeyword));
    assert(optional(';', semicolon));
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
  void handleDottedName(int count, Token firstIdentifier) {
    assert(firstIdentifier.isIdentifier);
    debugEvent("DottedName");

    List<SimpleIdentifier> components = popTypedList(count);
    push(ast.dottedName(components));
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token semicolon) {
    assert(optional('do', doKeyword));
    assert(optional('while', whileKeyword));
    assert(optional(';', semicolon));
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
    assert(optional('if', ifKeyword));
    assert(optionalOrNull('(', leftParen));
    assert(optionalOrNull('==', equalSign));
    debugEvent("ConditionalUri");

    StringLiteral libraryUri = pop();
    StringLiteral value = popIfNotNull(equalSign);
    if (value is StringInterpolation) {
      for (var child in value.childEntities) {
        if (child is InterpolationExpression) {
          // This error is reported in OutlineBuilder.endLiteralString
          handleRecoverableError(
              messageInterpolationInUri, child.beginToken, child.endToken);
          break;
        }
      }
    }
    DottedName name = pop();
    push(ast.configuration(ifKeyword, leftParen, name, equalSign, value,
        leftParen?.endGroup, libraryUri));
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");

    push(popTypedList<Configuration>(count) ?? NullValue.ConditionalUris);
  }

  @override
  void handleIdentifierList(int count) {
    debugEvent("IdentifierList");

    push(popTypedList<SimpleIdentifier>(count) ?? NullValue.IdentifierList);
  }

  @override
  void endShow(Token showKeyword) {
    assert(optional('show', showKeyword));
    debugEvent("Show");

    List<SimpleIdentifier> shownNames = pop();
    push(ast.showCombinator(showKeyword, shownNames));
  }

  @override
  void endHide(Token hideKeyword) {
    assert(optional('hide', hideKeyword));
    debugEvent("Hide");

    List<SimpleIdentifier> hiddenNames = pop();
    push(ast.hideCombinator(hideKeyword, hiddenNames));
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(popTypedList<Combinator>(count) ?? NullValue.Combinators);
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popTypedList<TypeName>(count) ?? NullValue.TypeList);
  }

  @override
  void endClassBody(int memberCount, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("ClassBody");

    classDeclaration.leftBracket = leftBracket;
    classDeclaration.rightBracket = rightBracket;
  }

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    assert(classDeclaration == null);
    push(new _Modifiers()..abstractKeyword = abstractToken);
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    assert(optionalOrNull('extends', extendsKeyword));
    debugEvent("ClassExtends");

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
    assert(optionalOrNull('implements', implementsKeyword));
    debugEvent("ClassImplements");

    if (implementsKeyword != null) {
      List<TypeName> interfaces = popTypedList(interfacesCount);
      push(ast.implementsClause(implementsKeyword, interfaces));
    } else {
      push(NullValue.IdentifierList);
    }
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    assert(optional('class', classKeyword));
    assert(optionalOrNull('native', nativeToken));
    assert(classDeclaration == null);
    debugEvent("ClassHeader");

    NativeClause nativeClause;
    if (nativeToken != null) {
      nativeClause = ast.nativeClause(nativeToken, nativeName);
    }
    ImplementsClause implementsClause = pop(NullValue.IdentifierList);
    WithClause withClause = pop(NullValue.WithClause);
    ExtendsClause extendsClause = pop(NullValue.ExtendsClause);
    _Modifiers modifiers = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, classKeyword);
    // leftBracket, members, and rightBracket are set in [endClassBody].
    classDeclaration = ast.classDeclaration(
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
    classDeclaration = null;
  }

  @override
  void beginNamedMixinApplication(
      Token begin, Token abstractToken, Token name) {
    push(new _Modifiers()..abstractKeyword = abstractToken);
  }

  @override
  void endMixinApplication(Token withKeyword) {
    assert(optionalOrNull('with', withKeyword));
    debugEvent("MixinApplication");

    List<TypeName> mixinTypes = pop();
    TypeName supertype = pop();
    push(new _MixinApplication(supertype, withKeyword, mixinTypes));
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equalsToken, Token implementsKeyword, Token semicolon) {
    assert(optional('class', classKeyword));
    assert(optionalOrNull('=', equalsToken));
    assert(optionalOrNull('implements', implementsKeyword));
    assert(optional(';', semicolon));
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
    _Modifiers modifiers = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    declarations.add(ast.classTypeAlias(
        comment,
        metadata,
        classKeyword,
        name,
        typeParameters,
        equalsToken,
        abstractKeyword,
        superclass,
        withClause,
        implementsClause,
        semicolon));
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");

    Statement statement = pop();
    List<Label> labels = popTypedList(labelCount);
    push(ast.labeledStatement(labels, statement));
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    assert(optional('library', libraryKeyword));
    assert(optional(';', semicolon));
    debugEvent("LibraryName");

    List<SimpleIdentifier> libraryName = pop();
    var name = ast.libraryIdentifier(libraryName);
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, libraryKeyword);
    directives.add(ast.libraryDirective(
        comment, metadata, libraryKeyword, name, semicolon));
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    /// TODO(danrubel): Ignore this error until we deprecate `native` support.
    if (message == messageNativeClauseShouldBeAnnotation && allowNativeClause) {
      return;
    }
    debugEvent("Error: ${message.message}");
    if (message.code.analyzerCode == null && startToken is ErrorToken) {
      translateErrorToken(startToken, errorReporter.reportScannerError);
    } else {
      int offset = startToken.offset;
      int length = endToken.end - offset;
      addCompileTimeError(message, offset, length);
    }
  }

  @override
  void handleQualified(Token period) {
    assert(optional('.', period));

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
    assert(optional('part', partKeyword));
    assert(optional(';', semicolon));
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
    assert(optional('part', partKeyword));
    assert(optional('of', ofKeyword));
    assert(optional(';', semicolon));
    debugEvent("PartOf");
    var libraryNameOrUri = pop();
    LibraryIdentifier name;
    StringLiteral uri;
    if (libraryNameOrUri is StringLiteral) {
      uri = libraryNameOrUri;
    } else {
      name = ast.libraryIdentifier(libraryNameOrUri as List<SimpleIdentifier>);
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
  void beginFactoryMethod(
      Token lastConsumed, Token externalToken, Token constToken) {
    push(new _Modifiers()
      ..externalKeyword = externalToken
      ..finalConstOrVarKeyword = constToken);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    assert(optional('factory', factoryKeyword));
    assert(optional(';', endToken) || optional('}', endToken));
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
      body = ast.emptyFunctionBody(endToken);
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

    classDeclaration.members.add(ast.constructorDeclaration(
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
    assert(optional('=', assignment));
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
    TypeParameterList typeParameters = pop();
    List<Annotation> metadata = pop(NullValue.Metadata);
    FunctionExpression functionExpression =
        ast.functionExpression(typeParameters, parameters, body);
    push(ast.functionDeclarationStatement(ast.functionDeclaration(
        null, metadata, null, returnType, null, name, functionExpression)));
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
  }

  void endTopLevelFields(Token staticToken, Token covariantToken,
      Token varFinalOrConst, int count, Token beginToken, Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("TopLevelFields");

    List<VariableDeclaration> variables = popTypedList(count);
    TypeAnnotation type = pop();
    _Modifiers modifiers = new _Modifiers()
      ..staticKeyword = staticToken
      ..covariantKeyword = covariantToken
      ..finalConstOrVarKeyword = varFinalOrConst;
    Token keyword = modifiers?.finalConstOrVarKeyword;
    var variableList =
        ast.variableDeclarationList(null, null, keyword, type, variables);
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    declarations.add(ast.topLevelVariableDeclaration(
        comment, metadata, variableList, semicolon));
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.  Note that this is tricky due to the handling of initializers
    // in constructors, so the logic should be shared with BodyBuilder as much
    // as possible.
    assert(extendsOrSuper == null ||
        optional('extends', extendsOrSuper) ||
        optional('super', extendsOrSuper));
    debugEvent("TypeVariable");

    TypeAnnotation bound = pop();
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, name.beginToken);
    push(ast.typeParameter(comment, metadata, name, extendsOrSuper, bound));
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    assert(optional('<', beginToken));
    assert(optional('>', endToken));
    debugEvent("TypeVariables");

    List<TypeParameter> typeParameters = popTypedList(count);
    push(ast.typeParameterList(beginToken, typeParameters, endToken));
  }

  @override
  void beginMethod(Token externalToken, Token staticToken, Token covariantToken,
      Token varFinalOrConst, Token name) {
    _Modifiers modifiers = new _Modifiers();
    if (externalToken != null) {
      assert(externalToken.isModifier);
      modifiers.externalKeyword = externalToken;
    }
    if (staticToken != null) {
      assert(staticToken.isModifier);
      if (name?.lexeme == classDeclaration.name.name) {
        // This error is also reported in OutlineBuilder.beginMethod
        handleRecoverableError(
            messageStaticConstructor, staticToken, staticToken);
      } else {
        modifiers.staticKeyword = staticToken;
      }
    }
    if (covariantToken != null) {
      assert(covariantToken.isModifier);
      modifiers.covariantKeyword = covariantToken;
    }
    if (varFinalOrConst != null) {
      assert(varFinalOrConst.isModifier);
      modifiers.finalConstOrVarKeyword = varFinalOrConst;
    }
    push(modifiers);
  }

  @override
  void endMethod(
      Token getOrSet, Token beginToken, Token beginParam, Token endToken) {
    assert(getOrSet == null ||
        optional('get', getOrSet) ||
        optional('set', getOrSet));
    debugEvent("Method");

    var bodyObject = pop();
    List<ConstructorInitializer> initializers = pop() ?? const [];
    Token separator = pop();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    var name = pop();
    TypeAnnotation returnType = pop();
    _Modifiers modifiers = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);

    ConstructorName redirectedConstructor;
    FunctionBody body;
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      separator = bodyObject.equalToken;
      redirectedConstructor = bodyObject.constructorName;
      body = ast.emptyFunctionBody(endToken);
    } else {
      unhandled("${bodyObject.runtimeType}", "bodyObject",
          beginToken.charOffset, uri);
    }

    if (parameters == null && (getOrSet == null || optional('set', getOrSet))) {
      Token previous = typeParameters?.endToken;
      if (previous == null) {
        if (name is AstNode) {
          previous = name.endToken;
        } else if (name is _OperatorName) {
          previous = name.name.endToken;
        } else {
          throw new UnimplementedError();
        }
      }
      Token leftParen =
          new SyntheticBeginToken(TokenType.OPEN_PAREN, previous.end);
      Token rightParen =
          new SyntheticToken(TokenType.CLOSE_PAREN, leftParen.offset);
      rightParen.next = previous.next;
      leftParen.next = rightParen;
      previous.next = leftParen;
      leftParen.previous = previous;
      rightParen.previous = leftParen;
      rightParen.next.previous = rightParen;
      parameters = ast.formalParameterList(
          leftParen, <FormalParameter>[], null, null, rightParen);
    }

    void constructor(
        SimpleIdentifier prefixOrName, Token period, SimpleIdentifier name) {
      if (modifiers?.constKeyword != null &&
          body != null &&
          (body.length > 1 || body.beginToken?.lexeme != ';')) {
        // This error is also reported in BodyBuilder.finishFunction
        Token bodyToken = body.beginToken ?? modifiers.constKeyword;
        handleRecoverableError(
            messageConstConstructorWithBody, bodyToken, bodyToken);
      }
      if (returnType != null) {
        // This error is also reported in OutlineBuilder.endMethod
        handleRecoverableError(messageConstructorWithReturnType,
            returnType.beginToken, returnType.beginToken);
      }
      classDeclaration.members.add(ast.constructorDeclaration(
          comment,
          metadata,
          modifiers?.externalKeyword,
          modifiers?.finalConstOrVarKeyword,
          null, // TODO(paulberry): factoryKeyword
          ast.simpleIdentifier(prefixOrName.token),
          period,
          name,
          parameters,
          separator,
          initializers,
          redirectedConstructor,
          body));
    }

    void method(Token operatorKeyword, SimpleIdentifier name) {
      if (modifiers?.constKeyword != null &&
          body != null &&
          (body.length > 1 || body.beginToken?.lexeme != ';')) {
        // This error is also reported in OutlineBuilder.endMethod
        handleRecoverableError(
            messageConstMethod, modifiers.constKeyword, modifiers.constKeyword);
      }
      if (parameters?.parameters != null) {
        parameters.parameters.forEach((FormalParameter param) {
          if (param is FieldFormalParameter) {
            // This error is reported in the BodyBuilder.endFormalParameter.
            handleRecoverableError(messageFieldInitializerOutsideConstructor,
                param.thisKeyword, param.thisKeyword);
          }
        });
      }
      classDeclaration.members.add(ast.methodDeclaration(
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
      if (name.name == classDeclaration.name.name && getOrSet == null) {
        constructor(name, null, null);
      } else if (initializers.isNotEmpty) {
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
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember");
    pop(); // metadata star
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void handleVoidKeyword(Token voidKeyword) {
    assert(optional('void', voidKeyword));
    debugEvent("VoidKeyword");

    // TODO(paulberry): is this sufficient, or do we need to hook the "void"
    // keyword up to an element?
    handleIdentifier(voidKeyword, IdentifierContext.typeReference);
    handleNoTypeArguments(voidKeyword);
    handleType(voidKeyword, voidKeyword);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token semicolon) {
    assert(optional('typedef', typedefKeyword));
    assert(optionalOrNull('=', equals));
    assert(optional(';', semicolon));
    debugEvent("FunctionTypeAlias");

    if (equals == null) {
      FormalParameterList parameters = pop();
      TypeParameterList typeParameters = pop();
      SimpleIdentifier name = pop();
      TypeAnnotation returnType = pop();
      List<Annotation> metadata = pop();
      Comment comment = _findComment(metadata, typedefKeyword);
      declarations.add(ast.functionTypeAlias(comment, metadata, typedefKeyword,
          returnType, name, typeParameters, parameters, semicolon));
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
      declarations.add(ast.genericTypeAlias(
          comment,
          metadata,
          typedefKeyword,
          name,
          templateParameters,
          equals,
          type as GenericFunctionType,
          semicolon));
    }
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    assert(optional('enum', enumKeyword));
    assert(optional('{', leftBrace));
    debugEvent("Enum");

    List<EnumConstantDeclaration> constants = popTypedList(count);
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, enumKeyword);
    declarations.add(ast.enumDeclaration(comment, metadata, enumKeyword, name,
        leftBrace, constants, leftBrace?.endGroup));
  }

  @override
  void endTypeArguments(int count, Token leftBracket, Token rightBracket) {
    assert(optional('<', leftBracket));
    assert(optional('>', rightBracket));
    debugEvent("TypeArguments");

    List<TypeAnnotation> arguments = popTypedList(count);
    push(ast.typeArgumentList(leftBracket, arguments, rightBracket));
  }

  @override
  void endFields(Token staticToken, Token covariantToken, Token varFinalOrConst,
      int count, Token beginToken, Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("Fields");

    List<VariableDeclaration> variables = popTypedList(count);
    TypeAnnotation type = pop();
    _Modifiers modifiers = new _Modifiers()
      ..staticKeyword = staticToken
      ..covariantKeyword = covariantToken
      ..finalConstOrVarKeyword = varFinalOrConst;
    var variableList = ast.variableDeclarationList(
        null, null, modifiers?.finalConstOrVarKeyword, type, variables);
    Token covariantKeyword = modifiers?.covariantKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    classDeclaration.members.add(ast.fieldDeclaration2(
        comment: comment,
        metadata: metadata,
        covariantKeyword: covariantKeyword,
        staticKeyword: modifiers?.staticKeyword,
        fieldList: variableList,
        semicolon: semicolon));
  }

  @override
  AstNode finishFields() {
    debugEvent("finishFields");

    return classDeclaration != null
        ? classDeclaration.members.removeAt(classDeclaration.members.length - 1)
        : declarations.removeLast();
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    assert(optional('operator', operatorKeyword));
    assert(token.type.isUserDefinableOperator);
    debugEvent("OperatorName");

    push(new _OperatorName(
        operatorKeyword, ast.simpleIdentifier(token, isDeclaration: true)));
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    assert(optional('operator', operatorKeyword));
    debugEvent("InvalidOperatorName");

    push(new _OperatorName(
        operatorKeyword, ast.simpleIdentifier(token, isDeclaration: true)));
  }

  @override
  void beginMetadataStar(Token token) {
    debugEvent("beginMetadataStar");
  }

  @override
  void endMetadata(Token atSign, Token periodBeforeName, Token endToken) {
    assert(optional('@', atSign));
    assert(optionalOrNull('.', periodBeforeName));
    debugEvent("Metadata");

    MethodInvocation invocation = pop();
    SimpleIdentifier constructorName = periodBeforeName != null ? pop() : null;
    pop(); // Type arguments, not allowed.
    Identifier name = pop();
    push(ast.annotation(atSign, name, periodBeforeName, constructorName,
        invocation?.argumentList));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");

    push(popTypedList<Annotation>(count) ?? NullValue.Metadata);
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

  /// Search the given list of [ranges] for a range that contains the given
  /// [index]. Return the range that was found, or `null` if none of the ranges
  /// contain the index.
  List<int> _findRange(List<List<int>> ranges, int index) {
    int rangeCount = ranges.length;
    for (int i = 0; i < rangeCount; i++) {
      List<int> range = ranges[i];
      if (range[0] <= index && index <= range[1]) {
        return range;
      } else if (index < range[0]) {
        return null;
      }
    }
    return null;
  }

  /// Return a list of the ranges of characters in the given [comment] that
  /// should be treated as code blocks.
  List<List<int>> _getCodeBlockRanges(String comment) {
    List<List<int>> ranges = <List<int>>[];
    int length = comment.length;
    if (length < 3) {
      return ranges;
    }
    int index = 0;
    int firstChar = comment.codeUnitAt(0);
    if (firstChar == 0x2F) {
      int secondChar = comment.codeUnitAt(1);
      int thirdChar = comment.codeUnitAt(2);
      if ((secondChar == 0x2A && thirdChar == 0x2A) ||
          (secondChar == 0x2F && thirdChar == 0x2F)) {
        index = 3;
      }
    }
    if (comment.startsWith('    ', index)) {
      int end = index + 4;
      while (end < length &&
          comment.codeUnitAt(end) != 0xD &&
          comment.codeUnitAt(end) != 0xA) {
        end = end + 1;
      }
      ranges.add(<int>[index, end]);
      index = end;
    }
    while (index < length) {
      int currentChar = comment.codeUnitAt(index);
      if (currentChar == 0xD || currentChar == 0xA) {
        index = index + 1;
        while (index < length &&
            Character.isWhitespace(comment.codeUnitAt(index))) {
          index = index + 1;
        }
        if (comment.startsWith('      ', index)) {
          int end = index + 6;
          while (end < length &&
              comment.codeUnitAt(end) != 0xD &&
              comment.codeUnitAt(end) != 0xA) {
            end = end + 1;
          }
          ranges.add(<int>[index, end]);
          index = end;
        }
      } else if (index + 1 < length &&
          currentChar == 0x5B &&
          comment.codeUnitAt(index + 1) == 0x3A) {
        int end = comment.indexOf(':]', index + 2);
        if (end < 0) {
          end = length;
        }
        ranges.add(<int>[index, end]);
        index = end + 1;
      } else {
        index = index + 1;
      }
    }
    return ranges;
  }

  ///
  /// Given that we have just found bracketed text within the given [comment],
  /// look to see whether that text is (a) followed by a parenthesized link
  /// address, (b) followed by a colon, or (c) followed by optional whitespace
  /// and another square bracket. The [rightIndex] is the index of the right
  /// bracket. Return `true` if the bracketed text is followed by a link
  /// address.
  ///
  /// This method uses the syntax described by the
  /// <a href="http://daringfireball.net/projects/markdown/syntax">markdown</a>
  /// project.
  bool _isLinkText(String comment, int rightIndex) {
    int length = comment.length;
    int index = rightIndex + 1;
    if (index >= length) {
      return false;
    }
    int nextChar = comment.codeUnitAt(index);
    if (nextChar == 0x28 || nextChar == 0x3A) {
      return true;
    }
    while (Character.isWhitespace(nextChar)) {
      index = index + 1;
      if (index >= length) {
        return false;
      }
      nextChar = comment.codeUnitAt(index);
    }
    return nextChar == 0x5B;
  }

  /// Parse a comment reference from the source between square brackets. The
  /// [referenceSource] is the source occurring between the square brackets
  /// within a documentation comment. The [sourceOffset] is the offset of the
  /// first character of the reference source. Return the comment reference that
  /// was parsed, or `null` if no reference could be found.
  /// ```
  /// commentReference ::=
  ///     'new'? prefixedIdentifier
  /// ```
  CommentReference _parseCommentReference(
      String referenceSource, int sourceOffset) {
    // TODO(brianwilkerson) The errors are not getting the right offset/length
    // and are being duplicated.
    void offsetTokens(Token token) {
      while (token.type != TokenType.EOF) {
        token.offset = token.offset + sourceOffset;
        token = token.next;
      }
    }

    try {
      BooleanErrorListener listener = new BooleanErrorListener();
      ScannerResult result = scanString(referenceSource);
      Token firstToken = result.tokens;
      offsetTokens(firstToken);
      if (listener.errorReported) {
        return null;
      }
      if (firstToken.type == TokenType.EOF) {
        Token syntheticToken =
            new SyntheticStringToken(TokenType.IDENTIFIER, "", sourceOffset);
        syntheticToken.setNext(firstToken);
        return ast.commentReference(null, ast.simpleIdentifier(syntheticToken));
      }
      Token newKeyword = null;
      if (_tokenMatchesKeyword(firstToken, Keyword.NEW)) {
        newKeyword = firstToken;
        firstToken = firstToken.next;
      }
      if (firstToken.isUserDefinableOperator) {
        if (firstToken.next.type != TokenType.EOF) {
          return null;
        }
        Identifier identifier = ast.simpleIdentifier(firstToken);
        return ast.commentReference(null, identifier);
      } else if (_tokenMatchesKeyword(firstToken, Keyword.OPERATOR)) {
        Token secondToken = firstToken.next;
        if (secondToken.isUserDefinableOperator) {
          if (secondToken.next.type != TokenType.EOF) {
            return null;
          }
          Identifier identifier = ast.simpleIdentifier(secondToken);
          return ast.commentReference(null, identifier);
        }
        return null;
      } else if (_tokenMatchesIdentifier(firstToken)) {
        Token secondToken = firstToken.next;
        Token thirdToken = secondToken.next;
        Token nextToken;
        Identifier identifier;
        if (_tokenMatches(secondToken, TokenType.PERIOD)) {
          if (thirdToken.isUserDefinableOperator) {
            identifier = ast.prefixedIdentifier(
                ast.simpleIdentifier(firstToken),
                secondToken,
                ast.simpleIdentifier(thirdToken));
            nextToken = thirdToken.next;
          } else if (_tokenMatchesKeyword(thirdToken, Keyword.OPERATOR)) {
            Token fourthToken = thirdToken.next;
            if (fourthToken.isUserDefinableOperator) {
              identifier = ast.prefixedIdentifier(
                  ast.simpleIdentifier(firstToken),
                  secondToken,
                  ast.simpleIdentifier(fourthToken));
              nextToken = fourthToken.next;
            } else {
              return null;
            }
          } else if (_tokenMatchesIdentifier(thirdToken)) {
            identifier = ast.prefixedIdentifier(
                ast.simpleIdentifier(firstToken),
                secondToken,
                ast.simpleIdentifier(thirdToken));
            nextToken = thirdToken.next;
          }
        } else {
          identifier = ast.simpleIdentifier(firstToken);
          nextToken = firstToken.next;
        }
        if (nextToken.type != TokenType.EOF) {
          return null;
        }
        return ast.commentReference(newKeyword, identifier);
      } else {
        Keyword keyword = firstToken.keyword;
        if (keyword == Keyword.THIS ||
            keyword == Keyword.NULL ||
            keyword == Keyword.TRUE ||
            keyword == Keyword.FALSE) {
          // TODO(brianwilkerson) If we want to support this we will need to
          // extend the definition of CommentReference to take an expression
          // rather than an identifier. For now we just ignore it to reduce the
          // number of errors produced, but that's probably not a valid long
          // term approach.
          return null;
        }
      }
    } catch (exception) {
      // Ignored because we assume that it wasn't a real comment reference.
    }
    return null;
  }

  /// Parse all of the comment references occurring in the given array of
  /// documentation comments. The [tokens] are the comment tokens representing
  /// the documentation comments to be parsed. Return the comment references that
  /// were parsed.
  /// ```
  /// commentReference ::=
  ///     '[' 'new'? qualified ']' libraryReference?
  ///
  /// libraryReference ::=
  ///      '(' stringLiteral ')'
  /// ```
  List<CommentReference> _parseCommentReferences(List<Token> tokens) {
    List<CommentReference> references = <CommentReference>[];
    bool isInGitHubCodeBlock = false;
    for (Token token in tokens) {
      String comment = token.lexeme;
      // Skip GitHub code blocks.
      // https://help.github.com/articles/creating-and-highlighting-code-blocks/
      if (tokens.length != 1) {
        if (comment.indexOf('```') != -1) {
          isInGitHubCodeBlock = !isInGitHubCodeBlock;
        }
        if (isInGitHubCodeBlock) {
          continue;
        }
      }
      // Remove GitHub include code.
      comment = _removeGitHubInlineCode(comment);
      // Find references.
      int length = comment.length;
      List<List<int>> codeBlockRanges = _getCodeBlockRanges(comment);
      int leftIndex = comment.indexOf('[');
      while (leftIndex >= 0 && leftIndex + 1 < length) {
        List<int> range = _findRange(codeBlockRanges, leftIndex);
        if (range == null) {
          int nameOffset = token.offset + leftIndex + 1;
          int rightIndex = comment.indexOf(']', leftIndex);
          if (rightIndex >= 0) {
            int firstChar = comment.codeUnitAt(leftIndex + 1);
            if (firstChar != 0x27 && firstChar != 0x22) {
              if (_isLinkText(comment, rightIndex)) {
                // TODO(brianwilkerson) Handle the case where there's a library
                // URI in the link text.
              } else {
                CommentReference reference = _parseCommentReference(
                    comment.substring(leftIndex + 1, rightIndex), nameOffset);
                if (reference != null) {
                  references.add(reference);
                }
              }
            }
          } else {
            // terminating ']' is not typed yet
            int charAfterLeft = comment.codeUnitAt(leftIndex + 1);
            Token nameToken;
            if (Character.isLetterOrDigit(charAfterLeft)) {
              int nameEnd = StringUtilities.indexOfFirstNotLetterDigit(
                  comment, leftIndex + 1);
              String name = comment.substring(leftIndex + 1, nameEnd);
              nameToken =
                  new StringToken(TokenType.IDENTIFIER, name, nameOffset);
            } else {
              nameToken = new SyntheticStringToken(
                  TokenType.IDENTIFIER, '', nameOffset);
            }
            nameToken.setNext(new Token.eof(nameToken.end));
            references.add(
                ast.commentReference(null, ast.simpleIdentifier(nameToken)));
            // next character
            rightIndex = leftIndex + 1;
          }
          leftIndex = comment.indexOf('[', rightIndex);
        } else {
          leftIndex = comment.indexOf('[', range[1]);
        }
      }
    }
    return references;
  }

  /// Parse a documentation comment. Return the documentation comment that was
  /// parsed, or `null` if there was no comment.
  Comment _parseDocumentationCommentOpt(Token commentToken) {
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
    List<CommentReference> references = _parseCommentReferences(tokens);
    return tokens.isEmpty ? null : ast.documentationComment(tokens, references);
  }

  /// Remove any substrings in the given [comment] that represent in-line code
  /// in markdown.
  String _removeGitHubInlineCode(String comment) {
    int index = 0;
    while (true) {
      int beginIndex = comment.indexOf('`', index);
      if (beginIndex == -1) {
        break;
      }
      int endIndex = comment.indexOf('`', beginIndex + 1);
      if (endIndex == -1) {
        break;
      }
      comment = comment.substring(0, beginIndex + 1) +
          ' ' * (endIndex - beginIndex - 1) +
          comment.substring(endIndex);
      index = endIndex + 1;
    }
    return comment;
  }

  /// Return `true` if the given [token] has the given [type].
  bool _tokenMatches(Token token, TokenType type) => token.type == type;

  /// Return `true` if the given [token] is a valid identifier. Valid
  /// identifiers include built-in identifiers (pseudo-keywords).
  bool _tokenMatchesIdentifier(Token token) =>
      _tokenMatches(token, TokenType.IDENTIFIER) ||
      _tokenMatchesPseudoKeyword(token);

  /// Return `true` if the given [token] matches the given [keyword].
  bool _tokenMatchesKeyword(Token token, Keyword keyword) =>
      token.keyword == keyword;

  /// Return `true` if the given [token] matches a pseudo keyword.
  bool _tokenMatchesPseudoKeyword(Token token) =>
      token.keyword?.isBuiltInOrPseudo ?? false;

  @override
  void debugEvent(String name) {
    // printEvent('AstBuilder: $name');
  }

  @override
  void discardTypeReplacedWithCommentTypeAssign() {
    pop();
  }

  @override
  void addCompileTimeError(Message message, int offset, int length) {
    if (directives.isEmpty &&
        message.code.analyzerCode == 'NON_PART_OF_DIRECTIVE_IN_PART') {
      message = messageDirectiveAfterDeclaration;
    }
    errorReporter.reportMessage(message, offset, length);
  }

  /// Return `true` if [token] is either `null` or is the symbol or keyword
  /// [value].
  bool optionalOrNull(String value, Token token) {
    return token == null || identical(value, token.stringValue);
  }

  List<T> popTypedList<T>(int count, [List<T> list]) {
    if (count == 0) return null;
    assert(stack.arrayLength >= count);

    final table = stack.array;
    final length = stack.arrayLength;

    final tailList = list ?? new List<T>.filled(count, null, growable: true);
    final startIndex = length - count;
    for (int i = 0; i < count; i++) {
      final value = table[startIndex + i];
      tailList[i] = value is NullValue ? null : value;
      table[startIndex + i] = null;
    }
    stack.arrayLength -= count;

    return tailList;
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

  _Modifiers([List<Token> modifierTokens]) {
    // No need to check the order and uniqueness of the modifiers, or that
    // disallowed modifiers are not used; the parser should do that.
    // TODO(paulberry,ahe): implement the necessary logic in the parser.
    if (modifierTokens != null) {
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

  /// Return the `const` keyword or `null`.
  Token get constKeyword {
    return identical('const', finalConstOrVarKeyword?.lexeme)
        ? finalConstOrVarKeyword
        : null;
  }
}
