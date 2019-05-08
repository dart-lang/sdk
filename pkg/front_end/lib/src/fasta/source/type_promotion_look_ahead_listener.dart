// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_promotion_look_ahead_listener;

import '../builder/builder.dart' show Declaration;

import '../messages.dart' show LocatedMessage, Message;

import '../parser.dart'
    show Assert, IdentifierContext, FormalParameterKind, Listener, MemberKind;

import '../problems.dart' as problems show unhandled;

import '../scanner.dart' show Token;

import '../scope.dart' show Scope;

import '../severity.dart' show Severity;

final NoArguments noArgumentsSentinel = new NoArguments();

abstract class TypePromotionState {
  final Uri uri;

  final List<Scope> scopes = <Scope>[new Scope.top(isModifiable: true)];

  final List<Declaration> stack = <Declaration>[];

  TypePromotionState(this.uri);

  Scope get currentScope => scopes.last;

  void enterScope(String debugName) {
    scopes.add(new Scope.nested(currentScope, "block"));
  }

  Scope exitScope(Token token) {
    return scopes.removeLast();
  }

  void declareIdentifier(Token token) {
    String name = token.lexeme;
    LocatedMessage error = currentScope.declare(
        name, new UnspecifiedDeclaration(name, uri, token.charOffset), uri);
    if (error != null) {
      report(error, Severity.error);
    }
    pushNull(token.lexeme, token);
  }

  void registerWrite(UnspecifiedDeclaration declaration, Token token) {}

  void registerPromotionCandidate(
      UnspecifiedDeclaration declaration, Token token) {}

  void pushReference(Token token) {
    String name = token.lexeme;
    Declaration declaration = currentScope.lookup(name, token.charOffset, uri);
    stack.add(declaration);
  }

  Declaration pop() => stack.removeLast();

  void push(Declaration declaration) {
    stack.add(declaration);
  }

  Declaration popPushNull(String name, Token token) {
    int last = stack.length - 1;
    Declaration declaration = stack[last];
    stack[last] = nullValue(name, token);
    return declaration;
  }

  void discard(int count) {
    stack.length = stack.length - count;
  }

  void pushNull(String name, Token token) {
    stack.add(nullValue(name, token));
  }

  Declaration nullValue(String name, Token token) => null;

  void report(LocatedMessage message, Severity severity,
      {List<LocatedMessage> context});

  void trace(String message, Token token) {}

  void checkEmpty(Token token) {}
}

class UnspecifiedDeclaration extends Declaration {
  final String name;

  @override
  final Uri fileUri;

  @override
  int charOffset;

  UnspecifiedDeclaration(this.name, this.fileUri, this.charOffset);

  @override
  Declaration get parent => null;

  @override
  String get fullNameForErrors => name;

  @override
  String toString() => "UnspecifiedDeclaration($name)";
}

class NoArguments extends Declaration {
  NoArguments();

  @override
  Uri get fileUri => null;

  @override
  int get charOffset => -1;

  @override
  Declaration get parent => null;

  @override
  String get fullNameForErrors => "<<no arguments>>";

  @override
  String toString() => fullNameForErrors;
}

class TypePromotionLookAheadListener extends Listener {
  final TypePromotionState state;

  TypePromotionLookAheadListener(this.state);

  Uri get uri => state.uri;

  void logEvent(String name) {
    throw new UnimplementedError(name);
  }

  void debugEvent(String name, Token token) {
    // state.trace(name, token);
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments", beginToken);
    state.discard(count);
    state.pushNull("%Arguments%", endToken);
  }

  @override
  void handleNoArguments(Token token) {
    debugEvent("NoArguments", token);
    state.push(noArgumentsSentinel);
  }

  @override
  void handleAsOperator(Token operator) {
    debugEvent("AsOperator", operator);
    state.popPushNull(operator.lexeme, operator);
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token commaToken, Token semicolonToken) {
    debugEvent("Assert", assertKeyword);
    if (commaToken != null) {
      state.pop(); // Message.
    }
    state.pop(); // Condition.
    switch (kind) {
      case Assert.Expression:
        state.pushNull("%AssertExpression%", assertKeyword);
        break;

      case Assert.Initializer:
        state.pushNull("%AssertInitializer%", assertKeyword);
        break;

      case Assert.Statement:
        break;
    }
  }

  @override
  void handleAssignmentExpression(Token token) {
    debugEvent("AssignmentExpression", token);
    state.pop(); // Right-hand side.
    Declaration lhs = state.popPushNull(token.lexeme, token);
    if (lhs is UnspecifiedDeclaration) {
      state.registerWrite(lhs, token);
    }
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier", asyncToken);
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    debugEvent("AwaitExpression", beginToken);
    state.popPushNull(beginToken.lexeme, beginToken); // Expression.
  }

  @override
  void endBinaryExpression(Token token) {
    debugEvent("BinaryExpression", token);
    state.pop(); // Right-hand side.
    state.popPushNull(token.lexeme, token); // Left-hand side.
  }

  @override
  void beginBlock(Token token) {
    debugEvent("beginBlock", token);
    state.enterScope("block");
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    debugEvent("Block", beginToken);
    state.exitScope(endToken);
  }

  @override
  void beginBlockFunctionBody(Token token) {
    debugEvent("beginBlockFunctionBody", token);
    state.enterScope("block-function-body");
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    debugEvent("BlockFunctionBody", beginToken);
    state.exitScope(endToken);
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    debugEvent("BreakStatement", breakKeyword);
    if (hasTarget) {
      state.pop(); // Target.
    }
  }

  @override
  void endCascade() {
    debugEvent("Cascade", null);
    state.popPushNull("%Cascade%", null);
  }

  @override
  void endCaseExpression(Token colon) {
    debugEvent("CaseExpression", colon);
    state.pop(); // Expression.
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    debugEvent("CaseMatch", caseKeyword);
  }

  @override
  void handleCatchBlock(Token onKeyword, Token catchKeyword, Token comma) {
    debugEvent("CatchBlock", catchKeyword);
  }

  @override
  void endCatchClause(Token token) {
    debugEvent("CatchClause", token);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("ClassDeclaration", beginToken);
    state.checkEmpty(endToken);
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    debugEvent("ClassExtends", extendsKeyword);
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    debugEvent("ClassHeader", begin);
    state.pop(); // Class name.
    state.checkEmpty(classKeyword);
  }

  @override
  void handleClassNoWithClause() {
    debugEvent("ClassNoWithClause", null);
  }

  @override
  void endClassOrMixinBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassOrMixinBody", beginToken);
    state.checkEmpty(endToken);
  }

  @override
  void handleClassOrMixinImplements(
      Token implementsKeyword, int interfacesCount) {
    debugEvent("ClassOrMixinImplements", implementsKeyword);
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    debugEvent("ClassWithClause", withKeyword);
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators", null);
  }

  @override
  void handleCommentReference(
      Token newKeyword, Token prefix, Token period, Token token) {
    debugEvent("CommentReference", newKeyword);
    unhandled("CommentReference", newKeyword);
  }

  @override
  void handleNoCommentReference() {
    debugEvent("NoCommentReference", null);
    unhandled("NoCommentReference", null);
  }

  @override
  void handleCommentReferenceText(String referenceSource, int referenceOffset) {
    debugEvent("CommentReferenceText", null);
    unhandled("CommentReferenceText", null);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    debugEvent("CompilationUnit", token);
    print(state.stack);
  }

  @override
  void endConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression", question);
    state.pop(); // Otherwise expression.
    state.pop(); // Then expression.
    state.popPushNull(question.lexeme, question); // Condition.
  }

  @override
  void handleConditionalExpressionColon() {
    debugEvent("ConditionalExpressionColon", null);
    // TODO(ahe): Rename this event. This is not handling any colons as it
    // isn't being passed a colon. One alternative is
    // handleConditionalThenExpression, but check the specification for naming
    // conventions. Kernel uses "then" and "otherwise".
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    debugEvent("ConditionalUri", ifKeyword);
    unhandled("ConditionalUri", ifKeyword);
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris", null);
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("ConstExpression", token);
    doConstuctorInvocation(token, true);
  }

  @override
  void endForControlFlow(Token token) {
    // TODO(danrubel) add support for for control flow collection entries
    // but for now this is ignored and an error reported in the body builder.
  }

  @override
  void endForInControlFlow(Token token) {
    // TODO(danrubel) add support for for control flow collection entries
    // but for now this is ignored and an error reported in the body builder.
  }

  @override
  void handleElseControlFlow(Token token) {}

  @override
  void endIfControlFlow(Token token) {
    state.pop(); // Element.
    state.pop(); // Condition.
    state.pushNull("%IfControlFlow%", token);
  }

  @override
  void endIfElseControlFlow(Token token) {
    state.pop(); // Else element.
    state.pop(); // Then element.
    state.pop(); // Condition.
    state.pushNull("%IfElseControlFlow%", token);
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    // TODO(danrubel) add support for spread collections
    // but for now this is ignored and an error reported in the body builder.
    // The top of stack is the spread collection expression.
  }

  void doConstuctorInvocation(Token token, bool isConst) {
    state.pop(); // Arguments.
    state.popPushNull(token.lexeme, token); // Constructor reference.
  }

  @override
  void endConstLiteral(Token token) {
    debugEvent("ConstLiteral", token);
    state.popPushNull("%ConstLiteral%", token);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference", start);
    if (periodBeforeName != null) {
      state.pop(); // Prefix.
    }
    state.popPushNull("%ConstructorReference%", start);
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments", token);
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    debugEvent("ContinueStatement", continueKeyword);
    if (hasTarget) {
      state.pop(); // Target.
    }
  }

  @override
  void handleDirectivesOnly() {
    debugEvent("DirectivesOnly", null);
    unhandled("DirectivesOnly", null);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    debugEvent("DoWhileStatement", doKeyword);
    state.pop(); // Condition.
  }

  @override
  void endDoWhileStatementBody(Token token) {
    debugEvent("DoWhileStatementBody", token);
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName", firstIdentifier);
    unhandled("DottedName", firstIdentifier);
  }

  @override
  void endElseStatement(Token token) {
    debugEvent("ElseStatement", token);
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    debugEvent("EmptyFunctionBody", semicolon);
  }

  @override
  void handleEmptyStatement(Token token) {
    debugEvent("EmptyStatement", token);
  }

  @override
  void beginEnum(Token enumKeyword) {
    debugEvent("beginEnum", enumKeyword);
    state.checkEmpty(enumKeyword);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("endEnum", enumKeyword);
    state.discard(count); // Enum values.
    state.pop(); // Enum name.
    state.checkEmpty(enumKeyword);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export", exportKeyword);
    state.pop(); // Export URI.
    state.checkEmpty(semicolon);
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token endToken) {
    debugEvent("ExpressionFunctionBody", arrowToken);
    state.pop();
  }

  @override
  void handleExpressionStatement(Token token) {
    debugEvent("ExpressionStatement", token);
    state.pop();
  }

  @override
  void handleExtraneousExpression(Token token, Message message) {
    debugEvent("ExtraneousExpression", token);
    unhandled("ExtraneousExpression", token);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("FactoryMethod", beginToken);
    state.pop(); // Name.
    state.checkEmpty(endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    debugEvent("FieldInitializer", assignment);
    state.pop(); // Initializer.
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer", token);
  }

  @override
  void endFields(Token staticToken, Token covariantToken, Token lateToken,
      Token varFinalOrConst, int count, Token beginToken, Token endToken) {
    debugEvent("Fields", staticToken);
    state.discard(count); // Field names.
    state.checkEmpty(endToken);
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    debugEvent("FinallyBlock", finallyKeyword);
  }

  @override
  void endForIn(Token endToken) {
    debugEvent("ForIn", endToken);
  }

  @override
  void endForInBody(Token token) {
    debugEvent("ForInBody", token);
  }

  @override
  void endForInExpression(Token token) {
    debugEvent("ForInExpression", token);
    state.pop(); // Expression.
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    debugEvent("ForInitializerEmptyStatement", token);
  }

  @override
  void handleForInitializerExpressionStatement(Token token) {
    debugEvent("ForInitializerExpressionStatement", token);
    state.pop(); // Expression.
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token) {
    debugEvent("ForInitializerLocalVariableDeclaration", token);
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    debugEvent("handleForLoopParts", forKeyword);
    state.discard(updateExpressionCount);
  }

  @override
  void endForStatement(Token endToken) {
    debugEvent("ForStatement", endToken);
  }

  @override
  void endForStatementBody(Token token) {
    debugEvent("ForStatementBody", token);
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    debugEvent("FormalParameter", thisKeyword);
    state.pop(); // Parameter name.
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("FormalParameterDefaultValueExpression", null);
    state.pop();
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue", token);
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters", beginToken);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    debugEvent("NoFormalParameters", token);
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody", token);
    unhandled("NoFunctionBody", token);
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    debugEvent("FunctionBodySkipped", token);
    unhandled("FunctionBodySkipped", token);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    debugEvent("FunctionExpression", beginToken);
    state.pushNull("%function%", token);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName", beginToken);
  }

  @override
  void endFunctionType(Token functionToken, Token questionMark) {
    debugEvent("FunctionType", functionToken);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("FunctionTypeAlias", typedefKeyword);
    state.pop(); // Name.
    state.checkEmpty(endToken);
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken) {
    debugEvent("FunctionTypedFormalParameter", nameToken);
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("Hide", hideKeyword);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("Identifier ${context}", token);
    if (context.inSymbol) {
      // Do nothing.
    } else if (context.inDeclaration) {
      if (identical(IdentifierContext.localVariableDeclaration, context) ||
          identical(IdentifierContext.formalParameterDeclaration, context)) {
        state.declareIdentifier(token);
      } else {
        state.pushNull(token.lexeme, token);
      }
    } else if (context.isContinuation) {
      state.pushNull(token.lexeme, token);
    } else if (context.isScopeReference) {
      state.pushReference(token);
    } else {
      state.pushNull(token.lexeme, token);
    }
  }

  @override
  void handleIdentifierList(int count) {
    debugEvent("IdentifierList", null);
    state.discard(count);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    debugEvent("IfStatement", ifToken);
    state.pop(); // Condition.
  }

  @override
  void endImplicitCreationExpression(Token token) {
    debugEvent("ImplicitCreationExpression", token);
    doConstuctorInvocation(token, false);
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    debugEvent("Import", importKeyword);
    state.pop(); // Import URI.
    state.checkEmpty(semicolon);
  }

  @override
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
    debugEvent("ImportPrefix", deferredKeyword);
    if (asKeyword != null) {
      state.pop(); // Prefix name.
    }
  }

  @override
  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    debugEvent("IndexedExpression", openSquareBracket);
    state.pop(); // Index.
    state.popPushNull("%indexed%", closeSquareBracket); // Expression.
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    debugEvent("InitializedIdentifier", nameToken);
  }

  @override
  void endInitializer(Token token) {
    debugEvent("Initializer", token);
    state.pop(); // Initializer.
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers", beginToken);
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers", null);
  }

  @override
  void handleInterpolationExpression(Token leftBracket, Token rightBracket) {
    debugEvent("InterpolationExpression", leftBracket);
    state.popPushNull(r"$", leftBracket);
  }

  @override
  void handleInvalidExpression(Token token) {
    // TODO(ahe): The parser doesn't generate this event anymore.
    debugEvent("InvalidExpression", token);
    unhandled("InvalidExpression", token);
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    debugEvent("InvalidFunctionBody", token);
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember", endToken);
    state.checkEmpty(endToken);
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    debugEvent("InvalidOperatorName", operatorKeyword);
    state.checkEmpty(operatorKeyword);
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    debugEvent("InvalidStatement", token);
  }

  @override
  void handleInvalidTopLevelBlock(Token token) {
    debugEvent("InvalidTopLevelBlock", token);
    state.checkEmpty(token);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration", endToken);
    state.checkEmpty(endToken);
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments", token);
  }

  @override
  void handleInvalidTypeReference(Token token) {
    debugEvent("InvalidTypeReference", token);
    unhandled("InvalidTypeReference", token);
  }

  @override
  void handleIsOperator(Token isOperator, Token not) {
    debugEvent("IsOperator", isOperator);
    Declaration lhs = state.popPushNull(isOperator.lexeme, isOperator);
    if (not == null && lhs is UnspecifiedDeclaration) {
      state.registerPromotionCandidate(lhs, isOperator);
    }
  }

  @override
  void handleLabel(Token token) {
    debugEvent("Label", token);
    state.pop(); // Label.
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement", null);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("LibraryName", libraryKeyword);
    state.pop(); // Library name.
    state.checkEmpty(semicolon);
  }

  @override
  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token constKeyword, Token rightBracket) {
    debugEvent("LiteralList", leftBracket);
    state.discard(count);
    state.pushNull("[]", leftBracket);
  }

  @override
  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token constKeyword,
    Token rightBrace,
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool hasSetEntry,
  ) {
    debugEvent("LiteralSetOrMap", leftBrace);
    state.discard(count);
    state.pushNull("{}", leftBrace);
  }

  @override
  void handleLiteralMapEntry(Token colon, Token endToken) {
    debugEvent("LiteralMapEntry", colon);
    state.pop(); // Value.
    state.popPushNull("%LiteralMapEntry%", colon); // Key.
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("LiteralString", endToken);
    state.discard(interpolationCount * 2);
    state.popPushNull("%string%", endToken);
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    debugEvent("LiteralSymbol", hashToken);
    state.pushNull(hashToken.lexeme, hashToken);
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    debugEvent("LocalFunctionDeclaration", endToken);
    state.pop(); // Function name.
  }

  @override
  void endMember() {
    debugEvent("Member", null);
    state.checkEmpty(null);
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata", beginToken);
    state.pop(); // Arguments.
    if (periodBeforeName != null) {
      state.pop(); // Suffix.
    }
    state.pop(); // Qualifier.
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar", null);
  }

  @override
  void beginMethod(Token externalToken, Token staticToken, Token covariantToken,
      Token varFinalOrConst, Token getOrSet, Token name) {
    debugEvent("beginMethod", name);
    state.checkEmpty(name);
  }

  @override
  void endMethod(
      Token getOrSet, Token beginToken, Token beginParam, Token endToken) {
    debugEvent("endMethod", endToken);
    state.pop(); // Method name.
    state.checkEmpty(endToken);
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    debugEvent("MixinDeclaration", mixinKeyword);
    state.checkEmpty(endToken);
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    debugEvent("MixinHeader", mixinKeyword);
    state.pop(); // Mixin name.
    state.checkEmpty(mixinKeyword);
  }

  @override
  void handleMixinOn(Token onKeyword, int typeCount) {
    debugEvent("MixinOn", onKeyword);
  }

  @override
  void handleNoName(Token token) {
    debugEvent("NoName", token);
    state.pushNull("%NoName%", token);
  }

  @override
  void handleNamedArgument(Token colon) {
    debugEvent("NamedArgument", colon);
    state.pop(); // Expression.
    state.popPushNull("%NamedArgument%", colon); // Identifier.
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    debugEvent("NamedFunctionExpression", endToken);
    state.popPushNull(
        "%named function expression%", endToken); // Function name.
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication", begin);
    state.pop(); // Mixin application name.
    state.checkEmpty(endToken);
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    debugEvent("NamedMixinApplicationWithClause", withKeyword);
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause", nativeToken);
    if (hasName) {
      state.pop(); // Name.
    }
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBody", nativeToken);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored", nativeToken);
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodySkipped", nativeToken);
  }

  @override
  void endNewExpression(Token token) {
    debugEvent("NewExpression", token);
    doConstuctorInvocation(token, false);
  }

  @override
  void handleOperator(Token token) {
    debugEvent("Operator", token);
    unhandled("Operator", token);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName", operatorKeyword);
    state.pushNull(token.lexeme, token);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters", beginToken);
  }

  @override
  void handleParenthesizedCondition(Token token) {
    debugEvent("ParenthesizedCondition", token);
  }

  @override
  void handleParenthesizedExpression(Token token) {
    debugEvent("ParenthesizedExpression", token);
    state.popPushNull("%(expr)%", token);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part", partKeyword);
    state.pop(); // URI.
    state.checkEmpty(semicolon);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    debugEvent("PartOf", partKeyword);
    state.pop(); // Name or URI.
    state.checkEmpty(semicolon);
  }

  @override
  void handleQualified(Token period) {
    debugEvent("Qualified", period);
    state.pop(); // Suffix.
    state.popPushNull("%Qualified%", period); // Qualifier.
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("RecoverClassHeader", null);
    state.checkEmpty(null);
  }

  @override
  void handleRecoverImport(Token semicolon) {
    debugEvent("RecoverImport", semicolon);
    unhandled("RecoverImport", semicolon);
  }

  @override
  void handleRecoverMixinHeader() {
    debugEvent("RecoverMixinHeader", null);
    state.checkEmpty(null);
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    debugEvent("RecoverableError ${message.message}", startToken);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody", beginToken);
    state.pop(); // Constructor reference.
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    debugEvent("RethrowStatement", rethrowToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    debugEvent("ReturnStatement", beginToken);
    if (hasExpression) {
      state.pop(); // Expression.
    }
  }

  @override
  void handleScript(Token token) {
    debugEvent("Script", token);
    unhandled("Script", token);
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send", beginToken);
    Declaration arguments = state.pop();
    if (identical(arguments, noArgumentsSentinel)) {
      // Leave the receiver on the stack.
    } else {
      state.popPushNull("%send%", beginToken);
    }
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show", showKeyword);
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition", null);
    state.discard(literalCount);
    state.pushNull("%StringJuxtaposition%", null);
  }

  @override
  void handleStringPart(Token token) {
    debugEvent("StringPart", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    debugEvent("SuperExpression", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    debugEvent("SwitchBlock", beginToken);
    state.pop(); // Expression.
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
    debugEvent("SwitchCase", defaultKeyword);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement", switchKeyword);
  }

  @override
  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid", token);
    unhandled("SymbolVoid", token);
  }

  @override
  void endThenStatement(Token token) {
    debugEvent("ThenStatement", token);
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression", token);
    state.pushNull(token.lexeme, token);
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression", throwToken);
    state.popPushNull(throwToken.lexeme, throwToken);
  }

  @override
  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration", token);
    state.checkEmpty(token);
  }

  @override
  void endTopLevelFields(
      Token staticToken,
      Token covariantToken,
      Token lateToken,
      Token varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("TopLevelFields", staticToken);
    state.discard(count); // Field names.
    state.checkEmpty(endToken);
  }

  @override
  void beginTopLevelMethod(Token lastConsumed, Token externalToken) {
    debugEvent("beginTopLevelMethod", lastConsumed.next);
    state.checkEmpty(lastConsumed.next);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    debugEvent("endTopLevelMethod", beginToken);
    state.pop(); // Method name.
    state.checkEmpty(endToken);
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    debugEvent("TryStatement", tryKeyword);
  }

  @override
  void handleType(Token beginToken, Token questionMark) {
    debugEvent("Type", beginToken);
    state.pop();
  }

  @override
  void handleNoType(Token lastConsumed) {
    debugEvent("NoType", lastConsumed);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments", beginToken);
  }

  @override
  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments", token);
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList", null);
  }

  @override
  void endTypeVariable(Token token, int index, Token extendsOrSuper) {
    debugEvent("TypeVariable", token);
    state.pop(); // Name.
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("TypeVariables", beginToken);
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables", token);
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("TypeVariablesDefined", token);
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression", token);
    Declaration expr = state.popPushNull(token.lexeme, token);
    if (expr is UnspecifiedDeclaration) {
      state.registerWrite(expr, token);
    }
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression", token);
    Declaration expr = state.popPushNull(token.lexeme, token);
    if (expr is UnspecifiedDeclaration) {
      state.registerWrite(expr, token);
    }
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    debugEvent("UnaryPrefixExpression", token);
    state.popPushNull("%UnaryPrefixExpression%", token);
  }

  @override
  void handleUnescapeError(
      Message message, Token location, int stringOffset, int length) {
    debugEvent("UnescapeError", location);
    unhandled("UnescapeError", location);
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    debugEvent("ValuedFormalParameter", equals);
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer", assignmentOperator);
    state.pop(); // Initializer.
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer", token);
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    debugEvent("VariablesDeclaration", endToken);
    state.discard(count); // Variable names.
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword", token);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    debugEvent("WhileStatement", whileKeyword);
    state.pop(); // Condition.
  }

  @override
  void endWhileStatementBody(Token token) {
    debugEvent("WhileStatementBody", token);
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    debugEvent("YieldStatement", yieldToken);
    state.pop(); // Expression.
  }

  void unhandled(String event, Token token) {
    problems.unhandled(
        event, "TypePromotionLookAheadListener", token?.charOffset ?? -1, uri);
  }
}
