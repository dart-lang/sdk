// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/fasta/parser/identifier_context.dart'
    show IdentifierContext;
import 'package:front_end/src/fasta/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/fasta/util/link.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';

/**
 * Proxy implementation of the fasta parser listener that
 * asserts begin/end pairs of events and forwards all events
 * to the specified listener.
 */
class ForwardingTestListener implements fasta.Listener {
  final fasta.Listener listener;
  final _stack = <String>[];

  void _begin(String event) {
    _stack.add(event);
  }

  void _in(String event) {
    if (_stack.isEmpty || _stack.last != event) {
      fail('Expected $event, but found $_stack');
    }
  }

  void _end(String event) {
    _in(event);
    _stack.removeLast();
  }

  ForwardingTestListener(this.listener);

  @override
  void beginArguments(Token token) {
    listener.beginArguments(token);
    _begin('Arguments');
  }

  @override
  void beginAssert(Token assertKeyword, fasta.Assert kind) {
    listener.beginAssert(assertKeyword, kind);
    _begin('Assert');
  }

  @override
  void beginAwaitExpression(Token token) {
    listener.beginAwaitExpression(token);
    _begin('AwaitExpression');
  }

  @override
  void beginBlock(Token token) {
    listener.beginBlock(token);
    _begin('Block');
  }

  @override
  void beginBlockFunctionBody(Token token) {
    listener.beginBlockFunctionBody(token);
    _begin('BlockFunctionBody');
  }

  @override
  void beginCascade(Token token) {
    listener.beginCascade(token);
    _begin('Cascade');
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    listener.beginCaseExpression(caseKeyword);
    _begin('CaseExpression');
  }

  @override
  void beginCatchClause(Token token) {
    listener.beginCatchClause(token);
    _begin('CatchClause');
  }

  @override
  void beginClassBody(Token token) {
    listener.beginClassBody(token);
    _begin('ClassBody');
  }

  @override
  void beginClassDeclaration(Token beginToken, Token name) {
    listener.beginClassDeclaration(beginToken, name);
    _begin('ClassDeclaration');
  }

  @override
  void beginClassOrNamedMixinApplication(Token token) {
    listener.beginClassOrNamedMixinApplication(token);
    _begin('ClassOrNamedMixinApplication');
  }

  @override
  void beginCombinators(Token token) {
    listener.beginCombinators(token);
    _begin('Combinators');
  }

  @override
  void beginCompilationUnit(Token token) {
    listener.beginCompilationUnit(token);
    _begin('CompilationUnit');
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    listener.beginConditionalUri(ifKeyword);
    _begin('ConditionalUri');
  }

  @override
  void beginConditionalUris(Token token) {
    listener.beginConditionalUris(token);
    _begin('ConditionalUris');
  }

  @override
  void beginConstExpression(Token constKeyword) {
    listener.beginConstExpression(constKeyword);
    _begin('ConstExpression');
  }

  @override
  void beginConstLiteral(Token token) {
    listener.beginConstLiteral(token);
    _begin('ConstLiteral');
  }

  @override
  void beginConstructorReference(Token start) {
    listener.beginConstructorReference(start);
    _begin('ConstructorReference');
  }

  @override
  void beginDoWhileStatement(Token token) {
    listener.beginDoWhileStatement(token);
    _begin('DoWhileStatement');
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    listener.beginDoWhileStatementBody(token);
    _begin('DoWhileStatementBody');
  }

  @override
  void beginDottedName(Token token) {
    listener.beginDottedName(token);
    _begin('DottedName');
  }

  @override
  void beginElseStatement(Token token) {
    listener.beginElseStatement(token);
    _begin('ElseStatement');
  }

  @override
  void beginEnum(Token enumKeyword) {
    listener.beginEnum(enumKeyword);
    _begin('Enum');
  }

  @override
  void beginExport(Token token) {
    listener.beginExport(token);
    _begin('Export');
  }

  @override
  void beginExpressionStatement(Token token) {
    listener.beginExpressionStatement(token);
    _begin('ExpressionStatement');
  }

  @override
  void beginFactoryMethod(Token token) {
    listener.beginFactoryMethod(token);
    _begin('FactoryMethod');
  }

  @override
  void beginFieldInitializer(Token token) {
    listener.beginFieldInitializer(token);
    _begin('FieldInitializer');
  }

  @override
  void beginForInBody(Token token) {
    listener.beginForInBody(token);
    _begin('ForInBody');
  }

  @override
  void beginForInExpression(Token token) {
    listener.beginForInExpression(token);
    _begin('ForInExpression');
  }

  @override
  void beginForStatement(Token token) {
    listener.beginForStatement(token);
    _begin('ForStatement');
  }

  @override
  void beginForStatementBody(Token token) {
    listener.beginForStatementBody(token);
    _begin('ForStatementBody');
  }

  @override
  void beginFormalParameter(Token token, fasta.MemberKind kind) {
    listener.beginFormalParameter(token, kind);
    _begin('FormalParameter');
  }

  @override
  void beginFormalParameters(Token token, fasta.MemberKind kind) {
    listener.beginFormalParameters(token, kind);
    _begin('FormalParameters');
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    listener.beginLocalFunctionDeclaration(token);
    _begin('LocalFunctionDeclaration');
  }

  @override
  void beginFunctionExpression(Token token) {
    listener.beginFunctionExpression(token);
    _begin('FunctionExpression');
  }

  @override
  void beginFunctionName(Token token) {
    listener.beginFunctionName(token);
    _begin('FunctionName');
  }

  @override
  void beginFunctionType(Token beginToken) {
    listener.beginFunctionType(beginToken);
    _begin('FunctionType');
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    listener.beginFunctionTypeAlias(token);
    _begin('FunctionTypeAlias');
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    listener.beginFunctionTypedFormalParameter(token);
    _begin('FunctionTypedFormalParameter');
  }

  @override
  void beginHide(Token hideKeyword) {
    listener.beginHide(hideKeyword);
    _begin('Hide');
  }

  @override
  void beginIdentifierList(Token token) {
    listener.beginIdentifierList(token);
    _begin('IdentifierList');
  }

  @override
  void beginIfStatement(Token token) {
    listener.beginIfStatement(token);
    _begin('IfStatement');
  }

  @override
  void beginImport(Token importKeyword) {
    listener.beginImport(importKeyword);
    _begin('Import');
  }

  @override
  void beginInitializedIdentifier(Token token) {
    listener.beginInitializedIdentifier(token);
    _begin('InitializedIdentifier');
  }

  @override
  void beginInitializer(Token token) {
    listener.beginInitializer(token);
    _begin('Initializer');
  }

  @override
  void beginInitializers(Token token) {
    listener.beginInitializers(token);
    _begin('Initializers');
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    listener.beginLabeledStatement(token, labelCount);
    _begin('LabeledStatement');
  }

  @override
  void beginLibraryName(Token token) {
    listener.beginLibraryName(token);
    _begin('LibraryName');
  }

  @override
  void beginLiteralMapEntry(Token token) {
    listener.beginLiteralMapEntry(token);
    _begin('LiteralMapEntry');
  }

  @override
  void beginLiteralString(Token token) {
    listener.beginLiteralString(token);
    _begin('LiteralString');
  }

  @override
  void beginLiteralSymbol(Token token) {
    listener.beginLiteralSymbol(token);
    _begin('LiteralSymbol');
  }

  @override
  void beginMember(Token token) {
    listener.beginMember(token);
    _begin('Member');
  }

  @override
  void beginMetadata(Token token) {
    listener.beginMetadata(token);
    _begin('Metadata');
  }

  @override
  void beginMetadataStar(Token token) {
    listener.beginMetadataStar(token);
    _begin('MetadataStar');
  }

  @override
  void beginMethod(Token token, Token name) {
    listener.beginMethod(token, name);
    _begin('Method');
  }

  @override
  void beginMixinApplication(Token token) {
    listener.beginMixinApplication(token);
    _begin('MixinApplication');
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    listener.beginNamedFunctionExpression(token);
    _begin('NamedFunctionExpression');
  }

  @override
  void beginNamedMixinApplication(Token beginToken, Token name) {
    listener.beginNamedMixinApplication(beginToken, name);
    _begin('NamedMixinApplication');
  }

  @override
  void beginNewExpression(Token token) {
    listener.beginNewExpression(token);
    _begin('NewExpression');
  }

  @override
  void beginOptionalFormalParameters(Token token) {
    listener.beginOptionalFormalParameters(token);
    _begin('OptionalFormalParameters');
  }

  @override
  void beginPart(Token token) {
    listener.beginPart(token);
    _begin('Part');
  }

  @override
  void beginPartOf(Token token) {
    listener.beginPartOf(token);
    _begin('PartOf');
  }

  @override
  void beginRedirectingFactoryBody(Token token) {
    listener.beginRedirectingFactoryBody(token);
    _begin('RedirectingFactoryBody');
  }

  @override
  void beginRethrowStatement(Token token) {
    listener.beginRethrowStatement(token);
    _begin('RethrowStatement');
  }

  @override
  void beginReturnStatement(Token token) {
    listener.beginReturnStatement(token);
    _begin('ReturnStatement');
  }

  @override
  void beginShow(Token showKeyword) {
    listener.beginShow(showKeyword);
    _begin('Show');
  }

  @override
  void beginSwitchBlock(Token token) {
    listener.beginSwitchBlock(token);
    _begin('SwitchBlock');
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    listener.beginSwitchCase(labelCount, expressionCount, firstToken);
    _begin('SwitchCase');
  }

  @override
  void beginSwitchStatement(Token token) {
    listener.beginSwitchStatement(token);
    _begin('SwitchStatement');
  }

  @override
  void beginThenStatement(Token token) {
    listener.beginThenStatement(token);
    _begin('ThenStatement');
  }

  @override
  void beginTopLevelMember(Token token) {
    listener.beginTopLevelMember(token);
    _begin('TopLevelMember');
  }

  @override
  void beginTopLevelMethod(Token token, Token name) {
    listener.beginTopLevelMethod(token, name);
    _begin('TopLevelMethod');
  }

  @override
  void beginTryStatement(Token token) {
    listener.beginTryStatement(token);
    _begin('TryStatement');
  }

  @override
  void beginTypeArguments(Token token) {
    listener.beginTypeArguments(token);
    _begin('TypeArguments');
  }

  @override
  void beginTypeList(Token token) {
    listener.beginTypeList(token);
    _begin('TypeList');
  }

  @override
  void beginTypeVariable(Token token) {
    listener.beginTypeVariable(token);
    _begin('TypeVariable');
  }

  @override
  void beginTypeVariables(Token token) {
    listener.beginTypeVariables(token);
    _begin('TypeVariables');
  }

  @override
  void beginVariableInitializer(Token token) {
    listener.beginVariableInitializer(token);
    _begin('VariableInitializer');
  }

  @override
  void beginVariablesDeclaration(Token token) {
    listener.beginVariablesDeclaration(token);
    _begin('VariablesDeclaration');
  }

  @override
  void beginWhileStatement(Token token) {
    listener.beginWhileStatement(token);
    _begin('WhileStatement');
  }

  @override
  void beginWhileStatementBody(Token token) {
    listener.beginWhileStatementBody(token);
    _begin('WhileStatementBody');
  }

  @override
  void beginYieldStatement(Token token) {
    listener.beginYieldStatement(token);
    _begin('YieldStatement');
  }

  @override
  void discardTypeReplacedWithCommentTypeAssign() {
    listener.discardTypeReplacedWithCommentTypeAssign();
    // TODO(danrubel): implement discardTypeReplacedWithCommentTypeAssign
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    _end('Arguments');
    listener.endArguments(count, beginToken, endToken);
  }

  @override
  void endAssert(Token assertKeyword, fasta.Assert kind, Token leftParenthesis,
      Token commaToken, Token rightParenthesis, Token semicolonToken) {
    _end('Assert');
    listener.endAssert(assertKeyword, kind, leftParenthesis, commaToken,
        rightParenthesis, semicolonToken);
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    _end('AwaitExpression');
    listener.endAwaitExpression(beginToken, endToken);
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    _end('Block');
    listener.endBlock(count, beginToken, endToken);
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    _end('BlockFunctionBody');
    listener.endBlockFunctionBody(count, beginToken, endToken);
  }

  @override
  void endCascade() {
    _end('Cascade');
    listener.endCascade();
  }

  @override
  void endCaseExpression(Token colon) {
    _end('CaseExpression');
    listener.endCaseExpression(colon);
  }

  @override
  void endCatchClause(Token token) {
    _end('CatchClause');
    listener.endCatchClause(token);
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    _end('ClassBody');
    listener.endClassBody(memberCount, beginToken, endToken);
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    _end('ClassDeclaration');
    _end('ClassOrNamedMixinApplication');
    listener.endClassDeclaration(interfacesCount, beginToken, classKeyword,
        extendsKeyword, implementsKeyword, endToken);
  }

  @override
  void endCombinators(int count) {
    _end('Combinators');
    listener.endCombinators(count);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    _end('CompilationUnit');
    listener.endCompilationUnit(count, token);
  }

  @override
  void endConditionalUri(Token ifKeyword, Token equalitySign) {
    _end('ConditionalUri');
    listener.endConditionalUri(ifKeyword, equalitySign);
  }

  @override
  void endConditionalUris(int count) {
    _end('ConditionalUris');
    listener.endConditionalUris(count);
  }

  @override
  void endConstExpression(Token token) {
    _end('ConstExpression');
    listener.endConstExpression(token);
  }

  @override
  void endConstLiteral(Token token) {
    _end('ConstLiteral');
    listener.endConstLiteral(token);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    _end('ConstructorReference');
    listener.endConstructorReference(start, periodBeforeName, endToken);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    _end('DoWhileStatement');
    listener.endDoWhileStatement(doKeyword, whileKeyword, endToken);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    _end('DoWhileStatementBody');
    listener.endDoWhileStatementBody(token);
  }

  @override
  void endDottedName(int count, Token firstIdentifier) {
    _end('DottedName');
    listener.endDottedName(count, firstIdentifier);
  }

  @override
  void endElseStatement(Token token) {
    _end('ElseStatement');
    listener.endElseStatement(token);
  }

  @override
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    _end('Enum');
    listener.endEnum(enumKeyword, endBrace, count);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    _end('Export');
    listener.endExport(exportKeyword, semicolon);
  }

  @override
  void endExpressionStatement(Token token) {
    _end('ExpressionStatement');
    listener.endExpressionStatement(token);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    _end('FactoryMethod');
    listener.endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    _end('FieldInitializer');
    listener.endFieldInitializer(assignment, token);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    // beginMember --> endFields, endMember
    _in('Member');
    listener.endFields(count, beginToken, endToken);
  }

  @override
  void endForIn(Token awaitToken, Token forToken, Token leftParenthesis,
      Token inKeyword, Token rightParenthesis, Token endToken) {
    _end('ForStatement');
    listener.endForIn(awaitToken, forToken, leftParenthesis, inKeyword,
        rightParenthesis, endToken);
  }

  @override
  void endForInBody(Token token) {
    _end('ForInBody');
    listener.endForInBody(token);
  }

  @override
  void endForInExpression(Token token) {
    _end('ForInExpression');
    listener.endForInExpression(token);
  }

  @override
  void endForStatement(Token forKeyword, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    _end('ForStatement');
    listener.endForStatement(
        forKeyword, leftSeparator, updateExpressionCount, endToken);
  }

  @override
  void endForStatementBody(Token token) {
    _end('ForStatementBody');
    listener.endForStatementBody(token);
  }

  @override
  void endFormalParameter(Token thisKeyword, Token nameToken,
      fasta.FormalParameterKind kind, fasta.MemberKind memberKind) {
    _end('FormalParameter');
    listener.endFormalParameter(thisKeyword, nameToken, kind, memberKind);
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, fasta.MemberKind kind) {
    _end('FormalParameters');
    listener.endFormalParameters(count, beginToken, endToken, kind);
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    _end('LocalFunctionDeclaration');
    listener.endLocalFunctionDeclaration(endToken);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    _end('FunctionExpression');
    listener.endFunctionExpression(beginToken, token);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    _end('FunctionName');
    listener.endFunctionName(beginToken, token);
  }

  @override
  void endFunctionType(Token functionToken, Token endToken) {
    _end('FunctionType');
    listener.endFunctionType(functionToken, endToken);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    _end('FunctionTypeAlias');
    listener.endFunctionTypeAlias(typedefKeyword, equals, endToken);
  }

  @override
  void endFunctionTypedFormalParameter() {
    _end('FunctionTypedFormalParameter');
    listener.endFunctionTypedFormalParameter();
  }

  @override
  void endHide(Token hideKeyword) {
    _end('Hide');
    listener.endHide(hideKeyword);
  }

  @override
  void endIdentifierList(int count) {
    _end('IdentifierList');
    listener.endIdentifierList(count);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    _end('IfStatement');
    listener.endIfStatement(ifToken, elseToken);
  }

  @override
  void endImport(Token importKeyword, Token DeferredKeyword, Token asKeyword,
      Token semicolon) {
    _end('Import');
    listener.endImport(importKeyword, DeferredKeyword, asKeyword, semicolon);
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    _end('InitializedIdentifier');
    listener.endInitializedIdentifier(nameToken);
  }

  @override
  void endInitializer(Token token) {
    _end('Initializer');
    listener.endInitializer(token);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    _end('Initializers');
    listener.endInitializers(count, beginToken, endToken);
  }

  @override
  void endLabeledStatement(int labelCount) {
    _end('LabeledStatement');
    listener.endLabeledStatement(labelCount);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    _end('LibraryName');
    listener.endLibraryName(libraryKeyword, semicolon);
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
    _end('LiteralMapEntry');
    listener.endLiteralMapEntry(colon, endToken);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    _end('LiteralString');
    listener.endLiteralString(interpolationCount, endToken);
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    _end('LiteralSymbol');
    listener.endLiteralSymbol(hashToken, identifierCount);
  }

  @override
  void endMember() {
    _end('Member');
    listener.endMember();
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    _end('Metadata');
    listener.endMetadata(beginToken, periodBeforeName, endToken);
  }

  @override
  void endMetadataStar(int count, bool forParameter) {
    _end('MetadataStar');
    listener.endMetadataStar(count, forParameter);
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    _end('Method');
    listener.endMethod(getOrSet, beginToken, endToken);
  }

  @override
  void endMixinApplication(Token withKeyword) {
    _end('MixinApplication');
    listener.endMixinApplication(withKeyword);
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    _end('NamedFunctionExpression');
    listener.endNamedFunctionExpression(endToken);
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    _end('NamedMixinApplication');
    _end('ClassOrNamedMixinApplication');
    listener.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, endToken);
  }

  @override
  void endNewExpression(Token token) {
    _end('NewExpression');
    listener.endNewExpression(token);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    _end('OptionalFormalParameters');
    listener.endOptionalFormalParameters(count, beginToken, endToken);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    _end('Part');
    listener.endPart(partKeyword, semicolon);
  }

  @override
  void endPartOf(Token partKeyword, Token semicolon, bool hasName) {
    _end('PartOf');
    listener.endPartOf(partKeyword, semicolon, hasName);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    _end('RedirectingFactoryBody');
    listener.endRedirectingFactoryBody(beginToken, endToken);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    _end('RethrowStatement');
    listener.endRethrowStatement(rethrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    _end('ReturnStatement');
    listener.endReturnStatement(hasExpression, beginToken, endToken);
  }

  @override
  void endShow(Token showKeyword) {
    _end('Show');
    listener.endShow(showKeyword);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    _end('SwitchBlock');
    listener.endSwitchBlock(caseCount, beginToken, endToken);
  }

  @override
  void endSwitchCase(int labelCount, int expressionCount, Token defaultKeyword,
      int statementCount, Token firstToken, Token endToken) {
    _end('SwitchCase');
    listener.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        statementCount, firstToken, endToken);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    _end('SwitchStatement');
    listener.endSwitchStatement(switchKeyword, endToken);
  }

  @override
  void endThenStatement(Token token) {
    _end('ThenStatement');
    listener.endThenStatement(token);
  }

  @override
  void endTopLevelDeclaration(Token token) {
    // There is no corresponding beginTopLevelDeclaration
    //_expectBegin('TopLevelDeclaration');
    listener.endTopLevelDeclaration(token);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    _end('TopLevelMember');
    listener.endTopLevelFields(count, beginToken, endToken);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    _end('TopLevelMethod');
    _end('TopLevelMember');
    listener.endTopLevelMethod(beginToken, getOrSet, endToken);
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    _end('TryStatement');
    listener.endTryStatement(catchCount, tryKeyword, finallyKeyword);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    _end('TypeArguments');
    listener.endTypeArguments(count, beginToken, endToken);
  }

  @override
  void endTypeList(int count) {
    _end('TypeList');
    listener.endTypeList(count);
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    _end('TypeVariable');
    listener.endTypeVariable(token, extendsOrSuper);
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    _end('TypeVariables');
    listener.endTypeVariables(count, beginToken, endToken);
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    _end('VariableInitializer');
    listener.endVariableInitializer(assignmentOperator);
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    _end('VariablesDeclaration');
    listener.endVariablesDeclaration(count, endToken);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    _end('WhileStatement');
    listener.endWhileStatement(whileKeyword, endToken);
  }

  @override
  void endWhileStatementBody(Token token) {
    _end('WhileStatementBody');
    listener.endWhileStatementBody(token);
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    _end('YieldStatement');
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
  void handleBinaryExpression(Token token) {
    listener.handleBinaryExpression(token);
    // TODO(danrubel): implement handleBinaryExpression
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
  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    listener.handleCatchBlock(onKeyword, catchKeyword);
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
  Link<Token> handleMemberName(Link<Token> identifiers) {
    return listener.handleMemberName(identifiers);
    // TODO(danrubel): implement handleMemberName
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

  // TODO(danrubel): implement uri
  @override
  Uri get uri => listener.uri;
}
