// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// [AssignedVariables] is a helper class capable of computing the set of
/// variables that are potentially written to, and potentially captured by
/// closures, at various locations inside the code being analyzed.  This class
/// should be used prior to running flow analysis, to compute the sets of
/// variables to pass in to flow analysis.
///
/// This class is intended to be used in two phases.  In the first phase, the
/// client should traverse the source code recursively, making calls to
/// [beginNode] and [endNode] to indicate the constructs in which writes should
/// be tracked, and calls to [write] to indicate when a write is encountered.
/// The order of visiting is not important provided that nesting is respected.
/// This phase is called the "pre-traversal" because it should happen prior to
/// flow analysis.
///
/// Then, in the second phase, the client may make queries using
/// [capturedAnywhere], [writtenInNode], and [capturedInNode].
///
/// We use the term "node" to refer generally to a loop statement, switch
/// statement, try statement, loop collection element, local function, or
/// closure.
class AssignedVariables<Node, Variable> {
  /// Mapping from a node to the set of local variables that are potentially
  /// written to within that node.
  final Map<Node, Set<Variable>> _writtenInNode = {};

  /// Mapping from a node to the set of local variables for which a potential
  /// write is captured by a local function or closure inside that node.
  final Map<Node, Set<Variable>> _capturedInNode = {};

  /// Stack of sets accumulating variables that are potentially written to.
  ///
  /// A set is pushed onto the stack when a node is entered, and popped when
  /// a node is left.
  final List<Set<Variable>> _writtenStack = [];

  /// Stack of sets accumulating variables for which a potential write is
  /// captured by a local function or closure.
  ///
  /// A set is pushed onto the stack when a node is entered, and popped when
  /// a node is left.
  final List<Set<Variable>> _capturedStack = [];

  /// Stack of integers counting the number of entries in [_capturedStack] that
  /// should be updated when a variable write is seen.
  ///
  /// When a closure is entered, the length of [_capturedStack] is pushed onto
  /// this stack; when a node is left, it is popped.
  ///
  /// Each time a write occurs, we consult the top of this stack to determine
  /// how many elements of [capturedStack] should be updated.
  final List<int> _closureIndexStack = [];

  AssignedVariables();

  /// This method should be called during pre-traversal, to mark the start of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, or closure which might need to be queried later.
  ///
  /// [isClosure] should be true if the node is a local function or closure.
  ///
  /// The span between the call to [beginNode] and [endNode] should cover any
  /// statements and expressions that might be crossed by a backwards jump.  So
  /// for instance, in a "for" loop, the condition, updaters, and body should be
  /// covered, but the initializers should not.  Similarly, in a switch
  /// statement, the body of the switch statement should be covered, but the
  /// switch expression should not.
  void beginNode({bool isClosure: false}) {
    _writtenStack.add(new Set<Variable>.identity());
    if (isClosure) {
      _closureIndexStack.add(_capturedStack.length);
    }
    _capturedStack.add(new Set<Variable>.identity());
  }

  /// Queries the set of variables for which a potential write is captured by a
  /// local function or closure inside the [node].
  Set<Variable> capturedInNode(Node node) {
    return _capturedInNode[node] ?? const {};
  }

  /// This method should be called during pre-traversal, to mark the end of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, or closure which might need to be queried later.
  ///
  /// [isClosure] should be true if the node is a local function or closure.
  ///
  /// See [beginNode] for more details.
  void endNode(Node node, {bool isClosure: false}) {
    _writtenInNode[node] = _writtenStack.removeLast();
    _capturedInNode[node] = _capturedStack.removeLast();
    if (isClosure) {
      _closureIndexStack.removeLast();
    }
  }

  /// This method should be called during pre-traversal, to mark a write to a
  /// variable.
  void write(Variable variable) {
    for (int i = 0; i < _writtenStack.length; ++i) {
      _writtenStack[i].add(variable);
    }
    if (_closureIndexStack.isNotEmpty) {
      int closureIndex = _closureIndexStack.last;
      for (int i = 0; i < closureIndex; ++i) {
        _capturedStack[i].add(variable);
      }
    }
  }

  /// Queries the set of variables that are potentially written to inside the
  /// [node].
  Set<Variable> writtenInNode(Node node) {
    return _writtenInNode[node] ?? const {};
  }
}

class FlowAnalysis<Statement, Expression, Variable, Type> {
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

  FlowModel<Variable, Type> _current;

  /// The last boolean condition, for [_conditionTrue] and [_conditionFalse].
  Expression _condition;

  /// The state when [_condition] evaluates to `true`.
  FlowModel<Variable, Type> _conditionTrue;

  /// The state when [_condition] evaluates to `false`.
  FlowModel<Variable, Type> _conditionFalse;

  factory FlowAnalysis(
    NodeOperations<Expression> nodeOperations,
    TypeOperations<Variable, Type> typeOperations,
    FunctionBodyAccess<Variable> functionBody,
  ) {
    return new FlowAnalysis._(nodeOperations, typeOperations, functionBody);
  }

  FlowAnalysis._(this.nodeOperations, this.typeOperations, this.functionBody) {
    _current = new FlowModel<Variable, Type>(true);
  }

  /// Return `true` if the current state is reachable.
  bool get isReachable => _current.reachable;

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
    _current = _current.removePromotedAll(loopAssigned);

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
    _current = _current.removePromotedAll(loopAssigned);
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
  /// in the loop's body.  [loopVariable] should be the loop variable, if it's a
  /// local variable, or `null` otherwise.
  void forEach_bodyBegin(Set<Variable> loopAssigned, Variable loopVariable) {
    _stack.add(_current);
    _current = _current.removePromotedAll(loopAssigned);
    if (loopVariable != null) {
      assert(loopAssigned.contains(loopVariable));
      _current = _current.write(loopVariable);
    }
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
      _current = _current.removePromotedAll(notPromoted);
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
    return _current.infoFor(variable).assigned;
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
    return _current.infoFor(variable).promotedType;
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
      _current = _stack.last.removePromotedAll(notPromoted);
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
        beforeBody.removePromotedAll(assignedInBody);
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
    FlowModel<Variable, Type> afterBody = _stack.removeLast();
    _current = _current.restrict(typeOperations, afterBody, assignedInFinally);
  }

  void tryFinallyStatement_finallyBegin(Iterable<Variable> assignedInBody) {
    FlowModel<Variable, Type> beforeTry = _stack.removeLast();
    FlowModel<Variable, Type> afterBody = _current;
    _stack.add(afterBody);
    _current = _join(afterBody, beforeTry.removePromotedAll(assignedInBody));
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
    _current = _current.removePromotedAll(loopAssigned);
  }

  void whileStatement_end() {
    _stack.removeLast(); // continue
    FlowModel<Variable, Type> breakState = _stack.removeLast();
    FlowModel<Variable, Type> falseCondition = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  /// Register write of the given [variable] in the current state.
  void write(Variable variable) {
    _current = _current.write(variable);
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

  /// Variable model for variables that have never been seen before.
  final VariableModel<Type> _freshVariableInfo;

  /// Creates a state object with the given [reachable] status.  All variables
  /// are assumed to be unpromoted and already assigned, so joining another
  /// state with this one will have no effect on it.
  FlowModel(bool reachable)
      : this._(
          reachable,
          const {},
        );

  FlowModel._(this.reachable, this.variableInfo)
      : _freshVariableInfo = new VariableModel.fresh() {
    assert(() {
      for (VariableModel<Type> value in variableInfo.values) {
        assert(value != null);
      }
      return true;
    }());
  }

  /// Gets the info for the given [variable], creating it if it doesn't exist.
  VariableModel<Type> infoFor(Variable variable) =>
      variableInfo[variable] ?? _freshVariableInfo;

  /// Updates the state to indicate that the given [variable] has been
  /// determined to contain a non-null value.
  ///
  /// TODO(paulberry): should this method mark the variable as definitely
  /// assigned?  Does it matter?
  FlowModel<Variable, Type> markNonNullable(
      TypeOperations<Variable, Type> typeOperations, Variable variable) {
    VariableModel<Type> info = infoFor(variable);
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
    VariableModel<Type> info = infoFor(variable);
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
  FlowModel<Variable, Type> removePromotedAll(Iterable<Variable> variables) {
    Map<Variable, VariableModel<Type>> newVariableInfo;
    for (Variable variable in variables) {
      VariableModel<Type> info = infoFor(variable);
      if (info.promotedType != null) {
        (newVariableInfo ??= new Map<Variable, VariableModel<Type>>.from(
            variableInfo))[variable] = info.withPromotedType(null);
      }
    }
    if (newVariableInfo == null) return this;
    return new FlowModel<Variable, Type>._(reachable, newVariableInfo);
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
      FlowModel<Variable, Type> other,
      Set<Variable> unsafe) {
    bool newReachable = reachable && other.reachable;

    Map<Variable, VariableModel<Type>> newVariableInfo =
        <Variable, VariableModel<Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesOther = true;
    for (MapEntry<Variable, VariableModel<Type>> entry
        in variableInfo.entries) {
      Variable variable = entry.key;
      VariableModel<Type> thisModel = entry.value;
      VariableModel<Type> otherModel = other.infoFor(variable);
      VariableModel<Type> restricted = thisModel.restrict(
          typeOperations, otherModel, unsafe.contains(variable));
      if (!identical(restricted, _freshVariableInfo)) {
        newVariableInfo[variable] = restricted;
      }
      if (!identical(restricted, thisModel)) variableInfoMatchesThis = false;
      if (!identical(restricted, otherModel)) variableInfoMatchesOther = false;
    }
    for (MapEntry<Variable, VariableModel<Type>> entry
        in other.variableInfo.entries) {
      Variable variable = entry.key;
      if (variableInfo.containsKey(variable)) continue;
      VariableModel<Type> thisModel = _freshVariableInfo;
      VariableModel<Type> otherModel = entry.value;
      VariableModel<Type> restricted = thisModel.restrict(
          typeOperations, otherModel, unsafe.contains(variable));
      if (!identical(restricted, _freshVariableInfo)) {
        newVariableInfo[variable] = restricted;
      }
      if (!identical(restricted, thisModel)) variableInfoMatchesThis = false;
      if (!identical(restricted, otherModel)) variableInfoMatchesOther = false;
    }
    assert(variableInfoMatchesThis ==
        _variableInfosEqual(newVariableInfo, variableInfo));
    assert(variableInfoMatchesOther ==
        _variableInfosEqual(newVariableInfo, other.variableInfo));
    if (variableInfoMatchesThis) {
      newVariableInfo = variableInfo;
    } else if (variableInfoMatchesOther) {
      newVariableInfo = other.variableInfo;
    }

    return _identicalOrNew(this, other, newReachable, newVariableInfo);
  }

  /// Updates the state to indicate whether the control flow path is
  /// [reachable].
  FlowModel<Variable, Type> setReachable(bool reachable) {
    if (this.reachable == reachable) return this;

    return new FlowModel<Variable, Type>._(reachable, variableInfo);
  }

  @override
  String toString() => '($reachable, $variableInfo)';

  /// Updates the state to indicate that an assignment was made to the given
  /// [variable].  The variable is marked as definitely assigned, and any
  /// previous type promotion is removed.
  ///
  /// TODO(paulberry): allow for writes that preserve type promotions.
  FlowModel<Variable, Type> write(Variable variable) {
    VariableModel<Type> infoForVar = infoFor(variable);
    VariableModel<Type> newInfoForVar = infoForVar.write();
    if (identical(newInfoForVar, infoForVar)) return this;
    return _updateVariableInfo(variable, newInfoForVar);
  }

  /// Returns a new [FlowModel] where the information for [variable] is replaced
  /// with [model].
  FlowModel<Variable, Type> _updateVariableInfo(
      Variable variable, VariableModel<Type> model) {
    Map<Variable, VariableModel<Type>> newVariableInfo =
        new Map<Variable, VariableModel<Type>>.from(variableInfo);
    newVariableInfo[variable] = model;
    return new FlowModel<Variable, Type>._(reachable, newVariableInfo);
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
    Map<Variable, VariableModel<Type>> newVariableInfo =
        FlowModel.joinVariableInfo(
            typeOperations, first.variableInfo, second.variableInfo);

    return FlowModel._identicalOrNew(
        first, second, newReachable, newVariableInfo);
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
      Map<Variable, VariableModel<Type>> newVariableInfo) {
    if (first.reachable == newReachable &&
        identical(first.variableInfo, newVariableInfo)) {
      return first;
    }
    if (second.reachable == newReachable &&
        identical(second.variableInfo, newVariableInfo)) {
      return second;
    }

    return new FlowModel<Variable, Type>._(newReachable, newVariableInfo);
  }

  /// Determines whether the given "variableInfo" maps are equivalent.
  ///
  /// The equivalence check is shallow; if two variables' models are not
  /// identical, we return `false`.
  static bool _variableInfosEqual<Variable, Type>(
      Map<Variable, VariableModel<Type>> p1,
      Map<Variable, VariableModel<Type>> p2) {
    if (p1.length != p2.length) return false;
    if (!p1.keys.toSet().containsAll(p2.keys)) return false;
    for (MapEntry<Variable, VariableModel<Type>> entry in p1.entries) {
      VariableModel<Type> p1Value = entry.value;
      VariableModel<Type> p2Value = p2[entry.key];
      if (!identical(p1Value, p2Value)) {
        return false;
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

  /// Indicates whether the variable has definitely been assigned.
  final bool assigned;

  VariableModel(this.promotedType, this.assigned);

  /// Creates a [VariableModel] representing a variable that's never been seen
  /// before.
  VariableModel.fresh()
      : promotedType = null,
        assigned = false;

  @override
  bool operator ==(Object other) {
    return other is VariableModel<Type> &&
        this.promotedType == other.promotedType &&
        this.assigned == other.assigned;
  }

  /// Returns an updated model reflect a control path that is known to have
  /// previously passed through some [other] state.  See [FlowModel.restrict]
  /// for details.
  VariableModel<Type> restrict(TypeOperations<Object, Type> typeOperations,
      VariableModel<Type> otherModel, bool unsafe) {
    Type thisType = promotedType;
    Type otherType = otherModel?.promotedType;
    bool newAssigned = assigned || otherModel.assigned;
    if (!unsafe) {
      if (otherType != null &&
          (thisType == null ||
              typeOperations.isSubtypeOf(otherType, thisType))) {
        return _identicalOrNew(this, otherModel, otherType, newAssigned);
      }
    }
    return _identicalOrNew(this, otherModel, thisType, newAssigned);
  }

  @override
  String toString() => 'VariableModel($promotedType, $assigned)';

  /// Returns a new [VariableModel] where the promoted type is replaced with
  /// [promotedType].
  VariableModel<Type> withPromotedType(Type promotedType) =>
      new VariableModel<Type>(promotedType, assigned);

  /// Returns a new [VariableModel] reflecting the fact that the variable was
  /// just written to.
  VariableModel<Type> write() {
    if (promotedType == null && assigned) return this;
    return new VariableModel<Type>(null, true);
  }

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
    bool newAssigned = first.assigned && second.assigned;
    return _identicalOrNew(first, second, newPromotedType, newAssigned);
  }

  /// Creates a new [VariableModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static VariableModel<Type> _identicalOrNew<Type>(VariableModel<Type> first,
      VariableModel<Type> second, Type newPromotedType, bool newAssigned) {
    if (identical(first.promotedType, newPromotedType) &&
        first.assigned == newAssigned) {
      return first;
    } else if (identical(second.promotedType, newPromotedType) &&
        second.assigned == newAssigned) {
      return second;
    } else {
      return new VariableModel<Type>(newPromotedType, newAssigned);
    }
  }
}
