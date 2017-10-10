// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages.dart';
import '../parser.dart';
import '../scanner.dart';

class ForwardingListener implements Listener {
  Listener listener;

  ForwardingListener([this.listener]);

  @override
  Uri get uri => listener?.uri;

  @override
  void beginArguments(Token token) {
    listener?.beginArguments(token);
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    listener?.beginAssert(assertKeyword, kind);
  }

  @override
  void beginAwaitExpression(Token token) {
    listener?.beginAwaitExpression(token);
  }

  @override
  void beginBlock(Token token) {
    listener?.beginBlock(token);
  }

  @override
  void beginBlockFunctionBody(Token token) {
    listener?.beginBlockFunctionBody(token);
  }

  @override
  void beginCascade(Token token) {
    listener?.beginCascade(token);
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    listener?.beginCaseExpression(caseKeyword);
  }

  @override
  void beginCatchClause(Token token) {
    listener?.beginCatchClause(token);
  }

  @override
  void beginClassBody(Token token) {
    listener?.beginClassBody(token);
  }

  @override
  void beginClassDeclaration(Token beginToken, Token name) {
    listener?.beginClassDeclaration(beginToken, name);
  }

  @override
  void beginClassOrNamedMixinApplication(Token token) {
    listener?.beginClassOrNamedMixinApplication(token);
  }

  @override
  void beginCombinators(Token token) {
    listener?.beginCombinators(token);
  }

  @override
  void beginCompilationUnit(Token token) {
    listener?.beginCompilationUnit(token);
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    listener?.beginConditionalUri(ifKeyword);
  }

  @override
  void beginConditionalUris(Token token) {
    listener?.beginConditionalUris(token);
  }

  @override
  void beginConstExpression(Token constKeyword) {
    listener?.beginConstExpression(constKeyword);
  }

  @override
  void beginConstLiteral(Token token) {
    listener?.beginConstLiteral(token);
  }

  @override
  void beginConstructorReference(Token start) {
    listener?.beginConstructorReference(start);
  }

  @override
  void beginDoWhileStatement(Token token) {
    listener?.beginDoWhileStatement(token);
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    listener?.beginDoWhileStatementBody(token);
  }

  @override
  void beginDottedName(Token token) {
    listener?.beginDottedName(token);
  }

  @override
  void beginElseStatement(Token token) {
    listener?.beginElseStatement(token);
  }

  @override
  void beginEnum(Token enumKeyword) {
    listener?.beginEnum(enumKeyword);
  }

  @override
  void beginExport(Token token) {
    listener?.beginExport(token);
  }

  @override
  void beginExpressionStatement(Token token) {
    listener?.beginExpressionStatement(token);
  }

  @override
  void beginFactoryMethod(Token token) {
    listener?.beginFactoryMethod(token);
  }

  @override
  void beginFieldInitializer(Token token) {
    listener?.beginFieldInitializer(token);
  }

  @override
  void beginForInBody(Token token) {
    listener?.beginForInBody(token);
  }

  @override
  void beginForInExpression(Token token) {
    listener?.beginForInExpression(token);
  }

  @override
  void beginForStatement(Token token) {
    listener?.beginForStatement(token);
  }

  @override
  void beginForStatementBody(Token token) {
    listener?.beginForStatementBody(token);
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind) {
    listener?.beginFormalParameter(token, kind);
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    listener?.beginFormalParameters(token, kind);
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    listener?.beginLocalFunctionDeclaration(token);
  }

  @override
  void beginFunctionExpression(Token token) {
    listener?.beginFunctionExpression(token);
  }

  @override
  void beginFunctionName(Token token) {
    listener?.beginFunctionName(token);
  }

  @override
  void beginFunctionType(Token beginToken) {
    listener?.beginFunctionType(beginToken);
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    listener?.beginFunctionTypeAlias(token);
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    listener?.beginFunctionTypedFormalParameter(token);
  }

  @override
  void beginHide(Token hideKeyword) {
    listener?.beginHide(hideKeyword);
  }

  @override
  void beginIdentifierList(Token token) {
    listener?.beginIdentifierList(token);
  }

  @override
  void beginIfStatement(Token token) {
    listener?.beginIfStatement(token);
  }

  @override
  void beginImport(Token importKeyword) {
    listener?.beginImport(importKeyword);
  }

  @override
  void beginInitializedIdentifier(Token token) {
    listener?.beginInitializedIdentifier(token);
  }

  @override
  void beginInitializer(Token token) {
    listener?.beginInitializer(token);
  }

  @override
  void beginInitializers(Token token) {
    listener?.beginInitializers(token);
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    listener?.beginLabeledStatement(token, labelCount);
  }

  @override
  void beginLibraryName(Token token) {
    listener?.beginLibraryName(token);
  }

  @override
  void beginLiteralMapEntry(Token token) {
    listener?.beginLiteralMapEntry(token);
  }

  @override
  void beginLiteralString(Token token) {
    listener?.beginLiteralString(token);
  }

  @override
  void beginLiteralSymbol(Token token) {
    listener?.beginLiteralSymbol(token);
  }

  @override
  void beginMember(Token token) {
    listener?.beginMember(token);
  }

  @override
  void beginMetadata(Token token) {
    listener?.beginMetadata(token);
  }

  @override
  void beginMetadataStar(Token token) {
    listener?.beginMetadataStar(token);
  }

  @override
  void beginMethod(Token token, Token name) {
    listener?.beginMethod(token, name);
  }

  @override
  void beginMixinApplication(Token token) {
    listener?.beginMixinApplication(token);
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    listener?.beginNamedFunctionExpression(token);
  }

  @override
  void beginNamedMixinApplication(Token beginToken, Token name) {
    listener?.beginNamedMixinApplication(beginToken, name);
  }

  @override
  void beginNewExpression(Token token) {
    listener?.beginNewExpression(token);
  }

  @override
  void beginOptionalFormalParameters(Token token) {
    listener?.beginOptionalFormalParameters(token);
  }

  @override
  void beginPart(Token token) {
    listener?.beginPart(token);
  }

  @override
  void beginPartOf(Token token) {
    listener?.beginPartOf(token);
  }

  @override
  void beginRedirectingFactoryBody(Token token) {
    listener?.beginRedirectingFactoryBody(token);
  }

  @override
  void beginRethrowStatement(Token token) {
    listener?.beginRethrowStatement(token);
  }

  @override
  void beginReturnStatement(Token token) {
    listener?.beginReturnStatement(token);
  }

  @override
  void beginShow(Token showKeyword) {
    listener?.beginShow(showKeyword);
  }

  @override
  void beginSwitchBlock(Token token) {
    listener?.beginSwitchBlock(token);
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    listener?.beginSwitchCase(labelCount, expressionCount, firstToken);
  }

  @override
  void beginSwitchStatement(Token token) {
    listener?.beginSwitchStatement(token);
  }

  @override
  void beginThenStatement(Token token) {
    listener?.beginThenStatement(token);
  }

  @override
  void beginTopLevelMember(Token token) {
    listener?.beginTopLevelMember(token);
  }

  @override
  void beginTopLevelMethod(Token token, Token name) {
    listener?.beginTopLevelMethod(token, name);
  }

  @override
  void beginTryStatement(Token token) {
    listener?.beginTryStatement(token);
  }

  @override
  void beginTypeArguments(Token token) {
    listener?.beginTypeArguments(token);
  }

  @override
  void beginTypeList(Token token) {
    listener?.beginTypeList(token);
  }

  @override
  void beginTypeVariable(Token token) {
    listener?.beginTypeVariable(token);
  }

  @override
  void beginTypeVariables(Token token) {
    listener?.beginTypeVariables(token);
  }

  @override
  void beginVariableInitializer(Token token) {
    listener?.beginVariableInitializer(token);
  }

  @override
  void beginVariablesDeclaration(Token token) {
    listener?.beginVariablesDeclaration(token);
  }

  @override
  void beginWhileStatement(Token token) {
    listener?.beginWhileStatement(token);
  }

  @override
  void beginWhileStatementBody(Token token) {
    listener?.beginWhileStatementBody(token);
  }

  @override
  void beginYieldStatement(Token token) {
    listener?.beginYieldStatement(token);
  }

  @override
  void discardTypeReplacedWithCommentTypeAssign() {
    listener?.discardTypeReplacedWithCommentTypeAssign();
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    listener?.endArguments(count, beginToken, endToken);
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token commaToken, Token semicolonToken) {
    listener?.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, semicolonToken);
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    listener?.endAwaitExpression(beginToken, endToken);
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    listener?.endBlock(count, beginToken, endToken);
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    listener?.endBlockFunctionBody(count, beginToken, endToken);
  }

  @override
  void endCascade() {
    listener?.endCascade();
  }

  @override
  void endCaseExpression(Token colon) {
    listener?.endCaseExpression(colon);
  }

  @override
  void endCatchClause(Token token) {
    listener?.endCatchClause(token);
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    listener?.endClassBody(memberCount, beginToken, endToken);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    listener?.endClassDeclaration(beginToken, endToken);
  }

  @override
  void endCombinators(int count) {
    listener?.endCombinators(count);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    listener?.endCompilationUnit(count, token);
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    listener?.endConditionalUri(ifKeyword, leftParen, equalSign);
  }

  @override
  void endConditionalUris(int count) {
    listener?.endConditionalUris(count);
  }

  @override
  void endConstExpression(Token token) {
    listener?.endConstExpression(token);
  }

  @override
  void endConstLiteral(Token token) {
    listener?.endConstLiteral(token);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    listener?.endConstructorReference(start, periodBeforeName, endToken);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    listener?.endDoWhileStatement(doKeyword, whileKeyword, endToken);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    listener?.endDoWhileStatementBody(token);
  }

  @override
  void endDottedName(int count, Token firstIdentifier) {
    listener?.endDottedName(count, firstIdentifier);
  }

  @override
  void endElseStatement(Token token) {
    listener?.endElseStatement(token);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    listener?.endEnum(enumKeyword, leftBrace, count);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    listener?.endExport(exportKeyword, semicolon);
  }

  @override
  void endExpressionStatement(Token token) {
    listener?.endExpressionStatement(token);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    listener?.endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    listener?.endFieldInitializer(assignment, token);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    listener?.endFields(count, beginToken, endToken);
  }

  @override
  void endForIn(Token awaitToken, Token forToken, Token leftParen,
      Token inKeyword, Token endToken) {
    listener?.endForIn(awaitToken, forToken, leftParen, inKeyword, endToken);
  }

  @override
  void endForInBody(Token token) {
    listener?.endForInBody(token);
  }

  @override
  void endForInExpression(Token token) {
    listener?.endForInExpression(token);
  }

  @override
  void endForStatement(Token forKeyword, Token leftParen, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    listener?.endForStatement(
        forKeyword, leftParen, leftSeparator, updateExpressionCount, endToken);
  }

  @override
  void endForStatementBody(Token token) {
    listener?.endForStatementBody(token);
  }

  @override
  void endFormalParameter(Token thisKeyword, Token nameToken,
      FormalParameterKind kind, MemberKind memberKind) {
    listener?.endFormalParameter(thisKeyword, nameToken, kind, memberKind);
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    listener?.endFormalParameters(count, beginToken, endToken, kind);
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    listener?.endLocalFunctionDeclaration(endToken);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    listener?.endFunctionExpression(beginToken, token);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    listener?.endFunctionName(beginToken, token);
  }

  @override
  void endFunctionType(Token functionToken, Token endToken) {
    listener?.endFunctionType(functionToken, endToken);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    listener?.endFunctionTypeAlias(typedefKeyword, equals, endToken);
  }

  @override
  void endFunctionTypedFormalParameter() {
    listener?.endFunctionTypedFormalParameter();
  }

  @override
  void endHide(Token hideKeyword) {
    listener?.endHide(hideKeyword);
  }

  @override
  void endIdentifierList(int count) {
    listener?.endIdentifierList(count);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    listener?.endIfStatement(ifToken, elseToken);
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    listener?.endImport(importKeyword, semicolon);
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    listener?.endInitializedIdentifier(nameToken);
  }

  @override
  void endInitializer(Token token) {
    listener?.endInitializer(token);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    listener?.endInitializers(count, beginToken, endToken);
  }

  @override
  void endLabeledStatement(int labelCount) {
    listener?.endLabeledStatement(labelCount);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    listener?.endLibraryName(libraryKeyword, semicolon);
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
    listener?.endLiteralMapEntry(colon, endToken);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    listener?.endLiteralString(interpolationCount, endToken);
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    listener?.endLiteralSymbol(hashToken, identifierCount);
  }

  @override
  void endMember() {
    listener?.endMember();
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    listener?.endMetadata(beginToken, periodBeforeName, endToken);
  }

  @override
  void endMetadataStar(int count) {
    listener?.endMetadataStar(count);
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    listener?.endMethod(getOrSet, beginToken, endToken);
  }

  @override
  void endMixinApplication(Token withKeyword) {
    listener?.endMixinApplication(withKeyword);
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    listener?.endNamedFunctionExpression(endToken);
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    listener?.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, endToken);
  }

  @override
  void endNewExpression(Token token) {
    listener?.endNewExpression(token);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    listener?.endOptionalFormalParameters(count, beginToken, endToken);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    listener?.endPart(partKeyword, semicolon);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    listener?.endPartOf(partKeyword, ofKeyword, semicolon, hasName);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    listener?.endRedirectingFactoryBody(beginToken, endToken);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    listener?.endRethrowStatement(rethrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    listener?.endReturnStatement(hasExpression, beginToken, endToken);
  }

  @override
  void endShow(Token showKeyword) {
    listener?.endShow(showKeyword);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    listener?.endSwitchBlock(caseCount, beginToken, endToken);
  }

  @override
  void endSwitchCase(int labelCount, int expressionCount, Token defaultKeyword,
      int statementCount, Token firstToken, Token endToken) {
    listener?.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        statementCount, firstToken, endToken);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    listener?.endSwitchStatement(switchKeyword, endToken);
  }

  @override
  void endThenStatement(Token token) {
    listener?.endThenStatement(token);
  }

  @override
  void endTopLevelDeclaration(Token token) {
    listener?.endTopLevelDeclaration(token);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    listener?.endTopLevelFields(count, beginToken, endToken);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    listener?.endTopLevelMethod(beginToken, getOrSet, endToken);
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    listener?.endTryStatement(catchCount, tryKeyword, finallyKeyword);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    listener?.endTypeArguments(count, beginToken, endToken);
  }

  @override
  void endTypeList(int count) {
    listener?.endTypeList(count);
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    listener?.endTypeVariable(token, extendsOrSuper);
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    listener?.endTypeVariables(count, beginToken, endToken);
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    listener?.endVariableInitializer(assignmentOperator);
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    listener?.endVariablesDeclaration(count, endToken);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    listener?.endWhileStatement(whileKeyword, endToken);
  }

  @override
  void endWhileStatementBody(Token token) {
    listener?.endWhileStatementBody(token);
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    listener?.endYieldStatement(yieldToken, starToken, endToken);
  }

  @override
  void handleAsOperator(Token operator, Token endToken) {
    listener?.handleAsOperator(operator, endToken);
  }

  @override
  void handleAssignmentExpression(Token token) {
    listener?.handleAssignmentExpression(token);
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    listener?.handleAsyncModifier(asyncToken, starToken);
  }

  @override
  void beginBinaryExpression(Token token) {
    listener?.beginBinaryExpression(token);
  }

  @override
  void endBinaryExpression(Token token) {
    listener?.endBinaryExpression(token);
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    listener?.handleBreakStatement(hasTarget, breakKeyword, endToken);
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    listener?.handleCaseMatch(caseKeyword, colon);
  }

  @override
  void handleCatchBlock(Token onKeyword, Token catchKeyword, Token comma) {
    listener?.handleCatchBlock(onKeyword, catchKeyword, comma);
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    listener?.handleClassExtends(extendsKeyword);
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    listener?.handleClassHeader(begin, classKeyword, nativeToken);
  }

  @override
  void handleClassImplements(Token implementsKeyword, int interfacesCount) {
    listener?.handleClassImplements(implementsKeyword, interfacesCount);
  }

  @override
  void handleConditionalExpression(Token question, Token colon) {
    listener?.handleConditionalExpression(question, colon);
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    listener?.handleContinueStatement(hasTarget, continueKeyword, endToken);
  }

  @override
  void handleEmptyStatement(Token token) {
    listener?.handleEmptyStatement(token);
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    listener?.handleEmptyFunctionBody(semicolon);
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token endToken) {
    listener?.handleExpressionFunctionBody(arrowToken, endToken);
  }

  @override
  void handleExtraneousExpression(Token token, Message message) {
    listener?.handleExtraneousExpression(token, message);
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    listener?.handleFinallyBlock(finallyKeyword);
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    listener?.handleFormalParameterWithoutValue(token);
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    listener?.handleFunctionBodySkipped(token, isExpressionBody);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    listener?.handleIdentifier(token, context);
  }

  @override
  void handleRecoverImport(Token semicolon) {
    listener?.handleRecoverImport(semicolon);
  }

  @override
  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    listener?.handleIndexedExpression(openSquareBracket, closeSquareBracket);
  }

  @override
  void handleInvalidExpression(Token token) {
    listener?.handleInvalidExpression(token);
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    listener?.handleInvalidFunctionBody(token);
  }

  @override
  void handleInvalidTypeReference(Token token) {
    listener?.handleInvalidTypeReference(token);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    listener?.handleInvalidTopLevelDeclaration(endToken);
  }

  @override
  void handleIsOperator(Token operator, Token not, Token endToken) {
    listener?.handleIsOperator(operator, not, endToken);
  }

  @override
  void handleLabel(Token token) {
    listener?.handleLabel(token);
  }

  @override
  void handleLiteralBool(Token token) {
    listener?.handleLiteralBool(token);
  }

  @override
  void handleLiteralDouble(Token token) {
    listener?.handleLiteralDouble(token);
  }

  @override
  void handleLiteralInt(Token token) {
    listener?.handleLiteralInt(token);
  }

  @override
  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    listener?.handleLiteralList(count, beginToken, constKeyword, endToken);
  }

  @override
  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    listener?.handleLiteralMap(count, beginToken, constKeyword, endToken);
  }

  @override
  void handleLiteralNull(Token token) {
    listener?.handleLiteralNull(token);
  }

  @override
  void handleModifier(Token token) {
    listener?.handleModifier(token);
  }

  @override
  void handleModifiers(int count) {
    listener?.handleModifiers(count);
  }

  @override
  void handleNamedArgument(Token colon) {
    listener?.handleNamedArgument(colon);
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    listener?.handleNativeClause(nativeToken, hasName);
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    listener?.handleNativeFunctionBody(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    listener?.handleNativeFunctionBodyIgnored(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    listener?.handleNativeFunctionBodySkipped(nativeToken, semicolon);
  }

  @override
  void handleNoArguments(Token token) {
    listener?.handleNoArguments(token);
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    listener?.handleNoConstructorReferenceContinuationAfterTypeArguments(token);
  }

  @override
  void handleNoExpression(Token token) {
    listener?.handleNoExpression(token);
  }

  @override
  void handleNoFieldInitializer(Token token) {
    listener?.handleNoFieldInitializer(token);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    listener?.handleNoFormalParameters(token, kind);
  }

  @override
  void handleNoFunctionBody(Token token) {
    listener?.handleNoFunctionBody(token);
  }

  @override
  void handleNoInitializers() {
    listener?.handleNoInitializers();
  }

  @override
  void handleNoName(Token token) {
    listener?.handleNoName(token);
  }

  @override
  void handleNoType(Token token) {
    listener?.handleNoType(token);
  }

  @override
  void handleNoTypeArguments(Token token) {
    listener?.handleNoTypeArguments(token);
  }

  @override
  void handleNoTypeVariables(Token token) {
    listener?.handleNoTypeVariables(token);
  }

  @override
  void handleNoVariableInitializer(Token token) {
    listener?.handleNoVariableInitializer(token);
  }

  @override
  void handleOperator(Token token) {
    listener?.handleOperator(token);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    listener?.handleOperatorName(operatorKeyword, token);
  }

  @override
  void handleParenthesizedExpression(Token token) {
    listener?.handleParenthesizedExpression(token);
  }

  @override
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
    listener?.handleImportPrefix(deferredKeyword, asKeyword);
  }

  @override
  void handleQualified(Token period) {
    listener?.handleQualified(period);
  }

  @override
  void handleRecoverClassHeader() {
    listener?.handleRecoverClassHeader();
  }

  @override
  void handleRecoverExpression(Token token, Message message) {
    listener?.handleRecoverExpression(token, message);
  }

  @override
  void handleRecoverableError(Token token, Message message) {
    listener?.handleRecoverableError(token, message);
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    listener?.handleInvalidStatement(token, message);
  }

  @override
  void handleScript(Token token) {
    listener?.handleScript(token);
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    listener?.handleSend(beginToken, endToken);
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    listener?.handleStringJuxtaposition(literalCount);
  }

  @override
  void handleStringPart(Token token) {
    listener?.handleStringPart(token);
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    listener?.handleSuperExpression(token, context);
  }

  @override
  void handleSymbolVoid(Token token) {
    listener?.handleSymbolVoid(token);
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    listener?.handleThisExpression(token, context);
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    listener?.handleThrowExpression(throwToken, endToken);
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    listener?.handleType(beginToken, endToken);
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    listener?.handleUnaryPostfixAssignmentExpression(token);
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    listener?.handleUnaryPrefixAssignmentExpression(token);
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    listener?.handleUnaryPrefixExpression(token);
  }

  @override
  Token handleUnrecoverableError(Token token, Message message) {
    return listener?.handleUnrecoverableError(token, message);
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    listener?.handleValuedFormalParameter(equals, token);
  }

  @override
  void handleVoidKeyword(Token token) {
    listener?.handleVoidKeyword(token);
  }

  @override
  Token injectGenericCommentTypeAssign(Token token) {
    return listener?.injectGenericCommentTypeAssign(token);
  }

  @override
  Token injectGenericCommentTypeList(Token token) {
    return listener?.injectGenericCommentTypeList(token);
  }

  @override
  void logEvent(String name) {
    listener?.logEvent(name);
  }

  @override
  Token newSyntheticToken(Token next) {
    return listener?.newSyntheticToken(next);
  }

  @override
  List<ParserError> get recoverableErrors => listener?.recoverableErrors;

  @override
  Token replaceTokenWithGenericCommentTypeAssign(
      Token tokenToStartReplacing, Token tokenWithComment) {
    return listener?.replaceTokenWithGenericCommentTypeAssign(
        tokenToStartReplacing, tokenWithComment);
  }

  @override
  set suppressParseErrors(bool value) {
    listener?.suppressParseErrors = value;
  }
}
