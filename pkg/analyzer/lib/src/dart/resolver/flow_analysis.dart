// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Sets of local variables that are potentially assigned in a statement.
///
/// These statements are loops, `switch`, and `try` statements.
class AssignedVariables<Statement, Variable> {
  final emptySet = Set<Variable>();

  /// Mapping from a [Statement] to the set of local variables that are
  /// potentially assigned in that statement.
  final Map<Statement, Set<Variable>> _map = {};

  /// The stack of nested statements.
  final List<Set<Variable>> _stack = [];

  AssignedVariables();

  /// Return the set of variables that are potentially assigned in the
  /// [statement].
  Set<Variable> operator [](Statement statement) {
    return _map[statement] ?? emptySet;
  }

  void beginStatement() {
    var set = Set<Variable>.identity();
    _stack.add(set);
  }

  void endStatement(Statement node) {
    _map[node] = _stack.removeLast();
  }

  void write(Variable variable) {
    for (var i = 0; i < _stack.length; ++i) {
      _stack[i].add(variable);
    }
  }
}

class FlowAnalysis<Statement, Expression, Variable, Type> {
  final _VariableSet<Variable> _emptySet;
  final State<Variable, Type> _identity;

  /// The [NodeOperations], used to manipulate expressions.
  final NodeOperations<Expression> nodeOperations;

  /// The [TypeOperations], used to access types, and check subtyping.
  final TypeOperations<Variable, Type> typeOperations;

  /// The enclosing function body, used to check for potential mutations.
  final FunctionBodyAccess<Variable> functionBody;

  /// The stack of states of variables that are not definitely assigned.
  final List<State<Variable, Type>> _stack = [];

  /// The mapping from labeled [Statement]s to the index in the [_stack]
  /// where the first related element is located.  The number of elements
  /// is statement specific.  Loops have two elements: `break` and `continue`
  /// states.
  final Map<Statement, int> _statementToStackIndex = {};

  /// The list of all variables.
  final List<Variable> _variables = [];

  State<Variable, Type> _current;

  /// The last boolean condition, for [_conditionTrue] and [_conditionFalse].
  Expression _condition;

  /// The state when [_condition] evaluates to `true`.
  State<Variable, Type> _conditionTrue;

  /// The state when [_condition] evaluates to `false`.
  State<Variable, Type> _conditionFalse;

  factory FlowAnalysis(
    NodeOperations<Expression> nodeOperations,
    TypeOperations<Variable, Type> typeOperations,
    FunctionBodyAccess<Variable> functionBody,
  ) {
    var identityState = State<Variable, Type>(false);
    var emptySet = identityState.notAssigned;
    return FlowAnalysis._(
      nodeOperations,
      typeOperations,
      functionBody,
      emptySet,
      identityState,
    );
  }

  FlowAnalysis._(
    this.nodeOperations,
    this.typeOperations,
    this.functionBody,
    this._emptySet,
    this._identity,
  ) {
    _current = State<Variable, Type>(true);
  }

  /// Return `true` if the current state is reachable.
  bool get isReachable => _current.reachable;

  /// Add a new [variable], which might be already [assigned].
  void add(Variable variable, {bool assigned: false}) {
    _variables.add(variable);
    _current = _current.add(variable, assigned: assigned);
  }

  void booleanLiteral(Expression expression, bool value) {
    _condition = expression;
    if (value) {
      _conditionTrue = _current;
      _conditionFalse = _identity;
    } else {
      _conditionTrue = _identity;
      _conditionFalse = _current;
    }
  }

  void conditional_elseBegin(Expression conditionalExpression,
      Expression thenExpression, bool isBool) {
    var afterThen = _current;
    var falseCondition = _stack.removeLast();

    if (isBool) {
      _conditionalEnd(thenExpression);
      // Tail of the stack: falseThen, trueThen
    }

    _stack.add(afterThen);
    _current = falseCondition;
  }

  void conditional_end(Expression conditionalExpression,
      Expression elseExpression, bool isBool) {
    var afterThen = _stack.removeLast();
    var afterElse = _current;

    if (isBool) {
      _conditionalEnd(elseExpression);
      // Tail of the stack: falseThen, trueThen, falseElse, trueElse

      var trueElse = _stack.removeLast();
      var falseElse = _stack.removeLast();

      var trueThen = _stack.removeLast();
      var falseThen = _stack.removeLast();

      var trueResult = _join(trueThen, trueElse);
      var falseResult = _join(falseThen, falseElse);

      _condition = conditionalExpression;
      _conditionTrue = trueResult;
      _conditionFalse = falseResult;
    }

    _current = _join(afterThen, afterElse);
  }

  void conditional_thenBegin(
      Expression conditionalExpression, Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  /// The [binaryExpression] checks that the [variable] is equal to `null`.
  void conditionEqNull(Expression binaryExpression, Variable variable) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = binaryExpression;
    _conditionTrue = _current;
    _conditionFalse = _current.markNonNullable(typeOperations, variable);
  }

  /// The [binaryExpression] checks that the [variable] is not equal to `null`.
  void conditionNotEqNull(Expression binaryExpression, Variable variable) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = binaryExpression;
    _conditionTrue = _current.markNonNullable(typeOperations, variable);
    _conditionFalse = _current;
  }

  void doStatement_bodyBegin(
      Statement doStatement, Set<Variable> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);

    _statementToStackIndex[doStatement] = _stack.length;
    _stack.add(_identity); // break
    _stack.add(_identity); // continue
  }

  void doStatement_conditionBegin() {
    // Tail of the stack: break, continue

    var continueState = _stack.removeLast();
    _current = _join(_current, continueState);
  }

  void doStatement_end(Statement doStatement, Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack:  break, falseCondition, trueCondition

    _stack.removeLast(); // trueCondition
    var falseCondition = _stack.removeLast();
    var breakState = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  void forEachStatement_bodyBegin(Set<Variable> loopAssigned) {
    _stack.add(_current);
    _current = _current.removePromotedAll(loopAssigned);
  }

  void forEachStatement_end() {
    var afterIterable = _stack.removeLast();
    _current = _join(_current, afterIterable);
  }

  void forStatement_bodyBegin(Statement node, Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();

    _statementToStackIndex[node] = _stack.length;
    _stack.add(_identity); // break
    _stack.add(_identity); // continue

    _current = trueCondition;
  }

  void forStatement_conditionBegin(Set<Variable> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);
  }

  void forStatement_end() {
    // Tail of the stack: falseCondition, break
    var breakState = _stack.removeLast();
    var falseCondition = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  void forStatement_updaterBegin() {
    // Tail of the stack: falseCondition, break, continue
    var afterBody = _current;
    var continueState = _stack.removeLast();

    _current = _join(afterBody, continueState);
  }

  void functionExpression_begin() {
    _stack.add(_current);

    Set<Variable> notPromoted = null;
    for (var variable in _current.promoted.keys) {
      if (functionBody.isPotentiallyMutatedInScope(variable)) {
        notPromoted ??= Set<Variable>.identity();
        notPromoted.add(variable);
      }
    }

    if (notPromoted != null) {
      _current = _current.removePromotedAll(notPromoted);
    }
  }

  void functionExpression_end() {
    _current = _stack.removeLast();
  }

  void handleBreak(Statement target) {
    var breakIndex = _statementToStackIndex[target];
    if (breakIndex != null) {
      _stack[breakIndex] = _join(_stack[breakIndex], _current);
    }
    _current = _current.exit();
  }

  void handleContinue(Statement target) {
    var breakIndex = _statementToStackIndex[target];
    if (breakIndex != null) {
      var continueIndex = breakIndex + 1;
      _stack[continueIndex] = _join(_stack[continueIndex], _current);
    }
    _current = _current.exit();
  }

  /// Register the fact that the current state definitely exists, e.g. returns
  /// from the body, throws an exception, etc.
  void handleExit() {
    _current = _current.exit();
  }

  void ifNullExpression_end() {
    var afterLeft = _stack.removeLast();
    _current = _join(_current, afterLeft);
  }

  void ifNullExpression_rightBegin() {
    _stack.add(_current); // afterLeft
  }

  void ifStatement_elseBegin() {
    var afterThen = _current;
    var falseCondition = _stack.removeLast();
    _stack.add(afterThen);
    _current = falseCondition;
  }

  void ifStatement_end(bool hasElse) {
    State<Variable, Type> afterThen;
    State<Variable, Type> afterElse;
    if (hasElse) {
      afterThen = _stack.removeLast();
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = _stack.removeLast(); // `falseCond` is still on the stack
    }
    _current = _join(afterThen, afterElse);
  }

  void ifStatement_thenBegin(Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack:  falseCondition, trueCondition

    var trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  /// Return whether the [variable] is definitely assigned in the current state.
  bool isAssigned(Variable variable) {
    return !_current.notAssigned.contains(variable);
  }

  void isExpression_end(
      Expression isExpression, Variable variable, bool isNot, Type type) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = isExpression;
    if (isNot) {
      _conditionTrue = _current;
      _conditionFalse = _current.promote(typeOperations, variable, type);
    } else {
      _conditionTrue = _current.promote(typeOperations, variable, type);
      _conditionFalse = _current;
    }
  }

  @visibleForTesting
  Map<Variable, Type> joinPromoted(
    Map<Variable, Type> first,
    Map<Variable, Type> second,
  ) {
    if (identical(first, second)) return first;
    if (first.isEmpty || second.isEmpty) return const {};

    var result = <Variable, Type>{};
    var alwaysFirst = true;
    var alwaysSecond = true;
    for (var variable in first.keys) {
      var firstType = first[variable];
      var secondType = second[variable];
      if (secondType != null) {
        if (identical(firstType, secondType)) {
          result[variable] = firstType;
        } else if (typeOperations.isSubtypeOf(firstType, secondType)) {
          result[variable] = secondType;
          alwaysFirst = false;
        } else if (typeOperations.isSubtypeOf(secondType, firstType)) {
          result[variable] = firstType;
          alwaysSecond = false;
        } else {
          alwaysFirst = false;
          alwaysSecond = false;
        }
      } else {
        alwaysFirst = false;
      }
    }

    if (alwaysFirst) return first;
    if (alwaysSecond && result.length == second.length) return second;
    if (result.isEmpty) return const {};
    return result;
  }

  void logicalAnd_end(Expression andExpression, Expression rightOperand) {
    _conditionalEnd(rightOperand);
    // Tail of the stack: falseLeft, trueLeft, falseRight, trueRight

    var trueRight = _stack.removeLast();
    var falseRight = _stack.removeLast();

    _stack.removeLast(); // trueLeft is not used
    var falseLeft = _stack.removeLast();

    var trueResult = trueRight;
    var falseResult = _join(falseLeft, falseRight);
    var afterResult = _join(trueResult, falseResult);

    _condition = andExpression;
    _conditionTrue = trueResult;
    _conditionFalse = falseResult;

    _current = afterResult;
  }

  void logicalAnd_rightBegin(Expression andExpression, Expression leftOperand) {
    _conditionalEnd(leftOperand);
    // Tail of the stack: falseLeft, trueLeft

    var trueLeft = _stack.last;
    _current = trueLeft;
  }

  void logicalNot_end(Expression notExpression, Expression operand) {
    _conditionalEnd(operand);
    var trueExpr = _stack.removeLast();
    var falseExpr = _stack.removeLast();

    _condition = notExpression;
    _conditionTrue = falseExpr;
    _conditionFalse = trueExpr;
  }

  void logicalOr_end(Expression orExpression, Expression rightOperand) {
    _conditionalEnd(rightOperand);
    // Tail of the stack: falseLeft, trueLeft, falseRight, trueRight

    var trueRight = _stack.removeLast();
    var falseRight = _stack.removeLast();

    var trueLeft = _stack.removeLast();
    _stack.removeLast(); // falseLeft is not used

    var trueResult = _join(trueLeft, trueRight);
    var falseResult = falseRight;
    var afterResult = _join(trueResult, falseResult);

    _condition = orExpression;
    _conditionTrue = trueResult;
    _conditionFalse = falseResult;

    _current = afterResult;
  }

  void logicalOr_rightBegin(Expression orExpression, Expression leftOperand) {
    _conditionalEnd(leftOperand);
    // Tail of the stack: falseLeft, trueLeft

    var falseLeft = _stack[_stack.length - 2];
    _current = falseLeft;
  }

  /// Retrieves the type that the [variable] is promoted to, if the [variable]
  /// is currently promoted.  Otherwise returns `null`.
  Type promotedType(Variable variable) {
    return _current.promoted[variable];
  }

  /// The [notPromoted] set contains all variables that are potentially
  /// assigned in other cases that might target this with `continue`, so
  /// these variables might have different types and are "un-promoted" from
  /// the "afterExpression" state.
  void switchStatement_beginCase(Set<Variable> notPromoted) {
    _current = _stack.last.removePromotedAll(notPromoted);
  }

  void switchStatement_end(Statement switchStatement, bool hasDefault) {
    // Tail of the stack: break, continue, afterExpression
    var afterExpression = _current = _stack.removeLast();
    _stack.removeLast(); // continue
    var breakState = _stack.removeLast();

    if (hasDefault) {
      _current = breakState;
    } else {
      _current = _join(breakState, afterExpression);
    }
  }

  void switchStatement_expressionEnd(Statement switchStatement) {
    _statementToStackIndex[switchStatement] = _stack.length;
    _stack.add(_identity); // break
    _stack.add(_identity); // continue
    _stack.add(_current); // afterExpression
  }

  void tryCatchStatement_bodyBegin() {
    _stack.add(_current);
    // Tail of the stack: beforeBody
  }

  void tryCatchStatement_bodyEnd(Set<Variable> assignedInBody) {
    var beforeBody = _stack.removeLast();
    var beforeCatch = beforeBody.removePromotedAll(assignedInBody);
    _stack.add(beforeCatch);
    _stack.add(_current); // afterBodyAndCatches
    // Tail of the stack: beforeCatch, afterBodyAndCatches
  }

  void tryCatchStatement_catchBegin() {
    var beforeCatch = _stack[_stack.length - 2];
    _current = beforeCatch;
  }

  void tryCatchStatement_catchEnd() {
    var afterBodyAndCatches = _stack.last;
    _stack.last = _join(afterBodyAndCatches, _current);
  }

  void tryCatchStatement_end() {
    var afterBodyAndCatches = _stack.removeLast();
    _stack.removeLast(); // beforeCatch
    _current = afterBodyAndCatches;
  }

  void tryFinallyStatement_bodyBegin() {
    _stack.add(_current); // beforeTry
  }

  void tryFinallyStatement_end(Set<Variable> assignedInFinally) {
    var afterBody = _stack.removeLast();
    _current = _current.restrict(
      typeOperations,
      _emptySet,
      afterBody,
      assignedInFinally,
    );
  }

  void tryFinallyStatement_finallyBegin(Set<Variable> assignedInBody) {
    var beforeTry = _stack.removeLast();
    var afterBody = _current;
    _stack.add(afterBody);
    _current = _join(afterBody, beforeTry.removePromotedAll(assignedInBody));
  }

  void verifyStackEmpty() {
    assert(_stack.isEmpty);
  }

  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();

    _statementToStackIndex[whileStatement] = _stack.length;
    _stack.add(_identity); // break
    _stack.add(_identity); // continue

    _current = trueCondition;
  }

  void whileStatement_conditionBegin(Set<Variable> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);
  }

  void whileStatement_end() {
    _stack.removeLast(); // continue
    var breakState = _stack.removeLast();
    var falseCondition = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  /// Register write of the given [variable] in the current state.
  void write(Variable variable) {
    _current = _current.write(typeOperations, _emptySet, variable);
  }

  void _conditionalEnd(Expression condition) {
    condition = nodeOperations.unwrapParenthesized(condition);
    if (identical(condition, _condition)) {
      _stack.add(_conditionFalse);
      _stack.add(_conditionTrue);
    } else {
      _stack.add(_current);
      _stack.add(_current);
    }
  }

  State<Variable, Type> _join(
    State<Variable, Type> first,
    State<Variable, Type> second,
  ) {
    if (identical(first, _identity)) return second;
    if (identical(second, _identity)) return first;

    if (first.reachable && !second.reachable) return first;
    if (!first.reachable && second.reachable) return second;

    var newReachable = first.reachable || second.reachable;
    var newNotAssigned = first.notAssigned.union(second.notAssigned);
    var newPromoted = joinPromoted(first.promoted, second.promoted);

    return State._identicalOrNew(
      first,
      second,
      newReachable,
      newNotAssigned,
      newPromoted,
    );
  }
}

/// Accessor for function body information.
abstract class FunctionBodyAccess<Variable> {
  bool isPotentiallyMutatedInClosure(Variable variable);

  bool isPotentiallyMutatedInScope(Variable variable);
}

/// Operations on nodes, abstracted from concrete node interfaces.
abstract class NodeOperations<Expression> {
  /// If the [node] is a parenthesized expression, recursively unwrap it.
  Expression unwrapParenthesized(Expression node);
}

@visibleForTesting
class State<Variable, Type> {
  final bool reachable;
  final _VariableSet<Variable> notAssigned;
  final Map<Variable, Type> promoted;

  State(bool reachable)
      : this._(
          reachable,
          _VariableSet<Variable>._(const []),
          const {},
        );

  State._(
    this.reachable,
    this.notAssigned,
    this.promoted,
  );

  /// Add a new [variable] to track definite assignment.
  State<Variable, Type> add(Variable variable, {bool assigned: false}) {
    var newNotAssigned = assigned ? notAssigned : notAssigned.add(variable);

    if (identical(newNotAssigned, notAssigned)) {
      return this;
    }

    return State<Variable, Type>._(
      reachable,
      newNotAssigned,
      promoted,
    );
  }

  State<Variable, Type> exit() {
    return State<Variable, Type>._(
      false,
      notAssigned,
      promoted,
    );
  }

  State<Variable, Type> markNonNullable(
      TypeOperations<Variable, Type> typeOperations, Variable variable) {
    var previousType = promoted[variable];
    previousType ??= typeOperations.variableType(variable);
    var type = typeOperations.promoteToNonNull(previousType);

    if (!typeOperations.isSameType(type, previousType)) {
      var newPromoted = <Variable, Type>{}..addAll(promoted);
      newPromoted[variable] = type;
      return State<Variable, Type>._(
        reachable,
        notAssigned,
        newPromoted,
      );
    }

    return this;
  }

  State<Variable, Type> promote(
    TypeOperations<Variable, Type> typeOperations,
    Variable variable,
    Type type,
  ) {
    var previousType = promoted[variable];
    previousType ??= typeOperations.variableType(variable);

    if (typeOperations.isSubtypeOf(type, previousType) &&
        !typeOperations.isSameType(type, previousType)) {
      var newPromoted = <Variable, Type>{}..addAll(promoted);
      newPromoted[variable] = type;
      return State<Variable, Type>._(
        reachable,
        notAssigned,
        newPromoted,
      );
    }

    return this;
  }

  State<Variable, Type> removePromotedAll(Set<Variable> variables) {
    var newPromoted = _removePromotedAll(promoted, variables);

    if (identical(newPromoted, promoted)) return this;

    return State<Variable, Type>._(
      reachable,
      notAssigned,
      newPromoted,
    );
  }

  State<Variable, Type> restrict(
    TypeOperations<Variable, Type> typeOperations,
    _VariableSet<Variable> emptySet,
    State<Variable, Type> other,
    Set<Variable> unsafe,
  ) {
    var newReachable = reachable && other.reachable;
    var newNotAssigned = notAssigned.intersect(
      empty: emptySet,
      other: other.notAssigned,
    );
    if (newNotAssigned.variables.length == notAssigned.variables.length) {
      newNotAssigned = notAssigned;
    } else if (newNotAssigned.variables.length ==
        other.notAssigned.variables.length) {
      newNotAssigned = other.notAssigned;
    }

    var newPromoted = <Variable, Type>{};
    bool promotedMatchesThis = true;
    bool promotedMatchesOther = true;
    for (var variable in Set<Variable>.from(promoted.keys)
      ..addAll(other.promoted.keys)) {
      var thisType = promoted[variable];
      var otherType = other.promoted[variable];
      if (!unsafe.contains(variable)) {
        if (otherType != null &&
            (thisType == null ||
                typeOperations.isSubtypeOf(otherType, thisType))) {
          newPromoted[variable] = otherType;
          if (promotedMatchesThis &&
              (thisType == null ||
                  !typeOperations.isSameType(thisType, otherType))) {
            promotedMatchesThis = false;
          }
          continue;
        }
      }
      if (thisType != null) {
        newPromoted[variable] = thisType;
        if (promotedMatchesOther &&
            (otherType == null ||
                !typeOperations.isSameType(thisType, otherType))) {
          promotedMatchesOther = false;
        }
      } else {
        if (promotedMatchesOther && otherType != null) {
          promotedMatchesOther = false;
        }
      }
    }
    assert(promotedMatchesThis ==
        _promotionsEqual(typeOperations, newPromoted, promoted));
    assert(promotedMatchesOther ==
        _promotionsEqual(typeOperations, newPromoted, other.promoted));
    if (promotedMatchesThis) {
      newPromoted = promoted;
    } else if (promotedMatchesOther) {
      newPromoted = other.promoted;
    }

    return _identicalOrNew(
      this,
      other,
      newReachable,
      newNotAssigned,
      newPromoted,
    );
  }

  State<Variable, Type> setReachable(bool reachable) {
    if (this.reachable == reachable) return this;

    return State<Variable, Type>._(
      reachable,
      notAssigned,
      promoted,
    );
  }

  @override
  String toString() => '($reachable, $notAssigned, $promoted)';

  State<Variable, Type> write(TypeOperations<Variable, Type> typeOperations,
      _VariableSet<Variable> emptySet, Variable variable) {
    var newNotAssigned = typeOperations.isLocalVariable(variable)
        ? notAssigned.remove(emptySet, variable)
        : notAssigned;

    var newPromoted = _removePromoted(promoted, variable);

    if (identical(newNotAssigned, notAssigned) &&
        identical(newPromoted, promoted)) {
      return this;
    }

    return State<Variable, Type>._(
      reachable,
      newNotAssigned,
      newPromoted,
    );
  }

  Map<Variable, Type> _removePromoted(
      Map<Variable, Type> map, Variable variable) {
    if (map.isEmpty) return const {};

    var result = <Variable, Type>{};
    for (var key in map.keys) {
      if (!identical(key, variable)) {
        result[key] = map[key];
      }
    }

    if (result.isEmpty) return const {};
    return result;
  }

  Map<Variable, Type> _removePromotedAll(
    Map<Variable, Type> map,
    Set<Variable> variables,
  ) {
    if (map.isEmpty) return const {};
    if (variables.isEmpty) return map;

    var result = <Variable, Type>{};
    var noChanges = true;
    for (var key in map.keys) {
      if (variables.contains(key)) {
        noChanges = false;
      } else {
        result[key] = map[key];
      }
    }

    if (noChanges) return map;
    if (result.isEmpty) return const {};
    return result;
  }

  static State<Variable, Type> _identicalOrNew<Variable, Type>(
    State<Variable, Type> first,
    State<Variable, Type> second,
    bool newReachable,
    _VariableSet<Variable> newNotAssigned,
    Map<Variable, Type> newPromoted,
  ) {
    if (first.reachable == newReachable &&
        identical(first.notAssigned, newNotAssigned) &&
        identical(first.promoted, newPromoted)) {
      return first;
    }
    if (second.reachable == newReachable &&
        identical(second.notAssigned, newNotAssigned) &&
        identical(second.promoted, newPromoted)) {
      return second;
    }

    return State<Variable, Type>._(
      newReachable,
      newNotAssigned,
      newPromoted,
    );
  }

  static bool _promotionsEqual<Variable, Type>(
      TypeOperations<Variable, Type> typeOperations,
      Map<Variable, Type> p1,
      Map<Variable, Type> p2) {
    if (p1.length != p2.length) return false;
    if (!p1.keys.toSet().containsAll(p2.keys)) return false;
    for (var entry in p1.entries) {
      var p1Value = entry.value;
      var p2Value = p2[entry.key];
      if (!typeOperations.isSameType(p1Value, p2Value)) return false;
    }
    return true;
  }
}

/// Operations on types, abstracted from concrete type interfaces.
abstract class TypeOperations<Variable, Type> {
  /// Return `true` if the [variable] is a local variable, not a parameter.
  bool isLocalVariable(Variable variable);

  /// Returns `true` if [type1] and [type2] are the same type.
  bool isSameType(Type type1, Type type2);

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  bool isSubtypeOf(Type leftType, Type rightType);

  /// Returns the non-null promoted version of [type].
  ///
  /// Note that some types don't have a non-nullable version (e.g.
  /// `FutureOr<int?>`), so [type] may be returned even if it is nullable.
  Type /*!*/ promoteToNonNull(Type type);

  /// Return the static type of the given [variable].
  Type variableType(Variable variable);
}

/// List based immutable set of variables.
class _VariableSet<Variable> {
  final List<Variable> variables;

  _VariableSet._(this.variables);

  _VariableSet<Variable> add(Variable addedVariable) {
    if (contains(addedVariable)) {
      return this;
    }

    var length = variables.length;
    var newVariables = List<Variable>(length + 1);
    for (var i = 0; i < length; ++i) {
      newVariables[i] = variables[i];
    }
    newVariables[length] = addedVariable;
    return _VariableSet._(newVariables);
  }

  _VariableSet<Variable> addAll(Iterable<Variable> variables) {
    var result = this;
    for (var variable in variables) {
      result = result.add(variable);
    }
    return result;
  }

  bool contains(Variable variable) {
    var length = variables.length;
    for (var i = 0; i < length; ++i) {
      if (identical(variables[i], variable)) {
        return true;
      }
    }
    return false;
  }

  _VariableSet<Variable> intersect({
    _VariableSet<Variable> empty,
    _VariableSet<Variable> other,
  }) {
    if (identical(other, empty)) return empty;
    if (identical(this, other)) return this;

    // TODO(scheglov) optimize
    var newVariables =
        variables.toSet().intersection(other.variables.toSet()).toList();

    if (newVariables.isEmpty) return empty;
    return _VariableSet._(newVariables);
  }

  _VariableSet<Variable> remove(
    _VariableSet<Variable> empty,
    Variable removedVariable,
  ) {
    if (!contains(removedVariable)) {
      return this;
    }

    var length = variables.length;
    if (length == 1) {
      return empty;
    }

    var newVariables = List<Variable>(length - 1);
    var newIndex = 0;
    for (var i = 0; i < length; ++i) {
      var variable = variables[i];
      if (!identical(variable, removedVariable)) {
        newVariables[newIndex++] = variable;
      }
    }

    return _VariableSet._(newVariables);
  }

  @override
  String toString() => variables.isEmpty ? '{}' : '{ ${variables.join(', ')} }';

  _VariableSet<Variable> union(_VariableSet<Variable> other) {
    if (other.variables.isEmpty) {
      return this;
    }

    var result = this;
    var otherVariables = other.variables;
    for (var i = 0; i < otherVariables.length; ++i) {
      var otherVariable = otherVariables[i];
      result = result.add(otherVariable);
    }
    return result;
  }
}
