// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';

class FlowAnalysis {
  /// The output list of variables that were read before they were written.
  /// TODO(scheglov) use _ElementSet?
  final List<LocalVariableElement> readBeforeWritten = [];

  final TypeSystem typeSystem;
  final List<_State> _stack = [];

  _State _current;

  /// The last boolean condition, for [_conditionTrue] and [_conditionFalse].
  Expression _condition;

  /// The state when [_condition] evaluates to `true`.
  _State _conditionTrue;

  /// The state when [_condition] evaluates to `false`.
  _State _conditionFalse;

  FlowAnalysis(this.typeSystem) {
    _current = _State(false, _ElementSet.empty, const {});
  }

  /// Add a new [variable], which might be already [assigned].
  void add(LocalVariableElement variable, {bool assigned: false}) {
    if (!assigned) {
      _current = _current.add(variable);
    }
  }

  void falseLiteral(BooleanLiteral expression) {
    _condition = expression;
    _conditionTrue = _State.identity;
    _conditionFalse = _current;
  }

  /// Register the fact that the current state definitely exists, e.g. returns
  /// from the body, throws an exception, etc.
  void handleExit() {
    _current = _State.identity;
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
    _current = afterThen.combine(typeSystem, afterElse);
  }

  void ifStatement_thenBegin(IfStatement ifStatement) {
    _conditionalEnd(ifStatement.condition);
    // Tail of the stack:  falseCondition, trueCondition

    var trueCondition = _stack.removeLast();
    _current = trueCondition;
  }

  void isExpression_end(
      IsExpression isExpression, LocalElement element, DartType type) {
    // TODO(scheglov) check for mutations
    _condition = isExpression;
    if (isExpression.notOperator == null) {
      _conditionTrue = _current.promote(typeSystem, element, type);
      _conditionFalse = _current;
    } else {
      _conditionTrue = _current;
      _conditionFalse = _current.promote(typeSystem, element, type);
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
    var falseResult = falseLeft.combine(typeSystem, falseRight);
    var afterResult = trueResult.combine(typeSystem, falseResult);

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

    var trueResult = trueLeft.combine(typeSystem, trueRight);
    var falseResult = falseRight;
    var afterResult = trueResult.combine(typeSystem, falseResult);

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

  /// Retrieves the type that [element] is promoted to, if [element] is
  /// currently promoted.  Otherwise returns `null`.
  DartType promotedType(LocalElement element) {
    return _current.promoted[element];
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

  void trueLiteral(BooleanLiteral expression) {
    _condition = expression;
    _conditionTrue = _current;
    _conditionFalse = _State.identity;
  }

  void verifyStackEmpty() {
    assert(_stack.isEmpty);
  }

  /// Register write of the given [variable] in the current state.
  void write(LocalVariableElement variable) {
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
    if (other == null || other.elements.isEmpty) {
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

class _State {
  static final identity = _State(false, _ElementSet.empty, null);

  final bool reachable;
  final _ElementSet notAssigned;
  final Map<LocalElement, DartType> promoted;

  _State(this.reachable, this.notAssigned, this.promoted);

  /// Add a new [variable] to track definite assignment.
  _State add(LocalVariableElement variable) {
    var newNotAssigned = notAssigned.add(variable);
    if (identical(newNotAssigned, notAssigned)) return this;
    return _State(reachable, newNotAssigned, promoted);
  }

  _State combine(TypeSystem typeSystem, _State other) {
    if (identical(this, identity)) return other;
    if (identical(other, identity)) return this;

    var newReachable = reachable || other.reachable;
    var newNotAssigned = notAssigned.union(other.notAssigned);
    var newPromoted = _combinePromoted(typeSystem, promoted, other.promoted);

    if (reachable == newReachable &&
        identical(notAssigned, newNotAssigned) &&
        identical(promoted, newPromoted)) {
      return this;
    }
    if (other.reachable == newReachable &&
        identical(other.notAssigned, newNotAssigned) &&
        identical(other.promoted, newPromoted)) {
      return other;
    }

    return _State(newReachable, newNotAssigned, newPromoted);
  }

  _State promote(TypeSystem typeSystem, LocalElement element, DartType type) {
    var previousType = promoted[element];
    if (previousType == null) {
      if (element is LocalVariableElement) {
        previousType = element.type;
      } else if (element is ParameterElement) {
        previousType = element.type;
      } else {
        throw StateError('Unexpected type: (${element.runtimeType}) $element');
      }
    }

    if (typeSystem.isSubtypeOf(type, previousType) && type != previousType) {
      var newPromoted = <LocalElement, DartType>{}..addAll(promoted);
      newPromoted[element] = type;
      return _State(reachable, notAssigned, newPromoted);
    }

    return this;
  }

  _State write(LocalVariableElement variable) {
    var newNotAssigned = notAssigned.remove(variable);
    if (identical(newNotAssigned, notAssigned)) return this;
    return _State(reachable, newNotAssigned, promoted);
  }

  Map<LocalElement, DartType> _combinePromoted(TypeSystem typeSystem,
      Map<LocalElement, DartType> a, Map<LocalElement, DartType> b) {
    if (identical(a, b)) return a;
    if (a.isEmpty || b.isEmpty) return const {};

    var result = <LocalElement, DartType>{};
    var alwaysA = true;
    var alwaysB = true;
    for (var element in a.keys) {
      var aType = a[element];
      var bType = b[element];
      if (aType != null && bType != null) {
        if (typeSystem.isSubtypeOf(aType, bType)) {
          result[element] = bType;
          alwaysA = false;
        } else if (typeSystem.isSubtypeOf(bType, aType)) {
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
}
