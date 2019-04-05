// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The implementation of the class [DartObject].
 */
import 'dart:collection';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

/**
 * The state of an object representing a boolean value.
 */
class BoolState extends InstanceState {
  /**
   * An instance representing the boolean value 'false'.
   */
  static BoolState FALSE_STATE = new BoolState(false);

  /**
   * An instance representing the boolean value 'true'.
   */
  static BoolState TRUE_STATE = new BoolState(true);

  /**
   * A state that can be used to represent a boolean whose value is not known.
   */
  static BoolState UNKNOWN_VALUE = new BoolState(null);

  /**
   * The value of this instance.
   */
  final bool value;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  BoolState(this.value);

  @override
  int get hashCode => value == null ? 0 : (value ? 2 : 3);

  @override
  bool get isBool => true;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "bool";

  @override
  bool operator ==(Object object) =>
      object is BoolState && identical(value, object.value);

  @override
  BoolState convertToBool() => this;

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value ? "true" : "false");
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is BoolState) {
      bool rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return BoolState.from(identical(value, rightValue));
    } else if (rightOperand is DynamicState) {
      return UNKNOWN_VALUE;
    }
    return FALSE_STATE;
  }

  @override
  BoolState lazyAnd(InstanceState rightOperandComputer()) {
    if (value == false) {
      return FALSE_STATE;
    }
    InstanceState rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return value == null ? UNKNOWN_VALUE : rightOperand.convertToBool();
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  BoolState lazyOr(InstanceState rightOperandComputer()) {
    if (value == true) {
      return TRUE_STATE;
    }
    InstanceState rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return value == null ? UNKNOWN_VALUE : rightOperand.convertToBool();
  }

  @override
  BoolState logicalNot() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return value ? FALSE_STATE : TRUE_STATE;
  }

  @override
  String toString() => value == null ? "-unknown-" : (value ? "true" : "false");

  /**
   * Return the boolean state representing the given boolean [value].
   */
  static BoolState from(bool value) =>
      value ? BoolState.TRUE_STATE : BoolState.FALSE_STATE;
}

/**
 * Information about a const constructor invocation.
 */
class ConstructorInvocation {
  /**
   * The constructor that was called.
   */
  final ConstructorElement constructor;

  /**
   * Values of specified arguments, actual values for positional, and `null`
   * for named (which are provided as [namedArguments]).
   */
  final List<DartObjectImpl> _argumentValues;

  /**
   * The named arguments passed to the constructor.
   */
  final Map<String, DartObjectImpl> namedArguments;

  ConstructorInvocation(
      this.constructor, this._argumentValues, this.namedArguments);

  /**
   * The positional arguments passed to the constructor.
   */
  List<DartObjectImpl> get positionalArguments {
    return _argumentValues.takeWhile((v) => v != null).toList();
  }
}

/**
 * A representation of an instance of a Dart class.
 */
class DartObjectImpl implements DartObject {
  /// When `true`, `operator==` only compares constant values, ignoring types.
  ///
  /// This is a temporary hack to work around dartbug.com/35908.
  /// TODO(paulberry): when #35908 is fixed, remove this hack.
  static bool _ignoreTypesInEqualityComparison = false;

  @override
  final ParameterizedType type;

  /**
   * The state of the object.
   */
  final InstanceState _state;

  /**
   * Initialize a newly created object to have the given [type] and [_state].
   */
  DartObjectImpl(this.type, this._state);

  /**
   * Create an object to represent an unknown value.
   */
  factory DartObjectImpl.validWithUnknownValue(ParameterizedType type) {
    if (type.element.library.isDartCore) {
      String typeName = type.name;
      if (typeName == "bool") {
        return new DartObjectImpl(type, BoolState.UNKNOWN_VALUE);
      } else if (typeName == "double") {
        return new DartObjectImpl(type, DoubleState.UNKNOWN_VALUE);
      } else if (typeName == "int") {
        return new DartObjectImpl(type, IntState.UNKNOWN_VALUE);
      } else if (typeName == "String") {
        return new DartObjectImpl(type, StringState.UNKNOWN_VALUE);
      }
    }
    return new DartObjectImpl(type, GenericState.UNKNOWN_VALUE);
  }

  Map<String, DartObjectImpl> get fields => _state.fields;

  @override
  int get hashCode => JenkinsSmiHash.hash2(type.hashCode, _state.hashCode);

  @override
  bool get hasKnownValue => !_state.isUnknown;

  /**
   * Return `true` if this object represents an object whose type is 'bool'.
   */
  bool get isBool => _state.isBool;

  /**
   * Return `true` if this object represents an object whose type is either
   * 'bool', 'num', 'String', or 'Null'.
   */
  bool get isBoolNumStringOrNull => _state.isBoolNumStringOrNull;

  /**
   * Return `true` if this object represents an object whose type is 'int'.
   */
  bool get isInt => _state.isInt;

  @override
  bool get isNull => _state is NullState;

  /**
   * Return `true` if this object represents an unknown value.
   */
  bool get isUnknown => _state.isUnknown;

  /**
   * Return `true` if this object represents an instance of a user-defined
   * class.
   */
  bool get isUserDefinedObject => _state is GenericState;

  @override
  bool operator ==(Object object) {
    if (object is DartObjectImpl) {
      return (_ignoreTypesInEqualityComparison || type == object.type) &&
          _state == object._state;
    }
    return false;
  }

  /**
   * Return the result of invoking the '+' operator on this object with the
   * given [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl add(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.add(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    } else if (result is StringState) {
      return new DartObjectImpl(typeProvider.stringType, result);
    }
    // We should never get here.
    throw new StateError("add returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '~' operator on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl bitNot(TypeProvider typeProvider) =>
      new DartObjectImpl(typeProvider.intType, _state.bitNot());

  /**
   * Return the result of casting this object to the given [castType].
   */
  DartObjectImpl castToType(TypeProvider typeProvider, TypeSystem typeSystem,
      DartObjectImpl castType) {
    _assertType(castType);
    if (isNull) {
      return this;
    }
    if (!typeSystem.isSubtypeOf(type, (castType._state as TypeState)._type)) {
      throw new EvaluationException(
          CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
    }
    return this;
  }

  /**
   * Return the result of invoking the ' ' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl concatenate(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.stringType, _state.concatenate(rightOperand._state));

  /**
   * Return the result of applying boolean conversion to this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl convertToBool(TypeProvider typeProvider) {
    InterfaceType boolType = typeProvider.boolType;
    if (identical(type, boolType)) {
      return this;
    }
    return new DartObjectImpl(boolType, _state.convertToBool());
  }

  /**
   * Return the result of invoking the '/' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for
   * an object of this kind.
   */
  DartObjectImpl divide(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.divide(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new StateError("divide returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '&' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl eagerAnd(
      TypeProvider typeProvider, DartObjectImpl rightOperand, bool allowBool) {
    if (allowBool && isBool && rightOperand.isBool) {
      return new DartObjectImpl(
          typeProvider.boolType, _state.logicalAnd(rightOperand._state));
    } else if (isInt && rightOperand.isInt) {
      return new DartObjectImpl(
          typeProvider.intType, _state.bitAnd(rightOperand._state));
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT);
  }

  /**
   * Return the result of invoking the '|' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl eagerOr(
      TypeProvider typeProvider, DartObjectImpl rightOperand, bool allowBool) {
    if (allowBool && isBool && rightOperand.isBool) {
      return new DartObjectImpl(
          typeProvider.boolType, _state.logicalOr(rightOperand._state));
    } else if (isInt && rightOperand.isInt) {
      return new DartObjectImpl(
          typeProvider.intType, _state.bitOr(rightOperand._state));
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT);
  }

  /**
   * Return the result of invoking the '^' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl eagerXor(
      TypeProvider typeProvider, DartObjectImpl rightOperand, bool allowBool) {
    if (allowBool && isBool && rightOperand.isBool) {
      return new DartObjectImpl(
          typeProvider.boolType, _state.logicalXor(rightOperand._state));
    } else if (isInt && rightOperand.isInt) {
      return new DartObjectImpl(
          typeProvider.intType, _state.bitXor(rightOperand._state));
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT);
  }

  /**
   * Return the result of invoking the '==' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl equalEqual(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    if (isNull || rightOperand.isNull) {
      return new DartObjectImpl(
          typeProvider.boolType,
          isNull && rightOperand.isNull
              ? BoolState.TRUE_STATE
              : BoolState.FALSE_STATE);
    }
    if (isBoolNumStringOrNull) {
      return new DartObjectImpl(
          typeProvider.boolType, _state.equalEqual(rightOperand._state));
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
  }

  @override
  DartObject getField(String name) {
    InstanceState state = _state;
    if (state is GenericState) {
      return state.fields[name];
    }
    return null;
  }

  /// Gets the constructor that was called to create this value, if this is a
  /// const constructor invocation. Otherwise returns null.
  ConstructorInvocation getInvocation() {
    InstanceState state = _state;
    if (state is GenericState) {
      return state.invocation;
    }
    return null;
  }

  /**
   * Return the result of invoking the '&gt;' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl greaterThan(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.greaterThan(rightOperand._state));

  /**
   * Return the result of invoking the '&gt;=' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl greaterThanOrEqual(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(typeProvider.boolType,
          _state.greaterThanOrEqual(rightOperand._state));

  /**
   * Return the result of testing whether this object has the given [testedType].
   */
  DartObjectImpl hasType(TypeProvider typeProvider, TypeSystem typeSystem,
      DartObjectImpl testedType) {
    _assertType(testedType);
    DartType typeType = (testedType._state as TypeState)._type;
    BoolState state;
    if (isNull) {
      if (typeType == typeProvider.objectType ||
          typeType == typeProvider.dynamicType ||
          typeType == typeProvider.nullType) {
        state = BoolState.TRUE_STATE;
      } else {
        state = BoolState.FALSE_STATE;
      }
    } else {
      state = BoolState.from(typeSystem.isSubtypeOf(type, typeType));
    }
    return new DartObjectImpl(typeProvider.boolType, state);
  }

  /**
   * Return the result of invoking the '~/' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl integerDivide(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.integerDivide(rightOperand._state));

  /// Indicates whether `this` is equal to [other], ignoring types both in this
  /// object and sub-objects.
  ///
  /// This is a temporary hack to work around dartbug.com/35908.
  /// TODO(paulberry): when #35908 is fixed, remove this hack.
  bool isEqualIgnoringTypesRecursively(Object other) {
    bool oldIgnoreTypesInEqualityComparison = _ignoreTypesInEqualityComparison;
    _ignoreTypesInEqualityComparison = true;
    try {
      return this == other;
    } finally {
      _ignoreTypesInEqualityComparison = oldIgnoreTypesInEqualityComparison;
    }
  }

  /**
   * Return the result of invoking the identical function on this object with
   * the [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   */
  DartObjectImpl isIdentical(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    return new DartObjectImpl(
        typeProvider.boolType, _state.isIdentical(rightOperand._state));
  }

  /**
   * Return the result of invoking the '&&' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl lazyAnd(
          TypeProvider typeProvider, DartObjectImpl rightOperandComputer()) =>
      new DartObjectImpl(typeProvider.boolType,
          _state.lazyAnd(() => rightOperandComputer()?._state));

  /**
   * Return the result of invoking the '==' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl lazyEqualEqual(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    if (isNull || rightOperand.isNull) {
      return new DartObjectImpl(
          typeProvider.boolType,
          isNull && rightOperand.isNull
              ? BoolState.TRUE_STATE
              : BoolState.FALSE_STATE);
    }
    if (isBoolNumStringOrNull) {
      return new DartObjectImpl(
          typeProvider.boolType, _state.lazyEqualEqual(rightOperand._state));
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
  }

  /**
   * Return the result of invoking the '||' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl lazyOr(
          TypeProvider typeProvider, DartObjectImpl rightOperandComputer()) =>
      new DartObjectImpl(typeProvider.boolType,
          _state.lazyOr(() => rightOperandComputer()?._state));

  /**
   * Return the result of invoking the '&lt;' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl lessThan(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.lessThan(rightOperand._state));

  /**
   * Return the result of invoking the '&lt;=' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl lessThanOrEqual(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.boolType, _state.lessThanOrEqual(rightOperand._state));

  /**
   * Return the result of invoking the '!' operator on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl logicalNot(TypeProvider typeProvider) =>
      new DartObjectImpl(typeProvider.boolType, _state.logicalNot());

  /**
   * Return the result of invoking the '&gt;&gt;&gt;' operator on this object
   * with the [rightOperand]. The [typeProvider] is the type provider used to
   * find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl logicalShiftRight(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.logicalShiftRight(rightOperand._state));

  /**
   * Return the result of invoking the '-' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl minus(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.minus(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new StateError("minus returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '-' operator on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl negated(TypeProvider typeProvider) {
    InstanceState result = _state.negated();
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new StateError("negated returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '!=' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl notEqual(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    return equalEqual(typeProvider, rightOperand).logicalNot(typeProvider);
  }

  /**
   * Return the result of converting this object to a 'String'. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the object cannot be converted to a
   * 'String'.
   */
  DartObjectImpl performToString(TypeProvider typeProvider) {
    InterfaceType stringType = typeProvider.stringType;
    if (identical(type, stringType)) {
      return this;
    }
    return new DartObjectImpl(stringType, _state.convertToString());
  }

  /**
   * Return the result of invoking the '%' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl remainder(
      TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.remainder(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new StateError("remainder returned a ${result.runtimeType}");
  }

  /**
   * Return the result of invoking the '&lt;&lt;' operator on this object with
   * the [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl shiftLeft(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.shiftLeft(rightOperand._state));

  /**
   * Return the result of invoking the '&gt;&gt;' operator on this object with
   * the [rightOperand]. The [typeProvider] is the type provider used to find
   * known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl shiftRight(
          TypeProvider typeProvider, DartObjectImpl rightOperand) =>
      new DartObjectImpl(
          typeProvider.intType, _state.shiftRight(rightOperand._state));

  /**
   * Return the result of invoking the 'length' getter on this object. The
   * [typeProvider] is the type provider used to find known types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl stringLength(TypeProvider typeProvider) =>
      new DartObjectImpl(typeProvider.intType, _state.stringLength());

  /**
   * Return the result of invoking the '*' operator on this object with the
   * [rightOperand]. The [typeProvider] is the type provider used to find known
   * types.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  DartObjectImpl times(TypeProvider typeProvider, DartObjectImpl rightOperand) {
    InstanceState result = _state.times(rightOperand._state);
    if (result is IntState) {
      return new DartObjectImpl(typeProvider.intType, result);
    } else if (result is DoubleState) {
      return new DartObjectImpl(typeProvider.doubleType, result);
    } else if (result is NumState) {
      return new DartObjectImpl(typeProvider.numType, result);
    }
    // We should never get here.
    throw new StateError("times returned a ${result.runtimeType}");
  }

  @override
  bool toBoolValue() {
    InstanceState state = _state;
    if (state is BoolState) {
      return state.value;
    }
    return null;
  }

  @override
  double toDoubleValue() {
    InstanceState state = _state;
    if (state is DoubleState) {
      return state.value;
    }
    return null;
  }

  /**
   * If this constant represents a library function or static method, returns
   * it, otherwise returns `null`.
   */
  ExecutableElement toFunctionValue() {
    InstanceState state = _state;
    return state is FunctionState ? state._element : null;
  }

  @override
  int toIntValue() {
    InstanceState state = _state;
    if (state is IntState) {
      return state.value;
    }
    return null;
  }

  @override
  List<DartObject> toListValue() {
    InstanceState state = _state;
    if (state is ListState) {
      return state._elements;
    }
    return null;
  }

  @override
  Map<DartObject, DartObject> toMapValue() {
    InstanceState state = _state;
    if (state is MapState) {
      return state._entries;
    }
    return null;
  }

  @override
  Set<DartObject> toSetValue() {
    InstanceState state = _state;
    if (state is SetState) {
      return state._elements;
    }
    return null;
  }

  @override
  String toString() => "${type.displayName} ($_state)";

  @override
  String toStringValue() {
    InstanceState state = _state;
    if (state is StringState) {
      return state.value;
    }
    return null;
  }

  @override
  String toSymbolValue() {
    InstanceState state = _state;
    if (state is SymbolState) {
      return state.value;
    }
    return null;
  }

  @override
  DartType toTypeValue() {
    InstanceState state = _state;
    if (state is TypeState) {
      return state._type;
    }
    return null;
  }

  /**
   * Throw an exception if the given [object]'s state does not represent a Type
   * value.
   */
  void _assertType(DartObjectImpl object) {
    if (object._state is! TypeState) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_TYPE);
    }
  }
}

/**
 * The state of an object representing a double.
 */
class DoubleState extends NumState {
  /**
   * A state that can be used to represent a double whose value is not known.
   */
  static DoubleState UNKNOWN_VALUE = new DoubleState(null);

  /**
   * The value of this instance.
   */
  final double value;

  /**
   * Initialize a newly created state to represent a double with the given
   * [value].
   */
  DoubleState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "double";

  @override
  bool operator ==(Object object) =>
      object is DoubleState && (value == object.value);

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value + rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value + rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value.toString());
  }

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value / rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value / rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value > rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value > rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value >= rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value >= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return IntState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      }
      double result = value / rightValue.toDouble();
      return new IntState(result.toInt());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      }
      double result = value / rightValue;
      return new IntState(result.toInt());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return IntState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue.toDouble());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value < rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value < rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value <= rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value <= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value - rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value - rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState negated() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return new DoubleState(-(value));
  }

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value % rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value % rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value * rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new DoubleState(value * rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/**
 * The state of an object representing a Dart object for which there is no type
 * information.
 */
class DynamicState extends InstanceState {
  /**
   * The unique instance of this class.
   */
  static DynamicState DYNAMIC_STATE = new DynamicState();

  @override
  bool get isBool => true;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  String get typeName => "dynamic";

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  IntState bitNot() => IntState.UNKNOWN_VALUE;

  @override
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  StringState concatenate(InstanceState rightOperand) {
    assertString(rightOperand);
    return StringState.UNKNOWN_VALUE;
  }

  @override
  BoolState convertToBool() => BoolState.UNKNOWN_VALUE;

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lazyAnd(InstanceState rightOperandComputer()) {
    assertBool(rightOperandComputer());
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lazyOr(InstanceState rightOperandComputer()) {
    InstanceState rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return rightOperand.convertToBool();
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState logicalNot() => BoolState.UNKNOWN_VALUE;

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  NumState negated() => NumState.UNKNOWN_VALUE;

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  @override
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    return IntState.UNKNOWN_VALUE;
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return _unknownNum(rightOperand);
  }

  /**
   * Return an object representing an unknown numeric value whose type is based
   * on the type of the [rightOperand].
   */
  NumState _unknownNum(InstanceState rightOperand) {
    if (rightOperand is IntState) {
      return IntState.UNKNOWN_VALUE;
    } else if (rightOperand is DoubleState) {
      return DoubleState.UNKNOWN_VALUE;
    }
    return NumState.UNKNOWN_VALUE;
  }
}

/**
 * Exception that would be thrown during the evaluation of Dart code.
 */
class EvaluationException {
  /**
   * The error code associated with the exception.
   */
  final ErrorCode errorCode;

  /**
   * Initialize a newly created exception to have the given [errorCode].
   */
  EvaluationException(this.errorCode);
}

/**
 * The state of an object representing a function.
 */
class FunctionState extends InstanceState {
  /**
   * The element representing the function being modeled.
   */
  final ExecutableElement _element;

  /**
   * Initialize a newly created state to represent the function with the given
   * [element].
   */
  FunctionState(this._element);

  @override
  int get hashCode => _element == null ? 0 : _element.hashCode;

  @override
  String get typeName => "Function";

  @override
  bool operator ==(Object object) =>
      object is FunctionState && (_element == object._element);

  @override
  StringState convertToString() {
    if (_element == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(_element.name);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (_element == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is FunctionState) {
      ExecutableElement rightElement = rightOperand._element;
      if (rightElement == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(_element == rightElement);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  String toString() => _element == null ? "-unknown-" : _element.name;
}

/**
 * The state of an object representing a Dart object for which there is no more
 * specific state.
 */
class GenericState extends InstanceState {
  /**
   * Pseudo-field that we use to represent fields in the superclass.
   */
  static String SUPERCLASS_FIELD = "(super)";

  /**
   * A state that can be used to represent an object whose state is not known.
   */
  static GenericState UNKNOWN_VALUE =
      new GenericState(new HashMap<String, DartObjectImpl>());

  /**
   * The values of the fields of this instance.
   */
  final Map<String, DartObjectImpl> _fieldMap;

  /**
   * Information about the constructor invoked to generate this instance.
   */
  final ConstructorInvocation invocation;

  /**
   * Initialize a newly created state to represent a newly created object. The
   * [fieldMap] contains the values of the fields of the instance.
   */
  GenericState(this._fieldMap, {this.invocation});

  @override
  Map<String, DartObjectImpl> get fields => _fieldMap;

  @override
  int get hashCode {
    int hashCode = 0;
    for (DartObjectImpl value in _fieldMap.values) {
      hashCode += value.hashCode;
    }
    return hashCode;
  }

  @override
  bool get isUnknown => identical(this, UNKNOWN_VALUE);

  @override
  String get typeName => "user defined type";

  @override
  bool operator ==(Object object) {
    if (object is GenericState) {
      HashSet<String> otherFields =
          new HashSet<String>.from(object._fieldMap.keys.toSet());
      for (String fieldName in _fieldMap.keys.toSet()) {
        if (_fieldMap[fieldName] != object._fieldMap[fieldName]) {
          return false;
        }
        otherFields.remove(fieldName);
      }
      for (String fieldName in otherFields) {
        if (object._fieldMap[fieldName] != _fieldMap[fieldName]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    List<String> fieldNames = _fieldMap.keys.toList();
    fieldNames.sort();
    bool first = true;
    for (String fieldName in fieldNames) {
      if (first) {
        first = false;
      } else {
        buffer.write('; ');
      }
      buffer.write(fieldName);
      buffer.write(' = ');
      buffer.write(_fieldMap[fieldName]);
    }
    return buffer.toString();
  }
}

/**
 * The state of an object representing a Dart object.
 */
abstract class InstanceState {
  /**
   * If this represents a generic dart object, return a map from its field names
   * to their values. Otherwise return null.
   */
  Map<String, DartObjectImpl> get fields => null;

  /**
   * Return `true` if this object represents an object whose type is 'bool'.
   */
  bool get isBool => false;

  /**
   * Return `true` if this object represents an object whose type is either
   * 'bool', 'num', 'String', or 'Null'.
   */
  bool get isBoolNumStringOrNull => false;

  /**
   * Return `true` if this object represents an object whose type is 'int'.
   */
  bool get isInt => false;

  /**
   * Return `true` if this object represents the value 'null'.
   */
  bool get isNull => false;

  /**
   * Return `true` if this object represents an unknown value.
   */
  bool get isUnknown => false;

  /**
   * Return the name of the type of this value.
   */
  String get typeName;

  /**
   * Return the result of invoking the '+' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  InstanceState add(InstanceState rightOperand) {
    if (this is StringState && rightOperand is StringState) {
      return concatenate(rightOperand);
    }
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Throw an exception if the given [state] does not represent a boolean value.
   */
  void assertBool(InstanceState state) {
    if (!(state is BoolState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent a boolean,
   * numeric, string or null value.
   */
  void assertBoolNumStringOrNull(InstanceState state) {
    if (!(state is BoolState ||
        state is DoubleState ||
        state is IntState ||
        state is NumState ||
        state is StringState ||
        state is NullState ||
        state is DynamicState)) {
      throw new EvaluationException(
          CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent an integer or
   * null value.
   */
  void assertIntOrNull(InstanceState state) {
    if (!(state is IntState ||
        state is NumState ||
        state is NullState ||
        state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent a boolean,
   * numeric, string or null value.
   */
  void assertNumOrNull(InstanceState state) {
    if (!(state is DoubleState ||
        state is IntState ||
        state is NumState ||
        state is NullState ||
        state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
  }

  /**
   * Throw an exception if the given [state] does not represent a String value.
   */
  void assertString(InstanceState state) {
    if (!(state is StringState || state is DynamicState)) {
      throw new EvaluationException(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
  }

  /**
   * Return the result of invoking the '&' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '~' operator on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitNot() {
    assertIntOrNull(this);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '|' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '^' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the ' ' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  StringState concatenate(InstanceState rightOperand) {
    assertString(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of applying boolean conversion to this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState convertToBool() => BoolState.FALSE_STATE;

  /**
   * Return the result of converting this object to a String.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  StringState convertToString();

  /**
   * Return the result of invoking the '/' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '==' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState equalEqual(InstanceState rightOperand);

  /**
   * Return the result of invoking the '&gt;' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '&gt;=' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '~/' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the identical function on this object with
   * the [rightOperand].
   */
  BoolState isIdentical(InstanceState rightOperand);

  /**
   * Return the result of invoking the '&&' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState lazyAnd(InstanceState rightOperandComputer()) {
    assertBool(this);
    if (convertToBool() == BoolState.FALSE_STATE) {
      return this;
    }
    InstanceState rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return rightOperand.convertToBool();
  }

  /**
   * Return the result of invoking the '==' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState lazyEqualEqual(InstanceState rightOperand);

  /**
   * Return the result of invoking the '||' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState lazyOr(InstanceState rightOperandComputer()) {
    assertBool(this);
    if (convertToBool() == BoolState.TRUE_STATE) {
      return this;
    }
    InstanceState rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return rightOperand.convertToBool();
  }

  /**
   * Return the result of invoking the '&lt;' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '&lt;=' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '&' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState logicalAnd(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    bool leftValue = convertToBool().value;
    bool rightValue = rightOperand.convertToBool().value;
    if (leftValue == null || rightValue == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(leftValue & rightValue);
  }

  /**
   * Return the result of invoking the '!' operator on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState logicalNot() {
    assertBool(this);
    return BoolState.TRUE_STATE;
  }

  /**
   * Return the result of invoking the '|' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState logicalOr(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    bool leftValue = convertToBool().value;
    bool rightValue = rightOperand.convertToBool().value;
    if (leftValue == null || rightValue == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(leftValue | rightValue);
  }

  /**
   * Return the result of invoking the '&gt;&gt;' operator on this object with
   * the [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState logicalShiftRight(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '^' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  BoolState logicalXor(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    bool leftValue = convertToBool().value;
    bool rightValue = rightOperand.convertToBool().value;
    if (leftValue == null || rightValue == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(leftValue ^ rightValue);
  }

  /**
   * Return the result of invoking the '-' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '-' operator on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState negated() {
    assertNumOrNull(this);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '%' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '&lt;&lt;' operator on this object with
   * the [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '&gt;&gt;' operator on this object with
   * the [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the 'length' getter on this object.
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  IntState stringLength() {
    assertString(this);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  /**
   * Return the result of invoking the '*' operator on this object with the
   * [rightOperand].
   *
   * Throws an [EvaluationException] if the operator is not appropriate for an
   * object of this kind.
   */
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }
}

/**
 * The state of an object representing an int.
 */
class IntState extends NumState {
  /**
   * A state that can be used to represent an int whose value is not known.
   */
  static IntState UNKNOWN_VALUE = new IntState(null);

  /**
   * The value of this instance.
   */
  final int value;

  /**
   * Initialize a newly created state to represent an int with the given
   * [value].
   */
  IntState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isInt => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "int";

  @override
  bool operator ==(Object object) =>
      object is IntState && (value == object.value);

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value + rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() + rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value & rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState bitNot() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return new IntState(~value);
  }

  @override
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value | rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value ^ rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value.toString());
  }

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return DoubleState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      } else {
        return new DoubleState(value.toDouble() / rightValue.toDouble());
      }
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() / rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return DoubleState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) > 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() > rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) >= 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() >= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue == 0) {
        throw new EvaluationException(
            CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE);
      }
      return new IntState(value ~/ rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      double result = value.toDouble() / rightValue;
      return new IntState(result.toInt());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(rightValue == value.toDouble());
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) < 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() < rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.compareTo(rightValue) <= 0);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value.toDouble() <= rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return BoolState.UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState logicalShiftRight(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue.bitLength > 31) {
        return UNKNOWN_VALUE;
      }
      if (rightValue >= 0) {
        // TODO(brianwilkerson) After the analyzer package has a minimum SDK
        // constraint that includes support for the real operator, consider
        // changing the line below to
        //   return new IntState(value >>> rightValue);
        int divisor = 1 << rightValue;
        if (divisor == 0) {
          // The `rightValue` is large enough to cause all of the non-zero bits
          // in the left operand to be shifted out of the value.
          return new IntState(0);
        }
        return new IntState(value ~/ divisor);
      }
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value - rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() - rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState negated() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return new IntState(-value);
  }

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      if (rightValue != 0) {
        return new IntState(value % rightValue);
      }
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() % rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue.bitLength > 31) {
        return UNKNOWN_VALUE;
      }
      if (rightValue >= 0) {
        return new IntState(value << rightValue);
      }
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue.bitLength > 31) {
        return UNKNOWN_VALUE;
      }
      if (rightValue >= 0) {
        return new IntState(value >> rightValue);
      }
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      if (rightOperand is DoubleState) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new IntState(value * rightValue);
    } else if (rightOperand is DoubleState) {
      double rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return new DoubleState(value.toDouble() * rightValue);
    } else if (rightOperand is DynamicState || rightOperand is NumState) {
      return UNKNOWN_VALUE;
    }
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/**
 * The state of an object representing a list.
 */
class ListState extends InstanceState {
  /**
   * The elements of the list.
   */
  final List<DartObjectImpl> _elements;

  /**
   * Initialize a newly created state to represent a list with the given
   * [elements].
   */
  ListState(this._elements);

  @override
  int get hashCode {
    int value = 0;
    int count = _elements.length;
    for (int i = 0; i < count; i++) {
      value = (value << 3) ^ _elements[i].hashCode;
    }
    return value;
  }

  @override
  String get typeName => "List";

  @override
  bool operator ==(Object object) {
    if (object is ListState) {
      List<DartObjectImpl> otherElements = object._elements;
      int count = _elements.length;
      if (otherElements.length != count) {
        return false;
      } else if (count == 0) {
        return true;
      }
      for (int i = 0; i < count; i++) {
        if (_elements[i] != otherElements[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('[');
    bool first = true;
    _elements.forEach((DartObjectImpl element) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(element);
    });
    buffer.write(']');
    return buffer.toString();
  }
}

/**
 * The state of an object representing a map.
 */
class MapState extends InstanceState {
  /**
   * The entries in the map.
   */
  final Map<DartObjectImpl, DartObjectImpl> _entries;

  /**
   * Initialize a newly created state to represent a map with the given
   * [entries].
   */
  MapState(this._entries);

  @override
  int get hashCode {
    int value = 0;
    for (DartObjectImpl key in _entries.keys.toSet()) {
      value = (value << 3) ^ key.hashCode;
    }
    return value;
  }

  @override
  String get typeName => "Map";

  @override
  bool operator ==(Object object) {
    if (object is MapState) {
      Map<DartObjectImpl, DartObjectImpl> otherElements = object._entries;
      int count = _entries.length;
      if (otherElements.length != count) {
        return false;
      } else if (count == 0) {
        return true;
      }
      for (DartObjectImpl key in _entries.keys) {
        DartObjectImpl value = _entries[key];
        DartObjectImpl otherValue = otherElements[key];
        if (value != otherValue) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('{');
    bool first = true;
    _entries.forEach((DartObjectImpl key, DartObjectImpl value) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(key);
      buffer.write(' = ');
      buffer.write(value);
    });
    buffer.write('}');
    return buffer.toString();
  }
}

/**
 * The state of an object representing the value 'null'.
 */
class NullState extends InstanceState {
  /**
   * An instance representing the boolean value 'null'.
   */
  static NullState NULL_STATE = new NullState();

  @override
  int get hashCode => 0;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isNull => true;

  @override
  String get typeName => "Null";

  @override
  bool operator ==(Object object) => object is NullState;

  @override
  BoolState convertToBool() {
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  StringState convertToString() => new StringState("null");

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(rightOperand is NullState);
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  BoolState logicalNot() {
    throw new EvaluationException(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
  }

  @override
  String toString() => "null";
}

/**
 * The state of an object representing a number of an unknown type (a 'num').
 */
class NumState extends InstanceState {
  /**
   * A state that can be used to represent a number whose value is not known.
   */
  static NumState UNKNOWN_VALUE = new NumState();

  @override
  int get hashCode => 7;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => identical(this, UNKNOWN_VALUE);

  @override
  String get typeName => "num";

  @override
  bool operator ==(Object object) => object is NumState;

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return DoubleState.UNKNOWN_VALUE;
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (rightOperand is IntState) {
      int rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      } else if (rightValue == 0) {
        throw new EvaluationException(
            CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE);
      }
    } else if (rightOperand is DynamicState) {
      return IntState.UNKNOWN_VALUE;
    }
    return IntState.UNKNOWN_VALUE;
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  NumState negated() => UNKNOWN_VALUE;

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    return UNKNOWN_VALUE;
  }

  @override
  String toString() => "-unknown-";
}

/**
 * The state of an object representing a set.
 */
class SetState extends InstanceState {
  /**
   * The elements of the set.
   */
  final Set<DartObjectImpl> _elements;

  /**
   * Initialize a newly created state to represent a set with the given
   * [elements].
   */
  SetState(this._elements);

  @override
  int get hashCode {
    int value = 0;
    for (DartObjectImpl element in _elements) {
      value = (value << 3) ^ element.hashCode;
    }
    return value;
  }

  @override
  String get typeName => "Set";

  @override
  bool operator ==(Object object) {
    if (object is SetState) {
      List<DartObjectImpl> elements = _elements.toList();
      List<DartObjectImpl> otherElements = object._elements.toList();
      int count = elements.length;
      if (otherElements.length != count) {
        return false;
      } else if (count == 0) {
        return true;
      }
      for (int i = 0; i < count; i++) {
        if (elements[i] != otherElements[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(this == rightOperand);
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('{');
    bool first = true;
    _elements.forEach((DartObjectImpl element) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(element);
    });
    buffer.write('}');
    return buffer.toString();
  }
}

/**
 * The state of an object representing a string.
 */
class StringState extends InstanceState {
  /**
   * A state that can be used to represent a double whose value is not known.
   */
  static StringState UNKNOWN_VALUE = new StringState(null);

  /**
   * The value of this instance.
   */
  final String value;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  StringState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "String";

  @override
  bool operator ==(Object object) =>
      object is StringState && (value == object.value);

  @override
  StringState concatenate(InstanceState rightOperand) {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is StringState) {
      String rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return new StringState("$value$rightValue");
    } else if (rightOperand is DynamicState) {
      return UNKNOWN_VALUE;
    }
    return super.concatenate(rightOperand);
  }

  @override
  StringState convertToString() => this;

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is StringState) {
      String rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  IntState stringLength() {
    if (value == null) {
      return IntState.UNKNOWN_VALUE;
    }
    return new IntState(value.length);
  }

  @override
  String toString() => value == null ? "-unknown-" : "'$value'";
}

/**
 * The state of an object representing a symbol.
 */
class SymbolState extends InstanceState {
  /**
   * The value of this instance.
   */
  final String value;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  SymbolState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  String get typeName => "Symbol";

  @override
  bool operator ==(Object object) =>
      object is SymbolState && (value == object.value);

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(value);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is SymbolState) {
      String rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  String toString() => value == null ? "-unknown-" : "#$value";
}

/**
 * The state of an object representing a type.
 */
class TypeState extends InstanceState {
  /**
   * The element representing the type being modeled.
   */
  final DartType _type;

  /**
   * Initialize a newly created state to represent the given [value].
   */
  TypeState(this._type);

  @override
  int get hashCode => _type?.hashCode ?? 0;

  @override
  String get typeName => "Type";

  @override
  bool operator ==(Object object) =>
      object is TypeState && (_type == object._type);

  @override
  StringState convertToString() {
    if (_type == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return new StringState(_type.displayName);
  }

  @override
  BoolState equalEqual(InstanceState rightOperand) {
    assertBoolNumStringOrNull(rightOperand);
    return isIdentical(rightOperand);
  }

  @override
  BoolState isIdentical(InstanceState rightOperand) {
    if (_type == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is TypeState) {
      DartType rightType = rightOperand._type;
      if (rightType == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(_type == rightType);
    } else if (rightOperand is DynamicState) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lazyEqualEqual(InstanceState rightOperand) {
    return isIdentical(rightOperand);
  }

  @override
  String toString() => _type?.toString() ?? "-unknown-";
}
