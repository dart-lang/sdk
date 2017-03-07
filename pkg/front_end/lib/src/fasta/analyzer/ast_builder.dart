// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.ast_builder;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast_factory.dart' show AstFactory;
import 'package:analyzer/dart/ast/standard_ast_factory.dart' as standard;
import 'package:analyzer/dart/ast/token.dart' as analyzer show Token;
import 'package:analyzer/dart/element/element.dart' show Element;
import '../parser/parser.dart' show FormalParameterType;
import '../scanner/token.dart' show BeginGroupToken, Token;

import '../errors.dart' show internalError;
import '../kernel/kernel_builder.dart'
    show Builder, KernelLibraryBuilder, ProcedureBuilder;
import '../parser/identifier_context.dart' show IdentifierContext;
import '../quote.dart';
import '../source/scope_listener.dart'
    show JumpTargetKind, NullValue, Scope, ScopeListener;
import 'analyzer.dart' show toKernel;
import 'element_store.dart'
    show
        AnalyzerLocalVariableElemment,
        AnalyzerParameterElement,
        ElementStore,
        KernelClassElement;
import 'token_utils.dart' show toAnalyzerToken;

class AstBuilder extends ScopeListener {
  final AstFactory ast = standard.astFactory;

  final KernelLibraryBuilder library;

  final Builder member;

  final ElementStore elementStore;

  @override
  final Uri uri;

  /// The name of the class currently being parsed, or `null` if no class is
  /// being parsed.
  String className;

  AstBuilder(this.library, this.member, this.elementStore, Scope scope,
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
        toAnalyzerToken(periodBeforeName), constructorName));
  }

  @override
  void handleConstExpression(Token token) {
    debugEvent("ConstExpression");
    _handleInstanceCreation(token);
  }

  void _handleInstanceCreation(Token token) {
    MethodInvocation arguments = pop();
    ConstructorName constructorName = pop();
    push(ast.instanceCreationExpression(
        toAnalyzerToken(token), constructorName, arguments.argumentList));
  }

  @override
  void handleNewExpression(Token token) {
    debugEvent("NewExpression");
    _handleInstanceCreation(token);
  }

  @override
  void handleParenthesizedExpression(BeginGroupToken token) {
    debugEvent("ParenthesizedExpression");
    Expression expression = pop();
    push(ast.parenthesizedExpression(
        toAnalyzerToken(token), expression, toAnalyzerToken(token.endGroup)));
  }

  void handleStringPart(Token token) {
    debugEvent("StringPart");
    push(token);
  }

  void doStringPart(Token token) {
    push(ast.simpleStringLiteral(toAnalyzerToken(token), token.value));
  }

  void endLiteralString(int interpolationCount) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop();
      String value = unescapeString(token.value);
      push(ast.simpleStringLiteral(toAnalyzerToken(token), value));
    } else {
      List parts = popList(1 + interpolationCount * 2);
      Token first = parts.first;
      Token last = parts.last;
      Quote quote = analyzeQuote(first.value);
      List<InterpolationElement> elements = <InterpolationElement>[];
      elements.add(ast.interpolationString(
          toAnalyzerToken(first), unescapeFirstStringPart(first.value, quote)));
      for (int i = 1; i < parts.length - 1; i++) {
        var part = parts[i];
        if (part is Token) {
          elements
              .add(ast.interpolationString(toAnalyzerToken(part), part.value));
        } else if (part is Expression) {
          elements.add(ast.interpolationExpression(null, part, null));
        } else {
          internalError(
              "Unexpected part in string interpolation: ${part.runtimeType}");
        }
      }
      elements.add(ast.interpolationString(
          toAnalyzerToken(last), unescapeLastStringPart(last.value, quote)));
      push(ast.stringInterpolation(elements));
    }
  }

  void handleScript(Token token) {
    debugEvent("Script");
    push(ast.scriptTag(toAnalyzerToken(token)));
  }

  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    push(ast.adjacentStrings(popList(literalCount)));
  }

  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    List expressions = popList(count);
    ArgumentList arguments = ast.argumentList(
        toAnalyzerToken(beginToken), expressions, toAnalyzerToken(endToken));
    push(ast.methodInvocation(null, null, null, null, arguments));
  }

  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    analyzer.Token analyzerToken = toAnalyzerToken(token);

    if (context.inSymbol) {
      push(analyzerToken);
      return;
    }

    SimpleIdentifier identifier = ast.simpleIdentifier(analyzerToken);
    if (context.inLibraryOrPartOfDeclaration) {
      if (!context.isContinuation) {
        push([identifier]);
      } else {
        push(identifier);
      }
    } else if (context == IdentifierContext.enumValueDeclaration) {
      // TODO(paulberry): analyzer's ASTs allow for enumerated values to have
      // metadata, but the spec doesn't permit it.
      List<Annotation> metadata;
      // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
      Comment comment = null;
      push(ast.enumConstantDeclaration(comment, metadata, identifier));
    } else {
      if (context.isScopeReference) {
        String name = token.value;
        Builder builder = scope.lookup(name, token.charOffset, uri);
        if (builder != null) {
          Element element = elementStore[builder];
          assert(element != null);
          identifier.staticElement = element;
        }
      } else if (context == IdentifierContext.classDeclaration) {
        className = identifier.name;
      }
      push(identifier);
    }
  }

  void endSend(Token token) {
    debugEvent("Send");
    MethodInvocation arguments = pop();
    TypeArgumentList typeArguments = pop();
    if (arguments != null) {
      doInvocation(token, typeArguments, arguments);
    } else {
      doPropertyGet(token);
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
    push(ast.expressionStatement(pop(), toAnalyzerToken(token)));
  }

  void endFunctionBody(int count, Token beginToken, Token endToken) {
    debugEvent("FunctionBody");
    List statements = popList(count);
    if (beginToken != null) {
      exitLocalScope();
    }
    Block block = ast.block(
        toAnalyzerToken(beginToken), statements, toAnalyzerToken(endToken));
    analyzer.Token star = pop();
    analyzer.Token asyncKeyword = pop();
    push(ast.blockFunctionBody(asyncKeyword, star, block));
  }

  void finishFunction(formals, asyncModifier, FunctionBody body) {
    debugEvent("finishFunction");
    Statement bodyStatement;
    if (body is ExpressionFunctionBody) {
      bodyStatement = ast.returnStatement(null, body.expression, null);
    } else {
      bodyStatement = (body as BlockFunctionBody).block;
    }
    var kernel = toKernel(bodyStatement, elementStore, library.library, scope);
    if (member is ProcedureBuilder) {
      ProcedureBuilder builder = member;
      builder.body = kernel;
    } else {
      internalError("Internal error: expected procedure, but got: $member");
    }
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
    push(toAnalyzerToken(token));
  }

  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid");
    push(toAnalyzerToken(token));
  }

  void handleBinaryExpression(Token token) {
    debugEvent("BinaryExpression");
    if (identical(".", token.stringValue) ||
        identical("?.", token.stringValue) ||
        identical("..", token.stringValue)) {
      doDotExpression(token);
    } else {
      Expression right = pop();
      Expression left = pop();
      push(ast.binaryExpression(left, toAnalyzerToken(token), right));
    }
  }

  void doDotExpression(Token token) {
    Expression identifierOrInvoke = pop();
    Expression receiver = pop();
    if (identifierOrInvoke is SimpleIdentifier) {
      if (receiver is SimpleIdentifier && identical('.', token.stringValue)) {
        push(ast.prefixedIdentifier(
            receiver, toAnalyzerToken(token), identifierOrInvoke));
      } else {
        push(ast.propertyAccess(
            receiver, toAnalyzerToken(token), identifierOrInvoke));
      }
    } else if (identifierOrInvoke is MethodInvocation) {
      assert(identifierOrInvoke.target == null);
      identifierOrInvoke
        ..target = receiver
        ..operator = toAnalyzerToken(token);
      push(identifierOrInvoke);
    } else {
      internalError(
          "Unhandled property access: ${identifierOrInvoke.runtimeType}");
    }
  }

  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    push(ast.integerLiteral(toAnalyzerToken(token), int.parse(token.value)));
  }

  void endExpressionFunctionBody(Token arrowToken, Token endToken) {
    debugEvent("ExpressionFunctionBody");
    Expression expression = pop();
    analyzer.Token star = pop();
    analyzer.Token asyncKeyword = pop();
    assert(star == null);
    push(ast.expressionFunctionBody(asyncKeyword, toAnalyzerToken(arrowToken),
        expression, toAnalyzerToken(endToken)));
  }

  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    debugEvent("ReturnStatement");
    Expression expression = hasExpression ? pop() : null;
    push(ast.returnStatement(
        toAnalyzerToken(beginToken), expression, toAnalyzerToken(endToken)));
  }

  void endIfStatement(Token ifToken, Token elseToken) {
    Statement elsePart = popIfNotNull(elseToken);
    Statement thenPart = pop();
    Expression condition = pop();
    BeginGroupToken leftParenthesis = ifToken.next;
    push(ast.ifStatement(
        toAnalyzerToken(ifToken),
        toAnalyzerToken(ifToken.next),
        condition,
        toAnalyzerToken(leftParenthesis.endGroup),
        thenPart,
        toAnalyzerToken(elseToken),
        elsePart));
  }

  void prepareInitializers() {
    debugEvent("prepareInitializers");
  }

  void handleNoInitializers() {
    debugEvent("NoInitializers");
  }

  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    popList(count);
  }

  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer");
    assert(assignmentOperator.stringValue == "=");
    Expression initializer = pop();
    Identifier identifier = pop();
    // TODO(ahe): Don't push initializers, instead install them.
    push(ast.variableDeclaration(
        identifier, toAnalyzerToken(assignmentOperator), initializer));
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
  }

  void endInitializedIdentifier() {
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
      internalError("unhandled identifier: ${node.runtimeType}");
    }
    push(variable);
    scope[variable.name.name] = variable.name.staticElement =
        new AnalyzerLocalVariableElemment(variable);
  }

  void endVariablesDeclaration(int count, Token endToken) {
    debugEvent("VariablesDeclaration");
    List<VariableDeclaration> variables = popList(count);
    TypeName type = pop();
    pop(); // TODO(paulberry): Modifiers.
    push(ast.variableDeclarationStatement(
        ast.variableDeclarationList(null, null, null, type, variables),
        toAnalyzerToken(endToken)));
  }

  void handleAssignmentExpression(Token token) {
    debugEvent("AssignmentExpression");
    Expression rhs = pop();
    Expression lhs = pop();
    push(ast.assignmentExpression(lhs, toAnalyzerToken(token), rhs));
  }

  void endBlock(int count, Token beginToken, Token endToken) {
    debugEvent("Block");
    List<Statement> statements = popList(count) ?? <Statement>[];
    exitLocalScope();
    push(ast.block(
        toAnalyzerToken(beginToken), statements, toAnalyzerToken(endToken)));
  }

  void endForStatement(
      int updateExpressionCount, Token beginToken, Token endToken) {
    debugEvent("ForStatement");
    Statement body = pop();
    List<Expression> updates = popList(updateExpressionCount);
    ExpressionStatement condition = pop();
    VariableDeclarationStatement variables = pop();
    exitContinueTarget();
    exitBreakTarget();
    exitLocalScope();
    BeginGroupToken leftParenthesis = beginToken.next;
    push(ast.forStatement(
        toAnalyzerToken(beginToken),
        toAnalyzerToken(leftParenthesis),
        variables?.variables,
        null, // initialization.
        variables?.semicolon,
        condition.expression,
        condition.semicolon,
        updates,
        toAnalyzerToken(leftParenthesis.endGroup),
        body));
  }

  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    debugEvent("LiteralList");
    List<Expression> expressions = popList(count);
    TypeArgumentList typeArguments = pop();
    push(ast.listLiteral(toAnalyzerToken(constKeyword), typeArguments,
        toAnalyzerToken(beginToken), expressions, toAnalyzerToken(endToken)));
  }

  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
    push(toAnalyzerToken(asyncToken) ?? NullValue.FunctionBodyAsyncToken);
    push(toAnalyzerToken(starToken) ?? NullValue.FunctionBodyStarToken);
  }

  void endAwaitExpression(Token beginToken, Token endToken) {
    debugEvent("AwaitExpression");
    push(ast.awaitExpression(toAnalyzerToken(beginToken), pop()));
  }

  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = identical(token.stringValue, "true");
    assert(value || identical(token.stringValue, "false"));
    push(ast.booleanLiteral(toAnalyzerToken(token), value));
  }

  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(ast.doubleLiteral(toAnalyzerToken(token), double.parse(token.value)));
  }

  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(ast.nullLiteral(toAnalyzerToken(token)));
  }

  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    debugEvent("LiteralMap");
    List<MapLiteralEntry> entries = popList(count) ?? <MapLiteralEntry>[];
    TypeArgumentList typeArguments = pop();
    push(ast.mapLiteral(toAnalyzerToken(constKeyword), typeArguments,
        toAnalyzerToken(beginToken), entries, toAnalyzerToken(endToken)));
  }

  void endLiteralMapEntry(Token colon, Token endToken) {
    debugEvent("LiteralMapEntry");
    Expression value = pop();
    Expression key = pop();
    push(ast.mapLiteralEntry(key, toAnalyzerToken(colon), value));
  }

  void endLiteralSymbol(Token hashToken, int tokenCount) {
    debugEvent("LiteralSymbol");
    List<analyzer.Token> components = popList(tokenCount);
    push(ast.symbolLiteral(toAnalyzerToken(hashToken), components));
  }

  @override
  void handleSuperExpression(Token token) {
    debugEvent("SuperExpression");
    push(ast.superExpression(toAnalyzerToken(token)));
  }

  @override
  void handleThisExpression(Token token) {
    debugEvent("ThisExpression");
    push(ast.thisExpression(toAnalyzerToken(token)));
  }

  void handleType(Token beginToken, Token endToken) {
    debugEvent("Type");
    TypeArgumentList arguments = pop();
    Identifier name = pop();
    // TODO(paulberry,ahe): what if the type doesn't resolve to a class
    // element?  Try to share code with BodyBuilder.builderToFirstExpression.
    KernelClassElement cls = name.staticElement;
    push(ast.typeName(name, arguments)..type = cls?.rawType);
  }

  void handleAsOperator(Token operator, Token endToken) {
    debugEvent("AsOperator");
    TypeAnnotation type = pop();
    Expression expression = pop();
    push(ast.asExpression(expression, toAnalyzerToken(operator), type));
  }

  void handleIsOperator(Token operator, Token not, Token endToken) {
    debugEvent("IsOperator");
    TypeName type = pop();
    Expression expression = pop();
    push(ast.isExpression(
        expression, toAnalyzerToken(operator), toAnalyzerToken(not), type));
  }

  void handleConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = pop();
    Expression thenExpression = pop();
    Expression condition = pop();
    push(ast.conditionalExpression(condition, toAnalyzerToken(question),
        thenExpression, toAnalyzerToken(colon), elseExpression));
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    debugEvent("RethrowStatement");
    RethrowExpression expression =
        ast.rethrowExpression(toAnalyzerToken(rethrowToken));
    // TODO(scheglov) According to the specification, 'rethrow' is a statement.
    push(ast.expressionStatement(expression, toAnalyzerToken(endToken)));
  }

  void endThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    push(ast.throwExpression(toAnalyzerToken(throwToken), pop()));
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

  void handleFunctionType(Token functionToken, Token semicolon) {
    debugEvent("FunctionType");
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    TypeAnnotation returnType = pop();
    push(ast.genericFunctionType(returnType, toAnalyzerToken(functionToken),
        typeParameters, parameters));
  }

  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
    push(NullValue.ParameterDefaultValue);
  }

  void endFormalParameter(
      Token covariantKeyword, Token thisKeyword, FormalParameterType kind) {
    debugEvent("FormalParameter");
    _ParameterDefaultValue defaultValue = pop();

    AstNode nameOrFunctionTypedParameter = pop();

    FormalParameter node;
    SimpleIdentifier name;
    if (nameOrFunctionTypedParameter is FormalParameter) {
      node = nameOrFunctionTypedParameter;
      name = nameOrFunctionTypedParameter.identifier;
    } else {
      name = nameOrFunctionTypedParameter;
      TypeAnnotation type = pop();
      _Modifiers modifiers = pop();
      Token keyword = modifiers?.finalConstOrVarKeyword;
      pop(); // TODO(paulberry): Metadata.
      if (thisKeyword == null) {
        node = ast.simpleFormalParameter2(
            covariantKeyword: toAnalyzerToken(covariantKeyword),
            keyword: toAnalyzerToken(keyword),
            type: type,
            identifier: name);
      } else {
        // TODO(scheglov): Ideally the period token should be passed in.
        Token period = identical('.', thisKeyword.next?.stringValue)
            ? thisKeyword.next
            : null;
        node = ast.fieldFormalParameter2(
            covariantKeyword: toAnalyzerToken(covariantKeyword),
            keyword: toAnalyzerToken(keyword),
            type: type,
            thisKeyword: toAnalyzerToken(thisKeyword),
            period: toAnalyzerToken(period),
            identifier: name);
      }
    }

    ParameterKind analyzerKind = _toAnalyzerParameterKind(kind);
    if (analyzerKind != ParameterKind.REQUIRED) {
      node = ast.defaultFormalParameter(node, analyzerKind,
          toAnalyzerToken(defaultValue?.separator), defaultValue?.value);
    }

    if (name != null) {
      scope[name.name] =
          name.staticElement = new AnalyzerParameterElement(node);
    }
    push(node);
  }

  @override
  void endFunctionTypedFormalParameter(
      Token covariantKeyword, Token thisKeyword, FormalParameterType kind) {
    debugEvent("FunctionTypedFormalParameter");

    FormalParameterList formalParameters = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    TypeName returnType = pop();

    {
      _Modifiers modifiers = pop();
      if (modifiers != null) {
        // TODO(scheglov): Report error.
        internalError('Unexpected modifier. Report an error.');
      }
    }

    pop(); // TODO(paulberry): Metadata.

    FormalParameter node;
    if (thisKeyword == null) {
      node = ast.functionTypedFormalParameter2(
          covariantKeyword: toAnalyzerToken(covariantKeyword),
          returnType: returnType,
          identifier: name,
          typeParameters: typeParameters,
          parameters: formalParameters);
    } else {
      // TODO(scheglov): Ideally the period token should be passed in.
      Token period = identical('.', thisKeyword?.next?.stringValue)
          ? thisKeyword.next
          : null;
      node = ast.fieldFormalParameter2(
          covariantKeyword: toAnalyzerToken(covariantKeyword),
          type: returnType,
          thisKeyword: toAnalyzerToken(thisKeyword),
          period: toAnalyzerToken(period),
          identifier: name,
          typeParameters: typeParameters,
          parameters: formalParameters);
    }

    scope[name.name] = name.staticElement = new AnalyzerParameterElement(node);
    push(node);
  }

  void endFormalParameters(int count, Token beginToken, Token endToken) {
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
        toAnalyzerToken(beginToken),
        parameters,
        toAnalyzerToken(leftDelimiter),
        toAnalyzerToken(rightDelimiter),
        toAnalyzerToken(endToken)));
  }

  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    debugEvent("CatchBlock");
    Block body = pop();
    FormalParameterList catchParameters = popIfNotNull(catchKeyword);
    if (catchKeyword != null) {
      exitLocalScope();
    }
    TypeName type = popIfNotNull(onKeyword);
    SimpleIdentifier exception;
    SimpleIdentifier stackTrace;
    if (catchParameters != null) {
      if (catchParameters.length > 0) {
        exception = catchParameters.parameters[0].identifier;
      }
      if (catchParameters.length > 1) {
        stackTrace = catchParameters.parameters[1].identifier;
      }
    }
    BeginGroupToken leftParenthesis = catchKeyword.next;
    push(ast.catchClause(
        toAnalyzerToken(onKeyword),
        type,
        toAnalyzerToken(catchKeyword),
        toAnalyzerToken(leftParenthesis),
        exception,
        null,
        stackTrace,
        toAnalyzerToken(leftParenthesis.endGroup),
        body));
  }

  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    Block finallyBlock = popIfNotNull(finallyKeyword);
    List<CatchClause> catchClauses = popList(catchCount);
    Block body = pop();
    push(ast.tryStatement(toAnalyzerToken(tryKeyword), body, catchClauses,
        toAnalyzerToken(finallyKeyword), finallyBlock));
  }

  void handleNoExpression(Token token) {
    debugEvent("NoExpression");
    push(NullValue.Expression);
  }

  void handleIndexedExpression(
      Token openCurlyBracket, Token closeCurlyBracket) {
    debugEvent("IndexedExpression");
    Expression index = pop();
    Expression target = pop();
    if (target == null) {
      CascadeExpression receiver = pop();
      Token token = peek();
      push(receiver);
      IndexExpression expression = ast.indexExpressionForCascade(
          toAnalyzerToken(token),
          toAnalyzerToken(openCurlyBracket),
          index,
          toAnalyzerToken(closeCurlyBracket));
      assert(expression.isCascaded);
      push(expression);
    } else {
      push(ast.indexExpressionForTarget(
          target,
          toAnalyzerToken(openCurlyBracket),
          index,
          toAnalyzerToken(closeCurlyBracket)));
    }
  }

  void handleUnaryPrefixExpression(Token token) {
    debugEvent("UnaryPrefixExpression");
    push(ast.prefixExpression(toAnalyzerToken(token), pop()));
  }

  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression");
    push(ast.prefixExpression(toAnalyzerToken(token), pop()));
  }

  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression");
    push(ast.postfixExpression(pop(), toAnalyzerToken(token)));
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
    analyzer.Token propertyKeyword = toAnalyzerToken(getOrSet);
    TypeAnnotation returnType = pop();
    _Modifiers modifiers = pop();
    Token externalKeyword = modifiers?.externalKeyword;
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.functionDeclaration(
        comment,
        metadata,
        toAnalyzerToken(externalKeyword),
        returnType,
        propertyKeyword,
        name,
        ast.functionExpression(typeParameters, parameters, body)));
  }

  @override
  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration");
  }

  @override
  void endCompilationUnit(int count, Token token) {
    debugEvent("CompilationUnit");
    analyzer.Token beginToken = null; // TODO(paulberry)
    ScriptTag scriptTag = null;
    var directives = <Directive>[];
    var declarations = <CompilationUnitMember>[];
    analyzer.Token endToken = null; // TODO(paulberry)
    List<Object> elements = popList(count);
    if (elements != null) {
      for (AstNode node in elements) {
        if (node is ScriptTag) {
          scriptTag = node;
        } else if (node is Directive) {
          directives.add(node);
        } else if (node is CompilationUnitMember) {
          declarations.add(node);
        } else {
          internalError(
              'Unrecognized compilation unit member: ${node.runtimeType}');
        }
      }
    }
    push(ast.compilationUnit(
        beginToken, scriptTag, directives, declarations, endToken));
  }

  void endImport(Token importKeyword, Token deferredKeyword, Token asKeyword,
      Token semicolon) {
    debugEvent("Import");
    List<Combinator> combinators = pop();
    SimpleIdentifier prefix;
    if (asKeyword != null) prefix = pop();
    List<Configuration> configurations = pop();
    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    assert(metadata == null);
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.importDirective(
        comment,
        metadata,
        toAnalyzerToken(importKeyword),
        uri,
        configurations,
        toAnalyzerToken(deferredKeyword),
        toAnalyzerToken(asKeyword),
        prefix,
        combinators,
        toAnalyzerToken(semicolon)));
  }

  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
    List<Combinator> combinators = pop();
    List<Configuration> configurations = pop();
    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    assert(metadata == null);
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.exportDirective(comment, metadata, toAnalyzerToken(exportKeyword),
        uri, configurations, combinators, toAnalyzerToken(semicolon)));
  }

  @override
  void endDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    List<SimpleIdentifier> components = popList(count);
    push(ast.dottedName(components));
  }

  void endConditionalUri(Token ifKeyword, Token equalitySign) {
    debugEvent("ConditionalUri");
    StringLiteral libraryUri = pop();
    // TODO(paulberry,ahe): the parser should report the right paren token to
    // the listener.
    Token rightParen = null;
    StringLiteral value;
    if (equalitySign != null) {
      value = pop();
    }
    DottedName name = pop();
    // TODO(paulberry,ahe): what if there is no `(` token due to an error in the
    // file being parsed?  It seems like we need the parser to do adequate error
    // recovery and then report both the ifKeyword and leftParen tokens to the
    // listener.
    Token leftParen = ifKeyword.next;
    push(ast.configuration(
        toAnalyzerToken(ifKeyword),
        toAnalyzerToken(leftParen),
        name,
        toAnalyzerToken(equalitySign),
        value,
        toAnalyzerToken(rightParen),
        libraryUri));
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
    push(ast.showCombinator(toAnalyzerToken(showKeyword), shownNames));
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("Hide");
    List<SimpleIdentifier> hiddenNames = pop();
    push(ast.hideCombinator(toAnalyzerToken(hideKeyword), hiddenNames));
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popList(count) ?? NullValue.TypeList);
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
    push(new _ClassBody(
        beginToken, popList(memberCount) ?? <ClassMember>[], endToken));
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    debugEvent("ClassDeclaration");
    _ClassBody body = pop();
    ImplementsClause implementsClause;
    if (implementsKeyword != null) {
      List<TypeName> interfaces = popList(interfacesCount);
      implementsClause =
          ast.implementsClause(toAnalyzerToken(implementsKeyword), interfaces);
    }
    ExtendsClause extendsClause;
    WithClause withClause;
    var supertype = pop();
    if (supertype == null) {
      // No extends clause
    } else if (supertype is TypeName) {
      extendsClause =
          ast.extendsClause(toAnalyzerToken(extendsKeyword), supertype);
    } else if (supertype is _MixinApplication) {
      extendsClause = ast.extendsClause(
          toAnalyzerToken(extendsKeyword), supertype.supertype);
      withClause = ast.withClause(
          toAnalyzerToken(supertype.withKeyword), supertype.mixinTypes);
    } else {
      internalError('Unexpected kind of supertype ${supertype.runtimeType}');
    }
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    assert(className == name.name);
    className = null;
    _Modifiers modifiers = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.classDeclaration(
        comment,
        metadata,
        toAnalyzerToken(abstractKeyword),
        toAnalyzerToken(classKeyword),
        name,
        typeParameters,
        extendsClause,
        withClause,
        implementsClause,
        toAnalyzerToken(body.beginToken),
        body.members,
        toAnalyzerToken(body.endToken)));
  }

  @override
  void endMixinApplication() {
    debugEvent("MixinApplication");
    List<TypeName> mixinTypes = pop();
    // TODO(paulberry,ahe): the parser doesn't give us enough information to
    // locate the "with" keyword.
    Token withKeyword;
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
      implementsClause =
          ast.implementsClause(toAnalyzerToken(implementsKeyword), interfaces);
    }
    _MixinApplication mixinApplication = pop();
    var superclass = mixinApplication.supertype;
    var withClause = ast.withClause(
        toAnalyzerToken(mixinApplication.withKeyword),
        mixinApplication.mixinTypes);
    analyzer.Token equals = toAnalyzerToken(equalsToken);
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    _Modifiers modifiers = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.classTypeAlias(
        comment,
        metadata,
        toAnalyzerToken(classKeyword),
        name,
        typeParameters,
        equals,
        toAnalyzerToken(abstractKeyword),
        superclass,
        withClause,
        implementsClause,
        toAnalyzerToken(endToken)));
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("LibraryName");
    List<SimpleIdentifier> libraryName = pop();
    var name = ast.libraryIdentifier(libraryName);
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.libraryDirective(comment, metadata,
        toAnalyzerToken(libraryKeyword), name, toAnalyzerToken(semicolon)));
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
      push(ast.prefixedIdentifier(prefix, toAnalyzerToken(period), identifier));
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
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.partDirective(comment, metadata, toAnalyzerToken(partKeyword), uri,
        toAnalyzerToken(semicolon)));
  }

  @override
  void endPartOf(Token partKeyword, Token semicolon) {
    debugEvent("PartOf");
    List<SimpleIdentifier> libraryName = pop();
    var name = ast.libraryIdentifier(libraryName);
    StringLiteral uri = null; // TODO(paulberry)
    // TODO(paulberry,ahe): seems hacky.  It would be nice if the parser passed
    // in a reference to the "of" keyword.
    var ofKeyword = partKeyword.next;
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.partOfDirective(comment, metadata, toAnalyzerToken(partKeyword),
        toAnalyzerToken(ofKeyword), uri, name, toAnalyzerToken(semicolon)));
  }

  void endUnnamedFunction(Token token) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.  Note that this is tricky due to the handling of initializers
    // in constructors, so the logic should be shared with BodyBuilder as much
    // as possible.
    debugEvent("UnnamedFunction");
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

  void endFieldInitializer(Token assignment) {
    debugEvent("FieldInitializer");
    Expression initializer = pop();
    SimpleIdentifier name = pop();
    push(ast.variableDeclaration(
        name, toAnalyzerToken(assignment), initializer));
  }

  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("TopLevelFields");
    List<VariableDeclaration> variables = popList(count);
    TypeAnnotation type = pop();
    _Modifiers modifiers = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    var variableList = ast.variableDeclarationList(
        null, null, toAnalyzerToken(keyword), type, variables);
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.topLevelVariableDeclaration(
        comment, metadata, variableList, toAnalyzerToken(endToken)));
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
    List<Annotation> metadata = null; // TODO(paulberry)
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.typeParameter(
        comment, metadata, name, toAnalyzerToken(extendsOrSuper), bound));
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    List<TypeParameter> typeParameters = popList(count);
    push(ast.typeParameterList(toAnalyzerToken(beginToken), typeParameters,
        toAnalyzerToken(endToken)));
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    debugEvent("Method");
    FunctionBody body = pop();
    ConstructorName redirectedConstructor = null; // TODO(paulberry)
    List<ConstructorInitializer> initializers = null; // TODO(paulberry)
    Token separator = null; // TODO(paulberry)
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop(); // TODO(paulberry)
    var name = pop();
    TypeAnnotation returnType = pop(); // TODO(paulberry)
    _Modifiers modifiers = pop();
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    Token period;
    void unnamedConstructor(
        SimpleIdentifier returnType, SimpleIdentifier name) {
      push(ast.constructorDeclaration(
          comment,
          metadata,
          toAnalyzerToken(modifiers?.externalKeyword),
          toAnalyzerToken(modifiers?.finalConstOrVarKeyword),
          null, // TODO(paulberry): factoryKeyword
          returnType,
          toAnalyzerToken(period),
          name,
          parameters,
          toAnalyzerToken(separator),
          initializers,
          redirectedConstructor,
          body));
    }

    void method(Token operatorKeyword, SimpleIdentifier name) {
      push(ast.methodDeclaration(
          comment,
          metadata,
          toAnalyzerToken(modifiers?.externalKeyword),
          toAnalyzerToken(
              modifiers?.abstractKeyword ?? modifiers?.staticKeyword),
          returnType,
          toAnalyzerToken(getOrSet),
          toAnalyzerToken(operatorKeyword),
          name,
          typeParameters,
          parameters,
          body));
    }

    if (name is SimpleIdentifier) {
      if (name.name == className) {
        unnamedConstructor(name, null);
      } else {
        method(null, name);
      }
    } else if (name is _OperatorName) {
      method(name.operatorKeyword, name.name);
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
      // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
      Comment comment = null;
      push(ast.functionTypeAlias(
          comment,
          metadata,
          toAnalyzerToken(typedefKeyword),
          returnType,
          name,
          typeParameters,
          parameters,
          toAnalyzerToken(endToken)));
    } else {
      TypeAnnotation type = pop();
      TypeParameterList templateParameters = pop();
      SimpleIdentifier name = pop();
      List<Annotation> metadata = pop();
      // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
      Comment comment = null;
      if (type is! GenericFunctionType) {
        // TODO(paulberry) Generate an error and recover (better than
        // this).
        type = null;
      }
      push(ast.genericTypeAlias(
          comment,
          metadata,
          toAnalyzerToken(typedefKeyword),
          name,
          templateParameters,
          toAnalyzerToken(equals),
          type,
          toAnalyzerToken(endToken)));
    }
  }

  @override
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    debugEvent("Enum");
    List<EnumConstantDeclaration> constants = popList(count);
    // TODO(paulberry,ahe): the parser should pass in the openBrace token.
    var openBrace = enumKeyword.next.next as BeginGroupToken;
    // TODO(paulberry): what if the '}' is missing and the parser has performed
    // error recovery?
    Token closeBrace = openBrace.endGroup;
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.enumDeclaration(
        comment,
        metadata,
        toAnalyzerToken(enumKeyword),
        name,
        toAnalyzerToken(openBrace),
        constants,
        toAnalyzerToken(closeBrace)));
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    List<TypeAnnotation> arguments = popList(count);
    push(ast.typeArgumentList(
        toAnalyzerToken(beginToken), arguments, toAnalyzerToken(endToken)));
  }

  @override
  void endFields(
      int count, Token covariantKeyword, Token beginToken, Token endToken) {
    debugEvent("Fields");
    List<VariableDeclaration> variables = popList(count);
    TypeAnnotation type = pop();
    _Modifiers modifiers = pop();
    var variableList = ast.variableDeclarationList(null, null,
        toAnalyzerToken(modifiers?.finalConstOrVarKeyword), type, variables);
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.  See dartbug.com/28851.
    Comment comment = null;
    push(ast.fieldDeclaration2(
        comment: comment,
        metadata: metadata,
        covariantKeyword: toAnalyzerToken(covariantKeyword),
        staticKeyword: toAnalyzerToken(modifiers?.staticKeyword),
        fieldList: variableList,
        semicolon: toAnalyzerToken(endToken)));
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(new _OperatorName(operatorKeyword,
        ast.simpleIdentifier(toAnalyzerToken(token), isDeclaration: true)));
  }

  ParameterKind _toAnalyzerParameterKind(FormalParameterType type) {
    if (type == FormalParameterType.POSITIONAL) {
      return ParameterKind.POSITIONAL;
    } else if (type == FormalParameterType.NAMED) {
      return ParameterKind.NAMED;
    } else {
      return ParameterKind.REQUIRED;
    }
  }
}

/// Data structure placed on the stack to represent a class body.
///
/// This is needed because analyzer has no separate AST representation of a
/// class body; it simply stores all of the relevant data in the
/// [ClassDeclaration] object.
class _ClassBody {
  final Token beginToken;

  final List<ClassMember> members;

  final Token endToken;

  _ClassBody(this.beginToken, this.members, this.endToken);
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

  _Modifiers(List<Token> modifierTokens) {
    // No need to check the order and uniqueness of the modifiers, or that
    // disallowed modifiers are not used; the parser should do that.
    // TODO(paulberry,ahe): implement the necessary logic in the parser.
    for (var token in modifierTokens) {
      var s = token.value;
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
      } else {
        internalError('Unhandled modifier: $s');
      }
    }
  }
}
