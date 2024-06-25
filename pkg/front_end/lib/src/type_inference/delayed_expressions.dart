// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../type_inference/external_ast_helper.dart';
import 'matching_cache.dart';

/// Interface for delayed creating [Expression]s.
///
/// This is used to create the expression structure pattern matching expression
/// where actual encoding and potential caching of (sub)expressions is
/// determined by the use count of each expression.
abstract class DelayedExpression {
  /// Creates the resulting [Expression].
  ///
  /// If the expression has side effects that need to occur when the expression
  /// evaluates to `true`, then these should be added to [effects]. If this is
  /// not supported by the calling context, [effect] is `null`.
  ///
  /// If [inCacheInitializer] is `true`, the generated expression will be
  /// part of a late variable cache.
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer});

  /// Adds the effect of evaluating this expression into [results].
  ///
  /// If [effects] is provided, observable effects of a partial evaluation of
  /// the expression must be put in [effects] instead of [results].
  ///
  /// This is only supported for expressions for which [isEffectOnly] is `true`.
  void createStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Statement>? effects});

  /// Generates the expression, putting the irrefutable tail, if any, in
  /// [results] and returning the expression for the refutable head, if any.
  Expression? createExpressionAndStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Expression>? expressionEffects, List<Statement>? statementEffects});

  /// Returns the type of the resulting expression.
  DartType getType(TypeEnvironment typeEnvironment);

  /// Registers that this expression is used.
  ///
  /// Implementations must call recursively into subexpression, such that both
  /// direct and indirect use is counted.
  void registerUse();

  /// If `true`, this expression, when used for pattern matching, does not
  /// perform any tests.
  ///
  /// This occurs when for instance a pattern variable declaration or pattern
  /// assignment is statically known to match. Such matches can be encoded as a
  /// sequence of assignments, instead of an if-statement that assigns as a
  /// side effect of matching and throws if the match fails.
  bool get isEffectOnly;

  /// If `true`, this expression is either [isEffectOnly] or has a tail of
  /// [isEffectOnly] expressions.
  ///
  /// This is used to optimize the matching code where assignment to pattern
  /// variables can be moved after the matching code. For instance
  ///
  ///     if (_x case var x?) print(x);
  ///
  /// can be lowered as
  ///
  ///     if (_x != null) {
  ///       var x = _x;
  ///       print(x);
  ///     }
  ///
  /// instead of
  ///
  ///     var x;
  ///     if (_x != null && let _x = x in true) {
  ///       print(x);
  ///     }
  ///
  /// which makes it easier for backend to reason about the flow.
  bool get hasIrrefutableTail;

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

abstract mixin class AbstractDelayedExpression implements DelayedExpression {
  @override
  void createStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Statement>? effects}) {
    results.add(createExpressionStatement(
        createExpression(typeEnvironment, inCacheInitializer: false)));
  }

  @override
  Expression? createExpressionAndStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Expression>? expressionEffects,
      List<Statement>? statementEffects}) {
    return createExpression(typeEnvironment,
        inCacheInitializer: false, effects: expressionEffects);
  }

  @override
  bool get isEffectOnly => false;

  @override
  bool get hasIrrefutableTail => false;
}

/// A [DelayedExpression] based on an explicit [Expression] value.
///
/// This expression can only be used once.
class FixedExpression extends AbstractDelayedExpression {
  final Expression _expression;
  final DartType _type;

  bool used = false;

  FixedExpression(this._expression, this._type);

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return _expression;
  }

  @override
  void registerUse() {
    assert(!used, "FixedExpression can only be used once.");
    used = true;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) => _type;

  @override
  bool uses(DelayedExpression expression) => identical(this, expression);
}

/// A bool literal expression of the boolean [value].
class BooleanExpression extends AbstractDelayedExpression {
  final bool value;
  final int fileOffset;

  BooleanExpression(this.value, {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createBoolLiteral(value, fileOffset: fileOffset);
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) =>
      typeEnvironment.coreTypes.boolNonNullableRawType;

  @override
  void registerUse() {}

  @override
  bool uses(DelayedExpression expression) => identical(this, expression);
}

/// An int literal expression of the integer [value].
class IntegerExpression extends AbstractDelayedExpression {
  final int value;
  final int fileOffset;

  IntegerExpression(this.value, {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createIntLiteral(typeEnvironment.coreTypes, value,
        fileOffset: fileOffset);
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) =>
      typeEnvironment.coreTypes.intNonNullableRawType;

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
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createAndExpression(
        _left.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _right.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        fileOffset: fileOffset);
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) =>
      typeEnvironment.coreTypes.boolNonNullableRawType;

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

  @override
  bool get isEffectOnly => _left.isEffectOnly && _right.isEffectOnly;

  @override
  bool get hasIrrefutableTail => _right.hasIrrefutableTail;

  static DelayedExpression merge(
      DelayedExpression? left, DelayedExpression right,
      {required int fileOffset}) {
    if (left != null) {
      if (left is BooleanExpression && left.value) {
        return right;
      } else if (right is BooleanExpression && right.value) {
        return left;
      } else {
        return new DelayedAndExpression(left, right, fileOffset: fileOffset);
      }
    } else {
      return right;
    }
  }

  @override
  void createStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Statement>? effects}) {
    _left.createStatements(typeEnvironment, results, effects: effects);
    _right.createStatements(typeEnvironment, results, effects: effects);
  }

  @override
  Expression? createExpressionAndStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Expression>? expressionEffects,
      List<Statement>? statementEffects}) {
    if (_right.isEffectOnly) {
      // When [_right] is effect only, we generate [_right] fully into
      // [results]. The enables us to generate any irrefutable tail of [_left]
      // to [results].
      //
      // For instance:
      //
      //    String method(List<int> o) => switch (o) {
      //       [1, var x, var y] => "$x$y",
      //       _ => "no match"
      //     };
      //
      // The delayed expression is
      //
      //    o.length == 3 && o[0] == 1
      //      && let #1 = x = o[1] in true
      //      && let #2 = y = o[2] in true
      //
      // and we can generate both [_right], which is `let #2 = y = o[2] in true`
      // and a tail of [_left], that is `let #1 = x = o[1] in true`, into
      // [results]:
      //
      //    if (o.length == 3 && o[0] == 1) {
      //      x = o[1];
      //      y = o[2];
      //      {
      //        #result = "$x$y";
      //      }
      //    }
      //
      Expression? left = _left.createExpressionAndStatements(
          typeEnvironment, results,
          expressionEffects: expressionEffects,
          statementEffects: statementEffects);
      _right.createStatements(typeEnvironment, results,
          effects: statementEffects);
      return left;
    } else {
      // When [_right] is _not_ effect only, we can only generate [_right]
      // into [results].
      //
      // For instance:
      //
      //    String method(List<int> o) => switch (o) {
      //       [var x, 2, var y] => "$x$y",
      //       _ => "no match"
      //     };
      //
      // The delayed expression is
      //
      //    o.length == 3
      //      && let #1 = x = o[0] in true
      //      && o[0] == 2
      //      && let #2 = y = o[2] in true
      //
      // and we can generate [_right], which is `let #2 = y = o[2] in true` but
      // not `let #1 = x = o[0] in true` into [results] because we must preserve
      // the order of expressions `o[0]`, `o[1]`, and `o[2]`:
      //
      //    if (o.length == 3 && let #1 = x = o[0] in true && o[0] == 2) {
      //      y = o[2];
      //      {
      //        #result = "$x$y";
      //      }
      //    }
      //
      Expression left = _left.createExpression(typeEnvironment,
          inCacheInitializer: false, effects: expressionEffects);
      Expression? right = _right.createExpressionAndStatements(
          typeEnvironment, results,
          expressionEffects: expressionEffects,
          statementEffects: statementEffects);
      if (right != null) {
        return createAndExpression(left, right, fileOffset: fileOffset);
      } else {
        return left;
      }
    }
  }
}

/// A lazy-or expression of the [_left] and [_right] expressions.
class DelayedOrExpression extends AbstractDelayedExpression {
  final DelayedExpression _left;
  final DelayedExpression _right;
  final int fileOffset;

  DelayedOrExpression(this._left, this._right, {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createOrExpression(
        _left.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _right.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        fileOffset: fileOffset);
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) =>
      typeEnvironment.coreTypes.boolNonNullableRawType;

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

/// A expression that executes [_effect] for effect and results in [_result].
///
/// This is encoded as `let # = effect in result`.
///
/// An optional [_lateEffect] can be passed. This is registered as an effect
/// in [createExpression] if the `effects` argument is supplied. Otherwise it
/// is included in the created expression through this encoding:
///
///   let #1 = (let #2 = effect in late-effect) in result
///
class EffectExpression implements DelayedExpression {
  final DelayedExpression _effect;
  final DelayedExpression _result;
  final DelayedExpression? _lateEffect;

  EffectExpression(this._effect, this._result, [this._lateEffect]);

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    DelayedExpression? lateEffect = _lateEffect;
    if (lateEffect != null) {
      if (effects != null) {
        effects.add(lateEffect.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer));
      } else {
        return createLetEffect(
            effect: createLetEffect(
                effect: _effect.createExpression(typeEnvironment,
                    effects: effects, inCacheInitializer: inCacheInitializer),
                result: lateEffect.createExpression(typeEnvironment,
                    effects: effects, inCacheInitializer: inCacheInitializer)),
            result: _result.createExpression(typeEnvironment,
                effects: effects, inCacheInitializer: inCacheInitializer));
      }
    }
    return createLetEffect(
        effect: _effect.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        result: _result.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer));
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _result.getType(typeEnvironment);
  }

  @override
  void registerUse() {
    _effect.registerUse();
    _result.registerUse();
    _lateEffect?.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) ||
      _effect.uses(expression) ||
      _result.uses(expression) ||
      (_lateEffect != null && _lateEffect.uses(expression));

  @override
  bool get isEffectOnly => _result.isEffectOnly;

  @override
  void createStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Statement>? effects}) {
    _effect.createStatements(typeEnvironment, results, effects: effects);
    _result.createStatements(typeEnvironment, results, effects: effects);
    if (_lateEffect != null) {
      if (effects != null) {
        _lateEffect.createStatements(typeEnvironment, effects);
      } else {
        _lateEffect.createStatements(typeEnvironment, results);
      }
    }
  }

  @override
  bool get hasIrrefutableTail => isEffectOnly;

  @override
  Expression? createExpressionAndStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Expression>? expressionEffects,
      List<Statement>? statementEffects}) {
    if (isEffectOnly) {
      createStatements(typeEnvironment, results, effects: statementEffects);
      return null;
    } else {
      return createExpression(typeEnvironment,
          inCacheInitializer: false, effects: expressionEffects);
    }
  }
}

/// A expression that assigns [_value] to [_target].
///
/// If [hasEffect] is `true`, the assignment uses a temporary variable created
/// through [_cache] to separate the evaluation of [_value] from the assignment
/// to [_target].
class DelayedAssignment extends DelayedExpression {
  final MatchingCache _cache;
  final VariableDeclaration _target;
  final DartType _type;
  final DelayedExpression _value;
  final bool hasEffect;
  final int fileOffset;

  DelayedAssignment(this._cache, this._target, this._type, this._value,
      {required this.hasEffect, required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    if (effects != null && hasEffect) {
      VariableDeclaration tempVariable =
          _cache.createTemporaryVariable(_type, fileOffset: fileOffset);
      effects.add(createVariableSet(_target, createVariableGet(tempVariable),
          allowFinalAssignment: true, fileOffset: fileOffset));
      return createLetEffect(
          effect: createVariableSet(
              tempVariable,
              _value.createExpression(typeEnvironment,
                  effects: effects, inCacheInitializer: inCacheInitializer),
              fileOffset: fileOffset),
          result: createBoolLiteral(true, fileOffset: fileOffset));
    } else {
      return createLetEffect(
          effect: createVariableSet(
              _target,
              _value.createExpression(typeEnvironment,
                  effects: effects, inCacheInitializer: inCacheInitializer),
              allowFinalAssignment: true,
              fileOffset: fileOffset),
          result: createBoolLiteral(true, fileOffset: TreeNode.noOffset));
    }
  }

  @override
  void createStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Statement>? effects}) {
    if (effects != null && hasEffect) {
      VariableDeclaration tempVariable =
          _cache.createTemporaryVariable(_type, fileOffset: fileOffset);
      results.add(createExpressionStatement(createVariableSet(tempVariable,
          _value.createExpression(typeEnvironment, inCacheInitializer: false),
          fileOffset: fileOffset)));
      effects.add(createExpressionStatement(createVariableSet(
          _target, createVariableGet(tempVariable),
          fileOffset: fileOffset)));
    } else {
      results.add(createExpressionStatement(createVariableSet(_target,
          _value.createExpression(typeEnvironment, inCacheInitializer: false),
          allowFinalAssignment: true, fileOffset: fileOffset)));
    }
  }

  @override
  Expression? createExpressionAndStatements(
      TypeEnvironment typeEnvironment, List<Statement> results,
      {List<Expression>? expressionEffects,
      List<Statement>? statementEffects}) {
    createStatements(typeEnvironment, results, effects: statementEffects);
    return null;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return typeEnvironment.coreTypes.boolNonNullableRawType;
  }

  @override
  bool get isEffectOnly => true;

  @override
  bool get hasIrrefutableTail => true;

  @override
  void registerUse() {
    _value.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) {
    return identical(this, expression) || _value.uses(expression);
  }
}

/// An is-test of [_operand] against [_type].
class DelayedIsExpression extends AbstractDelayedExpression {
  final DelayedExpression _operand;
  final DartType _type;
  final int fileOffset;

  DelayedIsExpression(this._operand, this._type, {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createIsExpression(
        _operand.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _type,
        fileOffset: fileOffset);
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return typeEnvironment.coreTypes.boolNonNullableRawType;
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
class DelayedAsExpression extends AbstractDelayedExpression {
  final DelayedExpression _operand;
  final DartType _type;
  final bool isUnchecked;
  final bool isImplicit;
  final bool isCovarianceCheck;
  final int fileOffset;

  DelayedAsExpression(this._operand, this._type,
      {this.isUnchecked = false,
      this.isImplicit = false,
      this.isCovarianceCheck = false,
      required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    Expression operand = _operand.createExpression(typeEnvironment,
        effects: effects, inCacheInitializer: inCacheInitializer);
    if (isCovarianceCheck) {
      return createAsExpression(operand, _type,
          forNonNullableByDefault: true,
          isCovarianceCheck: true,
          fileOffset: fileOffset);
    } else if (isImplicit) {
      DartType operandType = _operand.getType(typeEnvironment);
      if (typeEnvironment.isSubtypeOf(
          operandType, _type, SubtypeCheckMode.withNullabilities)) {
        return operand;
      }
    }
    return createAsExpression(operand, _type,
        forNonNullableByDefault: true,
        isUnchecked: isUnchecked,
        fileOffset: fileOffset);
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
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
class DelayedNullAssertExpression extends AbstractDelayedExpression {
  final DelayedExpression _operand;
  final int fileOffset;

  DelayedNullAssertExpression(this._operand, {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createNullCheck(
        _operand.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        fileOffset: fileOffset);
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _operand.getType(typeEnvironment).toNonNull();
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
class DelayedNullCheckExpression extends AbstractDelayedExpression {
  final DelayedExpression _operand;
  final int fileOffset;

  DelayedNullCheckExpression(this._operand, {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createNot(createEqualsNull(
        _operand.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        fileOffset: fileOffset));
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return typeEnvironment.coreTypes.boolNonNullableRawType;
  }

  @override
  void registerUse() {
    _operand.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _operand.uses(expression);
}

/// An access to [_target] on [_receiver].
///
/// The [_resultType] is the static type of expression. If [isObjectAccess] is
/// `true`, the [_target] is an Object member accessed on a non-Object type,
/// for instance a nullable access to `hashCode`.
class DelayedInstanceGet extends AbstractDelayedExpression {
  final CacheableExpression _receiver;
  final Member _target;
  final DartType _resultType;
  final bool isObjectAccess;
  final int fileOffset;

  DelayedInstanceGet(this._receiver, this._target, this._resultType,
      {required this.fileOffset, this.isObjectAccess = false});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    Member target = _target;
    if (target is Procedure && !target.isGetter) {
      return new InstanceTearOff(
          isObjectAccess
              ? InstanceAccessKind.Object
              : InstanceAccessKind.Instance,
          _receiver.createExpression(typeEnvironment,
              effects: effects, inCacheInitializer: inCacheInitializer),
          _target.name,
          interfaceTarget: target,
          resultType: _resultType)
        ..fileOffset = fileOffset;
    } else {
      return new InstanceGet(
          isObjectAccess
              ? InstanceAccessKind.Object
              : InstanceAccessKind.Instance,
          _receiver.createExpression(typeEnvironment,
              effects: effects, inCacheInitializer: inCacheInitializer),
          _target.name,
          interfaceTarget: target,
          resultType: _resultType)
        ..fileOffset = fileOffset;
    }
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _resultType;
  }

  @override
  void registerUse() {
    _receiver.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _receiver.uses(expression);
}

/// An access to [_propertyName] on [_receiver] with no statically known target.
///
/// The [_resultType] is the static type of expression.
class DelayedDynamicGet extends AbstractDelayedExpression {
  final CacheableExpression _receiver;
  final Name _propertyName;
  final DynamicAccessKind _kind;
  final DartType _resultType;
  final int fileOffset;

  DelayedDynamicGet(
      this._receiver, this._propertyName, this._kind, this._resultType,
      {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new DynamicGet(
        _kind,
        _receiver.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _propertyName)
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _resultType;
  }

  @override
  void registerUse() {
    _receiver.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _receiver.uses(expression);
}

/// An access to `call` on the function typed [_receiver].
///
/// The [_resultType] is the static type of expression.
class DelayedFunctionTearOff extends AbstractDelayedExpression {
  final CacheableExpression _receiver;
  final DartType _resultType;
  final int fileOffset;

  DelayedFunctionTearOff(this._receiver, this._resultType,
      {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new FunctionTearOff(_receiver.createExpression(typeEnvironment,
        effects: effects, inCacheInitializer: inCacheInitializer))
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _resultType;
  }

  @override
  void registerUse() {
    _receiver.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _receiver.uses(expression);
}

/// An invocation of [_methodName] on [_receiver] with the provided positional
/// [_arguments] and no statically known target.
///
/// The [_resultType] is the static type of expression.
class DelayedDynamicInvocation extends AbstractDelayedExpression {
  final CacheableExpression _receiver;
  final Name _methodName;
  final List<DelayedExpression> _arguments;
  final DynamicAccessKind _kind;
  final DartType _resultType;
  final int fileOffset;

  DelayedDynamicInvocation(this._receiver, this._methodName, this._arguments,
      this._kind, this._resultType,
      {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new DynamicInvocation(
        _kind,
        _receiver.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _methodName,
        new Arguments(_arguments
            .map((e) => e.createExpression(typeEnvironment,
                effects: effects, inCacheInitializer: inCacheInitializer))
            .toList())
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _resultType;
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
    if (_receiver.uses(expression)) return true;
    for (DelayedExpression argument in _arguments) {
      if (argument.uses(expression)) {
        return true;
      }
    }
    return false;
  }
}

/// An indexed record field access on [_receiver] of type [_recordType].
///
/// The [_resultType] is the static type of expression.
class DelayedRecordIndexGet extends AbstractDelayedExpression {
  final CacheableExpression _receiver;
  final RecordType _recordType;
  final int _index;
  final int fileOffset;

  DelayedRecordIndexGet(this._receiver, this._recordType, this._index,
      {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new RecordIndexGet(
        _receiver.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _recordType,
        _index)
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _recordType.positional[_index];
  }

  @override
  void registerUse() {
    _receiver.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _receiver.uses(expression);
}

/// An access of record field [_name] on [_receiver] of type [_recordType].
///
/// The [_resultType] is the static type of expression.
class DelayedRecordNameGet extends AbstractDelayedExpression {
  final CacheableExpression _receiver;
  final RecordType _recordType;
  final String _name;
  final int fileOffset;

  DelayedRecordNameGet(this._receiver, this._recordType, this._name,
      {required this.fileOffset})
      : assert(
            _recordType.named
                    .where((element) => element.name == _name)
                    .length ==
                1,
            "Invalid record type $_recordType for named access of '$_name'.");

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new RecordNameGet(
        _receiver.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _recordType,
        _name)
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _recordType.named
        .singleWhere((element) => element.name == _name)
        .type;
  }

  @override
  void registerUse() {
    _receiver.registerUse();
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || _receiver.uses(expression);
}

/// An invocation of [_target] on [receiver] with the positional [_arguments].
///
/// The [_functionType] is the static type of the invocation.
class DelayedInstanceInvocation extends AbstractDelayedExpression {
  final CacheableExpression _receiver;
  final Procedure _target;
  final FunctionType _functionType;
  final List<DelayedExpression> _arguments;
  final int fileOffset;

  DelayedInstanceInvocation(
      this._receiver, this._target, this._functionType, this._arguments,
      {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        _receiver.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _target.name,
        new Arguments(_arguments
            .map((e) => e.createExpression(typeEnvironment,
                effects: effects, inCacheInitializer: inCacheInitializer))
            .toList())
          ..fileOffset = fileOffset,
        interfaceTarget: _target,
        functionType: _functionType)
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _functionType.returnType;
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
    if (_receiver.uses(expression)) return true;
    for (DelayedExpression argument in _arguments) {
      if (argument.uses(expression)) {
        return true;
      }
    }
    return false;
  }
}

/// A static invocation of the lowered extension or extension type declaration
/// [_target] with the provided [_arguments] and [_typeArguments].
///
/// The [_functionType] is the static type of the invocation.
class DelayedExtensionInvocation extends AbstractDelayedExpression {
  final Procedure _target;
  final List<DelayedExpression> _arguments;
  final List<DartType> _typeArguments;
  final DartType _resultType;
  final int fileOffset;

  DelayedExtensionInvocation(
      this._target, this._arguments, this._typeArguments, this._resultType,
      {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new StaticInvocation(
        _target,
        new Arguments(
            _arguments
                .map((e) => e.createExpression(typeEnvironment,
                    effects: effects, inCacheInitializer: inCacheInitializer))
                .toList(),
            types: _typeArguments)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _resultType;
  }

  @override
  void registerUse() {
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

/// An invocation of the `==` operator [_target] of type [_functionType] on
/// [_left]  with [_right].
class DelayedEqualsExpression extends AbstractDelayedExpression {
  final CacheableExpression _left;
  final DelayedExpression _right;
  final Procedure _target;
  final FunctionType _functionType;
  final int fileOffset;

  DelayedEqualsExpression(
      this._left, this._right, this._target, this._functionType,
      {required this.fileOffset});

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return new EqualsCall(
        _left.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        _right.createExpression(typeEnvironment,
            effects: effects, inCacheInitializer: inCacheInitializer),
        functionType: _functionType,
        interfaceTarget: _target)
      ..fileOffset = fileOffset;
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return _functionType.returnType;
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

/// A negation of [_expression].
class DelayedNotExpression extends AbstractDelayedExpression {
  final DelayedExpression _expression;

  DelayedNotExpression(this._expression);

  @override
  Expression createExpression(TypeEnvironment typeEnvironment,
      {List<Expression>? effects, required bool inCacheInitializer}) {
    return createNot(_expression.createExpression(typeEnvironment,
        effects: effects, inCacheInitializer: inCacheInitializer));
  }

  @override
  DartType getType(TypeEnvironment typeEnvironment) {
    return typeEnvironment.coreTypes.boolNonNullableRawType;
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
