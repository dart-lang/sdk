// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope_listener;

import 'package:_fe_analyzer_shared/src/parser/block_kind.dart' show BlockKind;

import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show NullValue;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import '../scope.dart' show Scope;
import 'stack_listener_impl.dart';

export 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show FixedNullableList, GrowableList, NullValue, ParserRecovery;

enum JumpTargetKind {
  Break,
  Continue,
  Goto, // Continue label in switch.
}

abstract class ScopeListener<J> extends StackListenerImpl {
  Scope scope;

  J breakTarget;

  J continueTarget;

  ScopeListener(Scope scope) : scope = scope ?? new Scope.immutable();

  J createJumpTarget(JumpTargetKind kind, int charOffset);

  J createBreakTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Break, charOffset);
  }

  J createContinueTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Continue, charOffset);
  }

  J createGotoTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Goto, charOffset);
  }

  void enterLocalScope(String debugName, [Scope newScope]) {
    push(scope);
    scope = newScope ?? scope.createNestedScope(debugName);
  }

  @override
  void exitLocalScope() {
    scope = pop();
    assert(scope != null);
  }

  void enterBreakTarget(int charOffset, [J target]) {
    push(breakTarget ?? NullValue.BreakTarget);
    breakTarget = target ?? createBreakTarget(charOffset);
  }

  void enterContinueTarget(int charOffset, [J target]) {
    push(continueTarget ?? NullValue.ContinueTarget);
    continueTarget = target ?? createContinueTarget(charOffset);
  }

  J exitBreakTarget() {
    J current = breakTarget;
    breakTarget = pop();
    return current;
  }

  J exitContinueTarget() {
    J current = continueTarget;
    continueTarget = pop();
    return current;
  }

  void enterLoop(int charOffset) {
    enterBreakTarget(charOffset);
    enterContinueTarget(charOffset);
  }

  @override
  void beginBlockFunctionBody(Token begin) {
    debugEvent("beginBlockFunctionBody");
    enterLocalScope("block function body");
  }

  @override
  void beginForStatement(Token token) {
    debugEvent("beginForStatement");
    enterLoop(token.charOffset);
    enterLocalScope("for statement");
  }

  @override
  void beginForControlFlow(Token awaitToken, Token forToken) {
    debugEvent("beginForControlFlow");
    enterLocalScope("for in a collection");
  }

  @override
  void beginBlock(Token token, BlockKind blockKind) {
    debugEvent("beginBlock");
    enterLocalScope("block");
  }

  @override
  void beginSwitchBlock(Token token) {
    debugEvent("beginSwitchBlock");
    enterLocalScope("switch block");
    enterBreakTarget(token.charOffset);
  }

  @override
  void beginDoWhileStatement(Token token) {
    debugEvent("beginDoWhileStatement");
    enterLoop(token.charOffset);
  }

  @override
  void beginWhileStatement(Token token) {
    debugEvent("beginWhileStatement");
    enterLoop(token.charOffset);
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    debugEvent("beginDoWhileStatementBody");
    enterLocalScope("do-while statement body");
  }

  @override
  void endDoWhileStatementBody(Token token) {
    debugEvent("endDoWhileStatementBody");
    Object body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginWhileStatementBody(Token token) {
    debugEvent("beginWhileStatementBody");
    enterLocalScope("while statement body");
  }

  @override
  void endWhileStatementBody(Token token) {
    debugEvent("endWhileStatementBody");
    Object body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForStatementBody(Token token) {
    debugEvent("beginForStatementBody");
    enterLocalScope("for statement body");
  }

  @override
  void endForStatementBody(Token token) {
    debugEvent("endForStatementBody");
    Object body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForInBody(Token token) {
    debugEvent("beginForInBody");
    enterLocalScope("for-in body");
  }

  @override
  void endForInBody(Token token) {
    debugEvent("endForInBody");
    Object body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginThenStatement(Token token) {
    debugEvent("beginThenStatement");
    enterLocalScope("then");
  }

  @override
  void endThenStatement(Token token) {
    debugEvent("endThenStatement");
    Object body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginElseStatement(Token token) {
    debugEvent("beginElseStatement");
    enterLocalScope("else");
  }

  @override
  void endElseStatement(Token token) {
    debugEvent("endElseStatement");
    Object body = pop();
    exitLocalScope();
    push(body);
  }
}
