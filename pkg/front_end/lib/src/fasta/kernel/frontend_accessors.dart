// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/builder/ast_factory.dart';

/// A library to help transform compounds and null-aware accessors into
/// let expressions.

import 'package:front_end/src/fasta/kernel/utils.dart' show offsetForToken;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/kernel/fasta_accessors.dart'
    show BuilderHelper;

import 'package:kernel/ast.dart' hide MethodInvocation;

final Name indexGetName = new Name("[]");

final Name indexSetName = new Name("[]=");

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
abstract class Accessor {
  final BuilderHelper helper;
  final Token token;

  // [builtBinary] and [builtGetter] capture the inner nodes. Used by
  // dart2js+rasta for determining how subexpressions map to legacy dart2js Ast
  // nodes. This will be removed once dart2js type analysis (aka inference) is
  // reimplemented on kernel.
  Expression builtBinary;
  Expression builtGetter;

  Accessor(this.helper, this.token);

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
      return _finish(new ConditionalExpression(
          buildIsNull(helper.astFactory, _makeRead()),
          _makeWrite(value, false),
          new NullLiteral(),
          type));
    }
    var tmp = new VariableDeclaration.forValue(_makeRead());
    return _finish(makeLet(
        tmp,
        new ConditionalExpression(
            buildIsNull(helper.astFactory, new VariableGet(tmp)),
            _makeWrite(value, false),
            new VariableGet(tmp),
            type)));
  }

  /// Returns an [Expression] representing a compound assignment (e.g. `+=`)
  /// with the accessor on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return _finish(_makeWrite(
        builtBinary = makeBinary(helper.astFactory, _makeRead(), binaryOperator,
            interfaceTarget, value,
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
        builtBinary = makeBinary(helper.astFactory, valueAccess(),
            binaryOperator, interfaceTarget, new IntLiteral(1),
            offset: offset),
        true));
    return _finish(makeLet(value, makeLet(dummy, valueAccess())));
  }

  Expression _makeSimpleRead() => _makeRead();

  Expression _makeSimpleWrite(Expression value, bool voidContext) {
    return _makeWrite(value, voidContext);
  }

  Expression _makeRead();

  Expression _makeWrite(Expression value, bool voidContext);

  Expression _finish(Expression body) => body;

  /// Returns an [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  makeInvalidRead() => new InvalidExpression();

  /// Returns an [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  makeInvalidWrite(Expression value) => wrapInvalid(value);
}

abstract class VariableAccessor extends Accessor {
  VariableDeclaration variable;
  DartType promotedType;

  VariableAccessor(
      BuilderHelper helper, this.variable, this.promotedType, Token token)
      : super(helper, token);

  Expression _makeRead() {
    var fact = helper.typePromoter
        .getFactForAccess(variable, helper.functionNestingLevel);
    var scope = helper.typePromoter.currentScope;
    return helper.astFactory.variableGet(variable, fact, scope, token);
  }

  Expression _makeWrite(Expression value, bool voidContext) {
    helper.typePromoter.mutateVariable(variable, helper.functionNestingLevel);
    return variable.isFinal || variable.isConst
        ? makeInvalidWrite(value)
        : helper.astFactory.variableSet(variable, value)
      ..fileOffset = offsetForToken(token);
  }
}

class PropertyAccessor extends Accessor {
  VariableDeclaration _receiverVariable;
  Expression receiver;
  Name name;
  Member getter, setter;

  static Accessor make(BuilderHelper helper, Expression receiver, Name name,
      Member getter, Member setter,
      {Token token}) {
    if (receiver is ThisExpression) {
      return new ThisPropertyAccessor(helper, name, getter, setter, token);
    } else {
      return new PropertyAccessor.internal(
          helper, receiver, name, getter, setter, token);
    }
  }

  PropertyAccessor.internal(BuilderHelper helper, this.receiver, this.name,
      this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() =>
      helper.astFactory.propertyGet(receiver, name, getter)
        ..fileOffset = offsetForToken(token);

  Expression _makeSimpleWrite(Expression value, bool voidContext) {
    return helper.astFactory.propertySet(receiver, name, value, setter)
      ..fileOffset = offsetForToken(token);
  }

  receiverAccess() {
    _receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(_receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeRead() => builtGetter = helper.astFactory
      .propertyGet(receiverAccess(), name, getter)
        ..fileOffset = offsetForToken(token);

  Expression _makeWrite(Expression value, bool voidContext) {
    return helper.astFactory.propertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
  }

  Expression _finish(Expression body) => makeLet(_receiverVariable, body);
}

/// Special case of [PropertyAccessor] to avoid creating an indirect access to
/// 'this'.
class ThisPropertyAccessor extends Accessor {
  Name name;
  Member getter, setter;

  ThisPropertyAccessor(
      BuilderHelper helper, this.name, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeRead() => builtGetter = helper.astFactory
      .propertyGet(new ThisExpression(), name, getter)
        ..fileOffset = offsetForToken(token);

  Expression _makeWrite(Expression value, bool voidContext) {
    return helper.astFactory
        .propertySet(new ThisExpression(), name, value, setter)
          ..fileOffset = offsetForToken(token);
  }
}

class NullAwarePropertyAccessor extends Accessor {
  VariableDeclaration receiver;
  Name name;
  Member getter, setter;
  DartType type;

  NullAwarePropertyAccessor(BuilderHelper helper, Expression receiver,
      this.name, this.getter, this.setter, this.type, Token token)
      : this.receiver = makeOrReuseVariable(receiver),
        super(helper, token);

  receiverAccess() => new VariableGet(receiver);

  Expression _makeRead() => builtGetter =
      helper.astFactory.propertyGet(receiverAccess(), name, getter);

  Expression _makeWrite(Expression value, bool voidContext) {
    return helper.astFactory.propertySet(receiverAccess(), name, value, setter);
  }

  Expression _finish(Expression body) => makeLet(
      receiver,
      new ConditionalExpression(
          buildIsNull(helper.astFactory, receiverAccess()),
          new NullLiteral(),
          body,
          type));
}

class SuperPropertyAccessor extends Accessor {
  Name name;
  Member getter, setter;

  SuperPropertyAccessor(
      BuilderHelper helper, this.name, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeRead() {
    if (getter == null) return makeInvalidRead();
    // TODO(ahe): Use [DirectPropertyGet] when possible.
    return builtGetter = new SuperPropertyGet(name, getter)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeWrite(Expression value, bool voidContext) {
    if (setter == null) return makeInvalidWrite(value);
    // TODO(ahe): Use [DirectPropertySet] when possible.
    return new SuperPropertySet(name, value, setter)
      ..fileOffset = offsetForToken(token);
  }
}

class IndexAccessor extends Accessor {
  Expression receiver;
  Expression index;
  VariableDeclaration receiverVariable;
  VariableDeclaration indexVariable;
  Procedure getter, setter;

  static Accessor make(BuilderHelper helper, Expression receiver,
      Expression index, Procedure getter, Procedure setter,
      {Token token}) {
    if (receiver is ThisExpression) {
      return new ThisIndexAccessor(helper, index, getter, setter, token);
    } else {
      return new IndexAccessor.internal(
          helper, receiver, index, getter, setter, token);
    }
  }

  IndexAccessor.internal(BuilderHelper helper, this.receiver, this.index,
      this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() => helper.astFactory.methodInvocation(receiver,
      indexGetName, helper.astFactory.arguments(<Expression>[index]), getter)
    ..fileOffset = offsetForToken(token);

  Expression _makeSimpleWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return helper.astFactory.methodInvocation(receiver, indexSetName,
        helper.astFactory.arguments(<Expression>[index, value]), setter)
      ..fileOffset = offsetForToken(token);
  }

  receiverAccess() {
    // We cannot reuse the receiver if it is a variable since it might be
    // reassigned in the index expression.
    receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable)..fileOffset = offsetForToken(token);
  }

  Expression _makeRead() {
    return builtGetter = helper.astFactory.methodInvocation(
        receiverAccess(),
        indexGetName,
        helper.astFactory.arguments(<Expression>[indexAccess()]),
        getter)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return helper.astFactory.methodInvocation(receiverAccess(), indexSetName,
        helper.astFactory.arguments(<Expression>[indexAccess(), value]), setter)
      ..fileOffset = offsetForToken(token);
  }

  // TODO(dmitryas): remove this method after the "[]=" operator of the Context
  // class is made to return a value.
  _makeWriteAndReturn(Expression value) {
    // The call to []= does not return the value like direct-style assignments
    // do.  We need to bind the value in a let.
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(helper.astFactory
        .methodInvocation(
            receiverAccess(),
            indexSetName,
            helper.astFactory.arguments(
                <Expression>[indexAccess(), new VariableGet(valueVariable)]),
            setter)
          ..fileOffset = offsetForToken(token));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(Expression body) {
    return makeLet(receiverVariable, makeLet(indexVariable, body));
  }
}

/// Special case of [IndexAccessor] to avoid creating an indirect access to
/// 'this'.
class ThisIndexAccessor extends Accessor {
  Expression index;
  VariableDeclaration indexVariable;
  Procedure getter, setter;

  ThisIndexAccessor(
      BuilderHelper helper, this.index, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() {
    return helper.astFactory.methodInvocation(new ThisExpression(),
        indexGetName, helper.astFactory.arguments(<Expression>[index]), getter);
  }

  Expression _makeSimpleWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return helper.astFactory.methodInvocation(
        new ThisExpression(),
        indexSetName,
        helper.astFactory.arguments(<Expression>[index, value]),
        setter);
  }

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeRead() => builtGetter = helper.astFactory.methodInvocation(
      new ThisExpression(),
      indexGetName,
      helper.astFactory.arguments(<Expression>[indexAccess()]),
      getter);

  Expression _makeWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return helper.astFactory.methodInvocation(
        new ThisExpression(),
        indexSetName,
        helper.astFactory.arguments(<Expression>[indexAccess(), value]),
        setter);
  }

  _makeWriteAndReturn(Expression value) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(helper.astFactory
        .methodInvocation(
            new ThisExpression(),
            indexSetName,
            helper.astFactory.arguments(
                <Expression>[indexAccess(), new VariableGet(valueVariable)]),
            setter));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(Expression body) => makeLet(indexVariable, body);
}

class SuperIndexAccessor extends Accessor {
  Expression index;
  VariableDeclaration indexVariable;
  Member getter, setter;

  SuperIndexAccessor(
      BuilderHelper helper, this.index, this.getter, this.setter, Token token)
      : super(helper, token);

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeSimpleRead() => new SuperMethodInvocation(
      indexGetName, helper.astFactory.arguments(<Expression>[index]), getter);

  Expression _makeSimpleWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new SuperMethodInvocation(indexSetName,
        helper.astFactory.arguments(<Expression>[index, value]), setter);
  }

  Expression _makeRead() {
    return builtGetter = new SuperMethodInvocation(indexGetName,
        helper.astFactory.arguments(<Expression>[indexAccess()]), getter);
  }

  Expression _makeWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new SuperMethodInvocation(
        indexSetName,
        helper.astFactory.arguments(<Expression>[indexAccess(), value]),
        setter);
  }

  _makeWriteAndReturn(Expression value) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(new SuperMethodInvocation(
        indexSetName,
        helper.astFactory.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)]),
        setter));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(Expression body) {
    return makeLet(indexVariable, body);
  }
}

class StaticAccessor extends Accessor {
  Member readTarget;
  Member writeTarget;

  StaticAccessor(
      BuilderHelper helper, this.readTarget, this.writeTarget, Token token)
      : super(helper, token);

  Expression _makeRead() => builtGetter = readTarget == null
      ? makeInvalidRead()
      : helper.makeStaticGet(readTarget, token);

  Expression _makeWrite(Expression value, bool voidContext) {
    return writeTarget == null
        ? makeInvalidWrite(value)
        : new StaticSet(writeTarget, value)
      ..fileOffset = offsetForToken(token);
  }
}

class ReadOnlyAccessor extends Accessor {
  Expression expression;
  VariableDeclaration value;

  ReadOnlyAccessor(BuilderHelper helper, this.expression, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() => expression;

  Expression _makeRead() {
    value ??= new VariableDeclaration.forValue(expression);
    return new VariableGet(value);
  }

  Expression _makeWrite(Expression value, bool voidContext) =>
      makeInvalidWrite(value);

  Expression _finish(Expression body) => makeLet(value, body);
}

Expression makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression makeBinary(AstFactory astFactory, Expression left, Name operator,
    Procedure interfaceTarget, Expression right,
    {int offset: TreeNode.noOffset}) {
  return astFactory.methodInvocation(left, operator,
      astFactory.arguments(<Expression>[right]), interfaceTarget)
    ..fileOffset = offset;
}

final Name _equalOperator = new Name('==');

Expression buildIsNull(AstFactory astFactory, Expression value,
    {int offset: TreeNode.noOffset}) {
  return makeBinary(astFactory, value, _equalOperator, null, new NullLiteral(),
      offset: offset);
}

VariableDeclaration makeOrReuseVariable(Expression value) {
  // TODO: Devise a way to remember if a variable declaration was reused
  // or is fresh (hence needs a let binding).
  return new VariableDeclaration.forValue(value);
}

Expression wrapInvalid(Expression e) {
  return new Let(new VariableDeclaration.forValue(e), new InvalidExpression());
}
