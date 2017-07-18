// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/src/generated/parser.dart' as analyzer;
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
  void beginArguments(analyzer.Token token) {
    listener.beginArguments(token);
    _begin('Arguments');
  }

  @override
  void beginAssert(analyzer.Token assertKeyword, fasta.Assert kind) {
    listener.beginAssert(assertKeyword, kind);
    _begin('Assert');
  }

  @override
  void beginAwaitExpression(analyzer.Token token) {
    listener.beginAwaitExpression(token);
    _begin('AwaitExpression');
  }

  @override
  void beginBlock(analyzer.Token token) {
    listener.beginBlock(token);
    _begin('Block');
  }

  @override
  void beginBlockFunctionBody(analyzer.Token token) {
    listener.beginBlockFunctionBody(token);
    _begin('BlockFunctionBody');
  }

  @override
  void beginCascade(analyzer.Token token) {
    listener.beginCascade(token);
    _begin('Cascade');
  }

  @override
  void beginCaseExpression(analyzer.Token caseKeyword) {
    listener.beginCaseExpression(caseKeyword);
    _begin('CaseExpression');
  }

  @override
  void beginCatchClause(analyzer.Token token) {
    listener.beginCatchClause(token);
    _begin('CatchClause');
  }

  @override
  void beginClassBody(analyzer.Token token) {
    listener.beginClassBody(token);
    _begin('ClassBody');
  }

  @override
  void beginClassDeclaration(analyzer.Token beginToken, analyzer.Token name) {
    listener.beginClassDeclaration(beginToken, name);
    _begin('ClassDeclaration');
  }

  @override
  void beginClassOrNamedMixinApplication(analyzer.Token token) {
    listener.beginClassOrNamedMixinApplication(token);
    _begin('ClassOrNamedMixinApplication');
  }

  @override
  void beginCombinators(analyzer.Token token) {
    listener.beginCombinators(token);
    _begin('Combinators');
  }

  @override
  void beginCompilationUnit(analyzer.Token token) {
    listener.beginCompilationUnit(token);
    _begin('CompilationUnit');
  }

  @override
  void beginConditionalUri(analyzer.Token ifKeyword) {
    listener.beginConditionalUri(ifKeyword);
    _begin('ConditionalUri');
  }

  @override
  void beginConditionalUris(analyzer.Token token) {
    listener.beginConditionalUris(token);
    _begin('ConditionalUris');
  }

  @override
  void beginConstExpression(analyzer.Token constKeyword) {
    listener.beginConstExpression(constKeyword);
    _begin('ConstExpression');
  }

  @override
  void beginConstLiteral(analyzer.Token token) {
    listener.beginConstLiteral(token);
    _begin('ConstLiteral');
  }

  @override
  void beginConstructorReference(analyzer.Token start) {
    listener.beginConstructorReference(start);
    _begin('ConstructorReference');
  }

  @override
  void beginDoWhileStatement(analyzer.Token token) {
    listener.beginDoWhileStatement(token);
    _begin('DoWhileStatement');
  }

  @override
  void beginDoWhileStatementBody(analyzer.Token token) {
    listener.beginDoWhileStatementBody(token);
    _begin('DoWhileStatementBody');
  }

  @override
  void beginDottedName(analyzer.Token token) {
    listener.beginDottedName(token);
    _begin('DottedName');
  }

  @override
  void beginElseStatement(analyzer.Token token) {
    listener.beginElseStatement(token);
    _begin('ElseStatement');
  }

  @override
  void beginEnum(analyzer.Token enumKeyword) {
    listener.beginEnum(enumKeyword);
    _begin('Enum');
  }

  @override
  void beginExport(analyzer.Token token) {
    listener.beginExport(token);
    _begin('Export');
  }

  @override
  void beginExpressionStatement(analyzer.Token token) {
    listener.beginExpressionStatement(token);
    _begin('ExpressionStatement');
  }

  @override
  void beginFactoryMethod(analyzer.Token token) {
    listener.beginFactoryMethod(token);
    _begin('FactoryMethod');
  }

  @override
  void beginFieldInitializer(analyzer.Token token) {
    listener.beginFieldInitializer(token);
    _begin('FieldInitializer');
  }

  @override
  void beginForInBody(analyzer.Token token) {
    listener.beginForInBody(token);
    _begin('ForInBody');
  }

  @override
  void beginForInExpression(analyzer.Token token) {
    listener.beginForInExpression(token);
    _begin('ForInExpression');
  }

  @override
  void beginForStatement(analyzer.Token token) {
    listener.beginForStatement(token);
    _begin('ForStatement');
  }

  @override
  void beginForStatementBody(analyzer.Token token) {
    listener.beginForStatementBody(token);
    _begin('ForStatementBody');
  }

  @override
  void beginFormalParameter(analyzer.Token token, fasta.MemberKind kind) {
    listener.beginFormalParameter(token, kind);
    _begin('FormalParameter');
  }

  @override
  void beginFormalParameters(analyzer.Token token, fasta.MemberKind kind) {
    listener.beginFormalParameters(token, kind);
    _begin('FormalParameters');
  }

  @override
  void beginLocalFunctionDeclaration(analyzer.Token token) {
    listener.beginLocalFunctionDeclaration(token);
    _begin('LocalFunctionDeclaration');
  }

  @override
  void beginFunctionExpression(analyzer.Token token) {
    listener.beginFunctionExpression(token);
    _begin('FunctionExpression');
  }

  @override
  void beginFunctionName(analyzer.Token token) {
    listener.beginFunctionName(token);
    _begin('FunctionName');
  }

  @override
  void beginFunctionType(analyzer.Token beginToken) {
    listener.beginFunctionType(beginToken);
    _begin('FunctionType');
  }

  @override
  void beginFunctionTypeAlias(analyzer.Token token) {
    listener.beginFunctionTypeAlias(token);
    _begin('FunctionTypeAlias');
  }

  @override
  void beginFunctionTypedFormalParameter(analyzer.Token token) {
    listener.beginFunctionTypedFormalParameter(token);
    _begin('FunctionTypedFormalParameter');
  }

  @override
  void beginHide(analyzer.Token hideKeyword) {
    listener.beginHide(hideKeyword);
    _begin('Hide');
  }

  @override
  void beginIdentifierList(analyzer.Token token) {
    listener.beginIdentifierList(token);
    _begin('IdentifierList');
  }

  @override
  void beginIfStatement(analyzer.Token token) {
    listener.beginIfStatement(token);
    _begin('IfStatement');
  }

  @override
  void beginImport(analyzer.Token importKeyword) {
    listener.beginImport(importKeyword);
    _begin('Import');
  }

  @override
  void beginInitializedIdentifier(analyzer.Token token) {
    listener.beginInitializedIdentifier(token);
    _begin('InitializedIdentifier');
  }

  @override
  void beginInitializer(analyzer.Token token) {
    listener.beginInitializer(token);
    _begin('Initializer');
  }

  @override
  void beginInitializers(analyzer.Token token) {
    listener.beginInitializers(token);
    _begin('Initializers');
  }

  @override
  void beginLabeledStatement(analyzer.Token token, int labelCount) {
    listener.beginLabeledStatement(token, labelCount);
    _begin('LabeledStatement');
  }

  @override
  void beginLibraryName(analyzer.Token token) {
    listener.beginLibraryName(token);
    _begin('LibraryName');
  }

  @override
  void beginLiteralMapEntry(analyzer.Token token) {
    listener.beginLiteralMapEntry(token);
    _begin('LiteralMapEntry');
  }

  @override
  void beginLiteralString(analyzer.Token token) {
    listener.beginLiteralString(token);
    _begin('LiteralString');
  }

  @override
  void beginLiteralSymbol(analyzer.Token token) {
    listener.beginLiteralSymbol(token);
    _begin('LiteralSymbol');
  }

  @override
  void beginMember(analyzer.Token token) {
    listener.beginMember(token);
    _begin('Member');
  }

  @override
  void beginMetadata(analyzer.Token token) {
    listener.beginMetadata(token);
    _begin('Metadata');
  }

  @override
  void beginMetadataStar(analyzer.Token token) {
    listener.beginMetadataStar(token);
    _begin('MetadataStar');
  }

  @override
  void beginMethod(analyzer.Token token, analyzer.Token name) {
    listener.beginMethod(token, name);
    _begin('Method');
  }

  @override
  void beginMixinApplication(analyzer.Token token) {
    listener.beginMixinApplication(token);
    _begin('MixinApplication');
  }

  @override
  void beginNamedFunctionExpression(analyzer.Token token) {
    listener.beginNamedFunctionExpression(token);
    _begin('NamedFunctionExpression');
  }

  @override
  void beginNamedMixinApplication(
      analyzer.Token beginToken, analyzer.Token name) {
    listener.beginNamedMixinApplication(beginToken, name);
    _begin('NamedMixinApplication');
  }

  @override
  void beginNewExpression(analyzer.Token token) {
    listener.beginNewExpression(token);
    _begin('NewExpression');
  }

  @override
  void beginOptionalFormalParameters(analyzer.Token token) {
    listener.beginOptionalFormalParameters(token);
    _begin('OptionalFormalParameters');
  }

  @override
  void beginPart(analyzer.Token token) {
    listener.beginPart(token);
    _begin('Part');
  }

  @override
  void beginPartOf(analyzer.Token token) {
    listener.beginPartOf(token);
    _begin('PartOf');
  }

  @override
  void beginRedirectingFactoryBody(analyzer.Token token) {
    listener.beginRedirectingFactoryBody(token);
    _begin('RedirectingFactoryBody');
  }

  @override
  void beginRethrowStatement(analyzer.Token token) {
    listener.beginRethrowStatement(token);
    _begin('RethrowStatement');
  }

  @override
  void beginReturnStatement(analyzer.Token token) {
    listener.beginReturnStatement(token);
    _begin('ReturnStatement');
  }

  @override
  void beginShow(analyzer.Token showKeyword) {
    listener.beginShow(showKeyword);
    _begin('Show');
  }

  @override
  void beginSwitchBlock(analyzer.Token token) {
    listener.beginSwitchBlock(token);
    _begin('SwitchBlock');
  }

  @override
  void beginSwitchCase(
      int labelCount, int expressionCount, analyzer.Token firstToken) {
    listener.beginSwitchCase(labelCount, expressionCount, firstToken);
    _begin('SwitchCase');
  }

  @override
  void beginSwitchStatement(analyzer.Token token) {
    listener.beginSwitchStatement(token);
    _begin('SwitchStatement');
  }

  @override
  void beginThenStatement(analyzer.Token token) {
    listener.beginThenStatement(token);
    _begin('ThenStatement');
  }

  @override
  void beginTopLevelMember(analyzer.Token token) {
    listener.beginTopLevelMember(token);
    _begin('TopLevelMember');
  }

  @override
  void beginTopLevelMethod(analyzer.Token token, analyzer.Token name) {
    listener.beginTopLevelMethod(token, name);
    _begin('TopLevelMethod');
  }

  @override
  void beginTryStatement(analyzer.Token token) {
    listener.beginTryStatement(token);
    _begin('TryStatement');
  }

  @override
  void beginTypeArguments(analyzer.Token token) {
    listener.beginTypeArguments(token);
    _begin('TypeArguments');
  }

  @override
  void beginTypeList(analyzer.Token token) {
    listener.beginTypeList(token);
    _begin('TypeList');
  }

  @override
  void beginTypeVariable(analyzer.Token token) {
    listener.beginTypeVariable(token);
    _begin('TypeVariable');
  }

  @override
  void beginTypeVariables(analyzer.Token token) {
    listener.beginTypeVariables(token);
    _begin('TypeVariables');
  }

  @override
  void beginVariableInitializer(analyzer.Token token) {
    listener.beginVariableInitializer(token);
    _begin('VariableInitializer');
  }

  @override
  void beginVariablesDeclaration(analyzer.Token token) {
    listener.beginVariablesDeclaration(token);
    _begin('VariablesDeclaration');
  }

  @override
  void beginWhileStatement(analyzer.Token token) {
    listener.beginWhileStatement(token);
    _begin('WhileStatement');
  }

  @override
  void beginWhileStatementBody(analyzer.Token token) {
    listener.beginWhileStatementBody(token);
    _begin('WhileStatementBody');
  }

  @override
  void beginYieldStatement(analyzer.Token token) {
    listener.beginYieldStatement(token);
    _begin('YieldStatement');
  }

  @override
  void discardTypeReplacedWithCommentTypeAssign() {
    listener.discardTypeReplacedWithCommentTypeAssign();
    // TODO(danrubel): implement discardTypeReplacedWithCommentTypeAssign
  }

  @override
  void endArguments(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('Arguments');
    listener.endArguments(count, beginToken, endToken);
  }

  @override
  void endAssert(
      analyzer.Token assertKeyword,
      fasta.Assert kind,
      analyzer.Token leftParenthesis,
      analyzer.Token commaToken,
      analyzer.Token rightParenthesis,
      analyzer.Token semicolonToken) {
    _end('Assert');
    listener.endAssert(assertKeyword, kind, leftParenthesis, commaToken,
        rightParenthesis, semicolonToken);
  }

  @override
  void endAwaitExpression(analyzer.Token beginToken, analyzer.Token endToken) {
    _end('AwaitExpression');
    listener.endAwaitExpression(beginToken, endToken);
  }

  @override
  void endBlock(int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('Block');
    listener.endBlock(count, beginToken, endToken);
  }

  @override
  void endBlockFunctionBody(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('BlockFunctionBody');
    listener.endBlockFunctionBody(count, beginToken, endToken);
  }

  @override
  void endCascade() {
    _end('Cascade');
    listener.endCascade();
  }

  @override
  void endCaseExpression(analyzer.Token colon) {
    _end('CaseExpression');
    listener.endCaseExpression(colon);
  }

  @override
  void endCatchClause(analyzer.Token token) {
    _end('CatchClause');
    listener.endCatchClause(token);
  }

  @override
  void endClassBody(
      int memberCount, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('ClassBody');
    listener.endClassBody(memberCount, beginToken, endToken);
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      analyzer.Token beginToken,
      analyzer.Token classKeyword,
      analyzer.Token extendsKeyword,
      analyzer.Token implementsKeyword,
      analyzer.Token endToken) {
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
  void endCompilationUnit(int count, analyzer.Token token) {
    _end('CompilationUnit');
    listener.endCompilationUnit(count, token);
  }

  @override
  void endConditionalUri(
      analyzer.Token ifKeyword, analyzer.Token equalitySign) {
    _end('ConditionalUri');
    listener.endConditionalUri(ifKeyword, equalitySign);
  }

  @override
  void endConditionalUris(int count) {
    _end('ConditionalUris');
    listener.endConditionalUris(count);
  }

  @override
  void endConstExpression(analyzer.Token token) {
    _end('ConstExpression');
    listener.endConstExpression(token);
  }

  @override
  void endConstLiteral(analyzer.Token token) {
    _end('ConstLiteral');
    listener.endConstLiteral(token);
  }

  @override
  void endConstructorReference(analyzer.Token start,
      analyzer.Token periodBeforeName, analyzer.Token endToken) {
    _end('ConstructorReference');
    listener.endConstructorReference(start, periodBeforeName, endToken);
  }

  @override
  void endDoWhileStatement(analyzer.Token doKeyword,
      analyzer.Token whileKeyword, analyzer.Token endToken) {
    _end('DoWhileStatement');
    listener.endDoWhileStatement(doKeyword, whileKeyword, endToken);
  }

  @override
  void endDoWhileStatementBody(analyzer.Token token) {
    _end('DoWhileStatementBody');
    listener.endDoWhileStatementBody(token);
  }

  @override
  void endDottedName(int count, analyzer.Token firstIdentifier) {
    _end('DottedName');
    listener.endDottedName(count, firstIdentifier);
  }

  @override
  void endElseStatement(analyzer.Token token) {
    _end('ElseStatement');
    listener.endElseStatement(token);
  }

  @override
  void endEnum(analyzer.Token enumKeyword, analyzer.Token endBrace, int count) {
    _end('Enum');
    listener.endEnum(enumKeyword, endBrace, count);
  }

  @override
  void endExport(analyzer.Token exportKeyword, analyzer.Token semicolon) {
    _end('Export');
    listener.endExport(exportKeyword, semicolon);
  }

  @override
  void endExpressionStatement(analyzer.Token token) {
    _end('ExpressionStatement');
    listener.endExpressionStatement(token);
  }

  @override
  void endFactoryMethod(analyzer.Token beginToken,
      analyzer.Token factoryKeyword, analyzer.Token endToken) {
    _end('FactoryMethod');
    listener.endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endFieldInitializer(analyzer.Token assignment, analyzer.Token token) {
    _end('FieldInitializer');
    listener.endFieldInitializer(assignment, token);
  }

  @override
  void endFields(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    // beginMember --> endFields, endMember
    _in('Member');
    listener.endFields(count, beginToken, endToken);
  }

  @override
  void endForIn(
      analyzer.Token awaitToken,
      analyzer.Token forToken,
      analyzer.Token leftParenthesis,
      analyzer.Token inKeyword,
      analyzer.Token rightParenthesis,
      analyzer.Token endToken) {
    _end('ForStatement');
    listener.endForIn(awaitToken, forToken, leftParenthesis, inKeyword,
        rightParenthesis, endToken);
  }

  @override
  void endForInBody(analyzer.Token token) {
    _end('ForInBody');
    listener.endForInBody(token);
  }

  @override
  void endForInExpression(analyzer.Token token) {
    _end('ForInExpression');
    listener.endForInExpression(token);
  }

  @override
  void endForStatement(analyzer.Token forKeyword, analyzer.Token leftSeparator,
      int updateExpressionCount, analyzer.Token endToken) {
    _end('ForStatement');
    listener.endForStatement(
        forKeyword, leftSeparator, updateExpressionCount, endToken);
  }

  @override
  void endForStatementBody(analyzer.Token token) {
    _end('ForStatementBody');
    listener.endForStatementBody(token);
  }

  @override
  void endFormalParameter(analyzer.Token thisKeyword, analyzer.Token nameToken,
      fasta.FormalParameterKind kind, fasta.MemberKind memberKind) {
    _end('FormalParameter');
    listener.endFormalParameter(thisKeyword, nameToken, kind, memberKind);
  }

  @override
  void endFormalParameters(int count, analyzer.Token beginToken,
      analyzer.Token endToken, fasta.MemberKind kind) {
    _end('FormalParameters');
    listener.endFormalParameters(count, beginToken, endToken, kind);
  }

  @override
  void endLocalFunctionDeclaration(analyzer.Token endToken) {
    _end('LocalFunctionDeclaration');
    listener.endLocalFunctionDeclaration(endToken);
  }

  @override
  void endFunctionExpression(analyzer.Token beginToken, analyzer.Token token) {
    _end('FunctionExpression');
    listener.endFunctionExpression(beginToken, token);
  }

  @override
  void endFunctionName(analyzer.Token beginToken, analyzer.Token token) {
    _end('FunctionName');
    listener.endFunctionName(beginToken, token);
  }

  @override
  void endFunctionType(analyzer.Token functionToken, analyzer.Token endToken) {
    _end('FunctionType');
    listener.endFunctionType(functionToken, endToken);
  }

  @override
  void endFunctionTypeAlias(analyzer.Token typedefKeyword,
      analyzer.Token equals, analyzer.Token endToken) {
    _end('FunctionTypeAlias');
    listener.endFunctionTypeAlias(typedefKeyword, equals, endToken);
  }

  @override
  void endFunctionTypedFormalParameter() {
    _end('FunctionTypedFormalParameter');
    listener.endFunctionTypedFormalParameter();
  }

  @override
  void endHide(analyzer.Token hideKeyword) {
    _end('Hide');
    listener.endHide(hideKeyword);
  }

  @override
  void endIdentifierList(int count) {
    _end('IdentifierList');
    listener.endIdentifierList(count);
  }

  @override
  void endIfStatement(analyzer.Token ifToken, analyzer.Token elseToken) {
    _end('IfStatement');
    listener.endIfStatement(ifToken, elseToken);
  }

  @override
  void endImport(analyzer.Token importKeyword, analyzer.Token DeferredKeyword,
      analyzer.Token asKeyword, analyzer.Token semicolon) {
    _end('Import');
    listener.endImport(importKeyword, DeferredKeyword, asKeyword, semicolon);
  }

  @override
  void endInitializedIdentifier(analyzer.Token nameToken) {
    _end('InitializedIdentifier');
    listener.endInitializedIdentifier(nameToken);
  }

  @override
  void endInitializer(analyzer.Token token) {
    _end('Initializer');
    listener.endInitializer(token);
  }

  @override
  void endInitializers(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('Initializers');
    listener.endInitializers(count, beginToken, endToken);
  }

  @override
  void endLabeledStatement(int labelCount) {
    _end('LabeledStatement');
    listener.endLabeledStatement(labelCount);
  }

  @override
  void endLibraryName(analyzer.Token libraryKeyword, analyzer.Token semicolon) {
    _end('LibraryName');
    listener.endLibraryName(libraryKeyword, semicolon);
  }

  @override
  void endLiteralMapEntry(analyzer.Token colon, analyzer.Token endToken) {
    _end('LiteralMapEntry');
    listener.endLiteralMapEntry(colon, endToken);
  }

  @override
  void endLiteralString(int interpolationCount, analyzer.Token endToken) {
    _end('LiteralString');
    listener.endLiteralString(interpolationCount, endToken);
  }

  @override
  void endLiteralSymbol(analyzer.Token hashToken, int identifierCount) {
    _end('LiteralSymbol');
    listener.endLiteralSymbol(hashToken, identifierCount);
  }

  @override
  void endMember() {
    _end('Member');
    listener.endMember();
  }

  @override
  void endMetadata(analyzer.Token beginToken, analyzer.Token periodBeforeName,
      analyzer.Token endToken) {
    _end('Metadata');
    listener.endMetadata(beginToken, periodBeforeName, endToken);
  }

  @override
  void endMetadataStar(int count, bool forParameter) {
    _end('MetadataStar');
    listener.endMetadataStar(count, forParameter);
  }

  @override
  void endMethod(analyzer.Token getOrSet, analyzer.Token beginToken,
      analyzer.Token endToken) {
    _end('Method');
    listener.endMethod(getOrSet, beginToken, endToken);
  }

  @override
  void endMixinApplication(analyzer.Token withKeyword) {
    _end('MixinApplication');
    listener.endMixinApplication(withKeyword);
  }

  @override
  void endNamedFunctionExpression(analyzer.Token endToken) {
    _end('NamedFunctionExpression');
    listener.endNamedFunctionExpression(endToken);
  }

  @override
  void endNamedMixinApplication(
      analyzer.Token begin,
      analyzer.Token classKeyword,
      analyzer.Token equals,
      analyzer.Token implementsKeyword,
      analyzer.Token endToken) {
    _end('NamedMixinApplication');
    _end('ClassOrNamedMixinApplication');
    listener.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, endToken);
  }

  @override
  void endNewExpression(analyzer.Token token) {
    _end('NewExpression');
    listener.endNewExpression(token);
  }

  @override
  void endOptionalFormalParameters(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('OptionalFormalParameters');
    listener.endOptionalFormalParameters(count, beginToken, endToken);
  }

  @override
  void endPart(analyzer.Token partKeyword, analyzer.Token semicolon) {
    _end('Part');
    listener.endPart(partKeyword, semicolon);
  }

  @override
  void endPartOf(
      analyzer.Token partKeyword, analyzer.Token semicolon, bool hasName) {
    _end('PartOf');
    listener.endPartOf(partKeyword, semicolon, hasName);
  }

  @override
  void endRedirectingFactoryBody(
      analyzer.Token beginToken, analyzer.Token endToken) {
    _end('RedirectingFactoryBody');
    listener.endRedirectingFactoryBody(beginToken, endToken);
  }

  @override
  void endRethrowStatement(
      analyzer.Token rethrowToken, analyzer.Token endToken) {
    _end('RethrowStatement');
    listener.endRethrowStatement(rethrowToken, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('ReturnStatement');
    listener.endReturnStatement(hasExpression, beginToken, endToken);
  }

  @override
  void endShow(analyzer.Token showKeyword) {
    _end('Show');
    listener.endShow(showKeyword);
  }

  @override
  void endSwitchBlock(
      int caseCount, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('SwitchBlock');
    listener.endSwitchBlock(caseCount, beginToken, endToken);
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      analyzer.Token defaultKeyword,
      int statementCount,
      analyzer.Token firstToken,
      analyzer.Token endToken) {
    _end('SwitchCase');
    listener.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        statementCount, firstToken, endToken);
  }

  @override
  void endSwitchStatement(
      analyzer.Token switchKeyword, analyzer.Token endToken) {
    _end('SwitchStatement');
    listener.endSwitchStatement(switchKeyword, endToken);
  }

  @override
  void endThenStatement(analyzer.Token token) {
    _end('ThenStatement');
    listener.endThenStatement(token);
  }

  @override
  void endTopLevelDeclaration(analyzer.Token token) {
    // There is no corresponding beginTopLevelDeclaration
    //_expectBegin('TopLevelDeclaration');
    listener.endTopLevelDeclaration(token);
  }

  @override
  void endTopLevelFields(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('TopLevelMember');
    listener.endTopLevelFields(count, beginToken, endToken);
  }

  @override
  void endTopLevelMethod(analyzer.Token beginToken, analyzer.Token getOrSet,
      analyzer.Token endToken) {
    _end('TopLevelMethod');
    _end('TopLevelMember');
    listener.endTopLevelMethod(beginToken, getOrSet, endToken);
  }

  @override
  void endTryStatement(int catchCount, analyzer.Token tryKeyword,
      analyzer.Token finallyKeyword) {
    _end('TryStatement');
    listener.endTryStatement(catchCount, tryKeyword, finallyKeyword);
  }

  @override
  void endTypeArguments(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('TypeArguments');
    listener.endTypeArguments(count, beginToken, endToken);
  }

  @override
  void endTypeList(int count) {
    _end('TypeList');
    listener.endTypeList(count);
  }

  @override
  void endTypeVariable(analyzer.Token token, analyzer.Token extendsOrSuper) {
    _end('TypeVariable');
    listener.endTypeVariable(token, extendsOrSuper);
  }

  @override
  void endTypeVariables(
      int count, analyzer.Token beginToken, analyzer.Token endToken) {
    _end('TypeVariables');
    listener.endTypeVariables(count, beginToken, endToken);
  }

  @override
  void endVariableInitializer(analyzer.Token assignmentOperator) {
    _end('VariableInitializer');
    listener.endVariableInitializer(assignmentOperator);
  }

  @override
  void endVariablesDeclaration(int count, analyzer.Token endToken) {
    _end('VariablesDeclaration');
    listener.endVariablesDeclaration(count, endToken);
  }

  @override
  void endWhileStatement(analyzer.Token whileKeyword, analyzer.Token endToken) {
    _end('WhileStatement');
    listener.endWhileStatement(whileKeyword, endToken);
  }

  @override
  void endWhileStatementBody(analyzer.Token token) {
    _end('WhileStatementBody');
    listener.endWhileStatementBody(token);
  }

  @override
  void endYieldStatement(analyzer.Token yieldToken, analyzer.Token starToken,
      analyzer.Token endToken) {
    _end('YieldStatement');
    listener.endYieldStatement(yieldToken, starToken, endToken);
  }

  @override
  void handleAsOperator(analyzer.Token operator, analyzer.Token endToken) {
    listener.handleAsOperator(operator, endToken);
    // TODO(danrubel): implement handleAsOperator
  }

  @override
  void handleAssignmentExpression(analyzer.Token token) {
    listener.handleAssignmentExpression(token);
    // TODO(danrubel): implement handleAssignmentExpression
  }

  @override
  void handleAsyncModifier(
      analyzer.Token asyncToken, analyzer.Token starToken) {
    listener.handleAsyncModifier(asyncToken, starToken);
    // TODO(danrubel): implement handleAsyncModifier
  }

  @override
  void handleBinaryExpression(analyzer.Token token) {
    listener.handleBinaryExpression(token);
    // TODO(danrubel): implement handleBinaryExpression
  }

  @override
  void handleBreakStatement(
      bool hasTarget, analyzer.Token breakKeyword, analyzer.Token endToken) {
    listener.handleBreakStatement(hasTarget, breakKeyword, endToken);
    // TODO(danrubel): implement handleBreakStatement
  }

  @override
  void handleCaseMatch(analyzer.Token caseKeyword, analyzer.Token colon) {
    listener.handleCaseMatch(caseKeyword, colon);
    // TODO(danrubel): implement handleCaseMatch
  }

  @override
  void handleCatchBlock(analyzer.Token onKeyword, analyzer.Token catchKeyword) {
    listener.handleCatchBlock(onKeyword, catchKeyword);
    // TODO(danrubel): implement handleCatchBlock
  }

  @override
  void handleConditionalExpression(
      analyzer.Token question, analyzer.Token colon) {
    listener.handleConditionalExpression(question, colon);
    // TODO(danrubel): implement handleConditionalExpression
  }

  @override
  void handleContinueStatement(
      bool hasTarget, analyzer.Token continueKeyword, analyzer.Token endToken) {
    listener.handleContinueStatement(hasTarget, continueKeyword, endToken);
    // TODO(danrubel): implement handleContinueStatement
  }

  @override
  void handleEmptyStatement(analyzer.Token token) {
    listener.handleEmptyStatement(token);
    // TODO(danrubel): implement handleEmptyStatement
  }

  @override
  void handleEmptyFunctionBody(analyzer.Token semicolon) {
    listener.handleEmptyFunctionBody(semicolon);
    // TODO(danrubel): implement handleEmptyFunctionBody
  }

  @override
  void handleExpressionFunctionBody(
      analyzer.Token arrowToken, analyzer.Token endToken) {
    listener.handleExpressionFunctionBody(arrowToken, endToken);
    // TODO(danrubel): implement handleExpressionFunctionBody
  }

  @override
  void handleExtraneousExpression(analyzer.Token token, Message message) {
    listener.handleExtraneousExpression(token, message);
    // TODO(danrubel): implement handleExtraneousExpression
  }

  @override
  void handleFinallyBlock(analyzer.Token finallyKeyword) {
    listener.handleFinallyBlock(finallyKeyword);
    // TODO(danrubel): implement handleFinallyBlock
  }

  @override
  void handleFormalParameterWithoutValue(analyzer.Token token) {
    listener.handleFormalParameterWithoutValue(token);
    // TODO(danrubel): implement handleFormalParameterWithoutValue
  }

  @override
  void handleFunctionBodySkipped(analyzer.Token token, bool isExpressionBody) {
    listener.handleFunctionBodySkipped(token, isExpressionBody);
    // TODO(danrubel): implement handleFunctionBodySkipped
  }

  @override
  void handleIdentifier(analyzer.Token token, IdentifierContext context) {
    listener.handleIdentifier(token, context);
    // TODO(danrubel): implement handleIdentifier
  }

  @override
  void handleIndexedExpression(
      analyzer.Token openSquareBracket, analyzer.Token closeSquareBracket) {
    listener.handleIndexedExpression(openSquareBracket, closeSquareBracket);
    // TODO(danrubel): implement handleIndexedExpression
  }

  @override
  void handleInvalidExpression(analyzer.Token token) {
    listener.handleInvalidExpression(token);
    // TODO(danrubel): implement handleInvalidExpression
  }

  @override
  void handleInvalidFunctionBody(analyzer.Token token) {
    listener.handleInvalidFunctionBody(token);
    // TODO(danrubel): implement handleInvalidFunctionBody
  }

  @override
  void handleInvalidTypeReference(analyzer.Token token) {
    listener.handleInvalidTypeReference(token);
    // TODO(danrubel): implement handleInvalidTypeReference
  }

  @override
  void handleIsOperator(
      analyzer.Token operator, analyzer.Token not, analyzer.Token endToken) {
    listener.handleIsOperator(operator, not, endToken);
    // TODO(danrubel): implement handleIsOperator
  }

  @override
  void handleLabel(analyzer.Token token) {
    listener.handleLabel(token);
    // TODO(danrubel): implement handleLabel
  }

  @override
  void handleLiteralBool(analyzer.Token token) {
    listener.handleLiteralBool(token);
    // TODO(danrubel): implement handleLiteralBool
  }

  @override
  void handleLiteralDouble(analyzer.Token token) {
    listener.handleLiteralDouble(token);
    // TODO(danrubel): implement handleLiteralDouble
  }

  @override
  void handleLiteralInt(analyzer.Token token) {
    listener.handleLiteralInt(token);
    // TODO(danrubel): implement handleLiteralInt
  }

  @override
  void handleLiteralList(int count, analyzer.Token beginToken,
      analyzer.Token constKeyword, analyzer.Token endToken) {
    listener.handleLiteralList(count, beginToken, constKeyword, endToken);
    // TODO(danrubel): implement handleLiteralList
  }

  @override
  void handleLiteralMap(int count, analyzer.Token beginToken,
      analyzer.Token constKeyword, analyzer.Token endToken) {
    listener.handleLiteralMap(count, beginToken, constKeyword, endToken);
    // TODO(danrubel): implement handleLiteralMap
  }

  @override
  void handleLiteralNull(analyzer.Token token) {
    listener.handleLiteralNull(token);
    // TODO(danrubel): implement handleLiteralNull
  }

  @override
  Link<analyzer.Token> handleMemberName(Link<analyzer.Token> identifiers) {
    return listener.handleMemberName(identifiers);
    // TODO(danrubel): implement handleMemberName
  }

  @override
  void handleModifier(analyzer.Token token) {
    listener.handleModifier(token);
    // TODO(danrubel): implement handleModifier
  }

  @override
  void handleModifiers(int count) {
    listener.handleModifiers(count);
    // TODO(danrubel): implement handleModifiers
  }

  @override
  void handleNamedArgument(analyzer.Token colon) {
    listener.handleNamedArgument(colon);
    // TODO(danrubel): implement handleNamedArgument
  }

  @override
  void handleNoArguments(analyzer.Token token) {
    listener.handleNoArguments(token);
    // TODO(danrubel): implement handleNoArguments
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(
      analyzer.Token token) {
    listener.handleNoConstructorReferenceContinuationAfterTypeArguments(token);
    // TODO(danrubel): implement handleNoConstructorReferenceContinuationAfterTypeArguments
  }

  @override
  void handleNoExpression(analyzer.Token token) {
    listener.handleNoExpression(token);
    // TODO(danrubel): implement handleNoExpression
  }

  @override
  void handleNoFieldInitializer(analyzer.Token token) {
    listener.handleNoFieldInitializer(token);
    // TODO(danrubel): implement handleNoFieldInitializer
  }

  @override
  void handleNoFormalParameters(analyzer.Token token, fasta.MemberKind kind) {
    listener.handleNoFormalParameters(token, kind);
    // TODO(danrubel): implement handleNoFormalParameters
  }

  @override
  void handleNoFunctionBody(analyzer.Token token) {
    listener.handleNoFunctionBody(token);
    // TODO(danrubel): implement handleNoFunctionBody
  }

  @override
  void handleNoInitializers() {
    listener.handleNoInitializers();
    // TODO(danrubel): implement handleNoInitializers
  }

  @override
  void handleNoName(analyzer.Token token) {
    listener.handleNoName(token);
    // TODO(danrubel): implement handleNoName
  }

  @override
  void handleNoType(analyzer.Token token) {
    listener.handleNoType(token);
    // TODO(danrubel): implement handleNoType
  }

  @override
  void handleNoTypeArguments(analyzer.Token token) {
    listener.handleNoTypeArguments(token);
    // TODO(danrubel): implement handleNoTypeArguments
  }

  @override
  void handleNoTypeVariables(analyzer.Token token) {
    listener.handleNoTypeVariables(token);
    // TODO(danrubel): implement handleNoTypeVariables
  }

  @override
  void handleNoVariableInitializer(analyzer.Token token) {
    listener.handleNoVariableInitializer(token);
    // TODO(danrubel): implement handleNoVariableInitializer
  }

  @override
  void handleOperator(analyzer.Token token) {
    listener.handleOperator(token);
    // TODO(danrubel): implement handleOperator
  }

  @override
  void handleOperatorName(
      analyzer.Token operatorKeyword, analyzer.Token token) {
    listener.handleOperatorName(operatorKeyword, token);
    // TODO(danrubel): implement handleOperatorName
  }

  @override
  void handleParenthesizedExpression(BeginToken token) {
    listener.handleParenthesizedExpression(token);
    // TODO(danrubel): implement handleParenthesizedExpression
  }

  @override
  void handleQualified(analyzer.Token period) {
    listener.handleQualified(period);
    // TODO(danrubel): implement handleQualified
  }

  @override
  void handleRecoverExpression(analyzer.Token token, Message message) {
    listener.handleRecoverExpression(token, message);
    // TODO(danrubel): implement handleRecoverExpression
  }

  @override
  void handleRecoverableError(analyzer.Token token, Message message) {
    listener.handleRecoverableError(token, message);
    // TODO(danrubel): implement handleRecoverableError
  }

  @override
  void handleScript(analyzer.Token token) {
    listener.handleScript(token);
    // TODO(danrubel): implement handleScript
  }

  @override
  void handleSend(analyzer.Token beginToken, analyzer.Token endToken) {
    listener.handleSend(beginToken, endToken);
    // TODO(danrubel): implement handleSend
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    listener.handleStringJuxtaposition(literalCount);
    // TODO(danrubel): implement handleStringJuxtaposition
  }

  @override
  void handleStringPart(analyzer.Token token) {
    listener.handleStringPart(token);
    // TODO(danrubel): implement handleStringPart
  }

  @override
  void handleSuperExpression(analyzer.Token token, IdentifierContext context) {
    listener.handleSuperExpression(token, context);
    // TODO(danrubel): implement handleSuperExpression
  }

  @override
  void handleSymbolVoid(analyzer.Token token) {
    listener.handleSymbolVoid(token);
    // TODO(danrubel): implement handleSymbolVoid
  }

  @override
  void handleThisExpression(analyzer.Token token, IdentifierContext context) {
    listener.handleThisExpression(token, context);
    // TODO(danrubel): implement handleThisExpression
  }

  @override
  void handleThrowExpression(
      analyzer.Token throwToken, analyzer.Token endToken) {
    listener.handleThrowExpression(throwToken, endToken);
    // TODO(danrubel): implement handleThrowExpression
  }

  @override
  void handleType(analyzer.Token beginToken, analyzer.Token endToken) {
    listener.handleType(beginToken, endToken);
    // TODO(danrubel): implement handleType
  }

  @override
  void handleUnaryPostfixAssignmentExpression(analyzer.Token token) {
    listener.handleUnaryPostfixAssignmentExpression(token);
    // TODO(danrubel): implement handleUnaryPostfixAssignmentExpression
  }

  @override
  void handleUnaryPrefixAssignmentExpression(analyzer.Token token) {
    listener.handleUnaryPrefixAssignmentExpression(token);
    // TODO(danrubel): implement handleUnaryPrefixAssignmentExpression
  }

  @override
  void handleUnaryPrefixExpression(analyzer.Token token) {
    listener.handleUnaryPrefixExpression(token);
    // TODO(danrubel): implement handleUnaryPrefixExpression
  }

  @override
  analyzer.Token handleUnrecoverableError(
      analyzer.Token token, Message message) {
    return listener.handleUnrecoverableError(token, message);
    // TODO(danrubel): implement handleUnrecoverableError
  }

  @override
  void handleValuedFormalParameter(
      analyzer.Token equals, analyzer.Token token) {
    listener.handleValuedFormalParameter(equals, token);
    // TODO(danrubel): implement handleValuedFormalParameter
  }

  @override
  void handleVoidKeyword(analyzer.Token token) {
    listener.handleVoidKeyword(token);
    // TODO(danrubel): implement handleVoidKeyword
  }

  @override
  analyzer.Token injectGenericCommentTypeAssign(analyzer.Token token) {
    return listener.injectGenericCommentTypeAssign(token);
    // TODO(danrubel): implement injectGenericCommentTypeAssign
  }

  @override
  analyzer.Token injectGenericCommentTypeList(analyzer.Token token) {
    return listener.injectGenericCommentTypeList(token);
    // TODO(danrubel): implement injectGenericCommentTypeList
  }

  @override
  void logEvent(String name) {
    listener.logEvent(name);
    // TODO(danrubel): implement logEvent
  }

  @override
  analyzer.Token newSyntheticToken(analyzer.Token next) {
    return listener.newSyntheticToken(next);
    // TODO(danrubel): implement newSyntheticToken
  }

  // TODO(danrubel): implement recoverableErrors
  @override
  List<fasta.ParserError> get recoverableErrors => listener.recoverableErrors;

  @override
  analyzer.Token replaceTokenWithGenericCommentTypeAssign(
      analyzer.Token tokenToStartReplacing, analyzer.Token tokenWithComment) {
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
