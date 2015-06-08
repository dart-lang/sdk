// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir.optimization.statement_rewriter;

import 'optimization.dart' show Pass;
import '../tree_ir_nodes.dart';

/**
 * Performs the following transformations on the tree:
 * - Assignment inlining
 * - Assignment expression propagation
 * - If-to-conditional conversion
 * - Flatten nested ifs
 * - Break inlining
 * - Redirect breaks
 *
 * The above transformations all eliminate statements from the tree, and may
 * introduce redexes of each other.
 *
 *
 * ASSIGNMENT INLINING:
 * Single-use definitions are inlined at their use site when possible.
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
 * See [visitVariableUse] for the implementation of the heuristic for
 * propagating a definition.
 *
 *
 * ASSIGNMENT EXPRESSION PROPAGATION:
 * Definitions with multiple uses are propagated to their first use site
 * when possible. For example:
 *
 *     { v0 = foo(); bar(v0); return v0; }
 *       ==>
 *     { bar(v0 = foo()); return v0; }
 *
 * Note that the [RestoreInitializers] phase will later undo this rewrite
 * in cases where it prevents an assignment from being pulled into an
 * initializer.
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
class StatementRewriter extends Transformer implements Pass {
  String get passName => 'Statement rewriter';

  @override
  void rewrite(FunctionDefinition node) {
    node.body = visitStatement(node.body);
  }

  /// True if targeting Dart.
  final bool isDartMode;

  /// The most recently evaluated impure expressions, with the most recent
  /// expression being last.
  ///
  /// Most importantly, this contains [Assign] expressions that we attempt to
  /// inline at their use site. It also contains other impure expressions that
  /// we can propagate to a variable use if they are known to return the value
  /// of that variable.
  ///
  /// Except for [Conditional]s, expressions in the environment have
  /// not been processed, and all their subexpressions must therefore be
  /// variables uses.
  List<Expression> environment = <Expression>[];

  /// Binding environment for variables that are assigned to effectively
  /// constant expressions (see [isEffectivelyConstant]).
  final Map<Variable, Expression> constantEnvironment;

  /// Substitution map for labels. Any break to a label L should be substituted
  /// for a break to L' if L maps to L'.
  Map<Label, Jump> labelRedirects = <Label, Jump>{};

  /// Number of uses of the given variable that are still unseen.
  /// Used to detect the first use of a variable (since we do backwards
  /// traversal, the first use is the last one seen).
  Map<Variable, int> unseenUses = <Variable, int>{};

  /// Rewriter for methods.
  StatementRewriter({this.isDartMode})
      : constantEnvironment = <Variable, Expression>{} {
    assert(isDartMode != null);
  }

  /// Rewriter for nested functions.
  StatementRewriter.nested(StatementRewriter parent)
      : constantEnvironment = parent.constantEnvironment,
        unseenUses = parent.unseenUses,
        isDartMode = parent.isDartMode;

  /// A set of labels that can be safely inlined at their use.
  ///
  /// The successor statements for labeled statements that have only one break
  /// from them are normally rewritten inline at the site of the break.  This
  /// is not safe if the code would be moved inside the scope of an exception
  /// handler (i.e., if the code would be moved into a try from outside it).
  Set<Label> safeForInlining = new Set<Label>();

  /// Returns the redirect target of [jump] or [jump] itself if it should not
  /// be redirected.
  Jump redirect(Jump jump) {
    Jump newJump = labelRedirects[jump.target];
    return newJump != null ? newJump : jump;
  }

  void inEmptyEnvironment(void action()) {
    List oldEnvironment = environment;
    environment = <Expression>[];
    action();
    assert(environment.isEmpty);
    environment = oldEnvironment;
  }

  /// Left-hand side of the given assignment, or `null` if not an assignment.
  Variable getLeftHand(Expression e) {
    return e is Assign ? e.variable : null;
  }

  /// If the given expression always returns the value of one of its
  /// subexpressions, returns that subexpression, otherwise `null`.
  Expression getValueSubexpression(Expression e) {
    if (isDartMode &&
        e is InvokeMethod &&
        (e.selector.isSetter || e.selector.isIndexSet)) {
      return e.arguments.last;
    }
    if (e is SetField) return e.value;
    return null;
  }

  /// If the given expression always returns the value of one of its
  /// subexpressions, and that subexpression is a variable use, returns that
  /// variable. Otherwise `null`.
  Variable getRightHand(Expression e) {
    Expression value = getValueSubexpression(e);
    return value is VariableUse ? value.variable : null;
  }

  @override
  Expression visitVariableUse(VariableUse node) {
    // Count of number of unseen uses remaining.
    unseenUses.putIfAbsent(node.variable, () => node.variable.readCount);
    --unseenUses[node.variable];

    // We traverse the tree right-to-left, so when we have seen all uses,
    // it means we are looking at the first use.
    assert(unseenUses[node.variable] < node.variable.readCount);
    assert(unseenUses[node.variable] >= 0);
    bool isFirstUse = unseenUses[node.variable] == 0;

    // Propagate constant to use site.
    Expression constant = constantEnvironment[node.variable];
    if (constant != null) {
      --node.variable.readCount;
      return visitExpression(constant);
    }

    // Try to propagate another expression into this variable use.
    if (!environment.isEmpty) {
      Expression binding = environment.last;

      // Is this variable assigned by the most recently evaluated impure
      // expression?
      //
      // If so, propagate the assignment, e.g:
      //
      //     { x = foo(); bar(x, x) } ==> bar(x = foo(), x)
      //
      // We must ensure that no other uses separate this use from the
      // assignment. We therefore only propagate assignments into the first use.
      //
      // Note that if this is only use, `visitAssign` will then remove the
      // redundant assignment.
      if (getLeftHand(binding) == node.variable && isFirstUse) {
        environment.removeLast();
        --node.variable.readCount;
        return visitExpression(binding);
      }

      // Is the most recently evaluated impure expression known to have the
      // value of this variable?
      //
      // If so, we can replace this use with the impure expression, e.g:
      //
      //     { E.foo = x; bar(x) } ==> bar(E.foo = x)
      //
      if (getRightHand(binding) == node.variable) {
        environment.removeLast();
        --node.variable.readCount;
        return visitExpression(binding);
      }
    }

    // If the definition could not be propagated, leave the variable use.
    return node;
  }

  /// Returns true if [exp] has no side effects and has a constant value within
  /// any given activation of the enclosing method.
  bool isEffectivelyConstant(Expression exp) {
    // TODO(asgerf): Can be made more aggressive e.g. by checking conditional
    // expressions recursively. Determine if that is a valuable optimization
    // and/or if it is better handled at the CPS level.
    return exp is Constant ||
           exp is This ||
           exp is CreateInvocationMirror ||
           exp is InvokeStatic && exp.isEffectivelyConstant ||
           exp is VariableUse && constantEnvironment.containsKey(exp.variable);
  }

  /// True if [node] is an assignment that can be propagated as a constant.
  bool isEffectivelyConstantAssignment(Expression node) {
    return node is Assign &&
           node.variable.writeCount == 1 &&
           isEffectivelyConstant(node.value);
  }

  Statement visitExpressionStatement(ExpressionStatement stmt) {
    if (isEffectivelyConstantAssignment(stmt.expression)) {
      Assign assign = stmt.expression;
      // Handle constant assignments specially.
      // They are always safe to propagate (though we should avoid duplication).
      // Moreover, they should not prevent other expressions from propagating.
      if (assign.variable.readCount <= 1) {
        // A single-use constant should always be propagted to its use site.
        constantEnvironment[assign.variable] = assign.value;
        --assign.variable.writeCount;
        return visitStatement(stmt.next);
      } else {
        // With more than one use, we cannot propagate the constant.
        // Visit the following statement without polluting [environment] so
        // that any preceding non-constant assignments might still propagate.
        stmt.next = visitStatement(stmt.next);
        assign.value = visitExpression(assign.value);
        return stmt;
      }
    }
    // Try to propagate the expression, and block previous impure expressions
    // until this has propagated.
    environment.add(stmt.expression);
    stmt.next = visitStatement(stmt.next);
    if (!environment.isEmpty && environment.last == stmt.expression) {
      // Retain the expression statement.
      environment.removeLast();
      stmt.expression = visitExpression(stmt.expression);
      return stmt;
    } else {
      // Expression was propagated into the successor.
      return stmt.next;
    }
  }

  Expression visitAssign(Assign node) {
    node.value = visitExpression(node.value);
    // Remove assignments to variables without any uses. This can happen
    // because the assignment was propagated into its use, e.g:
    //
    //     { x = foo(); bar(x) } ==> bar(x = foo()) ==> bar(foo())
    //
    if (node.variable.readCount == 0) {
      --node.variable.writeCount;
      return node.value;
    }
    return node;
  }

  /// Process nodes right-to-left, the opposite of evaluation order in the case
  /// of argument lists..
  void _rewriteList(List<Node> nodes) {
    for (int i = nodes.length - 1; i >= 0; --i) {
      nodes[i] = visitExpression(nodes[i]);
    }
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitInvokeMethod(InvokeMethod node) {
    if (node.receiverIsNotNull) {
      _rewriteList(node.arguments);
      node.receiver = visitExpression(node.receiver);
    } else {
      // Impure expressions cannot be propagated across the method lookup,
      // because it throws when the receiver is null.
      inEmptyEnvironment(() {
        _rewriteList(node.arguments);
      });
      node.receiver = visitExpression(node.receiver);
    }
    return node;
  }

  Expression visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    _rewriteList(node.arguments);
    node.receiver = visitExpression(node.receiver);
    return node;
  }

  Expression visitInvokeConstructor(InvokeConstructor node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitConcatenateStrings(ConcatenateStrings node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitConditional(Conditional node) {
    // Conditional expressions do not exist in the input, but they are
    // introduced by if-to-conditional conversion.
    // Their subexpressions have already been processed; do not reprocess them.
    //
    // Note that this can only happen for conditional expressions. It is an
    // error for any other type of expression to be visited twice or to be
    // created and then visited. We use this special treatment of conditionals
    // to allow for assignment inlining after if-to-conditional conversion.
    //
    // There are several reasons we should not reprocess the subexpressions:
    //
    // - It will mess up the [seenUses] counter, since a single use will be
    //   counted twice.
    //
    // - Other visit methods assume that all subexpressions are variable uses
    //   because they come fresh out of the tree IR builder.
    //
    // - Reprocessing can be expensive.
    //
    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);

    // Impure expressions may not propagate across the branch.
    inEmptyEnvironment(() {
      node.right = visitExpression(node.right);
    });

    return node;
  }

  Expression visitNot(Not node) {
    node.operand = visitExpression(node.operand);
    return node;
  }

  Expression visitFunctionExpression(FunctionExpression node) {
    new StatementRewriter.nested(this).rewrite(node.definition);
    return node;
  }

  Statement visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }

  Statement visitThrow(Throw node) {
    node.value = visitExpression(node.value);
    return node;
  }

  Statement visitRethrow(Rethrow node) {
    return node;
  }

  Statement visitBreak(Break node) {
    // Redirect through chain of breaks.
    // Note that useCount was accounted for at visitLabeledStatement.
    // Note redirect may return either a Break or Continue statement.
    Jump jump = redirect(node);
    if (jump is Break &&
        jump.target.useCount == 1 &&
        safeForInlining.contains(jump.target)) {
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

    safeForInlining.add(node.label);
    node.body = visitStatement(node.body);
    safeForInlining.remove(node.label);

    if (node.label.useCount == 0) {
      // Eliminate the label if next was inlined at a break
      return node.body;
    }

    // Do not propagate assignments into the successor statements, since they
    // may be overwritten by assignments in the body.
    inEmptyEnvironment(() {
      node.next = visitStatement(node.next);
    });

    return node;
  }

  Statement visitIf(If node) {
    node.condition = visitExpression(node.condition);

    // Do not propagate assignments into branches.  Doing so will lead to code
    // duplication.
    // TODO(kmillikin): Rethink this. Propagating some assignments
    // (e.g. variables) is benign.  If they can occur here, they should
    // be handled well.
    inEmptyEnvironment(() {
      node.thenStatement = visitStatement(node.thenStatement);
      node.elseStatement = visitStatement(node.elseStatement);

      tryCollapseIf(node);
    });

    Statement reduced = combineStatementsInBranches(
        node.thenStatement,
        node.elseStatement,
        node.condition);
    if (reduced != null) {
      return reduced;
    }

    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    // Do not propagate assignments into loops.  Doing so is not safe for
    // variables modified in the loop (the initial value will be propagated).
    inEmptyEnvironment(() {
      node.body = visitStatement(node.body);
    });
    return node;
  }

  Statement visitWhileCondition(WhileCondition node) {
    // Not introduced yet
    throw "Unexpected WhileCondition in StatementRewriter";
  }

  Statement visitTry(Try node) {
    inEmptyEnvironment(() {
      Set<Label> saved = safeForInlining;
      safeForInlining = new Set<Label>();
      node.tryBody = visitStatement(node.tryBody);
      safeForInlining = saved;
      node.catchBody = visitStatement(node.catchBody);
    });
    return node;
  }

  Expression visitConstant(Constant node) {
    return node;
  }

  Expression visitThis(This node) {
    return node;
  }

  Expression visitLiteralList(LiteralList node) {
    _rewriteList(node.values);
    return node;
  }

  Expression visitLiteralMap(LiteralMap node) {
    // Process arguments right-to-left, the opposite of evaluation order.
    for (LiteralMapEntry entry in node.entries.reversed) {
      entry.value = visitExpression(entry.value);
      entry.key = visitExpression(entry.key);
    }
    return node;
  }

  Expression visitTypeOperator(TypeOperator node) {
    _rewriteList(node.typeArguments);
    node.value = visitExpression(node.value);
    return node;
  }

  Expression visitSetField(SetField node) {
    node.value = visitExpression(node.value);
    node.object = visitExpression(node.object);
    return node;
  }

  Expression visitGetField(GetField node) {
    node.object = visitExpression(node.object);
    return node;
  }

  Expression visitGetStatic(GetStatic node) {
    return node;
  }

  Expression visitSetStatic(SetStatic node) {
    node.value = visitExpression(node.value);
    return node;
  }

  Expression visitCreateBox(CreateBox node) {
    return node;
  }

  Expression visitCreateInstance(CreateInstance node) {
    _rewriteList(node.arguments);
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

  Expression visitTypeExpression(TypeExpression node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitCreateInvocationMirror(CreateInvocationMirror node) {
    _rewriteList(node.arguments);
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
  Statement combineStatementsInBranches(
      Statement s,
      Statement t,
      Expression condition) {
    if (s is Return && t is Return) {
      return new Return(new Conditional(condition, s.value, t.value));
    }
    if (s is ExpressionStatement && t is ExpressionStatement) {
      // Combine the two expressions and the two successor statements.
      //
      //    C ? {E1 ; S1} : {E2 ; S2}
      //      ==>
      //    (C ? E1 : E2) : combine(S1, S2)
      //
      // If E1 and E2 are assignments, we want to propagate these into the
      // combined statement.
      //
      // It might not be possible to combine the statements, so we combine the
      // expressions, put the result in the environment, and then uncombine the
      // expressions if the statements could not be combined.

      // Combine the expressions.
      CombinedExpressions values =
          combineAsConditional(s.expression, t.expression, condition);

      // Put this into the environment and try to combine the statements.
      // We are not in risk of reprocessing the original subexpressions because
      // the combined expression will always hide them inside a Conditional.
      environment.add(values.combined);
      Statement next = combineStatements(s.next, t.next);

      if (next == null) {
        // Statements could not be combined.
        // Restore the environment and uncombine expressions again.
        environment.removeLast();
        values.uncombine();
        return null;
      } else if (!environment.isEmpty && environment.last == values.combined) {
        // Statements were combined but the combined expression could not be
        // propagated. Leave it as an expression statement here.
        environment.removeLast();
        s.expression = values.combined;
        s.next = next;
        return s;
      } else {
        // Statements were combined and the combined expressions were
        // propagated into the combined statement.
        return next;
      }
    }
    return null;
  }

  /// Creates the expression `[condition] ? [s] : [t]` or an equivalent
  /// expression if something better can be done.
  ///
  /// In particular, assignments will be merged as follows:
  ///
  ///     C ? (v = E1) : (v = E2)
  ///       ==>
  ///     v = C ? E1 : E2
  ///
  /// The latter form is more compact and can also be inlined.
  CombinedExpressions combineAsConditional(
      Expression s,
      Expression t,
      Expression condition) {
    if (s is Assign && t is Assign && s.variable == t.variable) {
      Expression values = new Conditional(condition, s.value, t.value);
      return new CombinedAssigns(s, t, new CombinedExpressions(values));
    }
    return new CombinedExpressions(new Conditional(condition, s, t));
  }

  /// Returns a statement equivalent to both [s] and [t], or null if [s] and
  /// [t] are incompatible.
  /// If non-null is returned, the caller MUST discard [s] and [t] and use
  /// the returned statement instead.
  /// If two breaks are combined, the label's break counter will be decremented.
  Statement combineStatements(Statement s, Statement t) {
    if (s is Break && t is Break && s.target == t.target) {
      --t.target.useCount; // Two breaks become one.
      if (s.target.useCount == 1 && safeForInlining.contains(s.target)) {
        // Only one break remains; inline it.
        --s.target.useCount;
        return visitStatement(s.target.binding.next);
      }
      return s;
    }
    if (s is Continue && t is Continue && s.target == t.target) {
      --t.target.useCount; // Two continues become one.
      return s;
    }
    if (s is Return && t is Return) {
      CombinedExpressions values = combineExpressions(s.value, t.value);
      if (values != null) {
        return new Return(values.combined);
      }
    }
    if (s is ExpressionStatement && t is ExpressionStatement) {
      CombinedExpressions values =
          combineExpressions(s.expression, t.expression);
      if (values == null) return null;
      environment.add(values.combined);
      Statement next = combineStatements(s.next, t.next);
      if (next == null) {
        // The successors could not be combined.
        // Restore the environment and uncombine the values again.
        assert(environment.last == values.combined);
        environment.removeLast();
        values.uncombine();
        return null;
      } else if (!environment.isEmpty && environment.last == values.combined) {
        // The successors were combined but the combined expressions were not
        // propagated. Leave the combined expression as a statement.
        environment.removeLast();
        s.expression = values.combined;
        s.next = next;
        return s;
      } else {
        // The successors were combined, and the combined expressions were
        // propagated into the successors.
        return next;
      }
    }
    return null;
  }

  /// Returns an expression equivalent to both [e1] and [e2].
  /// If non-null is returned, the caller must discard [e1] and [e2] and use
  /// the resulting expression in the tree.
  CombinedExpressions combineExpressions(Expression e1, Expression e2) {
    if (e1 is VariableUse && e2 is VariableUse && e1.variable == e2.variable) {
      return new CombinedUses(e1, e2);
    }
    if (e1 is Assign && e2 is Assign && e1.variable == e2.variable) {
      CombinedExpressions values = combineExpressions(e1.value, e2.value);
      if (values != null) {
        return new CombinedAssigns(e1, e2, values);
      }
    }
    if (e1 is Constant && e2 is Constant && e1.value == e2.value) {
      return new CombinedExpressions(e1);
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
  /// Must be called with an empty environment.
  void tryCollapseIf(If node) {
    assert(environment.isEmpty);
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
    if (outerThen is If) {
      If innerIf = outerThen;
      Statement innerThen = getBranch(innerIf, branch2);
      Statement innerElse = getBranch(innerIf, !branch2);
      Statement combinedElse = combineStatements(innerElse, outerElse);
      if (combinedElse != null) {
        // We always put S in the then branch of the result, and adjust the
        // condition expression if S was actually found in the else branch(es).
        outerIf.condition = new LogicalOperator.and(
            makeCondition(outerIf.condition, branch1),
            makeCondition(innerIf.condition, branch2));
        outerIf.thenStatement = innerThen;
        outerIf.elseStatement = combinedElse;
        return outerIf.elseStatement is If;
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

/// Result of combining two expressions, with the potential for reverting the
/// combination.
///
/// Reverting a combination is done by calling [uncombine]. In this case,
/// both the original expressions should remain in the tree, and the [combined]
/// expression should be orphaned.
///
/// Explicitly reverting a combination is necessary to maintain variable
/// reference counts.
abstract class CombinedExpressions {
  Expression get combined;
  void uncombine();

  factory CombinedExpressions(Expression e) = GenericCombinedExpressions;
}

/// Combines assignments of form `[variable] := E1` and `[variable] := E2` into
/// a single assignment of form `[variable] := combine(E1, E2)`.
class CombinedAssigns implements CombinedExpressions {
  Assign assign1, assign2;
  CombinedExpressions value;
  Expression combined;

  CombinedAssigns(this.assign1, this.assign2, this.value) {
    assert(assign1.variable == assign2.variable);
    assign1.variable.writeCount -= 2; // Destroy the two original assignemnts.
    combined = new Assign(assign1.variable, value.combined);
  }

  void uncombine() {
    value.uncombine();
    ++assign1.variable.writeCount; // Restore original reference count.
  }
}

/// Combines two variable uses into one.
class CombinedUses implements CombinedExpressions {
  VariableUse use1, use2;
  Expression combined;

  CombinedUses(this.use1, this.use2) {
    assert(use1.variable == use2.variable);
    use1.variable.readCount -= 2; // Destroy both the original uses.
    combined = new VariableUse(use1.variable);
  }

  void uncombine() {
    ++use1.variable.readCount; // Restore original reference count.
  }
}

/// Result of combining two expressions that do not affect reference counting.
class GenericCombinedExpressions implements CombinedExpressions {
  Expression combined;

  GenericCombinedExpressions(this.combined);

  void uncombine() {}
}
