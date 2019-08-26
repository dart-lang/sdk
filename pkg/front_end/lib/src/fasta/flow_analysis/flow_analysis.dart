// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Sets of local variables that are potentially assigned in a loop statement,
/// switch statement, try statement, or loop collection element.
class AssignedVariables<StatementOrElement, Variable> {
  /// Mapping from a statement or element to the set of local variables that
  /// are potentially assigned in that statement or element.
  final Map<StatementOrElement, Set<Variable>> _map = {};

  /// The stack of nested statements or collection elements.
  final List<Set<Variable>> _stack = [];

  AssignedVariables();

  /// Return the set of variables that are potentially assigned in the
  /// [statementOrElement].
  Set<Variable> operator [](StatementOrElement statementOrElement) {
    return _map[statementOrElement] ?? const {};
  }

  void beginStatementOrElement() {
    Set<Variable> set = Set<Variable>.identity();
    _stack.add(set);
  }

  void endStatementOrElement(StatementOrElement node) {
    _map[node] = _stack.removeLast();
  }

  void write(Variable variable) {
    for (int i = 0; i < _stack.length; ++i) {
      _stack[i].add(variable);
    }
  }
}

class FlowAnalysis<Statement, Expression, Variable, Type> {
  static bool get _assertionsEnabled {
    bool result = false;
    assert(result = true);
    return result;
  }

  final _VariableSet<Variable> _emptySet;

  /// The [NodeOperations], used to manipulate expressions.
  final NodeOperations<Expression> nodeOperations;

  /// The [TypeOperations], used to access types, and check subtyping.
  final TypeOperations<Variable, Type> typeOperations;

  /// The enclosing function body, used to check for potential mutations.
  final FunctionBodyAccess<Variable> functionBody;

  /// The stack of states of variables that are not definitely assigned.
  final List<FlowModel<Variable, Type>> _stack = [];

  /// The mapping from labeled [Statement]s to the index in the [_stack]
  /// where the first related element is located.  The number of elements
  /// is statement specific.  Loops have two elements: `break` and `continue`
  /// states.
  final Map<Statement, int> _statementToStackIndex = {};

  /// List of all variables passed to [add].
  final List<Variable> _addedVariables = [];

  FlowModel<Variable, Type> _current;

  /// The last boolean condition, for [_conditionTrue] and [_conditionFalse].
  Expression _condition;

  /// The state when [_condition] evaluates to `true`.
  FlowModel<Variable, Type> _conditionTrue;

  /// The state when [_condition] evaluates to `false`.
  FlowModel<Variable, Type> _conditionFalse;

  /// If assertions are enabled, keeps track of all variables that have been
  /// passed into the API (other than through a call to [add]).  The [finish]
  /// method uses this to verify that the caller doesn't forget to pass a
  /// variable to [add].
  ///
  /// Note: the reason we have to keep track of this set (rather than simply
  /// checking each variable at the time it is passed into the API) is because
  /// the client doesn't call `add` until a variable is declared, and in
  /// erroneous code, it's possible that a variable might be used before its
  /// declaration.
  final Set<Variable> _referencedVariables =
      _assertionsEnabled ? Set<Variable>() : null;

  factory FlowAnalysis(
    NodeOperations<Expression> nodeOperations,
    TypeOperations<Variable, Type> typeOperations,
    FunctionBodyAccess<Variable> functionBody,
  ) {
    _VariableSet<Variable> emptySet =
        FlowModel<Variable, Type>(false).notAssigned;
    return FlowAnalysis._(
      nodeOperations,
      typeOperations,
      functionBody,
      emptySet,
    );
  }

  FlowAnalysis._(
    this.nodeOperations,
    this.typeOperations,
    this.functionBody,
    this._emptySet,
  ) {
    _current = FlowModel<Variable, Type>(true);
  }

  /// Return `true` if the current state is reachable.
  bool get isReachable => _current.reachable;

  /// Add a new [variable], which might be already [assigned].
  void add(Variable variable, {bool assigned: false}) {
    _addedVariables.add(variable);
    _current = _current.add(variable, assigned: assigned);
  }

  void booleanLiteral(Expression expression, bool value) {
    _condition = expression;
    if (value) {
      _conditionTrue = _current;
      _conditionFalse = _current.setReachable(false);
    } else {
      _conditionTrue = _current.setReachable(false);
      _conditionFalse = _current;
    }
  }

  void conditional_elseBegin(Expression thenExpression) {
    FlowModel<Variable, Type> afterThen = _current;
    FlowModel<Variable, Type> falseCondition = _stack.removeLast();

    _conditionalEnd(thenExpression);
    // Tail of the stack: falseThen, trueThen

    _stack.add(afterThen);
    _current = falseCondition;
  }

  void conditional_end(
      Expression conditionalExpression, Expression elseExpression) {
    FlowModel<Variable, Type> afterThen = _stack.removeLast();
    FlowModel<Variable, Type> afterElse = _current;

    _conditionalEnd(elseExpression);
    // Tail of the stack: falseThen, trueThen, falseElse, trueElse

    FlowModel<Variable, Type> trueElse = _stack.removeLast();
    FlowModel<Variable, Type> falseElse = _stack.removeLast();

    FlowModel<Variable, Type> trueThen = _stack.removeLast();
    FlowModel<Variable, Type> falseThen = _stack.removeLast();

    FlowModel<Variable, Type> trueResult = _join(trueThen, trueElse);
    FlowModel<Variable, Type> falseResult = _join(falseThen, falseElse);

    _condition = conditionalExpression;
    _conditionTrue = trueResult;
    _conditionFalse = falseResult;

    _current = _join(afterThen, afterElse);
  }

  void conditional_thenBegin(Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack: falseCondition, trueCondition

    FlowModel<Variable, Type> trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  /// The [binaryExpression] checks that the [variable] is, or is not, equal to
  /// `null`.
  void conditionEqNull(Expression binaryExpression, Variable variable,
      {bool notEqual: false}) {
    _variableReferenced(variable);
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = binaryExpression;
    FlowModel<Variable, Type> currentModel =
        _current.markNonNullable(typeOperations, variable);
    if (notEqual) {
      _conditionTrue = currentModel;
      _conditionFalse = _current;
    } else {
      _conditionTrue = _current;
      _conditionFalse = currentModel;
    }
  }

  void doStatement_bodyBegin(
      Statement doStatement, Iterable<Variable> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned, _referencedVariables);

    _statementToStackIndex[doStatement] = _stack.length;
    _stack.add(null); // break
    _stack.add(null); // continue
  }

  void doStatement_conditionBegin() {
    // Tail of the stack: break, continue

    FlowModel<Variable, Type> continueState = _stack.removeLast();
    _current = _join(_current, continueState);
  }

  void doStatement_end(Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack:  break, falseCondition, trueCondition

    _stack.removeLast(); // trueCondition
    FlowModel<Variable, Type> falseCondition = _stack.removeLast();
    FlowModel<Variable, Type> breakState = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  /// This method should be called at the conclusion of flow analysis for a top
  /// level function or method.  Performs assertion checks.
  void finish() {
    assert(_stack.isEmpty);
    assert(() {
      Set<Variable> variablesNotAdded =
          _referencedVariables.difference(Set<Variable>.from(_addedVariables));
      assert(variablesNotAdded.isEmpty,
          'Variables not passed to add: $variablesNotAdded');
      return true;
    }());
  }

  /// Call this method just before visiting the body of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  ///
  /// If a "for" statement is being entered, [node] is an opaque representation
  /// of the loop, for use as the target of future calls to [handleBreak] or
  /// [handleContinue].  If a "for" collection element is being entered, [node]
  /// should be `null`.
  ///
  /// [condition] is an opaque representation of the loop condition; it is
  /// matched against expressions passed to previous calls to determine whether
  /// the loop condition should cause any promotions to occur.  If [condition]
  /// is null, the condition is understood to be empty (equivalent to a
  /// condition of `true`).
  void for_bodyBegin(Statement node, Expression condition) {
    FlowModel<Variable, Type> trueCondition;
    if (condition == null) {
      trueCondition = _current;
      _stack.add(_current.setReachable(false));
    } else {
      _conditionalEnd(condition);
      // Tail of the stack: falseCondition, trueCondition

      trueCondition = _stack.removeLast();
    }
    // Tail of the stack: falseCondition

    if (node != null) {
      _statementToStackIndex[node] = _stack.length;
    }
    _stack.add(null); // break
    _stack.add(null); // continue

    _current = trueCondition;
  }

  /// Call this method just before visiting the condition of a conventional
  /// "for" statement or collection element.
  ///
  /// Note that a conventional "for" statement is a statement of the form
  /// `for (initializers; condition; updaters) body`.  Statements of the form
  /// `for (variable in iterable) body` should use [forEach_bodyBegin].  Similar
  /// for "for" collection elements.
  ///
  /// The order of visiting a "for" statement or collection element should be:
  /// - Visit the initializers.
  /// - Call [for_conditionBegin].
  /// - Visit the condition.
  /// - Call [for_bodyBegin].
  /// - Visit the body.
  /// - Call [for_updaterBegin].
  /// - Visit the updaters.
  /// - Call [for_end].
  ///
  /// [loopAssigned] should be the set of variables that are assigned anywhere
  /// in the loop's condition, updaters, or body.
  void for_conditionBegin(Set<Variable> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned, _referencedVariables);
  }

  /// Call this method just after visiting the updaters of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  void for_end() {
    // Tail of the stack: falseCondition, break
    FlowModel<Variable, Type> breakState = _stack.removeLast();
    FlowModel<Variable, Type> falseCondition = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  /// Call this method just before visiting the updaters of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  void for_updaterBegin() {
    // Tail of the stack: falseCondition, break, continue
    FlowModel<Variable, Type> afterBody = _current;
    FlowModel<Variable, Type> continueState = _stack.removeLast();

    _current = _join(afterBody, continueState);
  }

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.
  ///
  /// The order of visiting a "for-in" statement or collection element should
  /// be:
  /// - Visit the iterable expression.
  /// - Call [forEach_bodyBegin].
  /// - Visit the body.
  /// - Call [forEach_end].
  ///
  /// [loopAssigned] should be the set of variables that are assigned anywhere
  /// in the loop's body.
  void forEach_bodyBegin(Set<Variable> loopAssigned) {
    _stack.add(_current);
    _current = _current.removePromotedAll(loopAssigned, _referencedVariables);
  }

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.  See [forEach_bodyBegin] for details.
  void forEach_end() {
    FlowModel<Variable, Type> afterIterable = _stack.removeLast();
    _current = _join(_current, afterIterable);
  }

  void functionExpression_begin() {
    _stack.add(_current);

    List<Variable> notPromoted = [];
    for (MapEntry<Variable, VariableModel<Type>> entry
        in _current.variableInfo.entries) {
      Variable variable = entry.key;
      Type promotedType = entry.value.promotedType;
      if (promotedType != null &&
          functionBody.isPotentiallyMutatedInScope(variable)) {
        notPromoted.add(variable);
      }
    }

    if (notPromoted.isNotEmpty) {
      _current = _current.removePromotedAll(notPromoted, null);
    }
  }

  void functionExpression_end() {
    _current = _stack.removeLast();
  }

  void handleBreak(Statement target) {
    int breakIndex = _statementToStackIndex[target];
    if (breakIndex != null) {
      _stack[breakIndex] = _join(_stack[breakIndex], _current);
    }
    _current = _current.setReachable(false);
  }

  void handleContinue(Statement target) {
    int breakIndex = _statementToStackIndex[target];
    if (breakIndex != null) {
      int continueIndex = breakIndex + 1;
      _stack[continueIndex] = _join(_stack[continueIndex], _current);
    }
    _current = _current.setReachable(false);
  }

  /// Register the fact that the current state definitely exists, e.g. returns
  /// from the body, throws an exception, etc.
  void handleExit() {
    _current = _current.setReachable(false);
  }

  void ifNullExpression_end() {
    FlowModel<Variable, Type> afterLeft = _stack.removeLast();
    _current = _join(_current, afterLeft);
  }

  void ifNullExpression_rightBegin() {
    _stack.add(_current); // afterLeft
  }

  void ifStatement_elseBegin() {
    FlowModel<Variable, Type> afterThen = _current;
    FlowModel<Variable, Type> falseCondition = _stack.removeLast();
    _stack.add(afterThen);
    _current = falseCondition;
  }

  void ifStatement_end(bool hasElse) {
    FlowModel<Variable, Type> afterThen;
    FlowModel<Variable, Type> afterElse;
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

    FlowModel<Variable, Type> trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  /// Return whether the [variable] is definitely assigned in the current state.
  bool isAssigned(Variable variable) {
    _variableReferenced(variable);
    return !_current.notAssigned.contains(variable);
  }

  void isExpression_end(
      Expression isExpression, Variable variable, bool isNot, Type type) {
    _variableReferenced(variable);
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

  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {@required bool isAnd}) {
    _conditionalEnd(rightOperand);
    // Tail of the stack: falseLeft, trueLeft, falseRight, trueRight

    FlowModel<Variable, Type> trueRight = _stack.removeLast();
    FlowModel<Variable, Type> falseRight = _stack.removeLast();

    FlowModel<Variable, Type> trueLeft = _stack.removeLast();
    FlowModel<Variable, Type> falseLeft = _stack.removeLast();

    FlowModel<Variable, Type> trueResult;
    FlowModel<Variable, Type> falseResult;
    if (isAnd) {
      trueResult = trueRight;
      falseResult = _join(falseLeft, falseRight);
    } else {
      trueResult = _join(trueLeft, trueRight);
      falseResult = falseRight;
    }

    FlowModel<Variable, Type> afterResult = _join(trueResult, falseResult);

    _condition = wholeExpression;
    _conditionTrue = trueResult;
    _conditionFalse = falseResult;

    _current = afterResult;
  }

  void logicalBinaryOp_rightBegin(Expression leftOperand,
      {@required bool isAnd}) {
    _conditionalEnd(leftOperand);
    // Tail of the stack: falseLeft, trueLeft

    if (isAnd) {
      FlowModel<Variable, Type> trueLeft = _stack.last;
      _current = trueLeft;
    } else {
      FlowModel<Variable, Type> falseLeft = _stack[_stack.length - 2];
      _current = falseLeft;
    }
  }

  void logicalNot_end(Expression notExpression, Expression operand) {
    _conditionalEnd(operand);
    FlowModel<Variable, Type> trueExpr = _stack.removeLast();
    FlowModel<Variable, Type> falseExpr = _stack.removeLast();

    _condition = notExpression;
    _conditionTrue = falseExpr;
    _conditionFalse = trueExpr;
  }

  /// Retrieves the type that the [variable] is promoted to, if the [variable]
  /// is currently promoted.  Otherwise returns `null`.
  Type promotedType(Variable variable) {
    _variableReferenced(variable);
    return _current.variableInfo[variable]?.promotedType;
  }

  /// Call this method just before visiting one of the cases in the body of a
  /// switch statement.  See [switchStatement_expressionEnd] for details.
  ///
  /// [hasLabel] indicates whether the case has any labels.
  ///
  /// The [notPromoted] set contains all variables that are potentially assigned
  /// within the body of the switch statement.
  void switchStatement_beginCase(
      bool hasLabel, Iterable<Variable> notPromoted) {
    if (hasLabel) {
      _current =
          _stack.last.removePromotedAll(notPromoted, _referencedVariables);
    } else {
      _current = _stack.last;
    }
  }

  /// Call this method just after visiting the body of a switch statement.  See
  /// [switchStatement_expressionEnd] for details.
  ///
  /// [hasDefault] indicates whether the switch statement had a "default" case.
  void switchStatement_end(bool hasDefault) {
    // Tail of the stack: break, continue, afterExpression
    FlowModel<Variable, Type> afterExpression = _stack.removeLast();
    _stack.removeLast(); // continue
    FlowModel<Variable, Type> breakState = _stack.removeLast();

    // It is allowed to "fall off" the end of a switch statement, so join the
    // current state to any breaks that were found previously.
    breakState = _join(breakState, _current);

    // And, if there is an implicit fall-through default, join it to any breaks.
    if (!hasDefault) breakState = _join(breakState, afterExpression);

    _current = breakState;
  }

  /// Call this method just after visiting the expression part of a switch
  /// statement.
  ///
  /// The order of visiting a switch statement should be:
  /// - Visit the switch expression.
  /// - Call [switchStatement_expressionEnd].
  /// - For each switch case (including the default case, if any):
  ///   - Call [switchStatement_beginCase].
  ///   - Visit the case.
  /// - Call [switchStatement_end].
  void switchStatement_expressionEnd(Statement switchStatement) {
    _statementToStackIndex[switchStatement] = _stack.length;
    _stack.add(null); // break
    _stack.add(null); // continue
    _stack.add(_current); // afterExpression
  }

  void tryCatchStatement_bodyBegin() {
    _stack.add(_current);
    // Tail of the stack: beforeBody
  }

  void tryCatchStatement_bodyEnd(Iterable<Variable> assignedInBody) {
    FlowModel<Variable, Type> beforeBody = _stack.removeLast();
    FlowModel<Variable, Type> beforeCatch =
        beforeBody.removePromotedAll(assignedInBody, _referencedVariables);
    _stack.add(beforeCatch);
    _stack.add(_current); // afterBodyAndCatches
    // Tail of the stack: beforeCatch, afterBodyAndCatches
  }

  void tryCatchStatement_catchBegin() {
    FlowModel<Variable, Type> beforeCatch = _stack[_stack.length - 2];
    _current = beforeCatch;
  }

  void tryCatchStatement_catchEnd() {
    FlowModel<Variable, Type> afterBodyAndCatches = _stack.last;
    _stack.last = _join(afterBodyAndCatches, _current);
  }

  void tryCatchStatement_end() {
    FlowModel<Variable, Type> afterBodyAndCatches = _stack.removeLast();
    _stack.removeLast(); // beforeCatch
    _current = afterBodyAndCatches;
  }

  void tryFinallyStatement_bodyBegin() {
    _stack.add(_current); // beforeTry
  }

  void tryFinallyStatement_end(Set<Variable> assignedInFinally) {
    _variablesReferenced(assignedInFinally);
    FlowModel<Variable, Type> afterBody = _stack.removeLast();
    _current = _current.restrict(
      typeOperations,
      _emptySet,
      afterBody,
      assignedInFinally,
    );
  }

  void tryFinallyStatement_finallyBegin(Iterable<Variable> assignedInBody) {
    FlowModel<Variable, Type> beforeTry = _stack.removeLast();
    FlowModel<Variable, Type> afterBody = _current;
    _stack.add(afterBody);
    _current = _join(afterBody,
        beforeTry.removePromotedAll(assignedInBody, _referencedVariables));
  }

  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack: falseCondition, trueCondition

    FlowModel<Variable, Type> trueCondition = _stack.removeLast();

    _statementToStackIndex[whileStatement] = _stack.length;
    _stack.add(null); // break
    _stack.add(null); // continue

    _current = trueCondition;
  }

  void whileStatement_conditionBegin(Iterable<Variable> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned, _referencedVariables);
  }

  void whileStatement_end() {
    _stack.removeLast(); // continue
    FlowModel<Variable, Type> breakState = _stack.removeLast();
    FlowModel<Variable, Type> falseCondition = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  /// Register write of the given [variable] in the current state.
  void write(Variable variable) {
    _variableReferenced(variable);
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

  FlowModel<Variable, Type> _join(
          FlowModel<Variable, Type> first, FlowModel<Variable, Type> second) =>
      FlowModel.join(typeOperations, first, second);

  /// If assertions are enabled, records that the given variable has been
  /// referenced.  The [finish] method will verify that all referenced variables
  /// were eventually passed to [add].
  void _variableReferenced(Variable variable) {
    assert(() {
      _referencedVariables.add(variable);
      return true;
    }());
  }

  /// If assertions are enabled, records that the given variables have been
  /// referenced.  The [finish] method will verify that all referenced variables
  /// were eventually passed to [add].
  void _variablesReferenced(Iterable<Variable> variables) {
    assert(() {
      _referencedVariables.addAll(variables);
      return true;
    }());
  }
}

/// An instance of the [FlowModel] class represents the information gathered by
/// flow analysis at a single point in the control flow of the function or
/// method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class FlowModel<Variable, Type> {
  /// Indicates whether this point in the control flow is reachable.
  final bool reachable;

  /// The set of variables that are not yet definitely assigned at this point in
  /// the control flow.
  final _VariableSet<Variable> notAssigned;

  /// For each variable being tracked by flow analysis, the variable's model.
  ///
  /// Flow analysis has no awareness of scope, so variables that are out of
  /// scope are retained in the map until such time as their declaration no
  /// longer dominates the control flow.  So, for example, if a variable is
  /// declared inside the `then` branch of an `if` statement, and the `else`
  /// branch of the `if` statement ends in a `return` statement, then the
  /// variable remains in the map after the `if` statement ends, even though the
  /// variable is not in scope anymore.  This should not have any effect on
  /// analysis results for error-free code, because it is an error to refer to a
  /// variable that is no longer in scope.
  final Map<Variable, VariableModel<Type> /*!*/ > variableInfo;

  /// Creates a state object with the given [reachable] status.  All variables
  /// are assumed to be unpromoted and already assigned, so joining another
  /// state with this one will have no effect on it.
  FlowModel(bool reachable)
      : this._(
          reachable,
          _VariableSet<Variable>._(const []),
          const {},
        );

  FlowModel._(
    this.reachable,
    this.notAssigned,
    this.variableInfo,
  ) {
    assert(() {
      for (VariableModel<Type> value in variableInfo.values) {
        assert(value != null);
      }
      return true;
    }());
  }

  /// Updates the state to track a newly declared local [variable].  The
  /// optional [assigned] boolean indicates whether the variable is assigned at
  /// the point of declaration.
  FlowModel<Variable, Type> add(Variable variable, {bool assigned: false}) {
    _VariableSet<Variable> newNotAssigned =
        assigned ? notAssigned : notAssigned.add(variable);
    Map<Variable, VariableModel<Type>> newVariableInfo =
        Map<Variable, VariableModel<Type>>.from(variableInfo);
    newVariableInfo[variable] = VariableModel<Type>(null);

    return FlowModel<Variable, Type>._(
      reachable,
      newNotAssigned,
      newVariableInfo,
    );
  }

  /// Updates the state to indicate that the given [variable] has been
  /// determined to contain a non-null value.
  ///
  /// TODO(paulberry): should this method mark the variable as definitely
  /// assigned?  Does it matter?
  FlowModel<Variable, Type> markNonNullable(
      TypeOperations<Variable, Type> typeOperations, Variable variable) {
    VariableModel<Type> info = variableInfo[variable];
    Type previousType = info.promotedType;
    previousType ??= typeOperations.variableType(variable);
    Type type = typeOperations.promoteToNonNull(previousType);
    if (typeOperations.isSameType(type, previousType)) return this;
    return _updateVariableInfo(variable, info.withPromotedType(type));
  }

  /// Updates the state to indicate that the given [variable] has been
  /// determined to satisfy the given [type], e.g. as a consequence of an `is`
  /// expression as the condition of an `if` statement.
  ///
  /// Note that the state is only changed if [type] is a subtype of the
  /// variable's previous (possibly promoted) type.
  ///
  /// TODO(paulberry): if the type is non-nullable, should this method mark the
  /// variable as definitely assigned?  Does it matter?
  FlowModel<Variable, Type> promote(
    TypeOperations<Variable, Type> typeOperations,
    Variable variable,
    Type type,
  ) {
    VariableModel<Type> info = variableInfo[variable];
    Type previousType = info.promotedType;
    previousType ??= typeOperations.variableType(variable);

    if (!typeOperations.isSubtypeOf(type, previousType) ||
        typeOperations.isSameType(type, previousType)) {
      return this;
    }
    return _updateVariableInfo(variable, info.withPromotedType(type));
  }

  /// Updates the state to indicate that the given [variables] are no longer
  /// promoted; they are presumed to have their declared types.
  ///
  /// If assertions are enabled and [referencedVariables] is not `null`, all
  /// variables in [variables] will be stored in [referencedVariables] as a side
  /// effect of this call.
  ///
  /// This is used at the top of loops to conservatively cancel the promotion of
  /// variables that are modified within the loop, so that we correctly analyze
  /// code like the following:
  ///
  ///     if (x is int) {
  ///       x.isEven; // OK, promoted to int
  ///       while (true) {
  ///         x.isEven; // ERROR: promotion lost
  ///         x = 'foo';
  ///       }
  ///     }
  ///
  /// Note that a more accurate analysis would be to iterate to a fixed point,
  /// and only remove promotions if it can be shown that they aren't restored
  /// later in the loop body.  If we switch to a fixed point analysis, we should
  /// be able to remove this method.
  FlowModel<Variable, Type> removePromotedAll(
      Iterable<Variable> variables, Set<Variable> referencedVariables) {
    Map<Variable, VariableModel<Type>> newVariableInfo =
        _removePromotedAll(variableInfo, variables, referencedVariables);

    if (identical(newVariableInfo, variableInfo)) return this;

    return FlowModel<Variable, Type>._(
      reachable,
      notAssigned,
      newVariableInfo,
    );
  }

  /// Updates the state to reflect a control path that is known to have
  /// previously passed through some [other] state.
  ///
  /// Approximately, this method forms the union of the definite assignments and
  /// promotions in `this` state and the [other] state.  More precisely:
  ///
  /// The control flow path is considered reachable if both this state and the
  /// other state are reachable.  Variables are considered definitely assigned
  /// if they were definitely assigned in either this state or the other state.
  /// Variable type promotions are taken from this state, unless the promotion
  /// in the other state is more specific, and the variable is "safe".  A
  /// variable is considered safe if there is no chance that it was assigned
  /// more recently than the "other" state.
  ///
  /// This is used after a `try/finally` statement to combine the promotions and
  /// definite assignments that occurred in the `try` and `finally` blocks
  /// (where `this` is the state from the `finally` block and `other` is the
  /// state from the `try` block).  Variables that are assigned in the `finally`
  /// block are considered "unsafe" because the assignment might have cancelled
  /// the effect of any promotion that occurred inside the `try` block.
  FlowModel<Variable, Type> restrict(
    TypeOperations<Variable, Type> typeOperations,
    _VariableSet<Variable> emptySet,
    FlowModel<Variable, Type> other,
    Set<Variable> unsafe,
  ) {
    bool newReachable = reachable && other.reachable;
    _VariableSet<Variable> newNotAssigned = notAssigned.intersect(
      empty: emptySet,
      other: other.notAssigned,
    );
    if (newNotAssigned.variables.length == notAssigned.variables.length) {
      newNotAssigned = notAssigned;
    } else if (newNotAssigned.variables.length ==
        other.notAssigned.variables.length) {
      newNotAssigned = other.notAssigned;
    }

    Map<Variable, VariableModel<Type>> newVariableInfo =
        <Variable, VariableModel<Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesOther =
        other.variableInfo.length == variableInfo.length;
    for (MapEntry<Variable, VariableModel<Type>> entry
        in variableInfo.entries) {
      Variable variable = entry.key;
      VariableModel<Type> otherModel = other.variableInfo[variable];
      VariableModel<Type> restricted = entry.value
          .restrict(typeOperations, otherModel, unsafe.contains(variable));
      newVariableInfo[variable] = restricted;
      if (!identical(restricted, entry.value)) variableInfoMatchesThis = false;
      if (!identical(restricted, otherModel)) variableInfoMatchesOther = false;
    }
    assert(variableInfoMatchesThis ==
        _variableInfosEqual(typeOperations, newVariableInfo, variableInfo));
    assert(variableInfoMatchesOther ==
        _variableInfosEqual(
            typeOperations, newVariableInfo, other.variableInfo));
    if (variableInfoMatchesThis) {
      newVariableInfo = variableInfo;
    } else if (variableInfoMatchesOther) {
      newVariableInfo = other.variableInfo;
    }

    return _identicalOrNew(
      this,
      other,
      newReachable,
      newNotAssigned,
      newVariableInfo,
    );
  }

  /// Updates the state to indicate whether the control flow path is
  /// [reachable].
  FlowModel<Variable, Type> setReachable(bool reachable) {
    if (this.reachable == reachable) return this;

    return FlowModel<Variable, Type>._(
      reachable,
      notAssigned,
      variableInfo,
    );
  }

  @override
  String toString() => '($reachable, $notAssigned, $variableInfo)';

  /// Updates the state to indicate that an assignment was made to the given
  /// [variable].  The variable is marked as definitely assigned, and any
  /// previous type promotion is removed.
  ///
  /// TODO(paulberry): allow for writes that preserve type promotions.
  FlowModel<Variable, Type> write(TypeOperations<Variable, Type> typeOperations,
      _VariableSet<Variable> emptySet, Variable variable) {
    _VariableSet<Variable> newNotAssigned =
        typeOperations.isLocalVariable(variable)
            ? notAssigned.remove(emptySet, variable)
            : notAssigned;

    Map<Variable, VariableModel<Type>> newVariableInfo =
        _removePromoted(variableInfo, variable);

    if (identical(newNotAssigned, notAssigned) &&
        identical(newVariableInfo, variableInfo)) {
      return this;
    }

    return FlowModel<Variable, Type>._(
      reachable,
      newNotAssigned,
      newVariableInfo,
    );
  }

  /// Updates a "variableInfo" [map] to indicate that a [variable] is no longer
  /// promoted, treating the map as immutable.
  Map<Variable, VariableModel<Type>> _removePromoted(
      Map<Variable, VariableModel<Type>> map, Variable variable) {
    VariableModel<Type> info = map[variable];
    if (info.promotedType == null) return map;

    Map<Variable, VariableModel<Type>> result =
        Map<Variable, VariableModel<Type>>.from(map);
    result[variable] = info.withPromotedType(null);
    return result;
  }

  /// Updates a "variableInfo" [map] to indicate that a set of [variable] is no
  /// longer promoted, treating the map as immutable.
  ///
  /// If assertions are enabled and [referencedVariables] is not `null`, all
  /// variables in [variables] will be stored in [referencedVariables] as a side
  /// effect of this call.
  Map<Variable, VariableModel<Type>> _removePromotedAll(
      Map<Variable, VariableModel<Type>> map,
      Iterable<Variable> variables,
      Set<Variable> referencedVariables) {
    if (map.isEmpty) return const {};
    Map<Variable, VariableModel<Type>> result;
    for (Variable variable in variables) {
      assert(() {
        referencedVariables?.add(variable);
        return true;
      }());
      VariableModel<Type> info = map[variable];
      if (info.promotedType != null) {
        (result ??= Map<Variable, VariableModel<Type>>.from(map))[variable] =
            info.withPromotedType(null);
      }
    }
    if (result == null) return map;
    return result;
  }

  /// Returns a new [FlowModel] where the information for [variable] is replaced
  /// with [model].
  FlowModel<Variable, Type> _updateVariableInfo(
      Variable variable, VariableModel<Type> model) {
    Map<Variable, VariableModel<Type>> newVariableInfo =
        Map<Variable, VariableModel<Type>>.from(variableInfo);
    newVariableInfo[variable] = model;
    return FlowModel<Variable, Type>._(reachable, notAssigned, newVariableInfo);
  }

  /// Forms a new state to reflect a control flow path that might have come from
  /// either `this` or the [other] state.
  ///
  /// The control flow path is considered reachable if either of the input
  /// states is reachable.  Variables are considered definitely assigned if they
  /// were definitely assigned in both of the input states.  Variable promotions
  /// are kept only if they are common to both input states; if a variable is
  /// promoted to one type in one state and a subtype in the other state, the
  /// less specific type promotion is kept.
  static FlowModel<Variable, Type> join<Variable, Type>(
    TypeOperations<Variable, Type> typeOperations,
    FlowModel<Variable, Type> first,
    FlowModel<Variable, Type> second,
  ) {
    if (first == null) return second;
    if (second == null) return first;

    if (first.reachable && !second.reachable) return first;
    if (!first.reachable && second.reachable) return second;

    bool newReachable = first.reachable || second.reachable;
    _VariableSet<Variable> newNotAssigned =
        first.notAssigned.union(second.notAssigned);
    Map<Variable, VariableModel<Type>> newVariableInfo =
        FlowModel.joinVariableInfo(
            typeOperations, first.variableInfo, second.variableInfo);

    return FlowModel._identicalOrNew(
      first,
      second,
      newReachable,
      newNotAssigned,
      newVariableInfo,
    );
  }

  /// Joins two "variable info" maps.  See [join] for details.
  @visibleForTesting
  static Map<Variable, VariableModel<Type>> joinVariableInfo<Variable, Type>(
    TypeOperations<Variable, Type> typeOperations,
    Map<Variable, VariableModel<Type>> first,
    Map<Variable, VariableModel<Type>> second,
  ) {
    if (identical(first, second)) return first;
    if (first.isEmpty || second.isEmpty) return const {};

    Map<Variable, VariableModel<Type>> result =
        <Variable, VariableModel<Type>>{};
    bool alwaysFirst = true;
    bool alwaysSecond = true;
    for (MapEntry<Variable, VariableModel<Type>> entry in first.entries) {
      Variable variable = entry.key;
      VariableModel<Type> secondModel = second[variable];
      if (secondModel == null) {
        alwaysFirst = false;
      } else {
        VariableModel<Type> joined =
            VariableModel.join<Type>(typeOperations, entry.value, secondModel);
        result[variable] = joined;
        if (!identical(joined, entry.value)) alwaysFirst = false;
        if (!identical(joined, secondModel)) alwaysSecond = false;
      }
    }

    if (alwaysFirst) return first;
    if (alwaysSecond && result.length == second.length) return second;
    if (result.isEmpty) return const {};
    return result;
  }

  /// Creates a new [FlowModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static FlowModel<Variable, Type> _identicalOrNew<Variable, Type>(
    FlowModel<Variable, Type> first,
    FlowModel<Variable, Type> second,
    bool newReachable,
    _VariableSet<Variable> newNotAssigned,
    Map<Variable, VariableModel<Type>> newVariableInfo,
  ) {
    if (first.reachable == newReachable &&
        identical(first.notAssigned, newNotAssigned) &&
        identical(first.variableInfo, newVariableInfo)) {
      return first;
    }
    if (second.reachable == newReachable &&
        identical(second.notAssigned, newNotAssigned) &&
        identical(second.variableInfo, newVariableInfo)) {
      return second;
    }

    return FlowModel<Variable, Type>._(
      newReachable,
      newNotAssigned,
      newVariableInfo,
    );
  }

  /// Determines whether the given "variableInfo" maps are equivalent.
  static bool _variableInfosEqual<Variable, Type>(
      TypeOperations<Variable, Type> typeOperations,
      Map<Variable, VariableModel<Type>> p1,
      Map<Variable, VariableModel<Type>> p2) {
    if (p1.length != p2.length) return false;
    if (!p1.keys.toSet().containsAll(p2.keys)) return false;
    for (MapEntry<Variable, VariableModel<Type>> entry in p1.entries) {
      VariableModel<Type> p1Value = entry.value;
      VariableModel<Type> p2Value = p2[entry.key];
      if (p1Value == null) {
        if (p2Value != null) return false;
      } else {
        if (p2Value == null) return false;
        Type p1Type = p1Value.promotedType;
        Type p2Type = p2Value.promotedType;
        if (p1Type == null) {
          if (p2Type != null) return false;
        } else {
          if (p2Type == null) return false;
          if (!typeOperations.isSameType(p1Type, p2Type)) return false;
        }
      }
    }
    return true;
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

/// An instance of the [VariableModel] class represents the information gathered
/// by flow analysis for a single variable at a single point in the control flow
/// of the function or method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class VariableModel<Type> {
  /// The type that the variable has been promoted to, or `null` if the variable
  /// is not promoted.
  final Type promotedType;

  VariableModel(this.promotedType);

  @override
  bool operator ==(Object other) {
    return other is VariableModel<Type> &&
        this.promotedType == other.promotedType;
  }

  /// Returns an updated model reflect a control path that is known to have
  /// previously passed through some [other] state.  See [FlowModel.restrict]
  /// for details.
  VariableModel<Type> restrict(TypeOperations<Object, Type> typeOperations,
      VariableModel<Type> otherModel, bool unsafe) {
    Type thisType = promotedType;
    Type otherType = otherModel?.promotedType;
    if (!unsafe) {
      if (otherType != null &&
          (thisType == null ||
              typeOperations.isSubtypeOf(otherType, thisType))) {
        return _identicalOrNew(this, otherModel, otherType);
      }
    }
    if (thisType != null) {
      return _identicalOrNew(this, otherModel, thisType);
    } else {
      return _identicalOrNew(this, otherModel, null);
    }
  }

  @override
  String toString() => 'VariableModel($promotedType)';

  /// Returns a new [VariableModel] where the promoted type is replaced with
  /// [promotedType].
  VariableModel<Type> withPromotedType(Type promotedType) =>
      VariableModel<Type>(promotedType);

  /// Joins two variable models.  See [FlowModel.join] for details.
  static VariableModel<Type> join<Type>(
      TypeOperations<Object, Type> typeOperations,
      VariableModel<Type> first,
      VariableModel<Type> second) {
    Type firstType = first.promotedType;
    Type secondType = second.promotedType;
    Type newPromotedType;
    if (identical(firstType, secondType)) {
      newPromotedType = firstType;
    } else if (firstType == null || secondType == null) {
      newPromotedType = null;
    } else if (typeOperations.isSubtypeOf(firstType, secondType)) {
      newPromotedType = secondType;
    } else if (typeOperations.isSubtypeOf(secondType, firstType)) {
      newPromotedType = firstType;
    } else {
      newPromotedType = null;
    }
    return _identicalOrNew(first, second, newPromotedType);
  }

  /// Creates a new [VariableModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static VariableModel<Type> _identicalOrNew<Type>(VariableModel<Type> first,
      VariableModel<Type> second, Type newPromotedType) {
    if (identical(first.promotedType, newPromotedType)) {
      return first;
    } else if (identical(second.promotedType, newPromotedType)) {
      return second;
    } else {
      return VariableModel<Type>(newPromotedType);
    }
  }
}

/// List based immutable set of variables.
class _VariableSet<Variable> {
  final List<Variable> variables;

  _VariableSet._(this.variables);

  _VariableSet<Variable> add(Variable addedVariable) {
    if (contains(addedVariable)) {
      return this;
    }

    int length = variables.length;
    List<Variable> newVariables = List<Variable>(length + 1);
    for (int i = 0; i < length; ++i) {
      newVariables[i] = variables[i];
    }
    newVariables[length] = addedVariable;
    return _VariableSet._(newVariables);
  }

  _VariableSet<Variable> addAll(Iterable<Variable> variables) {
    _VariableSet<Variable> result = this;
    for (Variable variable in variables) {
      result = result.add(variable);
    }
    return result;
  }

  bool contains(Variable variable) {
    int length = variables.length;
    for (int i = 0; i < length; ++i) {
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
    List<Variable> newVariables =
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

    int length = variables.length;
    if (length == 1) {
      return empty;
    }

    List<Variable> newVariables = List<Variable>(length - 1);
    int newIndex = 0;
    for (int i = 0; i < length; ++i) {
      Variable variable = variables[i];
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

    _VariableSet<Variable> result = this;
    List<Variable> otherVariables = other.variables;
    for (int i = 0; i < otherVariables.length; ++i) {
      Variable otherVariable = otherVariables[i];
      result = result.add(otherVariable);
    }
    return result;
  }
}
