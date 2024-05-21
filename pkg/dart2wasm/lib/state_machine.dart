// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Placement of a control flow graph target within a statement. This
/// distinction is necessary since some statements need to have two targets
/// associated with them.
///
/// The meanings of the variants are:
///
///  - [Inner]: Loop entry of a [DoStatement], condition of a [ForStatement] or
///             [WhileStatement], the `else` branch of an [IfStatement], or the
///             initial entry target for a function body.
///
///  - [After]: After a statement, the resumption point of a suspension point
///             ([YieldStatement] or [AwaitExpression]), or the final state
///             (iterator done) of a function body.
enum StateTargetPlacement { Inner, After }

/// Representation of target in the `sync*` control flow graph.
class StateTarget {
  final int index;
  final TreeNode node;
  final StateTargetPlacement placement;

  StateTarget(this.index, this.node, this.placement);

  @override
  String toString() {
    String place = placement == StateTargetPlacement.Inner ? "in" : "after";
    return "$index: $place $node";
  }
}

/// Identify which statements contain `await` or `yield` statements, and assign
/// target indices to all control flow targets of these.
///
/// Target indices are assigned in program order.
class YieldFinder extends RecursiveVisitor {
  final List<StateTarget> targets = [];
  final bool enableAsserts;

  // The number of `await` statements seen so far.
  int yieldCount = 0;

  YieldFinder(this.enableAsserts);

  List<StateTarget> find(FunctionNode function) {
    // Initial state
    addTarget(function.body!, StateTargetPlacement.Inner);
    assert(function.body is Block || function.body is ReturnStatement);
    recurse(function.body!);
    // Final state
    addTarget(function.body!, StateTargetPlacement.After);
    return targets;
  }

  /// Recurse into a statement and then remove any targets added by the
  /// statement if it doesn't contain any `await` statements.
  void recurse(Statement statement) {
    final yieldCountIn = yieldCount;
    final targetsIn = targets.length;
    statement.accept(this);
    if (yieldCount == yieldCountIn) {
      targets.length = targetsIn;
    }
  }

  void addTarget(TreeNode node, StateTargetPlacement placement) {
    targets.add(StateTarget(targets.length, node, placement));
  }

  @override
  void visitBlock(Block node) {
    for (Statement statement in node.statements) {
      recurse(statement);
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitIfStatement(IfStatement node) {
    recurse(node.then);
    if (node.otherwise != null) {
      addTarget(node, StateTargetPlacement.Inner);
      recurse(node.otherwise!);
    }
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    recurse(node.body);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (SwitchCase c in node.cases) {
      addTarget(c, StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitTryFinally(TryFinally node) {
    // [TryFinally] blocks are always compiled to as CFG, even when they don't
    // have awaits. This is to keep the code size small: with normal
    // compilation finalizer blocks need to be duplicated based on
    // continuations, which we don't need in the CFG implementation.
    yieldCount++;
    recurse(node.body);
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.finalizer);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitTryCatch(TryCatch node) {
    // Also always compile [TryCatch] blocks to the CFG to be able to set
    // finalizer continuations.
    yieldCount++;
    recurse(node.body);
    for (Catch c in node.catches) {
      addTarget(c, StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    yieldCount++;
    addTarget(node, StateTargetPlacement.After);
  }

  // Handle awaits. After the await transformation await can only appear in a
  // RHS of a top-level assignment, or as a top-level statement.
  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;

    // Handle awaits in RHS of assignments.
    if (expression is VariableSet) {
      final value = expression.value;
      if (value is AwaitExpression) {
        yieldCount++;
        addTarget(value, StateTargetPlacement.After);
        return;
      }
    }

    // Handle top-level awaits.
    if (expression is AwaitExpression) {
      yieldCount++;
      addTarget(node, StateTargetPlacement.After);
      return;
    }

    super.visitExpressionStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  // Any other await expression means the await transformer is buggy and didn't
  // transform the expression as expected.
  @override
  void visitAwaitExpression(AwaitExpression node) {
    // Await expressions should've been converted to `VariableSet` statements
    // by `_AwaitTransformer`.
    throw 'Unexpected await expression: $node (${node.location})';
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (enableAsserts) {
      super.visitAssertStatement(node);
    }
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    if (enableAsserts) {
      super.visitAssertBlock(node);
    }
  }
}
