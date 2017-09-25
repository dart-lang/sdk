// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/fasta/parser/identifier_context.dart'
    show IdentifierContext;
import 'package:front_end/src/fasta/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';

/**
 * Proxy implementation of the fasta parser listener that
 * asserts begin/end pairs of events and forwards all events
 * to the specified listener.
 *
 * When `parseUnit` is called, then all events are generated as expected.
 * When "lower level" parse methods are called, then some "higher level"
 * begin/end event pairs will not be generated. In this case,
 * construct a new listener and call `begin('higher-level-event')`
 * before calling the "lower level" parse method. Once the parse method returns,
 * call `end('higher-level-event')` to assert that the stack is in the
 * expected state.
 *
 * For example, when calling `parseTopLevelDeclaration`, the
 * [beginCompilationUnit] and [endCompilationUnit] event pair is not generated.
 * In this case, call `begin('CompilationUnit')` before calling
 * `parseTopLevelDeclaration`, and call `end('CompilationUnit')` afterward.
 *
 * When calling `parseUnit`, do not call `begin` or `end`,
 * but call `expectEmpty` after `parseUnit` returns.
 */
class ForwardingTestListener implements fasta.Listener {
  final fasta.Listener listener;
  final _stack = <String>[];

  void begin(String event) {
    expect(event, isNotNull);
    _stack.add(event);
  }

  void expectEmpty() {
    expect(_stack, isEmpty);
  }

  void expectIn(String event) {
    if (_stack.isEmpty || _stack.last != event) {
      fail('Expected $event, but found $_stack');
    }
  }

  void expectInOneOf(List<String> events) {
    if (_stack.isEmpty || !events.contains(_stack.last)) {
      fail('Expected one of $events, but found $_stack');
    }
  }

  void end(String event) {
    expectIn(event);
    _stack.removeLast();
  }

  ForwardingTestListener(this.listener);

  @override
  Uri get uri => listener.uri;

  @override
  void beginArguments(Token token) {
    listener.beginArguments(token);
    begin('Arguments');
  }

  @override
  void beginAssert(Token assertKeyword, fasta.Assert kind) {
    listener.beginAssert(assertKeyword, kind);
    begin('Assert');
  }

  @override
  void beginAwaitExpression(Token token) {
    listener.beginAwaitExpression(token);
    begin('AwaitExpression');
  }

  @override
  void beginBlock(Token token) {
    listener.beginBlock(token);
    begin('Block');
  }

  @override
  void beginBlockFunctionBody(Token token) {
    listener.beginBlockFunctionBody(token);
    begin('BlockFunctionBody');
  }

  @override
  void beginCascade(Token token) {
    listener.beginCascade(token);
    begin('Cascade');
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    listener.beginCaseExpression(caseKeyword);
    begin('CaseExpression');
  }

  @override
  void beginCatchClause(Token token) {
    listener.beginCatchClause(token);
    begin('CatchClause');
  }

  @override
  void beginClassBody(Token token) {
    listener.beginClassBody(token);
    begin('ClassBody');
  }

  @override
  void beginClassDeclaration(Token beginToken, Token name) {
    listener.beginClassDeclaration(beginToken, name);
    begin('ClassDeclaration');
  }

  @override
  void beginClassOrNamedMixinApplication(Token token) {
    listener.beginClassOrNamedMixinApplication(token);
    begin('ClassOrNamedMixinApplication');
  }

  @override
  void beginCombinators(Token token) {
    listener.beginCombinators(token);
    begin('Combinators');
  }

  @override
  void beginCompilationUnit(Token token) {
    expectEmpty();
    listener.beginCompilationUnit(token);
    begin('CompilationUnit');
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    listener.beginConditionalUri(ifKeyword);
    begin('ConditionalUri');
  }

  @override
  void beginConditionalUris(Token token) {
    listener.beginConditionalUris(token);
    begin('ConditionalUris');
  }

  @override
  void beginConstExpression(Token constKeyword) {
    listener.beginConstExpression(constKeyword);
    begin('ConstExpression');
  }

  @override
  void beginConstLiteral(Token token) {
    listener.beginConstLiteral(token);
    begin('ConstLiteral');
  }

  @override
  void beginConstructorReference(Token start) {
    listener.beginConstructorReference(start);
    begin('ConstructorReference');
  }

  @override
  void beginDoWhileStatement(Token token) {
    listener.beginDoWhileStatement(token);
    begin('DoWhileStatement');
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    listener.beginDoWhileStatementBody(token);
    begin('DoWhileStatementBody');
  }

  @override
  void beginDottedName(Token token) {
    listener.beginDottedName(token);
    begin('DottedName');
  }

  @override
  void beginElseStatement(Token token) {
    listener.beginElseStatement(token);
    begin('ElseStatement');
  }

  @override
  void beginEnum(Token enumKeyword) {
    listener.beginEnum(enumKeyword);
    begin('Enum');
  }

  @override
  void beginExport(Token token) {
    listener.beginExport(token);
    begin('Export');
  }

  @override
  void beginExpressionStatement(Token token) {
    listener.beginExpressionStatement(token);
    begin('ExpressionStatement');
  }

  @override
  void beginFactoryMethod(Token token) {
    listener.beginFactoryMethod(token);
    begin('FactoryMethod');
  }

  @override
  void beginFieldInitializer(Token token) {
    listener.beginFieldInitializer(token);
    begin('FieldInitializer');
  }

  @override
  void beginForInBody(Token token) {
    listener.beginForInBody(token);
    begin('ForInBody');
  }

  @override
  void beginForInExpression(Token token) {
    listener.beginForInExpression(token);
    begin('ForInExpression');
  }

  @override
  void beginForStatement(Token token) {
    listener.beginForStatement(token);
    begin('ForStatement');
  }

  @override
  void beginForStatementBody(Token token) {
    listener.beginForStatementBody(token);
    begin('ForStatementBody');
  }

  @override
  void beginFormalParameter(Token token, fasta.MemberKind kind) {
    listener.beginFormalParameter(token, kind);
    begin('FormalParameter');
  }

  @override
  void beginFormalParameters(Token token, fasta.MemberKind kind) {
    listener.beginFormalParameters(token, kind);
    begin('FormalParameters');
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    listener.beginLocalFunctionDeclaration(token);
    begin('LocalFunctionDeclaration');
  }

  @override
  void beginFunctionExpression(Token token) {
    listener.beginFunctionExpression(token);
    begin('FunctionExpression');
  }

  @override
  void beginFunctionName(Token token) {
    listener.beginFunctionName(token);
    begin('FunctionName');
  }

  @override
  void beginFunctionType(Token beginToken) {
    listener.beginFunctionType(beginToken);
    begin('FunctionType');
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    listener.beginFunctionTypeAlias(token);
    begin('FunctionTypeAlias');
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    listener.beginFunctionTypedFormalParameter(token);
    begin('FunctionTypedFormalParameter');
  }

  @override
  void beginHide(Token hideKeyword) {
    listener.beginHide(hideKeyword);
    begin('Hide');
  }

  @override
  void beginIdentifierList(Token token) {
    listener.beginIdentifierList(token);
    begin('IdentifierList');
  }

  @override
  void beginIfStatement(Token token) {
    listener.beginIfStatement(token);
    begin('IfStatement');
  }

  @override
  void beginImport(Token importKeyword) {
    listener.beginImport(importKeyword);
    begin('Import');
  }

  @override
  void beginInitializedIdentifier(Token token) {
    listener.beginInitializedIdentifier(token);
    begin('InitializedIdentifier');
  }

  @override
  void beginInitializer(Token token) {
    listener.beginInitializer(token);
    begin('Initializer');
  }

  @override
  void beginInitializers(Token token) {
    listener.beginInitializers(token);
    begin('Initializers');
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    listener.beginLabeledStatement(token, labelCount);
    begin('LabeledStatement');
  }

  @override
  void beginLibraryName(Token token) {
    listener.beginLibraryName(token);
    begin('LibraryName');
  }

  @override
  void beginLiteralMapEntry(Token token) {
    listener.beginLiteralMapEntry(token);
    begin('LiteralMapEntry');
  }

  @override
  void beginLiteralString(Token token) {
    listener.beginLiteralString(token);
    begin('LiteralString');
  }

  @override
  void beginLiteralSymbol(Token token) {
    listener.beginLiteralSymbol(token);
    begin('LiteralSymbol');
  }

  @override
  void beginMember(Token token) {
    listener.beginMember(token);
    begin('Member');
  }

  @override
  void beginMetadata(Token token) {
    listener.beginMetadata(token);
    begin('Metadata');
  }

  @override
  void beginMetadataStar(Token token) {
    listener.beginMetadataStar(token);
    begin('MetadataStar');
  }

  @override
  void beginMethod(Token token, Token name) {
    listener.beginMethod(token, name);
    begin('Method');
  }

  @override
  void beginMixinApplication(Token token) {
    listener.beginMixinApplication(token);
    begin('MixinApplication');
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    listener.beginNamedFunctionExpression(token);
    begin('NamedFunctionExpression');
  }

  @override
  void beginNamedMixinApplication(Token beginToken, Token name) {
    listener.beginNamedMixinApplication(beginToken, name);
    begin('NamedMixinApplication');
  }

  @override
  void beginNewExpression(Token token) {
    listener.beginNewExpression(token);
    begin('NewExpression');
  }

  @override
  void beginOptionalFormalParameters(Token token) {
    listener.beginOptionalFormalParameters(token);
    begin('OptionalFormalParameters');
  }

  @override
  void beginPart(Token token) {
    listener.beginPart(token);
    begin('Part');
  }

  @override
  void beginPartOf(Token token) {
    listener.beginPartOf(token);
    begin('PartOf');
  }

  @override
  void beginRedirectingFactoryBody(Token token) {
    listener.beginRedirectingFactoryBody(token);
    begin('RedirectingFactoryBody');
  }

  @override
  void beginRethrowStatement(Token token) {
    listener.beginRethrowStatement(token);
    begin('RethrowStatement');
  }

  @override
  void beginReturnStatement(Token token) {
    listener.beginReturnStatement(token);
    begin('ReturnStatement');
  }

  @override
  void beginShow(Token showKeyword) {
    listener.beginShow(showKeyword);
    begin('Show');
  }

  @override
  void beginSwitchBlock(Token token) {
    listener.beginSwitchBlock(token);
    begin('SwitchBlock');
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    listener.beginSwitchCase(labelCount, expressionCount, firstToken);
    begin('SwitchCase');
  }

  @override
  void beginSwitchStatement(Token token) {
    listener.beginSwitchStatement(token);
    begin('SwitchStatement');
  }

  @override
  void beginThenStatement(Token token) {
    listener.beginThenStatement(token);
    begin('ThenStatement');
  }

  @override
  void beginTopLevelMember(Token token) {
    listener.beginTopLevelMember(token);
    begin('TopLevelMember');
  }

  @override
  void beginTopLevelMethod(Token token, Token name) {
    listener.beginTopLevelMethod(token, name);
    begin('TopLevelMethod');
  }

  @override
  void beginTryStatement(Token token) {
    listener.beginTryStatement(token);
    begin('TryStatement');
  }

  @override
  void beginTypeArguments(Token token) {
    listener.beginTypeArguments(token);
    begin('TypeArguments');
  }

  @override
  void beginTypeList(Token token) {
    listener.beginTypeList(token);
    begin('TypeList');
  }

  @override
  void beginTypeVariable(Token token) {
    listener.beginTypeVariable(token);
    begin('TypeVariable');
  }

  @override
  void beginTypeVariables(Token token) {
    listener.beginTypeVariables(token);
    begin('TypeVariables');
  }

  @override
  void beginVariableInitializer(Token token) {
    listener.beginVariableInitializer(token);
    begin('VariableInitializer');
  }

  @override
  void beginVariablesDeclaration(Token token) {
    listener.beginVariablesDeclaration(token);
    begin('VariablesDeclaration');
  }

  @override
  void beginWhileStatement(Token token) {
    listener.beginWhileStatement(token);
    begin('WhileStatement');
  }

  @override
  void beginWhileStatementBody(Token token) {
    listener.beginWhileStatementBody(token);
    begin('WhileStatementBody');
  }

  @override
  void beginYieldStatement(Token token) {
    listener.beginYieldStatement(token);
    begin('YieldStatement');
  }

  @override
  void discardTypeReplacedWithCommentTypeAssign() {
    listener.discardTypeReplacedWithCommentTypeAssign();
    // TODO(danrubel): implement discardTypeReplacedWithCommentTypeAssign
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    end('Arguments');
    listener.endArguments(count, beginToken, endToken);
  }

  @override
  void endAssert(Token assertKeyword, fasta.Assert kind, Token leftParenthesis,
      Token commaToken, Token semicolonToken) {
    end('Assert');
    listener.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, semicolonToken);
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    end('AwaitExpression');
    listener.endAwaitExpression(beginToken, endToken);
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    end('Block');
    listener.endBlock(count, beginToken, endToken);
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    end('BlockFunctionBody');
    listener.endBlockFunctionBody(count, beginToken, endToken);
  }

  @override
  void endCascade() {
    end('Cascade');
    listener.endCascade();
  }

  @override
  void endCaseExpression(Token colon) {
    end('CaseExpression');
    listener.endCaseExpression(colon);
  }

  @override
  void endCatchClause(Token token) {
    end('CatchClause');
    listener.endCatchClause(token);
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    end('ClassBody');
    listener.endClassBody(memberCount, beginToken, endToken);
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token nativeToken,
      Token endToken) {
    end('ClassDeclaration');
    end('ClassOrNamedMixinApplication');
    listener.endClassDeclaration(interfacesCount, beginToken, classKeyword,
        extendsKeyword, implementsKeyword, nativeToken, endToken);
  }

  @override
  void endCombinators(int count) {
    end('Combinators');
    listener.endCombinators(count);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    end('CompilationUnit');
    listener.endCompilationUnit(count, token);
    expectEmpty();
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    end('ConditionalUri');
    listener.endConditionalUri(ifKeyword, leftParen, equalSign);
  }

  @override
  void endConditionalUris(int count) {
    end('ConditionalUris');
    listener.endConditionalUris(count);
  }

  @override
  void endConstExpression(Token token) {
    end('ConstExpression');
    listener.endConstExpression(token);
  }

  @override
  void endConstLiteral(Token token) {
    end('ConstLiteral');
    listener.endConstLiteral(token);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    end('ConstructorReference');
    listener.endConstructorReference(start, periodBeforeName, endToken);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    end('DoWhileStatement');
    listener.endDoWhileStatement(doKeyword, whileKeyword, endToken);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    end('DoWhileStatementBody');
    listener.endDoWhileStatementBody(token);
  }

  @override
  void endDottedName(int count, Token firstIdentifier) {
    end('DottedName');
    listener.endDottedName(count, firstIdentifier);
  }

  @override
  void endElseStatement(Token token) {
    end('ElseStatement');
    listener.endElseStatement(token);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    end('Enum');
    listener.endEnum(enumKeyword, leftBrace, count);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    end('Export');
    listener.endExport(exportKeyword, semicolon);
  }

  @override
  void endExpressionStatement(Token token) {
    end('ExpressionStatement');
    listener.endExpressionStatement(token);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    end('FactoryMethod');
    listener.endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    end('FieldInitializer');
    listener.endFieldInitializer(assignment, token);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    // beginMember --> endFields, endMember
    expectIn('Member');
    listener.endFields(count, beginToken, endToken);
  }

  @override
  void endForIn(Token awaitToken, Token forToken, Token leftParen,
      Token inKeyword, Token endToken) {
    end('ForStatement');
    listener.endForIn(awaitToken, forToken, leftParen, inKeyword, endToken);
  }

  @override
  void endForInBody(Token token) {
    end('ForInBody');
    listener.endForInBody(token);
  }

  @override
  void endForInExpression(Token token) {
    end('ForInExpression');
    listener.endForInExpression(token);
  }

  @override
  void endForStatement(Token forKeyword, Token leftParen, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    end('ForStatement');
    listener.endForStatement(
        forKeyword, leftParen, leftSeparator, updateExpressionCount, endToken);
  }

  @override
  void endForStatementBody(Token token) {
    end('ForStatementBody');
    listener.endForStatementBody(token);
  }

  @override
  void endFormalParameter(Token thisKeyword, Token nameToken,
      fasta.FormalParameterKind kind, fasta.MemberKind memberKind) {
    end('FormalParameter');
    listener.endFormalParameter(thisKeyword, nameToken, kind, memberKind);
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, fasta.MemberKind kind) {
    end('FormalParameters');
    listener.endFormalParameters(count, beginToken, endToken, kind);
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    end('LocalFunctionDeclaration');
    listener.endLocalFunctionDeclaration(endToken);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    end('FunctionExpression');
    listener.endFunctionExpression(beginToken, token);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    end('FunctionName');
    listener.endFunctionName(beginToken, token);
  }

  @override
  void endFunctionType(Token functionToken, Token endToken) {
    end('FunctionType');
    listener.endFunctionType(functionToken, endToken);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    end('FunctionTypeAlias');
    listener.endFunctionTypeAlias(typedefKeyword, equals, endToken);
  }

  @override
  void endFunctionTypedFormalParameter() {
    end('FunctionTypedFormalParameter');
    listener.endFunctionTypedFormalParameter();
  }

  @override
  void endHide(Token hideKeyword) {
    end('Hide');
    listener.endHide(hideKeyword);
  }

  @override
  void endIdentifierList(int count) {
    end('IdentifierList');
    listener.endIdentifierList(count);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    end('IfStatement');
    listener.endIfStatement(ifToken, elseToken);
  }

  @override
  void endImport(Token importKeyword, Token DeferredKeyword, Token asKeyword,
      Token semicolon) {
    end('Import');
    listener.endImport(importKeyword, DeferredKeyword, asKeyword, semicolon);
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    end('InitializedIdentifier');
    listener.endInitializedIdentifier(nameToken);
  }

  @override
  void endInitializer(Token token) {
    end('Initializer');
    listener.endInitializer(token);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    end('Initializers');
    listener.endInitializers(count, beginToken, endToken);
  }

  @override
  void endLabeledStatement(int labelCount) {
    end('LabeledStatement');
    listener.endLabeledStatement(labelCount);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    end('LibraryName');
    listener.endLibraryName(libraryKeyword, semicolon);
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
    end('LiteralMapEntry');
    listener.endLiteralMapEntry(colon, endToken);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    end('LiteralString');
    listener.endLiteralString(interpolationCount, endToken);
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    end('LiteralSymbol');
    listener.endLiteralSymbol(hashToken, identifierCount);
  }

  @override
  void endMember() {
    end('Member');
    listener.endMember();
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    end('Metadata');
    listener.endMetadata(beginToken, periodBeforeName, endToken);
  }

  @override
  void endMetadataStar(int count) {
    end('MetadataStar');
    listener.endMetadataStar(count);
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    end('Method');
    listener.endMethod(getOrSet, beginToken, endToken);
  }

  @override
  void endMixinApplication(Token withKeyword) {
    end('MixinApplication');
    listener.endMixinApplication(withKeyword);
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    end('NamedFunctionExpression');
    listener.endNamedFunctionExpression(endToken);
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    end('NamedMixinApplication');
    end('ClassOrNamedMixinApplication');
    listener.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, endToken);
  }

  @override
  void endNewExpression(Token token) {
    end('NewExpression');
    listener.endNewExpression(token);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    end('OptionalFormalParameters');
    listener.endOptionalFormalParameters(count, beginToken, endToken);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    end('Part');
    listener.endPart(partKeyword, semicolon);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    end('PartOf');
    listener.endPartOf(partKeyword, ofKeyword, semicolon, hasName);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    end('RedirectingFactoryBody');
    listener.endRedirectingFactoryBody(beginToken, endToken);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    end('RethrowStatement');
    listener.endRethrowStatement(rethrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    end('ReturnStatement');
    listener.endReturnStatement(hasExpression, beginToken, endToken);
  }

  @override
  void endShow(Token showKeyword) {
    end('Show');
    listener.endShow(showKeyword);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    end('SwitchBlock');
    listener.endSwitchBlock(caseCount, beginToken, endToken);
  }

  @override
  void endSwitchCase(int labelCount, int expressionCount, Token defaultKeyword,
      int statementCount, Token firstToken, Token endToken) {
    end('SwitchCase');
    listener.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        statementCount, firstToken, endToken);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    end('SwitchStatement');
    listener.endSwitchStatement(switchKeyword, endToken);
  }

  @override
  void endThenStatement(Token token) {
    end('ThenStatement');
    listener.endThenStatement(token);
  }

  @override
  void endTopLevelDeclaration(Token token) {
    // There is no corresponding beginTopLevelDeclaration
    //_expectBegin('TopLevelDeclaration');
    expectIn('CompilationUnit');
    listener.endTopLevelDeclaration(token);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    end('TopLevelMember');
    listener.endTopLevelFields(count, beginToken, endToken);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    end('TopLevelMethod');
    end('TopLevelMember');
    listener.endTopLevelMethod(beginToken, getOrSet, endToken);
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    end('TryStatement');
    listener.endTryStatement(catchCount, tryKeyword, finallyKeyword);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    end('TypeArguments');
    listener.endTypeArguments(count, beginToken, endToken);
  }

  @override
  void endTypeList(int count) {
    end('TypeList');
    listener.endTypeList(count);
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    end('TypeVariable');
    listener.endTypeVariable(token, extendsOrSuper);
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    end('TypeVariables');
    listener.endTypeVariables(count, beginToken, endToken);
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    end('VariableInitializer');
    listener.endVariableInitializer(assignmentOperator);
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    end('VariablesDeclaration');
    listener.endVariablesDeclaration(count, endToken);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    end('WhileStatement');
    listener.endWhileStatement(whileKeyword, endToken);
  }

  @override
  void endWhileStatementBody(Token token) {
    end('WhileStatementBody');
    listener.endWhileStatementBody(token);
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    end('YieldStatement');
    listener.endYieldStatement(yieldToken, starToken, endToken);
  }

  @override
  void handleAsOperator(Token operator, Token endToken) {
    listener.handleAsOperator(operator, endToken);
    // TODO(danrubel): implement handleAsOperator
  }

  @override
  void handleAssignmentExpression(Token token) {
    listener.handleAssignmentExpression(token);
    // TODO(danrubel): implement handleAssignmentExpression
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    listener.handleAsyncModifier(asyncToken, starToken);
    // TODO(danrubel): implement handleAsyncModifier
  }

  @override
  void beginBinaryExpression(Token token) {
    listener.beginBinaryExpression(token);
    // TODO(danrubel): implement beginBinaryExpression
  }

  @override
  void endBinaryExpression(Token token) {
    listener.endBinaryExpression(token);
    // TODO(danrubel): implement endBinaryExpression
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    listener.handleBreakStatement(hasTarget, breakKeyword, endToken);
    // TODO(danrubel): implement handleBreakStatement
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    listener.handleCaseMatch(caseKeyword, colon);
    // TODO(danrubel): implement handleCaseMatch
  }

  @override
  void handleCatchBlock(Token onKeyword, Token catchKeyword, Token comma) {
    listener.handleCatchBlock(onKeyword, catchKeyword, comma);
    // TODO(danrubel): implement handleCatchBlock
  }

  @override
  void handleConditionalExpression(Token question, Token colon) {
    listener.handleConditionalExpression(question, colon);
    // TODO(danrubel): implement handleConditionalExpression
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    listener.handleContinueStatement(hasTarget, continueKeyword, endToken);
    // TODO(danrubel): implement handleContinueStatement
  }

  @override
  void handleEmptyStatement(Token token) {
    listener.handleEmptyStatement(token);
    // TODO(danrubel): implement handleEmptyStatement
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    listener.handleEmptyFunctionBody(semicolon);
    // TODO(danrubel): implement handleEmptyFunctionBody
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token endToken) {
    listener.handleExpressionFunctionBody(arrowToken, endToken);
    // TODO(danrubel): implement handleExpressionFunctionBody
  }

  @override
  void handleExtraneousExpression(Token token, Message message) {
    listener.handleExtraneousExpression(token, message);
    // TODO(danrubel): implement handleExtraneousExpression
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    listener.handleFinallyBlock(finallyKeyword);
    // TODO(danrubel): implement handleFinallyBlock
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    listener.handleFormalParameterWithoutValue(token);
    // TODO(danrubel): implement handleFormalParameterWithoutValue
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    listener.handleFunctionBodySkipped(token, isExpressionBody);
    // TODO(danrubel): implement handleFunctionBodySkipped
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    listener.handleIdentifier(token, context);
    // TODO(danrubel): implement handleIdentifier
  }

  @override
  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    listener.handleIndexedExpression(openSquareBracket, closeSquareBracket);
    // TODO(danrubel): implement handleIndexedExpression
  }

  @override
  void handleInvalidExpression(Token token) {
    listener.handleInvalidExpression(token);
    // TODO(danrubel): implement handleInvalidExpression
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    listener.handleInvalidFunctionBody(token);
    // TODO(danrubel): implement handleInvalidFunctionBody
  }

  @override
  void handleInvalidTypeReference(Token token) {
    listener.handleInvalidTypeReference(token);
    // TODO(danrubel): implement handleInvalidTypeReference
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    expectIn('CompilationUnit');
    listener.handleInvalidTopLevelDeclaration(endToken);
  }

  @override
  void handleIsOperator(Token operator, Token not, Token endToken) {
    listener.handleIsOperator(operator, not, endToken);
    // TODO(danrubel): implement handleIsOperator
  }

  @override
  void handleLabel(Token token) {
    listener.handleLabel(token);
    // TODO(danrubel): implement handleLabel
  }

  @override
  void handleLiteralBool(Token token) {
    listener.handleLiteralBool(token);
    // TODO(danrubel): implement handleLiteralBool
  }

  @override
  void handleLiteralDouble(Token token) {
    listener.handleLiteralDouble(token);
    // TODO(danrubel): implement handleLiteralDouble
  }

  @override
  void handleLiteralInt(Token token) {
    listener.handleLiteralInt(token);
    // TODO(danrubel): implement handleLiteralInt
  }

  @override
  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    listener.handleLiteralList(count, beginToken, constKeyword, endToken);
    // TODO(danrubel): implement handleLiteralList
  }

  @override
  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    listener.handleLiteralMap(count, beginToken, constKeyword, endToken);
    // TODO(danrubel): implement handleLiteralMap
  }

  @override
  void handleLiteralNull(Token token) {
    listener.handleLiteralNull(token);
    // TODO(danrubel): implement handleLiteralNull
  }

  @override
  void handleModifier(Token token) {
    listener.handleModifier(token);
    // TODO(danrubel): implement handleModifier
  }

  @override
  void handleModifiers(int count) {
    listener.handleModifiers(count);
    // TODO(danrubel): implement handleModifiers
  }

  @override
  void handleNamedArgument(Token colon) {
    listener.handleNamedArgument(colon);
    // TODO(danrubel): implement handleNamedArgument
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    expectInOneOf(['ClassDeclaration', 'Method']);
    listener.handleNativeClause(nativeToken, hasName);
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    expectInOneOf(['Method']);
    listener.handleNativeFunctionBody(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    expectInOneOf(['Method']);
    listener.handleNativeFunctionBodyIgnored(nativeToken, semicolon);
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    expectInOneOf(['Method']);
    listener.handleNativeFunctionBodySkipped(nativeToken, semicolon);
  }

  @override
  void handleNoArguments(Token token) {
    listener.handleNoArguments(token);
    // TODO(danrubel): implement handleNoArguments
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    listener.handleNoConstructorReferenceContinuationAfterTypeArguments(token);
    // TODO(danrubel): implement handleNoConstructorReferenceContinuationAfterTypeArguments
  }

  @override
  void handleNoExpression(Token token) {
    listener.handleNoExpression(token);
    // TODO(danrubel): implement handleNoExpression
  }

  @override
  void handleNoFieldInitializer(Token token) {
    listener.handleNoFieldInitializer(token);
    // TODO(danrubel): implement handleNoFieldInitializer
  }

  @override
  void handleNoFormalParameters(Token token, fasta.MemberKind kind) {
    listener.handleNoFormalParameters(token, kind);
    // TODO(danrubel): implement handleNoFormalParameters
  }

  @override
  void handleNoFunctionBody(Token token) {
    listener.handleNoFunctionBody(token);
    // TODO(danrubel): implement handleNoFunctionBody
  }

  @override
  void handleNoInitializers() {
    listener.handleNoInitializers();
    // TODO(danrubel): implement handleNoInitializers
  }

  @override
  void handleNoName(Token token) {
    listener.handleNoName(token);
    // TODO(danrubel): implement handleNoName
  }

  @override
  void handleNoType(Token token) {
    listener.handleNoType(token);
    // TODO(danrubel): implement handleNoType
  }

  @override
  void handleNoTypeArguments(Token token) {
    listener.handleNoTypeArguments(token);
    // TODO(danrubel): implement handleNoTypeArguments
  }

  @override
  void handleNoTypeVariables(Token token) {
    listener.handleNoTypeVariables(token);
    // TODO(danrubel): implement handleNoTypeVariables
  }

  @override
  void handleNoVariableInitializer(Token token) {
    listener.handleNoVariableInitializer(token);
    // TODO(danrubel): implement handleNoVariableInitializer
  }

  @override
  void handleOperator(Token token) {
    listener.handleOperator(token);
    // TODO(danrubel): implement handleOperator
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    listener.handleOperatorName(operatorKeyword, token);
    // TODO(danrubel): implement handleOperatorName
  }

  @override
  void handleParenthesizedExpression(Token token) {
    listener.handleParenthesizedExpression(token);
    // TODO(danrubel): implement handleParenthesizedExpression
  }

  @override
  void handleQualified(Token period) {
    listener.handleQualified(period);
    // TODO(danrubel): implement handleQualified
  }

  @override
  void handleRecoverExpression(Token token, Message message) {
    listener.handleRecoverExpression(token, message);
    // TODO(danrubel): implement handleRecoverExpression
  }

  @override
  void handleRecoverableError(Token token, Message message) {
    listener.handleRecoverableError(token, message);
    // TODO(danrubel): implement handleRecoverableError
  }

  @override
  void handleScript(Token token) {
    listener.handleScript(token);
    // TODO(danrubel): implement handleScript
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    listener.handleSend(beginToken, endToken);
    // TODO(danrubel): implement handleSend
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    listener.handleStringJuxtaposition(literalCount);
    // TODO(danrubel): implement handleStringJuxtaposition
  }

  @override
  void handleStringPart(Token token) {
    listener.handleStringPart(token);
    // TODO(danrubel): implement handleStringPart
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    listener.handleSuperExpression(token, context);
    // TODO(danrubel): implement handleSuperExpression
  }

  @override
  void handleSymbolVoid(Token token) {
    listener.handleSymbolVoid(token);
    // TODO(danrubel): implement handleSymbolVoid
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    listener.handleThisExpression(token, context);
    // TODO(danrubel): implement handleThisExpression
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    listener.handleThrowExpression(throwToken, endToken);
    // TODO(danrubel): implement handleThrowExpression
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    listener.handleType(beginToken, endToken);
    // TODO(danrubel): implement handleType
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    listener.handleUnaryPostfixAssignmentExpression(token);
    // TODO(danrubel): implement handleUnaryPostfixAssignmentExpression
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    listener.handleUnaryPrefixAssignmentExpression(token);
    // TODO(danrubel): implement handleUnaryPrefixAssignmentExpression
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    listener.handleUnaryPrefixExpression(token);
    // TODO(danrubel): implement handleUnaryPrefixExpression
  }

  @override
  Token handleUnrecoverableError(Token token, Message message) {
    return listener.handleUnrecoverableError(token, message);
    // TODO(danrubel): implement handleUnrecoverableError
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    listener.handleValuedFormalParameter(equals, token);
    // TODO(danrubel): implement handleValuedFormalParameter
  }

  @override
  void handleVoidKeyword(Token token) {
    listener.handleVoidKeyword(token);
    // TODO(danrubel): implement handleVoidKeyword
  }

  @override
  Token injectGenericCommentTypeAssign(Token token) {
    return listener.injectGenericCommentTypeAssign(token);
    // TODO(danrubel): implement injectGenericCommentTypeAssign
  }

  @override
  Token injectGenericCommentTypeList(Token token) {
    return listener.injectGenericCommentTypeList(token);
    // TODO(danrubel): implement injectGenericCommentTypeList
  }

  @override
  void logEvent(String name) {
    listener.logEvent(name);
    // TODO(danrubel): implement logEvent
  }

  @override
  Token newSyntheticToken(Token next) {
    return listener.newSyntheticToken(next);
    // TODO(danrubel): implement newSyntheticToken
  }

  // TODO(danrubel): implement recoverableErrors
  @override
  List<fasta.ParserError> get recoverableErrors => listener.recoverableErrors;

  @override
  Token replaceTokenWithGenericCommentTypeAssign(
      Token tokenToStartReplacing, Token tokenWithComment) {
    return listener.replaceTokenWithGenericCommentTypeAssign(
        tokenToStartReplacing, tokenWithComment);
    // TODO(danrubel): implement replaceTokenWithGenericCommentTypeAssign
  }

  @override
  set suppressParseErrors(bool value) {
    listener.suppressParseErrors = value;
    // TODO(danrubel): implement suppressParseErrors
  }
}
