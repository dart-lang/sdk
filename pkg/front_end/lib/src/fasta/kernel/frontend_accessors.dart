// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help transform compounds and null-aware accessors into
/// let expressions.

import '../../scanner/token.dart' show Token;

import '../names.dart' show equalsName, indexGetName, indexSetName;

import '../parser.dart' show offsetForToken;

import '../problems.dart' show unhandled;

import 'fasta_accessors.dart' show BuilderHelper;

import 'forest.dart' show Forest;

import 'kernel_builder.dart' show LoadLibraryBuilder, PrefixBuilder;

import 'kernel_ast_api.dart'
    show
        DartType,
        Expression,
        Let,
        Member,
        Name,
        Procedure,
        PropertySet,
        ShadowComplexAssignment,
        ShadowIllegalAssignment,
        ShadowMethodInvocation,
        ShadowNullAwarePropertyGet,
        ShadowPropertyAssign,
        ShadowPropertyGet,
        ShadowSuperMethodInvocation,
        ShadowSuperPropertyGet,
        ShadowVariableDeclaration,
        ShadowVariableGet,
        Statement,
        StaticSet,
        SuperMethodInvocation,
        SuperPropertySet,
        TreeNode,
        VariableDeclaration,
        VariableGet,
        VariableSet;

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
abstract class Accessor<Arguments> {
  final BuilderHelper<dynamic, dynamic, Arguments> helper;
  final Token token;

  Accessor(this.helper, this.token);

  Forest<Expression, Statement, Token, Arguments> get forest => helper.forest;

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
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    var complexAssignment = startComplexAssignment(value);
    if (voidContext) {
      var nullAwareCombiner = helper.storeOffset(
          forest.conditionalExpression(
              buildIsNull(_makeRead(complexAssignment), offset, helper),
              null,
              _makeWrite(value, false, complexAssignment),
              null,
              helper.storeOffset(forest.literalNull(null), offset)),
          offset);
      complexAssignment?.nullAwareCombiner = nullAwareCombiner;
      return _finish(nullAwareCombiner, complexAssignment);
    }
    var tmp = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    var nullAwareCombiner = helper.storeOffset(
        forest.conditionalExpression(
            buildIsNull(new VariableGet(tmp), offset, helper),
            null,
            _makeWrite(value, false, complexAssignment),
            null,
            new VariableGet(tmp)),
        offset);
    complexAssignment?.nullAwareCombiner = nullAwareCombiner;
    return _finish(makeLet(tmp, nullAwareCombiner), complexAssignment);
  }

  /// Returns an [Expression] representing a compound assignment (e.g. `+=`)
  /// with the accessor on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    var complexAssignment = startComplexAssignment(value);
    complexAssignment?.isPreIncDec = isPreIncDec;
    var combiner = makeBinary(_makeRead(complexAssignment), binaryOperator,
        interfaceTarget, value, helper,
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
    return buildCompoundAssignment(
        binaryOperator, helper.storeOffset(forest.literalInt(1, null), offset),
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPreIncDec: true);
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
    var rhs = helper.storeOffset(forest.literalInt(1, null), offset);
    var complexAssignment = startComplexAssignment(rhs);
    var value = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    valueAccess() => new VariableGet(value);
    var combiner = makeBinary(
        valueAccess(), binaryOperator, interfaceTarget, rhs, helper,
        offset: offset);
    complexAssignment?.combiner = combiner;
    complexAssignment?.isPostIncDec = true;
    var dummy = new ShadowVariableDeclaration.forValue(
        _makeWrite(combiner, true, complexAssignment),
        helper.functionNestingLevel);
    return _finish(
        makeLet(value, makeLet(dummy, valueAccess())), complexAssignment);
  }

  Expression _makeSimpleRead() => _makeRead(null);

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return _makeWrite(value, voidContext, complexAssignment);
  }

  Expression _makeRead(ShadowComplexAssignment complexAssignment);

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment);

  Expression _finish(
      Expression body, ShadowComplexAssignment complexAssignment) {
    if (complexAssignment != null) {
      complexAssignment.desugared = body;
      return complexAssignment;
    } else {
      return body;
    }
  }

  /// Returns an [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  makeInvalidRead() {
    return unhandled("compile-time error", "$runtimeType",
        offsetForToken(token), helper.uri);
  }

  /// Returns an [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  makeInvalidWrite(Expression value) {
    return unhandled("compile-time error", "$runtimeType",
        offsetForToken(token), helper.uri);
  }

  /// Creates a data structure for tracking the desugaring of a complex
  /// assignment expression whose right hand side is [rhs].
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowIllegalAssignment(rhs);
}

abstract class VariableAccessor<Arguments> extends Accessor<Arguments> {
  VariableDeclaration variable;
  DartType promotedType;

  VariableAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.variable, this.promotedType, Token token)
      : super(helper, token);

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var fact = helper.typePromoter
        .getFactForAccess(variable, helper.functionNestingLevel);
    var scope = helper.typePromoter.currentScope;
    var read = new ShadowVariableGet(variable, fact, scope)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    helper.typePromoter.mutateVariable(variable, helper.functionNestingLevel);
    var write = variable.isFinal || variable.isConst
        ? makeInvalidWrite(value)
        : new VariableSet(variable, value)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }
}

class PropertyAccessor<Arguments> extends Accessor<Arguments> {
  VariableDeclaration _receiverVariable;
  Expression receiver;
  Name name;
  Member getter, setter;

  static Accessor<Arguments> make<Arguments>(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Expression receiver,
      Name name,
      Member getter,
      Member setter,
      {Token token}) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisPropertyAccessor(helper, name, getter, setter, token);
    } else {
      return new PropertyAccessor.internal(
          helper, receiver, name, getter, setter, token);
    }
  }

  PropertyAccessor.internal(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.receiver, this.name, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() => new ShadowPropertyGet(receiver, name, getter)
    ..fileOffset = offsetForToken(token);

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    var write = new PropertySet(receiver, name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  receiverAccess() {
    _receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(_receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowPropertyGet(receiverAccess(), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  Expression _finish(
      Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(makeLet(_receiverVariable, body), complexAssignment);
  }
}

/// Special case of [PropertyAccessor] to avoid creating an indirect access to
/// 'this'.
class ThisPropertyAccessor<Arguments> extends Accessor<Arguments> {
  Name name;
  Member getter, setter;

  ThisPropertyAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.name, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedGet(name, offsetForToken(token));
    }
    var read = new ShadowPropertyGet(forest.thisExpression(token), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (setter == null) {
      helper.warnUnresolvedSet(name, offsetForToken(token));
    }
    var write =
        new PropertySet(forest.thisExpression(token), name, value, setter)
          ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }
}

class NullAwarePropertyAccessor<Arguments> extends Accessor<Arguments> {
  VariableDeclaration receiver;
  Expression receiverExpression;
  Name name;
  Member getter, setter;
  DartType type;

  NullAwarePropertyAccessor(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.receiverExpression,
      this.name,
      this.getter,
      this.setter,
      this.type,
      Token token)
      : this.receiver = makeOrReuseVariable(receiverExpression),
        super(helper, token);

  receiverAccess() => new VariableGet(receiver);

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowPropertyGet(receiverAccess(), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  Expression _finish(
      Expression body, ShadowComplexAssignment complexAssignment) {
    var offset = offsetForToken(token);
    var nullAwareGuard = helper.storeOffset(
        forest.conditionalExpression(
            buildIsNull(receiverAccess(), offset, helper),
            null,
            helper.storeOffset(forest.literalNull(null), offset),
            null,
            body),
        offset);
    if (complexAssignment != null) {
      body = makeLet(receiver, nullAwareGuard);
      ShadowPropertyAssign kernelPropertyAssign = complexAssignment;
      kernelPropertyAssign.nullAwareGuard = nullAwareGuard;
      kernelPropertyAssign.desugared = body;
      return kernelPropertyAssign;
    } else {
      return new ShadowNullAwarePropertyGet(receiver, nullAwareGuard)
        ..fileOffset = offset;
    }
  }
}

class SuperPropertyAccessor<Arguments> extends Accessor<Arguments> {
  Name name;
  Member getter, setter;

  SuperPropertyAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.name, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedGet(name, offsetForToken(token), isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertyGet] when possible.
    var read = new ShadowSuperPropertyGet(name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (setter == null) {
      helper.warnUnresolvedSet(name, offsetForToken(token), isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertySet] when possible.
    var write = new SuperPropertySet(name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }
}

class IndexAccessor<Arguments> extends Accessor<Arguments> {
  Expression receiver;
  Expression index;
  VariableDeclaration receiverVariable;
  VariableDeclaration indexVariable;
  Procedure getter, setter;

  static Accessor<Arguments> make<Arguments>(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter,
      {Token token}) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisIndexAccessor(helper, index, getter, setter, token);
    } else {
      return new IndexAccessor.internal(
          helper, receiver, index, getter, setter, token);
    }
  }

  IndexAccessor.internal(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.receiver, this.index, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() {
    var read = new ShadowMethodInvocation(receiver, indexGetName,
        forest.castArguments(forest.arguments(<Expression>[index], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    return read;
  }

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        receiver,
        indexSetName,
        forest
            .castArguments(forest.arguments(<Expression>[index, value], token)),
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

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowMethodInvocation(
        receiverAccess(),
        indexGetName,
        forest.castArguments(
            forest.arguments(<Expression>[indexAccess()], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        receiverAccess(),
        indexSetName,
        forest.castArguments(
            forest.arguments(<Expression>[indexAccess(), value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  // TODO(dmitryas): remove this method after the "[]=" operator of the Context
  // class is made to return a value.
  _makeWriteAndReturn(
      Expression value, ShadowComplexAssignment complexAssignment) {
    // The call to []= does not return the value like direct-style assignments
    // do.  We need to bind the value in a let.
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new ShadowMethodInvocation(
        receiverAccess(),
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new ShadowVariableDeclaration.forValue(
        write, helper.functionNestingLevel);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(
      Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(
        makeLet(receiverVariable, makeLet(indexVariable, body)),
        complexAssignment);
  }
}

/// Special case of [IndexAccessor] to avoid creating an indirect access to
/// 'this'.
class ThisIndexAccessor<Arguments> extends Accessor<Arguments> {
  Expression index;
  VariableDeclaration indexVariable;
  Procedure getter, setter;

  ThisIndexAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.index, this.getter, this.setter, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() {
    return new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexGetName,
        forest.castArguments(forest.arguments(<Expression>[index], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexSetName,
        forest
            .castArguments(forest.arguments(<Expression>[index, value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexGetName,
        forest.castArguments(
            forest.arguments(<Expression>[indexAccess()], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(
            forest.arguments(<Expression>[indexAccess(), value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  _makeWriteAndReturn(
      Expression value, ShadowComplexAssignment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(
      Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(makeLet(indexVariable, body), complexAssignment);
  }
}

class SuperIndexAccessor<Arguments> extends Accessor<Arguments> {
  Expression index;
  VariableDeclaration indexVariable;
  Member getter, setter;

  SuperIndexAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.index, this.getter, this.setter, Token token)
      : super(helper, token);

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeSimpleRead() {
    if (getter == null) {
      helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    // TODO(ahe): Use [DirectMethodInvocation] when possible.
    return new ShadowSuperMethodInvocation(
        indexGetName,
        forest.castArguments(forest.arguments(<Expression>[index], token)),
        getter)
      ..fileOffset = offsetForToken(token);
  }

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest
            .castArguments(forest.arguments(<Expression>[index, value], token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    var read = new SuperMethodInvocation(
        indexGetName,
        forest.castArguments(
            forest.arguments(<Expression>[indexAccess()], token)),
        getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(
            forest.arguments(<Expression>[indexAccess(), value], token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  _makeWriteAndReturn(
      Expression value, ShadowComplexAssignment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(
      Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(makeLet(indexVariable, body), complexAssignment);
  }
}

class StaticAccessor<Arguments> extends Accessor<Arguments> {
  Member readTarget;
  Member writeTarget;

  StaticAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.readTarget, this.writeTarget, Token token)
      : super(helper, token);

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (readTarget == null) {
      return makeInvalidRead();
    } else {
      var read = helper.makeStaticGet(readTarget, token);
      complexAssignment?.read = read;
      return read;
    }
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    Expression write;
    if (writeTarget == null) {
      write = makeInvalidWrite(value);
    } else {
      write = new StaticSet(writeTarget, value);
      complexAssignment?.write = write;
    }
    write.fileOffset = offsetForToken(token);
    return write;
  }
}

abstract class LoadLibraryAccessor<Arguments> extends Accessor<Arguments> {
  final LoadLibraryBuilder builder;

  LoadLibraryAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.builder)
      : super(helper, token);

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read =
        helper.makeStaticGet(builder.createTearoffMethod(helper.forest), token);
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    Expression write = makeInvalidWrite(value);
    write.fileOffset = offsetForToken(token);
    return write;
  }
}

abstract class DeferredAccessor<Arguments> extends Accessor<Arguments> {
  final PrefixBuilder builder;
  final Accessor accessor;

  DeferredAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.builder, this.accessor)
      : super(helper, token);

  Expression _makeSimpleRead() {
    return helper.wrapInDeferredCheck(
        accessor._makeSimpleRead(), builder, token.charOffset);
  }

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return helper.wrapInDeferredCheck(
        accessor._makeRead(complexAssignment), builder, token.charOffset);
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return helper.wrapInDeferredCheck(
        accessor._makeWrite(value, voidContext, complexAssignment),
        builder,
        token.charOffset);
  }
}

class ReadOnlyAccessor<Arguments> extends Accessor<Arguments> {
  Expression expression;
  VariableDeclaration value;

  ReadOnlyAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper,
      this.expression, Token token)
      : super(helper, token);

  Expression _makeSimpleRead() => expression;

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    value ??= new VariableDeclaration.forValue(expression);
    return new VariableGet(value);
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    var write = makeInvalidWrite(value);
    complexAssignment?.write = write;
    return write;
  }

  Expression _finish(
          Expression body, ShadowComplexAssignment complexAssignment) =>
      super._finish(makeLet(value, body), complexAssignment);
}

abstract class DelayedErrorAccessor<Arguments> extends Accessor<Arguments> {
  DelayedErrorAccessor(
      BuilderHelper<dynamic, dynamic, Arguments> helper, Token token)
      : super(helper, token);

  Expression buildError();

  Expression _makeSimpleRead() => buildError();
  Expression _makeSimpleWrite(Expression value, bool voidContext,
          ShadowComplexAssignment complexAssignment) =>
      buildError();
  Expression _makeRead(ShadowComplexAssignment complexAssignment) =>
      buildError();
  Expression _makeWrite(Expression value, bool voidContext,
          ShadowComplexAssignment complexAssignment) =>
      buildError();
}

Expression makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression makeBinary<Arguments>(
    Expression left,
    Name operator,
    Procedure interfaceTarget,
    Expression right,
    BuilderHelper<dynamic, dynamic, Arguments> helper,
    {int offset: TreeNode.noOffset}) {
  return new ShadowMethodInvocation(
      left,
      operator,
      helper.storeOffset(
          helper.forest.castArguments(
              helper.forest.arguments(<Expression>[right], null)),
          offset),
      interfaceTarget: interfaceTarget)
    ..fileOffset = offset;
}

Expression buildIsNull<Arguments>(Expression value, int offset,
    BuilderHelper<dynamic, dynamic, Arguments> helper) {
  return makeBinary(value, equalsName, null,
      helper.storeOffset(helper.forest.literalNull(null), offset), helper,
      offset: offset);
}

VariableDeclaration makeOrReuseVariable(Expression value) {
  // TODO: Devise a way to remember if a variable declaration was reused
  // or is fresh (hence needs a let binding).
  return new VariableDeclaration.forValue(value);
}
