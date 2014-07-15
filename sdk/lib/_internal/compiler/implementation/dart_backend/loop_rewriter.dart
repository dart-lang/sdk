// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library loop_rewriter;

import 'tree_ir_nodes.dart';

/// Rewrites [WhileTrue] statements with an [If] body into a [WhileCondition],
/// in situations where only one of the branches contains a [Continue] to the
/// loop. Schematically:
///
///   L:
///   while (true) {
///     if (E) {
///       S1  (has references to L)
///     } else {
///       S2  (has no references to L)
///     }
///   }
///     ==>
///   L:
///   while (E) {
///     S1
///   };
///   S2
///
/// A similar transformation is used when S2 occurs in the 'then' position.
///
/// Note that the above pattern needs no iteration since nested ifs
/// have been collapsed previously in the [StatementRewriter] phase.
class LoopRewriter extends RecursiveVisitor {

  Set<Label> usedContinueLabels = new Set<Label>();

  void rewrite(FunctionDefinition function) {
    function.body = visitStatement(function.body);
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    node.body = visitStatement(node.body);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitAssign(Assign node) {
    // Clean up redundant assignments left behind in the previous phase.
    if (node.variable == node.definition) {
      --node.variable.readCount;
      --node.variable.writeCount;
      return visitStatement(node.next);
    }
    visitExpression(node.definition);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitReturn(Return node) {
    visitExpression(node.value);
    return node;
  }

  Statement visitBreak(Break node) {
    return node;
  }

  Statement visitContinue(Continue node) {
    usedContinueLabels.add(node.target);
    return node;
  }

  Statement visitIf(If node) {
    visitExpression(node.condition);
    node.thenStatement = visitStatement(node.thenStatement);
    node.elseStatement = visitStatement(node.elseStatement);
    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    assert(!usedContinueLabels.contains(node.label));
    if (node.body is If) {
      If body = node.body;
      body.thenStatement = visitStatement(body.thenStatement);
      bool thenHasContinue = usedContinueLabels.remove(node.label);
      body.elseStatement = visitStatement(body.elseStatement);
      bool elseHasContinue = usedContinueLabels.remove(node.label);
      if (thenHasContinue && !elseHasContinue) {
        node.label.binding = null; // Prepare to rebind the label.
        return new WhileCondition(
            node.label,
            body.condition,
            body.thenStatement,
            body.elseStatement);
      } else if (!thenHasContinue && elseHasContinue) {
        node.label.binding = null;
        return new WhileCondition(
            node.label,
            new Not(body.condition),
            body.elseStatement,
            body.thenStatement);
      }
    } else {
      node.body = visitStatement(node.body);
      usedContinueLabels.remove(node.label);
    }
    return node;
  }

  Statement visitWhileCondition(WhileCondition node) {
    // Note: not reachable but the implementation is trivial
    visitExpression(node.condition);
    node.body = visitStatement(node.body);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    visitExpression(node.expression);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitFunctionDeclaration(FunctionDeclaration node) {
    new LoopRewriter().rewrite(node.definition);
    node.next = visitStatement(node.next);
    return node;
  }

  void visitFunctionExpression(FunctionExpression node) {
    new LoopRewriter().rewrite(node.definition);
  }
}
