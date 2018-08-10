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

class ThisAccessGenerator extends KernelGenerator {
  final bool isInitializer;
  final bool inFieldInitializer;

  final bool isSuper;

  ThisAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.isInitializer, this.inFieldInitializer,
      {this.isSuper: false})
      : super(helper, token);

  String get plainNameForRead {
    return unsupported("${isSuper ? 'super' : 'this'}.plainNameForRead",
        offsetForToken(token), uri);
  }

  String get debugName => "ThisAccessGenerator";

  Expression buildSimpleRead() {
    if (!isSuper) {
      if (inFieldInitializer) {
        return buildFieldInitializerError();
      } else {
        return forest.thisExpression(token);
      }
    } else {
      return new SyntheticExpressionJudgment(helper.buildCompileTimeError(
          messageSuperAsExpression,
          offsetForToken(token),
          lengthForToken(token)));
    }
  }

  @override
  Expression buildFieldInitializerError() {
    String keyword = isSuper ? "super" : "this";
    int offset = offsetForToken(token);
    return helper.buildCompileTimeErrorExpression(
        templateThisOrSuperAccessInFieldInitializer.withArguments(keyword),
        offset,
        length: keyword.length);
  }

  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    Name name = send.name;
    Arguments arguments = send.arguments;
    int offset = offsetForToken(send.token);
    if (isInitializer && send is SendAccessGenerator) {
      if (isNullAware) {
        helper.addCompileTimeError(
            messageInvalidUseOfNullAwareAccess, operatorOffset, 2);
      }
      return buildConstructorInitializer(offset, name, arguments);
    }
    if (inFieldInitializer && !isInitializer) {
      return buildFieldInitializerError();
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
      return new SyntheticExpressionJudgment(helper.buildCompileTimeError(
          messageSuperAsExpression, offset, noLength));
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
      return helper.buildInvalidInitializer(new SyntheticExpressionJudgment(
          helper.throwNoSuchMethodError(
              forest.literalNull(null)..fileOffset = offset,
              name.name,
              arguments,
              offset,
              isSuper: isSuper,
              argMessage: argMessage)));
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
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
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
    return helper.buildCompileTimeError(
        isSuper ? messageCannotAssignToSuper : messageNotAnLvalue,
        offsetForToken(token),
        token.length);
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
      ExpressionGeneratorHelper helper, Token token, this.name)
      : super(helper, token);

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware});

  Arguments get arguments => null;

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

class IncompleteErrorGenerator extends IncompleteSendGenerator
    with ErroneousExpressionGenerator {
  final Member member;
  final Message message;

  IncompleteErrorGenerator(
      ExpressionGeneratorHelper helper, Token token, this.member, this.message)
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
  doInvocation(int offset, Arguments arguments) => this;

  @override
  Expression buildSimpleRead() {
    var error = buildError(forest.argumentsEmpty(token, token), isGetter: true);
    return new InvalidPropertyGetJudgment(error, member)
      ..fileOffset = offsetForToken(token);
  }

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
      ExpressionGeneratorHelper helper, Token token, Name name, this.arguments)
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
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
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
      ExpressionGeneratorHelper helper, Token token, Name name)
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
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
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
      ExpressionGeneratorHelper helper, Token token, Expression expression)
      : super(helper, token, expression, null);

  String get debugName => "ParenthesizedExpressionGenerator";

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) {
    return new IllegalAssignmentJudgment(rhs,
        assignmentOffset: offsetForToken(token));
  }

  Expression makeInvalidWrite(Expression value) {
    var error = helper.buildCompileTimeError(
        messageCannotAssignToParenthesizedExpression,
        offsetForToken(token),
        lengthForToken(token));
    return new InvalidWriteJudgment(error, expression);
  }
}
