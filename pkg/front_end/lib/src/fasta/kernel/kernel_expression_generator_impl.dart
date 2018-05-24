// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// All classes in this file are temporary. Each class should be split in two:
///
/// 1. A common superclass.
/// 2. A kernel-specific implementation class.
///
/// The common superclass should keep the name of the class and be moved to
/// [expression_generator.dart]. The kernel-specific class should be moved to
/// [kernel_expression_generator.dart] and we can eventually delete this file.
///
/// Take a look at [VariableUseGenerator] for an example of how the common
/// superclass should use the forest API in a factory method.
part of 'kernel_expression_generator.dart';

class StaticAccessGenerator extends KernelGenerator {
  final Member readTarget;

  final Member writeTarget;

  StaticAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.readTarget,
      this.writeTarget)
      : assert(readTarget != null || writeTarget != null),
        super(helper, token);

  factory StaticAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
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

  Expression doInvocation(int offset, Arguments arguments) {
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
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
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

class LoadLibraryGenerator extends KernelGenerator {
  final LoadLibraryBuilder builder;

  LoadLibraryGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.builder)
      : super(helper, token);

  String get plainNameForRead => 'loadLibrary';

  String get debugName => "LoadLibraryGenerator";

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

  Expression doInvocation(int offset, Arguments arguments) {
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

class DeferredAccessGenerator extends KernelGenerator {
  final PrefixBuilder builder;

  final KernelGenerator generator;

  DeferredAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.builder,
      this.generator)
      : super(helper, token);

  String get plainNameForRead {
    return unsupported(
        "deferredAccessor.plainNameForRead", offsetForToken(token), uri);
  }

  String get debugName => "DeferredAccessGenerator";

  Expression _makeSimpleRead() {
    return helper.wrapInDeferredCheck(
        generator._makeSimpleRead(), builder, token.charOffset);
  }

  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return helper.wrapInDeferredCheck(
        generator._makeRead(complexAssignment), builder, token.charOffset);
  }

  Expression _makeWrite(Expression value, bool voidContext,
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
      Expression expression = propertyAccess;
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

  Expression doInvocation(int offset, Arguments arguments) {
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

class ReadOnlyAccessGenerator extends KernelGenerator {
  final String plainNameForRead;

  Expression expression;

  VariableDeclaration value;

  ReadOnlyAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.expression,
      this.plainNameForRead)
      : super(helper, token);

  String get debugName => "ReadOnlyAccessGenerator";

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

class LargeIntAccessGenerator extends KernelGenerator {
  LargeIntAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper, Token token)
      : super(helper, token);

  // TODO(ahe): This should probably be calling unhandled.
  String get plainNameForRead => null;

  String get debugName => "LargeIntAccessGenerator";

  @override
  Expression _makeSimpleRead() => buildError();

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return buildError();
  }

  @override
  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return buildError();
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return buildError();
  }

  Expression buildError() {
    return helper.buildCompileTimeError(
        templateIntegerLiteralIsOutOfRange.withArguments(token),
        offsetForToken(token),
        lengthForToken(token));
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return buildError();
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", lexeme: ");
    sink.write(token.lexeme);
  }
}

abstract class ErroneousExpressionGenerator implements KernelGenerator {
  /// Pass [arguments] that must be evaluated before throwing an error.  At
  /// most one of [isGetter] and [isSetter] should be true and they're passed
  /// to [ExpressionGeneratorHelper.buildThrowNoSuchMethodError] if it is used.
  Expression buildError(Arguments arguments,
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
  buildThrowNoSuchMethodError(Expression receiver, Arguments arguments,
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
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildError(forest.arguments(<Expression>[value], noLocation),
        isSetter: true);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return buildError(forest.arguments(<Expression>[value], token),
        isGetter: true);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    // TODO(ahe): For the Analyzer, we probably need to build a prefix
    // increment node that wraps an error.
    return buildError(
        forest.arguments(
            <Expression>[storeOffset(forest.literalInt(1, null), offset)],
            noLocation),
        isGetter: true);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    // TODO(ahe): For the Analyzer, we probably need to build a post increment
    // node that wraps an error.
    return buildError(
        forest.arguments(
            <Expression>[storeOffset(forest.literalInt(1, null), offset)],
            noLocation),
        isGetter: true);
  }

  @override
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildError(forest.arguments(<Expression>[value], noLocation),
        isSetter: true);
  }

  @override
  Expression buildSimpleRead() =>
      buildError(forest.argumentsEmpty(noLocation), isGetter: true);

  @override
  Expression makeInvalidRead() =>
      buildError(forest.argumentsEmpty(noLocation), isGetter: true);

  @override
  Expression makeInvalidWrite(Expression value) {
    return buildError(forest.arguments(<Expression>[value], noLocation),
        isSetter: true);
  }
}

class ThisAccessGenerator extends KernelGenerator {
  final bool isInitializer;

  final bool isSuper;

  ThisAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.isInitializer,
      {this.isSuper: false})
      : super(helper, token);

  String get plainNameForRead {
    return unsupported("${isSuper ? 'super' : 'this'}.plainNameForRead",
        offsetForToken(token), uri);
  }

  String get debugName => "ThisAccessGenerator";

  Expression buildSimpleRead() {
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
    if (isInitializer && send is SendAccessGenerator) {
      if (isNullAware) {
        helper.deprecated_addCompileTimeError(
            operatorOffset, "Expected '.'\nTry removing '?'.");
      }
      return buildConstructorInitializer(offset, name, arguments);
    }
    Member getter = helper.lookupInstanceMember(name, isSuper: isSuper);
    if (send is SendAccessGenerator) {
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

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildAssignmentError();
  }

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildAssignmentError();
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return buildAssignmentError();
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildAssignmentError();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildAssignmentError();
  }

  Expression buildAssignmentError() {
    String message =
        isSuper ? "Can't assign to 'super'." : "Can't assign to 'this'.";
    return helper.deprecated_buildCompileTimeError(
        message, offsetForToken(token));
  }

  @override
  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeRead", offsetForToken(token), uri);
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
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

abstract class IncompleteSendGenerator extends KernelGenerator {
  final Name name;

  IncompleteSendGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.name)
      : super(helper, token);

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware});

  Arguments get arguments => null;

  @override
  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeRead", offsetForToken(token), uri);
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeWrite", offsetForToken(token), uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

class UnresolvedNameGenerator extends KernelGenerator
    with ErroneousExpressionGenerator {
  @override
  final Name name;

  UnresolvedNameGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.name)
      : super(helper, token);

  String get debugName => "UnresolvedNameGenerator";

  Expression doInvocation(int charOffset, Arguments arguments) {
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
  Expression buildError(Arguments arguments,
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
  Expression _makeRead(ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeRead", offsetForToken(token), uri);
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ShadowComplexAssignment complexAssignment) {
    return unsupported("_makeWrite", offsetForToken(token), uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

class IncompleteErrorGenerator extends IncompleteSendGenerator
    with ErroneousExpressionGenerator {
  final Message message;

  IncompleteErrorGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.message)
      : super(helper, token, null);

  String get debugName => "IncompleteErrorGenerator";

  @override
  Expression buildError(Arguments arguments,
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

// TODO(ahe): Rename to SendGenerator.
class SendAccessGenerator extends IncompleteSendGenerator {
  @override
  final Arguments arguments;

  SendAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      Name name,
      this.arguments)
      : super(helper, token, name) {
    assert(arguments != null);
  }

  String get plainNameForRead => name.name;

  String get debugName => "SendAccessGenerator";

  Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", offsetForToken(token), uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
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

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, uri);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return unsupported(
        "buildCompoundAssignment", offset ?? offsetForToken(token), uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPrefixIncrement", offset ?? offsetForToken(token), uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPostfixIncrement", offset ?? offsetForToken(token), uri);
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, uri);
  }

  @override
  void printOn(StringSink sink) {
    super.printOn(sink);
    sink.write(", arguments: ");
    var node = arguments;
    if (node is Node) {
      printNodeOn(node, sink);
    } else {
      sink.write(node);
    }
  }
}

class IncompletePropertyAccessGenerator extends IncompleteSendGenerator {
  IncompletePropertyAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      Name name)
      : super(helper, token, name);

  String get plainNameForRead => name.name;

  String get debugName => "IncompletePropertyAccessGenerator";

  Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", offsetForToken(token), uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
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

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, uri);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return unsupported(
        "buildCompoundAssignment", offset ?? offsetForToken(token), uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPrefixIncrement", offset ?? offsetForToken(token), uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return unsupported(
        "buildPostfixIncrement", offset ?? offsetForToken(token), uri);
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, uri);
  }
}

class ParenthesizedExpressionGenerator extends ReadOnlyAccessGenerator {
  ParenthesizedExpressionGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      Expression expression)
      : super(helper, token, expression, null);

  String get debugName => "ParenthesizedExpressionGenerator";

  Expression makeInvalidWrite(Expression value) {
    return helper.deprecated_buildCompileTimeError(
        "Can't assign to a parenthesized expression.", offsetForToken(token));
  }
}

// TODO(ahe): Rename to TypeUseGenerator.
class TypeDeclarationAccessGenerator extends ReadOnlyAccessGenerator {
  /// The import prefix preceding the [declaration] reference, or `null` if
  /// the reference is not prefixed.
  final PrefixBuilder prefix;

  /// The offset at which the [declaration] is referenced by this generator,
  /// or `-1` if the reference is implicit.
  final int declarationReferenceOffset;

  final TypeDeclarationBuilder declaration;

  TypeDeclarationAccessGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.prefix,
      this.declarationReferenceOffset,
      this.declaration,
      String plainNameForRead)
      : super(helper, token, null, plainNameForRead);

  String get debugName => "TypeDeclarationAccessGenerator";

  Expression get expression {
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

  Expression makeInvalidWrite(Expression value) {
    return buildThrowNoSuchMethodError(
        forest.literalNull(token),
        storeOffset(
            forest.arguments(<Expression>[value], null), value.fileOffset),
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
        if (send is IncompletePropertyAccessGenerator) {
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
            "TypeDeclarationAccessGenerator.buildType",
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
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildConstructorInvocation(declaration, token, arguments, "",
        null, token.charOffset, Constness.implicit);
  }
}

abstract class ContextAwareGenerator
    extends Generator<Expression, Statement, Arguments> {
  final Generator generator;

  ContextAwareGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      this.generator)
      : super(helper, token);

  String get plainNameForRead {
    return unsupported("plainNameForRead", token.charOffset, helper.uri);
  }

  Expression doInvocation(int charOffset, Arguments arguments) {
    return unhandled("${runtimeType}", "doInvocation", charOffset, uri);
  }

  Expression buildSimpleRead();

  Expression buildForEffect();

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return makeInvalidWrite(value);
  }

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return makeInvalidWrite(value);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return makeInvalidWrite(value);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return makeInvalidWrite(null);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return makeInvalidWrite(null);
  }

  makeInvalidRead() {
    return unsupported("makeInvalidRead", token.charOffset, helper.uri);
  }

  Expression makeInvalidWrite(Expression value) {
    return helper.deprecated_buildCompileTimeError(
        "Can't be used as left-hand side of assignment.",
        offsetForToken(token));
  }
}

class DelayedAssignment extends ContextAwareGenerator {
  final Expression value;

  final String assignmentOperator;

  DelayedAssignment(ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token, Generator generator, this.value, this.assignmentOperator)
      : super(helper, token, generator);

  String get debugName => "DelayedAssignment";

  Expression buildSimpleRead() {
    return handleAssignment(false);
  }

  Expression buildForEffect() {
    return handleAssignment(true);
  }

  Expression handleAssignment(bool voidContext) {
    if (helper.constantContext != ConstantContext.none) {
      return helper.deprecated_buildCompileTimeError(
          "Not a constant expression.", offsetForToken(token));
    }
    if (identical("=", assignmentOperator)) {
      return generator.buildAssignment(value, voidContext: voidContext);
    } else if (identical("+=", assignmentOperator)) {
      return generator.buildCompoundAssignment(plusName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("-=", assignmentOperator)) {
      return generator.buildCompoundAssignment(minusName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("*=", assignmentOperator)) {
      return generator.buildCompoundAssignment(multiplyName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("%=", assignmentOperator)) {
      return generator.buildCompoundAssignment(percentName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("&=", assignmentOperator)) {
      return generator.buildCompoundAssignment(ampersandName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("/=", assignmentOperator)) {
      return generator.buildCompoundAssignment(divisionName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("<<=", assignmentOperator)) {
      return generator.buildCompoundAssignment(leftShiftName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical(">>=", assignmentOperator)) {
      return generator.buildCompoundAssignment(rightShiftName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("??=", assignmentOperator)) {
      return generator.buildNullAwareAssignment(
          value, const DynamicType(), offsetForToken(token),
          voidContext: voidContext);
    } else if (identical("^=", assignmentOperator)) {
      return generator.buildCompoundAssignment(caretName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("|=", assignmentOperator)) {
      return generator.buildCompoundAssignment(barName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("~/=", assignmentOperator)) {
      return generator.buildCompoundAssignment(mustacheName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else {
      return unhandled(
          assignmentOperator, "handleAssignment", token.charOffset, helper.uri);
    }
  }

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    if (!identical("=", assignmentOperator) ||
        !generator.isThisPropertyAccess) {
      return generator.buildFieldInitializer(initializedFields);
    }
    return helper.buildFieldInitializer(
        false, generator.plainNameForRead, offsetForToken(token), value);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", value: ");
    printNodeOn(value, sink);
    sink.write(", assignmentOperator: ");
    sink.write(assignmentOperator);
  }
}

class DelayedPostfixIncrement extends ContextAwareGenerator {
  final Name binaryOperator;

  final Procedure interfaceTarget;

  DelayedPostfixIncrement(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      Token token,
      Generator generator,
      this.binaryOperator,
      this.interfaceTarget)
      : super(helper, token, generator);

  String get debugName => "DelayedPostfixIncrement";

  Expression buildSimpleRead() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: offsetForToken(token),
        voidContext: false,
        interfaceTarget: interfaceTarget);
  }

  Expression buildForEffect() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: offsetForToken(token),
        voidContext: true,
        interfaceTarget: interfaceTarget);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", binaryOperator: ");
    sink.write(binaryOperator.name);
    sink.write(", interfaceTarget: ");
    printQualifiedNameOn(interfaceTarget, sink);
  }
}
