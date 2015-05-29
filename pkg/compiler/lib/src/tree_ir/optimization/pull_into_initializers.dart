// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir.optimization.pull_into_initializers;

import 'optimization.dart' show Pass;
import '../tree_ir_nodes.dart';

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
class PullIntoInitializers extends ExpressionVisitor<Expression>
                           implements Pass {
  String get passName => 'Pull into initializers';

  Set<Variable> assignedVariables = new Set<Variable>();

  /// The fragment between [first] and [last] holds the statements
  /// we pulled into the initializer block.
  ///
  /// The *initializer block* is a sequence of [ExpressionStatement]s with
  /// [Assign]s that we create in the beginning of the body, with the intent
  /// that code generation will convert them to variable initializers.
  ///
  /// The block is empty when both are `null`.
  Statement first, last;

  /// True if an impure expression has been returned by visitExpression.
  ///
  /// Expressions cannot be pulled into an initializer if this might reorder
  /// impure expressions.
  ///
  /// A visit method may not be called while this flag is set, meaning all
  /// visitor methods must check the flag between visiting subexpressions.
  bool seenImpure;

  /// Appends a statement to the initializer block.
  void append(Statement node) {
    if (first == null) {
      first = last = node;
    } else {
      last.next = node;
      last = node;
    }
  }

  /// Pulls assignment expressions from [node] into the initializer block
  /// by calling [append].
  ///
  /// Returns a transformed expression where the pulled assignments are
  /// replaced by variable uses.
  Expression rewriteExpression(Expression node) {
    seenImpure = false;
    return visitExpression(node);
  }

  void rewrite(FunctionDefinition node) {
    Statement body = node.body;
    assignedVariables.addAll(node.parameters);

    // [body] represents the first statement after the initializer block.
    // Repeatedly pull assignment statements into the initializer block.
    while (body is ExpressionStatement) {
      ExpressionStatement stmt = body;
      stmt.expression = rewriteExpression(stmt.expression);
      if (stmt.expression is VariableUse) {
        // The entire expression was pulled into an initializer.
        // This can happen when the expression was an assignment that was
        // pulled into the initializer block and replaced by a variable use.
        // Discard the statement and try to pull in more initializers from
        // the next statement.
        destroyVariableUse(stmt.expression);
        body = stmt.next;
      } else {
        // The whole expression could not be pulled into an initializer, so we
        // have reached the end of the initializer block.
        break;
      }
    }

    // [If] and [Return] statements terminate the initializer block, but the
    // initial expression they contain may be pulled up into an initializer.
    // It's ok to pull an assignment across a label so look for the first
    // non-labeled statement and try to pull its initial subexpression.
    Statement entryNode = unfoldLabeledStatements(body);
    if (entryNode is If) {
      entryNode.condition = rewriteExpression(entryNode.condition);
    } else if (entryNode is Return) {
      entryNode.value = rewriteExpression(entryNode.value);
    }

    append(body);
    assert(first != null); // Because we just appended the body.

    node.body = first;
  }

  void destroyVariableUse(VariableUse node) {
    --node.variable.readCount;
  }

  Statement unfoldLabeledStatements(Statement node) {
    while (node is LabeledStatement) {
      node = (node as LabeledStatement).body;
    }
    return node;
  }

  Expression visitAssign(Assign node) {
    assert(!seenImpure);
    node.value = visitExpression(node.value);
    if (!assignedVariables.add(node.variable)) {
      // This is not the first assignment to the variable, so it cannot be
      // pulled into an initializer.
      // We have to leave the assignment here, and assignments are impure.
      seenImpure = true;
      return node;
    } else {
      // Pull the assignment into an initializer.
      // We will leave behind a variable use, which is pure, so we can
      // disregard any impure expressions seen in the right-hand side.
      seenImpure = false;
      append(new ExpressionStatement(node, null));
      return new VariableUse(node.variable);
    }
  }

  void rewriteList(List<Expression> list) {
    for (int i = 0; i < list.length; i++) {
      list[i] = visitExpression(list[i]);
      if (seenImpure) return;
    }
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    rewriteList(node.arguments);
    seenImpure = true;
    return node;
  }

  Expression visitInvokeMethod(InvokeMethod node) {
    node.receiver = visitExpression(node.receiver);
    if (seenImpure) return node;
    rewriteList(node.arguments);
    seenImpure = true;
    return node;
  }

  Expression visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    node.receiver = visitExpression(node.receiver);
    if (seenImpure) return node;
    rewriteList(node.arguments);
    seenImpure = true;
    return node;
  }

  Expression visitInvokeConstructor(InvokeConstructor node) {
    rewriteList(node.arguments);
    seenImpure = true;
    return node;
  }

  Expression visitConcatenateStrings(ConcatenateStrings node) {
    rewriteList(node.arguments);
    seenImpure = true;
    return node;
  }

  Expression visitTypeExpression(TypeExpression node) {
    rewriteList(node.arguments);
    return node;
  }

  Expression visitConditional(Conditional node) {
    node.condition = visitExpression(node.condition);
    if (seenImpure) return node;
    node.thenExpression = visitExpression(node.thenExpression);
    if (seenImpure) return node;
    node.elseExpression = visitExpression(node.elseExpression);
    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);
    if (seenImpure) return node;
    node.right = visitExpression(node.right);
    return node;
  }

  Expression visitLiteralList(LiteralList node) {
    rewriteList(node.values);
    if (node.type != null) seenImpure = true; // Type casts can throw.
    return node;
  }

  Expression visitLiteralMap(LiteralMap node) {
    for (LiteralMapEntry entry in node.entries) {
      entry.key = visitExpression(entry.key);
      if (seenImpure) return node;
      entry.value = visitExpression(entry.value);
      if (seenImpure) return node;
    }
    if (node.type != null) seenImpure = true; // Type casts can throw.
    return node;
  }

  Expression visitTypeOperator(TypeOperator node) {
    node.value = visitExpression(node.value);
    if (seenImpure) return node;
    rewriteList(node.typeArguments);
    if (!node.isTypeTest) seenImpure = true; // Type cast can throw.
    return node;
  }

  void visitInnerFunction(FunctionDefinition node) {
    new PullIntoInitializers().rewrite(node);
  }

  Expression visitFunctionExpression(FunctionExpression node) {
    visitInnerFunction(node.definition);
    return node;
  }

  Expression visitGetField(GetField node) {
    node.object = visitExpression(node.object);
    seenImpure = true;
    return node;
  }

  Expression visitSetField(SetField node) {
    node.object = visitExpression(node.object);
    if (seenImpure) return node;
    node.value = visitExpression(node.value);
    seenImpure = true;
    return node;
  }

  Expression visitGetStatic(GetStatic node) {
    seenImpure = true;
    return node;
  }

  Expression visitSetStatic(SetStatic node) {
    node.value = visitExpression(node.value);
    seenImpure = true;
    return node;
  }

  Expression visitCreateBox(CreateBox node) {
    return node;
  }

  Expression visitCreateInstance(CreateInstance node) {
    rewriteList(node.arguments);
    return node;
  }

  Expression visitReifyRuntimeType(ReifyRuntimeType node) {
    node.value = visitExpression(node.value);
    return node;
  }

  Expression visitReadTypeVariable(ReadTypeVariable node) {
    node.target = visitExpression(node.target);
    return node;
  }

  Expression visitConstant(Constant node) {
    return node;
  }

  Expression visitThis(This node) {
    return node;
  }

  Expression visitNot(Not node) {
    node.operand = visitExpression(node.operand);
    return node;
  }

  Expression visitVariableUse(VariableUse node) {
    return node;
  }

  Expression visitCreateInvocationMirror(CreateInvocationMirror node) {
    rewriteList(node.arguments);
    return node;
  }
}
