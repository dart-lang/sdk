// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library statement_rewriter;

import 'tree_ir_nodes.dart';

/**
 * Performs the following transformations on the tree:
 * - Assignment propagation
 * - If-to-conditional conversion
 * - Flatten nested ifs
 * - Break inlining
 * - Redirect breaks
 *
 * The above transformations all eliminate statements from the tree, and may
 * introduce redexes of each other.
 *
 *
 * ASSIGNMENT PROPAGATION:
 * Single-use definitions are propagated to their use site when possible.
 * For example:
 *
 *   { v0 = foo(); return v0; }
 *     ==>
 *   return foo()
 *
 * After translating out of CPS, all intermediate values are bound by [Assign].
 * This transformation propagates such definitions to their uses when it is
 * safe and profitable.  Bindings are processed "on demand" when their uses are
 * seen, but are only processed once to keep this transformation linear in
 * the size of the tree.
 *
 * The transformation builds an environment containing [Assign] bindings that
 * are in scope.  These bindings have yet-untranslated definitions.  When a use
 * is encountered the transformation determines if it is safe and profitable
 * to propagate the definition to its use.  If so, it is removed from the
 * environment and the definition is recursively processed (in the
 * new environment at the use site) before being propagated.
 *
 * See [visitVariable] for the implementation of the heuristic for propagating
 * a definition.
 *
 *
 * IF-TO-CONDITIONAL CONVERSION:
 * If-statement are converted to conditional expressions when possible.
 * For example:
 *
 *   if (v0) { v1 = foo(); break L } else { v1 = bar(); break L }
 *     ==>
 *   { v1 = v0 ? foo() : bar(); break L }
 *
 * This can lead to inlining of L, which in turn can lead to further propagation
 * of the variable v1.
 *
 * See [visitIf].
 *
 *
 * FLATTEN NESTED IFS:
 * An if inside an if is converted to an if with a logical operator.
 * For example:
 *
 *   if (E1) { if (E2) {S} else break L } else break L
 *     ==>
 *   if (E1 && E2) {S} else break L
 *
 * This may lead to inlining of L.
 *
 *
 * BREAK INLINING:
 * Single-use labels are inlined at [Break] statements.
 * For example:
 *
 *   L0: { v0 = foo(); break L0 }; return v0;
 *     ==>
 *   v0 = foo(); return v0;
 *
 * This can lead to propagation of v0.
 *
 * See [visitBreak] and [visitLabeledStatement].
 *
 *
 * REDIRECT BREAKS:
 * Labeled statements whose next is a break become flattened and all breaks
 * to their label are redirected.
 * For example, where 'jump' is either break or continue:
 *
 *   L0: {... break L0 ...}; jump L1
 *     ==>
 *   {... jump L1 ...}
 *
 * This may trigger a flattening of nested ifs in case the eliminated label
 * separated two ifs.
 */
class StatementRewriter extends Visitor<Statement, Expression> {
  // The binding environment.  The rightmost element of the list is the nearest
  // available enclosing binding.
  List<Assign> environment;

  /// Substitution map for labels. Any break to a label L should be substituted
  /// for a break to L' if L maps to L'.
  Map<Label, Jump> labelRedirects = <Label, Jump>{};

  /// Returns the redirect target of [label] or [label] itself if it should not
  /// be redirected.
  Jump redirect(Jump jump) {
    Jump newJump = labelRedirects[jump.target];
    return newJump != null ? newJump : jump;
  }

  void rewrite(FunctionDefinition definition) {
    environment = <Assign>[];
    definition.body = visitStatement(definition.body);

    // TODO(kmillikin):  Allow definitions that are not propagated.  Here,
    // this means rebuilding the binding with a recursively unnamed definition,
    // or else introducing a variable definition and an assignment.
    assert(environment.isEmpty);
  }

  Expression visitExpression(Expression e) => e.processed ? e : e.accept(this);

  Expression visitVariable(Variable node) {
    // Propagate a variable's definition to its use site if:
    // 1.  It has a single use, to avoid code growth and potential duplication
    //     of side effects, AND
    // 2.  It was the most recent expression evaluated so that we do not
    //     reorder expressions with side effects.
    if (!environment.isEmpty &&
        environment.last.variable == node &&
        environment.last.hasExactlyOneUse) {
      return visitExpression(environment.removeLast().definition);
    }
    // If the definition could not be propagated, leave the variable use.
    return node;
  }


  Statement visitAssign(Assign node) {
    environment.add(node);
    Statement next = visitStatement(node.next);

    if (!environment.isEmpty && environment.last == node) {
      // The definition could not be propagated.  Residualize the let binding.
      node.next = next;
      environment.removeLast();
      node.definition = visitExpression(node.definition);
      return node;
    }
    assert(!environment.contains(node));
    return next;
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    // Process arguments right-to-left, the opposite of evaluation order.
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    return node;
  }

  Expression visitInvokeMethod(InvokeMethod node) {
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    node.receiver = visitExpression(node.receiver);
    return node;
  }

  Expression visitInvokeSuperMethod(InvokeSuperMethod node) {
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    return node;
  }

  Expression visitInvokeConstructor(InvokeConstructor node) {
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    return node;
  }

  Expression visitConcatenateStrings(ConcatenateStrings node) {
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    return node;
  }

  Expression visitConditional(Conditional node) {
    node.condition = visitExpression(node.condition);

    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.thenExpression = visitExpression(node.thenExpression);
    assert(environment.isEmpty);
    node.elseExpression = visitExpression(node.elseExpression);
    assert(environment.isEmpty);
    environment = savedEnvironment;

    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);

    environment.add(null); // impure expressions may not propagate across branch
    node.right = visitExpression(node.right);
    environment.removeLast();

    return node;
  }

  Expression visitNot(Not node) {
    node.operand = visitExpression(node.operand);
    return node;
  }

  Expression visitFunctionExpression(FunctionExpression node) {
    new StatementRewriter().rewrite(node.definition);
    return node;
  }

  Statement visitFunctionDeclaration(FunctionDeclaration node) {
    new StatementRewriter().rewrite(node.definition);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }


  Statement visitBreak(Break node) {
    // Redirect through chain of breaks.
    // Note that useCount was accounted for at visitLabeledStatement.
    // Note redirect may return either a Break or Continue statement.
    Jump jump = redirect(node);
    if (jump is Break && jump.target.useCount == 1) {
      --jump.target.useCount;
      return visitStatement(jump.target.binding.next);
    }
    return jump;
  }

  Statement visitContinue(Continue node) {
    return node;
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    if (node.next is Jump) {
      // Eliminate label if next is a break or continue statement
      // Breaks to this label are redirected to the outer label.
      // Note that breakCount for the two labels is updated proactively here
      // so breaks can reliably tell if they should inline their target.
      Jump next = node.next;
      Jump newJump = redirect(next);
      labelRedirects[node.label] = newJump;
      newJump.target.useCount += node.label.useCount - 1;
      node.label.useCount = 0;
      Statement result = visitStatement(node.body);
      labelRedirects.remove(node.label); // Save some space.
      return result;
    }

    node.body = visitStatement(node.body);

    if (node.label.useCount == 0) {
      // Eliminate the label if next was inlined at a break
      return node.body;
    }

    // Do not propagate assignments into the successor statements, since they
    // may be overwritten by assignments in the body.
    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.next = visitStatement(node.next);
    environment = savedEnvironment;

    return node;
  }

  Statement visitIf(If node) {
    node.condition = visitExpression(node.condition);

    // Do not propagate assignments into branches.  Doing so will lead to code
    // duplication.
    // TODO(kmillikin): Rethink this.  Propagating some assignments (e.g.,
    // constants or variables) is benign.  If they can occur here, they should
    // be handled well.
    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.thenStatement = visitStatement(node.thenStatement);
    assert(environment.isEmpty);
    node.elseStatement = visitStatement(node.elseStatement);
    assert(environment.isEmpty);
    environment = savedEnvironment;

    tryCollapseIf(node);

    Statement reduced = combineStatementsWithSubexpressions(
        node.thenStatement,
        node.elseStatement,
        (t,f) => new Conditional(node.condition, t, f)..processed = true);
    if (reduced != null) {
      if (reduced.next is Break) {
        // In case the break can now be inlined.
        reduced = visitStatement(reduced);
      }
      return reduced;
    }

    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    // Do not propagate assignments into loops.  Doing so is not safe for
    // variables modified in the loop (the initial value will be propagated).
    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.body = visitStatement(node.body);
    assert(environment.isEmpty);
    environment = savedEnvironment;
    return node;
  }

  Statement visitWhileCondition(WhileCondition node) {
    // Not introduced yet
    throw "Unexpected WhileCondition in StatementRewriter";
  }

  Expression visitConstant(Constant node) {
    return node;
  }

  Expression visitThis(This node) {
    return node;
  }

  Expression visitReifyTypeVar(ReifyTypeVar node) {
    return node;
  }

  Expression visitLiteralList(LiteralList node) {
    // Process values right-to-left, the opposite of evaluation order.
    for (int i = node.values.length - 1; i >= 0; --i) {
      node.values[i] = visitExpression(node.values[i]);
    }
    return node;
  }

  Expression visitLiteralMap(LiteralMap node) {
    // Process arguments right-to-left, the opposite of evaluation order.
    for (int i = node.values.length - 1; i >= 0; --i) {
      node.values[i] = visitExpression(node.values[i]);
      node.keys[i] = visitExpression(node.keys[i]);
    }
    return node;
  }

  Expression visitTypeOperator(TypeOperator node) {
    node.receiver = visitExpression(node.receiver);
    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    node.expression = visitExpression(node.expression);
    // Do not allow propagation of assignments past an expression evaluated
    // for its side effects because it risks reordering side effects.
    // TODO(kmillikin): Rethink this.  Some propagation is benign, e.g.,
    // constants, variables, or other pure values that are not destroyed by
    // the expression statement.  If they can occur here they should be
    // handled well.
    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.next = visitStatement(node.next);
    assert(environment.isEmpty);
    environment = savedEnvironment;
    return node;
  }

  /// If [s] and [t] are similar statements we extract their subexpressions
  /// and returns a new statement of the same type using expressions combined
  /// with the [combine] callback. For example:
  ///
  ///   combineStatements(Return E1, Return E2) = Return combine(E1, E2)
  ///
  /// If [combine] returns E1 then the unified statement is equivalent to [s],
  /// and if [combine] returns E2 the unified statement is equivalence to [t].
  ///
  /// It is guaranteed that no side effects occur between the beginning of the
  /// statement and the position of the combined expression.
  ///
  /// Returns null if the statements are too different.
  ///
  /// If non-null is returned, the caller MUST discard [s] and [t] and use
  /// the returned statement instead.
  static Statement combineStatementsWithSubexpressions(
      Statement s,
      Statement t,
      Expression combine(Expression s, Expression t)) {
    if (s is Return && t is Return) {
      return new Return(combine(s.value, t.value));
    }
    if (s is Assign && t is Assign && s.variable == t.variable) {
      Statement next = combineStatements(s.next, t.next);
      if (next != null) {
        --t.variable.writeCount; // Two assignments become one.
        return new Assign(s.variable,
                          combine(s.definition, t.definition),
                          next);
      }
    }
    if (s is ExpressionStatement && t is ExpressionStatement) {
      Statement next = combineStatements(s.next, t.next);
      if (next != null) {
        return new ExpressionStatement(combine(s.expression, t.expression),
                                       next);
      }
    }
    return null;
  }

  /// Returns a statement equivalent to both [s] and [t], or null if [s] and
  /// [t] are incompatible.
  /// If non-null is returned, the caller MUST discard [s] and [t] and use
  /// the returned statement instead.
  /// If two breaks are combined, the label's break counter will be decremented.
  static Statement combineStatements(Statement s, Statement t) {
    if (s is Break && t is Break && s.target == t.target) {
      --t.target.useCount; // Two breaks become one.
      return s;
    }
    if (s is Continue && t is Continue && s.target == t.target) {
      --t.target.useCount; // Two continues become one.
      return s;
    }
    if (s is Return && t is Return) {
      Expression e = combineExpressions(s.value, t.value);
      if (e != null) {
        return new Return(e);
      }
    }
    return null;
  }

  /// Returns an expression equivalent to both [e1] and [e2].
  /// If non-null is returned, the caller must discard [e1] and [e2] and use
  /// the resulting expression in the tree.
  static Expression combineExpressions(Expression e1, Expression e2) {
    if (e1 is Variable && e1 == e2) {
      --e1.readCount; // Two references become one.
      return e1;
    }
    if (e1 is Constant && e2 is Constant && e1.value == e2.value) {
      return e1;
    }
    return null;
  }

  /// Try to collapse nested ifs using && and || expressions.
  /// For example:
  ///
  ///   if (E1) { if (E2) S else break L } else break L
  ///     ==>
  ///   if (E1 && E2) S else break L
  ///
  /// [branch1] and [branch2] control the position of the S statement.
  ///
  /// Returns true if another collapse redex might have been introduced.
  void tryCollapseIf(If node) {
    // Repeatedly try to collapse nested ifs.
    // The transformation is shrinking (destroys an if) so it remains linear.
    // Here is an example where more than one iteration is required:
    //
    //   if (E1)
    //     if (E2) break L2 else break L1
    //   else
    //     break L1
    //
    // L1.target ::=
    //   if (E3) S else break L2
    //
    // After first collapse:
    //
    //   if (E1 && E2)
    //     break L2
    //   else
    //     {if (E3) S else break L2}  (inlined from break L1)
    //
    // We can then do another collapse using the inlined nested if.
    bool changed = true;
    while (changed) {
      changed = false;
      if (tryCollapseIfAux(node, true, true)) {
        changed = true;
      }
      if (tryCollapseIfAux(node, true, false)) {
        changed = true;
      }
      if (tryCollapseIfAux(node, false, true)) {
        changed = true;
      }
      if (tryCollapseIfAux(node, false, false)) {
        changed = true;
      }
    }
  }

  bool tryCollapseIfAux(If outerIf, bool branch1, bool branch2) {
    // NOTE: We name variables here as if S is in the then-then position.
    Statement outerThen = getBranch(outerIf, branch1);
    Statement outerElse = getBranch(outerIf, !branch1);
    if (outerThen is If && outerElse is Break) {
      If innerIf = outerThen;
      Statement innerThen = getBranch(innerIf, branch2);
      Statement innerElse = getBranch(innerIf, !branch2);
      if (innerElse is Break && innerElse.target == outerElse.target) {
        // We always put S in the then branch of the result, and adjust the
        // condition expression if S was actually found in the else branch(es).
        outerIf.condition = new LogicalOperator.and(
            makeCondition(outerIf.condition, branch1),
            makeCondition(innerIf.condition, branch2));
        outerIf.thenStatement = innerThen;
        --innerElse.target.useCount;

        // Try to inline the remaining break.  Do not propagate assignments.
        List<Assign> savedEnvironment = environment;
        environment = <Assign>[];
        outerIf.elseStatement = visitStatement(outerElse);
        assert(environment.isEmpty);
        environment = savedEnvironment;

        return outerIf.elseStatement is If && innerThen is Break;
      }
    }
    return false;
  }

  Expression makeCondition(Expression e, bool polarity) {
    return polarity ? e : new Not(e);
  }

  Statement getBranch(If node, bool polarity) {
    return polarity ? node.thenStatement : node.elseStatement;
  }
}
