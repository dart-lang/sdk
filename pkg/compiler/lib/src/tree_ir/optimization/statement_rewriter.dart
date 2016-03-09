// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir.optimization.statement_rewriter;

import 'optimization.dart' show Pass;
import '../tree_ir_nodes.dart';
import '../../io/source_information.dart';
import '../../elements/elements.dart';
import '../../js/placeholder_safety.dart';

/**
 * Translates to direct-style.
 *
 * In addition to the general IR constraints (see [CheckTreeIntegrity]),
 * the input is assumed to satisfy the following criteria:
 *
 * All expressions other than those nested in [Assign] or [ExpressionStatement]
 * must be simple. A [VariableUse] and [This] is a simple expression.
 * The right-hand of an [Assign] may not be an [Assign].
 *
 * Moreover, every variable must either be an SSA variable or a mutable
 * variable, and must satisfy the corresponding criteria:
 *
 * SSA VARIABLE:
 * An SSA variable must have a unique definition site, which is either an
 * assignment or label. In case of a label, its target must act as the unique
 * reaching definition of that variable at all uses of the variable and at
 * all other label targets where the variable is in scope.
 *
 * (The second criterion is to ensure that we can move a use of an SSA variable
 * across a label without changing its reaching definition).
 *
 * MUTABLE VARIABLE:
 * Uses of mutable variables are considered complex expressions, and hence must
 * not be nested in other expressions. Assignments to mutable variables must
 * have simple right-hand sides.
 *
 * ----
 *
 * This pass performs the following transformations on the tree:
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
    node.parameters.forEach(pushDominatingAssignment);
    node.body = visitStatement(node.body);
    node.parameters.forEach(popDominatingAssignment);
  }

  /// The most recently evaluated impure expressions, with the most recent
  /// expression being last.
  ///
  /// Most importantly, this contains [Assign] expressions that we attempt to
  /// inline at their use site. It also contains other impure expressions that
  /// we can propagate to a variable use if they are known to return the value
  /// of that variable.
  ///
  /// Assignments with constant right-hand sides (see [isEffectivelyConstant])
  /// are not considered impure and are put in [constantEnvironment] instead.
  ///
  /// Except for [Conditional]s, expressions in the environment have
  /// not been processed, and all their subexpressions must therefore be
  /// variables uses.
  List<Expression> environment = <Expression>[];

  /// Binding environment for variables that are assigned to effectively
  /// constant expressions (see [isEffectivelyConstant]).
  Map<Variable, Expression> constantEnvironment = <Variable, Expression>{};

  /// Substitution map for labels. Any break to a label L should be substituted
  /// for a break to L' if L maps to L'.
  Map<Label, Jump> labelRedirects = <Label, Jump>{};

  /// Number of uses of the given variable that are still unseen.
  /// Used to detect the first use of a variable (since we do backwards
  /// traversal, the first use is the last one seen).
  Map<Variable, int> unseenUses = <Variable, int>{};

  /// Number of assignments to a given variable that dominate the current
  /// position.
  ///
  /// Pure expressions will not be inlined if it uses a variable with more than
  /// one dominating assignment, because the reaching definition of the used
  /// variable might have changed since it was put in the environment.
  final Map<Variable, int> dominatingAssignments = <Variable, int>{};

  /// A set of labels that can be safely inlined at their use.
  ///
  /// The successor statements for labeled statements that have only one break
  /// from them are normally rewritten inline at the site of the break.  This
  /// is not safe if the code would be moved inside the scope of an exception
  /// handler (i.e., if the code would be moved into a try from outside it).
  Set<Label> safeForInlining = new Set<Label>();

  /// If the top element is true, assignments of form "x = CONST" may be
  /// propagated into a following occurence of CONST.  This may confuse the JS
  /// engine so it is disabled in some cases.
  final List<bool> allowRhsPropagation = <bool>[true];

  bool get isRhsPropagationAllowed => allowRhsPropagation.last;

  /// Returns the redirect target of [jump] or [jump] itself if it should not
  /// be redirected.
  Jump redirect(Jump jump) {
    Jump newJump = labelRedirects[jump.target];
    return newJump != null ? newJump : jump;
  }

  void inEmptyEnvironment(void action(), {bool keepConstants: true}) {
    List oldEnvironment = environment;
    Map oldConstantEnvironment = constantEnvironment;
    environment = <Expression>[];
    if (!keepConstants) {
      constantEnvironment = <Variable, Expression>{};
    }
    action();
    assert(environment.isEmpty);
    environment = oldEnvironment;
    if (!keepConstants) {
      constantEnvironment = oldConstantEnvironment;
    }
  }

  /// Left-hand side of the given assignment, or `null` if not an assignment.
  Variable getLeftHand(Expression e) {
    return e is Assign ? e.variable : null;
  }

  /// If the given expression always returns the value of one of its
  /// subexpressions, returns that subexpression, otherwise `null`.
  Expression getValueSubexpression(Expression e) {
    if (e is SetField) return e.value;
    return null;
  }

  /// If the given expression always returns the value of one of its
  /// subexpressions, and that subexpression is a variable use, returns that
  /// variable. Otherwise `null`.
  Variable getRightHandVariable(Expression e) {
    Expression value = getValueSubexpression(e);
    return value is VariableUse ? value.variable : null;
  }

  Constant getRightHandConstant(Expression e) {
    Expression value = getValueSubexpression(e);
    return value is Constant ? value : null;
  }

  /// True if the given expression (taken from [constantEnvironment]) uses a
  /// variable that might have been reassigned since [node] was evaluated.
  bool hasUnsafeVariableUse(Expression node) {
    bool wasFound = false;
    VariableUseVisitor.visit(node, (VariableUse use) {
      if (dominatingAssignments[use.variable] > 1) {
        wasFound = true;
      }
    });
    return wasFound;
  }

  void pushDominatingAssignment(Variable variable) {
    if (variable != null) {
      dominatingAssignments.putIfAbsent(variable, () => 0);
      ++dominatingAssignments[variable];
    }
  }

  void popDominatingAssignment(Variable variable) {
    if (variable != null) {
      --dominatingAssignments[variable];
    }
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

    // We cannot reliably find the first dynamic use of a variable that is
    // accessed from a JS function in a foreign code fragment.
    if (node.variable.isCaptured) return node;

    bool isFirstUse = unseenUses[node.variable] == 0;

    // Propagate constant to use site.
    Expression constant = constantEnvironment[node.variable];
    if (constant != null && !hasUnsafeVariableUse(constant)) {
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
      if (isRhsPropagationAllowed &&
          getRightHandVariable(binding) == node.variable) {
        environment.removeLast();
        --node.variable.readCount;
        return visitExpression(binding);
      }
    }

    // If the definition could not be propagated, leave the variable use.
    return node;
  }

  /// True if [exp] contains a use of a variable that was assigned to by the
  /// most recently evaluated impure expression (constant assignments are not
  /// considered impure).
  ///
  /// This implies that the assignment can be propagated into this use unless
  /// the use is moved further away.
  ///
  /// In this case, we will refrain from moving [exp] across other impure
  /// expressions, even when this is safe, because doing so would immediately
  /// prevent the previous expression from propagating, canceling out the
  /// benefit we might otherwise gain from propagating [exp].
  ///
  /// [exp] must be an unprocessed expression, i.e. either a [Conditional] or
  /// an expression whose subexpressions are all variable uses.
  bool usesRecentlyAssignedVariable(Expression exp) {
    if (environment.isEmpty) return false;
    Variable variable = getLeftHand(environment.last);
    if (variable == null) return false;
    IsVariableUsedVisitor visitor = new IsVariableUsedVisitor(variable);
    visitor.visitExpression(exp);
    return visitor.wasFound;
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
           exp is CreateInstance ||
           exp is CreateBox ||
           exp is TypeExpression ||
           exp is GetStatic && exp.element.isFunction ||
           exp is Interceptor ||
           exp is ApplyBuiltinOperator ||
           exp is VariableUse && constantEnvironment.containsKey(exp.variable);
  }

  /// True if [node] is an assignment that can be propagated as a constant.
  bool isEffectivelyConstantAssignment(Expression node) {
    return node is Assign &&
           node.variable.writeCount == 1 &&
           isEffectivelyConstant(node.value);
  }

  Statement visitExpressionStatement(ExpressionStatement inputNode) {
    // Analyze chains of expression statements.
    // To avoid deep recursion, [processExpressionStatement] returns a callback
    // to invoke after its successor node has been processed.
    // These callbacks are stored in a list and invoked in reverse at the end.
    List<Function> stack = [];
    Statement node = inputNode;
    while (node is ExpressionStatement) {
      stack.add(processExpressionStatement(node));
      node = node.next;
    }
    Statement result = visitStatement(node);
    for (Function fun in stack.reversed) {
      result = fun(result);
    }
    return result;
  }

  /// Attempts to propagate an assignment in an expression statement.
  ///
  /// Returns a callback to be invoked after the sucessor statement has
  /// been processed.
  Function processExpressionStatement(ExpressionStatement stmt) {
    Variable leftHand = getLeftHand(stmt.expression);
    pushDominatingAssignment(leftHand);
    if (isEffectivelyConstantAssignment(stmt.expression) &&
        !usesRecentlyAssignedVariable(stmt.expression)) {
      Assign assign = stmt.expression;
      // Handle constant assignments specially.
      // They are always safe to propagate (though we should avoid duplication).
      // Moreover, they should not prevent other expressions from propagating.
      if (assign.variable.readCount == 1) {
        // A single-use constant should always be propagated to its use site.
        constantEnvironment[assign.variable] = assign.value;
        return (Statement next) {
          popDominatingAssignment(leftHand);
          if (assign.variable.readCount > 0) {
            // The assignment could not be propagated into the successor,
            // either because it [hasUnsafeVariableUse] or because the
            // use is outside the current try block, and we do not currently
            // support constant propagation out of a try block.
            constantEnvironment.remove(assign.variable);
            assign.value = visitExpression(assign.value);
            stmt.next = next;
            return stmt;
          } else {
            --assign.variable.writeCount;
            return next;
          }
        };
      } else {
        // With more than one use, we cannot propagate the constant.
        // Visit the following statement without polluting [environment] so
        // that any preceding non-constant assignments might still propagate.
        return (Statement next) {
          stmt.next = next;
          popDominatingAssignment(leftHand);
          assign.value = visitExpression(assign.value);
          return stmt;
        };
      }
    } else {
      // Try to propagate the expression, and block previous impure expressions
      // until this has propagated.
      environment.add(stmt.expression);
      return (Statement next) {
        stmt.next = next;
        popDominatingAssignment(leftHand);
        if (!environment.isEmpty && environment.last == stmt.expression) {
          // Retain the expression statement.
          environment.removeLast();
          stmt.expression = visitExpression(stmt.expression);
          return stmt;
        } else {
          // Expression was propagated into the successor.
          return stmt.next;
        }
      };
    }
  }

  Expression visitAssign(Assign node) {
    allowRhsPropagation.add(true);
    node.value = visitExpression(node.value);
    allowRhsPropagation.removeLast();
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
  void _rewriteList(List<Node> nodes, {bool rhsPropagation: true}) {
    allowRhsPropagation.add(rhsPropagation);
    for (int i = nodes.length - 1; i >= 0; --i) {
      nodes[i] = visitExpression(nodes[i]);
    }
    allowRhsPropagation.removeLast();
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

  Expression visitOneShotInterceptor(OneShotInterceptor node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
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
    // The target function might not exist before the enclosing class has been
    // instantitated for the first time.  If the receiver might be the first
    // instantiation of its class, we cannot propgate it into the receiver
    // expression, because the target function is evaluated before the receiver.
    // Calls to constructor bodies are compiled so that the receiver is
    // evaluated first, so they are safe.
    if (node.target is! ConstructorBodyElement) {
      inEmptyEnvironment(() {
        node.receiver = visitExpression(node.receiver);
      });
    } else {
      node.receiver = visitExpression(node.receiver);
    }
    return node;
  }

  Expression visitInvokeConstructor(InvokeConstructor node) {
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
    // Impure expressions may not propagate across the branch.
    inEmptyEnvironment(() {
      node.right = visitExpression(node.right);
    });
    node.left = visitExpression(node.left);
    return node;
  }

  Expression visitNot(Not node) {
    node.operand = visitExpression(node.operand);
    return node;
  }

  bool isNullConstant(Expression node) {
    return node is Constant && node.value.isNull;
  }

  Statement visitReturn(Return node) {
    if (!isNullConstant(node.value)) {
      // Do not chain assignments into a null return.
      node.value = visitExpression(node.value);
    }
    return node;
  }

  Statement visitThrow(Throw node) {
    node.value = visitExpression(node.value);
    return node;
  }

  Statement visitUnreachable(Unreachable node) {
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
    // Do not propagate assignments into branches.
    inEmptyEnvironment(() {
      node.thenStatement = visitStatement(node.thenStatement);
      node.elseStatement = visitStatement(node.elseStatement);
    });

    node.condition = visitExpression(node.condition);

    inEmptyEnvironment(() {
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
    // Do not propagate effective constant expressions into loops, since
    // computing them is not free (e.g. interceptors are expensive).
    inEmptyEnvironment(() {
      node.body = visitStatement(node.body);
    }, keepConstants: false);
    return node;
  }

  Statement visitFor(For node) {
    // Not introduced yet
    throw "Unexpected For in StatementRewriter";
  }

  Statement visitTry(Try node) {
    inEmptyEnvironment(() {
      Set<Label> saved = safeForInlining;
      safeForInlining = new Set<Label>();
      node.tryBody = visitStatement(node.tryBody);
      safeForInlining = saved;
      node.catchParameters.forEach(pushDominatingAssignment);
      node.catchBody = visitStatement(node.catchBody);
      node.catchParameters.forEach(popDominatingAssignment);
    });
    return node;
  }

  Expression visitConstant(Constant node) {
    if (isRhsPropagationAllowed && !environment.isEmpty) {
      Constant constant = getRightHandConstant(environment.last);
      if (constant != null && constant.value == node.value) {
        return visitExpression(environment.removeLast());
      }
    }
    return node;
  }

  Expression visitThis(This node) {
    return node;
  }

  Expression visitLiteralList(LiteralList node) {
    _rewriteList(node.values);
    return node;
  }

  Expression visitTypeOperator(TypeOperator node) {
    _rewriteList(node.typeArguments);
    node.value = visitExpression(node.value);
    return node;
  }

  bool isCompoundableBuiltin(Expression e) {
    return e is ApplyBuiltinOperator &&
           e.arguments.length >= 2 &&
           isCompoundableOperator(e.operator);
  }

  /// Converts a compoundable operator application into the right-hand side for
  /// use in a compound assignment, discarding the left-hand value.
  ///
  /// For example, for `x + y + z` it returns `y + z`.
  Expression contractCompoundableBuiltin(ApplyBuiltinOperator e) {
    assert(isCompoundableBuiltin(e));
    if (e.arguments.length > 2) {
      assert(e.operator == BuiltinOperator.StringConcatenate);
      return new ApplyBuiltinOperator(e.operator, e.arguments.skip(1).toList());
    } else {
      return e.arguments[1];
    }
  }

  void destroyVariableUse(VariableUse node) {
    --node.variable.readCount;
  }

  Expression visitSetField(SetField node) {
    allowRhsPropagation.add(true);
    node.value = visitExpression(node.value);
    if (isCompoundableBuiltin(node.value)) {
      ApplyBuiltinOperator rhs = node.value;
      Expression left = rhs.arguments[0];
      if (left is GetField &&
          left.field == node.field &&
          samePrimary(left.object, node.object)) {
        destroyPrimaryExpression(left.object);
        node.compound = rhs.operator;
        node.value = contractCompoundableBuiltin(rhs);
      }
    }
    node.object = visitExpression(node.object);
    allowRhsPropagation.removeLast();
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
    allowRhsPropagation.add(true);
    node.value = visitExpression(node.value);
    if (isCompoundableBuiltin(node.value)) {
      ApplyBuiltinOperator rhs = node.value;
      Expression left = rhs.arguments[0];
      if (left is GetStatic &&
          left.element == node.element &&
          !left.useLazyGetter) {
        node.compound = rhs.operator;
        node.value = contractCompoundableBuiltin(rhs);
      }
    }
    allowRhsPropagation.removeLast();
    return node;
  }

  Expression visitGetTypeTestProperty(GetTypeTestProperty node) {
    node.object = visitExpression(node.object);
    return node;
  }

  Expression visitCreateBox(CreateBox node) {
    return node;
  }

  Expression visitCreateInstance(CreateInstance node) {
    if (node.typeInformation != null) {
      node.typeInformation = visitExpression(node.typeInformation);
    }
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

  Expression visitInterceptor(Interceptor node) {
    node.input = visitExpression(node.input);
    return node;
  }

  Expression visitGetLength(GetLength node) {
    node.object = visitExpression(node.object);
    return node;
  }

  Expression visitGetIndex(GetIndex node) {
    node.index = visitExpression(node.index);
    node.object = visitExpression(node.object);
    return node;
  }

  Expression visitSetIndex(SetIndex node) {
    node.value = visitExpression(node.value);
    if (isCompoundableBuiltin(node.value)) {
      ApplyBuiltinOperator rhs = node.value;
      Expression left = rhs.arguments[0];
      if (left is GetIndex &&
          samePrimary(left.object, node.object) &&
          samePrimary(left.index, node.index)) {
        destroyPrimaryExpression(left.object);
        destroyPrimaryExpression(left.index);
        node.compound = rhs.operator;
        node.value = contractCompoundableBuiltin(rhs);
      }
    }
    node.index = visitExpression(node.index);
    node.object = visitExpression(node.object);
    return node;
  }

  /// True if [operator] is a binary operator that always has the same value
  /// if its arguments are swapped.
  bool isSymmetricOperator(BuiltinOperator operator) {
    switch (operator) {
      case BuiltinOperator.StrictEq:
      case BuiltinOperator.StrictNeq:
      case BuiltinOperator.LooseEq:
      case BuiltinOperator.LooseNeq:
      case BuiltinOperator.NumAnd:
      case BuiltinOperator.NumOr:
      case BuiltinOperator.NumXor:
      case BuiltinOperator.NumAdd:
      case BuiltinOperator.NumMultiply:
        return true;
      default:
        return false;
    }
  }

  /// If [operator] is a commutable binary operator, returns the commuted
  /// operator, possibly the operator itself, otherwise returns `null`.
  BuiltinOperator commuteBinaryOperator(BuiltinOperator operator) {
    if (isSymmetricOperator(operator)) {
      // Symmetric operators are their own commutes.
      return operator;
    }
    switch(operator) {
      case BuiltinOperator.NumLt: return BuiltinOperator.NumGt;
      case BuiltinOperator.NumLe: return BuiltinOperator.NumGe;
      case BuiltinOperator.NumGt: return BuiltinOperator.NumLt;
      case BuiltinOperator.NumGe: return BuiltinOperator.NumLe;
      default: return null;
    }
  }

  /// Built-in binary operators are commuted when it is safe and can enable an
  /// assignment propagation. For example:
  ///
  ///    var x = foo();
  ///    var y = bar();
  ///    var z = y < x;
  ///
  ///      ==>
  ///
  ///    var z = foo() > bar();
  ///
  /// foo() must be evaluated before bar(), so the propagation is only possible
  /// by commuting the operator.
  Expression visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    if (!environment.isEmpty && getLeftHand(environment.last) != null) {
      Variable propagatableVariable = getLeftHand(environment.last);
      BuiltinOperator commuted = commuteBinaryOperator(node.operator);
      if (commuted != null) {
        // Only binary operators can commute.
        assert(node.arguments.length == 2);
        Expression left = node.arguments[0];
        if (left is VariableUse && propagatableVariable == left.variable) {
          Expression right = node.arguments[1];
          if (right is This ||
              (right is VariableUse &&
               propagatableVariable != right.variable &&
               !constantEnvironment.containsKey(right.variable))) {
            // An assignment can be propagated if we commute the operator.
            node.operator = commuted;
            node.arguments[0] = right;
            node.arguments[1] = left;
          }
        }
      }
    }
    // Avoid code like `p == (q.f = null)`. JS operators with a constant operand
    // can sometimes be compiled to a specialized instruction in the JS engine,
    // so retain syntactically constant operands.
    _rewriteList(node.arguments, rhsPropagation: false);
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

      Variable leftHand = getLeftHand(values.combined);
      pushDominatingAssignment(leftHand);
      Statement next = combineStatements(s.next, t.next);
      popDominatingAssignment(leftHand);

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
        // TODO(johnniwinther): Handle multiple source informations.
        SourceInformation sourceInformation = s.sourceInformation != null
            ? s.sourceInformation : t.sourceInformation;
        return new Return(values.combined,
            sourceInformation: sourceInformation);
      }
    }
    if (s is ExpressionStatement && t is ExpressionStatement) {
      CombinedExpressions values =
          combineExpressions(s.expression, t.expression);
      if (values == null) return null;
      environment.add(values.combined);
      Variable leftHand = getLeftHand(values.combined);
      pushDominatingAssignment(leftHand);
      Statement next = combineStatements(s.next, t.next);
      popDominatingAssignment(leftHand);
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

  void handleForeignCode(ForeignCode node) {
    // Some arguments will get inserted in a JS code template.  The arguments
    // will not always be evaluated (e.g. the second placeholder in the template
    // '# && #').
    bool isNullable(int position) => node.nullableArguments[position];

    int safeArguments =
      PlaceholderSafetyAnalysis.analyze(node.codeTemplate.ast, isNullable);
    inEmptyEnvironment(() {
      for (int i = node.arguments.length - 1; i >= safeArguments; --i) {
        node.arguments[i] = visitExpression(node.arguments[i]);
      }
    });
    for (int i = safeArguments - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
  }

  @override
  Expression visitForeignExpression(ForeignExpression node) {
    handleForeignCode(node);
    return node;
  }

  @override
  Statement visitForeignStatement(ForeignStatement node) {
    handleForeignCode(node);
    return node;
  }

  @override
  Expression visitAwait(Await node) {
    node.input = visitExpression(node.input);
    return node;
  }

  @override
  Statement visitYield(Yield node) {
    node.next = visitStatement(node.next);
    node.input = visitExpression(node.input);
    return node;
  }

  @override
  Statement visitReceiverCheck(ReceiverCheck node) {
    inEmptyEnvironment(() {
      node.next = visitStatement(node.next);
    });
    if (node.condition != null) {
      inEmptyEnvironment(() {
        // Value occurs in conditional context.
        node.value = visitExpression(node.value);
      });
      node.condition = visitExpression(node.condition);
    } else {
      node.value = visitExpression(node.value);
    }
    return node;
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

/// Looks for uses of a specific variable.
///
/// Note that this visitor is only applied to expressions where all
/// sub-expressions are known to be variable uses, so there is no risk of
/// explosive reprocessing.
class IsVariableUsedVisitor extends RecursiveVisitor {
  Variable variable;
  bool wasFound = false;

  IsVariableUsedVisitor(this.variable);

  visitVariableUse(VariableUse node) {
    if (node.variable == variable) {
      wasFound = true;
    }
  }
}

typedef VariableUseCallback(VariableUse use);

class VariableUseVisitor extends RecursiveVisitor {
  VariableUseCallback callback;

  VariableUseVisitor(this.callback);

  visitVariableUse(VariableUse use) => callback(use);

  static void visit(Expression node, VariableUseCallback callback) {
    new VariableUseVisitor(callback).visitExpression(node);
  }
}

bool sameVariable(Expression e1, Expression e2) {
  return e1 is VariableUse && e2 is VariableUse && e1.variable == e2.variable;
}

/// True if [e1] and [e2] are primary expressions (expressions without
/// subexpressions) with the same value.
bool samePrimary(Expression e1, Expression e2) {
  return sameVariable(e1, e2) || (e1 is This && e2 is This);
}

/// Decrement the reference count for [e] if it is a variable use.
void destroyPrimaryExpression(Expression e) {
  if (e is VariableUse) {
    --e.variable.readCount;
  } else {
    assert(e is This);
  }
}
