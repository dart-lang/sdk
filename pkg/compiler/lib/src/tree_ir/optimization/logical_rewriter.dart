// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of tree_ir.optimization;

/// Rewrites logical expressions to be more compact in the Tree IR.
///
/// In this class an expression is said to occur in "boolean context" if
/// its result is immediately applied to boolean conversion.
///
/// IF STATEMENTS:
///
/// We apply the following two rules to [If] statements (see [visitIf]).
///
///   if (E) {} else S  ==>  if (!E) S else {}    (else can be omitted)
///   if (!E) S1 else S2  ==>  if (E) S2 else S1  (unless previous rule applied)
///
/// NEGATION:
///
/// De Morgan's Laws are used to rewrite negations of logical operators so
/// negations are closer to the root:
///
///   !x && !y  -->  !(x || y)
///
/// This is to enable other rewrites, such as branch swapping in an if. In some
/// contexts, the rule is reversed because we do not expect to apply a rewrite
/// rule to the result. For example:
///
///   z = !(x || y)  ==>  z = !x && !y;
///
/// CONDITIONALS:
///
/// Conditionals with boolean constant operands occur frequently in the input.
/// They can often the re-written to logical operators, for instance:
///
///   if (x ? y : false) S1 else S2
///     ==>
///   if (x && y) S1 else S2
///
/// Conditionals are tricky to rewrite when they occur out of boolean context.
/// Here we must apply more conservative rules, such as:
///
///   x ? true : false  ==>  !!x
///
/// If an operand is known to be a boolean, we can introduce a logical operator:
///
///   x ? y : false  ==>  x && y   (if y is known to be a boolean)
///
/// The following sequence of rewrites demonstrates the merit of these rules:
///
///   x ? (y ? true : false) : false
///   x ? !!y : false   (double negation introduced by [toBoolean])
///   x && !!y          (!!y validated by [isBooleanValued])
///   x && y            (double negation removed by [putInBooleanContext])
///
class LogicalRewriter extends Visitor<Statement, Expression> implements Pass {

  /// Statement to be executed next by natural fallthrough. Although fallthrough
  /// is not introduced in this phase, we need to reason about fallthrough when
  /// evaluating the benefit of swapping the branches of an [If].
  Statement fallthrough;

  void rewrite(FunctionDefinition definition) {
    if (definition.isAbstract) return;

    definition.body = visitStatement(definition.body);
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    Statement savedFallthrough = fallthrough;
    fallthrough = node.next;
    node.body = visitStatement(node.body);
    fallthrough = savedFallthrough;
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitAssign(Assign node) {
    node.definition = visitExpression(node.definition);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }

  Statement visitBreak(Break node) {
    return node;
  }

  Statement visitContinue(Continue node) {
    return node;
  }

  bool isFallthroughBreak(Statement node) {
    return node is Break && node.target.binding.next == fallthrough;
  }

  Statement visitIf(If node) {
    // If one of the branches is empty (i.e. just a fallthrough), then that
    // branch should preferrably be the 'else' so we won't have to print it.
    // In other words, we wish to perform this rewrite:
    //   if (E) {} else {S}
    //     ==>
    //   if (!E) {S}
    // In the tree language, empty statements do not exist yet, so we must check
    // if one branch contains a break that can be eliminated by fallthrough.

    // Swap branches if then is a fallthrough break.
    if (isFallthroughBreak(node.thenStatement)) {
      node.condition = new Not(node.condition);
      Statement tmp = node.thenStatement;
      node.thenStatement = node.elseStatement;
      node.elseStatement = tmp;
    }

    // Can the else part be eliminated?
    // (Either due to the above swap or if the break was already there).
    bool emptyElse = isFallthroughBreak(node.elseStatement);

    node.condition = makeCondition(node.condition, true, liftNots: !emptyElse);
    node.thenStatement = visitStatement(node.thenStatement);
    node.elseStatement = visitStatement(node.elseStatement);

    // If neither branch is empty, eliminate a negation in the condition
    // if (!E) S1 else S2
    //   ==>
    // if (E) S2 else S1
    if (!emptyElse && node.condition is Not) {
      node.condition = (node.condition as Not).operand;
      Statement tmp = node.thenStatement;
      node.thenStatement = node.elseStatement;
      node.elseStatement = tmp;
    }

    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    node.body = visitStatement(node.body);
    return node;
  }

  Statement visitWhileCondition(WhileCondition node) {
    node.condition = makeCondition(node.condition, true, liftNots: false);
    node.body = visitStatement(node.body);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    node.expression = visitExpression(node.expression);
    node.next = visitStatement(node.next);
    return node;
  }


  Expression visitVariable(Variable node) {
    return node;
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitInvokeMethod(InvokeMethod node) {
    node.receiver = visitExpression(node.receiver);
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitInvokeSuperMethod(InvokeSuperMethod node) {
    _rewriteList(node.arguments);
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

  Expression visitLiteralList(LiteralList node) {
    _rewriteList(node.values);
    return node;
  }

  Expression visitLiteralMap(LiteralMap node) {
    node.entries.forEach((LiteralMapEntry entry) {
      entry.key = visitExpression(entry.key);
      entry.value = visitExpression(entry.value);
    });
    return node;
  }

  Expression visitTypeOperator(TypeOperator node) {
    node.receiver = visitExpression(node.receiver);
    return node;
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

  Expression visitFunctionExpression(FunctionExpression node) {
    new LogicalRewriter().rewrite(node.definition);
    return node;
  }

  Statement visitFunctionDeclaration(FunctionDeclaration node) {
    new LogicalRewriter().rewrite(node.definition);
    node.next = visitStatement(node.next);
    return node;
  }

  Expression visitNot(Not node) {
    return toBoolean(makeCondition(node.operand, false, liftNots: false));
  }

  Expression visitConditional(Conditional node) {
    // node.condition will be visited after the then and else parts, because its
    // polarity depends on what rewrite we use.
    node.thenExpression = visitExpression(node.thenExpression);
    node.elseExpression = visitExpression(node.elseExpression);

    // In the following, we must take care not to eliminate or introduce a
    // boolean conversion.

    // x ? true : false --> !!x
    if (isTrue(node.thenExpression) && isFalse(node.elseExpression)) {
      return toBoolean(makeCondition(node.condition, true, liftNots: false));
    }
    // x ? false : true --> !x
    if (isFalse(node.thenExpression) && isTrue(node.elseExpression)) {
      return toBoolean(makeCondition(node.condition, false, liftNots: false));
    }

    // x ? y : false ==> x && y  (if y is known to be a boolean)
    if (isBooleanValued(node.thenExpression) && isFalse(node.elseExpression)) {
      return new LogicalOperator.and(
          makeCondition(node.condition, true, liftNots:false),
          putInBooleanContext(node.thenExpression));
    }
    // x ? y : true ==> !x || y  (if y is known to be a boolean)
    if (isBooleanValued(node.thenExpression) && isTrue(node.elseExpression)) {
      return new LogicalOperator.or(
          makeCondition(node.condition, false, liftNots: false),
          putInBooleanContext(node.thenExpression));
    }
    // x ? true : y ==> x || y  (if y if known to be boolean)
    if (isBooleanValued(node.elseExpression) && isTrue(node.thenExpression)) {
      return new LogicalOperator.or(
          makeCondition(node.condition, true, liftNots: false),
          putInBooleanContext(node.elseExpression));
    }
    // x ? false : y ==> !x && y  (if y is known to be a boolean)
    if (isBooleanValued(node.elseExpression) && isFalse(node.thenExpression)) {
      return new LogicalOperator.and(
          makeCondition(node.condition, false, liftNots: false),
          putInBooleanContext(node.elseExpression));
    }

    node.condition = makeCondition(node.condition, true);

    // !x ? y : z ==> x ? z : y
    if (node.condition is Not) {
      node.condition = (node.condition as Not).operand;
      Expression tmp = node.thenExpression;
      node.thenExpression = node.elseExpression;
      node.elseExpression = tmp;
    }

    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = makeCondition(node.left, true);
    node.right = makeCondition(node.right, true);
    return node;
  }

  /// True if the given expression is known to evaluate to a boolean.
  /// This will not recursively traverse [Conditional] expressions, but if
  /// applied to the result of [visitExpression] conditionals will have been
  /// rewritten anyway.
  bool isBooleanValued(Expression e) {
    return isTrue(e) || isFalse(e) || e is Not || e is LogicalOperator;
  }

  /// Rewrite an expression that was originally processed in a non-boolean
  /// context.
  Expression putInBooleanContext(Expression e) {
    if (e is Not && e.operand is Not) {
      return (e.operand as Not).operand;
    } else {
      return e;
    }
  }

  /// Forces a boolean conversion of the given expression.
  Expression toBoolean(Expression e) {
    if (isBooleanValued(e))
      return e;
    else
      return new Not(new Not(e));
  }

  /// Creates an equivalent boolean expression. The expression must occur in a
  /// context where its result is immediately subject to boolean conversion.
  /// If [polarity] if false, the negated condition will be created instead.
  /// If [liftNots] is true (default) then Not expressions will be lifted toward
  /// the root the condition so they can be eliminated by the caller.
  Expression makeCondition(Expression e, bool polarity, {bool liftNots:true}) {
    if (e is Not) {
      // !!E ==> E
      return makeCondition(e.operand, !polarity, liftNots: liftNots);
    }
    if (e is LogicalOperator) {
      // If polarity=false, then apply the rewrite !(x && y) ==> !x || !y
      e.left = makeCondition(e.left, polarity);
      e.right = makeCondition(e.right, polarity);
      if (!polarity) {
        e.isAnd = !e.isAnd;
      }
      // !x && !y ==> !(x || y)  (only if lifting nots)
      if (e.left is Not && e.right is Not && liftNots) {
        e.left = (e.left as Not).operand;
        e.right = (e.right as Not).operand;
        e.isAnd = !e.isAnd;
        return new Not(e);
      }
      return e;
    }
    if (e is Conditional) {
      // Handle polarity by: !(x ? y : z) ==> x ? !y : !z
      // Rewrite individual branches now. The condition will be rewritten
      // when we know what polarity to use (depends on which rewrite is used).
      e.thenExpression = makeCondition(e.thenExpression, polarity);
      e.elseExpression = makeCondition(e.elseExpression, polarity);

      // x ? true : false ==> x
      if (isTrue(e.thenExpression) && isFalse(e.elseExpression)) {
        return makeCondition(e.condition, true, liftNots: liftNots);
      }
      // x ? false : true ==> !x
      if (isFalse(e.thenExpression) && isTrue(e.elseExpression)) {
        return makeCondition(e.condition, false, liftNots: liftNots);
      }
      // x ? true : y  ==> x || y
      if (isTrue(e.thenExpression)) {
        return makeOr(makeCondition(e.condition, true),
                      e.elseExpression,
                      liftNots: liftNots);
      }
      // x ? false : y  ==> !x && y
      if (isFalse(e.thenExpression)) {
        return makeAnd(makeCondition(e.condition, false),
                       e.elseExpression,
                       liftNots: liftNots);
      }
      // x ? y : true  ==> !x || y
      if (isTrue(e.elseExpression)) {
        return makeOr(makeCondition(e.condition, false),
                      e.thenExpression,
                      liftNots: liftNots);
      }
      // x ? y : false  ==> x && y
      if (isFalse(e.elseExpression)) {
        return makeAnd(makeCondition(e.condition, true),
                       e.thenExpression,
                       liftNots: liftNots);
      }

      e.condition = makeCondition(e.condition, true);

      // !x ? y : z ==> x ? z : y
      if (e.condition is Not) {
        e.condition = (e.condition as Not).operand;
        Expression tmp = e.thenExpression;
        e.thenExpression = e.elseExpression;
        e.elseExpression = tmp;
      }
      // x ? !y : !z ==> !(x ? y : z)  (only if lifting nots)
      if (e.thenExpression is Not && e.elseExpression is Not && liftNots) {
        e.thenExpression = (e.thenExpression as Not).operand;
        e.elseExpression = (e.elseExpression as Not).operand;
        return new Not(e);
      }
      return e;
    }
    if (e is Constant && e.value.isBool) {
      // !true ==> false
      if (!polarity) {
        values.BoolConstantValue value = e.value;
        return new Constant.primitive(value.negate());
      }
      return e;
    }
    e = visitExpression(e);
    return polarity ? e : new Not(e);
  }

  bool isTrue(Expression e) {
    return e is Constant && e.value.isTrue;
  }

  bool isFalse(Expression e) {
    return e is Constant && e.value.isFalse;
  }

  Expression makeAnd(Expression e1, Expression e2, {bool liftNots: true}) {
    if (e1 is Not && e2 is Not && liftNots) {
      return new Not(new LogicalOperator.or(e1.operand, e2.operand));
    } else {
      return new LogicalOperator.and(e1, e2);
    }
  }

  Expression makeOr(Expression e1, Expression e2, {bool liftNots: true}) {
    if (e1 is Not && e2 is Not && liftNots) {
      return new Not(new LogicalOperator.and(e1.operand, e2.operand));
    } else {
      return new LogicalOperator.or(e1, e2);
    }
  }

  /// Destructively updates each entry of [l] with the result of visiting it.
  void _rewriteList(List<Expression> l) {
    for (int i = 0; i < l.length; i++) {
      l[i] = visitExpression(l[i]);
    }
  }
}

