// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.node_listener;

import 'package:front_end/src/fasta/parser/parser.dart'
    show FormalParameterType, MemberKind;
import 'package:front_end/src/fasta/parser/identifier_context.dart'
    show IdentifierContext;
import 'package:front_end/src/fasta/scanner.dart' show Token;
import 'package:front_end/src/scanner/token.dart' show TokenType;

import '../common.dart';
import '../elements/elements.dart' show CompilationUnitElement;
import '../tree/tree.dart';
import '../util/util.dart' show Link;
import 'element_listener.dart' show ElementListener, ScannerOptions;

import 'package:front_end/src/fasta/parser/parser.dart' as fasta show Assert;

class NodeListener extends ElementListener {
  NodeListener(ScannerOptions scannerOptions, DiagnosticReporter reporter,
      CompilationUnitElement element)
      : super(scannerOptions, reporter, element, null);

  @override
  void addLibraryTag(LibraryTag tag) {
    pushNode(tag);
  }

  @override
  void addPartOfTag(PartOf tag) {
    pushNode(tag);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    Expression name = popNode();
    pushNode(new LibraryName(
        libraryKeyword,
        name,
        // TODO(sigmund): Import AST nodes have pointers to MetadataAnnotation
        // (element) instead of Metatada (node).
        null));
  }

  @override
  void endImport(Token importKeyword, Token deferredKeyword, Token asKeyword,
      Token semicolon) {
    NodeList combinators = popNode();
    Identifier prefix = asKeyword != null ? popNode() : null;
    NodeList conditionalUris = popNode();
    StringNode uri = popLiteralString();
    pushNode(new Import(
        importKeyword,
        uri,
        conditionalUris,
        prefix,
        combinators,
        // TODO(sigmund): Import AST nodes have pointers to MetadataAnnotation
        // (element) instead of Metatada (node).
        null,
        isDeferred: deferredKeyword != null));
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    NodeList combinators = popNode();
    NodeList conditionalUris = popNode();
    StringNode uri = popLiteralString();
    pushNode(new Export(
        exportKeyword,
        uri,
        conditionalUris,
        combinators,
        // TODO(sigmund): Import AST nodes have pointers to MetadataAnnotation
        // (element) instead of Metatada (node).
        null));
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    StringNode uri = popLiteralString();
    pushNode(new Part(
        partKeyword,
        uri,
        // TODO(sigmund): Import AST nodes have pointers to MetadataAnnotation
        // (element) instead of Metatada (node).
        null));
  }

  @override
  void endPartOf(Token partKeyword, Token semicolon, bool hasName) {
    Expression name = popNode(); // name
    pushNode(new PartOf(
        partKeyword,
        name,
        // TODO(sigmund): Import AST nodes have pointers to MetadataAnnotation
        // (element) instead of Metatada (node).
        null));
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    NodeList body = popNode();
    NodeList interfaces =
        makeNodeList(interfacesCount, implementsKeyword, null, ",");
    Node supertype = popNode();
    NodeList typeParameters = popNode();
    Identifier name = popNode();
    Modifiers modifiers = popNode();
    pushNode(new ClassNode(modifiers, name, typeParameters, supertype,
        interfaces, beginToken, extendsKeyword, body, endToken));
  }

  @override
  void endTopLevelDeclaration(Token token) {
    // TODO(sigmund): consider moving metadata into each declaration
    // element instead.
    Node node = popNode(); // top-level declaration
    popNode(); // Discard metadata
    pushNode(node);
    super.endTopLevelDeclaration(token);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    pushNode(makeNodeList(count, null, null, '\n'));
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    bool isGeneralizedTypeAlias;
    NodeList templateParameters;
    TypeAnnotation returnType;
    Identifier name;
    NodeList typeParameters;
    NodeList formals;
    if (equals == null) {
      isGeneralizedTypeAlias = false;
      formals = popNode();
      templateParameters = popNode();
      name = popNode();
      returnType = popNode();
    } else {
      // TODO(floitsch): keep using the `FunctionTypeAnnotation' node.
      isGeneralizedTypeAlias = true;
      Node type = popNode();
      if (type.asFunctionTypeAnnotation() == null) {
        // TODO(floitsch): The parser should diagnose this problem, not
        // this listener.
        // However, this problem goes away, when we allow aliases for
        // non-function types too.
        reportFatalError(type, 'Expected a function type.');
      }
      FunctionTypeAnnotation functionType = type;
      templateParameters = popNode();
      name = popNode();
      returnType = functionType.returnType;
      typeParameters = functionType.typeParameters;
      formals = functionType.formals;
    }
    pushNode(new Typedef(isGeneralizedTypeAlias, templateParameters, returnType,
        name, typeParameters, formals, typedefKeyword, endToken));
  }

  void handleNoName(Token token) {
    pushNode(null);
  }

  @override
  void handleFunctionType(Token functionToken, Token endToken) {
    NodeList formals = popNode();
    NodeList typeParameters = popNode();
    TypeAnnotation returnType = popNode();
    pushNode(new FunctionTypeAnnotation(
        returnType, functionToken, typeParameters, formals));
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    NodeList interfaces = (implementsKeyword != null) ? popNode() : null;
    Node mixinApplication = popNode();
    NodeList typeParameters = popNode();
    Identifier name = popNode();
    Modifiers modifiers = popNode();
    pushNode(new NamedMixinApplication(name, typeParameters, modifiers,
        mixinApplication, interfaces, beginToken, endToken));
  }

  @override
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    NodeList names = makeNodeList(count, enumKeyword.next.next, endBrace, ",");
    Identifier name = popNode();
    pushNode(new Enum(enumKeyword, name, names));
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    pushNode(makeNodeList(memberCount, beginToken, endToken, null));
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    NodeList variables = makeNodeList(count, null, endToken, ",");
    TypeAnnotation type = popNode();
    Modifiers modifiers = popNode();
    pushNode(new VariableDefinitions(type, modifiers, variables));
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    Statement body = popNode();
    AsyncModifier asyncModifier = popNode();
    NodeList formals = popNode();
    NodeList typeVariables = popNode();
    Identifier name = popNode();
    TypeAnnotation type = popNode();
    Modifiers modifiers = popNode();
    pushNode(new FunctionExpression(name, typeVariables, formals, body, type,
        modifiers, null, getOrSet, asyncModifier));
  }

  @override
  void endFormalParameter(Token thisKeyword, Token nameToken,
      FormalParameterType kind, MemberKind memberKind) {
    Expression name = popNode();
    if (thisKeyword != null) {
      Identifier thisIdentifier = new Identifier(thisKeyword);
      if (name.asSend() == null) {
        name = new Send(thisIdentifier, name);
      } else {
        name = name.asSend().copyWithReceiver(thisIdentifier, false);
      }
    }
    TypeAnnotation type = popNode();
    Modifiers modifiers = popNode();
    NodeList metadata = popNode();
    pushNode(new VariableDefinitions.forParameter(
        metadata, type, modifiers, new NodeList.singleton(name)));
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    pushNode(makeNodeList(count, beginToken, endToken, ","));
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    pushNode(null);
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    pushNode(makeNodeList(count, beginToken, endToken, ","));
  }

  @override
  void handleNoArguments(Token token) {
    pushNode(null);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    Identifier name = null;
    if (periodBeforeName != null) {
      name = popNode();
    }
    NodeList typeArguments = popNode();
    Node classReference = popNode();
    if (typeArguments != null) {
      classReference = new NominalTypeAnnotation(classReference, typeArguments);
    } else {
      Identifier identifier = classReference.asIdentifier();
      Send send = classReference.asSend();
      if (identifier != null) {
        // TODO(ahe): Should be:
        // classReference = new Send(null, identifier);
        classReference = identifier;
      } else if (send != null) {
        classReference = send;
      } else {
        internalError(node: classReference);
      }
    }
    Node constructor = classReference;
    if (name != null) {
      // Either typeName<args>.name or x.y.name.
      constructor = new Send(classReference, name);
    }
    pushNode(constructor);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    pushNode(new RedirectingFactoryBody(beginToken, endToken, popNode()));
  }

  void handleEmptyFunctionBody(Token semicolon) {
    endBlockFunctionBody(0, null, semicolon);
  }

  void handleExpressionFunctionBody(Token arrowToken, Token endToken) {
    endReturnStatement(true, arrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    Expression expression = hasExpression ? popNode() : null;
    pushNode(new Return(beginToken, endToken, expression));
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    Expression expression = popNode();
    pushNode(new Yield(yieldToken, starToken, expression, endToken));
  }

  @override
  void endExpressionStatement(Token token) {
    pushNode(new ExpressionStatement(popNode(), token));
  }

  void handleOnError(Token token, var errorInformation) {
    reporter.internalError(reporter.spanFromToken(token),
        "'${token.lexeme}': ${errorInformation}");
  }

  @override
  void handleLiteralInt(Token token) {
    pushNode(new LiteralInt(token, (t, e) => handleOnError(t, e)));
  }

  @override
  void handleLiteralDouble(Token token) {
    pushNode(new LiteralDouble(token, (t, e) => handleOnError(t, e)));
  }

  @override
  void handleLiteralBool(Token token) {
    pushNode(new LiteralBool(token, (t, e) => handleOnError(t, e)));
  }

  @override
  void handleLiteralNull(Token token) {
    pushNode(new LiteralNull(token));
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    NodeList identifiers = makeNodeList(identifierCount, null, null, '.');
    pushNode(new LiteralSymbol(hashToken, identifiers));
  }

  @override
  void handleBinaryExpression(Token token) {
    Node argument = popNode();
    Node receiver = popNode();
    String tokenString = token.stringValue;
    if (identical(tokenString, '.') ||
        identical(tokenString, '..') ||
        identical(tokenString, '?.')) {
      Send argumentSend = argument.asSend();
      if (argumentSend == null) {
        // TODO(ahe): The parser should diagnose this problem, not
        // this listener.
        reportFatalError(
            reporter.spanFromSpannable(argument), "Expected an identifier.");
      }
      if (argumentSend.receiver != null) internalError(node: argument);
      if (argument is SendSet) internalError(node: argument);
      pushNode(argument
          .asSend()
          .copyWithReceiver(receiver, identical(tokenString, '?.')));
    } else {
      NodeList arguments = new NodeList.singleton(argument);
      pushNode(new Send(receiver, new Operator(token), arguments));
    }
    if (identical(tokenString, '===')) {
      reporter.reportErrorMessage(reporter.spanFromToken(token),
          MessageKind.UNSUPPORTED_EQ_EQ_EQ, {'lhs': receiver, 'rhs': argument});
    }
    if (identical(tokenString, '!==')) {
      reporter.reportErrorMessage(
          reporter.spanFromToken(token),
          MessageKind.UNSUPPORTED_BANG_EQ_EQ,
          {'lhs': receiver, 'rhs': argument});
    }
  }

  @override
  void beginCascade(Token token) {
    pushNode(new CascadeReceiver(popNode(), token));
  }

  @override
  void endCascade() {
    pushNode(new Cascade(popNode()));
  }

  @override
  void handleAsOperator(Token operator, Token endToken) {
    TypeAnnotation type = popNode();
    Expression expression = popNode();
    NodeList arguments = new NodeList.singleton(type);
    pushNode(new Send(expression, new Operator(operator), arguments));
  }

  @override
  void handleAssignmentExpression(Token token) {
    Node arg = popNode();
    Node node = popNode();
    Send send = node.asSend();
    if (send == null || !(send.isPropertyAccess || send.isIndex)) {
      reportNotAssignable(node);
    }
    if (send.asSendSet() != null) internalError(node: send);
    NodeList arguments;
    if (send.isIndex) {
      Link<Node> link = const Link<Node>().prepend(arg);
      link = link.prepend(send.arguments.head);
      arguments = new NodeList(null, link);
    } else {
      arguments = new NodeList.singleton(arg);
    }
    Operator op = new Operator(token);
    pushNode(new SendSet(
        send.receiver, send.selector, op, arguments, send.isConditional));
  }

  void reportNotAssignable(Node node) {
    // TODO(ahe): The parser should diagnose this problem, not this
    // listener.
    reportFatalError(reporter.spanFromSpannable(node), "Not assignable.");
  }

  @override
  void handleConditionalExpression(Token question, Token colon) {
    Node elseExpression = popNode();
    Node thenExpression = popNode();
    Node condition = popNode();
    pushNode(new Conditional(
        condition, thenExpression, elseExpression, question, colon));
  }

  @override
  void endSend(Token beginToken, Token endToken) {
    NodeList arguments = popNode();
    NodeList typeArguments = popNode();
    Node selector = popNode();
    // TODO(ahe): Handle receiver.
    pushNode(new Send(null, selector, arguments, typeArguments));
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    if (count == 0 && beginToken == null) {
      pushNode(new EmptyStatement(endToken));
    } else {
      pushNode(new Block(makeNodeList(count, beginToken, endToken, null)));
    }
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    if (asyncToken != null) {
      pushNode(new AsyncModifier(asyncToken, starToken));
    } else {
      pushNode(null);
    }
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    pushNode(new Block(new NodeList.empty()));
  }

  @override
  void handleNoFunctionBody(Token token) {
    pushNode(new EmptyStatement(token));
  }

  @override
  void endFunction(Token getOrSet, Token endToken) {
    Statement body = popNode();
    AsyncModifier asyncModifier = popNode();
    NodeList initializers = popNode();
    NodeList formals = popNode();
    NodeList typeVariables = popNode();
    // The name can be an identifier or a send in case of named constructors.
    Expression name = popNode();
    TypeAnnotation type = popNode();
    Modifiers modifiers = popNode();
    pushNode(new FunctionExpression(name, typeVariables, formals, body, type,
        modifiers, initializers, getOrSet, asyncModifier));
  }

  @override
  void endFunctionDeclaration(Token endToken) {
    pushNode(new FunctionDeclaration(popNode()));
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    // TODO(ahe): Pick one name for this concept, either
    // VariablesDeclaration or VariableDefinitions.
    NodeList variables = makeNodeList(count, null, endToken, ",");
    TypeAnnotation type = popNode();
    Modifiers modifiers = popNode();
    popNode();
    pushNode(new VariableDefinitions(type, modifiers, variables));
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    Expression initializer = popNode();
    NodeList arguments =
        initializer == null ? null : new NodeList.singleton(initializer);
    Expression name = popNode();
    Operator op = new Operator(assignmentOperator);
    pushNode(new SendSet(null, name, op, arguments));
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    endVariableInitializer(assignmentOperator);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    Statement elsePart = (elseToken == null) ? null : popNode();
    Statement thenPart = popNode();
    ParenthesizedExpression condition = popNode();
    pushNode(new If(condition, thenPart, elsePart, ifToken, elseToken));
  }

  @override
  void endForStatement(Token forKeyword, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    Statement body = popNode();
    NodeList updates = makeNodeList(updateExpressionCount, null, null, ',');
    Statement condition = popNode();
    Node initializer = popNode();
    pushNode(new For(initializer, condition, updates, body, forKeyword));
  }

  @override
  void handleNoExpression(Token token) {
    pushNode(null);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    Expression condition = popNode();
    Statement body = popNode();
    pushNode(new DoWhile(body, condition, doKeyword, whileKeyword, endToken));
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    Statement body = popNode();
    Expression condition = popNode();
    pushNode(new While(condition, body, whileKeyword));
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    pushNode(new Block(makeNodeList(count, beginToken, endToken, null)));
  }

  @override
  void endThrowExpression(Token throwToken, Token endToken) {
    Expression expression = popNode();
    pushNode(new Throw(expression, throwToken, endToken));
  }

  @override
  void endAwaitExpression(Token awaitToken, Token endToken) {
    Expression expression = popNode();
    pushNode(new Await(awaitToken, expression));
  }

  @override
  void endRethrowStatement(Token throwToken, Token endToken) {
    pushNode(new Rethrow(throwToken, endToken));
    if (identical(throwToken.stringValue, 'throw')) {
      reporter.reportErrorMessage(reporter.spanFromToken(throwToken),
          MessageKind.MISSING_EXPRESSION_IN_THROW);
    }
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    pushNode(new Send.prefix(popNode(), new Operator(token)));
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    pushNode(new Identifier(token));
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    pushNode(new Identifier(token));
  }

  void handleUnaryAssignmentExpression(Token token, bool isPrefix) {
    Node node = popNode();
    Send send = node.asSend();
    if (send == null) {
      reportNotAssignable(node);
    }
    if (!(send.isPropertyAccess || send.isIndex)) {
      reportNotAssignable(node);
    }
    if (send.asSendSet() != null) internalError(node: send);
    Node argument = null;
    if (send.isIndex) argument = send.arguments.head;
    Operator op = new Operator(token);

    if (isPrefix) {
      pushNode(new SendSet.prefix(
          send.receiver, send.selector, op, argument, send.isConditional));
    } else {
      pushNode(new SendSet.postfix(
          send.receiver, send.selector, op, argument, send.isConditional));
    }
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    handleUnaryAssignmentExpression(token, false);
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    handleUnaryAssignmentExpression(token, true);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    pushNode(makeNodeList(count, beginToken, null, ','));
  }

  @override
  void handleNoInitializers() {
    pushNode(null);
  }

  @override
  void endMember() {
    // TODO(sigmund): consider moving metadata into each declaration
    // element instead.
    Node node = popNode(); // member
    popNode(); // Discard metadata
    pushNode(node);
    super.endMember();
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    NodeList variables = makeNodeList(count, null, endToken, ",");
    TypeAnnotation type = popNode();
    Modifiers modifiers = popNode();
    pushNode(new VariableDefinitions(type, modifiers, variables));
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    Statement body = popNode();
    AsyncModifier asyncModifier = popNode();
    NodeList initializers = popNode();
    NodeList formalParameters = popNode();
    NodeList typeVariables = popNode();
    Expression name = popNode();
    TypeAnnotation returnType = popNode();
    Modifiers modifiers = popNode();
    pushNode(new FunctionExpression(name, typeVariables, formalParameters, body,
        returnType, modifiers, initializers, getOrSet, asyncModifier));
  }

  @override
  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    NodeList entries = makeNodeList(count, beginToken, endToken, ',');
    NodeList typeArguments = popNode();
    pushNode(new LiteralMap(typeArguments, entries, constKeyword));
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
    Expression value = popNode();
    Expression key = popNode();
    pushNode(new LiteralMapEntry(key, colon, value));
  }

  @override
  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    NodeList elements = makeNodeList(count, beginToken, endToken, ',');
    pushNode(new LiteralList(popNode(), elements, constKeyword));
  }

  @override
  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    NodeList arguments =
        makeNodeList(1, openSquareBracket, closeSquareBracket, null);
    Node receiver = popNode();
    Token token = new Token(TokenType.INDEX, openSquareBracket.charOffset);
    Node selector = new Operator(token);
    pushNode(new Send(receiver, selector, arguments));
  }

  @override
  void endNewExpression(Token token) {
    NodeList arguments = popNode();
    Node name = popNode();
    pushNode(new NewExpression(token, new Send(null, name, arguments)));
  }

  @override
  void endConstExpression(Token token) {
    // [token] carries the 'const' information.
    endNewExpression(token);
  }

  @override
  void handleOperator(Token token) {
    pushNode(new Operator(token));
  }

  @override
  void handleSymbolVoid(Token token) {
    logEvent('SymbolVoid');
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    Operator op = new Operator(token);
    pushNode(new Send(new Identifier(operatorKeyword), op, null));
  }

  @override
  void handleNamedArgument(Token colon) {
    Expression expression = popNode();
    Identifier name = popNode();
    pushNode(new NamedArgument(name, colon, expression));
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    pushNode(makeNodeList(count, beginToken, endToken, ','));
  }

  @override
  void endFunctionTypedFormalParameter(
      Token thisKeyword, FormalParameterType kind) {
    NodeList formals = popNode();
    NodeList typeVariables = popNode();
    Identifier name = popNode();
    TypeAnnotation returnType = popNode();
    pushNode(null); // Signal "no type" to endFormalParameter.
    pushNode(new FunctionExpression(name, typeVariables, formals, null,
        returnType, Modifiers.EMPTY, null, null, null));
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    Expression defaultValue = popNode();
    Expression parameterName = popNode();
    pushNode(new SendSet(null, parameterName, new Operator(equals),
        new NodeList.singleton(defaultValue)));
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {}

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    Block finallyBlock = null;
    if (finallyKeyword != null) {
      finallyBlock = popNode();
    }
    NodeList catchBlocks = makeNodeList(catchCount, null, null, null);
    Block tryBlock = popNode();
    pushNode(new TryStatement(
        tryBlock, catchBlocks, finallyBlock, tryKeyword, finallyKeyword));
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    pushNode(new CaseMatch(caseKeyword, popNode(), colon));
  }

  @override
  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    Block block = popNode();
    NodeList formals = catchKeyword != null ? popNode() : null;
    TypeAnnotation type = onKeyword != null ? popNode() : null;
    pushNode(new CatchBlock(type, formals, block, onKeyword, catchKeyword));
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    NodeList cases = popNode();
    ParenthesizedExpression expression = popNode();
    pushNode(new SwitchStatement(expression, cases, switchKeyword));
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    Link<Node> caseNodes = const Link<Node>();
    while (caseCount > 0) {
      SwitchCase switchCase = popNode();
      caseNodes = caseNodes.prepend(switchCase);
      caseCount--;
    }
    pushNode(new NodeList(beginToken, caseNodes, endToken, null));
  }

  @override
  void handleSwitchCase(int labelCount, int caseCount, Token defaultKeyword,
      int statementCount, Token firstToken, Token endToken) {
    NodeList statements = makeNodeList(statementCount, null, null, null);
    NodeList labelsAndCases =
        makeNodeList(labelCount + caseCount, null, null, null);
    pushNode(
        new SwitchCase(labelsAndCases, defaultKeyword, statements, firstToken));
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    Identifier target = null;
    if (hasTarget) {
      target = popNode();
    }
    pushNode(new BreakStatement(target, breakKeyword, endToken));
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    Identifier target = null;
    if (hasTarget) {
      target = popNode();
    }
    pushNode(new ContinueStatement(target, continueKeyword, endToken));
  }

  @override
  void handleEmptyStatement(Token token) {
    pushNode(new EmptyStatement(token));
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    super.endFactoryMethod(beginToken, factoryKeyword, endToken);
    Statement body = popNode();
    AsyncModifier asyncModifier = popNode();
    NodeList formals = popNode();
    Node name = popNode();
    popNode(); // Discard modifiers. They're recomputed below.

    // TODO(ahe): Move this parsing to the parser.
    int modifierCount = 0;
    Token modifier = beginToken;
    if (modifier.stringValue == "external") {
      handleModifier(modifier);
      modifierCount++;
      modifier = modifier.next;
    }
    if (modifier.stringValue == "const") {
      handleModifier(modifier);
      modifierCount++;
      modifier = modifier.next;
    }
    assert(modifier.stringValue == "factory");
    handleModifier(modifier);
    modifierCount++;
    handleModifiers(modifierCount);
    Modifiers modifiers = popNode();

    pushNode(new FunctionExpression(
        name, null, formals, body, null, modifiers, null, null, asyncModifier));
  }

  @override
  void endForIn(Token awaitToken, Token forToken, Token leftParenthesis,
      Token inKeyword, Token rightParenthesis, Token endToken) {
    Statement body = popNode();
    Expression expression = popNode();
    Node declaredIdentifier = popNode();
    if (awaitToken == null) {
      pushNode(new SyncForIn(
          declaredIdentifier, expression, body, forToken, inKeyword));
    } else {
      pushNode(new AsyncForIn(declaredIdentifier, expression, body, awaitToken,
          forToken, inKeyword));
    }
  }

  @override
  void endMetadataStar(int count, bool forParameter) {
    if (0 == count) {
      pushNode(null);
    } else {
      pushNode(makeNodeList(count, null, null, ' '));
    }
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    NodeList arguments = popNode();
    if (arguments == null) {
      // This is a constant expression.
      Identifier name;
      if (periodBeforeName != null) {
        name = popNode();
      }
      NodeList typeArguments = popNode();
      Node receiver = popNode();
      if (typeArguments != null) {
        receiver = new NominalTypeAnnotation(receiver, typeArguments);
        recoverableError(typeArguments, 'Type arguments are not allowed here.');
      } else {
        Identifier identifier = receiver.asIdentifier();
        Send send = receiver.asSend();
        if (identifier != null) {
          receiver = new Send(null, identifier);
        } else if (send == null) {
          internalError(node: receiver);
        }
      }
      Send send = receiver;
      if (name != null) {
        send = new Send(receiver, name);
      }
      pushNode(new Metadata(beginToken, send));
    } else {
      // This is a const constructor call.
      endConstructorReference(beginToken, periodBeforeName, endToken);
      Node constructor = popNode();
      pushNode(new Metadata(beginToken,
          new NewExpression(null, new Send(null, constructor, arguments))));
    }
  }

  @override
  void endAssert(Token assertKeyword, fasta.Assert kind, Token leftParenthesis,
      Token commaToken, Token rightParenthesis, Token semicolonToken) {
    Node message;
    Node condition;
    if (commaToken != null) {
      message = popNode();
    }
    condition = popNode();
    pushNode(new Assert(assertKeyword, condition, message, semicolonToken));
  }

  @override
  void endUnnamedFunction(Token beginToken, Token token) {
    Statement body = popNode();
    AsyncModifier asyncModifier = popNode();
    NodeList formals = popNode();
    NodeList typeVariables = popNode();
    pushNode(new FunctionExpression(null, typeVariables, formals, body, null,
        Modifiers.EMPTY, null, null, asyncModifier));
  }

  @override
  void handleIsOperator(Token operator, Token not, Token endToken) {
    TypeAnnotation type = popNode();
    Expression expression = popNode();
    Node argument;
    if (not != null) {
      argument = new Send.prefix(type, new Operator(not));
    } else {
      argument = type;
    }

    NodeList arguments = new NodeList.singleton(argument);
    pushNode(new Send(expression, new Operator(operator), arguments));
  }

  @override
  void handleLabel(Token colon) {
    Identifier name = popNode();
    pushNode(new Label(name, colon));
  }

  @override
  void endLabeledStatement(int labelCount) {
    Statement statement = popNode();
    NodeList labels = makeNodeList(labelCount, null, null, null);
    pushNode(new LabeledStatement(labels, statement));
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    inTypeVariable = false;
    NominalTypeAnnotation bound = popNode();
    Identifier name = popNode();
    // TODO(paulberry): type variable metadata should not be ignored.  See
    // dartbug.com/5841.
    popNode(); // Metadata
    pushNode(new TypeVariable(name, extendsOrSuper, bound));
    rejectBuiltInIdentifier(name);
  }

  @override
  void log(message) {
    reporter.log(message);
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    if (!lastErrorWasNativeFunctionBody) {
      pushNode(null);
    }
    lastErrorWasNativeFunctionBody = false;
  }

  void internalError({Token token, Node node}) {
    // TODO(ahe): This should call reporter.internalError.
    Spannable spannable = (token == null) ? node : token;
    throw new SpannableAssertionFailure(spannable, 'Internal error in parser.');
  }
}
