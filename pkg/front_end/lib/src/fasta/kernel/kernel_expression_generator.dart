// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show Arguments, DynamicType, Expression, InvalidExpression, Node;

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart'
    show
        Message,
        LocatedMessage,
        messageCannotAssignToSuper,
        messageLoadLibraryTakesNoArguments,
        messageNotAConstantExpression,
        messageNotAnLvalue,
        messageCannotAssignToParenthesizedExpression,
        templateNotConstantExpression,
        messageSuperAsExpression,
        templateThisOrSuperAccessInFieldInitializer,
        messageInvalidUseOfNullAwareAccess;

import '../messages.dart' show Message, noLength;

import '../names.dart' show callName, equalsName, indexGetName, indexSetName;

import '../parser.dart' show lengthForToken, offsetForToken;

import '../problems.dart' show unhandled, unsupported;

import '../type_inference/type_inferrer.dart' show TypeInferrer;

import 'body_builder.dart' show noLocation;

import 'constness.dart' show Constness;

import 'expression_generator.dart'
    show
        ContextAwareGenerator,
        DeferredAccessGenerator,
        DelayedAssignment,
        DelayedPostfixIncrement,
        ErroneousExpressionGenerator,
        ExpressionGenerator,
        Generator,
        IndexedAccessGenerator,
        LargeIntAccessGenerator,
        LoadLibraryGenerator,
        NullAwarePropertyAccessGenerator,
        PrefixUseGenerator,
        PropertyAccessGenerator,
        ReadOnlyAccessGenerator,
        StaticAccessGenerator,
        SuperIndexedAccessGenerator,
        SuperPropertyAccessGenerator,
        ThisIndexedAccessGenerator,
        ThisPropertyAccessGenerator,
        TypeUseGenerator,
        UnexpectedQualifiedUseGenerator,
        UnlinkedGenerator,
        UnresolvedNameGenerator,
        VariableUseGenerator;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'forest.dart' show Forest;

import 'kernel_builder.dart'
    show LoadLibraryBuilder, PrefixBuilder, UnlinkedDeclaration;

import 'kernel_api.dart' show NameSystem, printNodeOn, printQualifiedNameOn;

import 'kernel_ast_api.dart'
    show
        ArgumentsJudgment,
        ComplexAssignmentJudgment,
        Constructor,
        DartType,
        Field,
        IllegalAssignmentJudgment,
        IndexAssignmentJudgment,
        Initializer,
        InvalidPropertyGetJudgment,
        InvalidType,
        InvalidVariableWriteJudgment,
        InvalidWriteJudgment,
        Let,
        LoadLibraryTearOffJudgment,
        Member,
        MethodInvocationJudgment,
        Name,
        NullAwarePropertyGetJudgment,
        Procedure,
        PropertyAssignmentJudgment,
        PropertyGetJudgment,
        PropertySet,
        StaticAssignmentJudgment,
        StaticSet,
        SuperMethodInvocation,
        SuperMethodInvocationJudgment,
        SuperPropertyGetJudgment,
        SuperPropertySet,
        SyntheticExpressionJudgment,
        Throw,
        TreeNode,
        TypeParameter,
        UnresolvedVariableAssignmentJudgment,
        UnresolvedVariableGetJudgment,
        VariableAssignmentJudgment,
        VariableDeclaration,
        VariableDeclarationJudgment,
        VariableGet,
        VariableGetJudgment,
        VariableSet;

import 'kernel_builder.dart'
    show
        Declaration,
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder;

part 'kernel_expression_generator_impl.dart';

abstract class KernelExpressionGenerator implements ExpressionGenerator {
  ExpressionGeneratorHelper get helper;

  Token get token;

  Forest get forest;

  String get plainNameForRead;

  @override
  Expression buildSimpleRead() {
    return _finish(_makeSimpleRead(), null);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    var complexAssignment = startComplexAssignment(value);
    return _finish(_makeSimpleWrite(value, voidContext, complexAssignment),
        complexAssignment);
  }

  @override
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    var complexAssignment = startComplexAssignment(value);
    if (voidContext) {
      var nullAwareCombiner = forest.conditionalExpression(
          buildIsNull(_makeRead(complexAssignment), offset, helper),
          null,
          _makeWrite(value, false, complexAssignment),
          null,
          forest.literalNull(null)..fileOffset = offset)
        ..fileOffset = offset;
      complexAssignment?.nullAwareCombiner = nullAwareCombiner;
      return _finish(nullAwareCombiner, complexAssignment);
    }
    var tmp = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    var nullAwareCombiner = forest.conditionalExpression(
        buildIsNull(new VariableGet(tmp), offset, helper),
        null,
        _makeWrite(value, false, complexAssignment),
        null,
        new VariableGet(tmp))
      ..fileOffset = offset;
    complexAssignment?.nullAwareCombiner = nullAwareCombiner;
    return _finish(makeLet(tmp, nullAwareCombiner), complexAssignment);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    var complexAssignment = startComplexAssignment(value);
    complexAssignment?.isPreIncDec = isPreIncDec;
    complexAssignment?.isPostIncDec = isPostIncDec;
    var combiner = makeBinary(_makeRead(complexAssignment), binaryOperator,
        interfaceTarget, value, helper,
        offset: offset);
    complexAssignment?.combiner = combiner;
    return _finish(_makeWrite(combiner, voidContext, complexAssignment),
        complexAssignment);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildCompoundAssignment(
        binaryOperator, forest.literalInt(1, null)..fileOffset = offset,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPreIncDec: true);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    if (voidContext) {
      return buildCompoundAssignment(
          binaryOperator, forest.literalInt(1, null)..fileOffset = offset,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    var rhs = forest.literalInt(1, null)..fileOffset = offset;
    var complexAssignment = startComplexAssignment(rhs);
    var value = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    valueAccess() => new VariableGet(value);
    var combiner = makeBinary(
        valueAccess(), binaryOperator, interfaceTarget, rhs, helper,
        offset: offset);
    complexAssignment?.combiner = combiner;
    complexAssignment?.isPostIncDec = true;
    var dummy = new VariableDeclarationJudgment.forValue(
        _makeWrite(combiner, true, complexAssignment),
        helper.functionNestingLevel);
    return _finish(
        makeLet(value, makeLet(dummy, valueAccess())), complexAssignment);
  }

  @override
  Expression makeInvalidRead() {
    return new SyntheticExpressionJudgment(helper.throwNoSuchMethodError(
        forest.literalNull(token),
        plainNameForRead,
        forest.argumentsEmpty(noLocation, noLocation),
        offsetForToken(token),
        isGetter: true));
  }

  @override
  Expression makeInvalidWrite(Expression value) {
    return buildInvalidWriteJudgment(helper.throwNoSuchMethodError(
        forest.literalNull(token),
        plainNameForRead,
        forest.arguments(<Expression>[value], noLocation, noLocation),
        offsetForToken(token),
        isSetter: true));
  }

  Expression buildInvalidWriteJudgment(Expression desugared) {
    return new SyntheticExpressionJudgment(desugared);
  }

  Expression _makeSimpleRead() => _makeRead(null);

  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    return _makeWrite(value, voidContext, complexAssignment);
  }

  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    Expression read = makeInvalidRead();
    complexAssignment?.read = read;
    return read;
  }

  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    Expression write = makeInvalidWrite(value);
    complexAssignment?.write = write;
    return write;
  }

  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    if (complexAssignment != null) {
      complexAssignment.desugared = body;
      return complexAssignment;
    } else {
      return body;
    }
  }

  /// Creates a data structure for tracking the desugaring of a complex
  /// assignment expression whose right hand side is [rhs].
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new IllegalAssignmentJudgment(rhs);
}

abstract class KernelGenerator = Generator with KernelExpressionGenerator;

class KernelVariableUseGenerator extends KernelGenerator
    with VariableUseGenerator {
  final VariableDeclaration variable;

  final DartType promotedType;

  KernelVariableUseGenerator(ExpressionGeneratorHelper helper, Token token,
      this.variable, this.promotedType)
      : super(helper, token);

  @override
  String get plainNameForRead => variable.name;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var fact = helper.typePromoter
        .getFactForAccess(variable, helper.functionNestingLevel);
    var scope = helper.typePromoter.currentScope;
    var read = new VariableGetJudgment(variable, fact, scope)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    helper.typePromoter.mutateVariable(variable, helper.functionNestingLevel);
    var write = variable.isFinal || variable.isConst
        ? makeInvalidWrite(value)
        : new VariableSet(variable, value)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(plainNameForRead, offset),
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new VariableAssignmentJudgment(rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", variable: ");
    printNodeOn(variable, sink, syntheticNames: syntheticNames);
    sink.write(", promotedType: ");
    printNodeOn(promotedType, sink, syntheticNames: syntheticNames);
  }
}

class KernelPropertyAccessGenerator extends KernelGenerator
    with PropertyAccessGenerator {
  final Expression receiver;

  final Name name;

  final Member getter;

  final Member setter;

  VariableDeclaration _receiverVariable;

  KernelPropertyAccessGenerator.internal(ExpressionGeneratorHelper helper,
      Token token, this.receiver, this.name, this.getter, this.setter)
      : super(helper, token);

  @override
  String get plainNameForRead => name.name;

  receiverAccess() {
    _receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(_receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(receiver, name, arguments, offset);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new PropertyAssignmentJudgment(receiver, rhs);

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

  @override
  Expression _makeSimpleRead() => new PropertyGetJudgment(receiver, name,
      interfaceTarget: getter, forSyntheticToken: token.isSynthetic)
    ..fileOffset = offsetForToken(token);

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    var write = new PropertySet(receiver, name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read =
        new PropertyGetJudgment(receiverAccess(), name, interfaceTarget: getter)
          ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    return super._finish(makeLet(_receiverVariable, body), complexAssignment);
  }
}

class KernelThisPropertyAccessGenerator extends KernelGenerator
    with ThisPropertyAccessGenerator {
  final Name name;

  final Member getter;

  final Member setter;

  KernelThisPropertyAccessGenerator(ExpressionGeneratorHelper helper,
      Token token, this.name, this.getter, this.setter)
      : super(helper, token);

  @override
  String get plainNameForRead => name.name;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedGet(name, offsetForToken(token));
    }
    var read = new PropertyGetJudgment(forest.thisExpression(token), name,
        interfaceTarget: getter, forSyntheticToken: token.isSynthetic)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (setter == null) {
      helper.warnUnresolvedSet(name, offsetForToken(token));
    }
    var write =
        new PropertySet(forest.thisExpression(token), name, value, setter)
          ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
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
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new PropertyAssignmentJudgment(null, rhs);

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

class KernelNullAwarePropertyAccessGenerator extends KernelGenerator
    with NullAwarePropertyAccessGenerator {
  final VariableDeclaration receiver;

  final Expression receiverExpression;

  final Name name;

  final Member getter;

  final Member setter;

  final DartType type;

  KernelNullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      this.receiverExpression,
      this.name,
      this.getter,
      this.setter,
      this.type)
      : this.receiver = makeOrReuseVariable(receiverExpression),
        super(helper, token);

  Expression receiverAccess() => new VariableGet(receiver);

  @override
  String get plainNameForRead => name.name;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read =
        new PropertyGetJudgment(receiverAccess(), name, interfaceTarget: getter)
          ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    var offset = offsetForToken(token);
    var nullAwareGuard = forest.conditionalExpression(
        buildIsNull(receiverAccess(), offset, helper),
        null,
        forest.literalNull(null)..fileOffset = offset,
        null,
        body)
      ..fileOffset = offset;
    if (complexAssignment != null) {
      body = makeLet(receiver, nullAwareGuard);
      PropertyAssignmentJudgment kernelPropertyAssign = complexAssignment;
      kernelPropertyAssign.nullAwareGuard = nullAwareGuard;
      kernelPropertyAssign.desugared = body;
      return kernelPropertyAssign;
    } else {
      return new NullAwarePropertyGetJudgment(receiver, nullAwareGuard)
        ..fileOffset = offset;
    }
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, uri);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new PropertyAssignmentJudgment(receiverExpression, rhs);

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

class KernelSuperPropertyAccessGenerator extends KernelGenerator
    with SuperPropertyAccessGenerator {
  final Name name;

  final Member getter;

  final Member setter;

  KernelSuperPropertyAccessGenerator(ExpressionGeneratorHelper helper,
      Token token, this.name, this.getter, this.setter)
      : super(helper, token);

  @override
  String get plainNameForRead => name.name;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedGet(name, offsetForToken(token), isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertyGet] when possible.
    var read = new SuperPropertyGetJudgment(name, interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (setter == null) {
      helper.warnUnresolvedSet(name, offsetForToken(token), isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertySet] when possible.
    var write = new SuperPropertySet(name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    if (helper.constantContext != ConstantContext.none) {
      // TODO(brianwilkerson) Fix the length
      helper.addCompileTimeError(messageNotAConstantExpression, offset, 1);
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
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new PropertyAssignmentJudgment(null, rhs, isSuper: true);

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

class KernelIndexedAccessGenerator extends KernelGenerator
    with IndexedAccessGenerator {
  final Token openSquareBracket;

  final Token closeSquareBracket;

  final Expression receiver;

  final Expression index;

  final Procedure getter;

  final Procedure setter;

  VariableDeclaration receiverVariable;

  VariableDeclaration indexVariable;

  KernelIndexedAccessGenerator.internal(
      ExpressionGeneratorHelper helper,
      this.openSquareBracket,
      this.closeSquareBracket,
      this.receiver,
      this.index,
      this.getter,
      this.setter)
      : super(helper, openSquareBracket);

  Expression indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable)..fileOffset = offsetForToken(token);
  }

  Expression receiverAccess() {
    // We cannot reuse the receiver if it is a variable since it might be
    // reassigned in the index expression.
    receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression _makeSimpleRead() {
    var read = new MethodInvocationJudgment(
        receiver,
        indexGetName,
        forest.castArguments(forest.arguments(
            <Expression>[index], openSquareBracket, closeSquareBracket)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    return read;
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        receiver,
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[index, value], openSquareBracket, closeSquareBracket)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read = new MethodInvocationJudgment(
        receiverAccess(),
        indexGetName,
        forest.castArguments(forest.arguments(<Expression>[indexAccess()],
            openSquareBracket, closeSquareBracket)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        receiverAccess(),
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), value],
            openSquareBracket,
            closeSquareBracket)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  // TODO(dmitryas): remove this method after the "[]=" operator of the Context
  // class is made to return a value.
  Expression _makeWriteAndReturn(
      Expression value, ComplexAssignmentJudgment complexAssignment) {
    // The call to []= does not return the value like direct-style assignments
    // do.  We need to bind the value in a let.
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new MethodInvocationJudgment(
        receiverAccess(),
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            openSquareBracket,
            closeSquareBracket)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclarationJudgment.forValue(
        write, helper.functionNestingLevel);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    int offset = offsetForToken(token);
    return super._finish(
        makeLet(
            receiverVariable, makeLet(indexVariable, body)..fileOffset = offset)
          ..fileOffset = offset,
        complexAssignment);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, forest.readOffset(arguments),
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new IndexAssignmentJudgment(receiver, index, rhs);

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

class KernelThisIndexedAccessGenerator extends KernelGenerator
    with ThisIndexedAccessGenerator {
  final Token openSquareBracket;

  final Token closeSquareBracket;

  final Expression index;

  final Procedure getter;

  final Procedure setter;

  VariableDeclaration indexVariable;

  KernelThisIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      this.openSquareBracket,
      this.closeSquareBracket,
      this.index,
      this.getter,
      this.setter)
      : super(helper, openSquareBracket);

  Expression indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeWriteAndReturn(
      Expression value, ComplexAssignmentJudgment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new MethodInvocationJudgment(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            openSquareBracket,
            closeSquareBracket)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  @override
  Expression _makeSimpleRead() {
    return new MethodInvocationJudgment(
        forest.thisExpression(token),
        indexGetName,
        forest.castArguments(forest.arguments(
            <Expression>[index], openSquareBracket, closeSquareBracket)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[index, value], openSquareBracket, closeSquareBracket)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read = new MethodInvocationJudgment(
        forest.thisExpression(token),
        indexGetName,
        forest.castArguments(forest.arguments(<Expression>[indexAccess()],
            openSquareBracket, closeSquareBracket)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        forest.thisExpression(token),
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), value],
            openSquareBracket,
            closeSquareBracket)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    return super._finish(makeLet(indexVariable, body), complexAssignment);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new IndexAssignmentJudgment(null, index, rhs);

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

class KernelSuperIndexedAccessGenerator extends KernelGenerator
    with SuperIndexedAccessGenerator {
  final Token openSquareBracket;

  final Token closeSquareBracket;

  final Expression index;

  final Member getter;

  final Member setter;

  VariableDeclaration indexVariable;

  KernelSuperIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      this.openSquareBracket,
      this.closeSquareBracket,
      this.index,
      this.getter,
      this.setter)
      : super(helper, openSquareBracket);

  Expression indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeWriteAndReturn(
      Expression value, ComplexAssignmentJudgment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            openSquareBracket,
            closeSquareBracket)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  @override
  Expression _makeSimpleRead() {
    if (getter == null) {
      helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    // TODO(ahe): Use [DirectMethodInvocation] when possible.
    return new SuperMethodInvocationJudgment(
        indexGetName,
        forest.castArguments(forest.arguments(
            <Expression>[index], openSquareBracket, closeSquareBracket)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[index, value], openSquareBracket, closeSquareBracket)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    if (getter == null) {
      helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    var read = new SuperMethodInvocation(
        indexGetName,
        forest.castArguments(forest.arguments(<Expression>[indexAccess()],
            openSquareBracket, closeSquareBracket)),
        getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        forest.castArguments(forest.arguments(
            <Expression>[indexAccess(), value],
            openSquareBracket,
            closeSquareBracket)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    return super._finish(
        makeLet(indexVariable, body)..fileOffset = offsetForToken(token),
        complexAssignment);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new IndexAssignmentJudgment(null, index, rhs, isSuper: true);

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

class KernelStaticAccessGenerator extends KernelGenerator
    with StaticAccessGenerator {
  @override
  final Member readTarget;

  final Member writeTarget;

  KernelStaticAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.readTarget, this.writeTarget)
      : assert(readTarget != null || writeTarget != null),
        super(helper, token);

  @override
  Node get fieldInitializerTarget => readTarget;

  @override
  String get plainNameForRead => (readTarget ?? writeTarget).name.name;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    if (readTarget == null) {
      return makeInvalidRead();
    } else {
      var read = helper.makeStaticGet(readTarget, token);
      complexAssignment?.read = read;
      return read;
    }
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    Expression write;
    if (writeTarget == null) {
      write = makeInvalidWrite(value);
    } else {
      write = new StaticSet(writeTarget, value);
    }
    complexAssignment?.write = write;
    write.fileOffset = offsetForToken(token);
    return write;
  }

  @override
  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false, TypeInferrer typeInferrer}) {
    var offset = offsetForToken(token);
    typeInferrer.storeTypeReference(
        offset, token.isSynthetic, readTarget, null, const DynamicType());
    return super.buildTypeWithBuiltArguments(arguments,
        nonInstanceAccessIsError: nonInstanceAccessIsError,
        typeInferrer: typeInferrer);
  }

  @override
  Expression doInvocation(int offset, ArgumentsJudgment arguments) {
    Expression error;
    if (helper.constantContext != ConstantContext.none &&
        !helper.isIdentical(readTarget)) {
      error = helper.buildCompileTimeError(
          templateNotConstantExpression.withArguments('Method invocation'),
          offset,
          readTarget?.name?.name?.length ?? 0);
    }
    if (readTarget == null || isFieldOrGetter(readTarget)) {
      return helper.buildMethodInvocation(buildSimpleRead(), callName,
          arguments, offset + (readTarget?.name?.name?.length ?? 0),
          error: error,
          // This isn't a constant expression, but we have checked if a
          // constant expression error should be emitted already.
          isConstantExpression: true,
          isImplicitCall: true);
    } else {
      return helper.buildStaticInvocation(readTarget, arguments,
          charOffset: offset, error: error);
    }
  }

  @override
  void storeUnexpectedTypePrefix(TypeInferrer typeInferrer) {
    typeInferrer.storeTypeReference(offsetForToken(token), token.isSynthetic,
        readTarget, null, const DynamicType());
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new StaticAssignmentJudgment(rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink, syntheticNames: syntheticNames);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink, syntheticNames: syntheticNames);
  }
}

class KernelLoadLibraryGenerator extends KernelGenerator
    with LoadLibraryGenerator {
  final LoadLibraryBuilder builder;

  KernelLoadLibraryGenerator(
      ExpressionGeneratorHelper helper, Token token, this.builder)
      : super(helper, token);

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    builder.importDependency.targetLibrary;
    var read = new LoadLibraryTearOffJudgment(
        builder.importDependency, builder.createTearoffMethod(helper.forest))
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    if (forest.argumentsPositional(arguments).length > 0 ||
        forest.argumentsNamed(arguments).length > 0) {
      helper.addProblemErrorIfConst(
          messageLoadLibraryTakesNoArguments, offset, 'loadLibrary'.length);
    }
    return builder.createLoadLibrary(offset, forest, arguments);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", builder: ");
    sink.write(builder);
  }
}

class KernelDeferredAccessGenerator extends KernelGenerator
    with DeferredAccessGenerator {
  @override
  final KernelPrefixUseGenerator prefixGenerator;

  @override
  final KernelGenerator suffixGenerator;

  KernelDeferredAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.prefixGenerator, this.suffixGenerator)
      : super(helper, token);

  @override
  Expression _makeSimpleRead() {
    return helper.wrapInDeferredCheck(suffixGenerator._makeSimpleRead(),
        prefixGenerator.prefix, token.charOffset);
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    return helper.wrapInDeferredCheck(
        suffixGenerator._makeRead(complexAssignment),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    return helper.wrapInDeferredCheck(
        suffixGenerator._makeWrite(value, voidContext, complexAssignment),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      new StaticAssignmentJudgment(rhs);
}

class KernelTypeUseGenerator extends KernelReadOnlyAccessGenerator
    with TypeUseGenerator {
  @override
  final TypeDeclarationBuilder declaration;

  KernelTypeUseGenerator(ExpressionGeneratorHelper helper, Token token,
      this.declaration, String plainNameForRead)
      : super(helper, token, null, plainNameForRead);

  @override
  Expression get expression {
    if (super.expression == null) {
      super.expression = computeExpression();
    }
    return super.expression;
  }

  Expression computeExpression({bool silent: false}) {
    int offset = offsetForToken(token);
    if (declaration is KernelInvalidTypeBuilder) {
      KernelInvalidTypeBuilder declaration = this.declaration;
      if (!silent) {
        helper.addProblemErrorIfConst(
            declaration.message.messageObject, offset, token.length);
      }
      return new SyntheticExpressionJudgment(
          new Throw(forest.literalString(declaration.message.message, token))
            ..fileOffset = offset);
    } else {
      return forest.literalType(
          buildTypeWithBuiltArguments(null, nonInstanceAccessIsError: true),
          token);
    }
  }

  @override
  Node get fieldInitializerTarget =>
      declaration.hasTarget ? declaration.target : null;

  @override
  Expression makeInvalidWrite(Expression value) {
    var read = computeExpression(silent: true);
    // The read needs to have a parent so that type inference can be applied to
    // it, but it doesn't mater what the parent is because the final read won't
    // appear in the tree.  So just give it a quick and dirty parent.
    new VariableDeclaration.forValue(read);

    var throwExpr = helper.throwNoSuchMethodError(
        forest.literalNull(token),
        plainNameForRead,
        forest.arguments(<Expression>[value], noLocation, noLocation)
          ..fileOffset = value.fileOffset,
        offsetForToken(token),
        isSetter: true);
    return new SyntheticExpressionJudgment(throwExpr, original: read);
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    helper.storeTypeUse(offsetForToken(token), declaration.target);

    // `SomeType?.toString` is the same as `SomeType.toString`, not
    // `(SomeType).toString`.
    isNullAware = false;

    Name name = send.name;
    Arguments arguments = send.arguments;

    if (declaration is KernelClassBuilder) {
      KernelClassBuilder declaration = this.declaration;
      Declaration member = declaration.findStaticBuilder(
          name.name, offsetForToken(token), uri, helper.library);

      Generator generator;
      if (member == null) {
        // If we find a setter, [member] is an [AccessErrorBuilder], not null.
        if (send is IncompletePropertyAccessGenerator) {
          generator = new UnresolvedNameGenerator(helper, send.token, name);
        } else {
          return helper.buildConstructorInvocation(
              declaration,
              send.token,
              send.token,
              arguments,
              name.name,
              null,
              token.charOffset,
              Constness.implicit);
        }
      } else {
        Declaration setter;
        if (member.isSetter) {
          setter = member;
        } else if (member.isGetter) {
          setter = declaration.findStaticBuilder(
              name.name, offsetForToken(token), uri, helper.library,
              isSetter: true);
        } else if (member.isField && !member.isFinal) {
          setter = member;
        }
        generator = new StaticAccessGenerator.fromBuilder(
            helper, member, send.token, setter);
      }

      return arguments == null
          ? generator
          : generator.doInvocation(offsetForToken(send.token), arguments);
    } else {
      return super.buildPropertyAccess(send, operatorOffset, isNullAware);
    }
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildConstructorInvocation(declaration, token, token,
        arguments, "", null, token.charOffset, Constness.implicit);
  }
}

class KernelReadOnlyAccessGenerator extends KernelGenerator
    with ReadOnlyAccessGenerator {
  @override
  final String plainNameForRead;

  Expression expression;

  VariableDeclaration value;

  KernelReadOnlyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.expression, this.plainNameForRead)
      : super(helper, token);

  @override
  Expression _makeSimpleRead() => expression;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    value ??= new VariableDeclaration.forValue(expression);
    return new VariableGet(value);
  }

  @override
  Expression _finish(
          Expression body, ComplexAssignmentJudgment complexAssignment) =>
      super._finish(makeLet(value, body), complexAssignment);

  @override
  Expression buildInvalidWriteJudgment(Expression desugared) {
    var expression = this.expression;
    if (expression is VariableGet) {
      return new InvalidVariableWriteJudgment(desugared, expression.variable)
        ..fileOffset = token.charOffset;
    } else {
      // TODO(paulberry): handle other cases
      return super.buildInvalidWriteJudgment(desugared);
    }
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
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

class KernelLargeIntAccessGenerator extends KernelGenerator
    with LargeIntAccessGenerator {
  KernelLargeIntAccessGenerator(ExpressionGeneratorHelper helper, Token token)
      : super(helper, token);

  @override
  Expression _makeSimpleRead() {
    return _buildErrorIntLiteral();
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    return _buildErrorIntLiteral();
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    return _buildErrorIntLiteral();
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    return _buildErrorIntLiteral();
  }

  Expression _buildErrorIntLiteral() {
    var error = buildError();
    return forest.literalInt(0, token, desugaredError: error);
  }
}

class KernelUnresolvedNameGenerator extends KernelGenerator
    with ErroneousExpressionGenerator, UnresolvedNameGenerator {
  @override
  final Name name;

  KernelUnresolvedNameGenerator(
      ExpressionGeneratorHelper helper, Token token, this.name)
      : super(helper, token);

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _buildUnresolvedVariableAssignment(false, value);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _buildUnresolvedVariableAssignment(true, value);
  }

  @override
  Expression buildSimpleRead() {
    Expression error =
        buildError(forest.argumentsEmpty(token, token), isGetter: true);
    return new UnresolvedVariableGetJudgment(error, token.isSynthetic)
      ..fileOffset = token.charOffset;
  }

  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false, TypeInferrer typeInferrer}) {
    var type = super.buildTypeWithBuiltArguments(arguments,
        nonInstanceAccessIsError: nonInstanceAccessIsError,
        typeInferrer: typeInferrer);
    typeInferrer.storeTypeReference(
        token.offset, token.isSynthetic, null, null, type);
    return type;
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }

  UnresolvedVariableAssignmentJudgment _buildUnresolvedVariableAssignment(
      bool isCompound, Expression value) {
    return new UnresolvedVariableAssignmentJudgment(
      buildError(forest.arguments(<Expression>[value], token, token),
          isSetter: true),
      isCompound,
      value,
    )..fileOffset = token.charOffset;
  }
}

class KernelUnlinkedGenerator extends KernelGenerator with UnlinkedGenerator {
  @override
  final UnlinkedDeclaration declaration;

  final Expression receiver;

  final Name name;

  KernelUnlinkedGenerator(
      ExpressionGeneratorHelper helper, Token token, this.declaration)
      : name = new Name(declaration.name, helper.library.target),
        receiver = new InvalidExpression(declaration.name)
          ..fileOffset = offsetForToken(token),
        super(helper, token);

  @override
  Expression buildAssignment(Expression value, {bool voidContext}) {
    return new PropertySet(receiver, name, value)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression buildSimpleRead() {
    return new PropertyGetJudgment(receiver, name)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, uri);
  }
}

abstract class KernelContextAwareGenerator extends KernelGenerator
    with ContextAwareGenerator {
  @override
  final Generator generator;

  KernelContextAwareGenerator(
      ExpressionGeneratorHelper helper, Token token, this.generator)
      : super(helper, token);
}

class KernelDelayedAssignment extends KernelContextAwareGenerator
    with DelayedAssignment {
  @override
  final Expression value;

  @override
  String assignmentOperator;

  KernelDelayedAssignment(ExpressionGeneratorHelper helper, Token token,
      Generator generator, this.value, this.assignmentOperator)
      : super(helper, token, generator);

  @override
  void printOn(StringSink sink) {
    sink.write(", value: ");
    printNodeOn(value, sink);
    sink.write(", assignmentOperator: ");
    sink.write(assignmentOperator);
  }
}

class KernelDelayedPostfixIncrement extends KernelContextAwareGenerator
    with DelayedPostfixIncrement {
  @override
  final Name binaryOperator;

  @override
  final Procedure interfaceTarget;

  KernelDelayedPostfixIncrement(ExpressionGeneratorHelper helper, Token token,
      Generator generator, this.binaryOperator, this.interfaceTarget)
      : super(helper, token, generator);
}

class KernelPrefixUseGenerator extends KernelGenerator with PrefixUseGenerator {
  final PrefixBuilder prefix;

  KernelPrefixUseGenerator(
      ExpressionGeneratorHelper helper, Token token, this.prefix)
      : super(helper, token);
}

class KernelUnexpectedQualifiedUseGenerator extends KernelGenerator
    with UnexpectedQualifiedUseGenerator {
  @override
  final KernelGenerator prefixGenerator;

  @override
  final bool isUnresolved;

  KernelUnexpectedQualifiedUseGenerator(ExpressionGeneratorHelper helper,
      Token token, this.prefixGenerator, this.isUnresolved)
      : super(helper, token);

  Expression invokeConstructor(
      List<DartType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameStringToken,
      Constness constness) {
    helper.storeTypeUse(offsetForToken(token), const InvalidType());
    return super.invokeConstructor(
        typeArguments, name, arguments, nameToken, nameStringToken, constness);
  }
}

Expression makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression makeBinary(Expression left, Name operator, Procedure interfaceTarget,
    Expression right, ExpressionGeneratorHelper helper,
    {int offset: TreeNode.noOffset}) {
  return new MethodInvocationJudgment(
      left,
      operator,
      helper.forest.castArguments(
          helper.forest.arguments(<Expression>[right], noLocation, noLocation))
        ..fileOffset = offset,
      interfaceTarget: interfaceTarget)
    ..fileOffset = offset;
}

Expression buildIsNull(
    Expression value, int offset, ExpressionGeneratorHelper helper) {
  return makeBinary(value, equalsName, null,
      helper.forest.literalNull(null)..fileOffset = offset, helper,
      offset: offset);
}

VariableDeclaration makeOrReuseVariable(Expression value) {
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
