// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show
        AssertStatement,
        Block,
        BreakStatement,
        Catch,
        ContinueSwitchStatement,
        DoStatement,
        EmptyStatement,
        ExpressionStatement,
        ForInStatement,
        ForStatement,
        FunctionDeclaration,
        IfStatement,
        InvalidStatement,
        LabeledStatement,
        ReturnStatement,
        Statement,
        StatementVisitor,
        SwitchStatement,
        Throw,
        TryCatch,
        TryFinally,
        VariableDeclaration,
        WhileStatement,
        YieldStatement;

/// Returns true if [node] would let execution reach the next node (aka
/// fall-through in switch cases).
bool fallsThrough(Statement node) => node.accept(const FallThroughVisitor());

/// Visitor implementing [computeFallThrough].
class FallThroughVisitor implements StatementVisitor<bool> {
  const FallThroughVisitor();

  bool defaultStatement(Statement node) => throw "Not implemented.";

  bool visitInvalidStatement(InvalidStatement node) => false;

  bool visitExpressionStatement(ExpressionStatement node) {
    return node.expression is! Throw;
  }

  bool visitBlock(Block node) {
    for (Statement statement in node.statements) {
      if (!statement.accept(this)) return false;
    }
    return true;
  }

  bool visitEmptyStatement(EmptyStatement node) => true;

  bool visitAssertStatement(AssertStatement node) => true;

  bool visitLabeledStatement(LabeledStatement node) => true;

  bool visitBreakStatement(BreakStatement node) => false;

  bool visitWhileStatement(WhileStatement node) => true;

  bool visitDoStatement(DoStatement node) => node.body.accept(this);

  bool visitForStatement(ForStatement node) => true;

  bool visitForInStatement(ForInStatement node) => true;

  bool visitSwitchStatement(SwitchStatement node) => true;

  bool visitContinueSwitchStatement(ContinueSwitchStatement node) => false;

  bool visitIfStatement(IfStatement node) {
    if (node.then == null || node.otherwise == null) return true;
    return node.then.accept(this) || node.otherwise.accept(this);
  }

  bool visitReturnStatement(ReturnStatement node) => false;

  bool visitTryCatch(TryCatch node) {
    if (node.body.accept(this)) return true;
    for (Catch catchNode in node.catches) {
      if (catchNode.body.accept(this)) return true;
    }
    return false;
  }

  bool visitTryFinally(TryFinally node) {
    return node.body.accept(this) && node.finalizer.accept(this);
  }

  bool visitYieldStatement(YieldStatement node) => true;

  bool visitVariableDeclaration(VariableDeclaration node) => true;

  bool visitFunctionDeclaration(FunctionDeclaration node) => true;
}
