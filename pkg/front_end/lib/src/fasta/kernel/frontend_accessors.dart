// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help transform compounds and null-aware accessors into
/// let expressions.

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show
        KernelArguments,
        KernelComplexAssignment,
        KernelConditionalExpression,
        KernelMethodInvocation,
        KernelPropertyGet,
        KernelPropertySet,
        KernelVariableDeclaration,
        KernelVariableGet,
        KernelVariableSet;

import 'package:front_end/src/fasta/kernel/utils.dart' show offsetForToken;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/kernel/fasta_accessors.dart'
    show BuilderHelper;

import 'package:kernel/ast.dart' hide MethodInvocation, InvalidExpression;

import '../names.dart' show equalsName, indexGetName, indexSetName;

import '../errors.dart' show internalError;

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

  Accessor(this.helper, this.token);

  /// Builds an [Expression] representing a read from the accessor.
  Expression buildSimpleRead() {
    return _finish(_makeSimpleRead(), null);
  }

  /// Builds an [Expression] representing an assignment with the accessor on
  /// the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    var complexAssignment = startComplexAssignment(value);
    return _finish(_makeSimpleWrite(value, voidContext, complexAssignment),
        complexAssignment);
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
    var complexAssignment = startComplexAssignment(value);
    if (voidContext) {
      var nullAwareCombiner = new KernelConditionalExpression(
          buildIsNull(_makeRead(complexAssignment)),
          _makeWrite(value, false, complexAssignment),
          new NullLiteral());
      complexAssignment?.nullAwareCombiner = nullAwareCombiner;
      return _finish(nullAwareCombiner, complexAssignment);
    }
    var tmp = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    var nullAwareCombiner = new KernelConditionalExpression(
        buildIsNull(new VariableGet(tmp)),
        _makeWrite(value, false, complexAssignment),
        new VariableGet(tmp));
    complexAssignment?.nullAwareCombiner = nullAwareCombiner;
    return _finish(makeLet(tmp, nullAwareCombiner), complexAssignment);
  }

  /// Returns an [Expression] representing a compound assignment (e.g. `+=`)
  /// with the accessor on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    var complexAssignment = startComplexAssignment(value);
    var combiner = makeBinary(
        _makeRead(complexAssignment), binaryOperator, interfaceTarget, value,
        offset: offset);
    complexAssignment?.combiner = combiner;
    return _finish(_makeWrite(combiner, voidContext, complexAssignment),
        complexAssignment);
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
    var rhs = new IntLiteral(1);
    var complexAssignment = startComplexAssignment(rhs);
    var value = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    valueAccess() => new VariableGet(value);
    var combiner = makeBinary(
        valueAccess(), binaryOperator, interfaceTarget, rhs,
        offset: offset);
    complexAssignment?.combiner = combiner;
    complexAssignment?.isPostIncDec = true;
    var dummy = new KernelVariableDeclaration.forValue(
        _makeWrite(combiner, true, complexAssignment),
        helper.functionNestingLevel);
    return _finish(
        makeLet(value, makeLet(dummy, valueAccess())), complexAssignment);
  }

  Expression _makeSimpleRead() => _makeRead(null);

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    return _makeWrite(value, voidContext, complexAssignment);
  }

  Expression _makeRead(KernelComplexAssignment complexAssignment);

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment);

  Expression _finish(
          Expression body, KernelComplexAssignment complexAssignment) =>
      body;

  /// Returns an [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  makeInvalidRead() {
    return internalError(
        "Unhandled compile-time error.", null, offsetForToken(token));
  }

  /// Returns an [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  makeInvalidWrite(Expression value) {
    return internalError(
        "Unhandled compile-time error.", null, offsetForToken(token));
  }

  /// Creates a data structure for tracking the desugaring of a complex
  /// assignment expression whose right hand side is [rhs], if necessary, or
  /// returns `null` if not necessary.
  KernelComplexAssignment startComplexAssignment(Expression rhs) => null;
}

abstract class VariableAccessor extends Accessor {
  VariableDeclaration variable;
  DartType promotedType;

  VariableAccessor(
      BuilderHelper helper, this.variable, this.promotedType, Token token)
      : super(helper, token);

  Expression _makeRead(KernelComplexAssignment complexAssignment) {
    var fact = helper.typePromoter
        .getFactForAccess(variable, helper.functionNestingLevel);
    var scope = helper.typePromoter.currentScope;
    return new KernelVariableGet(variable, fact, scope)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    helper.typePromoter.mutateVariable(variable, helper.functionNestingLevel);
    return variable.isFinal || variable.isConst
        ? makeInvalidWrite(value)
        : new KernelVariableSet(variable, value)
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

  Expression _makeSimpleRead() => new KernelPropertyGet(receiver, name, getter)
    ..fileOffset = offsetForToken(token);

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    return new KernelPropertySet(receiver, name, value, setter)
      ..fileOffset = offsetForToken(token);
  }

  receiverAccess() {
    _receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(_receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeRead(KernelComplexAssignment complexAssignment) =>
      new KernelPropertyGet(receiverAccess(), name, getter)
        ..fileOffset = offsetForToken(token);

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    return new KernelPropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
  }

  Expression _finish(
          Expression body, KernelComplexAssignment complexAssignment) =>
      makeLet(_receiverVariable, body);
}

/// Special case of [PropertyAccessor] to avoid creating an indirect access to
/// 'this'.
class ThisPropertyAccessor extends Accessor {
  Name name;
  Member getter, setter;

  ThisPropertyAccessor(
      BuilderHelper helper, this.name, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeRead(KernelComplexAssignment complexAssignment) =>
      new KernelPropertyGet(new ThisExpression(), name, getter)
        ..fileOffset = offsetForToken(token);

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    return new KernelPropertySet(new ThisExpression(), name, value, setter)
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

  Expression _makeRead(KernelComplexAssignment complexAssignment) =>
      new KernelPropertyGet(receiverAccess(), name, getter);

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    return new KernelPropertySet(receiverAccess(), name, value, setter);
  }

  Expression _finish(
          Expression body, KernelComplexAssignment complexAssignment) =>
      makeLet(
          receiver,
          new KernelConditionalExpression(
              buildIsNull(receiverAccess()), new NullLiteral(), body));
}

class SuperPropertyAccessor extends Accessor {
  Name name;
  Member getter, setter;

  SuperPropertyAccessor(
      BuilderHelper helper, this.name, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeRead(KernelComplexAssignment complexAssignment) {
    if (getter == null) return makeInvalidRead();
    // TODO(ahe): Use [DirectPropertyGet] when possible.
    return new SuperPropertyGet(name, getter)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
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

  Expression _makeSimpleRead() {
    var read = new KernelMethodInvocation(
        receiver, indexGetName, new KernelArguments(<Expression>[index]),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    return read;
  }

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new KernelMethodInvocation(
        receiver, indexSetName, new KernelArguments(<Expression>[index, value]),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
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

  Expression _makeRead(KernelComplexAssignment complexAssignment) {
    var read = new KernelMethodInvocation(receiverAccess(), indexGetName,
        new KernelArguments(<Expression>[indexAccess()]),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new KernelMethodInvocation(receiverAccess(), indexSetName,
        new KernelArguments(<Expression>[indexAccess(), value]),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  // TODO(dmitryas): remove this method after the "[]=" operator of the Context
  // class is made to return a value.
  _makeWriteAndReturn(
      Expression value, KernelComplexAssignment complexAssignment) {
    // The call to []= does not return the value like direct-style assignments
    // do.  We need to bind the value in a let.
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new KernelMethodInvocation(
        receiverAccess(),
        indexSetName,
        new KernelArguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)]),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new KernelVariableDeclaration.forValue(
        write, helper.functionNestingLevel);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(
      Expression body, KernelComplexAssignment complexAssignment) {
    Expression desugared =
        makeLet(receiverVariable, makeLet(indexVariable, body));
    if (complexAssignment != null) {
      complexAssignment.desugared = desugared;
      return complexAssignment;
    } else {
      return desugared;
    }
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
    return new KernelMethodInvocation(new ThisExpression(), indexGetName,
        new KernelArguments(<Expression>[index]),
        interfaceTarget: getter);
  }

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new KernelMethodInvocation(new ThisExpression(), indexSetName,
        new KernelArguments(<Expression>[index, value]),
        interfaceTarget: setter);
  }

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeRead(KernelComplexAssignment complexAssignment) =>
      new KernelMethodInvocation(new ThisExpression(), indexGetName,
          new KernelArguments(<Expression>[indexAccess()]),
          interfaceTarget: getter);

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new KernelMethodInvocation(new ThisExpression(), indexSetName,
        new KernelArguments(<Expression>[indexAccess(), value]),
        interfaceTarget: setter);
  }

  _makeWriteAndReturn(Expression value) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(new KernelMethodInvocation(
        new ThisExpression(),
        indexSetName,
        new KernelArguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)]),
        interfaceTarget: setter));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(
          Expression body, KernelComplexAssignment complexAssignment) =>
      makeLet(indexVariable, body);
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
      indexGetName, new KernelArguments(<Expression>[index]), getter);

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new SuperMethodInvocation(
        indexSetName, new KernelArguments(<Expression>[index, value]), setter);
  }

  Expression _makeRead(KernelComplexAssignment complexAssignment) {
    return new SuperMethodInvocation(
        indexGetName, new KernelArguments(<Expression>[indexAccess()]), getter);
  }

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new SuperMethodInvocation(indexSetName,
        new KernelArguments(<Expression>[indexAccess(), value]), setter);
  }

  _makeWriteAndReturn(Expression value) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(new SuperMethodInvocation(
        indexSetName,
        new KernelArguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)]),
        setter));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(
      Expression body, KernelComplexAssignment complexAssignment) {
    return makeLet(indexVariable, body);
  }
}

class StaticAccessor extends Accessor {
  Member readTarget;
  Member writeTarget;

  StaticAccessor(
      BuilderHelper helper, this.readTarget, this.writeTarget, Token token)
      : super(helper, token);

  Expression _makeRead(KernelComplexAssignment complexAssignment) =>
      readTarget == null
          ? makeInvalidRead()
          : helper.makeStaticGet(readTarget, token);

  Expression _makeWrite(Expression value, bool voidContext,
      KernelComplexAssignment complexAssignment) {
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

  Expression _makeRead(KernelComplexAssignment complexAssignment) {
    value ??= new VariableDeclaration.forValue(expression);
    return new VariableGet(value);
  }

  Expression _makeWrite(Expression value, bool voidContext,
          KernelComplexAssignment complexAssignment) =>
      makeInvalidWrite(value);

  Expression _finish(
          Expression body, KernelComplexAssignment complexAssignment) =>
      makeLet(value, body);
}

Expression makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression makeBinary(
    Expression left, Name operator, Procedure interfaceTarget, Expression right,
    {int offset: TreeNode.noOffset}) {
  return new KernelMethodInvocation(
      left, operator, new KernelArguments(<Expression>[right]),
      interfaceTarget: interfaceTarget)
    ..fileOffset = offset;
}

Expression buildIsNull(Expression value, {int offset: TreeNode.noOffset}) {
  return makeBinary(value, equalsName, null, new NullLiteral(), offset: offset);
}

VariableDeclaration makeOrReuseVariable(Expression value) {
  // TODO: Devise a way to remember if a variable declaration was reused
  // or is fresh (hence needs a let binding).
  return new VariableDeclaration.forValue(value);
}
