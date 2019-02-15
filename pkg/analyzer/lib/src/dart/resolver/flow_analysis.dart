// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Sets of variables that are potentially assigned in a node.
class AssignedVariables {
  static final emptySet = Set<VariableElement>();

  /// Mapping from a loop [AstNode] to the set of variables that are
  /// potentially assigned in this loop.
  final Map<AstNode, Set<VariableElement>> _map = {};

  /// The stack of nested loops.
  final List<Set<VariableElement>> _stack = [];

  /// Return the set of variables that are potentially assigned in the [loop].
  Set<VariableElement> operator [](AstNode loop) {
    return _map[loop] ?? emptySet;
  }

  void beginLoop() {
    var set = Set<VariableElement>.identity();
    _stack.add(set);
  }

  void endLoop(AstNode loop) {
    _map[loop] = _stack.removeLast();
  }

  void write(VariableElement variable) {
    for (var i = 0; i < _stack.length; ++i) {
      _stack[i].add(variable);
    }
  }
}

class FlowAnalysis<T> {
  final _identity = _State<T>(
    false,
    _ElementSet.empty,
    _ElementSet.empty,
    _ElementSet.empty,
    const {},
  );

  /// The output list of variables that were read before they were written.
  /// TODO(scheglov) use _ElementSet?
  final List<LocalVariableElement> readBeforeWritten = [];

  /// The [TypeOperations], used to access types, and check subtyping.
  final TypeOperations<T> typeOperations;

  /// The enclosing [FunctionBody], used to check for potential mutations.
  final FunctionBody functionBody;

  /// The stack of states of variables that are not definitely assigned.
  final List<_State> _stack = [];

  /// The mapping from labeled [Statement]s to the index in the [_stack]
  /// where the first related element is located.  The number of elements
  /// is statement specific.  Loops have two elements: `break` and `continue`
  /// states.
  final Map<Statement, int> _statementToStackIndex = {};

  /// The list of all variables.
  final List<VariableElement> _variables = [];

  _State<T> _current;

  /// The last boolean condition, for [_conditionTrue] and [_conditionFalse].
  Expression _condition;

  /// The state when [_condition] evaluates to `true`.
  _State<T> _conditionTrue;

  /// The state when [_condition] evaluates to `false`.
  _State<T> _conditionFalse;

  FlowAnalysis(this.typeOperations, this.functionBody) {
    _current = _State<T>(
      true,
      _ElementSet.empty,
      _ElementSet.empty,
      _ElementSet.empty,
      const {},
    );
  }

  /// Return `true` if the current state is reachable.
  bool get isReachable => _current.reachable;

  /// Add a new [variable], which might be already [assigned].
  void add(VariableElement variable, {bool assigned: false}) {
    _variables.add(variable);
    _current = _current.add(variable, assigned: assigned);
  }

  void conditional_elseBegin(ConditionalExpression node, bool isBool) {
    var afterThen = _current;
    var falseCondition = _stack.removeLast();

    if (isBool) {
      _conditionalEnd(node.thenExpression);
      // Tail of the stack: falseThen, trueThen
    }

    _stack.add(afterThen);
    _current = falseCondition;
  }

  void conditional_end(ConditionalExpression node, bool isBool) {
    var afterThen = _stack.removeLast();
    var afterElse = _current;

    if (isBool) {
      _conditionalEnd(node.elseExpression);
      // Tail of the stack: falseThen, trueThen, falseElse, trueElse

      var trueElse = _stack.removeLast();
      var falseElse = _stack.removeLast();

      var trueThen = _stack.removeLast();
      var falseThen = _stack.removeLast();

      var trueResult = _join(trueThen, trueElse);
      var falseResult = _join(falseThen, falseElse);

      _condition = node;
      _conditionTrue = trueResult;
      _conditionFalse = falseResult;
    }

    _current = _join(afterThen, afterElse);
  }

  void conditional_thenBegin(ConditionalExpression node) {
    _conditionalEnd(node.condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  /// The [node] checks that the [variable] is equal to `null`.
  void conditionEqNull(BinaryExpression node, VariableElement variable) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = node;
    _conditionTrue = _current.markNullable(variable);
    _conditionFalse = _current.markNonNullable(variable);
  }

  /// The [node] checks that the [variable] is not equal to `null`.
  void conditionNotEqNull(BinaryExpression node, VariableElement variable) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = node;
    _conditionTrue = _current.markNonNullable(variable);
    _conditionFalse = _current.markNullable(variable);
  }

  void doStatement_bodyBegin(
      DoStatement node, Set<VariableElement> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);

    _statementToStackIndex[node] = _stack.length;
    _stack.add(_identity); // break
    _stack.add(_identity); // continue
  }

  void doStatement_conditionBegin() {
    // Tail of the stack: break, continue

    var continueState = _stack.removeLast();
    _current = _join(_current, continueState);
  }

  void doStatement_end(DoStatement node) {
    _conditionalEnd(node.condition);
    // Tail of the stack:  break, falseCondition, trueCondition

    _stack.removeLast(); // trueCondition
    var falseCondition = _stack.removeLast();
    var breakState = _stack.removeLast();

    _current = _join(falseCondition, breakState);
  }

  void falseLiteral(BooleanLiteral expression) {
    _condition = expression;
    _conditionTrue = _identity;
    _conditionFalse = _current;
  }

  void forEachStatement_bodyBegin(Set<VariableElement> loopAssigned) {
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

  void forStatement_conditionBegin(Set<VariableElement> loopAssigned) {
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

    Set<VariableElement> notPromoted = null;
    for (var variable in _current.promoted.keys) {
      if (functionBody.isPotentiallyMutatedInScope(variable)) {
        notPromoted ??= Set<VariableElement>.identity();
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

  void handleBreak(AstNode target) {
    var breakIndex = _statementToStackIndex[target];
    if (breakIndex != null) {
      _stack[breakIndex] = _join(_stack[breakIndex], _current);
    }
    _current = _current.exit();
  }

  void handleContinue(AstNode target) {
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
    _State<T> afterThen;
    _State<T> afterElse;
    if (hasElse) {
      afterThen = _stack.removeLast();
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = _stack.removeLast(); // `falseCond` is still on the stack
    }
    _current = _join(afterThen, afterElse);
  }

  void ifStatement_thenBegin(IfStatement ifStatement) {
    _conditionalEnd(ifStatement.condition);
    // Tail of the stack:  falseCondition, trueCondition

    var trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  void isExpression_end(
      IsExpression isExpression, VariableElement variable, T type) {
    if (functionBody.isPotentiallyMutatedInClosure(variable)) {
      return;
    }

    _condition = isExpression;
    if (isExpression.notOperator == null) {
      _conditionTrue = _current.promote(typeOperations, variable, type);
      _conditionFalse = _current;
    } else {
      _conditionTrue = _current;
      _conditionFalse = _current.promote(typeOperations, variable, type);
    }
  }

  /// Return `true` if the [variable] is known to be be nullable.
  bool isNonNullable(VariableElement variable) {
    return !_current.notNonNullable.contains(variable);
  }

  /// Return `true` if the [variable] is known to be be non-nullable.
  bool isNullable(VariableElement variable) {
    return !_current.notNullable.contains(variable);
  }

  void logicalAnd_end(BinaryExpression andExpression) {
    _conditionalEnd(andExpression.rightOperand);
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

  void logicalAnd_rightBegin(BinaryExpression andExpression) {
    _conditionalEnd(andExpression.leftOperand);
    // Tail of the stack: falseLeft, trueLeft

    var trueLeft = _stack.last;
    _current = trueLeft;
  }

  void logicalNot_end(PrefixExpression notExpression) {
    _conditionalEnd(notExpression.operand);
    var trueExpr = _stack.removeLast();
    var falseExpr = _stack.removeLast();

    _condition = notExpression;
    _conditionTrue = falseExpr;
    _conditionFalse = trueExpr;
  }

  void logicalOr_end(BinaryExpression orExpression) {
    _conditionalEnd(orExpression.rightOperand);
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

  void logicalOr_rightBegin(BinaryExpression orExpression) {
    _conditionalEnd(orExpression.leftOperand);
    // Tail of the stack: falseLeft, trueLeft

    var falseLeft = _stack[_stack.length - 2];
    _current = falseLeft;
  }

  /// Retrieves the type that the [variable] is promoted to, if the [variable]
  /// is currently promoted.  Otherwise returns `null`.
  T promotedType(VariableElement variable) {
    return _current.promoted[variable];
  }

  /// Register read of the given [variable] in the current state.
  void read(LocalVariableElement variable) {
    if (_current.notAssigned.contains(variable)) {
      // Add to the list of violating variables, if not there yet.
      for (var i = 0; i < readBeforeWritten.length; ++i) {
        var violatingVariable = readBeforeWritten[i];
        if (identical(violatingVariable, variable)) {
          return;
        }
      }
      readBeforeWritten.add(variable);
    }
  }

  /// The [notPromoted] set contains all variables that are potentially
  /// assigned in other cases that might target this with `continue`, so
  /// these variables might have different types and are "un-promoted" from
  /// the "afterExpression" state.
  void switchStatement_beginCase(Set<VariableElement> notPromoted) {
    _current = _stack.last.removePromotedAll(notPromoted);
  }

  void switchStatement_end(SwitchStatement node, bool hasDefault) {
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

  void switchStatement_expressionEnd(SwitchStatement node) {
    _statementToStackIndex[node] = _stack.length;
    _stack.add(_identity); // break
    _stack.add(_identity); // continue
    _stack.add(_current); // afterExpression
  }

  void trueLiteral(BooleanLiteral expression) {
    _condition = expression;
    _conditionTrue = _current;
    _conditionFalse = _identity;
  }

  void tryCatchStatement_bodyBegin() {
    _stack.add(_current);
    // Tail of the stack: beforeBody
  }

  void tryCatchStatement_bodyEnd(Set<VariableElement> assignedInBody) {
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

  void tryFinallyStatement_end(Set<VariableElement> assignedInFinally) {
    var afterBody = _stack.removeLast();
    _current = _current.restrict(typeOperations, afterBody, assignedInFinally);
  }

  void tryFinallyStatement_finallyBegin(Set<VariableElement> assignedInBody) {
    var beforeTry = _stack.removeLast();
    var afterBody = _current;
    _stack.add(afterBody);
    _current = _join(afterBody, beforeTry.removePromotedAll(assignedInBody));
  }

  void verifyStackEmpty() {
    assert(_stack.isEmpty);
  }

  void whileStatement_bodyBegin(WhileStatement node) {
    _conditionalEnd(node.condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();

    _statementToStackIndex[node] = _stack.length;
    _stack.add(_identity); // break
    _stack.add(_identity); // continue

    _current = trueCondition;
  }

  void whileStatement_conditionBegin(Set<VariableElement> loopAssigned) {
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
    VariableElement variable, {
    bool isNull = false,
    bool isNonNull = false,
  }) {
    _current = _current.write(variable, isNull: isNull, isNonNull: isNonNull);
  }

  void _conditionalEnd(Expression condition) {
    while (condition is ParenthesizedExpression) {
      condition = (condition as ParenthesizedExpression).expression;
    }
    if (identical(condition, _condition)) {
      _stack.add(_conditionFalse);
      _stack.add(_conditionTrue);
    } else {
      _stack.add(_current);
      _stack.add(_current);
    }
  }

  _State<T> _join(_State<T> first, _State<T> second) {
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

  Map<VariableElement, T> _joinPromoted(
    Map<VariableElement, T> first,
    Map<VariableElement, T> second,
  ) {
    if (identical(first, second)) return first;
    if (first.isEmpty || second.isEmpty) return const {};

    var result = <VariableElement, T>{};
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

/// Operations on types, abstracted from concrete type interfaces.
abstract class TypeOperations<T> {
  /// Return the static type of with the given [element].
  T elementType(VariableElement element);

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  bool isSubtypeOf(T leftType, T rightType);
}

/// List based immutable set of elements.
class _ElementSet {
  static final empty = _ElementSet._(
    List<VariableElement>(0),
  );

  final List<VariableElement> elements;

  _ElementSet._(this.elements);

  _ElementSet add(VariableElement addedElement) {
    if (contains(addedElement)) {
      return this;
    }

    var length = elements.length;
    var newElements = List<VariableElement>(length + 1);
    for (var i = 0; i < length; ++i) {
      newElements[i] = elements[i];
    }
    newElements[length] = addedElement;
    return _ElementSet._(newElements);
  }

  _ElementSet addAll(Iterable<VariableElement> elements) {
    var result = this;
    for (var element in elements) {
      result = result.add(element);
    }
    return result;
  }

  bool contains(VariableElement element) {
    var length = elements.length;
    for (var i = 0; i < length; ++i) {
      if (identical(elements[i], element)) {
        return true;
      }
    }
    return false;
  }

  _ElementSet intersect(_ElementSet other) {
    if (identical(other, empty)) return empty;

    // TODO(scheglov) optimize
    var newElements =
        elements.toSet().intersection(other.elements.toSet()).toList();

    if (newElements.isEmpty) return empty;
    return _ElementSet._(newElements);
  }

  _ElementSet remove(VariableElement removedElement) {
    if (!contains(removedElement)) {
      return this;
    }

    var length = elements.length;
    if (length == 1) {
      return empty;
    }

    var newElements = List<VariableElement>(length - 1);
    var newIndex = 0;
    for (var i = 0; i < length; ++i) {
      var element = elements[i];
      if (!identical(element, removedElement)) {
        newElements[newIndex++] = element;
      }
    }

    return _ElementSet._(newElements);
  }

  _ElementSet union(_ElementSet other) {
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

class _State<T> {
  final bool reachable;
  final _ElementSet notAssigned;
  final _ElementSet notNullable;
  final _ElementSet notNonNullable;
  final Map<VariableElement, T> promoted;

  _State(
    this.reachable,
    this.notAssigned,
    this.notNullable,
    this.notNonNullable,
    this.promoted,
  );

  /// Add a new [variable] to track definite assignment.
  _State<T> add(VariableElement variable, {bool assigned: false}) {
    var newNotAssigned = assigned ? notAssigned : notAssigned.add(variable);
    var newNotNullable = notNullable.add(variable);
    var newNotNonNullable = notNonNullable.add(variable);

    if (identical(newNotAssigned, notAssigned) &&
        identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable)) {
      return this;
    }

    return _State<T>(
      reachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      promoted,
    );
  }

  _State<T> exit() {
    return _State<T>(false, notAssigned, notNullable, notNonNullable, promoted);
  }

  _State<T> markNonNullable(VariableElement variable) {
    var newNotNullable = notNullable.add(variable);
    var newNotNonNullable = notNonNullable.remove(variable);

    if (identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable)) {
      return this;
    }

    return _State<T>(
      reachable,
      notAssigned,
      newNotNullable,
      newNotNonNullable,
      promoted,
    );
  }

  _State<T> markNullable(VariableElement variable) {
    var newNotNullable = notNullable.remove(variable);
    var newNotNonNullable = notNonNullable.add(variable);

    if (identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable)) {
      return this;
    }

    return _State<T>(
      reachable,
      notAssigned,
      newNotNullable,
      newNotNonNullable,
      promoted,
    );
  }

  _State<T> promote(
    TypeOperations<T> typeOperations,
    VariableElement variable,
    T type,
  ) {
    var previousType = promoted[variable];
    previousType ??= typeOperations.elementType(variable);

    if (typeOperations.isSubtypeOf(type, previousType) &&
        type != previousType) {
      var newPromoted = <VariableElement, T>{}..addAll(promoted);
      newPromoted[variable] = type;
      return _State<T>(
        reachable,
        notAssigned,
        notNullable,
        notNonNullable,
        newPromoted,
      );
    }

    return this;
  }

  _State<T> removePromotedAll(Set<VariableElement> variables) {
    var newNotNullable = notNullable.addAll(variables);
    var newNotNonNullable = notNonNullable.addAll(variables);
    var newPromoted = _removePromotedAll(promoted, variables);

    if (identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable) &&
        identical(newPromoted, promoted)) return this;

    return _State<T>(
      reachable,
      notAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }

  _State<T> restrict(
    TypeOperations<T> typeOperations,
    _State<T> other,
    Set<VariableElement> unsafe,
  ) {
    var newReachable = reachable && other.reachable;
    var newNotAssigned = notAssigned.intersect(other.notAssigned);

    var newNotNullable = _ElementSet.empty;
    for (var variable in notNullable.elements) {
      if (unsafe.contains(variable) || other.notNullable.contains(variable)) {
        newNotNullable = newNotNullable.add(variable);
      }
    }

    var newNotNonNullable = _ElementSet.empty;
    for (var variable in notNonNullable.elements) {
      if (unsafe.contains(variable) ||
          other.notNonNullable.contains(variable)) {
        newNotNonNullable = newNotNonNullable.add(variable);
      }
    }

    var newPromoted = <VariableElement, T>{};
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

  _State<T> setReachable(bool reachable) {
    if (this.reachable == reachable) return this;

    return _State<T>(
      reachable,
      notAssigned,
      notNullable,
      notNonNullable,
      promoted,
    );
  }

  _State<T> write(
    VariableElement variable, {
    bool isNull = false,
    bool isNonNull = false,
  }) {
    var newNotAssigned = variable is LocalVariableElement
        ? notAssigned.remove(variable)
        : notAssigned;

    var newNotNullable =
        isNull ? notNullable.remove(variable) : notNullable.add(variable);

    var newNotNonNullable = isNonNull
        ? notNonNullable.remove(variable)
        : notNonNullable.add(variable);

    var newPromoted = _removePromoted(promoted, variable);

    if (identical(newNotAssigned, notAssigned) &&
        identical(newNotNullable, notNullable) &&
        identical(newNotNonNullable, notNonNullable) &&
        identical(newPromoted, promoted)) {
      return this;
    }

    return _State<T>(
      reachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }

  Map<VariableElement, T> _removePromoted(
    Map<VariableElement, T> map,
    VariableElement variable,
  ) {
    if (map.isEmpty) return const {};

    var result = <VariableElement, T>{};
    for (var key in map.keys) {
      if (!identical(key, variable)) {
        result[key] = map[key];
      }
    }

    if (result.isEmpty) return const {};
    return result;
  }

  Map<VariableElement, T> _removePromotedAll(
    Map<VariableElement, T> map,
    Set<VariableElement> variables,
  ) {
    if (map.isEmpty) return const {};
    if (variables.isEmpty) return map;

    var result = <VariableElement, T>{};
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

  static _State<T> _identicalOrNew<T>(
    _State<T> first,
    _State<T> second,
    bool newReachable,
    _ElementSet newNotAssigned,
    _ElementSet newNotNullable,
    _ElementSet newNotNonNullable,
    Map<VariableElement, T> newPromoted,
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

    return _State<T>(
      newReachable,
      newNotAssigned,
      newNotNullable,
      newNotNonNullable,
      newPromoted,
    );
  }
}
