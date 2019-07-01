// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Sets of local variables that are potentially assigned in a statement.
///
/// These statements are loops, `switch`, and `try` statements.
class AssignedVariables<Statement, Element> {
  final emptySet = Set<Element>();

  /// Mapping from a [Statement] to the set of local variables that are
  /// potentially assigned in that statement.
  final Map<Statement, Set<Element>> _map = {};

  /// The stack of nested statements.
  final List<Set<Element>> _stack = [];

  AssignedVariables();

  /// Return the set of variables that are potentially assigned in the
  /// [statement].
  Set<Element> operator [](Statement statement) {
    return _map[statement] ?? emptySet;
  }

  void beginStatement() {
    var set = Set<Element>.identity();
    _stack.add(set);
  }

  void endStatement(Statement node) {
    _map[node] = _stack.removeLast();
  }

  void write(Element variable) {
    for (var i = 0; i < _stack.length; ++i) {
      _stack[i].add(variable);
    }
  }
}

class FlowAnalysis<Statement, Expression, Element, Type> {
  final _ElementSet<Element> _emptySet;
  final _State<Element, Type> _identity;

  /// The [NodeOperations], used to manipulate expressions.
  final NodeOperations<Expression> nodeOperations;

  /// The [TypeOperations], used to access types, and check subtyping.
  final TypeOperations<Element, Type> typeOperations;

  /// The enclosing function body, used to check for potential mutations.
  final FunctionBodyAccess functionBody;

  /// The stack of states of variables that are not definitely assigned.
  final List<_State<Element, Type>> _stack = [];

  /// The mapping from labeled [Statement]s to the index in the [_stack]
  /// where the first related element is located.  The number of elements
  /// is statement specific.  Loops have two elements: `break` and `continue`
  /// states.
  final Map<Statement, int> _statementToStackIndex = {};

  /// The list of all variables.
  final List<Element> _variables = [];

  _State<Element, Type> _current;

  /// The last boolean condition, for [_conditionTrue] and [_conditionFalse].
  Expression _condition;

  /// The state when [_condition] evaluates to `true`.
  _State<Element, Type> _conditionTrue;

  /// The state when [_condition] evaluates to `false`.
  _State<Element, Type> _conditionFalse;

  factory FlowAnalysis(
    NodeOperations<Expression> nodeOperations,
    TypeOperations<Element, Type> typeOperations,
    FunctionBodyAccess functionBody,
  ) {
    var emptySet = _ElementSet<Element>._(
      List<Element>(0),
    );
    var identifyState = _State<Element, Type>(
      false,
      emptySet,
      emptySet,
      emptySet,
      const {},
    );
    return FlowAnalysis._(
      nodeOperations,
      typeOperations,
      functionBody,
      emptySet,
      identifyState,
    );
  }

  FlowAnalysis._(
    this.nodeOperations,
    this.typeOperations,
    this.functionBody,
    this._emptySet,
    this._identity,
  ) {
    _current = _State<Element, Type>(
      true,
      _emptySet,
      _emptySet,
      _emptySet,
      const {},
    );
  }

  /// Return `true` if the current state is reachable.
  bool get isReachable => _current.reachable;

  /// Add a new [variable], which might be already [assigned].
  void add(Element variable, {bool assigned: false}) {
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
  void conditionEqNull(Expression binaryExpression, Element variable) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = binaryExpression;
    _conditionTrue = _current.markNullable(_emptySet, variable);
    _conditionFalse = _current.markNonNullable(_emptySet, variable);
  }

  /// The [binaryExpression] checks that the [variable] is not equal to `null`.
  void conditionNotEqNull(Expression binaryExpression, Element variable) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = binaryExpression;
    _conditionTrue = _current.markNonNullable(_emptySet, variable);
    _conditionFalse = _current.markNullable(_emptySet, variable);
  }

  void doStatement_bodyBegin(Statement doStatement, Set<Element> loopAssigned) {
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

  void forEachStatement_bodyBegin(Set<Element> loopAssigned) {
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

  void forStatement_conditionBegin(Set<Element> loopAssigned) {
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

    Set<Element> notPromoted = null;
    for (var variable in _current.promoted.keys) {
      if (functionBody.isPotentiallyMutatedInScope(variable)) {
        notPromoted ??= Set<Element>.identity();
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
    _State<Element, Type> afterThen;
    _State<Element, Type> afterElse;
    if (hasElse) {
      afterThen = _stack.removeLast();
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = _stack.removeLast(); // `falseCond` is still on the stack
    }
    _current = _join(afterThen, afterElse);
  }

  void ifStatement_thenBegin(Statement ifStatement, Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack:  falseCondition, trueCondition

    var trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  /// Return whether the [variable] is definitely assigned in the current state.
  bool isAssigned(Element variable) {
    return !_current.notAssigned.contains(variable);
  }

  void isExpression_end(
      Expression isExpression, Element variable, bool isNot, Type type) {
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

  /// Return `true` if the [variable] is known to be be non-nullable.
  bool isNonNullable(Element variable) {
    return !_current.notNonNullable.contains(variable);
  }

  /// Return `true` if the [variable] is known to be be nullable.
  bool isNullable(Element variable) {
    return !_current.notNullable.contains(variable);
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
  Type promotedType(Element variable) {
    return _current.promoted[variable];
  }

  /// The [notPromoted] set contains all variables that are potentially
  /// assigned in other cases that might target this with `continue`, so
  /// these variables might have different types and are "un-promoted" from
  /// the "afterExpression" state.
  void switchStatement_beginCase(Set<Element> notPromoted) {
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

  void tryCatchStatement_bodyEnd(Set<Element> assignedInBody) {
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

  void tryFinallyStatement_end(Set<Element> assignedInFinally) {
    var afterBody = _stack.removeLast();
    _current = _current.restrict(
      typeOperations,
      _emptySet,
      afterBody,
      assignedInFinally,
    );
  }

  void tryFinallyStatement_finallyBegin(Set<Element> assignedInBody) {
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

  void whileStatement_conditionBegin(Set<Element> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);
  }

  void whileStatement_end() {
    _stack.removeLast(); // continue
    var breakState = _stack.removeLast();
    var falseCondition = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  /// Register write of the given [variable] in the current state.
  void write(
    Element variable, {
    bool isNull = false,
    bool isNonNull = false,
  }) {
    _current = _current.write(typeOperations, _emptySet, variable,
        isNull: isNull, isNonNull: isNonNull);
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

  _State<Element, Type> _join(
    _State<Element, Type> first,
    _State<Element, Type> second,
  ) {
    if (identical(first, _identity)) return second;
    if (identical(second, _identity)) return first;

    if (first.reachable && !second.reachable) return first;
    if (!first.reachable && second.reachable) return second;

    var newReachable = first.reachable || second.reachable;
    var newNotAssigned = first.notAssigned.union(second.notAssigned);
    var newNotNullable = first.notNullable.union(second.notNullable);
    var newNotNonNullable = first.notNonNullable.union(second.notNonNullable);
    var newPromoted = _joinPromoted(first.promoted, second.promoted);

    return _State._identicalOrNew(
      first,
      second,
      newReachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }

  Map<Element, Type> _joinPromoted(
    Map<Element, Type> first,
    Map<Element, Type> second,
  ) {
    if (identical(first, second)) return first;
    if (first.isEmpty || second.isEmpty) return const {};

    var result = <Element, Type>{};
    var alwaysFirst = true;
    var alwaysSecond = true;
    for (var element in first.keys) {
      var firstType = first[element];
      var secondType = second[element];
      if (firstType != null && secondType != null) {
        if (typeOperations.isSubtypeOf(firstType, secondType)) {
          result[element] = secondType;
          alwaysFirst = false;
        } else if (typeOperations.isSubtypeOf(secondType, firstType)) {
          result[element] = firstType;
          alwaysSecond = false;
        } else {
          alwaysFirst = false;
          alwaysSecond = false;
        }
      } else {
        alwaysFirst = false;
        alwaysSecond = false;
      }
    }

    if (alwaysFirst) return first;
    if (alwaysSecond) return second;
    if (result.isEmpty) return const {};
    return result;
  }
}

/// Accessor for function body information.
abstract class FunctionBodyAccess<Element> {
  bool isPotentiallyMutatedInClosure(Element variable);

  bool isPotentiallyMutatedInScope(Element variable);
}

/// Operations on nodes, abstracted from concrete node interfaces.
abstract class NodeOperations<Expression> {
  /// If the [node] is a parenthesized expression, recursively unwrap it.
  Expression unwrapParenthesized(Expression node);
}

/// Operations on types, abstracted from concrete type interfaces.
abstract class TypeOperations<Element, Type> {
  /// Return the static type of the given [element].
  Type elementType(Element element);

  /// Return `true` if the [element] is a local variable, not a parameter.
  bool isLocalVariable(Element element);

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  bool isSubtypeOf(Type leftType, Type rightType);
}

/// List based immutable set of elements.
class _ElementSet<Element> {
  final List<Element> elements;

  _ElementSet._(this.elements);

  _ElementSet<Element> add(Element addedElement) {
    if (contains(addedElement)) {
      return this;
    }

    var length = elements.length;
    var newElements = List<Element>(length + 1);
    for (var i = 0; i < length; ++i) {
      newElements[i] = elements[i];
    }
    newElements[length] = addedElement;
    return _ElementSet._(newElements);
  }

  _ElementSet<Element> addAll(Iterable<Element> elements) {
    var result = this;
    for (var element in elements) {
      result = result.add(element);
    }
    return result;
  }

  bool contains(Element element) {
    var length = elements.length;
    for (var i = 0; i < length; ++i) {
      if (identical(elements[i], element)) {
        return true;
      }
    }
    return false;
  }

  _ElementSet<Element> intersect({
    _ElementSet<Element> empty,
    _ElementSet<Element> other,
  }) {
    if (identical(other, empty)) return empty;

    // TODO(scheglov) optimize
    var newElements =
        elements.toSet().intersection(other.elements.toSet()).toList();

    if (newElements.isEmpty) return empty;
    return _ElementSet._(newElements);
  }

  _ElementSet<Element> remove(
    _ElementSet<Element> empty,
    Element removedElement,
  ) {
    if (!contains(removedElement)) {
      return this;
    }

    var length = elements.length;
    if (length == 1) {
      return empty;
    }

    var newElements = List<Element>(length - 1);
    var newIndex = 0;
    for (var i = 0; i < length; ++i) {
      var element = elements[i];
      if (!identical(element, removedElement)) {
        newElements[newIndex++] = element;
      }
    }

    return _ElementSet._(newElements);
  }

  _ElementSet<Element> union(_ElementSet<Element> other) {
    if (other.elements.isEmpty) {
      return this;
    }

    var result = this;
    var otherElements = other.elements;
    for (var i = 0; i < otherElements.length; ++i) {
      var otherElement = otherElements[i];
      result = result.add(otherElement);
    }
    return result;
  }
}

class _State<Element, Type> {
  final bool reachable;
  final _ElementSet<Element> notAssigned;
  final _ElementSet<Element> notNullable;
  final _ElementSet<Element> notNonNullable;
  final Map<Element, Type> promoted;

  _State(
    this.reachable,
    this.notAssigned,
    this.notNullable,
    this.notNonNullable,
    this.promoted,
  );

  /// Add a new [variable] to track definite assignment.
  _State<Element, Type> add(Element variable, {bool assigned: false}) {
    var newNotAssigned = assigned ? notAssigned : notAssigned.add(variable);
    var newNotNullable = notNullable.add(variable);
    var newNotNonNullable = notNonNullable.add(variable);

    if (identical(newNotAssigned, notAssigned) &&
        identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable)) {
      return this;
    }

    return _State<Element, Type>(
      reachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      promoted,
    );
  }

  _State<Element, Type> exit() {
    return _State<Element, Type>(
      false,
      notAssigned,
      notNullable,
      notNonNullable,
      promoted,
    );
  }

  _State<Element, Type> markNonNullable(
      _ElementSet<Element> emptySet, Element variable) {
    var newNotNullable = notNullable.add(variable);
    var newNotNonNullable = notNonNullable.remove(emptySet, variable);

    if (identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable)) {
      return this;
    }

    return _State<Element, Type>(
      reachable,
      notAssigned,
      newNotNullable,
      newNotNonNullable,
      promoted,
    );
  }

  _State<Element, Type> markNullable(
      _ElementSet<Element> emptySet, Element variable) {
    var newNotNullable = notNullable.remove(emptySet, variable);
    var newNotNonNullable = notNonNullable.add(variable);

    if (identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable)) {
      return this;
    }

    return _State<Element, Type>(
      reachable,
      notAssigned,
      newNotNullable,
      newNotNonNullable,
      promoted,
    );
  }

  _State<Element, Type> promote(
    TypeOperations<Element, Type> typeOperations,
    Element variable,
    Type type,
  ) {
    var previousType = promoted[variable];
    previousType ??= typeOperations.elementType(variable);

    if (typeOperations.isSubtypeOf(type, previousType) &&
        type != previousType) {
      var newPromoted = <Element, Type>{}..addAll(promoted);
      newPromoted[variable] = type;
      return _State<Element, Type>(
        reachable,
        notAssigned,
        notNullable,
        notNonNullable,
        newPromoted,
      );
    }

    return this;
  }

  _State<Element, Type> removePromotedAll(Set<Element> variables) {
    var newNotNullable = notNullable.addAll(variables);
    var newNotNonNullable = notNonNullable.addAll(variables);
    var newPromoted = _removePromotedAll(promoted, variables);

    if (identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable) &&
        identical(newPromoted, promoted)) return this;

    return _State<Element, Type>(
      reachable,
      notAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }

  _State<Element, Type> restrict(
    TypeOperations<Element, Type> typeOperations,
    _ElementSet<Element> emptySet,
    _State<Element, Type> other,
    Set<Element> unsafe,
  ) {
    var newReachable = reachable && other.reachable;
    var newNotAssigned = notAssigned.intersect(
      empty: emptySet,
      other: other.notAssigned,
    );

    var newNotNullable = emptySet;
    for (var variable in notNullable.elements) {
      if (unsafe.contains(variable) || other.notNullable.contains(variable)) {
        newNotNullable = newNotNullable.add(variable);
      }
    }

    var newNotNonNullable = emptySet;
    for (var variable in notNonNullable.elements) {
      if (unsafe.contains(variable) ||
          other.notNonNullable.contains(variable)) {
        newNotNonNullable = newNotNonNullable.add(variable);
      }
    }

    var newPromoted = <Element, Type>{};
    for (var variable in promoted.keys) {
      var thisType = promoted[variable];
      if (!unsafe.contains(variable)) {
        var otherType = other.promoted[variable];
        if (otherType != null &&
            typeOperations.isSubtypeOf(otherType, thisType)) {
          newPromoted[variable] = otherType;
          continue;
        }
      }
      newPromoted[variable] = thisType;
    }

    return _identicalOrNew(
      this,
      other,
      newReachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }

  _State<Element, Type> setReachable(bool reachable) {
    if (this.reachable == reachable) return this;

    return _State<Element, Type>(
      reachable,
      notAssigned,
      notNullable,
      notNonNullable,
      promoted,
    );
  }

  _State<Element, Type> write(
    TypeOperations<Element, Type> typeOperations,
    _ElementSet<Element> emptySet,
    Element variable, {
    bool isNull = false,
    bool isNonNull = false,
  }) {
    var newNotAssigned = typeOperations.isLocalVariable(variable)
        ? notAssigned.remove(emptySet, variable)
        : notAssigned;

    var newNotNullable = isNull
        ? notNullable.remove(emptySet, variable)
        : notNullable.add(variable);

    var newNotNonNullable = isNonNull
        ? notNonNullable.remove(emptySet, variable)
        : notNonNullable.add(variable);

    var newPromoted = _removePromoted(promoted, variable);

    if (identical(newNotAssigned, notAssigned) &&
        identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable) &&
        identical(newPromoted, promoted)) {
      return this;
    }

    return _State<Element, Type>(
      reachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }

  Map<Element, Type> _removePromoted(Map<Element, Type> map, Element variable) {
    if (map.isEmpty) return const {};

    var result = <Element, Type>{};
    for (var key in map.keys) {
      if (!identical(key, variable)) {
        result[key] = map[key];
      }
    }

    if (result.isEmpty) return const {};
    return result;
  }

  Map<Element, Type> _removePromotedAll(
    Map<Element, Type> map,
    Set<Element> variables,
  ) {
    if (map.isEmpty) return const {};
    if (variables.isEmpty) return map;

    var result = <Element, Type>{};
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

  static _State<Element, Type> _identicalOrNew<Element, Type>(
    _State<Element, Type> first,
    _State<Element, Type> second,
    bool newReachable,
    _ElementSet<Element> newNotAssigned,
    _ElementSet<Element> newNotNullable,
    _ElementSet<Element> newNotNonNullable,
    Map<Element, Type> newPromoted,
  ) {
    if (first.reachable == newReachable &&
        identical(first.notAssigned, newNotAssigned) &&
        identical(first.notNullable, newNotNullable) &&
        identical(first.notNonNullable, newNotNonNullable) &&
        identical(first.promoted, newPromoted)) {
      return first;
    }
    if (second.reachable == newReachable &&
        identical(second.notAssigned, newNotAssigned) &&
        identical(second.notNullable, newNotNullable) &&
        identical(second.notNonNullable, newNotNonNullable) &&
        identical(second.promoted, newPromoted)) {
      return second;
    }

    return _State<Element, Type>(
      newReachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }
}
