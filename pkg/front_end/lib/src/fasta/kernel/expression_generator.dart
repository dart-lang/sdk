// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help generate expression.
library fasta.expression_generator;

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        messageInvalidInitializer,
        messageLoadLibraryTakesNoArguments,
        messageSuperAsExpression,
        templateDeferredTypeAnnotation,
        templateIntegerLiteralIsOutOfRange,
        templateNotAPrefixInTypeAnnotation,
        templateNotAType,
        templateUnresolvedPrefixInTypeAnnotation;

import '../messages.dart' show Message, noLength;

import '../names.dart'
    show callName, equalsName, indexGetName, indexSetName, lengthName;

import '../parser.dart' show lengthForToken, lengthOfSpan, offsetForToken;

import '../problems.dart' show unhandled, unsupported;

import '../scope.dart' show AccessErrorBuilder;

import 'body_builder.dart' show Identifier, noLocation;

import 'constness.dart' show Constness;

import 'expression_generator_helper.dart' show BuilderHelper;

import 'forest.dart' show Forest;

import 'kernel_builder.dart' show LoadLibraryBuilder, PrefixBuilder;

import 'kernel_api.dart' show NameSystem, printNodeOn, printQualifiedNameOn;

import 'kernel_ast_api.dart'
    show
        Constructor,
        DartType,
        Field,
        Initializer,
        InvalidType,
        Let,
        Member,
        Name,
        Procedure,
        PropertySet,
        ShadowComplexAssignment,
        ShadowIllegalAssignment,
        ShadowIndexAssign,
        ShadowMethodInvocation,
        ShadowNullAwarePropertyGet,
        ShadowPropertyAssign,
        ShadowPropertyGet,
        ShadowStaticAssignment,
        ShadowSuperMethodInvocation,
        ShadowSuperPropertyGet,
        ShadowVariableAssignment,
        ShadowVariableDeclaration,
        ShadowVariableGet,
        StaticSet,
        SuperMethodInvocation,
        SuperPropertySet,
        Throw,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        VariableSet;

import 'kernel_ast_api.dart' as kernel show Expression, Node, Statement;

import 'kernel_builder.dart'
    show
        Builder,
        BuiltinTypeBuilder,
        FunctionTypeAliasBuilder,
        KernelClassBuilder,
        KernelFunctionTypeAliasBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeVariableBuilder,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder;

/// A generator represents a subexpression for which we can't yet build an
/// expression because we don't yet know the context in which it's used.
///
/// Once the context is known, a generator can be converted into an expression
/// by calling a `build` method.
///
/// For example, when building a kernel representation for `a[x] = b`, after
/// parsing `a[x]` but before parsing `= b`, we don't yet know whether to
/// generate an invocation of `operator[]` or `operator[]=`, so we create a
/// [Generator] object.  Later, after `= b` is parsed, [buildAssignment] will
/// be called.
abstract class Generator<Arguments> {
  final BuilderHelper<dynamic, dynamic, Arguments> helper;
  final Token token;

  Generator(this.helper, this.token);

  // TODO(ahe): Change type arguments.
  Forest<kernel.Expression, kernel.Statement, Token, Arguments> get forest =>
      helper.forest;

  String get plainNameForRead;

  String get debugName;

  Uri get uri => helper.uri;

  String get plainNameForWrite => plainNameForRead;

  bool get isInitializer => false;

  /// Builds a [kernel.Expression] representing a read from the generator.
  kernel.Expression buildSimpleRead() {
    return _finish(_makeSimpleRead(), null);
  }

  /// Builds a [kernel.Expression] representing an assignment with the
  /// generator on the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  kernel.Expression buildAssignment(kernel.Expression value,
      {bool voidContext: false}) {
    var complexAssignment = startComplexAssignment(value);
    return _finish(_makeSimpleWrite(value, voidContext, complexAssignment),
        complexAssignment);
  }

  /// Returns a [kernel.Expression] representing a null-aware assignment
  /// (`??=`) with the generator on the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  ///
  /// [type] is the static type of the RHS.
  kernel.Expression buildNullAwareAssignment(
      kernel.Expression value, DartType type, int offset,
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

  /// Returns a [kernel.Expression] representing a compound assignment
  /// (e.g. `+=`) with the generator on the LHS and [value] on the RHS.
  kernel.Expression buildCompoundAssignment(
      Name binaryOperator, kernel.Expression value,
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

  /// Returns a [kernel.Expression] representing a pre-increment or
  /// pre-decrement of the generator.
  kernel.Expression buildPrefixIncrement(Name binaryOperator,
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

  /// Returns a [kernel.Expression] representing a post-increment or
  /// post-decrement of the generator.
  kernel.Expression buildPostfixIncrement(Name binaryOperator,
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

  kernel.Expression _makeSimpleRead() => _makeRead(null);

  kernel.Expression _makeSimpleWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return _makeWrite(value, voidContext, complexAssignment);
  }

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment);

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment);

  kernel.Expression _finish(
      kernel.Expression body, ShadowComplexAssignment complexAssignment) {
    if (complexAssignment != null) {
      complexAssignment.desugared = body;
      return complexAssignment;
    } else {
      return body;
    }
  }

  /// Returns a [kernel.Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  kernel.Expression makeInvalidRead() {
    return buildThrowNoSuchMethodError(
        forest.literalNull(token), forest.argumentsEmpty(noLocation),
        isGetter: true);
  }

  /// Returns a [kernel.Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  kernel.Expression makeInvalidWrite(kernel.Expression value) {
    return buildThrowNoSuchMethodError(forest.literalNull(token),
        forest.arguments(<kernel.Expression>[value], noLocation),
        isSetter: true);
  }

  /// Creates a data structure for tracking the desugaring of a complex
  /// assignment expression whose right hand side is [rhs].
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowIllegalAssignment(rhs);

  T storeOffset<T>(T node, int offset) {
    return helper.storeOffset(node, offset);
  }

  kernel.Expression buildForEffect() => buildSimpleRead();

  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    int offset = offsetForToken(token);
    return helper.buildInvalidInitializer(
        helper.buildCompileTimeError(
            messageInvalidInitializer, offset, lengthForToken(token)),
        offset);
  }

  /* kernel.Expression | Generator | Initializer */ doInvocation(
      int offset, Arguments arguments);

  /* kernel.Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is SendAccessor) {
      return helper.buildMethodInvocation(buildSimpleRead(), send.name,
          send.arguments, offsetForToken(send.token),
          isNullAware: isNullAware);
    } else {
      if (helper.constantContext != ConstantContext.none &&
          send.name != lengthName) {
        helper.deprecated_addCompileTimeError(
            offsetForToken(token), "Not a constant expression.");
      }
      return PropertyAccessGenerator.make(helper, send.token, buildSimpleRead(),
          send.name, null, null, isNullAware);
    }
  }

  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false}) {
    helper.addProblem(templateNotAType.withArguments(token.lexeme),
        offsetForToken(token), lengthForToken(token));
    return const InvalidType();
  }

  /* kernel.Expression | Generator */ buildThrowNoSuchMethodError(
      kernel.Expression receiver, Arguments arguments,
      {bool isSuper: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isStatic: false,
      String name,
      int offset,
      LocatedMessage argMessage}) {
    return helper.throwNoSuchMethodError(receiver, name ?? plainNameForWrite,
        arguments, offset ?? offsetForToken(this.token),
        isGetter: isGetter,
        isSetter: isSetter,
        isSuper: isSuper,
        isStatic: isStatic,
        argMessage: argMessage);
  }

  bool get isThisPropertyAccess => false;

  void printOn(StringSink sink);

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write(debugName);
    buffer.write("(offset: ");
    buffer.write("${offsetForToken(token)}");
    printOn(buffer);
    buffer.write(")");
    return "$buffer";
  }
}

class VariableUseGenerator<Arguments> extends Generator<Arguments> {
  final VariableDeclaration variable;

  final DartType promotedType;

  VariableUseGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.variable,
      [this.promotedType])
      : super(helper, token);

  String get plainNameForRead => variable.name;

  String get debugName => "VariableUseGenerator";

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var fact = helper.typePromoter
        .getFactForAccess(variable, helper.functionNestingLevel);
    var scope = helper.typePromoter.currentScope;
    var read = new ShadowVariableGet(variable, fact, scope)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    helper.typePromoter.mutateVariable(variable, helper.functionNestingLevel);
    var write = variable.isFinal || variable.isConst
        ? makeInvalidWrite(value)
        : new VariableSet(variable, value)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(plainNameForRead, offset),
        isImplicitCall: true);
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowVariableAssignment(rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", variable: ");
    printNodeOn(variable, sink, syntheticNames: syntheticNames);
    sink.write(", promotedType: ");
    printNodeOn(promotedType, sink, syntheticNames: syntheticNames);
  }
}

class PropertyAccessGenerator<Arguments> extends Generator<Arguments> {
  final kernel.Expression receiver;

  final Name name;

  final Member getter;

  final Member setter;

  VariableDeclaration _receiverVariable;

  PropertyAccessGenerator.internal(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token,
      this.receiver,
      this.name,
      this.getter,
      this.setter)
      : super(helper, token);

  static Generator<Arguments> make<Arguments>(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token,
      kernel.Expression receiver,
      Name name,
      Member getter,
      Member setter,
      bool isNullAware) {
    if (helper.forest.isThisExpression(receiver)) {
      return unsupported("ThisExpression", offsetForToken(token), helper.uri);
    } else {
      return isNullAware
          ? new NullAwarePropertyAccessGenerator(
              helper, token, receiver, name, getter, setter, null)
          : new PropertyAccessGenerator.internal(
              helper, token, receiver, name, getter, setter);
    }
  }

  String get plainNameForRead => name.name;

  String get debugName => "PropertyAccessGenerator";

  bool get isThisPropertyAccess => forest.isThisExpression(receiver);

  kernel.Expression _makeSimpleRead() =>
      new ShadowPropertyGet(receiver, name, getter)
        ..fileOffset = offsetForToken(token);

  kernel.Expression _makeSimpleWrite(kernel.Expression value, bool voidContext,
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

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowPropertyGet(receiverAccess(), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  kernel.Expression _finish(
      kernel.Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(makeLet(_receiverVariable, body), complexAssignment);
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(receiver, name, arguments, offset);
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowPropertyAssign(receiver, rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", _receiverVariable: ");
    printNodeOn(_receiverVariable, sink, syntheticNames: syntheticNames);
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }
}

/// Special case of [PropertyAccessGenerator] to avoid creating an indirect
/// access to 'this'.
class ThisPropertyAccessGenerator<Arguments> extends Generator<Arguments> {
  final Name name;

  final Member getter;

  final Member setter;

  ThisPropertyAccessGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.name, this.getter, this.setter)
      : super(helper, token);

  String get plainNameForRead => name.name;

  String get debugName => "ThisPropertyAccessGenerator";

  bool get isThisPropertyAccess => true;

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedGet(name, offsetForToken(token));
    }
    var read = new ShadowPropertyGet(forest.thisExpression(token), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
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

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    Member interfaceTarget = getter;
    if (interfaceTarget == null) {
      helper.warnUnresolvedMethod(name, offset);
    }
    if (interfaceTarget is Field) {
      // TODO(ahe): In strong mode we should probably rewrite this to
      // `this.name.call(arguments)`.
      interfaceTarget = null;
    }
    return helper.buildMethodInvocation(
        forest.thisExpression(null), name, arguments, offset,
        interfaceTarget: interfaceTarget);
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowPropertyAssign(null, rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }
}

class NullAwarePropertyAccessGenerator<Arguments> extends Generator<Arguments> {
  final VariableDeclaration receiver;

  final kernel.Expression receiverExpression;

  final Name name;

  final Member getter;

  final Member setter;

  final DartType type;

  NullAwarePropertyAccessGenerator(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token,
      this.receiverExpression,
      this.name,
      this.getter,
      this.setter,
      this.type)
      : this.receiver = makeOrReuseVariable(receiverExpression),
        super(helper, token);

  String get plainNameForRead => name.name;

  String get debugName => "NullAwarePropertyAccessGenerator";

  kernel.Expression receiverAccess() => new VariableGet(receiver);

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowPropertyGet(receiverAccess(), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  kernel.Expression _finish(
      kernel.Expression body, ShadowComplexAssignment complexAssignment) {
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

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, uri);
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowPropertyAssign(receiverExpression, rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", receiverExpression: ");
    printNodeOn(receiverExpression, sink, syntheticNames: syntheticNames);
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
    sink.write(", type: ");
    printNodeOn(type, sink, syntheticNames: syntheticNames);
  }
}

class SuperPropertyAccessGenerator<Arguments> extends Generator<Arguments> {
  final Name name;

  final Member getter;

  final Member setter;

  SuperPropertyAccessGenerator(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token,
      this.name,
      this.getter,
      this.setter)
      : super(helper, token);

  String get plainNameForRead => name.name;

  String get debugName => "SuperPropertyAccessGenerator";

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedGet(name, offsetForToken(token), isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertyGet] when possible.
    var read = new ShadowSuperPropertyGet(name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
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

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    if (helper.constantContext != ConstantContext.none) {
      helper.deprecated_addCompileTimeError(
          offset, "Not a constant expression.");
    }
    if (getter == null || isFieldOrGetter(getter)) {
      return helper.buildMethodInvocation(
          buildSimpleRead(), callName, arguments, offset,
          // This isn't a constant expression, but we have checked if a
          // constant expression error should be emitted already.
          isConstantExpression: true,
          isImplicitCall: true);
    } else {
      // TODO(ahe): This could be something like "super.property(...)" where
      // property is a setter.
      return unhandled("${getter.runtimeType}", "doInvocation", offset, uri);
    }
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowPropertyAssign(null, rhs, isSuper: true);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }
}

class IndexedAccessGenerator<Arguments> extends Generator<Arguments> {
  final kernel.Expression receiver;

  final kernel.Expression index;

  final Procedure getter;

  final Procedure setter;

  VariableDeclaration receiverVariable;

  VariableDeclaration indexVariable;

  IndexedAccessGenerator.internal(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token,
      this.receiver,
      this.index,
      this.getter,
      this.setter)
      : super(helper, token);

  static Generator<Arguments> make<Arguments>(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token,
      kernel.Expression receiver,
      kernel.Expression index,
      Procedure getter,
      Procedure setter) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisIndexedAccessGenerator(
          helper, token, index, getter, setter);
    } else {
      return new IndexedAccessGenerator.internal(
          helper, token, receiver, index, getter, setter);
    }
  }

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  String get debugName => "IndexedAccessGenerator";

  kernel.Expression _makeSimpleRead() {
    var read = new ShadowMethodInvocation(
        receiver,
        indexGetName,
        forest
            .castArguments(forest.arguments(<kernel.Expression>[index], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    return read;
  }

  kernel.Expression _makeSimpleWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        receiver,
        indexSetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[index, value], token)),
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

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowMethodInvocation(
        receiverAccess(),
        indexGetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[indexAccess()], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        receiverAccess(),
        indexSetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[indexAccess(), value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  // TODO(dmitryas): remove this method after the "[]=" operator of the Context
  // class is made to return a value.
  _makeWriteAndReturn(
      kernel.Expression value, ShadowComplexAssignment complexAssignment) {
    // The call to []= does not return the value like direct-style assignments
    // do.  We need to bind the value in a let.
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new ShadowMethodInvocation(
        receiverAccess(),
        indexSetName,
        forest.castArguments(forest.arguments(
            <kernel.Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new ShadowVariableDeclaration.forValue(
        write, helper.functionNestingLevel);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  kernel.Expression _finish(
      kernel.Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(
        makeLet(receiverVariable, makeLet(indexVariable, body)),
        complexAssignment);
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, forest.readOffset(arguments),
        isImplicitCall: true);
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowIndexAssign(receiver, index, rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
    sink.write(", receiverVariable: ");
    printNodeOn(receiverVariable, sink, syntheticNames: syntheticNames);
    sink.write(", indexVariable: ");
    printNodeOn(indexVariable, sink, syntheticNames: syntheticNames);
  }
}

/// Special case of [IndexedAccessGenerator] to avoid creating an indirect
/// access to 'this'.
class ThisIndexedAccessGenerator<Arguments> extends Generator<Arguments> {
  final kernel.Expression index;

  final Procedure getter;

  final Procedure setter;

  VariableDeclaration indexVariable;

  ThisIndexedAccessGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.index, this.getter, this.setter)
      : super(helper, token);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  String get debugName => "ThisIndexedAccessGenerator";

  kernel.Expression _makeSimpleRead() {
    return new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexGetName,
        forest
            .castArguments(forest.arguments(<kernel.Expression>[index], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
  }

  kernel.Expression _makeSimpleWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[index, value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexGetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[indexAccess()], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[indexAccess(), value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  _makeWriteAndReturn(
      kernel.Expression value, ShadowComplexAssignment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new ShadowMethodInvocation(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(forest.arguments(
            <kernel.Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  kernel.Expression _finish(
      kernel.Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(makeLet(indexVariable, body), complexAssignment);
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowIndexAssign(null, index, rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
    sink.write(", indexVariable: ");
    printNodeOn(indexVariable, sink, syntheticNames: syntheticNames);
  }
}

class SuperIndexedAccessGenerator<Arguments> extends Generator<Arguments> {
  final kernel.Expression index;

  final Member getter;

  final Member setter;

  VariableDeclaration indexVariable;

  SuperIndexedAccessGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.index, this.getter, this.setter)
      : super(helper, token);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  String get debugName => "SuperIndexedAccessGenerator";

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  kernel.Expression _makeSimpleRead() {
    if (getter == null) {
      helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    // TODO(ahe): Use [DirectMethodInvocation] when possible.
    return new ShadowSuperMethodInvocation(
        indexGetName,
        forest
            .castArguments(forest.arguments(<kernel.Expression>[index], token)),
        getter)
      ..fileOffset = offsetForToken(token);
  }

  kernel.Expression _makeSimpleWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[index, value], token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    var read = new SuperMethodInvocation(
        indexGetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[indexAccess()], token)),
        getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(
            forest.arguments(<kernel.Expression>[indexAccess(), value], token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  _makeWriteAndReturn(
      kernel.Expression value, ShadowComplexAssignment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(forest.arguments(
            <kernel.Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  kernel.Expression _finish(
      kernel.Expression body, ShadowComplexAssignment complexAssignment) {
    return super._finish(makeLet(indexVariable, body), complexAssignment);
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowIndexAssign(null, index, rhs, isSuper: true);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
    sink.write(", indexVariable: ");
    printNodeOn(indexVariable, sink, syntheticNames: syntheticNames);
  }
}

class StaticAccessGenerator<Arguments> extends Generator<Arguments> {
  final Member readTarget;

  final Member writeTarget;

  StaticAccessGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.readTarget, this.writeTarget)
      : assert(readTarget != null || writeTarget != null),
        super(helper, token);

  factory StaticAccessGenerator.fromBuilder(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Builder builder,
      Token token,
      Builder builderSetter) {
    if (builder is AccessErrorBuilder) {
      AccessErrorBuilder error = builder;
      builder = error.builder;
      // We should only see an access error here if we've looked up a setter
      // when not explicitly looking for a setter.
      assert(builder.isSetter);
    } else if (builder.target == null) {
      return unhandled(
          "${builder.runtimeType}",
          "StaticAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri);
    }
    Member getter = builder.target.hasGetter ? builder.target : null;
    Member setter = builder.target.hasSetter ? builder.target : null;
    if (setter == null) {
      if (builderSetter?.target?.hasSetter ?? false) {
        setter = builderSetter.target;
      }
    }
    return new StaticAccessGenerator(helper, token, getter, setter);
  }

  String get plainNameForRead => (readTarget ?? writeTarget).name.name;

  String get debugName => "StaticAccessGenerator";

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    if (readTarget == null) {
      return makeInvalidRead();
    } else {
      var read = helper.makeStaticGet(readTarget, token);
      complexAssignment?.read = read;
      return read;
    }
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    kernel.Expression write;
    if (writeTarget == null) {
      write = makeInvalidWrite(value);
    } else {
      write = new StaticSet(writeTarget, value);
      complexAssignment?.write = write;
    }
    write.fileOffset = offsetForToken(token);
    return write;
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    if (helper.constantContext != ConstantContext.none &&
        !helper.isIdentical(readTarget)) {
      helper.deprecated_addCompileTimeError(
          offset, "Not a constant expression.");
    }
    if (readTarget == null || isFieldOrGetter(readTarget)) {
      return helper.buildMethodInvocation(buildSimpleRead(), callName,
          arguments, offset + (readTarget?.name?.name?.length ?? 0),
          // This isn't a constant expression, but we have checked if a
          // constant expression error should be emitted already.
          isConstantExpression: true,
          isImplicitCall: true);
    } else {
      return helper.buildStaticInvocation(readTarget, arguments,
          charOffset: offset);
    }
  }

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowStaticAssignment(rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink, syntheticNames: syntheticNames);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink, syntheticNames: syntheticNames);
  }
}

class LoadLibraryGenerator<Arguments> extends Generator<Arguments> {
  final LoadLibraryBuilder builder;

  LoadLibraryGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.builder)
      : super(helper, token);

  String get plainNameForRead => 'loadLibrary';

  String get debugName => "LoadLibraryGenerator";

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    var read =
        helper.makeStaticGet(builder.createTearoffMethod(helper.forest), token);
    complexAssignment?.read = read;
    return read;
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    kernel.Expression write = makeInvalidWrite(value);
    write.fileOffset = offsetForToken(token);
    return write;
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    if (forest.argumentsPositional(arguments).length > 0 ||
        forest.argumentsNamed(arguments).length > 0) {
      helper.addProblemErrorIfConst(
          messageLoadLibraryTakesNoArguments, offset, 'loadLibrary'.length);
    }
    return builder.createLoadLibrary(offset, forest);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", builder: ");
    sink.write(builder);
  }
}

class DeferredAccessGenerator<Arguments> extends Generator<Arguments> {
  final PrefixBuilder builder;

  final Generator generator;

  DeferredAccessGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.builder, this.generator)
      : super(helper, token);

  String get plainNameForRead {
    return unsupported(
        "deferredAccessor.plainNameForRead", offsetForToken(token), uri);
  }

  String get debugName => "DeferredAccessGenerator";

  kernel.Expression _makeSimpleRead() {
    return helper.wrapInDeferredCheck(
        generator._makeSimpleRead(), builder, token.charOffset);
  }

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return helper.wrapInDeferredCheck(
        generator._makeRead(complexAssignment), builder, token.charOffset);
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return helper.wrapInDeferredCheck(
        generator._makeWrite(value, voidContext, complexAssignment),
        builder,
        token.charOffset);
  }

  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    var propertyAccess =
        generator.buildPropertyAccess(send, operatorOffset, isNullAware);
    if (propertyAccess is Generator) {
      return new DeferredAccessGenerator(
          helper, token, builder, propertyAccess);
    } else {
      kernel.Expression expression = propertyAccess;
      return helper.wrapInDeferredCheck(expression, builder, token.charOffset);
    }
  }

  @override
  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false}) {
    helper.addProblem(
        templateDeferredTypeAnnotation.withArguments(
            generator.buildTypeWithBuiltArguments(arguments,
                nonInstanceAccessIsError: nonInstanceAccessIsError),
            builder.name),
        offsetForToken(token),
        lengthForToken(token));
    return const InvalidType();
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.wrapInDeferredCheck(
        generator.doInvocation(offset, arguments), builder, token.charOffset);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", builder: ");
    sink.write(builder);
    sink.write(", generator: ");
    sink.write(generator);
  }
}

class ReadOnlyAccessGenerator<Arguments> extends Generator<Arguments> {
  final String plainNameForRead;

  kernel.Expression expression;

  VariableDeclaration value;

  ReadOnlyAccessGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.expression, this.plainNameForRead)
      : super(helper, token);

  String get debugName => "ReadOnlyAccessGenerator";

  kernel.Expression _makeSimpleRead() => expression;

  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    value ??= new VariableDeclaration.forValue(expression);
    return new VariableGet(value);
  }

  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    var write = makeInvalidWrite(value);
    complexAssignment?.write = write;
    return write;
  }

  kernel.Expression _finish(
          kernel.Expression body, ShadowComplexAssignment complexAssignment) =>
      super._finish(makeLet(value, body), complexAssignment);

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(plainNameForRead, offset),
        isImplicitCall: true);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", expression: ");
    printNodeOn(expression, sink, syntheticNames: syntheticNames);
    sink.write(", plainNameForRead: ");
    sink.write(plainNameForRead);
    sink.write(", value: ");
    printNodeOn(value, sink, syntheticNames: syntheticNames);
  }
}

class LargeIntAccessGenerator<Arguments> extends Generator<Arguments> {
  LargeIntAccessGenerator(
      BuilderHelper<dynamic, dynamic, Arguments> helper, Token token)
      : super(helper, token);

  // TODO(ahe): This should probably be calling unhandled.
  String get plainNameForRead => null;

  String get debugName => "LargeIntAccessGenerator";

  @override
  kernel.Expression _makeSimpleRead() => buildError();

  @override
  kernel.Expression _makeSimpleWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return buildError();
  }

  @override
  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return buildError();
  }

  @override
  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return buildError();
  }

  kernel.Expression buildError() {
    return helper.buildCompileTimeError(
        templateIntegerLiteralIsOutOfRange.withArguments(token),
        offsetForToken(token),
        lengthForToken(token));
  }

  @override
  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return buildError();
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", lexeme: ");
    sink.write(token.lexeme);
  }
}

abstract class ErroneousExpressionGenerator<Arguments>
    implements Generator<Arguments> {
  /// Pass [arguments] that must be evaluated before throwing an error.  At
  /// most one of [isGetter] and [isSetter] should be true and they're passed
  /// to [BuilderHelper.buildThrowNoSuchMethodError] if it is used.
  kernel.Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset});

  DartType buildErroneousTypeNotAPrefix(Identifier suffix);

  Name get name => unsupported("name", offsetForToken(token), uri);

  @override
  String get plainNameForRead => name.name;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware}) => this;

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    return helper.buildInvalidInitializer(
        buildError(forest.argumentsEmpty(noLocation), isSetter: true));
  }

  @override
  doInvocation(int offset, Arguments arguments) {
    return buildError(arguments, offset: offset);
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    return this;
  }

  @override
  buildThrowNoSuchMethodError(kernel.Expression receiver, Arguments arguments,
      {bool isSuper: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isStatic: false,
      String name,
      int offset,
      LocatedMessage argMessage}) {
    return this;
  }

  @override
  kernel.Expression buildAssignment(kernel.Expression value,
      {bool voidContext: false}) {
    return buildError(forest.arguments(<kernel.Expression>[value], noLocation),
        isSetter: true);
  }

  @override
  kernel.Expression buildCompoundAssignment(
      Name binaryOperator, kernel.Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return buildError(forest.arguments(<kernel.Expression>[value], token),
        isGetter: true);
  }

  @override
  kernel.Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    // TODO(ahe): For the Analyzer, we probably need to build a prefix
    // increment node that wraps an error.
    return buildError(
        forest.arguments(<kernel.Expression>[
          storeOffset(forest.literalInt(1, null), offset)
        ], noLocation),
        isGetter: true);
  }

  @override
  kernel.Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    // TODO(ahe): For the Analyzer, we probably need to build a post increment
    // node that wraps an error.
    return buildError(
        forest.arguments(<kernel.Expression>[
          storeOffset(forest.literalInt(1, null), offset)
        ], noLocation),
        isGetter: true);
  }

  @override
  kernel.Expression buildNullAwareAssignment(
      kernel.Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildError(forest.arguments(<kernel.Expression>[value], noLocation),
        isSetter: true);
  }

  @override
  kernel.Expression buildSimpleRead() =>
      buildError(forest.argumentsEmpty(noLocation), isGetter: true);

  @override
  kernel.Expression makeInvalidRead() =>
      buildError(forest.argumentsEmpty(noLocation), isGetter: true);

  @override
  kernel.Expression makeInvalidWrite(kernel.Expression value) {
    return buildError(forest.arguments(<kernel.Expression>[value], noLocation),
        isSetter: true);
  }
}

class ThisAccessGenerator<Arguments> extends Generator<Arguments> {
  final bool isInitializer;

  final bool isSuper;

  ThisAccessGenerator(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.isInitializer,
      {this.isSuper: false})
      : super(helper, token);

  String get plainNameForRead {
    return unsupported("${isSuper ? 'super' : 'this'}.plainNameForRead",
        offsetForToken(token), uri);
  }

  String get debugName => "ThisAccessGenerator";

  kernel.Expression buildSimpleRead() {
    if (!isSuper) {
      return forest.thisExpression(token);
    } else {
      return helper.buildCompileTimeError(messageSuperAsExpression,
          offsetForToken(token), lengthForToken(token));
    }
  }

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    String keyword = isSuper ? "super" : "this";
    int offset = offsetForToken(token);
    return helper.buildInvalidInitializer(
        helper.deprecated_buildCompileTimeError(
            "Can't use '$keyword' here, did you mean '$keyword()'?", offset),
        offset);
  }

  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    Name name = send.name;
    Arguments arguments = send.arguments;
    int offset = offsetForToken(send.token);
    if (isInitializer && send is SendAccessor) {
      if (isNullAware) {
        helper.deprecated_addCompileTimeError(
            operatorOffset, "Expected '.'\nTry removing '?'.");
      }
      return buildConstructorInitializer(offset, name, arguments);
    }
    Member getter = helper.lookupInstanceMember(name, isSuper: isSuper);
    if (send is SendAccessor) {
      // Notice that 'this' or 'super' can't be null. So we can ignore the
      // value of [isNullAware].
      if (getter == null) {
        helper.warnUnresolvedMethod(name, offsetForToken(send.token),
            isSuper: isSuper);
      }
      return helper.buildMethodInvocation(forest.thisExpression(null), name,
          send.arguments, offsetForToken(send.token),
          isSuper: isSuper, interfaceTarget: getter);
    } else {
      Member setter =
          helper.lookupInstanceMember(name, isSuper: isSuper, isSetter: true);
      if (isSuper) {
        return new SuperPropertyAccessGenerator(
            helper, send.token, name, getter, setter);
      } else {
        return new ThisPropertyAccessGenerator(
            helper, send.token, name, getter, setter);
      }
    }
  }

  doInvocation(int offset, Arguments arguments) {
    if (isInitializer) {
      return buildConstructorInitializer(offset, new Name(""), arguments);
    } else if (isSuper) {
      return helper.buildCompileTimeError(
          messageSuperAsExpression, offset, noLength);
    } else {
      return helper.buildMethodInvocation(
          forest.thisExpression(null), callName, arguments, offset,
          isImplicitCall: true);
    }
  }

  Initializer buildConstructorInitializer(
      int offset, Name name, Arguments arguments) {
    Constructor constructor = helper.lookupConstructor(name, isSuper: isSuper);
    LocatedMessage argMessage;
    if (constructor != null) {
      argMessage = helper.checkArgumentsForFunction(
          constructor.function, arguments, offset, <TypeParameter>[]);
    }
    if (constructor == null || argMessage != null) {
      return helper.buildInvalidInitializer(
          buildThrowNoSuchMethodError(
              storeOffset(forest.literalNull(null), offset), arguments,
              isSuper: isSuper,
              name: name.name,
              offset: offset,
              argMessage: argMessage),
          offset);
    } else if (isSuper) {
      return helper.buildSuperInitializer(
          false, constructor, arguments, offset);
    } else {
      return helper.buildRedirectingInitializer(constructor, arguments, offset);
    }
  }

  kernel.Expression buildAssignment(kernel.Expression value,
      {bool voidContext: false}) {
    return buildAssignmentError();
  }

  kernel.Expression buildNullAwareAssignment(
      kernel.Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildAssignmentError();
  }

  kernel.Expression buildCompoundAssignment(
      Name binaryOperator, kernel.Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return buildAssignmentError();
  }

  kernel.Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildAssignmentError();
  }

  kernel.Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildAssignmentError();
  }

  kernel.Expression buildAssignmentError() {
    String message =
        isSuper ? "Can't assign to 'super'." : "Can't assign to 'this'.";
    return helper.deprecated_buildCompileTimeError(
        message, offsetForToken(token));
  }

  @override
  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeRead", offsetForToken(token), uri);
  }

  @override
  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeWrite", offsetForToken(token), uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", isInitializer: ");
    sink.write(isInitializer);
    sink.write(", isSuper: ");
    sink.write(isSuper);
  }
}

abstract class IncompleteSendGenerator<Arguments> extends Generator<Arguments> {
  final Name name;

  IncompleteSendGenerator(
      BuilderHelper<dynamic, dynamic, Arguments> helper, Token token, this.name)
      : super(helper, token);

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware});

  Arguments get arguments => null;

  @override
  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeRead", offsetForToken(token), uri);
  }

  @override
  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeWrite", offsetForToken(token), uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

class UnresolvedNameGenerator<Arguments> extends Generator<Arguments>
    with ErroneousExpressionGenerator<Arguments> {
  @override
  final Name name;

  UnresolvedNameGenerator(
      BuilderHelper<dynamic, dynamic, Arguments> helper, Token token, this.name)
      : super(helper, token);

  String get debugName => "UnresolvedNameGenerator";

  kernel.Expression doInvocation(int charOffset, Arguments arguments) {
    return buildError(arguments, offset: charOffset);
  }

  @override
  DartType buildErroneousTypeNotAPrefix(Identifier suffix) {
    helper.addProblem(
        templateUnresolvedPrefixInTypeAnnotation.withArguments(
            name.name, suffix.name),
        offsetForToken(token),
        lengthOfSpan(token, suffix.token));
    return const InvalidType();
  }

  @override
  kernel.Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    offset ??= offsetForToken(this.token);
    return helper.throwNoSuchMethodError(
        storeOffset(forest.literalNull(null), offset),
        plainNameForRead,
        arguments,
        offset,
        isGetter: isGetter,
        isSetter: isSetter);
  }

  @override
  kernel.Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeRead", offsetForToken(token), uri);
  }

  @override
  kernel.Expression _makeWrite(kernel.Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeWrite", offsetForToken(token), uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

// TODO(ahe): Rename to IncompleteErrorGenerator.
class IncompleteError<Arguments> extends IncompleteSendGenerator<Arguments>
    with ErroneousExpressionGenerator<Arguments> {
  final Message message;

  IncompleteError(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, this.message)
      : super(helper, token, null);

  String get debugName => "IncompleteError";

  @override
  kernel.Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    int length = noLength;
    if (offset == null) {
      offset = offsetForToken(token);
      length = lengthForToken(token);
    }
    return helper.buildCompileTimeError(message, offset, length);
  }

  @override
  DartType buildErroneousTypeNotAPrefix(Identifier suffix) {
    helper.addProblem(
        templateNotAPrefixInTypeAnnotation.withArguments(
            token.lexeme, suffix.name),
        offsetForToken(token),
        lengthOfSpan(token, suffix.token));
    return const InvalidType();
  }

  @override
  doInvocation(int offset, Arguments arguments) => this;

  @override
  void printOn(StringSink sink) {
    sink.write(", message: ");
    sink.write(message.code.name);
  }
}

// TODO(ahe): Rename to SendAccessGenerator.
class SendAccessor<Arguments> extends IncompleteSendGenerator<Arguments> {
  @override
  final Arguments arguments;

  SendAccessor(BuilderHelper<dynamic, dynamic, Arguments> helper, Token token,
      Name name, this.arguments)
      : super(helper, token, name) {
    assert(arguments != null);
  }

  String get plainNameForRead => name.name;

  String get debugName => "SendAccessor";

  kernel.Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", offsetForToken(token), uri);
  }

  kernel.Expression buildAssignment(kernel.Expression value,
      {bool voidContext: false}) {
    return unsupported("buildAssignment", offsetForToken(token), uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is Generator) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    if (receiver is PrefixBuilder) {
      PrefixBuilder prefix = receiver;
      if (isNullAware) {
        helper.deprecated_addCompileTimeError(
            offsetForToken(token),
            "Library prefix '${prefix.name}' can't be used with null-aware "
            "operator.\nTry removing '?'.");
      }
      receiver = helper.scopeLookup(prefix.exportScope, name.name, token,
          isQualified: true, prefix: prefix);
      return helper.finishSend(receiver, arguments, offsetForToken(token));
    }
    return helper.buildMethodInvocation(
        helper.toValue(receiver), name, arguments, offsetForToken(token),
        isNullAware: isNullAware);
  }

  kernel.Expression buildNullAwareAssignment(
      kernel.Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, uri);
  }

  kernel.Expression buildCompoundAssignment(
      Name binaryOperator, kernel.Expression value,
      {int offset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return unsupported(
        "buildCompoundAssignment", offset ?? offsetForToken(token), uri);
  }

  kernel.Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPrefixIncrement", offset ?? offsetForToken(token), uri);
  }

  kernel.Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPostfixIncrement", offset ?? offsetForToken(token), uri);
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, uri);
  }

  @override
  void printOn(StringSink sink) {
    super.printOn(sink);
    sink.write(", arguments: ");
    var node = arguments;
    if (node is kernel.Node) {
      printNodeOn(node, sink);
    } else {
      sink.write(node);
    }
  }
}

// TODO(ahe): Rename to IncompletePropertyAccessGenerator.
class IncompletePropertyAccessor<Arguments>
    extends IncompleteSendGenerator<Arguments> {
  IncompletePropertyAccessor(
      BuilderHelper<dynamic, dynamic, Arguments> helper, Token token, Name name)
      : super(helper, token, name);

  String get plainNameForRead => name.name;

  String get debugName => "IncompletePropertyAccessor";

  kernel.Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", offsetForToken(token), uri);
  }

  kernel.Expression buildAssignment(kernel.Expression value,
      {bool voidContext: false}) {
    return unsupported("buildAssignment", offsetForToken(token), uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is Generator) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    if (receiver is PrefixBuilder) {
      PrefixBuilder prefix = receiver;
      if (isNullAware) {
        helper.deprecated_addCompileTimeError(
            offsetForToken(token),
            "Library prefix '${prefix.name}' can't be used with null-aware "
            "operator.\nTry removing '?'.");
      }
      return helper.scopeLookup(prefix.exportScope, name.name, token,
          isQualified: true, prefix: prefix);
    }

    return PropertyAccessGenerator.make(
        helper, token, helper.toValue(receiver), name, null, null, isNullAware);
  }

  kernel.Expression buildNullAwareAssignment(
      kernel.Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, uri);
  }

  kernel.Expression buildCompoundAssignment(
      Name binaryOperator, kernel.Expression value,
      {int offset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return unsupported(
        "buildCompoundAssignment", offset ?? offsetForToken(token), uri);
  }

  kernel.Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPrefixIncrement", offset ?? offsetForToken(token), uri);
  }

  kernel.Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPostfixIncrement", offset ?? offsetForToken(token), uri);
  }

  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, uri);
  }
}

// TODO(ahe): Rename to ParenthesizedExpressionGenerator.
class ParenthesizedExpression<Arguments>
    extends ReadOnlyAccessGenerator<Arguments> {
  ParenthesizedExpression(BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token, kernel.Expression expression)
      : super(helper, token, expression, null);

  String get debugName => "ParenthesizedExpression";

  kernel.Expression makeInvalidWrite(kernel.Expression value) {
    return helper.deprecated_buildCompileTimeError(
        "Can't assign to a parenthesized expression.", offsetForToken(token));
  }
}

// TODO(ahe): Rename to TypeDeclarationAccessGenerator.
class TypeDeclarationAccessor<Arguments>
    extends ReadOnlyAccessGenerator<Arguments> {
  /// The import prefix preceding the [declaration] reference, or `null` if
  /// the reference is not prefixed.
  final PrefixBuilder prefix;

  /// The offset at which the [declaration] is referenced by this generator,
  /// or `-1` if the reference is implicit.
  final int declarationReferenceOffset;

  final TypeDeclarationBuilder declaration;

  TypeDeclarationAccessor(
      BuilderHelper<dynamic, dynamic, Arguments> helper,
      Token token,
      this.prefix,
      this.declarationReferenceOffset,
      this.declaration,
      String plainNameForRead)
      : super(helper, token, null, plainNameForRead);

  String get debugName => "TypeDeclarationAccessor";

  kernel.Expression get expression {
    if (super.expression == null) {
      int offset = offsetForToken(token);
      if (declaration is KernelInvalidTypeBuilder) {
        KernelInvalidTypeBuilder declaration = this.declaration;
        helper.addProblemErrorIfConst(
            declaration.message.messageObject, offset, token.length);
        super.expression =
            new Throw(forest.literalString(declaration.message.message, token))
              ..fileOffset = offset;
      } else {
        super.expression = forest.literalType(
            buildTypeWithBuiltArguments(null, nonInstanceAccessIsError: true),
            token);
      }
    }
    return super.expression;
  }

  kernel.Expression makeInvalidWrite(kernel.Expression value) {
    return buildThrowNoSuchMethodError(
        forest.literalNull(token),
        storeOffset(forest.arguments(<kernel.Expression>[value], null),
            value.fileOffset),
        isSetter: true);
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    // `SomeType?.toString` is the same as `SomeType.toString`, not
    // `(SomeType).toString`.
    isNullAware = false;

    Name name = send.name;
    Arguments arguments = send.arguments;

    if (declaration is KernelClassBuilder) {
      KernelClassBuilder declaration = this.declaration;
      Builder builder = declaration.findStaticBuilder(
          name.name, offsetForToken(token), uri, helper.library);

      Generator generator;
      if (builder == null) {
        // If we find a setter, [builder] is an [AccessErrorBuilder], not null.
        if (send is IncompletePropertyAccessor) {
          generator = new UnresolvedNameGenerator(helper, send.token, name);
        } else {
          return helper.buildConstructorInvocation(declaration, send.token,
              arguments, name.name, null, token.charOffset, Constness.implicit);
        }
      } else {
        Builder setter;
        if (builder.isSetter) {
          setter = builder;
        } else if (builder.isGetter) {
          setter = declaration.findStaticBuilder(
              name.name, offsetForToken(token), uri, helper.library,
              isSetter: true);
        } else if (builder.isField && !builder.isFinal) {
          setter = builder;
        }
        generator = new StaticAccessGenerator.fromBuilder(
            helper, builder, send.token, setter);
      }

      return arguments == null
          ? generator
          : generator.doInvocation(offsetForToken(send.token), arguments);
    } else {
      return super.buildPropertyAccess(send, operatorOffset, isNullAware);
    }
  }

  @override
  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false}) {
    if (arguments != null) {
      int expected = 0;
      if (declaration is KernelClassBuilder) {
        expected = declaration.target.typeParameters.length;
      } else if (declaration is FunctionTypeAliasBuilder) {
        expected = declaration.target.typeParameters.length;
      } else if (declaration is KernelTypeVariableBuilder) {
        // Type arguments on a type variable - error reported elsewhere.
      } else if (declaration is BuiltinTypeBuilder) {
        // Type arguments on a built-in type, for example, dynamic or void.
        expected = 0;
      } else {
        return unhandled(
            "${declaration.runtimeType}",
            "TypeDeclarationAccessor.buildType",
            offsetForToken(token),
            helper.uri);
      }
      if (arguments.length != expected) {
        helper.warnTypeArgumentsMismatch(
            declaration.name, expected, offsetForToken(token));
        // We ignore the provided arguments, which will in turn return the
        // raw type below.
        // TODO(sigmund): change to use an InvalidType and include the raw type
        // as a recovery node once the IR can represent it (Issue #29840).
        arguments = null;
      }
    }

    DartType type;
    if (arguments == null) {
      TypeDeclarationBuilder typeDeclaration = declaration;
      if (typeDeclaration is KernelClassBuilder) {
        type = typeDeclaration.buildType(helper.library, null);
      } else if (typeDeclaration is KernelFunctionTypeAliasBuilder) {
        type = typeDeclaration.buildType(helper.library, null);
      }
    }
    if (type == null) {
      type =
          declaration.buildTypesWithBuiltArguments(helper.library, arguments);
    }
    if (type is TypeParameterType) {
      return helper.validatedTypeVariableUse(
          type, offsetForToken(token), nonInstanceAccessIsError);
    }
    return type;
  }

  @override
  kernel.Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildConstructorInvocation(declaration, token, arguments, "",
        null, token.charOffset, Constness.implicit);
  }
}

kernel.Expression makeLet(
    VariableDeclaration variable, kernel.Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

kernel.Expression makeBinary<Arguments>(
    kernel.Expression left,
    Name operator,
    Procedure interfaceTarget,
    kernel.Expression right,
    BuilderHelper<dynamic, dynamic, Arguments> helper,
    {int offset: TreeNode.noOffset}) {
  return new ShadowMethodInvocation(
      left,
      operator,
      helper.storeOffset(
          helper.forest.castArguments(
              helper.forest.arguments(<kernel.Expression>[right], null)),
          offset),
      interfaceTarget: interfaceTarget)
    ..fileOffset = offset;
}

kernel.Expression buildIsNull<Arguments>(kernel.Expression value, int offset,
    BuilderHelper<dynamic, dynamic, Arguments> helper) {
  return makeBinary(value, equalsName, null,
      helper.storeOffset(helper.forest.literalNull(null), offset), helper,
      offset: offset);
}

VariableDeclaration makeOrReuseVariable(kernel.Expression value) {
  // TODO: Devise a way to remember if a variable declaration was reused
  // or is fresh (hence needs a let binding).
  return new VariableDeclaration.forValue(value);
}

int adjustForImplicitCall(String name, int offset) {
  // Normally the offset is at the start of the token, but in this case,
  // because we insert a '.call', we want it at the end instead.
  return offset + (name?.length ?? 0);
}

bool isFieldOrGetter(Member member) {
  return member is Field || (member is Procedure && member.isGetter);
}
