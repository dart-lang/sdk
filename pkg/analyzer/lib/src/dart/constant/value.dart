// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The implementation of the class [DartObject].
///
/// @docImport 'package:analyzer/src/dart/constant/evaluation.dart';
library;

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/constant/has_invalid_type.dart';
import 'package:analyzer/src/dart/constant/has_type_parameter_reference.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:meta/meta.dart';

/// The state of an object representing a boolean value.
class BoolState extends InstanceState {
  /// An instance representing the boolean value 'false'.
  static BoolState FALSE_STATE = BoolState(false);

  /// An instance representing the boolean value 'true'.
  static BoolState TRUE_STATE = BoolState(true);

  /// A state that can be used to represent a boolean whose value is not known.
  static BoolState UNKNOWN_VALUE = BoolState(null);

  /// The value of this instance.
  final bool? value;

  /// Initialize a newly created state to represent the given [value].
  BoolState(this.value);

  @override
  int get hashCode => value == null ? 0 : (value! ? 2 : 3);

  @override
  bool get isBool => true;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "bool";

  @override
  bool operator ==(Object other) =>
      other is BoolState && identical(value, other.value);

  @override
  BoolState convertToBool() => this;

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return StringState(value! ? "true" : "false");
  }

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is BoolState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return BoolState.from(identical(value, rightValue));
    }
    return FALSE_STATE;
  }

  @override
  BoolState lazyAnd(InstanceState? Function() rightOperandComputer) {
    if (value == false) {
      return FALSE_STATE;
    }
    var rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return value == null ? UNKNOWN_VALUE : rightOperand!.convertToBool();
  }

  @override
  BoolState lazyOr(InstanceState? Function() rightOperandComputer) {
    if (value == true) {
      return TRUE_STATE;
    }
    var rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return value == null ? UNKNOWN_VALUE : rightOperand!.convertToBool();
  }

  @override
  BoolState logicalNot() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return value! ? FALSE_STATE : TRUE_STATE;
  }

  @override
  String toString() =>
      value == null ? "-unknown-" : (value! ? "true" : "false");

  /// Return the boolean state representing the given boolean [value].
  static BoolState from(bool value) =>
      value ? BoolState.TRUE_STATE : BoolState.FALSE_STATE;
}

/// A valid or invalid constant used by constant evaluator.
///
/// [DartObjectImpl] represents a valid result. Note that the [DartObjectImpl]
/// could have an unknown state and still be a valid constant.
/// [InvalidConstant] represents an invalid result with error information.
sealed class Constant {}

class ConstructorInvocationImpl implements ConstructorInvocation {
  @override
  final ConstructorElement constructor;

  @override
  final List<DartObjectImpl> positionalArguments;

  @override
  final Map<String, DartObjectImpl> namedArguments;

  ConstructorInvocationImpl(
    this.constructor,
    this.positionalArguments,
    this.namedArguments,
  );

  @Deprecated('Use constructor instead')
  @override
  ConstructorElement get constructor2 => constructor;
}

/// A representation of an instance of a Dart class.
class DartObjectImpl implements DartObject, Constant {
  final TypeSystemImpl _typeSystem;

  @override
  final TypeImpl type;

  /// The state of the object.
  final InstanceState state;

  @override
  final VariableElementImpl? variable;

  /// Initialize a newly created object to have the given [type] and [state].
  factory DartObjectImpl(
    TypeSystemImpl typeSystem,
    TypeImpl type,
    InstanceState state, {
    VariableElementImpl? variable,
  }) {
    type = type.extensionTypeErasure;
    return DartObjectImpl._(typeSystem, type, state, variable: variable);
  }

  /// Creates a duplicate instance of [other], tied to [variable].
  factory DartObjectImpl.forVariable(
    DartObjectImpl other,
    VariableElementImpl variable,
  ) {
    return DartObjectImpl(
      other._typeSystem,
      other.type,
      other.state,
      variable: variable,
    );
  }

  /// Create an object to represent an unknown value.
  factory DartObjectImpl.validWithUnknownValue(
    TypeSystemImpl typeSystem,
    TypeImpl type,
  ) {
    if (type.isDartCoreBool) {
      return DartObjectImpl(typeSystem, type, BoolState.UNKNOWN_VALUE);
    } else if (type.isDartCoreDouble) {
      return DartObjectImpl(typeSystem, type, DoubleState.UNKNOWN_VALUE);
    } else if (type.isDartCoreInt) {
      return DartObjectImpl(typeSystem, type, IntState.UNKNOWN_VALUE);
    } else if (type.isDartCoreList) {
      return DartObjectImpl(
        typeSystem,
        type,
        ListState.unknown(typeSystem.typeProvider.dynamicType),
      );
    } else if (type.isDartCoreMap) {
      return DartObjectImpl(
        typeSystem,
        type,
        MapState.unknown(
          typeSystem.typeProvider.dynamicType,
          typeSystem.typeProvider.dynamicType,
        ),
      );
    } else if (type.isDartCoreSet) {
      return DartObjectImpl(
        typeSystem,
        type,
        SetState.unknown(typeSystem.typeProvider.dynamicType),
      );
    } else if (type.isDartCoreString) {
      return DartObjectImpl(typeSystem, type, StringState.UNKNOWN_VALUE);
    }
    return DartObjectImpl(typeSystem, type, GenericState({}, isUnknown: true));
  }

  /// Initialize a newly created object to have the given [type] and [state].
  DartObjectImpl._(this._typeSystem, this.type, this.state, {this.variable}) {
    if (state case GenericState state) {
      state._object = this;
    }
  }

  @override
  ConstructorInvocationImpl? get constructorInvocation {
    return state.ifTypeOrNull<GenericState>()?.invocation;
  }

  Map<String, DartObjectImpl>? get fields => state.fields;

  @override
  int get hashCode => Object.hash(type, state);

  @override
  bool get hasKnownValue => !state.isUnknown;

  /// Return `true` if this object represents an object whose type is 'bool'.
  bool get isBool => state.isBool;

  /// Return `true` if this object represents an object whose type is either
  /// 'bool', 'num', 'String', or 'Null'.
  bool get isBoolNumStringOrNull => state.isBoolNumStringOrNull;

  /// Return `true` if this object represents an object whose type is 'int'.
  bool get isInt => state.isInt;

  /// Return `true` if this object represents an object whose type is an invalid
  /// type.
  bool get isInvalid => state.isInvalid || hasInvalidType(type);

  @override
  bool get isNull => state is NullState;

  /// Return `true` if this object represents an unknown value.
  bool get isUnknown => state.isUnknown;

  /// Return `true` if this object represents an instance of a user-defined
  /// class.
  bool get isUserDefinedObject => state is GenericState;

  @visibleForTesting
  List<DartType>? get typeArguments => (state as FunctionState).typeArguments;

  @override
  @Deprecated('Use variable instead')
  VariableElement? get variable2 => variable;

  @override
  bool operator ==(Object other) {
    if (other is DartObjectImpl) {
      return _typeSystem.runtimeTypesEqual(type, other.type) &&
          state == other.state;
    }
    return false;
  }

  /// Return the result of invoking the '+' operator on this object with the
  /// given [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl add(TypeSystemImpl typeSystem, DartObjectImpl rightOperand) {
    InstanceState result = state.add(rightOperand.state);
    if (result is IntState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        result,
      );
    } else if (result is DoubleState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.doubleType,
        result,
      );
    } else if (result is StringState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.stringType,
        result,
      );
    }
    // We should never get here.
    throw StateError("add returned a ${result.runtimeType}");
  }

  /// Return the result of invoking the '~' operator on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl bitNot(TypeSystemImpl typeSystem) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.intType,
      state.bitNot(),
    );
  }

  /// Return the result of casting this object to the given [castType].
  DartObjectImpl castToType(
    TypeSystemImpl typeSystem,
    DartObjectImpl castType,
  ) {
    _assertType(castType);
    var resultType = (castType.state as TypeState)._type;

    // If we don't know the type, we cannot prove that the cast will fail.
    if (resultType == null) {
      return this;
    }

    // If any type is unresolved, we cannot prove that the cast will fail.
    if (isInvalid || castType.isInvalid) {
      return this;
    }

    // We don't know the actual value of a type parameter.
    // So, the object type might be a subtype of the result type.
    if (hasTypeParameterReference(resultType)) {
      return this;
    }

    if (!typeSystem.isSubtypeOf(type, resultType)) {
      // TODO(kallentu): Make a more specific error for casting.
      throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
    }
    return this;
  }

  /// Return the result of invoking the ' ' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl concatenate(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.stringType,
      state.concatenate(rightOperand.state),
    );
  }

  /// Return the result of applying boolean conversion to this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl convertToBool(TypeSystemImpl typeSystem) {
    var boolType = typeSystem.typeProvider.boolType;
    if (identical(type, boolType)) {
      return this;
    }
    return DartObjectImpl(typeSystem, boolType, state.convertToBool());
  }

  /// Return the result of invoking the '/' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for
  /// an object of this kind.
  DartObjectImpl divide(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    InstanceState result = state.divide(rightOperand.state);
    if (result is IntState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        result,
      );
    } else if (result is DoubleState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.doubleType,
        result,
      );
    }
    // We should never get here.
    throw StateError("divide returned a ${result.runtimeType}");
  }

  /// Return the result of invoking the '&' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl eagerAnd(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    if (isBool && rightOperand.isBool) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.boolType,
        state.logicalAnd(rightOperand.state),
      );
    } else if (isInt && rightOperand.isInt) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        state.bitAnd(rightOperand.state),
      );
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalTypeBoolInt);
  }

  /// Return the result of invoking the '|' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl eagerOr(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    if (isBool && rightOperand.isBool) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.boolType,
        state.logicalOr(rightOperand.state),
      );
    } else if (isInt && rightOperand.isInt) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        state.bitOr(rightOperand.state),
      );
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalTypeBoolInt);
  }

  /// Return the result of invoking the '^' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl eagerXor(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    if (isBool && rightOperand.isBool) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.boolType,
        state.logicalXor(rightOperand.state),
      );
    } else if (isInt && rightOperand.isInt) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        state.bitXor(rightOperand.state),
      );
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalTypeBoolInt);
  }

  /// Returns the result of invoking the '==' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl equalEqual(
    TypeSystemImpl typeSystem,
    FeatureSet featureSet,
    DartObjectImpl rightOperand,
  ) {
    if (isNull || rightOperand.isNull) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.boolType,
        isNull && rightOperand.isNull
            ? BoolState.TRUE_STATE
            : BoolState.FALSE_STATE,
      );
    }
    if (featureSet.isEnabled(Feature.patterns)) {
      if (state is DoubleState || hasPrimitiveEquality(featureSet)) {
        return DartObjectImpl(
          typeSystem,
          typeSystem.typeProvider.boolType,
          state.equalEqual(typeSystem, rightOperand.state),
        );
      }
    } else {
      if (isBoolNumStringOrNull) {
        return DartObjectImpl(
          typeSystem,
          typeSystem.typeProvider.boolType,
          state.equalEqual(typeSystem, rightOperand.state),
        );
      }
    }
    throw EvaluationException(
      featureSet.isEnabled(Feature.patterns)
          ? CompileTimeErrorCode.constEvalPrimitiveEquality
          : CompileTimeErrorCode.constEvalTypeBoolNumString,
    );
  }

  @override
  DartObject? getField(String name) {
    var state = this.state;
    if (state is GenericState) {
      return state.fields[name];
    } else if (state is RecordState) {
      return state.getField(name);
    }
    return null;
  }

  /// Gets the constructor that was called to create this value, if this is a
  /// const constructor invocation. Otherwise returns null.
  @Deprecated('Use constructorInvocation instead')
  ConstructorInvocationImpl? getInvocation() {
    return constructorInvocation;
  }

  /// Return the result of invoking the '&gt;' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl greaterThan(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.greaterThan(rightOperand.state),
    );
  }

  /// Return the result of invoking the '&gt;=' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl greaterThanOrEqual(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.greaterThanOrEqual(rightOperand.state),
    );
  }

  /// Returns `true` if this value, inside a library with the [featureSet],
  /// has primitive equality, so can be used at compile-time.
  bool hasPrimitiveEquality(FeatureSet featureSet) {
    return state.hasPrimitiveEquality(featureSet);
  }

  /// Return the result of testing whether this object has the given
  /// [testedType].
  DartObjectImpl hasType(TypeSystemImpl typeSystem, DartObjectImpl testedType) {
    _assertType(testedType);
    var typeType = (testedType.state as TypeState)._type;
    BoolState state;
    if (typeType == null) {
      state = BoolState.TRUE_STATE;
    } else {
      state = BoolState.from(typeSystem.isSubtypeOf(type, typeType));
    }
    return DartObjectImpl(typeSystem, typeSystem.typeProvider.boolType, state);
  }

  /// Return the result of invoking the '~/' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl integerDivide(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.intType,
      state.integerDivide(rightOperand.state),
    );
  }

  /// Return the result of invoking the identical function on this object with
  /// the [rightOperand].
  DartObjectImpl isIdentical2(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    // Workaround for Flutter `const kIsWeb = identical(0, 0.0)`.
    if (type.isDartCoreInt && rightOperand.type.isDartCoreDouble ||
        type.isDartCoreDouble && rightOperand.type.isDartCoreInt) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.boolType,
        BoolState.UNKNOWN_VALUE,
      );
    }

    if (!_typeSystem.runtimeTypesEqual(type, rightOperand.type)) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.boolType,
        BoolState(false),
      );
    }

    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.isIdentical(typeSystem, rightOperand.state),
    );
  }

  /// Returns the result of invoking the '&&' operator on this object with the
  /// [rightOperandComputer].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl lazyAnd(
    TypeSystemImpl typeSystem,
    DartObjectImpl Function() rightOperandComputer,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.lazyAnd(() => rightOperandComputer().state),
    );
  }

  /// Returns the result of invoking the '||' operator on this object with the
  /// [rightOperandComputer].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl lazyOr(
    TypeSystemImpl typeSystem,
    DartObjectImpl Function() rightOperandComputer,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.lazyOr(() => rightOperandComputer().state),
    );
  }

  /// Return the result of invoking the '&lt;' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl lessThan(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.lessThan(rightOperand.state),
    );
  }

  /// Return the result of invoking the '&lt;=' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl lessThanOrEqual(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.lessThanOrEqual(rightOperand.state),
    );
  }

  /// Return the result of invoking the '!' operator on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl logicalNot(TypeSystemImpl typeSystem) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.boolType,
      state.logicalNot(),
    );
  }

  /// Return the result of invoking the '&gt;&gt;&gt;' operator on this object
  /// with the [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl logicalShiftRight(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.intType,
      state.logicalShiftRight(rightOperand.state),
    );
  }

  /// Return the result of invoking the '-' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl minus(TypeSystemImpl typeSystem, DartObjectImpl rightOperand) {
    InstanceState result = state.minus(rightOperand.state);
    if (result is IntState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        result,
      );
    } else if (result is DoubleState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.doubleType,
        result,
      );
    }
    // We should never get here.
    throw StateError("minus returned a ${result.runtimeType}");
  }

  /// Return the result of invoking the '-' operator on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl negated(TypeSystemImpl typeSystem) {
    InstanceState result = state.negated();
    if (result is IntState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        result,
      );
    } else if (result is DoubleState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.doubleType,
        result,
      );
    }
    // We should never get here.
    throw StateError("negated returned a ${result.runtimeType}");
  }

  /// Returns the result of invoking the '!=' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl notEqual(
    TypeSystemImpl typeSystem,
    FeatureSet featureSet,
    DartObjectImpl rightOperand,
  ) {
    return equalEqual(
      typeSystem,
      featureSet,
      rightOperand,
    ).logicalNot(typeSystem);
  }

  /// Return the result of converting this object to a 'String'.
  ///
  /// Throws an [EvaluationException] if the object cannot be converted to a
  /// 'String'.
  DartObjectImpl performToString(TypeSystemImpl typeSystem) {
    var stringType = typeSystem.typeProvider.stringType;
    if (identical(type, stringType)) {
      return this;
    }
    return DartObjectImpl(typeSystem, stringType, state.convertToString());
  }

  /// Return the result of invoking the '%' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl remainder(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    InstanceState result = state.remainder(rightOperand.state);
    if (result is IntState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        result,
      );
    } else if (result is DoubleState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.doubleType,
        result,
      );
    }
    // We should never get here.
    throw StateError("remainder returned a ${result.runtimeType}");
  }

  /// Return the result of invoking the '&lt;&lt;' operator on this object with
  /// the [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl shiftLeft(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.intType,
      state.shiftLeft(rightOperand.state),
    );
  }

  /// Return the result of invoking the '&gt;&gt;' operator on this object with
  /// the [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl shiftRight(
    TypeSystemImpl typeSystem,
    DartObjectImpl rightOperand,
  ) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.intType,
      state.shiftRight(rightOperand.state),
    );
  }

  /// Return the result of invoking the 'length' getter on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl stringLength(TypeSystemImpl typeSystem) {
    return DartObjectImpl(
      typeSystem,
      typeSystem.typeProvider.intType,
      state.stringLength(),
    );
  }

  /// Return the result of invoking the '*' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  DartObjectImpl times(TypeSystemImpl typeSystem, DartObjectImpl rightOperand) {
    InstanceState result = state.times(rightOperand.state);
    if (result is IntState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.intType,
        result,
      );
    } else if (result is DoubleState) {
      return DartObjectImpl(
        typeSystem,
        typeSystem.typeProvider.doubleType,
        result,
      );
    }
    // We should never get here.
    throw StateError("times returned a ${result.runtimeType}");
  }

  @override
  bool? toBoolValue() {
    var state = this.state;
    if (state is BoolState) {
      return state.value;
    }
    return null;
  }

  @override
  double? toDoubleValue() {
    var state = this.state;
    if (state is DoubleState) {
      return state.value;
    }
    return null;
  }

  @override
  InternalExecutableElement? toFunctionValue() {
    var state = this.state;
    return state is FunctionState ? state.element : null;
  }

  @override
  @Deprecated('Use toFunctionValue instead')
  ExecutableElement? toFunctionValue2() {
    return toFunctionValue();
  }

  @override
  int? toIntValue() {
    var state = this.state;
    if (state is IntState) {
      return state.value;
    }
    return null;
  }

  @override
  List<DartObjectImpl>? toListValue() {
    var state = this.state;
    if (state is ListState) {
      return state.elements;
    }
    return null;
  }

  @override
  Map<DartObjectImpl, DartObjectImpl>? toMapValue() {
    var state = this.state;
    if (state is MapState) {
      return state.entries;
    }
    return null;
  }

  @override
  ({List<DartObject> positional, Map<String, DartObject> named})?
  toRecordValue() {
    if (state case RecordState(:var positionalFields, :var namedFields)) {
      return (positional: positionalFields, named: namedFields);
    } else {
      return null;
    }
  }

  @override
  Set<DartObjectImpl>? toSetValue() {
    var state = this.state;
    if (state is SetState) {
      return state.elements;
    }
    return null;
  }

  @override
  String toString() {
    return "${type.getDisplayString()} ($state)";
  }

  @override
  String? toStringValue() {
    var state = this.state;
    if (state is StringState) {
      return state.value;
    }
    return null;
  }

  @override
  String? toSymbolValue() {
    var state = this.state;
    if (state is SymbolState) {
      return state.value;
    }
    return null;
  }

  @override
  TypeImpl? toTypeValue() {
    var state = this.state;
    if (state is TypeState) {
      return state._type;
    }
    return null;
  }

  /// Return the result of type-instantiating this object as [type].
  ///
  /// [typeArguments] are the type arguments used in the instantiation.
  DartObjectImpl typeInstantiate(
    TypeSystemImpl typeSystem,
    FunctionTypeImpl type,
    List<TypeImpl> typeArguments,
  ) {
    var functionState = state as FunctionState;
    return DartObjectImpl(
      typeSystem,
      type,
      FunctionState(
        functionState.element,
        typeArguments: typeArguments,
        viaTypeAlias: functionState._viaTypeAlias,
      ),
    );
  }

  /// Set the `index` and `_name` fields for this enum constant.
  void updateEnumConstant({required int index, required String name}) {
    var fields = state.fields!;
    fields['index'] = DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.intType,
      IntState(index),
    );
    fields['_name'] = DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.stringType,
      StringState(name),
    );
  }

  /// Throw an exception if the given [object]'s state does not represent a Type
  /// value.
  void _assertType(DartObjectImpl object) {
    if (object.state is! TypeState) {
      throw EvaluationException(CompileTimeErrorCode.constEvalTypeType);
    }
  }
}

/// The state of an object representing a double.
class DoubleState extends NumState {
  /// A state that can be used to represent a double whose value is not known.
  static DoubleState UNKNOWN_VALUE = DoubleState(null);

  /// The value of this instance.
  final double? value;

  /// Initialize a newly created state to represent a double with the given
  /// [value].
  DoubleState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "double";

  @override
  bool operator ==(Object other) =>
      other is DoubleState && identical(value, other.value);

  @override
  NumState add(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! + rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! + rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return StringState(value.toString());
  }

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! / rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! / rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! > rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! > rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! >= rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! >= rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return IntState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      }
      var result = value! / rightValue.toDouble();
      if (result.isFinite) {
        return IntState(result.toInt());
      }
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return IntState.UNKNOWN_VALUE;
      }
      double result = value! / rightValue;
      if (result.isFinite) {
        return IntState(result.toInt());
      }
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    var value = this.value;
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    } else if (value.isNaN) {
      // `double.nan` equality will always be `false`.
      return BoolState.FALSE_STATE;
    }
    if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      } else if (rightValue.isNaN) {
        // `double.nan` equality will always be `false`.
        return BoolState.FALSE_STATE;
      }
      return BoolState.from(identical(value, rightValue));
    } else if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(identical(value, rightValue.toDouble()));
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! < rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! < rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! <= rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value! <= rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! - rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! - rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  NumState negated() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return DoubleState(-value!);
  }

  @override
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! % rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! % rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! * rightValue.toDouble());
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return DoubleState(value! * rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/// Exception that would be thrown during the evaluation of Dart code.
class EvaluationException {
  /// The diagnostic code associated with the exception.
  final DiagnosticCode diagnosticCode;

  /// Returns `true` if the evaluation exception is a runtime exception.
  final bool isRuntimeException;

  /// Initialize a newly created exception to have the given [diagnosticCode].
  EvaluationException(this.diagnosticCode, {this.isRuntimeException = false});
}

/// The state of an object representing a function.
class FunctionState extends InstanceState {
  /// The element representing the function being modeled.
  final ExecutableElementImpl element;

  final List<TypeImpl>? typeArguments;

  /// The type alias which was referenced when tearing off a constructor,
  /// if this function is a constructor tear-off, referenced via a type alias,
  /// and the type alias is not a proper rename for the class, and the
  /// constructor tear-off is generic, so the tear-off cannot be considered
  /// equivalent to tearing off the associated constructor function of the
  /// aliased class.
  ///
  /// Otherwise null.
  final TypeDefiningElement? _viaTypeAlias;

  /// Initialize a newly created state to represent the function with the given
  /// [element].
  FunctionState(
    this.element, {
    this.typeArguments,
    TypeDefiningElement? viaTypeAlias,
  }) : _viaTypeAlias = viaTypeAlias;

  @override
  int get hashCode => element.hashCode;

  @override
  String get typeName => "Function";

  @override
  bool operator ==(Object other) {
    if (other is! FunctionState) {
      return false;
    }
    if (element != other.element) {
      return false;
    }
    var typeArguments = this.typeArguments;
    var otherTypeArguments = other.typeArguments;
    if (typeArguments == null || otherTypeArguments == null) {
      return typeArguments == null && otherTypeArguments == null;
    }
    if (typeArguments.length != otherTypeArguments.length) {
      return false;
    }
    if (_viaTypeAlias != other._viaTypeAlias) {
      return false;
    }
    for (var i = 0; i < typeArguments.length; i++) {
      if (typeArguments[i] != otherTypeArguments[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  StringState convertToString() => StringState(element.name);

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (rightOperand is FunctionState) {
      var otherElement = rightOperand.element;
      if (element.baseElement != otherElement.baseElement) {
        return BoolState.FALSE_STATE;
      }
      if (_viaTypeAlias != rightOperand._viaTypeAlias) {
        return BoolState.FALSE_STATE;
      }
      var typeArguments = this.typeArguments;
      var otherTypeArguments = rightOperand.typeArguments;
      if (typeArguments == null || otherTypeArguments == null) {
        return BoolState.from(
          typeArguments == null && otherTypeArguments == null,
        );
      }
      if (typeArguments.length != otherTypeArguments.length) {
        return BoolState.FALSE_STATE;
      }
      for (var i = 0; i < typeArguments.length; i++) {
        if (!typeSystem.runtimeTypesEqual(
          typeArguments[i],
          otherTypeArguments[i],
        )) {
          return BoolState.FALSE_STATE;
        }
      }
      return BoolState.TRUE_STATE;
    }
    return BoolState.FALSE_STATE;
  }

  @override
  String toString() => element.name ?? '<unnamed>';
}

/// The state of an object representing a Dart object for which there is no more
/// specific state.
class GenericState extends InstanceState {
  /// Pseudo-field that we use to represent fields in the superclass.
  static String SUPERCLASS_FIELD = "(super)";

  /// The enclosing [DartObjectImpl].
  late DartObjectImpl _object;

  /// The values of the fields of this instance.
  final Map<String, DartObjectImpl> _fieldMap;

  /// Information about the constructor invoked to generate this instance.
  final ConstructorInvocationImpl? invocation;

  @override
  final bool isUnknown;

  GenericState(this._fieldMap, {this.invocation, this.isUnknown = false});

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
  String get typeName => "user defined type";

  @override
  bool operator ==(Object other) {
    if (other is GenericState) {
      HashSet<String> otherFields = HashSet<String>.from(
        other._fieldMap.keys.toSet(),
      );
      for (String fieldName in _fieldMap.keys.toSet()) {
        if (_fieldMap[fieldName] != other._fieldMap[fieldName]) {
          return false;
        }
        otherFields.remove(fieldName);
      }
      for (String fieldName in otherFields) {
        if (other._fieldMap[fieldName] != _fieldMap[fieldName]) {
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
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) {
    var type = _object.type;
    if (type is InterfaceTypeImpl) {
      bool isFromDartCoreObject(ExecutableElement? element) {
        var enclosing = element?.enclosingElement;
        return enclosing is ClassElement && enclosing.isDartCoreObject;
      }

      var element = type.element;
      var library = element.library;

      var eqEq = type.lookUpMethod('==', library, concrete: true);
      if (!isFromDartCoreObject(eqEq)) {
        return false;
      }

      if (featureSet.isEnabled(Feature.patterns)) {
        var hash = type.lookUpGetter('hashCode', library, concrete: true);
        if (!isFromDartCoreObject(hash)) {
          return false;
        }
      }

      return true;
    } else {
      return false;
    }
  }

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return BoolState.from(this == rightOperand);
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
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

/// The state of an object representing a Dart object.
abstract class InstanceState {
  /// If this represents a generic dart object, return a map from its field
  /// names to their values. Otherwise return null.
  Map<String, DartObjectImpl>? get fields => null;

  /// Return `true` if this object represents an object whose type is 'bool'.
  bool get isBool => false;

  /// Return `true` if this object represents an object whose type is either
  /// 'bool', 'num', 'String', or 'Null'.
  bool get isBoolNumStringOrNull => false;

  /// Return `true` if this object represents an object whose type is 'int'.
  bool get isInt => false;

  /// Return `true` if this object represents an object whose type is an invalid
  /// type.
  bool get isInvalid => false;

  /// Return `true` if this object represents the value 'null'.
  bool get isNull => false;

  /// Return `true` if this object represents an unknown value.
  bool get isUnknown => false;

  /// Return the name of the type of this value.
  String get typeName;

  /// Returns the result of invoking the '+' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  InstanceState add(InstanceState rightOperand) {
    if (this is StringState && rightOperand is StringState) {
      return concatenate(rightOperand);
    }
    assertNumStringOrNull(this);
    assertNumStringOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Throws an exception if the given [state] does not represent a `bool`
  /// value.
  void assertBool(InstanceState? state) {
    if (state is! BoolState) {
      throw EvaluationException(CompileTimeErrorCode.constEvalTypeBool);
    }
  }

  /// Throws an exception if the given [state] does not represent an `int` or
  /// `null` value.
  void assertIntOrNull(InstanceState state) {
    if (!(state is IntState || state is NullState)) {
      throw EvaluationException(CompileTimeErrorCode.constEvalTypeInt);
    }
  }

  /// Throws an exception if the given [state] does not represent a `num` or
  /// `null` value.
  void assertNumOrNull(InstanceState state) {
    if (!(state is NumState || state is NullState)) {
      throw EvaluationException(CompileTimeErrorCode.constEvalTypeNum);
    }
  }

  /// Throws an exception if the given [state] does not represent a `num`,
  /// `String`, or `null` value.
  void assertNumStringOrNull(InstanceState state) {
    if (!(state is NumState || state is StringState || state is NullState)) {
      throw EvaluationException(CompileTimeErrorCode.constEvalTypeNumString);
    }
  }

  /// Throws an exception if the given [state] does not represent a `String`
  /// value.
  void assertString(InstanceState state) {
    if (state is! StringState) {
      throw EvaluationException(CompileTimeErrorCode.constEvalTypeString);
    }
  }

  /// Return the result of invoking the '&' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '~' operator on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState bitNot() {
    assertIntOrNull(this);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '|' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '^' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the ' ' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  StringState concatenate(InstanceState rightOperand) {
    assertString(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of applying boolean conversion to this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState convertToBool() => BoolState.FALSE_STATE;

  /// Return the result of converting this object to a String.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  StringState convertToString();

  /// Return the result of invoking the '/' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '==' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand);

  /// Return the result of invoking the '&gt;' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '&gt;=' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Returns `true` if this value, inside a library with the [featureSet],
  /// has primitive equality, so can be used at compile-time.
  bool hasPrimitiveEquality(FeatureSet featureSet) => false;

  /// Return the result of invoking the '~/' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the identical function on this object with
  /// the [rightOperand].
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand);

  /// Returns the result of invoking the '&&' operator on this object with the
  /// [rightOperandComputer].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState lazyAnd(InstanceState? Function() rightOperandComputer) {
    assertBool(this);
    if (convertToBool() == BoolState.FALSE_STATE) {
      return this as BoolState;
    }
    var rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return rightOperand!.convertToBool();
  }

  /// Returns the result of invoking the '||' operator on this object with the
  /// [rightOperandComputer].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState lazyOr(InstanceState? Function() rightOperandComputer) {
    assertBool(this);
    if (convertToBool() == BoolState.TRUE_STATE) {
      return this as BoolState;
    }
    var rightOperand = rightOperandComputer();
    assertBool(rightOperand);
    return rightOperand!.convertToBool();
  }

  /// Return the result of invoking the '&lt;' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '&lt;=' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '&' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState logicalAnd(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    var leftValue = convertToBool().value;
    var rightValue = rightOperand.convertToBool().value;
    if (leftValue == null || rightValue == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(leftValue & rightValue);
  }

  /// Return the result of invoking the '!' operator on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState logicalNot() {
    assertBool(this);
    return BoolState.TRUE_STATE;
  }

  /// Return the result of invoking the '|' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState logicalOr(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    var leftValue = convertToBool().value;
    var rightValue = rightOperand.convertToBool().value;
    if (leftValue == null || rightValue == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(leftValue | rightValue);
  }

  /// Return the result of invoking the '&gt;&gt;&gt;' operator on this object
  /// with the [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState logicalShiftRight(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '^' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  BoolState logicalXor(InstanceState rightOperand) {
    assertBool(this);
    assertBool(rightOperand);
    var leftValue = convertToBool().value;
    var rightValue = rightOperand.convertToBool().value;
    if (leftValue == null || rightValue == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    return BoolState.from(leftValue ^ rightValue);
  }

  /// Return the result of invoking the '-' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  NumState minus(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '-' operator on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  NumState negated() {
    assertNumOrNull(this);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '%' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  NumState remainder(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '&lt;&lt;' operator on this object with
  /// the [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '&gt;&gt;' operator on this object with
  /// the [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(this);
    assertIntOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the 'length' getter on this object.
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  IntState stringLength() {
    assertString(this);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  /// Return the result of invoking the '*' operator on this object with the
  /// [rightOperand].
  ///
  /// Throws an [EvaluationException] if the operator is not appropriate for an
  /// object of this kind.
  NumState times(InstanceState rightOperand) {
    assertNumOrNull(this);
    assertNumOrNull(rightOperand);
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }
}

/// The state of an object representing an int.
class IntState extends NumState {
  /// A state that can be used to represent an int whose value is not known.
  static IntState UNKNOWN_VALUE = IntState(null);

  /// The value of this instance.
  final int? value;

  /// Initialize a newly created state to represent an int with the given
  /// [value].
  IntState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  bool get isInt => true;

  @override
  bool get isUnknown => value == null;

  @override
  String get typeName => "int";

  @override
  bool operator ==(Object other) => other is IntState && (value == other.value);

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
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return IntState(value! + rightValue);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return DoubleState(value!.toDouble() + rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  IntState bitAnd(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return IntState(value! & rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  IntState bitNot() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return IntState(~value!);
  }

  @override
  IntState bitOr(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return IntState(value! | rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  IntState bitXor(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return IntState(value! ^ rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return StringState(value.toString());
  }

  @override
  NumState divide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return DoubleState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      } else {
        return DoubleState(value!.toDouble() / rightValue.toDouble());
      }
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return DoubleState(value!.toDouble() / rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState greaterThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.compareTo(rightValue) > 0);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.toDouble() > rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState greaterThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.compareTo(rightValue) >= 0);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.toDouble() >= rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  IntState integerDivide(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue == 0) {
        throw EvaluationException(
          CompileTimeErrorCode.constEvalThrowsIdbze,
          isRuntimeException: true,
        );
      }
      return IntState(value! ~/ rightValue);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      double result = value!.toDouble() / rightValue;
      if (result.isFinite) {
        return IntState(result.toInt());
      }
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(rightValue == value!.toDouble());
    }
    return BoolState.FALSE_STATE;
  }

  @override
  BoolState lessThan(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.compareTo(rightValue) < 0);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.toDouble() < rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  BoolState lessThanOrEqual(InstanceState rightOperand) {
    assertNumOrNull(rightOperand);
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.compareTo(rightValue) <= 0);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value!.toDouble() <= rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  IntState logicalShiftRight(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue >= 64) {
        return IntState(0);
      } else if (rightValue >= 0) {
        // TODO(srawlins): Replace with real operator once stable, like:
        //     return new IntState(value >>> rightValue);
        return IntState(
          (value! >> rightValue) & ((1 << (64 - rightValue)) - 1),
        );
      }
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
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
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return IntState(value! - rightValue);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return DoubleState(value!.toDouble() - rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  NumState negated() {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    return IntState(-value!);
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
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      if (rightValue != 0) {
        return IntState(value! % rightValue);
      }
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return DoubleState(value!.toDouble() % rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  IntState shiftLeft(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue.bitLength > 31) {
        return UNKNOWN_VALUE;
      }
      if (rightValue >= 0) {
        return IntState(value! << rightValue);
      }
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  IntState shiftRight(InstanceState rightOperand) {
    assertIntOrNull(rightOperand);
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is IntState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      } else if (rightValue.bitLength > 31) {
        return UNKNOWN_VALUE;
      }
      if (rightValue >= 0) {
        return IntState(value! >> rightValue);
      }
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
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
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return IntState(value! * rightValue);
    } else if (rightOperand is DoubleState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return DoubleState.UNKNOWN_VALUE;
      }
      return DoubleState(value!.toDouble() * rightValue);
    }
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  String toString() => value == null ? "-unknown-" : value.toString();
}

/// An invalid constant that contains diagnostic information.
class InvalidConstant implements Constant {
  /// The offset of the entity that the evaluation error is reported at.
  final int offset;

  /// The length of the entity that the evaluation error is reported at.
  final int length;

  /// The diagnostic code that is being reported.
  final DiagnosticCode diagnosticCode;

  /// The arguments required to complete the message.
  final List<Object> arguments;

  /// Additional context messages for the error, including stack trace
  /// information if the error occurs within a constructor.
  final List<DiagnosticMessage> contextMessages;

  /// Whether to omit reporting this error.
  ///
  /// If set to `true`, error reporting will ignore this invalid constant.
  /// Defaults to `false`.
  ///
  /// The `ConstantVisitor` can change this to `true` when there's already an
  /// error reported and this invalid constant would be an unnecessary follow-on
  /// error.
  bool avoidReporting;

  /// Whether this error was an exception thrown during constant evaluation.
  ///
  /// In [ConstantEvaluationEngine.evaluateAndFormatErrorsInConstructorCall],
  /// we convert this error into a
  /// [CompileTimeErrorCode.constEvalThrowsException] with a context message
  /// pointing to where the exception was thrown.
  final bool isRuntimeException;

  /// Whether the constant evaluation encounters an unresolved expression.
  final bool isUnresolved;

  /// Creates a duplicate instance of [other], with a different [entity].
  factory InvalidConstant.copyWithEntity({
    required InvalidConstant other,
    required SyntacticEntity entity,
  }) {
    return InvalidConstant.forEntity(
      entity: entity,
      diagnosticCode: other.diagnosticCode,
      arguments: other.arguments,
      contextMessages: other.contextMessages,
      avoidReporting: other.avoidReporting,
      isUnresolved: other.isUnresolved,
      isRuntimeException: other.isRuntimeException,
    );
  }

  /// Creates a constant evaluation error associated with an [element].
  InvalidConstant.forElement({
    required Element element,
    required DiagnosticCode diagnosticCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    bool avoidReporting = false,
    bool isUnresolved = false,
    bool isRuntimeException = false,
  }) : this._(
         length: element.name!.length,
         offset: element.firstFragment.nameOffset ?? -1,
         diagnosticCode: diagnosticCode,
         arguments: arguments,
         contextMessages: contextMessages,
         avoidReporting: avoidReporting,
         isUnresolved: isUnresolved,
         isRuntimeException: isRuntimeException,
       );

  /// Creates a constant evaluation error associated with a token or node
  /// [entity].
  InvalidConstant.forEntity({
    required SyntacticEntity entity,
    required DiagnosticCode diagnosticCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    bool avoidReporting = false,
    bool isUnresolved = false,
    bool isRuntimeException = false,
  }) : this._(
         offset: entity.offset,
         length: entity.length,
         diagnosticCode: diagnosticCode,
         arguments: arguments,
         contextMessages: contextMessages,
         avoidReporting: avoidReporting,
         isUnresolved: isUnresolved,
         isRuntimeException: isRuntimeException,
       );

  /// Creates a generic error depending on the [node] provided.
  factory InvalidConstant.genericError({
    required AstNode node,
    bool isUnresolved = false,
  }) {
    var parent = node.parent;
    var parent2 = parent?.parent;
    if (parent is ArgumentList &&
        parent2 is InstanceCreationExpression &&
        parent2.isConst) {
      return InvalidConstant.forEntity(
        entity: node,
        diagnosticCode: CompileTimeErrorCode.constWithNonConstantArgument,
        isUnresolved: isUnresolved,
      );
    }
    return InvalidConstant.forEntity(
      entity: node,
      diagnosticCode: CompileTimeErrorCode.invalidConstant,
      isUnresolved: isUnresolved,
    );
  }

  InvalidConstant._({
    required this.offset,
    required this.length,
    required this.diagnosticCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    this.avoidReporting = false,
    this.isUnresolved = false,
    this.isRuntimeException = false,
  }) : arguments = arguments ?? [],
       contextMessages = contextMessages ?? [];
}

/// The state of an object representing a list.
class ListState extends InstanceState {
  final TypeImpl elementType;
  final List<DartObjectImpl> elements;

  @override
  final bool isUnknown;

  ListState({
    required TypeImpl elementType,
    required this.elements,
    this.isUnknown = false,
  }) : elementType = elementType.extensionTypeErasure;

  /// Creates a state that represents a list whose value is not known.
  factory ListState.unknown(TypeImpl elementType) =>
      ListState(elementType: elementType, elements: [], isUnknown: true);

  @override
  int get hashCode {
    int value = 0;
    int count = elements.length;
    for (int i = 0; i < count; i++) {
      value = (value << 3) ^ elements[i].hashCode;
    }
    return value;
  }

  @override
  String get typeName => "List";

  @override
  bool operator ==(Object other) {
    if (other is ListState) {
      List<DartObjectImpl> otherElements = other.elements;
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
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (isUnknown || rightOperand.isUnknown) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is! ListState) {
      return BoolState.FALSE_STATE;
    }
    return BoolState.from(
      typeSystem.normalize(elementType) ==
              typeSystem.normalize(rightOperand.elementType) &&
          this == rightOperand,
    );
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('[');
    bool first = true;
    for (var element in elements) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(element);
    }
    buffer.write(']');
    return buffer.toString();
  }
}

/// The state of an object representing a map.
class MapState extends InstanceState {
  final TypeImpl _keyType;

  final TypeImpl _valueType;

  /// The entries in the map.
  final Map<DartObjectImpl, DartObjectImpl> entries;

  /// Whether the map contains an entry that has an unknown value.
  final bool _isUnknown;

  /// Initializes a newly created state to represent a set with the given
  /// [entries].
  MapState({
    required TypeImpl keyType,
    required TypeImpl valueType,
    required this.entries,
    bool isUnknown = false,
  }) : _keyType = keyType.extensionTypeErasure,
       _valueType = valueType.extensionTypeErasure,
       _isUnknown = isUnknown;

  /// Creates a state that represents a map whose value is not known.
  factory MapState.unknown(TypeImpl keyType, TypeImpl valueType) => MapState(
    keyType: keyType,
    valueType: valueType,
    entries: {},
    isUnknown: true,
  );

  @override
  int get hashCode {
    int value = 0;
    for (DartObjectImpl key in entries.keys.toSet()) {
      value = (value << 3) ^ key.hashCode;
    }
    return value;
  }

  @override
  bool get isUnknown => _isUnknown;

  @override
  String get typeName => "Map";

  @override
  bool operator ==(Object other) {
    if (other is MapState) {
      Map<DartObjectImpl, DartObjectImpl> otherElements = other.entries;
      int count = entries.length;
      if (otherElements.length != count) {
        return false;
      } else if (count == 0) {
        return true;
      }
      for (DartObjectImpl key in entries.keys) {
        var value = entries[key];
        var otherValue = otherElements[key];
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
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (isUnknown || rightOperand.isUnknown) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is! MapState) {
      return BoolState.FALSE_STATE;
    }
    return BoolState.from(
      typeSystem.normalize(_keyType) ==
              typeSystem.normalize(rightOperand._keyType) &&
          typeSystem.normalize(_valueType) ==
              typeSystem.normalize(rightOperand._valueType) &&
          this == rightOperand,
    );
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('{');
    bool first = true;
    entries.forEach((DartObjectImpl key, DartObjectImpl value) {
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

/// The state of an object representing the value 'null'.
class NullState extends InstanceState {
  /// An instance representing the boolean value 'null'.
  static NullState NULL_STATE = NullState();

  @override
  final bool isInvalid;

  NullState({this.isInvalid = false});

  @override
  int get hashCode => 0;

  @override
  bool get isBoolNumStringOrNull => true;

  @override
  bool get isNull => true;

  @override
  String get typeName => "Null";

  @override
  bool operator ==(Object other) => other is NullState;

  @override
  BoolState convertToBool() {
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  StringState convertToString() => StringState("null");

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return BoolState.from(rightOperand is NullState);
  }

  @override
  BoolState logicalNot() {
    throw EvaluationException(CompileTimeErrorCode.constEvalThrowsException);
  }

  @override
  String toString() => "null";
}

/// The state of an object representing a number.
abstract class NumState extends InstanceState {
  @override
  bool get isBoolNumStringOrNull => true;

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }
}

/// The state of an object representing a record.
class RecordState extends InstanceState {
  /// The values of the positional fields.
  final List<DartObjectImpl> positionalFields;

  /// The values of the named fields.
  final Map<String, DartObjectImpl> namedFields;

  @override
  late final hashCode = Object.hashAll([
    ...positionalFields,
    ...namedFields.values,
  ]);

  /// Initialize a newly created state to represent a record with the given
  /// values of [positionalFields] and [namedFields].
  RecordState(this.positionalFields, this.namedFields);

  @override
  String get typeName => 'Record';

  @override
  bool operator ==(Object other) {
    if (other is! RecordState) {
      return false;
    }
    var positionalCount = positionalFields.length;
    var otherPositionalFields = other.positionalFields;
    if (otherPositionalFields.length != positionalCount) {
      return false;
    }
    var namedCount = namedFields.length;
    var otherNamedFields = other.namedFields;
    if (otherNamedFields.length != namedCount) {
      return false;
    }
    for (var i = 0; i < positionalCount; i++) {
      if (positionalFields[i] != otherPositionalFields[i]) {
        return false;
      }
    }
    for (var entry in namedFields.entries) {
      var otherValue = otherNamedFields[entry.key];
      if (otherValue == null) {
        return false;
      }
      if (entry.value != otherValue) {
        return false;
      }
    }
    return true;
  }

  @override
  // The behavior of `toString` is undefined.
  StringState convertToString() => StringState.UNKNOWN_VALUE;

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  /// Returns the value of the field with the given [name].
  DartObject? getField(String name) {
    var index = RecordTypeExtension.positionalFieldIndex(name);
    if (index != null && index < positionalFields.length) {
      return positionalFields[index];
    } else {
      return namedFields[name];
    }
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) {
    return [
      ...positionalFields,
      ...namedFields.values,
    ].every((e) => e.hasPrimitiveEquality(featureSet));
  }

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (this != rightOperand) {
      return BoolState.FALSE_STATE;
    }
    return BoolState.UNKNOWN_VALUE;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write('(');
    bool first = true;
    for (var value in positionalFields) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(value);
    }
    var entries = namedFields.entries.toList();
    if (entries.isNotEmpty) {
      entries.sort((first, second) => first.key.compareTo(second.key));
      if (!first) {
        buffer.write(', ');
        first = true;
      }
      buffer.write('{');
      for (var entry in entries) {
        if (first) {
          first = false;
        } else {
          buffer.write(', ');
        }
        buffer.write(entry.key);
        buffer.write(': ');
        buffer.write(entry.value);
      }
      buffer.write('}');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

/// The state of an object representing a set.
class SetState extends InstanceState {
  final TypeImpl _elementType;

  /// The elements of the set.
  final Set<DartObjectImpl> elements;

  /// Whether the set contains an entry that has an unknown value.
  final bool _isUnknown;

  /// Initializes a newly created state to represent a set with the given
  /// [elements].
  SetState({
    required TypeImpl elementType,
    required this.elements,
    bool isUnknown = false,
  }) : _elementType = elementType.extensionTypeErasure,
       _isUnknown = isUnknown;

  /// Creates a state that represents a list whose value is not known.
  factory SetState.unknown(TypeImpl elementType) =>
      SetState(elementType: elementType, elements: {}, isUnknown: true);

  @override
  int get hashCode {
    int value = 0;
    for (DartObjectImpl element in elements) {
      value = (value << 3) ^ element.hashCode;
    }
    return value;
  }

  @override
  bool get isUnknown => _isUnknown;

  @override
  String get typeName => "Set";

  @override
  bool operator ==(Object other) {
    if (other is SetState) {
      List<DartObjectImpl> currentElements = elements.toList();
      List<DartObjectImpl> otherElements = other.elements.toList();
      int count = currentElements.length;
      if (otherElements.length != count) {
        return false;
      } else if (count == 0) {
        return true;
      }
      for (int i = 0; i < count; i++) {
        if (currentElements[i] != otherElements[i]) {
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
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (isUnknown || rightOperand.isUnknown) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is! SetState) {
      return BoolState.FALSE_STATE;
    }
    return BoolState.from(
      typeSystem.normalize(_elementType) ==
              typeSystem.normalize(rightOperand._elementType) &&
          this == rightOperand,
    );
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('{');
    bool first = true;
    for (var element in elements) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(element);
    }
    buffer.write('}');
    return buffer.toString();
  }
}

/// The state of an object representing a string.
class StringState extends InstanceState {
  /// A state that can be used to represent a string whose value is not known.
  static StringState UNKNOWN_VALUE = StringState(null);

  /// The value of this instance.
  final String? value;

  /// Initialize a newly created state to represent the given [value].
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
  bool operator ==(Object other) =>
      other is StringState && (value == other.value);

  @override
  StringState concatenate(InstanceState rightOperand) {
    if (value == null) {
      return UNKNOWN_VALUE;
    }
    if (rightOperand is StringState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return UNKNOWN_VALUE;
      }
      return StringState("$value$rightValue");
    }
    return super.concatenate(rightOperand);
  }

  @override
  StringState convertToString() => this;

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is StringState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    }
    return BoolState.FALSE_STATE;
  }

  @override
  IntState stringLength() {
    if (value == null) {
      return IntState.UNKNOWN_VALUE;
    }
    return IntState(value!.length);
  }

  @override
  String toString() => value == null ? "-unknown-" : "'$value'";
}

/// The state of an object representing a symbol.
class SymbolState extends InstanceState {
  /// The value of this instance.
  final String? value;

  /// Initialize a newly created state to represent the given [value].
  SymbolState(this.value);

  @override
  int get hashCode => value == null ? 0 : value.hashCode;

  @override
  String get typeName => "Symbol";

  @override
  bool operator ==(Object other) =>
      other is SymbolState && (value == other.value);

  @override
  StringState convertToString() {
    if (value == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return StringState(value);
  }

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (value == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is SymbolState) {
      var rightValue = rightOperand.value;
      if (rightValue == null) {
        return BoolState.UNKNOWN_VALUE;
      }
      return BoolState.from(value == rightValue);
    }
    return BoolState.FALSE_STATE;
  }

  @override
  String toString() => value == null ? "-unknown-" : "#$value";
}

/// The state of an object representing a type.
class TypeState extends InstanceState {
  /// The element representing the type being modeled.
  final TypeImpl? _type;

  factory TypeState(TypeImpl? type) {
    type = type?.extensionTypeErasure;
    return TypeState._(type);
  }

  TypeState._(this._type);

  @override
  int get hashCode => _type?.hashCode ?? 0;

  @override
  String get typeName => "Type";

  @override
  bool operator ==(Object other) =>
      other is TypeState && (_type == other._type);

  @override
  StringState convertToString() {
    if (_type == null) {
      return StringState.UNKNOWN_VALUE;
    }
    return StringState(_type.getDisplayString());
  }

  @override
  BoolState equalEqual(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    return isIdentical(typeSystem, rightOperand);
  }

  @override
  bool hasPrimitiveEquality(FeatureSet featureSet) => true;

  @override
  BoolState isIdentical(TypeSystemImpl typeSystem, InstanceState rightOperand) {
    if (_type == null) {
      return BoolState.UNKNOWN_VALUE;
    }
    if (rightOperand is TypeState) {
      var rightType = rightOperand._type;
      if (rightType == null) {
        return BoolState.UNKNOWN_VALUE;
      }

      return BoolState.from(typeSystem.runtimeTypesEqual(_type, rightType));
    }
    return BoolState.FALSE_STATE;
  }

  @override
  String toString() {
    return _type?.getDisplayString() ?? '-unknown-';
  }
}
