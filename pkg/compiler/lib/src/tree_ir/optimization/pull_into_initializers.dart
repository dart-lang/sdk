// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir.optimization.pull_into_initializers;

import 'optimization.dart' show Pass;
import '../tree_ir_nodes.dart';

/// Where a variable has been assigned.
enum AssignArea {
  /// The variable is only assigned in the initializer block.
  Initializer,

  // The variable has at least one assignment outside the initializer block.
  Anywhere,
}

/// Pulls assignment expressions to the top of the function body so they can be
/// translated into declaration-site variable initializaters.
///
/// This reverts the assignment expression propagation performed by
/// [StatementRewriter] in cases where it not beneficial.
///
/// EXAMPLE:
///
///     var x = foo(),
///         y = bar(x);
///
///     ==> [StatementRewriter]
///
///     var x,
///         y = bar(x = foo());
///
///     ==> [PullIntoInitializers] restores the initializer for x
///
///     var x = foo(),
///         y = bar(x);
///
///
/// Sometimes the assignment propagation will trigger another optimization
/// in the [StatementRewriter] which then prevents [PullIntoInitializers] from
/// restoring the initializer. This is acceptable, since most optimizations
/// at that level are better than restoring an initializer.
///
/// EXAMPLE:
///
///     var x = foo(),
///         y = bar();
///     baz(x, y, y);
///
///     ==> [StatementRewriter]
///
///     var y;
///     baz(foo(), y = bar(), y);
///
/// [PullIntoInitializers] cannot pull `y` into an initializer because
/// the impure expressions `foo()` and `bar()` would then be swapped.
///
class PullIntoInitializers extends RecursiveTransformer
                           implements Pass {
  String get passName => 'Pull into initializers';

  /// Denotes where each variable is currently assigned.
  ///
  /// Variables without assignments are absent from the map.
  Map<Variable, AssignArea> assignArea = <Variable, AssignArea>{};

  /// The fragment between [first] and [last] holds the statements
  /// we pulled into the initializer block.
  ///
  /// The "initializer block" is a sequence of [ExpressionStatement]s with
  /// [Assign]s that we create in the beginning of the body, with the intent
  /// that code generation will convert them to variable initializers.
  ///
  /// The block is empty when both are `null`.
  Statement first, last;

  /// The number of impure expressions separating the current program point
  /// from the initializer block.
  ///
  /// A pure expression is an expression that cannot throw, diverge, have side
  /// effects, or depend on mutable state.
  ///
  /// As a special case, variable uses are also considered pure when their only
  /// reaching definition is an assignment in the initializer block.
  int impureCounter = 0;

  /// The number of assignments separating the current program point from the
  /// initializer block. Note that these are also counted as impure expressions.
  ///
  /// Assignments are given special treatment because hoisting an assignment
  /// may change the reaching definitions of a variable use. The analysis may
  /// already have considered such a use to be pure, and we must then ensure
  /// that it remains pure.
  int assignCounter = 0;

  /// The number of branch points separating the current program point from
  /// the initializer block.
  ///
  /// We do not pull expressions out of branches, not even pure ones, but
  /// we sometimes want to traverse branches to check if they are pure.
  int branchCounter = 0;

  /// Appends a statement to the initializer block.
  void append(Statement node) {
    if (first == null) {
      first = last = node;
    } else {
      last.next = node;
      last = node;
    }
  }

  void rewrite(FunctionDefinition node) {
    for (Variable param in node.parameters) {
      assignArea[param] = AssignArea.Initializer;
    }
    Statement body = visitStatement(node.body);
    append(body);
    assert(first != null);
    node.body = first;
  }

  void destroyVariableUse(VariableUse node) {
    --node.variable.readCount;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    node.expression = visitExpression(node.expression);
    if (node.expression is VariableUse) {
      // The entire expression was pulled into an initializer.
      // This can happen when the expression was an assignment that was
      // pulled into the initializer block and replaced by a variable use.
      // Discard the statement and try to pull in more initializers from
      // the next statement.
      destroyVariableUse(node.expression);
      return visitStatement(node.next);
    }
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitIf(If node) {
    node.condition = visitExpression(node.condition);
    // We could traverse the branches and pull out pure expressions, but
    // some pure expressions might be too slow for this to pay off.
    // A CPS transform should decide when things get hoisted out of branches.
    return node;
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    node.body = visitStatement(node.body);
    // The 'next' statement might not always get reached, so do not try to
    // pull expressions up from there.
    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    return node;
  }

  Statement visitFor(For node) {
    return node;
  }

  Statement visitTry(Try node) {
    return node;
  }

  Statement visitNullCheck(NullCheck node) {
    if (node.condition != null) {
      node.condition = visitExpression(node.condition);
      // The value occurs in conditional context, so don't pull from that.
    } else {
      node.value = visitExpression(node.value);
    }
    return node;
  }

  Expression visitAssign(Assign node) {
    bool inImpureContext = impureCounter > 0;
    bool inBranch = branchCounter > 0;

    // Remember the number of impure expression seen yet, so we can tell if
    // there are any impure expressions on the right-hand side.
    int impureBefore = impureCounter;
    int assignmentsBefore = assignCounter;
    node.value = visitExpression(node.value);
    bool rightHandSideIsImpure = (impureCounter > impureBefore);
    bool rightHandSideHasAssign = (assignCounter > assignmentsBefore);

    bool alreadyAssigned = assignArea.containsKey(node.variable);

    // An impure right-hand side cannot be pulled out of impure context.
    // Expressions should not be pulled out of branches.
    // If this is not the first assignment, it cannot be hoisted.
    // If the right-hand side contains an unhoistable assignment, this
    // assignment cannot be hoisted either.
    if (inImpureContext && rightHandSideIsImpure ||
        inBranch ||
        alreadyAssigned ||
        rightHandSideHasAssign) {
      assignArea[node.variable] = AssignArea.Anywhere;
      ++impureCounter;
      ++assignCounter;
      return node;
    }

    // Pull the assignment into the initializer. Any side-effects in the
    // right-hand side will move into the initializer block, so reset the
    // impure counter.
    assignArea[node.variable] = AssignArea.Initializer;
    impureCounter = impureBefore;
    append(new ExpressionStatement(node, null));
    return new VariableUse(node.variable);
  }

  Expression visitVariableUse(VariableUse node) {
    if (assignArea[node.variable] == AssignArea.Anywhere) {
      // There is a reaching definition outside the initializer block.
      ++impureCounter;
    }
    return node;
  }

  void rewriteList(List<Expression> nodes) {
    for (int i = 0; i < nodes.length; ++i) {
      nodes[i] = visitExpression(nodes[i]);
    }
  }

  Expression visitInvokeMethod(InvokeMethod node) {
    node.receiver = visitExpression(node.receiver);
    if (!node.receiverIsNotNull) {
      // If the receiver is null, the method lookup throws.
      ++impureCounter;
    }
    rewriteList(node.arguments);
    ++impureCounter;
    return node;
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    super.visitInvokeStatic(node);
    ++impureCounter;
    return node;
  }

  Expression visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    super.visitInvokeMethodDirectly(node);
    ++impureCounter;
    return node;
  }

  Expression visitInvokeConstructor(InvokeConstructor node) {
    super.visitInvokeConstructor(node);
    ++impureCounter;
    return node;
  }

  Expression visitOneShotInterceptor(OneShotInterceptor node) {
    super.visitOneShotInterceptor(node);
    ++impureCounter;
    return node;
  }

  Expression visitConditional(Conditional node) {
    node.condition = visitExpression(node.condition);
    // Visit the branches to detect impure subexpressions, but do not pull
    // expressions out of the branch.
    ++branchCounter;
    node.thenExpression = visitExpression(node.thenExpression);
    node.elseExpression = visitExpression(node.elseExpression);
    --branchCounter;
    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);
    ++branchCounter;
    node.right = visitExpression(node.right);
    --branchCounter;
    return node;
  }

  Expression visitLiteralList(LiteralList node) {
    super.visitLiteralList(node);
    if (node.type != null) {
      ++impureCounter; // Type casts can throw.
    }
    return node;
  }

  Expression visitLiteralMap(LiteralMap node) {
    super.visitLiteralMap(node);
    if (node.type != null) {
      ++impureCounter; // Type casts can throw.
    }
    return node;
  }

  Expression visitTypeOperator(TypeOperator node) {
    super.visitTypeOperator(node);
    if (!node.isTypeTest) {
      ++impureCounter; // Type casts can throw.
    }
    return node;
  }

  Expression visitGetField(GetField node) {
    super.visitGetField(node);
    ++impureCounter;
    return node;
  }

  Expression visitSetField(SetField node) {
    super.visitSetField(node);
    ++impureCounter;
    return node;
  }

  Expression visitGetStatic(GetStatic node) {
    ++impureCounter;
    return node;
  }

  Expression visitSetStatic(SetStatic node) {
    super.visitSetStatic(node);
    ++impureCounter;
    return node;
  }

  Expression visitGetTypeTestProperty(GetTypeTestProperty node) {
    super.visitGetTypeTestProperty(node);
    return node;
  }

  Expression visitGetLength(GetLength node) {
    super.visitGetLength(node);
    ++impureCounter;
    return node;
  }

  Expression visitGetIndex(GetIndex node) {
    super.visitGetIndex(node);
    ++impureCounter;
    return node;
  }

  Expression visitSetIndex(SetIndex node) {
    super.visitSetIndex(node);
    ++impureCounter;
    return node;
  }

  Expression visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    rewriteList(node.arguments);
    return node;
  }

  Expression visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    node.receiver = visitExpression(node.receiver);
    if (!node.receiverIsNotNull) {
      // If the receiver is null, the method lookup throws.
      ++impureCounter;
    }
    rewriteList(node.arguments);
    ++impureCounter;
    return node;
  }

  @override
  Expression visitForeignExpression(ForeignExpression node) {
    rewriteList(node.arguments);
    if (node.nativeBehavior.sideEffects.hasSideEffects()) {
      ++impureCounter;
    }
    return node;
  }
}
