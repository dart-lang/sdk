// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fasta_accessors;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show
        KernelArguments,
        KernelComplexAssignment,
        KernelIndexAssign,
        KernelThisExpression,
        KernelVariableAssignment;

import 'package:front_end/src/fasta/kernel/utils.dart' show offsetForToken;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'frontend_accessors.dart' show Accessor;

import 'package:front_end/src/fasta/type_inference/type_promotion.dart'
    show TypePromoter;

import 'package:kernel/ast.dart'
    hide InvalidExpression, InvalidInitializer, InvalidStatement;

import '../errors.dart' show internalError;

import '../scope.dart' show AccessErrorBuilder, ProblemBuilder, Scope;

import 'frontend_accessors.dart' as kernel
    show
        IndexAccessor,
        NullAwarePropertyAccessor,
        PropertyAccessor,
        ReadOnlyAccessor,
        StaticAccessor,
        SuperIndexAccessor,
        SuperPropertyAccessor,
        ThisIndexAccessor,
        ThisPropertyAccessor,
        VariableAccessor;

import 'kernel_builder.dart'
    show
        Builder,
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        LibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder;

import '../names.dart' show callName, lengthName;

abstract class BuilderHelper {
  LibraryBuilder get library;

  Uri get uri;

  TypePromoter get typePromoter;

  int get functionNestingLevel;

  bool get constantExpressionRequired;

  Constructor lookupConstructor(Name name, {bool isSuper});

  Expression toSuperMethodInvocation(MethodInvocation node);

  Expression toValue(node);

  Member lookupSuperMember(Name name, {bool isSetter});

  scopeLookup(Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder prefix});

  finishSend(Object receiver, Arguments arguments, int offset);

  Expression buildCompileTimeError(error, [int offset]);

  Initializer buildInvalidInitializer(Expression expression, [int offset]);

  Initializer buildFieldInitializer(
      String name, int offset, Expression expression);

  Initializer buildSuperInitializer(
      Constructor constructor, Arguments arguments,
      [int offset]);

  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]);

  Expression buildStaticInvocation(Procedure target, Arguments arguments);

  Expression buildProblemExpression(ProblemBuilder builder, int offset);

  Expression throwNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isSuper, bool isGetter, bool isSetter, bool isStatic});

  Expression invokeSuperNoSuchMethod(
      String name, Arguments arguments, int charOffset,
      {bool isGetter, bool isSetter});

  bool checkArguments(FunctionNode function, Arguments arguments,
      List<TypeParameter> typeParameters);

  StaticGet makeStaticGet(Member readTarget, Token token);

  dynamic addCompileTimeError(int charOffset, String message, {bool silent});

  bool isIdentical(Member member);

  Expression buildMethodInvocation(
      Expression receiver, Name name, Arguments arguments, int offset,
      {bool isConstantExpression, bool isNullAware, bool isImplicitCall});

  DartType validatedTypeVariableUse(
      TypeParameterType type, int offset, bool nonInstanceAccessIsError);

  void warning(String message, [int charOffset]);
}

abstract class FastaAccessor implements Accessor {
  BuilderHelper get helper;

  String get plainNameForRead;

  Uri get uri => helper.uri;

  String get plainNameForWrite => plainNameForRead;

  bool get isInitializer => false;

  Expression buildForEffect() => buildSimpleRead();

  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    int offset = offsetForToken(token);
    return helper.buildInvalidInitializer(
        helper.buildCompileTimeError(
            // TODO(ahe): This error message is really bad.
            "Can't use $plainNameForRead here.",
            offset),
        offset);
  }

  Expression makeInvalidRead() {
    return buildThrowNoSuchMethodError(
        new NullLiteral()..fileOffset = offsetForToken(token),
        new Arguments.empty(),
        isGetter: true);
  }

  Expression makeInvalidWrite(Expression value) {
    return buildThrowNoSuchMethodError(
        new NullLiteral()..fileOffset = offsetForToken(token),
        new KernelArguments(<Expression>[value]),
        isSetter: true);
  }

  /* Expression | FastaAccessor | Initializer */ doInvocation(
      int offset, Arguments arguments);

  /* Expression | FastaAccessor */ buildPropertyAccess(
      IncompleteSend send, int operatorOffset, bool isNullAware) {
    if (send is SendAccessor) {
      return helper.buildMethodInvocation(buildSimpleRead(), send.name,
          send.arguments, offsetForToken(send.token),
          isNullAware: isNullAware);
    } else {
      if (helper.constantExpressionRequired && send.name != lengthName) {
        helper.addCompileTimeError(
            offsetForToken(token), "Not a constant expression.");
      }
      return PropertyAccessor.make(helper, send.token, buildSimpleRead(),
          send.name, null, null, isNullAware);
    }
  }

  /* Expression | FastaAccessor */ buildThrowNoSuchMethodError(
      Expression receiver, Arguments arguments,
      {bool isSuper: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isStatic: false,
      String name,
      int offset}) {
    return helper.throwNoSuchMethodError(receiver, name ?? plainNameForWrite,
        arguments, offset ?? offsetForToken(this.token),
        isGetter: isGetter,
        isSetter: isSetter,
        isSuper: isSuper,
        isStatic: isStatic);
  }

  bool get isThisPropertyAccessor => false;

  @override
  KernelComplexAssignment startComplexAssignment(Expression rhs) => null;
}

abstract class ErrorAccessor implements FastaAccessor {
  /// Pass [arguments] that must be evaluated before throwing an error.  At
  /// most one of [isGetter] and [isSetter] should be true and they're passed
  /// to [BuilderHelper.buildThrowNoSuchMethodError] if it is used.
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset});

  Name get name => internalError("Unsupported operation.");

  @override
  String get plainNameForRead => name.name;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware}) => this;

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    return helper.buildInvalidInitializer(
        buildError(new Arguments.empty(), isSetter: true));
  }

  @override
  doInvocation(int offset, Arguments arguments) {
    return buildError(arguments, offset: offset);
  }

  @override
  buildPropertyAccess(
      IncompleteSend send, int operatorOffset, bool isNullAware) {
    return this;
  }

  @override
  buildThrowNoSuchMethodError(Expression receiver, Arguments arguments,
      {bool isSuper: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isStatic: false,
      String name,
      int offset}) {
    return this;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildError(new KernelArguments(<Expression>[value]), isSetter: true);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return buildError(new KernelArguments(<Expression>[value]), isGetter: true);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildError(new KernelArguments(<Expression>[new IntLiteral(1)]),
        isGetter: true);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildError(new KernelArguments(<Expression>[new IntLiteral(1)]),
        isGetter: true);
  }

  @override
  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return buildError(new KernelArguments(<Expression>[value]), isSetter: true);
  }

  @override
  Expression buildSimpleRead() =>
      buildError(new Arguments.empty(), isGetter: true);

  @override
  Expression makeInvalidRead() =>
      buildError(new Arguments.empty(), isGetter: true);

  @override
  Expression makeInvalidWrite(Expression value) {
    return buildError(new KernelArguments(<Expression>[value]), isSetter: true);
  }
}

class ThisAccessor extends FastaAccessor {
  final BuilderHelper helper;

  final Token token;

  final bool isInitializer;

  final bool isSuper;

  ThisAccessor(this.helper, this.token, this.isInitializer,
      {this.isSuper: false});

  String get plainNameForRead => internalError(isSuper ? "super" : "this");

  Expression buildSimpleRead() {
    if (!isSuper) {
      return new KernelThisExpression();
    } else {
      return helper.buildCompileTimeError(
          "Can't use `super` as an expression.", offsetForToken(token));
    }
  }

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    String keyword = isSuper ? "super" : "this";
    int offset = offsetForToken(token);
    return helper.buildInvalidInitializer(
        helper.buildCompileTimeError(
            "Can't use '$keyword' here, did you mean '$keyword()'?", offset),
        offset);
  }

  buildPropertyAccess(
      IncompleteSend send, int operatorOffset, bool isNullAware) {
    if (isInitializer && send is SendAccessor) {
      return buildConstructorInitializer(
          offsetForToken(send.token), send.name, send.arguments);
    }
    if (send is SendAccessor) {
      // Notice that 'this' or 'super' can't be null. So we can ignore the
      // value of [isNullAware].
      MethodInvocation result = helper.buildMethodInvocation(
          new KernelThisExpression(),
          send.name,
          send.arguments,
          offsetForToken(send.token));
      return isSuper ? helper.toSuperMethodInvocation(result) : result;
    } else {
      if (isSuper) {
        Member getter = helper.lookupSuperMember(send.name);
        Member setter = helper.lookupSuperMember(send.name, isSetter: true);
        return new SuperPropertyAccessor(
            helper, send.token, send.name, getter, setter);
      } else {
        return new ThisPropertyAccessor(
            helper, send.token, send.name, null, null);
      }
    }
  }

  doInvocation(int offset, Arguments arguments) {
    if (isInitializer) {
      return buildConstructorInitializer(offset, new Name(""), arguments);
    } else {
      return helper.buildMethodInvocation(
          new KernelThisExpression(), callName, arguments, offset,
          isImplicitCall: true);
    }
  }

  Initializer buildConstructorInitializer(
      int offset, Name name, Arguments arguments) {
    Constructor constructor = helper.lookupConstructor(name, isSuper: isSuper);
    if (constructor == null ||
        !helper.checkArguments(
            constructor.function, arguments, <TypeParameter>[])) {
      return helper.buildInvalidInitializer(
          buildThrowNoSuchMethodError(
              new NullLiteral()..fileOffset = offset, arguments,
              isSuper: isSuper, name: name.name, offset: offset),
          offset);
    } else if (isSuper) {
      return helper.buildSuperInitializer(constructor, arguments, offset);
    } else {
      return helper.buildRedirectingInitializer(constructor, arguments, offset);
    }
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildAssignmentError();
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
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
    return helper.buildCompileTimeError(message, offsetForToken(token));
  }

  toString() {
    int offset = offsetForToken(token);
    return "ThisAccessor($offset${isSuper ? ', super' : ''})";
  }
}

abstract class IncompleteSend extends FastaAccessor {
  final BuilderHelper helper;

  @override
  final Token token;

  final Name name;

  IncompleteSend(this.helper, this.token, this.name);

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware});

  Arguments get arguments => null;
}

class IncompleteError extends IncompleteSend with ErrorAccessor {
  final Object error;

  IncompleteError(BuilderHelper helper, Token token, this.error)
      : super(helper, token, null);

  @override
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    return helper.buildCompileTimeError(
        error, offset ?? offsetForToken(this.token));
  }

  @override
  doInvocation(int offset, Arguments arguments) => this;
}

class SendAccessor extends IncompleteSend {
  @override
  final Arguments arguments;

  SendAccessor(BuilderHelper helper, Token token, Name name, this.arguments)
      : super(helper, token, name) {
    assert(arguments != null);
  }

  String get plainNameForRead => name.name;

  Expression buildSimpleRead() {
    return internalError("Unhandled");
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return internalError("Unhandled");
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is FastaAccessor) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    if (receiver is PrefixBuilder) {
      PrefixBuilder prefix = receiver;
      receiver = helper.scopeLookup(prefix.exports, name.name, token,
          isQualified: true, prefix: prefix);
      return helper.finishSend(receiver, arguments, offsetForToken(token));
    }
    return helper.buildMethodInvocation(
        helper.toValue(receiver), name, arguments, offsetForToken(token),
        isNullAware: isNullAware);
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return internalError("Unhandled");
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return internalError("Unhandled");
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return internalError("Unhandled");
  }

  toString() {
    int offset = offsetForToken(token);
    return "SendAccessor($offset, $name, $arguments)";
  }
}

class IncompletePropertyAccessor extends IncompleteSend {
  IncompletePropertyAccessor(BuilderHelper helper, Token token, Name name)
      : super(helper, token, name);

  String get plainNameForRead => name.name;

  Expression buildSimpleRead() => internalError("Unhandled");

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return internalError("Unhandled");
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is FastaAccessor) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    if (receiver is PrefixBuilder) {
      PrefixBuilder prefix = receiver;
      return helper.scopeLookup(prefix.exports, name.name, token,
          isQualified: true, prefix: prefix);
    }

    return PropertyAccessor.make(
        helper, token, helper.toValue(receiver), name, null, null, isNullAware);
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return internalError("Unhandled");
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false}) {
    return internalError("Unhandled");
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return internalError("Unhandled");
  }

  toString() {
    int offset = offsetForToken(token);
    return "IncompletePropertyAccessor($offset, $name)";
  }
}

class IndexAccessor extends kernel.IndexAccessor with FastaAccessor {
  final BuilderHelper helper;

  IndexAccessor.internal(this.helper, Token token, Expression receiver,
      Expression index, Procedure getter, Procedure setter)
      : super.internal(helper, receiver, index, getter, setter, token);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  toString() => "IndexAccessor()";

  static FastaAccessor make(
      BuilderHelper helper,
      Token token,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter) {
    if (receiver is ThisExpression) {
      return new ThisIndexAccessor(helper, token, index, getter, setter);
    } else {
      return new IndexAccessor.internal(
          helper, token, receiver, index, getter, setter);
    }
  }

  @override
  KernelComplexAssignment startComplexAssignment(Expression rhs) =>
      new KernelIndexAssign(receiver, index, rhs);
}

class PropertyAccessor extends kernel.PropertyAccessor with FastaAccessor {
  final BuilderHelper helper;

  PropertyAccessor.internal(this.helper, Token token, Expression receiver,
      Name name, Member getter, Member setter)
      : super.internal(helper, receiver, name, getter, setter, token);

  String get plainNameForRead => name.name;

  bool get isThisPropertyAccessor => receiver is ThisExpression;

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(receiver, name, arguments, offset);
  }

  toString() => "PropertyAccessor()";

  static FastaAccessor make(
      BuilderHelper helper,
      Token token,
      Expression receiver,
      Name name,
      Member getter,
      Member setter,
      bool isNullAware) {
    if (receiver is ThisExpression) {
      return new ThisPropertyAccessor(helper, token, name, getter, setter);
    } else {
      return isNullAware
          ? new NullAwarePropertyAccessor(
              helper, token, receiver, name, getter, setter, null)
          : new PropertyAccessor.internal(
              helper, token, receiver, name, getter, setter);
    }
  }
}

class StaticAccessor extends kernel.StaticAccessor with FastaAccessor {
  StaticAccessor(
      BuilderHelper helper, Token token, Member readTarget, Member writeTarget)
      : super(helper, readTarget, writeTarget, token) {
    assert(readTarget != null || writeTarget != null);
  }

  factory StaticAccessor.fromBuilder(BuilderHelper helper, Builder builder,
      Token token, Builder builderSetter) {
    if (builder is AccessErrorBuilder) {
      AccessErrorBuilder error = builder;
      builder = error.builder;
      // We should only see an access error here if we've looked up a setter
      // when not explicitly looking for a setter.
      assert(builder.isSetter);
    } else if (builder.target == null) {
      return internalError("Unhandled: ${builder}");
    }
    Member getter = builder.target.hasGetter ? builder.target : null;
    Member setter = builder.target.hasSetter ? builder.target : null;
    if (setter == null) {
      if (builderSetter?.target?.hasSetter ?? false) {
        setter = builderSetter.target;
      }
    }
    return new StaticAccessor(helper, token, getter, setter);
  }

  String get plainNameForRead => (readTarget ?? writeTarget).name.name;

  Expression doInvocation(int offset, Arguments arguments) {
    if (helper.constantExpressionRequired && !helper.isIdentical(readTarget)) {
      helper.addCompileTimeError(offset, "Not a constant expression.");
    }
    if (readTarget == null || isFieldOrGetter(readTarget)) {
      return helper.buildMethodInvocation(buildSimpleRead(), callName,
          arguments, offset + (readTarget?.name?.name?.length ?? 0),
          // This isn't a constant expression, but we have checked if a
          // constant expression error should be emitted already.
          isConstantExpression: true,
          isImplicitCall: true);
    } else {
      return helper.buildStaticInvocation(readTarget, arguments)
        ..fileOffset = offset;
    }
  }

  toString() => "StaticAccessor()";
}

class SuperPropertyAccessor extends kernel.SuperPropertyAccessor
    with FastaAccessor {
  SuperPropertyAccessor(BuilderHelper helper, Token token, Name name,
      Member getter, Member setter)
      : super(helper, name, getter, setter, token);

  String get plainNameForRead => name.name;

  Expression doInvocation(int offset, Arguments arguments) {
    if (helper.constantExpressionRequired) {
      helper.addCompileTimeError(offset, "Not a constant expression.");
    }
    if (getter == null || isFieldOrGetter(getter)) {
      return helper.buildMethodInvocation(
          buildSimpleRead(), callName, arguments, offset,
          // This isn't a constant expression, but we have checked if a
          // constant expression error should be emitted already.
          isConstantExpression: true,
          isImplicitCall: true);
    } else {
      return new DirectMethodInvocation(new ThisExpression(), getter, arguments)
        ..fileOffset = offset;
    }
  }

  Expression makeInvalidRead() {
    int offset = offsetForToken(token);
    return helper.invokeSuperNoSuchMethod(
        plainNameForRead, new Arguments.empty()..fileOffset = offset, offset,
        isGetter: true);
  }

  Expression makeInvalidWrite(Expression value) {
    return helper.invokeSuperNoSuchMethod(
        plainNameForRead,
        new Arguments(<Expression>[value])..fileOffset = value.fileOffset,
        offsetForToken(token),
        isSetter: true);
  }

  toString() => "SuperPropertyAccessor()";
}

class ThisIndexAccessor extends kernel.ThisIndexAccessor with FastaAccessor {
  ThisIndexAccessor(BuilderHelper helper, Token token, Expression index,
      Procedure getter, Procedure setter)
      : super(helper, index, getter, setter, token);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  toString() => "ThisIndexAccessor()";
}

class SuperIndexAccessor extends kernel.SuperIndexAccessor with FastaAccessor {
  SuperIndexAccessor(BuilderHelper helper, Token token, Expression index,
      Member getter, Member setter)
      : super(helper, index, getter, setter, token);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  toString() => "SuperIndexAccessor()";
}

class ThisPropertyAccessor extends kernel.ThisPropertyAccessor
    with FastaAccessor {
  final BuilderHelper helper;

  ThisPropertyAccessor(
      this.helper, Token token, Name name, Member getter, Member setter)
      : super(helper, name, getter, setter, token);

  String get plainNameForRead => name.name;

  bool get isThisPropertyAccessor => true;

  Expression doInvocation(int offset, Arguments arguments) {
    Member interfaceTarget = getter;
    if (interfaceTarget is Field) {
      // TODO(ahe): In strong mode we should probably rewrite this to
      // `this.name.call(arguments)`.
      interfaceTarget = null;
    }
    return helper.buildMethodInvocation(
        new KernelThisExpression(), name, arguments, offset);
  }

  toString() => "ThisPropertyAccessor()";
}

class NullAwarePropertyAccessor extends kernel.NullAwarePropertyAccessor
    with FastaAccessor {
  final BuilderHelper helper;

  NullAwarePropertyAccessor(this.helper, Token token, Expression receiver,
      Name name, Member getter, Member setter, DartType type)
      : super(helper, receiver, name, getter, setter, type, token);

  String get plainNameForRead => name.name;

  Expression doInvocation(int offset, Arguments arguments) {
    return internalError("Not implemented yet.");
  }

  toString() => "NullAwarePropertyAccessor()";
}

int adjustForImplicitCall(String name, int offset) {
  // Normally the offset is at the start of the token, but in this case,
  // because we insert a '.call', we want it at the end instead.
  return offset + (name?.length ?? 0);
}

class VariableAccessor extends kernel.VariableAccessor with FastaAccessor {
  VariableAccessor(
      BuilderHelper helper, Token token, VariableDeclaration variable,
      [DartType promotedType])
      : super(helper, variable, promotedType, token);

  String get plainNameForRead => variable.name;

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(plainNameForRead, offset),
        isImplicitCall: true);
  }

  toString() => "VariableAccessor()";

  @override
  KernelComplexAssignment startComplexAssignment(Expression rhs) =>
      new KernelVariableAssignment(rhs);
}

class ReadOnlyAccessor extends kernel.ReadOnlyAccessor with FastaAccessor {
  final String plainNameForRead;

  ReadOnlyAccessor(BuilderHelper helper, Expression expression,
      this.plainNameForRead, Token token)
      : super(helper, expression, token);

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(plainNameForRead, offset),
        isImplicitCall: true);
  }
}

class ParenthesizedExpression extends ReadOnlyAccessor {
  ParenthesizedExpression(
      BuilderHelper helper, Expression expression, Token token)
      : super(helper, expression, null, token);

  Expression makeInvalidWrite(Expression value) {
    return helper.buildCompileTimeError(
        "Can't assign to a parenthesized expression.", offsetForToken(token));
  }
}

class TypeDeclarationAccessor extends ReadOnlyAccessor {
  final TypeDeclarationBuilder declaration;

  TypeDeclarationAccessor(BuilderHelper helper, this.declaration,
      String plainNameForRead, Token token)
      : super(helper, null, plainNameForRead, token);

  Expression get expression {
    if (super.expression == null) {
      int offset = offsetForToken(token);
      if (declaration is KernelInvalidTypeBuilder) {
        KernelInvalidTypeBuilder declaration = this.declaration;
        String message = declaration.message;
        helper.library.addWarning(declaration.charOffset, message,
            fileUri: declaration.fileUri);
        helper.warning(message, offset);
        super.expression = new Throw(
            new StringLiteral(message)..fileOffset = offsetForToken(token))
          ..fileOffset = offset;
      } else {
        super.expression =
            new TypeLiteral(buildType(null, nonInstanceAccessIsError: true))
              ..fileOffset = offsetForToken(token);
      }
    }
    return super.expression;
  }

  Expression makeInvalidWrite(Expression value) {
    return buildThrowNoSuchMethodError(
        new NullLiteral()..fileOffset = offsetForToken(token),
        new Arguments(<Expression>[value])..fileOffset = value.fileOffset,
        isSetter: true);
  }

  @override
  buildPropertyAccess(
      IncompleteSend send, int operatorOffset, bool isNullAware) {
    // `SomeType?.toString` is the same as `SomeType.toString`, not
    // `(SomeType).toString`.
    isNullAware = false;

    Name name = send.name;
    Arguments arguments = send.arguments;

    if (declaration is KernelClassBuilder) {
      KernelClassBuilder declaration = this.declaration;
      Builder builder = declaration.findStaticBuilder(
          name.name, offsetForToken(token), uri, helper.library);

      FastaAccessor accessor;
      if (builder == null) {
        // If we find a setter, [builder] is an [AccessErrorBuilder], not null.
        accessor = new UnresolvedAccessor(helper, name, token);
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
        accessor =
            new StaticAccessor.fromBuilder(helper, builder, send.token, setter);
      }

      return arguments == null
          ? accessor
          : accessor.doInvocation(offsetForToken(send.token), arguments);
    } else {
      return super.buildPropertyAccess(send, operatorOffset, isNullAware);
    }
  }

  DartType buildType(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false}) {
    DartType type =
        declaration.buildTypesWithBuiltArguments(helper.library, arguments);
    if (type is TypeParameterType) {
      return helper.validatedTypeVariableUse(
          type, offsetForToken(token), nonInstanceAccessIsError);
    }
    return type;
  }
}

class UnresolvedAccessor extends FastaAccessor with ErrorAccessor {
  @override
  final Token token;

  @override
  final BuilderHelper helper;

  @override
  final Name name;

  UnresolvedAccessor(this.helper, this.name, this.token);

  Expression doInvocation(int charOffset, Arguments arguments) {
    return buildError(arguments, offset: charOffset);
  }

  @override
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    offset ??= offsetForToken(this.token);
    return helper.throwNoSuchMethodError(new NullLiteral()..fileOffset = offset,
        plainNameForRead, arguments, offset,
        isGetter: isGetter, isSetter: isSetter);
  }
}

bool isFieldOrGetter(Member member) {
  return member is Field || (member is Procedure && member.isGetter);
}
