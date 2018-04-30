// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fasta_accessors;

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

import '../names.dart' show callName, lengthName;

import '../parser.dart' show lengthForToken, lengthOfSpan, offsetForToken;

import '../problems.dart' show unhandled, unimplemented, unsupported;

import '../scope.dart' show AccessErrorBuilder, ProblemBuilder, Scope;

import '../type_inference/type_promotion.dart' show TypePromoter;

import 'body_builder.dart' show Identifier, noLocation;

import 'constness.dart' show Constness;

import 'forest.dart' show Forest;

import 'frontend_accessors.dart' as kernel
    show
        IndexAccessor,
        NullAwarePropertyAccessor,
        LoadLibraryAccessor,
        PropertyAccessor,
        ReadOnlyAccessor,
        DeferredAccessor,
        DelayedErrorAccessor,
        StaticAccessor,
        SuperIndexAccessor,
        SuperPropertyAccessor,
        ThisIndexAccessor,
        ThisPropertyAccessor,
        VariableAccessor;

import 'frontend_accessors.dart' show Accessor;

import 'kernel_ast_api.dart';

import 'kernel_builder.dart'
    show
        Builder,
        BuiltinTypeBuilder,
        FunctionTypeAliasBuilder,
        KernelClassBuilder,
        KernelFunctionTypeAliasBuilder,
        KernelInvalidTypeBuilder,
        KernelLibraryBuilder,
        KernelPrefixBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder,
        KernelTypeBuilder;

import 'type_algorithms.dart' show calculateBoundsForDeclaration;

abstract class BuilderHelper<Arguments> {
  LibraryBuilder get library;

  Uri get uri;

  TypePromoter get typePromoter;

  int get functionNestingLevel;

  ConstantContext get constantContext;

  Forest<Expression, Statement, Token, Arguments> get forest;

  Constructor lookupConstructor(Name name, {bool isSuper});

  Expression toValue(node);

  Member lookupInstanceMember(Name name, {bool isSetter, bool isSuper});

  scopeLookup(Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder prefix});

  finishSend(Object receiver, Arguments arguments, int offset);

  Expression buildCompileTimeError(Message message, int charOffset, int length);

  Expression wrapInCompileTimeError(Expression expression, Message message);

  Expression deprecated_buildCompileTimeError(String error, [int offset]);

  Initializer buildInvalidInitializer(Expression expression, [int offset]);

  Initializer buildFieldInitializer(
      bool isSynthetic, String name, int offset, Expression expression);

  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int offset]);

  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]);

  Expression buildStaticInvocation(Procedure target, Arguments arguments,
      {Constness constness, int charOffset, Member initialTarget});

  Expression buildProblemExpression(
      ProblemBuilder builder, int offset, int length);

  Expression throwNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int offset,
      {Member candidate,
      bool isSuper,
      bool isGetter,
      bool isSetter,
      bool isStatic,
      LocatedMessage argMessage});

  LocatedMessage checkArguments(FunctionTypeAccessor function,
      Arguments arguments, CalleeDesignation calleeKind, int offset,
      [List<TypeParameter> typeParameters]);

  StaticGet makeStaticGet(Member readTarget, Token token);

  Expression wrapInDeferredCheck(
      Expression expression, KernelPrefixBuilder prefix, int charOffset);

  dynamic deprecated_addCompileTimeError(int charOffset, String message);

  bool isIdentical(Member member);

  Expression buildMethodInvocation(
      Expression receiver, Name name, Arguments arguments, int offset,
      {bool isConstantExpression,
      bool isNullAware,
      bool isImplicitCall,
      bool isSuper,
      Member interfaceTarget});

  Expression buildConstructorInvocation(
      TypeDeclarationBuilder type,
      Token nameToken,
      Arguments arguments,
      String name,
      List<DartType> typeArguments,
      int charOffset,
      Constness constness);

  DartType validatedTypeVariableUse(
      TypeParameterType type, int offset, bool nonInstanceAccessIsError);

  void addProblem(Message message, int charOffset, int length);

  void addProblemErrorIfConst(Message message, int charOffset, int length);

  Message warnUnresolvedGet(Name name, int charOffset, {bool isSuper});

  Message warnUnresolvedSet(Name name, int charOffset, {bool isSuper});

  Message warnUnresolvedMethod(Name name, int charOffset, {bool isSuper});

  void warnTypeArgumentsMismatch(String name, int expected, int charOffset);

  T storeOffset<T>(T node, int offset);
}

// The name used to refer to a call target kind
enum CalleeDesignation { Function, Method, Constructor }

// Abstraction over FunctionNode and FunctionType to access the
// number and names of parameters.
class FunctionTypeAccessor {
  int requiredParameterCount;
  int positionalParameterCount;

  List _namedParameters;

  Set<String> get namedParameterNames {
    return new Set.from(_namedParameters.map((a) => a.name));
  }

  factory FunctionTypeAccessor.fromNode(FunctionNode node) {
    return new FunctionTypeAccessor._(node.requiredParameterCount,
        node.positionalParameters.length, node.namedParameters);
  }

  factory FunctionTypeAccessor.fromType(FunctionType type) {
    return new FunctionTypeAccessor._(type.requiredParameterCount,
        type.positionalParameters.length, type.namedParameters);
  }

  FunctionTypeAccessor._(this.requiredParameterCount,
      this.positionalParameterCount, this._namedParameters);
}

abstract class FastaAccessor<Arguments> implements Accessor<Arguments> {
  BuilderHelper get helper;

  Forest<Expression, Statement, Token, Arguments> get forest => helper.forest;

  String get plainNameForRead;

  Uri get uri => helper.uri;

  String get plainNameForWrite => plainNameForRead;

  bool get isInitializer => false;

  T storeOffset<T>(T node, int offset) {
    return helper.storeOffset(node, offset);
  }

  Expression buildForEffect() => buildSimpleRead();

  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    int offset = offsetForToken(token);
    return helper.buildInvalidInitializer(
        helper.buildCompileTimeError(
            messageInvalidInitializer, offset, lengthForToken(token)),
        offset);
  }

  Expression makeInvalidRead() {
    return buildThrowNoSuchMethodError(
        forest.literalNull(token), forest.argumentsEmpty(noLocation),
        isGetter: true);
  }

  Expression makeInvalidWrite(Expression value) {
    return buildThrowNoSuchMethodError(forest.literalNull(token),
        forest.arguments(<Expression>[value], noLocation),
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
      if (helper.constantContext != ConstantContext.none &&
          send.name != lengthName) {
        helper.deprecated_addCompileTimeError(
            offsetForToken(token), "Not a constant expression.");
      }
      return PropertyAccessor.make(helper, send.token, buildSimpleRead(),
          send.name, null, null, isNullAware);
    }
  }

  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false}) {
    helper.addProblem(templateNotAType.withArguments(token.lexeme),
        offsetForToken(token), lengthForToken(token));
    return const InvalidType();
  }

  /* Expression | FastaAccessor */ buildThrowNoSuchMethodError(
      Expression receiver, Arguments arguments,
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

  bool get isThisPropertyAccessor => false;

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowIllegalAssignment(rhs);
}

abstract class ErrorAccessor<Arguments> implements FastaAccessor<Arguments> {
  /// Pass [arguments] that must be evaluated before throwing an error.  At
  /// most one of [isGetter] and [isSetter] should be true and they're passed
  /// to [BuilderHelper.buildThrowNoSuchMethodError] if it is used.
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

class ThisAccessor<Arguments> extends FastaAccessor<Arguments> {
  final BuilderHelper helper;

  final Token token;

  final bool isInitializer;

  final bool isSuper;

  ThisAccessor(this.helper, this.token, this.isInitializer,
      {this.isSuper: false});

  String get plainNameForRead {
    return unsupported("${isSuper ? 'super' : 'this'}.plainNameForRead",
        offsetForToken(token), uri);
  }

  Expression buildSimpleRead() {
    if (!isSuper) {
      return new ShadowThisExpression()..fileOffset = offsetForToken(token);
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
      IncompleteSend send, int operatorOffset, bool isNullAware) {
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
      return helper.buildMethodInvocation(new ShadowThisExpression(), name,
          send.arguments, offsetForToken(send.token),
          isSuper: isSuper, interfaceTarget: getter);
    } else {
      Member setter =
          helper.lookupInstanceMember(name, isSuper: isSuper, isSetter: true);
      if (isSuper) {
        return new SuperPropertyAccessor(
            helper, send.token, name, getter, setter);
      } else {
        return new ThisPropertyAccessor(
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
          new ShadowThisExpression(), callName, arguments, offset,
          isImplicitCall: true);
    }
  }

  Initializer buildConstructorInitializer(
      int offset, Name name, Arguments arguments) {
    Constructor constructor = helper.lookupConstructor(name, isSuper: isSuper);
    LocatedMessage argMessage;
    if (constructor != null) {
      argMessage = helper.checkArguments(
          new FunctionTypeAccessor.fromNode(constructor.function),
          arguments,
          CalleeDesignation.Constructor,
          offset, <TypeParameter>[]);
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

  toString() {
    int offset = offsetForToken(token);
    return "ThisAccessor($offset${isSuper ? ', super' : ''})";
  }
}

abstract class IncompleteSend<Arguments> extends FastaAccessor<Arguments> {
  final BuilderHelper helper;

  @override
  final Token token;

  final Name name;

  IncompleteSend(this.helper, this.token, this.name);

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware});

  Arguments get arguments => null;
}

class IncompleteError<Arguments> extends IncompleteSend<Arguments>
    with ErrorAccessor<Arguments> {
  final Message message;

  IncompleteError(BuilderHelper helper, Token token, this.message)
      : super(helper, token, null);

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
}

class SendAccessor<Arguments> extends IncompleteSend<Arguments> {
  @override
  final Arguments arguments;

  SendAccessor(BuilderHelper helper, Token token, Name name, this.arguments)
      : super(helper, token, name) {
    assert(arguments != null);
  }

  String get plainNameForRead => name.name;

  Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", offsetForToken(token), uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return unsupported("buildAssignment", offsetForToken(token), uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is FastaAccessor) {
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

  toString() {
    int offset = offsetForToken(token);
    return "SendAccessor($offset, $name, $arguments)";
  }
}

class IncompletePropertyAccessor<Arguments> extends IncompleteSend<Arguments> {
  IncompletePropertyAccessor(BuilderHelper helper, Token token, Name name)
      : super(helper, token, name);

  String get plainNameForRead => name.name;

  Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", offsetForToken(token), uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return unsupported("buildAssignment", offsetForToken(token), uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is FastaAccessor) {
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

    return PropertyAccessor.make(
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

  toString() {
    int offset = offsetForToken(token);
    return "IncompletePropertyAccessor($offset, $name)";
  }
}

class IndexAccessor<Arguments> extends kernel.IndexAccessor<Arguments>
    with FastaAccessor<Arguments> {
  final BuilderHelper helper;

  IndexAccessor.internal(this.helper, Token token, Expression receiver,
      Expression index, Procedure getter, Procedure setter)
      : super.internal(helper, receiver, index, getter, setter, token);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, forest.readOffset(arguments),
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
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowIndexAssign(receiver, index, rhs);
}

class PropertyAccessor<Arguments> extends kernel.PropertyAccessor<Arguments>
    with FastaAccessor<Arguments> {
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
      return unsupported("ThisExpression", offsetForToken(token), helper.uri);
    } else {
      return isNullAware
          ? new NullAwarePropertyAccessor(
              helper, token, receiver, name, getter, setter, null)
          : new PropertyAccessor.internal(
              helper, token, receiver, name, getter, setter);
    }
  }

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowPropertyAssign(receiver, rhs);
}

class StaticAccessor<Arguments> extends kernel.StaticAccessor<Arguments>
    with FastaAccessor<Arguments> {
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
      return unhandled("${builder.runtimeType}", "StaticAccessor.fromBuilder",
          offsetForToken(token), helper.uri);
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

  toString() => "StaticAccessor()";

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowStaticAssignment(rhs);
}

class LoadLibraryAccessor<Arguments> extends kernel
    .LoadLibraryAccessor<Arguments> with FastaAccessor<Arguments> {
  LoadLibraryAccessor(
      BuilderHelper helper, Token token, LoadLibraryBuilder builder)
      : super(helper, token, builder);

  String get plainNameForRead => 'loadLibrary';

  Expression doInvocation(int offset, Arguments arguments) {
    if (forest.argumentsPositional(arguments).length > 0 ||
        forest.argumentsNamed(arguments).length > 0) {
      helper.addProblemErrorIfConst(
          messageLoadLibraryTakesNoArguments, offset, 'loadLibrary'.length);
    }
    return builder.createLoadLibrary(offset, forest);
  }
}

class DeferredAccessor<Arguments> extends kernel.DeferredAccessor<Arguments>
    with FastaAccessor<Arguments> {
  DeferredAccessor(BuilderHelper helper, Token token, PrefixBuilder builder,
      FastaAccessor expression)
      : super(helper, token, builder, expression);

  String get plainNameForRead {
    return unsupported(
        "deferredAccessor.plainNameForRead", offsetForToken(token), uri);
  }

  FastaAccessor get accessor => super.accessor;

  buildPropertyAccess(
      IncompleteSend send, int operatorOffset, bool isNullAware) {
    var propertyAccess =
        accessor.buildPropertyAccess(send, operatorOffset, isNullAware);
    if (propertyAccess is FastaAccessor) {
      return new DeferredAccessor(helper, token, builder, propertyAccess);
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
            accessor.buildTypeWithBuiltArguments(arguments,
                nonInstanceAccessIsError: nonInstanceAccessIsError),
            builder.name),
        offsetForToken(token),
        lengthForToken(token));
    return const InvalidType();
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return helper.wrapInDeferredCheck(
        accessor.doInvocation(offset, arguments), builder, token.charOffset);
  }
}

class SuperPropertyAccessor<Arguments> extends kernel
    .SuperPropertyAccessor<Arguments> with FastaAccessor<Arguments> {
  SuperPropertyAccessor(BuilderHelper helper, Token token, Name name,
      Member getter, Member setter)
      : super(helper, name, getter, setter, token);

  String get plainNameForRead => name.name;

  Expression doInvocation(int offset, Arguments arguments) {
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

  toString() => "SuperPropertyAccessor()";

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowPropertyAssign(null, rhs, isSuper: true);
}

class ThisIndexAccessor<Arguments> extends kernel.ThisIndexAccessor<Arguments>
    with FastaAccessor<Arguments> {
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

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowIndexAssign(null, index, rhs);
}

class SuperIndexAccessor<Arguments> extends kernel.SuperIndexAccessor<Arguments>
    with FastaAccessor<Arguments> {
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

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowIndexAssign(null, index, rhs, isSuper: true);
}

class ThisPropertyAccessor<Arguments> extends kernel
    .ThisPropertyAccessor<Arguments> with FastaAccessor<Arguments> {
  final BuilderHelper helper;

  ThisPropertyAccessor(
      this.helper, Token token, Name name, Member getter, Member setter)
      : super(helper, name, getter, setter, token);

  String get plainNameForRead => name.name;

  bool get isThisPropertyAccessor => true;

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
        new ShadowThisExpression(), name, arguments, offset,
        interfaceTarget: interfaceTarget);
  }

  toString() => "ThisPropertyAccessor()";

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowPropertyAssign(null, rhs);
}

class NullAwarePropertyAccessor<Arguments> extends kernel
    .NullAwarePropertyAccessor<Arguments> with FastaAccessor<Arguments> {
  final BuilderHelper helper;

  NullAwarePropertyAccessor(this.helper, Token token, Expression receiver,
      Name name, Member getter, Member setter, DartType type)
      : super(helper, receiver, name, getter, setter, type, token);

  String get plainNameForRead => name.name;

  Expression doInvocation(int offset, Arguments arguments) {
    return unimplemented("doInvocation", offset, uri);
  }

  toString() => "NullAwarePropertyAccessor()";

  @override
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowPropertyAssign(receiverExpression, rhs);
}

int adjustForImplicitCall(String name, int offset) {
  // Normally the offset is at the start of the token, but in this case,
  // because we insert a '.call', we want it at the end instead.
  return offset + (name?.length ?? 0);
}

class VariableAccessor<Arguments> extends kernel.VariableAccessor<Arguments>
    with FastaAccessor<Arguments> {
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
  ShadowComplexAssignment startComplexAssignment(Expression rhs) =>
      new ShadowVariableAssignment(rhs);
}

class ReadOnlyAccessor<Arguments> extends kernel.ReadOnlyAccessor<Arguments>
    with FastaAccessor<Arguments> {
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

class LargeIntAccessor<Arguments> extends kernel.DelayedErrorAccessor<Arguments>
    with FastaAccessor<Arguments> {
  final String plainNameForRead = null;

  LargeIntAccessor(BuilderHelper helper, Token token) : super(helper, token);

  @override
  Expression buildError() {
    return helper.buildCompileTimeError(
        templateIntegerLiteralIsOutOfRange.withArguments(token),
        offsetForToken(token),
        lengthForToken(token));
  }

  Expression doInvocation(int offset, Arguments arguments) => buildError();
}

class ParenthesizedExpression<Arguments> extends ReadOnlyAccessor<Arguments> {
  ParenthesizedExpression(
      BuilderHelper helper, Expression expression, Token token)
      : super(helper, expression, null, token);

  Expression makeInvalidWrite(Expression value) {
    return helper.deprecated_buildCompileTimeError(
        "Can't assign to a parenthesized expression.", offsetForToken(token));
  }
}

class TypeDeclarationAccessor<Arguments> extends ReadOnlyAccessor<Arguments> {
  /// The import prefix preceding the [declaration] reference, or `null` if
  /// the reference is not prefixed.
  final PrefixBuilder prefix;

  /// The offset at which the [declaration] is referenced by this accessor,
  /// or `-1` if the reference is implicit.
  final int declarationReferenceOffset;

  final TypeDeclarationBuilder declaration;

  TypeDeclarationAccessor(
      BuilderHelper helper,
      this.prefix,
      this.declarationReferenceOffset,
      this.declaration,
      String plainNameForRead,
      Token token)
      : super(helper, null, plainNameForRead, token);

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
        if (send is IncompletePropertyAccessor) {
          accessor = new UnresolvedAccessor(helper, name, send.token);
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
    LibraryBuilder helperLibrary = helper.library;
    if (arguments == null &&
        helperLibrary is KernelLibraryBuilder &&
        helperLibrary.loader.target.strongMode) {
      TypeDeclarationBuilder typeDeclaration = declaration;
      if (typeDeclaration is KernelClassBuilder) {
        typeDeclaration.calculatedBounds ??= calculateBoundsForDeclaration(
            typeDeclaration,
            helperLibrary.loader.target.dynamicType,
            helperLibrary.loader.target.bottomType,
            helperLibrary.loader.target.objectClassBuilder);
        type = typeDeclaration.buildType(
            helper.library, typeDeclaration.calculatedBounds);
      } else if (typeDeclaration is KernelFunctionTypeAliasBuilder) {
        typeDeclaration.calculatedBounds ??= calculateBoundsForDeclaration(
            typeDeclaration,
            helperLibrary.loader.target.dynamicType,
            helperLibrary.loader.target.bottomType,
            helperLibrary.loader.target.objectClassBuilder);
        type = typeDeclaration.buildType(
            helper.library, typeDeclaration.calculatedBounds);
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

  DartType buildType(List<KernelTypeBuilder> arguments,
      {bool nonInstanceAccessIsError: false}) {
    if (arguments != null) {
      int expected = 0;
      if (declaration is KernelClassBuilder) {
        expected = declaration.target.typeParameters.length;
      } else if (declaration is FunctionTypeAliasBuilder) {
        expected = declaration.target.typeParameters.length;
      } else if (declaration is KernelTypeVariableBuilder) {
        // Type arguments on a type variable - error reported elsewhere.
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
    DartType type = declaration.buildType(helper.library, arguments);
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

class UnresolvedAccessor<Arguments> extends FastaAccessor<Arguments>
    with ErrorAccessor<Arguments> {
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
}

bool isFieldOrGetter(Member member) {
  return member is Field || (member is Procedure && member.isGetter);
}
