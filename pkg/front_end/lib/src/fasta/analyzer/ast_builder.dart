// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.ast_builder;

import 'package:front_end/src/fasta/scanner/token.dart'
    show BeginGroupToken, Token;

import 'package:analyzer/analyzer.dart';

import 'package:analyzer/dart/ast/token.dart' as analyzer show Token;

import 'package:analyzer/dart/element/element.dart' show Element;

import 'package:analyzer/dart/ast/ast_factory.dart' show AstFactory;

import 'package:analyzer/dart/ast/standard_ast_factory.dart' as standard;

import 'package:kernel/ast.dart' show AsyncMarker;

import '../errors.dart' show internalError;

import '../source/scope_listener.dart'
    show JumpTargetKind, NullValue, Scope, ScopeListener;

import '../kernel/kernel_builder.dart'
    show Builder, KernelLibraryBuilder, ProcedureBuilder;

import '../quote.dart';

import '../source/outline_builder.dart' show asyncMarkerFromTokens;

import 'element_store.dart'
    show
        AnalyzerLocalVariableElemment,
        AnalyzerParameterElement,
        ElementStore,
        KernelClassElement;

import 'token_utils.dart' show toAnalyzerToken;

import 'analyzer.dart' show toKernel;

class AstBuilder extends ScopeListener {
  final AstFactory ast = standard.astFactory;

  final KernelLibraryBuilder library;

  final Builder member;

  final ElementStore elementStore;

  bool isFirstIdentifier = false;

  AstBuilder(this.library, this.member, this.elementStore, Scope scope)
      : super(scope);

  Uri get uri => library.fileUri ?? library.uri;

  createJumpTarget(JumpTargetKind kind, int charOffset) {
    // TODO(ahe): Implement jump targets.
    return null;
  }

  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
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

  void beginExpression(Token token) {
    isFirstIdentifier = true;
  }

  void handleIdentifier(Token token) {
    debugEvent("handleIdentifier");
    String name = token.value;
    SimpleIdentifier identifier = ast.simpleIdentifier(toAnalyzerToken(token));
    if (isFirstIdentifier) {
      Builder builder = scope.lookup(name, token.charOffset, uri);
      if (builder != null) {
        Element element = elementStore[builder];
        assert(element != null);
        identifier.staticElement = element;
      }
    }
    push(identifier);
    isFirstIdentifier = false;
  }

  void endSend(Token token) {
    debugEvent("Send");
    MethodInvocation arguments = pop();
    TypeArgumentList typeArguments = pop();
    if (arguments != null) {
      if (typeArguments != null) {
        arguments.typeArguments = typeArguments;
      }
      doInvocation(token, arguments);
    } else {
      doPropertyGet(token);
    }
  }

  void doInvocation(Token token, MethodInvocation arguments) {
    Expression receiver = pop();
    if (receiver is SimpleIdentifier) {
      arguments.methodName = receiver;
      push(arguments);
    } else {
      internalError("Unhandled receiver in send: ${receiver.runtimeType}");
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
    push(ast.block(
        toAnalyzerToken(beginToken), statements, toAnalyzerToken(endToken)));
  }

  void finishFunction(formals, asyncModifier, Statement body) {
    debugEvent("finishFunction");
    var kernel = toKernel(body, elementStore, library.library, scope);
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

  void handleBinaryExpression(Token token) {
    debugEvent("BinaryExpression");
    if (identical(".", token.stringValue) ||
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
      push(ast.propertyAccess(
          receiver, toAnalyzerToken(token), identifierOrInvoke));
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

  void endInitializedIdentifier() {
    debugEvent("InitializedIdentifier");
    AstNode node = pop();
    VariableDeclaration variable;
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
    pop(); // Modifiers.
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
    push(asyncMarkerFromTokens(asyncToken, starToken));
  }

  void endAwaitExpression(Token beginToken, Token endToken) {
    debugEvent("AwaitExpression");
    push(ast.awaitExpression(toAnalyzerToken(beginToken), pop()));
  }

  void beginLiteralSymbol(Token token) {
    isFirstIdentifier = false;
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

  void endLiteralSymbol(Token hashToken, int identifierCount) {
    debugEvent("LiteralSymbol");
    List<analyzer.Token> components = new List<analyzer.Token>(identifierCount);
    for (int i = identifierCount - 1; i >= 0; i--) {
      SimpleIdentifier identifier = pop();
      components[i] = identifier.token;
    }
    push(ast.symbolLiteral(toAnalyzerToken(hashToken), components));
  }

  void endType(Token beginToken, Token endToken) {
    debugEvent("Type");
    TypeArgumentList arguments = pop();
    SimpleIdentifier name = pop();
    KernelClassElement cls = name.staticElement;
    if (cls == null) {
      Builder builder = scope.lookup(name.name, beginToken.charOffset, uri);
      if (builder == null) {
        internalError("Undefined name: $name");
      }
      // TODO(paulberry,ahe): what if the type doesn't resolve to a class
      // element?
      cls = elementStore[builder];
      assert(cls != null);
      name.staticElement = cls;
    }
    push(ast.typeName(name, arguments)..type = cls.rawType);
  }

  void handleAsOperator(Token operator, Token endToken) {
    debugEvent("AsOperator");
    TypeName type = pop();
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

  void endThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    push(ast.throwExpression(toAnalyzerToken(throwToken), pop()));
  }

  void endFormalParameter(Token thisKeyword) {
    debugEvent("FormalParameter");
    if (thisKeyword != null) {
      internalError("'this' can't be used here.");
    }
    SimpleIdentifier name = pop();
    TypeName type = pop();
    pop(); // Modifiers.
    pop(); // Metadata.
    SimpleFormalParameter node = ast.simpleFormalParameter(
        null, null, toAnalyzerToken(thisKeyword), type, name);
    scope[name.name] = name.staticElement = new AnalyzerParameterElement(node);
    push(node);
  }

  void endFormalParameters(int count, Token beginToken, Token endToken) {
    debugEvent("FormalParameters");
    List<FormalParameter> parameters = popList(count) ?? <FormalParameter>[];
    push(ast.formalParameterList(toAnalyzerToken(beginToken), parameters, null,
        null, toAnalyzerToken(endToken)));
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
    // TODO(ahe): Don't ignore modifiers.
  }

  void handleModifiers(int count) {
    debugEvent("Modifiers");
    // TODO(ahe): Don't ignore modifiers.
    push(NullValue.Modifiers);
  }

  FunctionBody _endFunctionBody() {
    AstNode body = pop();
    // TODO(paulberry): asyncMarker should have a type that allows constructing
    // the necessary analyzer AST data structures.
    AsyncMarker asyncMarker = pop();
    assert(asyncMarker == AsyncMarker.Sync);
    analyzer.Token asyncKeyword = null;
    analyzer.Token star = null;
    if (body is Block) {
      return ast.blockFunctionBody(asyncKeyword, star, body);
    } else if (body is ReturnStatement) {
      assert(star == null);
      return ast.expressionFunctionBody(
          asyncKeyword, body.returnKeyword, body.expression, body.semicolon);
    } else {
      return internalError(
          'Unexpected function body type: ${body.runtimeType}');
    }
  }

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    debugEvent("TopLevelMethod");
    FunctionBody body = _endFunctionBody();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    analyzer.Token propertyKeyword = toAnalyzerToken(getOrSet);
    TypeAnnotation returnType = pop();
    // TODO(paulberry): handle modifiers.
    var modifiers = pop();
    assert(modifiers == null);
    analyzer.Token externalKeyword = null;
    List<Annotation> metadata = pop();
    // TODO(paulberry): capture doc comments.
    Comment comment = null;
    push(ast.functionDeclaration(
        comment,
        metadata,
        externalKeyword,
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
    ScriptTag scriptTag = null; // TODO(paulberry)
    var directives = <Directive>[];
    var declarations = <CompilationUnitMember>[];
    analyzer.Token endToken = null; // TODO(paulberry)
    for (AstNode node in popList(count)) {
      if (node is Directive) {
        directives.add(node);
      } else if (node is CompilationUnitMember) {
        declarations.add(node);
      } else {
        internalError(
            'Unrecognized compilation unit member: ${node.runtimeType}');
      }
    }
    push(ast.compilationUnit(
        beginToken, scriptTag, directives, declarations, endToken));
  }
}
