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
        return new SuperPropertyAccessGenerator<Expression, Statement,
            Arguments>(helper, send.token, name, getter, setter);
      } else {
        return new ThisPropertyAccessGenerator<Expression, Statement,
            Arguments>(helper, send.token, name, getter, setter);
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

    return PropertyAccessGenerator.make<Expression, Statement, Arguments>(
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

class ParenthesizedExpressionGenerator extends KernelReadOnlyAccessGenerator {
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
