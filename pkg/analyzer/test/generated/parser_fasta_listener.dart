// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/parser/forwarding_listener.dart';
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
class ForwardingTestListener extends ForwardingListener {
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

  ForwardingTestListener([Listener listener]) : super(listener);

  @override
  void beginArguments(Token token) {
    super.beginArguments(token);
    begin('Arguments');
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    super.beginAssert(assertKeyword, kind);
    begin('Assert');
  }

  @override
  void beginAwaitExpression(Token token) {
    super.beginAwaitExpression(token);
    begin('AwaitExpression');
  }

  @override
  void beginBlock(Token token) {
    super.beginBlock(token);
    begin('Block');
  }

  @override
  void beginBlockFunctionBody(Token token) {
    super.beginBlockFunctionBody(token);
    begin('BlockFunctionBody');
  }

  @override
  void beginCascade(Token token) {
    super.beginCascade(token);
    begin('Cascade');
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    super.beginCaseExpression(caseKeyword);
    begin('CaseExpression');
  }

  @override
  void beginCatchClause(Token token) {
    super.beginCatchClause(token);
    begin('CatchClause');
  }

  @override
  void beginClassBody(Token token) {
    super.beginClassBody(token);
    begin('ClassBody');
  }

  @override
  void beginClassDeclaration(Token beginToken, Token name) {
    super.beginClassDeclaration(beginToken, name);
    begin('ClassDeclaration');
  }

  @override
  void beginClassOrNamedMixinApplication(Token token) {
    super.beginClassOrNamedMixinApplication(token);
    begin('ClassOrNamedMixinApplication');
  }

  @override
  void beginCombinators(Token token) {
    super.beginCombinators(token);
    begin('Combinators');
  }

  @override
  void beginCompilationUnit(Token token) {
    expectEmpty();
    super.beginCompilationUnit(token);
    begin('CompilationUnit');
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    super.beginConditionalUri(ifKeyword);
    begin('ConditionalUri');
  }

  @override
  void beginConditionalUris(Token token) {
    super.beginConditionalUris(token);
    begin('ConditionalUris');
  }

  @override
  void beginConstExpression(Token constKeyword) {
    super.beginConstExpression(constKeyword);
    begin('ConstExpression');
  }

  @override
  void beginConstLiteral(Token token) {
    super.beginConstLiteral(token);
    begin('ConstLiteral');
  }

  @override
  void beginConstructorReference(Token start) {
    super.beginConstructorReference(start);
    begin('ConstructorReference');
  }

  @override
  void beginDoWhileStatement(Token token) {
    super.beginDoWhileStatement(token);
    begin('DoWhileStatement');
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    super.beginDoWhileStatementBody(token);
    begin('DoWhileStatementBody');
  }

  @override
  void beginDottedName(Token token) {
    super.beginDottedName(token);
    begin('DottedName');
  }

  @override
  void beginElseStatement(Token token) {
    super.beginElseStatement(token);
    begin('ElseStatement');
  }

  @override
  void beginEnum(Token enumKeyword) {
    super.beginEnum(enumKeyword);
    begin('Enum');
  }

  @override
  void beginExport(Token token) {
    super.beginExport(token);
    begin('Export');
  }

  @override
  void beginExpressionStatement(Token token) {
    super.beginExpressionStatement(token);
    begin('ExpressionStatement');
  }

  @override
  void beginFactoryMethod(Token token) {
    super.beginFactoryMethod(token);
    begin('FactoryMethod');
  }

  @override
  void beginFieldInitializer(Token token) {
    super.beginFieldInitializer(token);
    begin('FieldInitializer');
  }

  @override
  void beginForInBody(Token token) {
    super.beginForInBody(token);
    begin('ForInBody');
  }

  @override
  void beginForInExpression(Token token) {
    super.beginForInExpression(token);
    begin('ForInExpression');
  }

  @override
  void beginForStatement(Token token) {
    super.beginForStatement(token);
    begin('ForStatement');
  }

  @override
  void beginForStatementBody(Token token) {
    super.beginForStatementBody(token);
    begin('ForStatementBody');
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind) {
    super.beginFormalParameter(token, kind);
    begin('FormalParameter');
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    super.beginFormalParameters(token, kind);
    begin('FormalParameters');
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    super.beginLocalFunctionDeclaration(token);
    begin('LocalFunctionDeclaration');
  }

  @override
  void beginFunctionExpression(Token token) {
    super.beginFunctionExpression(token);
    begin('FunctionExpression');
  }

  @override
  void beginFunctionName(Token token) {
    super.beginFunctionName(token);
    begin('FunctionName');
  }

  @override
  void beginFunctionType(Token beginToken) {
    super.beginFunctionType(beginToken);
    begin('FunctionType');
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    super.beginFunctionTypeAlias(token);
    begin('FunctionTypeAlias');
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    super.beginFunctionTypedFormalParameter(token);
    begin('FunctionTypedFormalParameter');
  }

  @override
  void beginHide(Token hideKeyword) {
    super.beginHide(hideKeyword);
    begin('Hide');
  }

  @override
  void beginIdentifierList(Token token) {
    super.beginIdentifierList(token);
    begin('IdentifierList');
  }

  @override
  void beginIfStatement(Token token) {
    super.beginIfStatement(token);
    begin('IfStatement');
  }

  @override
  void beginImport(Token importKeyword) {
    super.beginImport(importKeyword);
    begin('Import');
  }

  @override
  void beginInitializedIdentifier(Token token) {
    super.beginInitializedIdentifier(token);
    begin('InitializedIdentifier');
  }

  @override
  void beginInitializer(Token token) {
    super.beginInitializer(token);
    begin('Initializer');
  }

  @override
  void beginInitializers(Token token) {
    super.beginInitializers(token);
    begin('Initializers');
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    super.beginLabeledStatement(token, labelCount);
    begin('LabeledStatement');
  }

  @override
  void beginLibraryName(Token token) {
    super.beginLibraryName(token);
    begin('LibraryName');
  }

  @override
  void beginLiteralMapEntry(Token token) {
    super.beginLiteralMapEntry(token);
    begin('LiteralMapEntry');
  }

  @override
  void beginLiteralString(Token token) {
    super.beginLiteralString(token);
    begin('LiteralString');
  }

  @override
  void beginLiteralSymbol(Token token) {
    super.beginLiteralSymbol(token);
    begin('LiteralSymbol');
  }

  @override
  void beginMember(Token token) {
    super.beginMember(token);
    begin('Member');
  }

  @override
  void beginMetadata(Token token) {
    super.beginMetadata(token);
    begin('Metadata');
  }

  @override
  void beginMetadataStar(Token token) {
    super.beginMetadataStar(token);
    begin('MetadataStar');
  }

  @override
  void beginMethod(Token token, Token name) {
    super.beginMethod(token, name);
    begin('Method');
  }

  @override
  void beginMixinApplication(Token token) {
    super.beginMixinApplication(token);
    begin('MixinApplication');
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    super.beginNamedFunctionExpression(token);
    begin('NamedFunctionExpression');
  }

  @override
  void beginNamedMixinApplication(Token beginToken, Token name) {
    super.beginNamedMixinApplication(beginToken, name);
    begin('NamedMixinApplication');
  }

  @override
  void beginNewExpression(Token token) {
    super.beginNewExpression(token);
    begin('NewExpression');
  }

  @override
  void beginOptionalFormalParameters(Token token) {
    super.beginOptionalFormalParameters(token);
    begin('OptionalFormalParameters');
  }

  @override
  void beginPart(Token token) {
    super.beginPart(token);
    begin('Part');
  }

  @override
  void beginPartOf(Token token) {
    super.beginPartOf(token);
    begin('PartOf');
  }

  @override
  void beginRedirectingFactoryBody(Token token) {
    super.beginRedirectingFactoryBody(token);
    begin('RedirectingFactoryBody');
  }

  @override
  void beginRethrowStatement(Token token) {
    super.beginRethrowStatement(token);
    begin('RethrowStatement');
  }

  @override
  void beginReturnStatement(Token token) {
    super.beginReturnStatement(token);
    begin('ReturnStatement');
  }

  @override
  void beginShow(Token showKeyword) {
    super.beginShow(showKeyword);
    begin('Show');
  }

  @override
  void beginSwitchBlock(Token token) {
    super.beginSwitchBlock(token);
    begin('SwitchBlock');
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    super.beginSwitchCase(labelCount, expressionCount, firstToken);
    begin('SwitchCase');
  }

  @override
  void beginSwitchStatement(Token token) {
    super.beginSwitchStatement(token);
    begin('SwitchStatement');
  }

  @override
  void beginThenStatement(Token token) {
    super.beginThenStatement(token);
    begin('ThenStatement');
  }

  @override
  void beginTopLevelMember(Token token) {
    super.beginTopLevelMember(token);
    begin('TopLevelMember');
  }

  @override
  void beginTopLevelMethod(Token token, Token name) {
    super.beginTopLevelMethod(token, name);
    begin('TopLevelMethod');
  }

  @override
  void beginTryStatement(Token token) {
    super.beginTryStatement(token);
    begin('TryStatement');
  }

  @override
  void beginTypeArguments(Token token) {
    super.beginTypeArguments(token);
    begin('TypeArguments');
  }

  @override
  void beginTypeList(Token token) {
    super.beginTypeList(token);
    begin('TypeList');
  }

  @override
  void beginTypeVariable(Token token) {
    super.beginTypeVariable(token);
    begin('TypeVariable');
  }

  @override
  void beginTypeVariables(Token token) {
    super.beginTypeVariables(token);
    begin('TypeVariables');
  }

  @override
  void beginVariableInitializer(Token token) {
    super.beginVariableInitializer(token);
    begin('VariableInitializer');
  }

  @override
  void beginVariablesDeclaration(Token token) {
    super.beginVariablesDeclaration(token);
    begin('VariablesDeclaration');
  }

  @override
  void beginWhileStatement(Token token) {
    super.beginWhileStatement(token);
    begin('WhileStatement');
  }

  @override
  void beginWhileStatementBody(Token token) {
    super.beginWhileStatementBody(token);
    begin('WhileStatementBody');
  }

  @override
  void beginYieldStatement(Token token) {
    super.beginYieldStatement(token);
    begin('YieldStatement');
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    end('Arguments');
    super.endArguments(count, beginToken, endToken);
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token commaToken, Token semicolonToken) {
    end('Assert');
    super.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, semicolonToken);
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    end('AwaitExpression');
    super.endAwaitExpression(beginToken, endToken);
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    end('Block');
    super.endBlock(count, beginToken, endToken);
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    end('BlockFunctionBody');
    super.endBlockFunctionBody(count, beginToken, endToken);
  }

  @override
  void endCascade() {
    end('Cascade');
    super.endCascade();
  }

  @override
  void endCaseExpression(Token colon) {
    end('CaseExpression');
    super.endCaseExpression(colon);
  }

  @override
  void endCatchClause(Token token) {
    end('CatchClause');
    super.endCatchClause(token);
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    end('ClassBody');
    super.endClassBody(memberCount, beginToken, endToken);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    end('ClassDeclaration');
    end('ClassOrNamedMixinApplication');
    super.endClassDeclaration(beginToken, endToken);
  }

  @override
  void endCombinators(int count) {
    end('Combinators');
    super.endCombinators(count);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    end('CompilationUnit');
    super.endCompilationUnit(count, token);
    expectEmpty();
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    end('ConditionalUri');
    super.endConditionalUri(ifKeyword, leftParen, equalSign);
  }

  @override
  void endConditionalUris(int count) {
    end('ConditionalUris');
    super.endConditionalUris(count);
  }

  @override
  void endConstExpression(Token token) {
    end('ConstExpression');
    super.endConstExpression(token);
  }

  @override
  void endConstLiteral(Token token) {
    end('ConstLiteral');
    super.endConstLiteral(token);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    end('ConstructorReference');
    super.endConstructorReference(start, periodBeforeName, endToken);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    end('DoWhileStatement');
    super.endDoWhileStatement(doKeyword, whileKeyword, endToken);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    end('DoWhileStatementBody');
    super.endDoWhileStatementBody(token);
  }

  @override
  void endDottedName(int count, Token firstIdentifier) {
    end('DottedName');
    super.endDottedName(count, firstIdentifier);
  }

  @override
  void endElseStatement(Token token) {
    end('ElseStatement');
    super.endElseStatement(token);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    end('Enum');
    super.endEnum(enumKeyword, leftBrace, count);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    end('Export');
    super.endExport(exportKeyword, semicolon);
  }

  @override
  void endExpressionStatement(Token token) {
    end('ExpressionStatement');
    super.endExpressionStatement(token);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    end('FactoryMethod');
    super.endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    end('FieldInitializer');
    super.endFieldInitializer(assignment, token);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    // beginMember --> endFields, endMember
    expectIn('Member');
    super.endFields(count, beginToken, endToken);
  }

  @override
  void endForIn(Token awaitToken, Token forToken, Token leftParen,
      Token inKeyword, Token endToken) {
    end('ForStatement');
    super.endForIn(awaitToken, forToken, leftParen, inKeyword, endToken);
  }

  @override
  void endForInBody(Token token) {
    end('ForInBody');
    super.endForInBody(token);
  }

  @override
  void endForInExpression(Token token) {
    end('ForInExpression');
    super.endForInExpression(token);
  }

  @override
  void endForStatement(Token forKeyword, Token leftParen, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    end('ForStatement');
    super.endForStatement(
        forKeyword, leftParen, leftSeparator, updateExpressionCount, endToken);
  }

  @override
  void endForStatementBody(Token token) {
    end('ForStatementBody');
    super.endForStatementBody(token);
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    end('FormalParameter');
    super.endFormalParameter(
        thisKeyword, periodAfterThis, nameToken, kind, memberKind);
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    end('FormalParameters');
    super.endFormalParameters(count, beginToken, endToken, kind);
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    end('LocalFunctionDeclaration');
    super.endLocalFunctionDeclaration(endToken);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    end('FunctionExpression');
    super.endFunctionExpression(beginToken, token);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    end('FunctionName');
    super.endFunctionName(beginToken, token);
  }

  @override
  void endFunctionType(Token functionToken, Token endToken) {
    end('FunctionType');
    super.endFunctionType(functionToken, endToken);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    end('FunctionTypeAlias');
    super.endFunctionTypeAlias(typedefKeyword, equals, endToken);
  }

  @override
  void endFunctionTypedFormalParameter() {
    end('FunctionTypedFormalParameter');
    super.endFunctionTypedFormalParameter();
  }

  @override
  void endHide(Token hideKeyword) {
    end('Hide');
    super.endHide(hideKeyword);
  }

  @override
  void endIdentifierList(int count) {
    end('IdentifierList');
    super.endIdentifierList(count);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    end('IfStatement');
    super.endIfStatement(ifToken, elseToken);
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    end('Import');
    super.endImport(importKeyword, semicolon);
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    end('InitializedIdentifier');
    super.endInitializedIdentifier(nameToken);
  }

  @override
  void endInitializer(Token token) {
    end('Initializer');
    super.endInitializer(token);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    end('Initializers');
    super.endInitializers(count, beginToken, endToken);
  }

  @override
  void endLabeledStatement(int labelCount) {
    end('LabeledStatement');
    super.endLabeledStatement(labelCount);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    end('LibraryName');
    super.endLibraryName(libraryKeyword, semicolon);
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
    end('LiteralMapEntry');
    super.endLiteralMapEntry(colon, endToken);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    end('LiteralString');
    super.endLiteralString(interpolationCount, endToken);
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    end('LiteralSymbol');
    super.endLiteralSymbol(hashToken, identifierCount);
  }

  @override
  void endMember() {
    end('Member');
    super.endMember();
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    end('Metadata');
    super.endMetadata(beginToken, periodBeforeName, endToken);
  }

  @override
  void endMetadataStar(int count) {
    end('MetadataStar');
    super.endMetadataStar(count);
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    end('Method');
    super.endMethod(getOrSet, beginToken, endToken);
  }

  @override
  void endMixinApplication(Token withKeyword) {
    end('MixinApplication');
    super.endMixinApplication(withKeyword);
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    end('NamedFunctionExpression');
    super.endNamedFunctionExpression(endToken);
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    end('NamedMixinApplication');
    end('ClassOrNamedMixinApplication');
    super.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, endToken);
  }

  @override
  void endNewExpression(Token token) {
    end('NewExpression');
    super.endNewExpression(token);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    end('OptionalFormalParameters');
    super.endOptionalFormalParameters(count, beginToken, endToken);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    end('Part');
    super.endPart(partKeyword, semicolon);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    end('PartOf');
    super.endPartOf(partKeyword, ofKeyword, semicolon, hasName);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    end('RedirectingFactoryBody');
    super.endRedirectingFactoryBody(beginToken, endToken);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    end('RethrowStatement');
    super.endRethrowStatement(rethrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    end('ReturnStatement');
    super.endReturnStatement(hasExpression, beginToken, endToken);
  }

  @override
  void endShow(Token showKeyword) {
    end('Show');
    super.endShow(showKeyword);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    end('SwitchBlock');
    super.endSwitchBlock(caseCount, beginToken, endToken);
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
    end('SwitchCase');
    super.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        colonAfterDefault, statementCount, firstToken, endToken);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    end('SwitchStatement');
    super.endSwitchStatement(switchKeyword, endToken);
  }

  @override
  void endThenStatement(Token token) {
    end('ThenStatement');
    super.endThenStatement(token);
  }

  @override
  void endTopLevelDeclaration(Token token) {
    // There is no corresponding beginTopLevelDeclaration
    //_expectBegin('TopLevelDeclaration');
    expectIn('CompilationUnit');
    super.endTopLevelDeclaration(token);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    end('TopLevelMember');
    super.endTopLevelFields(count, beginToken, endToken);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    end('TopLevelMethod');
    end('TopLevelMember');
    super.endTopLevelMethod(beginToken, getOrSet, endToken);
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    end('TryStatement');
    super.endTryStatement(catchCount, tryKeyword, finallyKeyword);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    end('TypeArguments');
    super.endTypeArguments(count, beginToken, endToken);
  }

  @override
  void endTypeList(int count) {
    end('TypeList');
    super.endTypeList(count);
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    end('TypeVariable');
    super.endTypeVariable(token, extendsOrSuper);
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    end('TypeVariables');
    super.endTypeVariables(count, beginToken, endToken);
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    end('VariableInitializer');
    super.endVariableInitializer(assignmentOperator);
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    end('VariablesDeclaration');
    super.endVariablesDeclaration(count, endToken);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    end('WhileStatement');
    super.endWhileStatement(whileKeyword, endToken);
  }

  @override
  void endWhileStatementBody(Token token) {
    end('WhileStatementBody');
    super.endWhileStatementBody(token);
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    end('YieldStatement');
    super.endYieldStatement(yieldToken, starToken, endToken);
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    expectIn('ClassDeclaration');
    listener.handleClassExtends(extendsKeyword);
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    expectIn('ClassDeclaration');
    listener.handleClassHeader(begin, classKeyword, nativeToken);
  }

  @override
  void handleClassImplements(Token implementsKeyword, int interfacesCount) {
    expectIn('ClassDeclaration');
    listener.handleClassImplements(implementsKeyword, interfacesCount);
  }

  @override
  void handleRecoverClassHeader() {
    expectIn('ClassDeclaration');
    listener.handleRecoverClassHeader();
  }

  @override
  void handleRecoverImport(Token semicolon) {
    expectIn('CompilationUnit');
    listener.handleRecoverImport(semicolon);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    expectIn('CompilationUnit');
    listener.handleInvalidTopLevelDeclaration(endToken);
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
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
    expectIn('Import');
    listener.handleImportPrefix(deferredKeyword, asKeyword);
  }

  @override
  void handleScript(Token token) {
    expectIn('CompilationUnit');
    listener.handleScript(token);
  }
}
