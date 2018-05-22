// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'expression_generator.dart';

abstract class BuilderHelper<Expression, Statement, Arguments> {
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

  Expression buildCompileTimeError(Message message, int charOffset, int length,
      {List<LocatedMessage> context});

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

// TODO(ahe): Merge this into [Generator] when all uses have been updated.
abstract class FastaAccessor<Arguments> implements Accessor<Arguments> {
  BuilderHelper<dynamic, dynamic, Arguments> get helper;

  // TODO(ahe): Change type arguments.
  Forest<kernel.Expression, kernel.Statement, Token, Arguments> get forest =>
      helper.forest;

  String get plainNameForRead;

  String get debugName;

  Uri get uri => helper.uri;

  String get plainNameForWrite => plainNameForRead;

  bool get isInitializer => false;

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

  kernel.Expression makeInvalidRead() {
    return buildThrowNoSuchMethodError(
        forest.literalNull(token), forest.argumentsEmpty(noLocation),
        isGetter: true);
  }

  kernel.Expression makeInvalidWrite(kernel.Expression value) {
    return buildThrowNoSuchMethodError(forest.literalNull(token),
        forest.arguments(<kernel.Expression>[value], noLocation),
        isSetter: true);
  }

  /* kernel.Expression | FastaAccessor | Initializer */ doInvocation(
      int offset, Arguments arguments);

  /* kernel.Expression | FastaAccessor */ buildPropertyAccess(
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

  /* kernel.Expression | FastaAccessor */ buildThrowNoSuchMethodError(
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

  @override
  ShadowComplexAssignment startComplexAssignment(kernel.Expression rhs) =>
      new ShadowIllegalAssignment(rhs);

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

int adjustForImplicitCall(String name, int offset) {
  // Normally the offset is at the start of the token, but in this case,
  // because we insert a '.call', we want it at the end instead.
  return offset + (name?.length ?? 0);
}

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

class TypeDeclarationAccessor<Arguments>
    extends ReadOnlyAccessGenerator<Arguments> {
  /// The import prefix preceding the [declaration] reference, or `null` if
  /// the reference is not prefixed.
  final PrefixBuilder prefix;

  /// The offset at which the [declaration] is referenced by this accessor,
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

      FastaAccessor accessor;
      if (builder == null) {
        // If we find a setter, [builder] is an [AccessErrorBuilder], not null.
        if (send is IncompletePropertyAccessor) {
          accessor = new UnresolvedNameGenerator(helper, send.token, name);
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
        accessor = new StaticAccessGenerator.fromBuilder(
            helper, builder, send.token, setter);
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

bool isFieldOrGetter(Member member) {
  return member is Field || (member is Procedure && member.isGetter);
}
