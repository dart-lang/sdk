// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help generate expression.
library fasta.expression_generator;

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart'
    show
        Message,
        Template,
        messageCantUsePrefixAsExpression,
        messageCantUsePrefixWithNullAware,
        messageIllegalAssignmentToNonAssignable,
        messageInvalidInitializer,
        messageNotAConstantExpression,
        templateCantUseDeferredPrefixAsConstant,
        templateDeferredTypeAnnotation,
        templateIntegerLiteralIsOutOfRange,
        templateMissingExplicitTypeArguments,
        templateNotAPrefixInTypeAnnotation,
        templateNotAType,
        templateUnresolvedPrefixInTypeAnnotation;

import '../names.dart'
    show
        ampersandName,
        barName,
        caretName,
        divisionName,
        leftShiftName,
        lengthName,
        minusName,
        multiplyName,
        mustacheName,
        percentName,
        plusName,
        rightShiftName;

import '../parser.dart' show lengthForToken, lengthOfSpan, offsetForToken;

import '../problems.dart' show unhandled, unsupported;

import '../type_inference/type_inferrer.dart' show TypeInferrer;

import 'constness.dart' show Constness;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'forest.dart'
    show
        Forest,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder,
        UnlinkedDeclaration;

import 'kernel_api.dart' show printQualifiedNameOn;

import 'kernel_ast_api.dart'
    show
        Arguments,
        ArgumentsJudgment,
        DartType,
        DynamicType,
        Expression,
        Initializer,
        InvalidConstructorInvocationJudgment,
        InvalidType,
        Member,
        Name,
        Node,
        Procedure,
        StaticInvocationJudgment,
        SyntheticExpressionJudgment,
        TreeNode,
        TypeParameterType,
        UnresolvedTargetInvocationJudgment,
        UnresolvedVariableUnaryJudgment,
        VariableDeclaration;

import 'kernel_builder.dart'
    show
        AccessErrorBuilder,
        BuiltinTypeBuilder,
        ClassBuilder,
        Declaration,
        DynamicTypeBuilder,
        FunctionTypeAliasBuilder,
        InvalidTypeBuilder,
        KernelClassBuilder,
        KernelFunctionTypeAliasBuilder,
        KernelTypeVariableBuilder,
        TypeVariableBuilder;

import 'kernel_expression_generator.dart'
    show IncompleteSendGenerator, SendAccessGenerator;

export 'kernel_expression_generator.dart'
    show
        IncompleteErrorGenerator,
        IncompletePropertyAccessGenerator,
        IncompleteSendGenerator,
        ParenthesizedExpressionGenerator,
        SendAccessGenerator,
        ThisAccessGenerator,
        buildIsNull;

abstract class ExpressionGenerator {
  /// Builds a [Expression] representing a read from the generator.
  Expression buildSimpleRead();

  /// Builds a [Expression] representing an assignment with the generator on
  /// the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  Expression buildAssignment(Expression value, {bool voidContext});

  /// Returns a [Expression] representing a null-aware assignment (`??=`) with
  /// the generator on the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  ///
  /// [type] is the static type of the RHS.
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext});

  /// Returns a [Expression] representing a compound assignment (e.g. `+=`)
  /// with the generator on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset,
      bool voidContext,
      Procedure interfaceTarget,
      bool isPreIncDec});

  /// Returns a [Expression] representing a pre-increment or pre-decrement of
  /// the generator.
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext, Procedure interfaceTarget});

  /// Returns a [Expression] representing a post-increment or post-decrement of
  /// the generator.
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext, Procedure interfaceTarget});

  /// Returns a [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  Expression makeInvalidRead();

  /// Returns a [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  Expression makeInvalidWrite(Expression value);
}

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
abstract class Generator implements ExpressionGenerator {
  final ExpressionGeneratorHelper helper;

  final Token token;

  Generator(this.helper, this.token);

  Forest get forest => helper.forest;

  String get plainNameForRead;

  String get debugName;

  Uri get uri => helper.uri;

  String get plainNameForWrite => plainNameForRead;

  bool get isInitializer => false;

  Expression buildForEffect() => buildSimpleRead();

  Node get fieldInitializerTarget => null;

  Expression buildFieldInitializerError() {
    int offset = offsetForToken(token);
    return helper.buildCompileTimeError(
        messageInvalidInitializer, offset, lengthForToken(token));
  }

  /* Expression | Generator | Initializer */ doInvocation(
      int offset, ArgumentsJudgment arguments);

  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is SendAccessGenerator) {
      return helper.buildMethodInvocation(
          buildSimpleRead(),
          send.name,
          send.arguments as dynamic /* TODO(ahe): Remove this cast. */,
          offsetForToken(send.token),
          isNullAware: isNullAware);
    } else {
      if (helper.constantContext != ConstantContext.none &&
          send.name != lengthName) {
        helper.addCompileTimeError(
            messageNotAConstantExpression, offsetForToken(token), token.length);
      }
      return PropertyAccessGenerator.make(helper, send.token, buildSimpleRead(),
          send.name, null, null, isNullAware);
    }
  }

  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false, TypeInferrer typeInferrer}) {
    helper.addProblem(templateNotAType.withArguments(token.lexeme),
        offsetForToken(token), lengthForToken(token));
    return const InvalidType();
  }

  /* Expression | Generator */ Object prefixedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(helper, name, this, false);
  }

  Expression invokeConstructor(
      List<DartType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    if (typeArguments != null) {
      assert(forest.argumentsTypeArguments(arguments).isEmpty);
      forest.argumentsSetTypeArguments(arguments, typeArguments);
    }
    var error = helper.throwNoSuchMethodError(
        forest.literalNull(token),
        name == "" ? plainNameForRead : "${plainNameForRead}.$name",
        arguments,
        nameToken.charOffset);

    return new InvalidConstructorInvocationJudgment(error, null, arguments);
  }

  /// This generator was unexpectedly used as a prefix in a type name.
  /// Store its resolution anyway.
  void storeUnexpectedTypePrefix(TypeInferrer typeInferrer) {
    typeInferrer.storeUnresolved(token);
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

abstract class VariableUseGenerator implements Generator {
  factory VariableUseGenerator(ExpressionGeneratorHelper helper, Token token,
      VariableDeclaration variable,
      [DartType promotedType]) {
    return helper.forest
        .variableUseGenerator(helper, token, variable, promotedType);
  }

  @override
  String get debugName => "VariableUseGenerator";
}

abstract class PropertyAccessGenerator implements Generator {
  factory PropertyAccessGenerator.internal(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiver,
      Name name,
      Member getter,
      Member setter) {
    return helper.forest
        .propertyAccessGenerator(helper, token, receiver, name, getter, setter);
  }

  static Generator make(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiver,
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

  @override
  String get debugName => "PropertyAccessGenerator";

  @override
  bool get isThisPropertyAccess => false;
}

/// Special case of [PropertyAccessGenerator] to avoid creating an indirect
/// access to 'this'.
abstract class ThisPropertyAccessGenerator implements Generator {
  factory ThisPropertyAccessGenerator(ExpressionGeneratorHelper helper,
      Token token, Name name, Member getter, Member setter) {
    return helper.forest
        .thisPropertyAccessGenerator(helper, token, name, getter, setter);
  }

  @override
  String get debugName => "ThisPropertyAccessGenerator";

  @override
  bool get isThisPropertyAccess => true;
}

abstract class NullAwarePropertyAccessGenerator implements Generator {
  factory NullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiverExpression,
      Name name,
      Member getter,
      Member setter,
      DartType type) {
    return helper.forest.nullAwarePropertyAccessGenerator(
        helper, token, receiverExpression, name, getter, setter, type);
  }

  @override
  String get debugName => "NullAwarePropertyAccessGenerator";
}

abstract class SuperPropertyAccessGenerator implements Generator {
  factory SuperPropertyAccessGenerator(ExpressionGeneratorHelper helper,
      Token token, Name name, Member getter, Member setter) {
    return helper.forest
        .superPropertyAccessGenerator(helper, token, name, getter, setter);
  }

  @override
  String get debugName => "SuperPropertyAccessGenerator";
}

abstract class IndexedAccessGenerator implements Generator {
  factory IndexedAccessGenerator.internal(
      ExpressionGeneratorHelper helper,
      Token openSquareBracket,
      Token closeSquareBracket,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return helper.forest.indexedAccessGenerator(helper, openSquareBracket,
        closeSquareBracket, receiver, index, getter, setter);
  }

  static Generator make(
      ExpressionGeneratorHelper helper,
      Token openSquareBracket,
      Token closeSquareBracket,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisIndexedAccessGenerator(
          helper, openSquareBracket, closeSquareBracket, index, getter, setter);
    } else {
      return new IndexedAccessGenerator.internal(helper, openSquareBracket,
          closeSquareBracket, receiver, index, getter, setter);
    }
  }

  @override
  String get plainNameForRead => "[]";

  @override
  String get plainNameForWrite => "[]=";

  @override
  String get debugName => "IndexedAccessGenerator";
}

/// Special case of [IndexedAccessGenerator] to avoid creating an indirect
/// access to 'this'.
abstract class ThisIndexedAccessGenerator implements Generator {
  factory ThisIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token openSquareBracket,
      Token closeSquareBracket,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return helper.forest.thisIndexedAccessGenerator(
        helper, openSquareBracket, closeSquareBracket, index, getter, setter);
  }

  @override
  String get plainNameForRead => "[]";

  @override
  String get plainNameForWrite => "[]=";

  @override
  String get debugName => "ThisIndexedAccessGenerator";
}

abstract class SuperIndexedAccessGenerator implements Generator {
  factory SuperIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token openSquareBracket,
      Token closeSquareBracket,
      Expression index,
      Member getter,
      Member setter) {
    return helper.forest.superIndexedAccessGenerator(
        helper, openSquareBracket, closeSquareBracket, index, getter, setter);
  }

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  String get debugName => "SuperIndexedAccessGenerator";
}

abstract class StaticAccessGenerator implements Generator {
  factory StaticAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      Member readTarget, Member writeTarget) {
    return helper.forest
        .staticAccessGenerator(helper, token, readTarget, writeTarget);
  }

  factory StaticAccessGenerator.fromBuilder(ExpressionGeneratorHelper helper,
      Declaration declaration, Token token, Declaration builderSetter) {
    if (declaration is AccessErrorBuilder) {
      AccessErrorBuilder error = declaration;
      declaration = error.builder;
      // We should only see an access error here if we've looked up a setter
      // when not explicitly looking for a setter.
      assert(declaration.isSetter);
    } else if (declaration.target == null) {
      return unhandled(
          "${declaration.runtimeType}",
          "StaticAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri);
    }
    Member getter = declaration.target.hasGetter ? declaration.target : null;
    Member setter = declaration.target.hasSetter ? declaration.target : null;
    if (setter == null) {
      if (builderSetter?.target?.hasSetter ?? false) {
        setter = builderSetter.target;
      }
    }
    return new StaticAccessGenerator(helper, token, getter, setter);
  }

  Member get readTarget;

  @override
  String get debugName => "StaticAccessGenerator";
}

abstract class LoadLibraryGenerator implements Generator {
  factory LoadLibraryGenerator(ExpressionGeneratorHelper helper, Token token,
      LoadLibraryBuilder builder) {
    return helper.forest.loadLibraryGenerator(helper, token, builder);
  }

  @override
  String get plainNameForRead => 'loadLibrary';

  @override
  String get debugName => "LoadLibraryGenerator";
}

abstract class DeferredAccessGenerator implements Generator {
  factory DeferredAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      PrefixUseGenerator prefixGenerator, Generator suffixGenerator) {
    return helper.forest.deferredAccessGenerator(
        helper, token, prefixGenerator, suffixGenerator);
  }

  PrefixUseGenerator get prefixGenerator;

  Generator get suffixGenerator;

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    var propertyAccess =
        suffixGenerator.buildPropertyAccess(send, operatorOffset, isNullAware);
    if (propertyAccess is Generator) {
      return new DeferredAccessGenerator(
          helper, token, prefixGenerator, propertyAccess);
    } else {
      Expression expression = propertyAccess;
      return helper.wrapInDeferredCheck(
          expression, prefixGenerator.prefix, token.charOffset);
    }
  }

  @override
  String get plainNameForRead {
    return unsupported(
        "deferredAccessor.plainNameForRead", offsetForToken(token), uri);
  }

  @override
  String get debugName => "DeferredAccessGenerator";

  @override
  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false, TypeInferrer typeInferrer}) {
    helper.addProblem(
        templateDeferredTypeAnnotation.withArguments(
            suffixGenerator.buildTypeWithBuiltArguments(arguments,
                nonInstanceAccessIsError: nonInstanceAccessIsError,
                typeInferrer: typeInferrer),
            prefixGenerator.plainNameForRead),
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token));
    return const InvalidType();
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return helper.wrapInDeferredCheck(
        suffixGenerator.doInvocation(offset, arguments),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression invokeConstructor(
      List<DartType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    return helper.wrapInDeferredCheck(
        suffixGenerator.invokeConstructor(typeArguments, name, arguments,
            nameToken, nameLastToken, constness),
        prefixGenerator.prefix,
        offsetForToken(suffixGenerator.token));
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", prefixGenerator: ");
    sink.write(prefixGenerator);
    sink.write(", suffixGenerator: ");
    sink.write(suffixGenerator);
  }
}

abstract class TypeUseGenerator implements Generator {
  factory TypeUseGenerator(ExpressionGeneratorHelper helper, Token token,
      TypeDeclarationBuilder declaration, String plainNameForRead) {
    return helper.forest
        .typeUseGenerator(helper, token, declaration, plainNameForRead);
  }

  TypeDeclarationBuilder get declaration;

  @override
  String get debugName => "TypeUseGenerator";

  @override
  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false, TypeInferrer typeInferrer}) {
    var declaration = this.declaration;
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
        return unhandled("${declaration.runtimeType}",
            "TypeUseGenerator.buildType", offsetForToken(token), helper.uri);
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
    } else if (declaration.typeVariablesCount != 0) {
      helper.addProblem(
          templateMissingExplicitTypeArguments
              .withArguments(declaration.typeVariablesCount),
          offsetForToken(token),
          lengthForToken(token));
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
    TreeNode declarationTarget;
    Object declarationBinder;
    if (declaration is KernelTypeVariableBuilder &&
        declaration.binder != null) {
      declarationBinder = declaration.binder;
    } else if (declaration is DynamicTypeBuilder ||
        declaration is InvalidTypeBuilder) {
      // There's no target associated with these types, so we have to let
      // the analyzer fill it in.
    } else if (declaration is ClassBuilder ||
        declaration is TypeVariableBuilder ||
        declaration is FunctionTypeAliasBuilder) {
      declarationTarget = declaration.target;
    } else {
      return unhandled(
          "${declaration.runtimeType}",
          "TypeUseGenerator.buildTypeWithBuiltArguments",
          offsetForToken(token),
          helper.uri);
    }
    typeInferrer?.storeTypeReference(token.charOffset, token.isSynthetic,
        declarationTarget, declarationBinder, type);
    if (type is TypeParameterType) {
      return helper.validatedTypeVariableUse(
          type, offsetForToken(token), nonInstanceAccessIsError);
    }
    return type;
  }

  @override
  Expression invokeConstructor(
      List<DartType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    helper.storeTypeUse(offsetForToken(token), declaration.target);
    return helper.buildConstructorInvocation(
        declaration,
        nameToken,
        nameLastToken,
        arguments,
        name,
        typeArguments,
        offsetForToken(nameToken ?? token),
        constness);
  }

  @override
  void storeUnexpectedTypePrefix(TypeInferrer typeInferrer) {
    typeInferrer.storeTypeReference(offsetForToken(token), token.isSynthetic,
        declaration.target, null, const DynamicType());
  }
}

abstract class ReadOnlyAccessGenerator implements Generator {
  factory ReadOnlyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      Expression expression, String plainNameForRead) {
    return helper.forest
        .readOnlyAccessGenerator(helper, token, expression, plainNameForRead);
  }

  @override
  String get debugName => "ReadOnlyAccessGenerator";
}

abstract class LargeIntAccessGenerator implements Generator {
  factory LargeIntAccessGenerator(
      ExpressionGeneratorHelper helper, Token token) {
    return helper.forest.largeIntAccessGenerator(helper, token);
  }

  // TODO(ahe): This should probably be calling unhandled.
  @override
  String get plainNameForRead => null;

  @override
  String get debugName => "LargeIntAccessGenerator";

  Expression buildError() {
    return helper.buildCompileTimeError(
        templateIntegerLiteralIsOutOfRange.withArguments(token),
        offsetForToken(token),
        lengthForToken(token));
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return new SyntheticExpressionJudgment(buildError());
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", lexeme: ");
    sink.write(token.lexeme);
  }
}

abstract class ErroneousExpressionGenerator implements Generator {
  /// Pass [arguments] that must be evaluated before throwing an error.  At
  /// most one of [isGetter] and [isSetter] should be true and they're passed
  /// to [ExpressionGeneratorHelper.throwNoSuchMethodError] if it is used.
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset});

  Name get name => unsupported("name", offsetForToken(token), uri);

  @override
  String get plainNameForRead => name.name;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware}) => this;

  @override
  Expression buildFieldInitializerError() {
    return buildError(forest.argumentsEmpty(token, token), isSetter: true);
  }

  @override
  doInvocation(int offset, Arguments arguments) {
    return new SyntheticExpressionJudgment(
        buildError(arguments, offset: offset));
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    return send.withReceiver(buildSimpleRead(), operatorOffset,
        isNullAware: isNullAware);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return new SyntheticExpressionJudgment(buildError(
        forest.arguments(<Expression>[value], token, token),
        isSetter: true));
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: -1,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return new SyntheticExpressionJudgment(buildError(
        forest.arguments(<Expression>[value], token, token),
        isGetter: true));
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    var error = buildError(
        forest.arguments(
            <Expression>[forest.literalInt(1, null)..fileOffset = offset],
            token,
            token),
        isGetter: true);
    return new UnresolvedVariableUnaryJudgment(
        error, token?.offset, token?.isSynthetic)
      ..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    var error = buildError(
        forest.arguments(
            <Expression>[forest.literalInt(1, null)..fileOffset = offset],
            token,
            token),
        isGetter: true);
    return new UnresolvedVariableUnaryJudgment(
        error, token?.offset, token?.isSynthetic)
      ..fileOffset = offset;
  }

  @override
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new SyntheticExpressionJudgment(buildError(
        forest.arguments(<Expression>[value], token, token),
        isSetter: true));
  }

  @override
  Expression buildSimpleRead() => new SyntheticExpressionJudgment(
      buildError(forest.argumentsEmpty(token, token), isGetter: true));

  @override
  Expression makeInvalidRead() => new SyntheticExpressionJudgment(
      buildError(forest.argumentsEmpty(token, token), isGetter: true));

  @override
  Expression makeInvalidWrite(Expression value) {
    return new SyntheticExpressionJudgment(buildError(
        forest.arguments(<Expression>[value], token, token),
        isSetter: true));
  }

  @override
  Expression invokeConstructor(
      List<DartType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    helper.storeTypeUse(offsetForToken(token), const InvalidType());
    if (typeArguments != null) {
      assert(forest.argumentsTypeArguments(arguments).isEmpty);
      forest.argumentsSetTypeArguments(arguments, typeArguments);
    }
    var error = buildError(arguments);
    return new InvalidConstructorInvocationJudgment(error, null, arguments);
  }
}

abstract class UnresolvedNameGenerator implements ErroneousExpressionGenerator {
  factory UnresolvedNameGenerator(
      ExpressionGeneratorHelper helper, Token token, Name name) {
    return helper.forest.unresolvedNameGenerator(helper, token, name);
  }

  @override
  String get debugName => "UnresolvedNameGenerator";

  @override
  Expression doInvocation(int charOffset, Arguments arguments) {
    return new UnresolvedTargetInvocationJudgment(
        buildError(arguments, offset: charOffset), arguments)
      ..fileOffset = arguments.fileOffset;
  }

  @override
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    offset ??= offsetForToken(this.token);
    return helper.throwNoSuchMethodError(
        forest.literalNull(null)..fileOffset = offset,
        plainNameForRead,
        arguments,
        offset,
        isGetter: isGetter,
        isSetter: isSetter);
  }

  @override
  /* Expression | Generator */ Object prefixedLookup(Token name) {
    helper.storeUnresolved(token);
    return new UnexpectedQualifiedUseGenerator(helper, name, this, true);
  }
}

abstract class UnlinkedGenerator implements Generator {
  factory UnlinkedGenerator(ExpressionGeneratorHelper helper, Token token,
      UnlinkedDeclaration declaration) {
    return helper.forest.unlinkedGenerator(helper, token, declaration);
  }

  UnlinkedDeclaration get declaration;

  @override
  String get plainNameForRead => declaration.name;

  @override
  String get debugName => "UnlinkedGenerator";

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(declaration.name);
  }
}

abstract class ContextAwareGenerator implements Generator {
  Generator get generator;

  @override
  String get plainNameForRead {
    return unsupported("plainNameForRead", token.charOffset, helper.uri);
  }

  @override
  Expression doInvocation(int charOffset, Arguments arguments) {
    return unhandled("${runtimeType}", "doInvocation", charOffset, uri);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return makeInvalidWrite(value);
  }

  @override
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return makeInvalidWrite(value);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: -1,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return makeInvalidWrite(value);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    return makeInvalidWrite(null);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    return makeInvalidWrite(null);
  }

  @override
  makeInvalidRead() {
    return unsupported("makeInvalidRead", token.charOffset, helper.uri);
  }

  @override
  Expression makeInvalidWrite(Expression value) {
    return helper.buildCompileTimeErrorExpression(
        messageIllegalAssignmentToNonAssignable, offsetForToken(token),
        length: token?.length);
  }
}

abstract class DelayedAssignment implements ContextAwareGenerator {
  factory DelayedAssignment(ExpressionGeneratorHelper helper, Token token,
      Generator generator, Expression value, String assignmentOperator) {
    return helper.forest
        .delayedAssignment(helper, token, generator, value, assignmentOperator);
  }

  Expression get value;

  String get assignmentOperator;

  @override
  String get debugName => "DelayedAssignment";

  @override
  Expression buildSimpleRead() {
    return handleAssignment(false);
  }

  @override
  Expression buildForEffect() {
    return handleAssignment(true);
  }

  Expression handleAssignment(bool voidContext) {
    if (helper.constantContext != ConstantContext.none) {
      return helper.buildCompileTimeErrorExpression(
          messageNotAConstantExpression, offsetForToken(token),
          length: token.length);
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

  Initializer buildFieldInitializer() {
    if (!identical("=", assignmentOperator) ||
        !generator.isThisPropertyAccess) {
      return helper.buildInvalidFieldInitializer(
          offsetForToken(token),
          false,
          generator.fieldInitializerTarget,
          value,
          generator.buildFieldInitializerError());
    }
    return helper.buildFieldInitializer(
        false, generator.plainNameForRead, offsetForToken(token), value);
  }
}

abstract class DelayedPostfixIncrement implements ContextAwareGenerator {
  factory DelayedPostfixIncrement(ExpressionGeneratorHelper helper, Token token,
      Generator generator, Name binaryOperator, Procedure interfaceTarget) {
    return helper.forest.delayedPostfixIncrement(
        helper, token, generator, binaryOperator, interfaceTarget);
  }

  Name get binaryOperator;

  Procedure get interfaceTarget;

  @override
  String get debugName => "DelayedPostfixIncrement";

  @override
  Expression buildSimpleRead() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: offsetForToken(token),
        voidContext: false,
        interfaceTarget: interfaceTarget);
  }

  @override
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

abstract class PrefixUseGenerator implements Generator {
  factory PrefixUseGenerator(
      ExpressionGeneratorHelper helper, Token token, PrefixBuilder prefix) {
    return helper.forest.prefixUseGenerator(helper, token, prefix);
  }

  PrefixBuilder get prefix;

  @override
  String get plainNameForRead => prefix.name;

  @override
  String get debugName => "PrefixUseGenerator";

  @override
  Expression buildSimpleRead() => makeInvalidRead();

  @override
  /* Expression | Generator */ Object prefixedLookup(Token name) {
    if (helper.constantContext != ConstantContext.none && prefix.deferred) {
      helper.addProblem(
          templateCantUseDeferredPrefixAsConstant.withArguments(token),
          offsetForToken(token),
          lengthForToken(token));
    }
    Object result = helper.scopeLookup(prefix.exportScope, name.lexeme, name,
        isQualified: true, prefix: prefix);
    if (prefix.deferred) {
      if (result is Generator) {
        if (result is! LoadLibraryGenerator) {
          result = new DeferredAccessGenerator(helper, name, this, result);
        }
      } else {
        helper.wrapInDeferredCheck(result, prefix, offsetForToken(token));
      }
    }
    return result;
  }

  @override
  /* Expression | Generator | Initializer */ doInvocation(
      int offset, Arguments arguments) {
    var error = helper.wrapInLocatedCompileTimeError(
        helper.evaluateArgumentsBefore(arguments, forest.literalNull(token)),
        messageCantUsePrefixAsExpression.withLocation(
            helper.uri, offsetForToken(token), lengthForToken(token)));
    return new StaticInvocationJudgment(null, forest.castArguments(arguments),
        desugaredError: error)
      ..fileOffset = offset;
  }

  @override
  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is IncompleteSendGenerator) {
      assert(send.name.name == send.token.lexeme,
          "'${send.name.name}' != ${send.token.lexeme}");
      Object result = prefixedLookup(send.token);
      if (send is SendAccessGenerator) {
        result = helper.finishSend(
            result,
            send.arguments as dynamic /* TODO(ahe): Remove this cast. */,
            offsetForToken(token));
      }
      if (isNullAware) {
        result = helper.wrapInLocatedCompileTimeError(
            helper.toValue(result),
            messageCantUsePrefixWithNullAware.withLocation(
                helper.uri, offsetForToken(token), lengthForToken(token)));
      }
      return result;
    } else {
      return buildSimpleRead();
    }
  }

  @override
  Expression makeInvalidRead() {
    return new SyntheticExpressionJudgment(helper.buildCompileTimeError(
        messageCantUsePrefixAsExpression,
        offsetForToken(token),
        lengthForToken(token)));
  }

  @override
  Expression makeInvalidWrite(Expression value) => makeInvalidRead();

  @override
  void printOn(StringSink sink) {
    sink.write(", prefix: ");
    sink.write(prefix.name);
    sink.write(", deferred: ");
    sink.write(prefix.deferred);
  }
}

abstract class UnexpectedQualifiedUseGenerator implements Generator {
  factory UnexpectedQualifiedUseGenerator(ExpressionGeneratorHelper helper,
      Token token, Generator prefixGenerator, bool isUnresolved) {
    return helper.forest.unexpectedQualifiedUseGenerator(
        helper, token, prefixGenerator, isUnresolved);
  }

  Generator get prefixGenerator;

  bool get isUnresolved;

  @override
  String get plainNameForRead {
    return "${prefixGenerator.plainNameForRead}.${token.lexeme}";
  }

  @override
  String get debugName => "UnexpectedQualifiedUseGenerator";

  @override
  Expression buildSimpleRead() => makeInvalidRead();

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return new SyntheticExpressionJudgment(helper.throwNoSuchMethodError(
        forest.literalNull(null)..fileOffset = offset,
        plainNameForRead,
        arguments,
        offsetForToken(token)));
  }

  @override
  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false, TypeInferrer typeInferrer}) {
    Template<Message Function(Token, Token)> template = isUnresolved
        ? templateUnresolvedPrefixInTypeAnnotation
        : templateNotAPrefixInTypeAnnotation;
    helper.addProblem(
        template.withArguments(prefixGenerator.token, token),
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token));
    prefixGenerator.storeUnexpectedTypePrefix(typeInferrer);
    helper.storeTypeUse(offsetForToken(token), const InvalidType());
    return const InvalidType();
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", prefixGenerator: ");
    prefixGenerator.printOn(sink);
  }
}
