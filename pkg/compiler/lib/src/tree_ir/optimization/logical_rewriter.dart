// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir.optimization.logical_rewriter;

import '../tree_ir_nodes.dart';
import 'optimization.dart' show Pass;
import '../../constants/values.dart' as values;

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
/// If the possible falsy values of the condition are known, we can sometimes
/// introduce a logical operator:
///
///   !x ? y : false  ==>  !x && y
///
class LogicalRewriter extends RecursiveTransformer
                      implements Pass {
  String get passName => 'Logical rewriter';

  @override
  void rewrite(FunctionDefinition node) {
    node.body = visitStatement(node.body);
  }

  final FallthroughStack fallthrough = new FallthroughStack();

  @override
  void visitInnerFunction(FunctionDefinition node) {
    new LogicalRewriter().rewrite(node);
  }

  /// True if the given statement is equivalent to its fallthrough semantics.
  ///
  /// This means it will ultimately translate to an empty statement.
  bool isFallthrough(Statement node) {
    return node is Break && isFallthroughBreak(node) ||
           node is Continue && isFallthroughContinue(node) ||
           node is Return && isFallthroughReturn(node);
  }

  bool isFallthroughBreak(Break node) {
    Statement target = fallthrough.target;
    return node.target.binding.next == target ||
           target is Break && target.target == node.target;
  }

  bool isFallthroughContinue(Continue node) {
    Statement target = fallthrough.target;
    return node.target.binding == target ||
           target is Continue && target.target == node.target;
  }

  bool isFallthroughReturn(Return node) {
    return isNull(node.value) && fallthrough.target == null;
  }

  bool isTerminator(Statement node) {
    return (node is Jump || node is Return) && !isFallthrough(node) ||
           (node is ExpressionStatement && node.next is Unreachable);
  }

  Statement visitIf(If node) {
    // If one of the branches is empty (i.e. just a fallthrough), then that
    // branch should preferably be the 'else' so we won't have to print it.
    // In other words, we wish to perform this rewrite:
    //   if (E) {} else {S}
    //     ==>
    //   if (!E) {S}
    // In the tree language, empty statements do not exist yet, so we must check
    // if one branch contains a break that can be eliminated by fallthrough.

    // Rewrite each branch and keep track of which ones might fall through.
    int usesBefore = fallthrough.useCount;
    node.thenStatement = visitStatement(node.thenStatement);
    int usesAfterThen = fallthrough.useCount;
    node.elseStatement = visitStatement(node.elseStatement);
    bool thenHasFallthrough = (fallthrough.useCount > usesBefore);
    bool elseHasFallthrough = (fallthrough.useCount > usesAfterThen);

    // Determine which branch is most beneficial as 'then' branch.
    const int THEN = 1;
    const int NEITHER = 0;
    const int ELSE = -1;
    int bestThenBranch = NEITHER;
    if (isFallthrough(node.thenStatement) &&
        !isFallthrough(node.elseStatement)) {
      // Put the empty statement in the 'else' branch.
      // if (E) {} else {S} ==> if (!E) {S}
      bestThenBranch = ELSE;
    } else if (isFallthrough(node.elseStatement) &&
               !isFallthrough(node.thenStatement)) {
      // Keep the empty statement in the 'else' branch.
      // if (E) {S} else {}
      bestThenBranch = THEN;
    } else if (thenHasFallthrough && !elseHasFallthrough) {
      // Put abrupt termination in the 'then' branch to omit 'else'.
      // if (E) {S1} else {S2; return v} ==> if (!E) {S2; return v}; S1
      bestThenBranch = ELSE;
    } else if (!thenHasFallthrough && elseHasFallthrough) {
      // Keep abrupt termination in the 'then' branch to omit 'else'.
      // if (E) {S1; return v}; S2
      bestThenBranch = THEN;
    } else if (isTerminator(node.elseStatement) &&
               !isTerminator(node.thenStatement)) {
      // Put early termination in the 'then' branch to reduce nesting depth.
      // if (E) {S}; return v ==> if (!E) return v; S
      bestThenBranch = ELSE;
    } else if (isTerminator(node.thenStatement) &&
               !isTerminator(node.elseStatement)) {
      // Keep early termination in the 'then' branch to reduce nesting depth.
      // if (E) {return v;} S
      bestThenBranch = THEN;
    }

    // Swap branches if 'else' is better as 'then'
    if (bestThenBranch == ELSE) {
      node.condition = new Not(node.condition);
      Statement tmp = node.thenStatement;
      node.thenStatement = node.elseStatement;
      node.elseStatement = tmp;
    }

    // If neither branch is better, eliminate a negation in the condition
    // if (!E) S1 else S2
    //   ==>
    // if (E) S2 else S1
    node.condition = makeCondition(node.condition, true,
                                   liftNots: bestThenBranch == NEITHER);
    if (bestThenBranch == NEITHER && node.condition is Not) {
      node.condition = (node.condition as Not).operand;
      Statement tmp = node.thenStatement;
      node.thenStatement = node.elseStatement;
      node.elseStatement = tmp;
    }

    return node;
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    fallthrough.push(node.next);
    node.body = visitStatement(node.body);
    fallthrough.pop();
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    fallthrough.push(node);
    node.body = visitStatement(node.body);
    fallthrough.pop();
    return node;
  }

  Statement visitFor(For node) {
    fallthrough.push(node);
    node.condition = makeCondition(node.condition, true, liftNots: false);
    node.body = visitStatement(node.body);
    fallthrough.pop();
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitBreak(Break node) {
    if (isFallthroughBreak(node)) {
      fallthrough.use();
    }
    return node;
  }

  Statement visitContinue(Continue node) {
    if (isFallthroughContinue(node)) {
      fallthrough.use();
    }
    return node;
  }

  Statement visitReturn(Return node) {
    node.value = visitExpression(node.value);
    if (isFallthroughReturn(node)) {
      fallthrough.use();
    }
    return node;
  }

  Expression visitNot(Not node) {
    return toBoolean(makeCondition(node.operand, false, liftNots: false));
  }

  /// True if the only possible falsy return value of [condition] is [value].
  ///
  /// If [value] is `null` or a truthy value, false is returned. This is to make
  /// pattern matching more convenient.
  bool matchesFalsyValue(Expression condition, values.ConstantValue value) {
    if (value == null) return false;
    // TODO(asgerf): Here we could really use some more type information,
    //               this is just the best we can do at the moment.
    return isBooleanValued(condition) && value.isFalse;
  }

  /// True if the only possible truthy return value of [condition] is [value].
  ///
  /// If [value] is `null` or a falsy value, false is returned. This is to make
  /// pattern matching more convenient.
  bool matchesTruthyValue(Expression condition, values.ConstantValue value) {
    if (value == null) return false;
    // TODO(asgerf): Again, more type information could really beef this up.
    return isBooleanValued(condition) && value.isTrue;
  }

  values.ConstantValue getConstant(Expression exp) {
    return exp is Constant ? exp.value : null;
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

    // x ? y : false ==> x && y  (if x is truthy or false)
    // x ? y : null  ==> x && y  (if x is truthy or null)
    // x ? y : 0     ==> x && y  (if x is truthy or zero) (and so on...)
    if (matchesFalsyValue(node.condition, getConstant(node.elseExpression))) {
      return new LogicalOperator.and(
          visitExpression(node.condition),
          node.thenExpression);
    }
    // x ? true : y ==> x || y  (if x is falsy or true)
    // x ? 1    : y ==> x || y  (if x is falsy or one) (and so on...)
    if (matchesTruthyValue(node.condition, getConstant(node.thenExpression))) {
      return new LogicalOperator.or(
          visitExpression(node.condition),
          node.elseExpression);
    }
    // x ? y : true ==> !x || y
    if (isTrue(node.elseExpression)) {
      return new LogicalOperator.or(
          toBoolean(makeCondition(node.condition, false, liftNots: false)),
          node.thenExpression);
    }
    // x ? false : y ==> !x && y
    if (isFalse(node.thenExpression)) {
      return new LogicalOperator.and(
          toBoolean(makeCondition(node.condition, false, liftNots: false)),
          node.elseExpression);
    }

    node.condition = makeCondition(node.condition, true);

    // !x ? y : z ==> x ? z : y
    if (node.condition is Not) {
      node.condition = (node.condition as Not).operand;
      Expression tmp = node.thenExpression;
      node.thenExpression = node.elseExpression;
      node.elseExpression = tmp;
    }

    // x ? y : x ==> x && y
    if (isSameVariable(node.condition, node.elseExpression)) {
      destroyVariableUse(node.elseExpression);
      return new LogicalOperator.and(node.condition, node.thenExpression);
    }
    // x ? x : y ==> x || y
    if (isSameVariable(node.condition, node.thenExpression)) {
      destroyVariableUse(node.thenExpression);
      return new LogicalOperator.or(node.condition, node.elseExpression);
    }

    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);
    node.right = visitExpression(node.right);
    return node;
  }

  /// True if the given expression is known to evaluate to a boolean.
  /// This will not recursively traverse [Conditional] expressions, but if
  /// applied to the result of [visitExpression] conditionals will have been
  /// rewritten anyway.
  bool isBooleanValued(Expression e) {
    return isTrue(e) ||
           isFalse(e) ||
           e is Not ||
           e is LogicalOperator ||
           e is ApplyBuiltinOperator && operatorReturnsBool(e.operator);
  }

  /// True if the given operator always returns `true` or `false`.
  bool operatorReturnsBool(BuiltinOperator operator) {
    switch (operator) {
      case BuiltinOperator.StrictEq:
      case BuiltinOperator.StrictNeq:
      case BuiltinOperator.LooseEq:
      case BuiltinOperator.LooseNeq:
      case BuiltinOperator.NumLt:
      case BuiltinOperator.NumLe:
      case BuiltinOperator.NumGt:
      case BuiltinOperator.NumGe:
      case BuiltinOperator.IsNumber:
      case BuiltinOperator.IsNotNumber:
      case BuiltinOperator.IsFloor:
      case BuiltinOperator.IsNumberAndFloor:
      case BuiltinOperator.Identical:
        return true;
      default:
        return false;
    }
  }

  BuiltinOperator negateBuiltin(BuiltinOperator operator) {
    switch (operator) {
      case BuiltinOperator.StrictEq: return BuiltinOperator.StrictNeq;
      case BuiltinOperator.StrictNeq: return BuiltinOperator.StrictEq;
      case BuiltinOperator.LooseEq: return BuiltinOperator.LooseNeq;
      case BuiltinOperator.LooseNeq: return BuiltinOperator.LooseEq;
      case BuiltinOperator.IsNumber: return BuiltinOperator.IsNotNumber;
      case BuiltinOperator.IsNotNumber: return BuiltinOperator.IsNumber;

      // Because of NaN, these do not have a negated form.
      case BuiltinOperator.NumLt:
      case BuiltinOperator.NumLe:
      case BuiltinOperator.NumGt:
      case BuiltinOperator.NumGe:
        return null;

      default:
        return null;
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
  /// the root of the condition so they can be eliminated by the caller.
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
    if (e is ApplyBuiltinOperator && polarity == false) {
      BuiltinOperator negated = negateBuiltin(e.operator);
      if (negated != null) {
        e.operator = negated;
        return visitExpression(e);
      } else {
        return new Not(visitExpression(e));
      }
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

      // x ? y : x ==> x && y
      if (isSameVariable(e.condition, e.elseExpression)) {
        destroyVariableUse(e.elseExpression);
        return new LogicalOperator.and(e.condition, e.thenExpression);
      }
      // x ? x : y ==> x || y
      if (isSameVariable(e.condition, e.thenExpression)) {
        destroyVariableUse(e.thenExpression);
        return new LogicalOperator.or(e.condition, e.elseExpression);
      }

      return e;
    }
    if (e is Constant && e.value.isBool) {
      // !true ==> false
      if (!polarity) {
        values.BoolConstantValue value = e.value;
        return new Constant.bool(value.negate());
      }
      return e;
    }
    e = visitExpression(e);
    return polarity ? e : new Not(e);
  }

  bool isNull(Expression e) {
    return e is Constant && e.value.isNull;
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

  /// True if [e2] is known to return the same value as [e1] 
  /// (with no additional side effects) if evaluated immediately after [e1].
  /// 
  /// Concretely, this is true if [e1] and [e2] are uses of the same variable,
  /// or if [e2] is a use of a variable assigned by [e1].
  bool isSameVariable(Expression e1, Expression e2) {
    if (e1 is VariableUse) {
      return e2 is VariableUse && e1.variable == e2.variable;
    } else if (e1 is Assign) {
      return e2 is VariableUse && e1.variable == e2.variable;
    }
    return false;
  }

  void destroyVariableUse(VariableUse node) {
    --node.variable.readCount;
  }
}

