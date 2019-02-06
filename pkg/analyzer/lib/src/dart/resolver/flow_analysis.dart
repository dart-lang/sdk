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
  /// The output list of variables that were read before they were written.
  /// TODO(scheglov) use _ElementSet?
  final List<LocalVariableElement> readBeforeWritten = [];

  /// The [TypeOperations], used to access types, and check subtyping.
  final TypeOperations typeOperations;

  /// The enclosing [FunctionBody], used to check for potential mutations.
  final FunctionBody functionBody;

  /// The stack of states of variables that are not definitely assigned.
  final List<_State> _stack = [];

  /// The mapping from labeled [Statement]s to the index in the [_stack]
  /// where the first related element is located.  The number of elements
  /// is statement specific.  Loops have two elements: `break` and `continue`
  /// states.
  final Map<Statement, int> _statementToStackIndex = {};

  _State _current;

  /// The last boolean condition, for [_conditionTrue] and [_conditionFalse].
  Expression _condition;

  /// The state when [_condition] evaluates to `true`.
  _State _conditionTrue;

  /// The state when [_condition] evaluates to `false`.
  _State _conditionFalse;

  FlowAnalysis(this.typeOperations, this.functionBody) {
    _current = _State(true, _ElementSet.empty, const {});
  }

  /// Return `true` if the current state is reachable.
  bool get isReachable => _current.reachable;

  /// Add a new [variable], which might be already [assigned].
  void add(LocalVariableElement variable, {bool assigned: false}) {
    if (!assigned) {
      _current = _current.add(variable);
    }
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

      var trueResult = trueThen.join(typeOperations, trueElse);
      var falseResult = falseThen.join(typeOperations, falseElse);

      _condition = node;
      _conditionTrue = trueResult;
      _conditionFalse = falseResult;
    }

    _current = afterThen.join(typeOperations, afterElse);
  }

  void conditional_thenBegin(ConditionalExpression node) {
    _conditionalEnd(node.condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  void doStatement_bodyBegin(
      DoStatement node, Set<VariableElement> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);

    _statementToStackIndex[node] = _stack.length;
    _stack.add(_State.identity); // break
    _stack.add(_State.identity); // continue
  }

  void doStatement_conditionBegin() {
    // Tail of the stack: break, continue

    var continueState = _stack.removeLast();
    _current = _current.join(typeOperations, continueState);
  }

  void doStatement_end(DoStatement node) {
    _conditionalEnd(node.condition);
    // Tail of the stack:  break, falseCondition, trueCondition

    _stack.removeLast(); // trueCondition
    var falseCondition = _stack.removeLast();
    var breakState = _stack.removeLast();

    _current = falseCondition.join(typeOperations, breakState);
  }

  void falseLiteral(BooleanLiteral expression) {
    _condition = expression;
    _conditionTrue = _State.identity;
    _conditionFalse = _current;
  }

  void forEachStatement_bodyBegin(Set<VariableElement> loopAssigned) {
    _stack.add(_current);
    _current = _current.removePromotedAll(loopAssigned);
  }

  void forEachStatement_end() {
    var afterIterable = _stack.removeLast();
    _current = _current.join(typeOperations, afterIterable);
  }

  void forStatement_bodyBegin(Statement node, Expression condition) {
    _conditionalEnd(condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();

    _statementToStackIndex[node] = _stack.length;
    _stack.add(_State.identity); // break
    _stack.add(_State.identity); // continue

    _current = trueCondition;
  }

  void forStatement_conditionBegin(Set<VariableElement> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);
  }

  void forStatement_end() {
    // Tail of the stack: falseCondition, break
    var breakState = _stack.removeLast();
    var falseCondition = _stack.removeLast();

    _current = falseCondition.join(typeOperations, breakState);
  }

  void forStatement_updaterBegin() {
    // Tail of the stack: falseCondition, break, continue
    var afterBody = _current;
    var continueState = _stack.removeLast();

    _current = afterBody.join(typeOperations, continueState);
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
      _stack[breakIndex] = _stack[breakIndex].join(typeOperations, _current);
    }
    _current = _current.exit();
  }

  void handleContinue(AstNode target) {
    var breakIndex = _statementToStackIndex[target];
    if (breakIndex != null) {
      var continueIndex = breakIndex + 1;
      _stack[continueIndex] =
          _stack[continueIndex].join(typeOperations, _current);
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
    _current = _current.join(typeOperations, afterLeft);
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
    _State afterThen;
    _State afterElse;
    if (hasElse) {
      afterThen = _stack.removeLast();
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = _stack.removeLast(); // `falseCond` is still on the stack
    }
    _current = afterThen.join(typeOperations, afterElse);
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

  void logicalAnd_end(BinaryExpression andExpression) {
    _conditionalEnd(andExpression.rightOperand);
    // Tail of the stack: falseLeft, trueLeft, falseRight, trueRight

    var trueRight = _stack.removeLast();
    var falseRight = _stack.removeLast();

    _stack.removeLast(); // trueLeft is not used
    var falseLeft = _stack.removeLast();

    var trueResult = trueRight;
    var falseResult = falseLeft.join(typeOperations, falseRight);
    var afterResult = trueResult.join(typeOperations, falseResult);

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

    var trueResult = trueLeft.join(typeOperations, trueRight);
    var falseResult = falseRight;
    var afterResult = trueResult.join(typeOperations, falseResult);

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
      _current = breakState.join(typeOperations, afterExpression);
    }
  }

  void switchStatement_expressionEnd(SwitchStatement node) {
    _statementToStackIndex[node] = _stack.length;
    _stack.add(_State.identity); // break
    _stack.add(_State.identity); // continue
    _stack.add(_current); // afterExpression
  }

  void trueLiteral(BooleanLiteral expression) {
    _condition = expression;
    _conditionTrue = _current;
    _conditionFalse = _State.identity;
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
    _stack.last = afterBodyAndCatches.join(typeOperations, _current);
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
    _current = afterBody.join(
      typeOperations,
      beforeTry.removePromotedAll(assignedInBody),
    );
  }

  void verifyStackEmpty() {
    assert(_stack.isEmpty);
  }

  void whileStatement_bodyBegin(WhileStatement node) {
    _conditionalEnd(node.condition);
    // Tail of the stack: falseCondition, trueCondition

    var trueCondition = _stack.removeLast();

    _statementToStackIndex[node] = _stack.length;
    _stack.add(_State.identity); // break
    _stack.add(_State.identity); // continue

    _current = trueCondition;
  }

  void whileStatement_conditionBegin(Set<VariableElement> loopAssigned) {
    _current = _current.removePromotedAll(loopAssigned);
  }

  void whileStatement_end() {
    _stack.removeLast(); // continue
    var breakState = _stack.removeLast();
    var falseCondition = _stack.removeLast();

    _current = falseCondition.join(typeOperations, breakState);
  }

  /// Register write of the given [variable] in the current state.
  void write(VariableElement variable) {
    _current = _current.write(variable);
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
    List<LocalVariableElement>(0),
  );

  final List<LocalVariableElement> elements;

  _ElementSet._(this.elements);

  _ElementSet add(LocalVariableElement addedElement) {
    if (contains(addedElement)) {
      return this;
    }

    var length = elements.length;
    var newElements = List<LocalVariableElement>(length + 1);
    for (var i = 0; i < length; ++i) {
      newElements[i] = elements[i];
    }
    newElements[length] = addedElement;
    return _ElementSet._(newElements);
  }

  bool contains(LocalVariableElement element) {
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

  _ElementSet remove(LocalVariableElement removedElement) {
    if (!contains(removedElement)) {
      return this;
    }

    var length = elements.length;
    if (length == 1) {
      return empty;
    }

    var newElements = List<LocalVariableElement>(length - 1);
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
  static final identity = _State(false, _ElementSet.empty, const {});

  final bool reachable;
  final _ElementSet notAssigned;
  final Map<VariableElement, T> promoted;

  _State(this.reachable, this.notAssigned, this.promoted);

  /// Add a new [variable] to track definite assignment.
  _State add(LocalVariableElement variable) {
    var newNotAssigned = notAssigned.add(variable);
    if (identical(newNotAssigned, notAssigned)) return this;
    return _State(reachable, newNotAssigned, promoted);
  }

  _State exit() {
    return _State(false, notAssigned, promoted);
  }

  _State join(TypeOperations typeOperations, _State other) {
    if (identical(this, identity)) return other;
    if (identical(other, identity)) return this;

    if (reachable && !other.reachable) return this;
    if (!reachable && other.reachable) return other;

    var newReachable = reachable || other.reachable;
    var newNotAssigned = notAssigned.union(other.notAssigned);
    var newPromoted = _joinPromoted(typeOperations, promoted, other.promoted);

    return _identicalOrNew(other, newReachable, newNotAssigned, newPromoted);
  }

  _State promote(
    TypeOperations typeOperations,
    VariableElement variable,
    T type,
  ) {
    var previousType = promoted[variable];
    previousType ??= typeOperations.elementType(variable);

    if (typeOperations.isSubtypeOf(type, previousType) &&
        type != previousType) {
      var newPromoted = <VariableElement, T>{}..addAll(promoted);
      newPromoted[variable] = type;
      return _State(reachable, notAssigned, newPromoted);
    }

    return this;
  }

  _State removePromotedAll(Set<VariableElement> variables) {
    var newPromoted = _removePromotedAll(promoted, variables);

    if (identical(newPromoted, promoted)) return this;

    return _State(reachable, notAssigned, newPromoted);
  }

  _State restrict(
    TypeOperations typeOperations,
    _State<T> other,
    Set<VariableElement> unsafe,
  ) {
    var newReachable = reachable && other.reachable;
    var newNotAssigned = notAssigned.intersect(other.notAssigned);

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

    return _identicalOrNew(other, newReachable, newNotAssigned, newPromoted);
  }

  _State setReachable(bool reachable) {
    if (this.reachable == reachable) return this;

    return _State(reachable, notAssigned, promoted);
  }

  _State write(VariableElement variable) {
    var newNotAssigned = variable is LocalVariableElement
        ? notAssigned.remove(variable)
        : notAssigned;
    var newPromoted = _removePromoted(promoted, variable);

    if (identical(newNotAssigned, notAssigned) &&
        identical(newPromoted, promoted)) {
      return this;
    }

    return _State(reachable, newNotAssigned, newPromoted);
  }

  _State _identicalOrNew(_State other, bool newReachable,
      _ElementSet newNotAssigned, Map<VariableElement, T> newPromoted) {
    if (this.reachable == newReachable &&
        identical(this, newNotAssigned) &&
        identical(other, newPromoted)) {
      return this;
    }
    if (other.reachable == newReachable &&
        identical(other.notAssigned, newNotAssigned) &&
        identical(other.promoted, newPromoted)) {
      return other;
    }

    return _State(newReachable, newNotAssigned, newPromoted);
  }

  Map<VariableElement, T> _joinPromoted(TypeOperations typeOperations,
      Map<VariableElement, T> a, Map<VariableElement, T> b) {
    if (identical(a, b)) return a;
    if (a.isEmpty || b.isEmpty) return const {};

    var result = <VariableElement, T>{};
    var alwaysA = true;
    var alwaysB = true;
    for (var element in a.keys) {
      var aType = a[element];
      var bType = b[element];
      if (aType != null && bType != null) {
        if (typeOperations.isSubtypeOf(aType, bType)) {
          result[element] = bType;
          alwaysA = false;
        } else if (typeOperations.isSubtypeOf(bType, aType)) {
          result[element] = aType;
          alwaysB = false;
        } else {
          alwaysA = false;
          alwaysB = false;
        }
      } else {
        alwaysA = false;
        alwaysB = false;
      }
    }

    if (alwaysA) return a;
    if (alwaysB) return b;
    if (result.isEmpty) return const {};
    return result;
  }

  Map<VariableElement, T> _removePromoted(
      Map<VariableElement, T> map, VariableElement variable) {
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
      Map<VariableElement, T> map, Set<VariableElement> variables) {
    if (map.isEmpty) return const {};

    var result = <VariableElement, T>{};
    for (var key in map.keys) {
      if (!variables.contains(key)) {
        result[key] = map[key];
      }
    }

    if (result.isEmpty) return const {};
    return result;
  }
}
