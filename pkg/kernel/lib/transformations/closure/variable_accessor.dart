// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help transform compounds and null-aware accessors into
/// let expressions.
library kernel.closure.variable_accessor;

import '../../ast.dart';

/// An [Accessor] represents a subexpression for which we can't yet build a
/// kernel [Expression] because we don't yet know the context in which it is
/// used.
///
/// Once the context is known, an [Accessor] can be converted into an
/// [Expression] by calling a "build" method.
///
/// For example, when building a kernel representation for `a[x] = b`, after
/// parsing `a[x]` but before parsing `= b`, we don't yet know whether to
/// generate an invocation of `operator[]` or `operator[]=`, so we generate an
/// [Accessor] object.  Later, after `= b` is parsed, [buildAssignment] will be
/// called.
class VariableAccessor {
  final int offset;
  VariableDeclaration variable;
  DartType promotedType;

  VariableAccessor(this.variable, this.promotedType, this.offset);

  // [builtBinary] and [builtGetter] capture the inner nodes. Used by
  // dart2js+rasta for determining how subexpressions map to legacy dart2js Ast
  // nodes. This will be removed once dart2js type analysis (aka inference) is
  // reimplemented on kernel.
  Expression builtBinary;
  Expression builtGetter;

  /// Builds an [Expression] representing a read from the accessor.
  Expression buildSimpleRead() {
    return _finish(_makeSimpleRead());
  }

  /// Builds an [Expression] representing an assignment with the accessor on
  /// the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _finish(_makeSimpleWrite(value, voidContext));
  }

  /// Returns an [Expression] representing a null-aware assignment (`??=`) with
  /// the accessor on the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  ///
  /// [type] is the static type of the RHS.
  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    if (voidContext) {
      return _finish(new ConditionalExpression(_buildIsNull(_makeRead()),
          _makeWrite(value, false), new NullLiteral(), type));
    }
    var tmp = new VariableDeclaration.forValue(_makeRead());
    return _finish(_makeLet(
        tmp,
        new ConditionalExpression(_buildIsNull(new VariableGet(tmp)),
            _makeWrite(value, false), new VariableGet(tmp), type)));
  }

  /// Returns an [Expression] representing a compound assignment (e.g. `+=`)
  /// with the accessor on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return _finish(_makeWrite(
        builtBinary = _makeBinary(
            _makeRead(), binaryOperator, interfaceTarget, value,
            offset: offset),
        voidContext));
  }

  /// Returns an [Expression] representing a pre-increment or pre-decrement
  /// of the accessor.
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildCompoundAssignment(binaryOperator, new IntLiteral(1),
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget);
  }

  /// Returns an [Expression] representing a post-increment or post-decrement
  /// of the accessor.
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    if (voidContext) {
      return buildPrefixIncrement(binaryOperator,
          offset: offset, voidContext: true, interfaceTarget: interfaceTarget);
    }
    var value = new VariableDeclaration.forValue(_makeRead());
    valueAccess() => new VariableGet(value);
    var dummy = new VariableDeclaration.forValue(_makeWrite(
        builtBinary = _makeBinary(
            valueAccess(), binaryOperator, interfaceTarget, new IntLiteral(1),
            offset: offset),
        true));
    return _finish(_makeLet(value, _makeLet(dummy, valueAccess())));
  }

  Expression _makeSimpleRead() => _makeRead();

  Expression _makeSimpleWrite(Expression value, bool voidContext) {
    return _makeWrite(value, voidContext);
  }

  Expression _finish(Expression body) => body;

  /// Returns an [Expression] representing a compile-time error.
  makeInvalidRead() => new InvalidExpression(null);

  /// Returns an [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// The expression will be a compile-time error but will contain [value] as a
  /// subexpression before the compile-time error.
  makeInvalidWrite(Expression value) => _wrapInvalid(value);

  _makeRead() => new VariableGet(variable, promotedType)..fileOffset = offset;

  _makeWrite(Expression value, bool voidContext) {
    return variable.isFinal || variable.isConst
        ? makeInvalidWrite(value)
        : new VariableSet(variable, value)
      ..fileOffset = offset;
  }
}

Expression _makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression _makeBinary(
    Expression left, Name operator, Procedure interfaceTarget, Expression right,
    {int offset: TreeNode.noOffset}) {
  return new MethodInvocation(
      left, operator, new Arguments(<Expression>[right]), interfaceTarget)
    ..fileOffset = offset;
}

final Name _equalOperator = new Name('==');

Expression _buildIsNull(Expression value, {int offset: TreeNode.noOffset}) {
  return _makeBinary(value, _equalOperator, null, new NullLiteral(),
      offset: offset);
}

Expression _wrapInvalid(Expression e) {
  return new Let(
      new VariableDeclaration.forValue(e), new InvalidExpression(null));
}
