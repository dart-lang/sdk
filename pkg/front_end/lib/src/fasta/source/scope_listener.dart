// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope_listener;

import 'package:front_end/src/fasta/scanner/token.dart' show
    Token;

import 'package:front_end/src/fasta/parser/error_kind.dart' show
    ErrorKind;

import 'unhandled_listener.dart' show
    NullValue,
    UnhandledListener;

import '../builder/scope.dart' show
    Scope;

export '../builder/scope.dart' show
    Scope;

export 'unhandled_listener.dart' show
    NullValue,
    Unhandled;

enum JumpTargetKind {
  Break,
  Continue,
  Goto, // Continue label in switch.
}

abstract class ScopeListener<J> extends UnhandledListener {
  Scope scope;

  J breakTarget;

  J continueTarget;

  ScopeListener(this.scope);

  J createJumpTarget(JumpTargetKind kind);

  J createBreakTarget() => createJumpTarget(JumpTargetKind.Break);

  J createContinueTarget() => createJumpTarget(JumpTargetKind.Continue);

  J createGotoTarget() => createJumpTarget(JumpTargetKind.Goto);

  void enterLocalScope([Scope newScope]) {
    push(scope);
    scope = newScope ?? scope.createNestedScope();
  }

  @override
  void exitLocalScope() {
    scope = pop();
    assert(scope != null);
  }

  void enterBreakTarget([J target]) {
    push(breakTarget ?? NullValue.BreakTarget);
    breakTarget = target ?? createBreakTarget();
  }

  void enterContinueTarget([J target]) {
    push(continueTarget ?? NullValue.ContinueTarget);
    continueTarget = target ?? createContinueTarget();
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

  void enterLoop() {
    enterBreakTarget();
    enterContinueTarget();
  }

  @override
  void beginFunctionBody(Token begin) {
    debugEvent("beginFunctionBody");
    enterLocalScope();
  }

  @override
  void beginForStatement(Token token) {
    debugEvent("beginForStatement");
    enterLoop();
    enterLocalScope();
  }

  @override
  void beginBlock(Token token) {
    debugEvent("beginBlock");
    enterLocalScope();
  }

  @override
  void beginSwitchBlock(Token token) {
    debugEvent("beginSwitchBlock");
    enterLocalScope();
    enterBreakTarget();
  }

  @override
  void beginDoWhileStatement(Token token) {
    debugEvent("beginDoWhileStatement");
    enterLoop();
  }

  @override
  void beginWhileStatement(Token token) {
    debugEvent("beginWhileStatement");
    enterLoop();
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    debugEvent("beginDoWhileStatementBody");
    enterLocalScope();
  }

  @override
  void endDoWhileStatementBody(Token token) {
    debugEvent("endDoWhileStatementBody");
    var body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginWhileStatementBody(Token token) {
    debugEvent("beginWhileStatementBody");
    enterLocalScope();
  }

  @override
  void endWhileStatementBody(Token token) {
    debugEvent("endWhileStatementBody");
    var body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForStatementBody(Token token) {
    debugEvent("beginForStatementBody");
    enterLocalScope();
  }

  @override
  void endForStatementBody(Token token) {
    debugEvent("endForStatementBody");
    var body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForInBody(Token token) {
    debugEvent("beginForInBody");
    enterLocalScope();
  }

  @override
  void endForInBody(Token token) {
    debugEvent("endForInBody");
    var body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginThenStatement(Token token) {
    debugEvent("beginThenStatement");
    enterLocalScope();
  }

  @override
  void endThenStatement(Token token) {
    debugEvent("endThenStatement");
    var body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginElseStatement(Token token) {
    debugEvent("beginElseStatement");
    enterLocalScope();
  }

  @override
  void endElseStatement(Token token) {
    debugEvent("endElseStatement");
    var body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void reportErrorHelper(Token token, ErrorKind kind, Map arguments) {
    super.reportErrorHelper(token, kind, arguments);
    debugEvent("error: ${recoverableErrors.last}");
  }
}
