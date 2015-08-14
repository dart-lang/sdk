// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir.optimization.loop_rewriter;

import 'optimization.dart' show Pass;
import '../tree_ir_nodes.dart';

/// Rewrites [WhileTrue] statements.
///
/// Before this phase, loops usually contain a lot of "exit code", that is,
/// code that happens at a point where a [Continue] can no longer be reached,
/// and is therefore not really part of the loop.
/// Exit code is moved down after the loop using the following rewrites rules:
///
/// EXTRACT LABELED STATEMENT:
///
///   L:
///   while (true) {
///     L2: {
///       S1  (has references to L)
///     }
///     S2    (has no references to L)
///   }
///
///     ==>
///
///   L2: {
///     L: while (true) S1
///   }
///   S2
///
/// INTRODUCE CONDITIONAL LOOP:
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
/// Note that the last pattern above needs no iteration since nested ifs
/// have been collapsed previously in the [StatementRewriter] phase.
///
/// [WhileCondition] statements exist only after this phase.
class LoopRewriter extends RecursiveTransformer
                   implements Pass {
  String get passName => 'Loop rewriter';

  Set<Label> usedContinueLabels = new Set<Label>();

  void rewrite(FunctionDefinition root) {
    root.body = visitStatement(root.body);
  }

  @override
  void visitInnerFunction(FunctionDefinition node) {
    node.body = new LoopRewriter().visitStatement(node.body);
  }

  Statement visitContinue(Continue node) {
    usedContinueLabels.add(node.target);
    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    assert(!usedContinueLabels.contains(node.label));

    // Pull labeled statements outside the loop when possible.
    // [head] and [tail] are the first and last labeled statements that were
    // pulled out, and null when none have been pulled out.
    LabeledStatement head, tail;
    while (node.body is LabeledStatement) {
      LabeledStatement inner = node.body;
      inner.next = visitStatement(inner.next);
      bool nextHasContinue = usedContinueLabels.remove(node.label);
      if (nextHasContinue) break;
      node.body = inner.body;
      inner.body = node;
      if (head == null) {
        head = tail = inner;
      } else {
        tail.body = inner;
        tail = inner;
      }
    }

    // Rewrite while(true) to while(condition).
    Statement loop = node;
    if (node.body is If) {
      If body = node.body;
      body.thenStatement = visitStatement(body.thenStatement);
      bool thenHasContinue = usedContinueLabels.remove(node.label);
      body.elseStatement = visitStatement(body.elseStatement);
      bool elseHasContinue = usedContinueLabels.remove(node.label);
      if (thenHasContinue && !elseHasContinue) {
        node.label.binding = null; // Prepare to rebind the label.
        loop = new WhileCondition(
            node.label,
            body.condition,
            body.thenStatement,
            body.elseStatement);
      } else if (!thenHasContinue && elseHasContinue) {
        node.label.binding = null;
        loop = new WhileCondition(
            node.label,
            new Not(body.condition),
            body.elseStatement,
            body.thenStatement);
      }
    } else if (node.body is LabeledStatement) {
      // If the body is a labeled statement, its .next has already been visited.
      LabeledStatement body = node.body;
      body.body = visitStatement(body.body);
      usedContinueLabels.remove(node.label);
    } else {
      node.body = visitStatement(node.body);
      usedContinueLabels.remove(node.label);
    }

    if (head == null) return loop;
    tail.body = loop;
    return head;
  }
}
