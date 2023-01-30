// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:kernel/ast.dart';

import '../kernel/internal_ast.dart';
import '../names.dart';
import '../type_inference/external_ast_helper.dart';
import '../type_inference/inference_visitor_base.dart';
import 'inference_results.dart';
import 'matching_cache.dart';
import 'object_access_target.dart';
import 'type_schema.dart';

/// Interface for delayed creating [Expression]s.
///
/// This is used to create the expression structure pattern matching expression
/// where actual encoding and potential caching of (sub)expressions is
/// determined by the use count of each expression.
abstract class DelayedExpression {
  /// Creates the resulting [Expression].
  Expression createExpression(InferenceVisitorBase base);

  /// Returns the type of the resulting expression.
  DartType getType(InferenceVisitorBase base);

  /// Registers that this expression is used.
  ///
  /// Implementations must call recursively into subexpression, such that both
  /// direct and indirect use is counted.
  void registerUse();

  /// Returns `true` if this expression or subexpressions uses [expression].
  ///
  /// This is used to determine whether [expression] needs to be included purely
  /// for effect or whether the effect trigger by the use through a
  /// subexpression. For instance:
  ///
  ///     if (o case Foo(bar: _, baz: 5)) { ... }
  ///
  /// Here the value of accessing `Foo.bar` on `o` is not uses in the subpattern
  /// `_` and the matched must therefore be encoded as `let # = o.bar in true`
  /// to trigger the access and its potential side effects. Since the value of
  /// accessing `Foo.baz` _is_ used by the subpattern, this match can simply be
  /// encoded as `o.baz == 5` instead of the redundant
  /// `let # o.baz in o.baz == 5`.
  bool uses(DelayedExpression expression);
}

/// A [DelayedExpression] based on an explicit [Expression] value.
///
/// This expression can only be used once.
class FixedExpression implements DelayedExpression {
  final Expression _expression;
  final DartType _type;

  bool used = false;

  FixedExpression(this._expression, this._type);

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return _expression;
  }

  @override
  void registerUse() {
    assert(!used, "FixedExpression can only be used once.");
    used = true;
  }

  @override
  DartType getType(InferenceVisitorBase base) => _type;

  @override
  bool uses(DelayedExpression expression) => identical(this, expression);
}

/// A bool literal expression of the boolean [value].
class BooleanExpression implements DelayedExpression {
  final bool value;
  final int fileOffset;

  BooleanExpression(this.value, {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createBoolLiteral(value, fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) =>
      base.coreTypes.boolNonNullableRawType;

  @override
  void registerUse() {}

  @override
  bool uses(DelayedExpression expression) => identical(this, expression);
}

/// An int literal expression of the integer [value].
class IntegerExpression implements DelayedExpression {
  final int value;
  final int fileOffset;

  IntegerExpression(this.value, {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createIntLiteral(value, fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) =>
      base.coreTypes.intNonNullableRawType;

  @override
  void registerUse() {}

  @override
  bool uses(DelayedExpression expression) => identical(this, expression);
}

/// A lazy-and expression of the [_left] and [_right] expressions.
class DelayedAndExpression implements DelayedExpression {
  final DelayedExpression _left;
  final DelayedExpression _right;
  final int fileOffset;

  DelayedAndExpression(this._left, this._right, {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createAndExpression(
        _left.createExpression(base), _right.createExpression(base),
        fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) =>
      base.coreTypes.boolNonNullableRawType;

  @override
  void registerUse() {
    _left.registerUse();
    _right.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) ||
      _left.uses(expression) ||
      _right.uses(expression);

  static DelayedExpression merge(
      DelayedExpression? left, DelayedExpression right,
      {required int fileOffset}) {
    if (left != null) {
      return new DelayedAndExpression(left, right, fileOffset: fileOffset);
    } else {
      return right;
    }
  }
}

/// A lazy-or expression of the [_left] and [_right] expressions.
class DelayedOrExpression implements DelayedExpression {
  final DelayedExpression _left;
  final DelayedExpression _right;
  final int fileOffset;

  DelayedOrExpression(this._left, this._right, {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createOrExpression(
        _left.createExpression(base), _right.createExpression(base),
        fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) =>
      base.coreTypes.boolNonNullableRawType;

  @override
  void registerUse() {
    _left.registerUse();
    _right.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) ||
      _left.uses(expression) ||
      _right.uses(expression);
}

/// A conditional expression of the [_condition], [_then] and [_otherwise]
/// expressions.
class DelayedConditionExpression implements DelayedExpression {
  final DelayedExpression _condition;
  final DelayedExpression _then;
  final DelayedExpression _otherwise;
  final int fileOffset;

  DelayedConditionExpression(this._condition, this._then, this._otherwise,
      {required this.fileOffset});

  @override
  DartType getType(InferenceVisitorBase base) =>
      base.coreTypes.boolNonNullableRawType;

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createConditionalExpression(_condition.createExpression(base),
        _then.createExpression(base), _otherwise.createExpression(base),
        staticType: base.coreTypes.boolNonNullableRawType,
        fileOffset: fileOffset);
  }

  @override
  void registerUse() {
    _condition.registerUse();
    _then.registerUse();
    _otherwise.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) ||
      _condition.uses(expression) ||
      _then.uses(expression) ||
      _otherwise.uses(expression);
}

/// An assignment of [_variable] with [_value].
///
/// If [allowFinalAssignment] is `true`, the created [VariableSet] is allowed to
/// assign to a final variable. This is used for encoding initialization of
/// final pattern variables.
// TODO(johnniwinther): Should we instead mark the variable as non-final?
class VariableSetExpression implements DelayedExpression {
  final VariableDeclaration _variable;
  final CacheableExpression _value;
  final bool allowFinalAssignment;
  final int fileOffset;

  VariableSetExpression(this._variable, this._value,
      {this.allowFinalAssignment = false, required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createVariableSet(_variable, _value.createExpression(base),
        allowFinalAssignment: allowFinalAssignment, fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return _value.getType(base);
  }

  @override
  void registerUse() {
    _value.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _value.uses(expression);
}

/// A expression that executes [_effect] for effect and results in [_result].
///
/// This is encoded as `let # = effect in result`.
class EffectExpression implements DelayedExpression {
  final DelayedExpression _effect;
  final DelayedExpression _result;

  EffectExpression(this._effect, this._result);

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createLetEffect(
        effect: _effect.createExpression(base),
        result: _result.createExpression(base));
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return _result.getType(base);
  }

  @override
  void registerUse() {
    _effect.registerUse();
    _result.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) ||
      _effect.uses(expression) ||
      _result.uses(expression);
}

/// An is-test of [_operand] against [_type].
class DelayedIsExpression implements DelayedExpression {
  final DelayedExpression _operand;
  final DartType _type;
  final int fileOffset;

  DelayedIsExpression(this._operand, this._type, {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createIsExpression(_operand.createExpression(base), _type,
        forNonNullableByDefault: base.isNonNullableByDefault,
        fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return base.coreTypes.boolNonNullableRawType;
  }

  @override
  void registerUse() {
    _operand.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _operand.uses(expression);
}

/// An as-cast of [_operand] against [_type].
class DelayedAsExpression implements DelayedExpression {
  final DelayedExpression _operand;
  final DartType _type;
  final bool isUnchecked;
  final int fileOffset;

  DelayedAsExpression(this._operand, this._type,
      {this.isUnchecked = false, required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createAsExpression(_operand.createExpression(base), _type,
        forNonNullableByDefault: base.isNonNullableByDefault,
        isUnchecked: isUnchecked,
        fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return _type;
  }

  @override
  void registerUse() {
    _operand.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _operand.uses(expression);
}

/// An null-assert, e!, of [_operand].
class DelayedNullAssertExpression implements DelayedExpression {
  final DelayedExpression _operand;
  final int fileOffset;

  DelayedNullAssertExpression(this._operand, {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createNullCheck(_operand.createExpression(base),
        fileOffset: fileOffset);
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return _operand.getType(base).toNonNull();
  }

  @override
  void registerUse() {
    _operand.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _operand.uses(expression);
}

/// An null check,e != null, of [_operand].
class DelayedNullCheckExpression implements DelayedExpression {
  final DelayedExpression _operand;
  final int fileOffset;

  DelayedNullCheckExpression(this._operand, {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createNot(createEqualsNull(_operand.createExpression(base),
        fileOffset: fileOffset));
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return base.coreTypes.boolNonNullableRawType;
  }

  @override
  void registerUse() {
    _operand.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _operand.uses(expression);
}

/// An access to [_propertyName] on [_receiver] of type [_receiverType].
///
/// The accessed [_readTarget] known upon creation of this delayed expression.
class DelayedPropertyGetExpression implements DelayedExpression {
  final DartType _receiverType;
  final CacheableExpression _receiver;
  final ObjectAccessTarget _readTarget;
  final Name _propertyName;
  final int fileOffset;

  DelayedPropertyGetExpression(
      this._receiverType, this._receiver, this._readTarget, this._propertyName,
      {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    PropertyGetInferenceResult propertyGet = base.createPropertyGet(
        fileOffset: fileOffset,
        receiver: _receiver.createExpression(base),
        receiverType: _receiverType,
        readTarget: _readTarget,
        propertyName: _propertyName,
        // TODO(johnniwinther): What is the type context?
        typeContext: const UnknownType(),
        // TODO(johnniwinther): Handle access on `this`.
        isThisReceiver: false);
    return propertyGet.expressionInferenceResult.expression;
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return _readTarget.getGetterType(base);
  }

  @override
  void registerUse() {
    _receiver.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _receiver.uses(expression);
}

/// An invocation of [_invokeName] on [receiver] of type [receiverType] with
/// L_arguments].
///
/// The accessed [_invokeTarget] known upon creation of this delayed expression.
class DelayedInvokeExpression implements DelayedExpression {
  final CacheableExpression _receiver;
  final ObjectAccessTarget _invokeTarget;
  final Name _invokeName;
  final List<DelayedExpression> _arguments;
  final int fileOffset;

  DelayedInvokeExpression(
      this._receiver, this._invokeTarget, this._invokeName, this._arguments,
      {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    ExpressionInferenceResult result = base.inferMethodInvocation(
        base,
        fileOffset,
        const Link(),
        _receiver.createExpression(base),
        _receiver.getType(base),
        _invokeName,
        new ArgumentsImpl(
            _arguments.map((e) => e.createExpression(base)).toList()),
        // TODO(johnniwinther): What is the type context?
        const UnknownType(),
        isExpressionInvocation: false,
        isImplicitCall: false,
        target: _invokeTarget);
    return result.expression;
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return _invokeTarget.getReturnType(base);
  }

  @override
  void registerUse() {
    _receiver.registerUse();
    for (DelayedExpression argument in _arguments) {
      argument.registerUse();
    }
  }

  @override
  bool uses(DelayedExpression expression) {
    if (identical(this, expression)) return true;
    for (DelayedExpression argument in _arguments) {
      if (argument.uses(expression)) {
        return true;
      }
    }
    return false;
  }
}

/// An invocation of `==` on [_left] of type [_leftType] with [_right].
///
/// If [isNot] is `true`, the result is negated.
///
/// The accessed [_invokeTarget] known upon creation of this delayed expression.
class DelayedEqualsExpression implements DelayedExpression {
  final CacheableExpression _left;
  final ObjectAccessTarget _invokeTarget;
  final DelayedExpression _right;
  final int fileOffset;

  DelayedEqualsExpression(this._left, this._invokeTarget, this._right,
      {required this.fileOffset});

  @override
  Expression createExpression(InferenceVisitorBase base) {
    if (_invokeTarget.isInstanceMember || _invokeTarget.isObjectMember) {
      FunctionType functionType = _invokeTarget.getFunctionType(base);
      return new EqualsCall(
          _left.createExpression(base), _right.createExpression(base),
          functionType: functionType,
          interfaceTarget: _invokeTarget.member as Procedure)
        ..fileOffset = fileOffset;
    } else {
      assert(_invokeTarget.isNever);
      FunctionType functionType = new FunctionType([const DynamicType()],
          const NeverType.nonNullable(), base.libraryBuilder.nonNullable);
      // Ensure operator == member even for `Never`.
      Member target = base
          .findInterfaceMember(const DynamicType(), equalsName, -1,
              instrumented: false,
              callSiteAccessKind: CallSiteAccessKind.operatorInvocation)
          .member!;
      return new EqualsCall(
          _left.createExpression(base), _right.createExpression(base),
          functionType: functionType, interfaceTarget: target as Procedure)
        ..fileOffset = fileOffset;
    }
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return _invokeTarget.getReturnType(base);
  }

  @override
  void registerUse() {
    _left.registerUse();
    _right.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) ||
      _left.uses(expression) ||
      _right.uses(expression);
}

class DelayedNotExpression implements DelayedExpression {
  final DelayedExpression _expression;

  DelayedNotExpression(this._expression);

  @override
  Expression createExpression(InferenceVisitorBase base) {
    return createNot(_expression.createExpression(base));
  }

  @override
  DartType getType(InferenceVisitorBase base) {
    return base.coreTypes.boolNonNullableRawType;
  }

  @override
  void registerUse() {
    _expression.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) {
    return identical(this, expression) || _expression.uses(expression);
  }
}
