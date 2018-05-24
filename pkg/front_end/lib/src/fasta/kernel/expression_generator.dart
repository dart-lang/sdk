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
        templateDeferredTypeAnnotation,
        templateNotAType;

import '../names.dart' show lengthName;

import '../parser.dart' show lengthForToken, offsetForToken;

import '../problems.dart' show unhandled, unsupported;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'forest.dart'
    show Forest, LoadLibraryBuilder, PrefixBuilder, TypeDeclarationBuilder;

import 'kernel_ast_api.dart'
    show
        DartType,
        Initializer,
        InvalidType,
        Member,
        Name,
        Procedure,
        TypeParameterType,
        VariableDeclaration;

import 'kernel_builder.dart'
    show
        AccessErrorBuilder,
        Builder,
        BuiltinTypeBuilder,
        FunctionTypeAliasBuilder,
        KernelClassBuilder,
        KernelFunctionTypeAliasBuilder,
        KernelTypeVariableBuilder;

import 'kernel_expression_generator.dart'
    show IncompleteSendGenerator, SendAccessGenerator;

export 'kernel_expression_generator.dart'
    show
        DelayedAssignment,
        DelayedPostfixIncrement,
        ErroneousExpressionGenerator,
        IncompleteErrorGenerator,
        IncompletePropertyAccessGenerator,
        IncompleteSendGenerator,
        LargeIntAccessGenerator,
        ParenthesizedExpressionGenerator,
        ReadOnlyAccessGenerator,
        SendAccessGenerator,
        ThisAccessGenerator,
        UnresolvedNameGenerator,
        buildIsNull;

abstract class ExpressionGenerator<Expression, Statement, Arguments> {
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

  /* Expression | Generator */ buildThrowNoSuchMethodError(
      Expression receiver, Arguments arguments,
      {bool isSuper,
      bool isGetter,
      bool isSetter,
      bool isStatic,
      String name,
      int offset,
      LocatedMessage argMessage});
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
abstract class Generator<Expression, Statement, Arguments>
    implements ExpressionGenerator<Expression, Statement, Arguments> {
  final ExpressionGeneratorHelper<Expression, Statement, Arguments> helper;

  final Token token;

  Generator(this.helper, this.token);

  Forest<Expression, Statement, Token, Arguments> get forest => helper.forest;

  String get plainNameForRead;

  String get debugName;

  Uri get uri => helper.uri;

  String get plainNameForWrite => plainNameForRead;

  bool get isInitializer => false;

  // TODO(ahe): Remove this method.
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

  /* Expression | Generator | Initializer */ doInvocation(
      int offset, Arguments arguments);

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
        helper.deprecated_addCompileTimeError(
            offsetForToken(token), "Not a constant expression.");
      }
      return PropertyAccessGenerator.make<Expression, Statement, Arguments>(
          helper,
          send.token,
          buildSimpleRead(),
          send.name,
          null,
          null,
          isNullAware);
    }
  }

  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false}) {
    helper.addProblem(templateNotAType.withArguments(token.lexeme),
        offsetForToken(token), lengthForToken(token));
    return const InvalidType();
  }

  @override
  /* Expression | Generator */ buildThrowNoSuchMethodError(
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

abstract class VariableUseGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory VariableUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      VariableDeclaration variable,
      [DartType promotedType]) {
    return helper.forest
        .variableUseGenerator(helper, token, variable, promotedType);
  }

  @override
  String get debugName => "VariableUseGenerator";
}

abstract class PropertyAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory PropertyAccessGenerator.internal(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression receiver,
      Name name,
      Member getter,
      Member setter) {
    return helper.forest
        .propertyAccessGenerator(helper, token, receiver, name, getter, setter);
  }

  static Generator<Expression, Statement, Arguments>
      make<Expression, Statement, Arguments>(
          ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
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
          ? new NullAwarePropertyAccessGenerator<Expression, Statement,
              Arguments>(helper, token, receiver, name, getter, setter, null)
          : new PropertyAccessGenerator<Expression, Statement,
                  Arguments>.internal(
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
abstract class ThisPropertyAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory ThisPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Name name,
      Member getter,
      Member setter) {
    return helper.forest
        .thisPropertyAccessGenerator(helper, token, name, getter, setter);
  }

  @override
  String get debugName => "ThisPropertyAccessGenerator";

  @override
  bool get isThisPropertyAccess => true;
}

abstract class NullAwarePropertyAccessGenerator<Expression, Statement,
    Arguments> implements Generator<Expression, Statement, Arguments> {
  factory NullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
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

abstract class SuperPropertyAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory SuperPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Name name,
      Member getter,
      Member setter) {
    return helper.forest
        .superPropertyAccessGenerator(helper, token, name, getter, setter);
  }

  @override
  String get debugName => "SuperPropertyAccessGenerator";
}

abstract class IndexedAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory IndexedAccessGenerator.internal(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return helper.forest
        .indexedAccessGenerator(helper, token, receiver, index, getter, setter);
  }

  static Generator<Expression, Statement, Arguments>
      make<Expression, Statement, Arguments>(
          ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
          Token token,
          Expression receiver,
          Expression index,
          Procedure getter,
          Procedure setter) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisIndexedAccessGenerator<Expression, Statement, Arguments>(
          helper, token, index, getter, setter);
    } else {
      return new IndexedAccessGenerator<Expression, Statement,
          Arguments>.internal(helper, token, receiver, index, getter, setter);
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
abstract class ThisIndexedAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory ThisIndexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression index,
      Procedure getter,
      Procedure setter) {
    return helper.forest
        .thisIndexedAccessGenerator(helper, token, index, getter, setter);
  }

  @override
  String get plainNameForRead => "[]";

  @override
  String get plainNameForWrite => "[]=";

  @override
  String get debugName => "ThisIndexedAccessGenerator";
}

abstract class SuperIndexedAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory SuperIndexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Expression index,
      Member getter,
      Member setter) {
    return helper.forest
        .superIndexedAccessGenerator(helper, token, index, getter, setter);
  }

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  String get debugName => "SuperIndexedAccessGenerator";
}

abstract class StaticAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory StaticAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      Member readTarget,
      Member writeTarget) {
    return helper.forest
        .staticAccessGenerator(helper, token, readTarget, writeTarget);
  }

  factory StaticAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
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
    return new StaticAccessGenerator<Expression, Statement, Arguments>(
        helper, token, getter, setter);
  }

  Member get readTarget;

  @override
  String get debugName => "StaticAccessGenerator";
}

abstract class LoadLibraryGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory LoadLibraryGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      LoadLibraryBuilder builder) {
    return helper.forest.loadLibraryGenerator(helper, token, builder);
  }

  @override
  String get plainNameForRead => 'loadLibrary';

  @override
  String get debugName => "LoadLibraryGenerator";
}

abstract class DeferredAccessGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory DeferredAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      PrefixBuilder builder,
      Generator<Expression, Statement, Arguments> generator) {
    return helper.forest
        .deferredAccessGenerator(helper, token, builder, generator);
  }

  PrefixBuilder get builder;

  Generator<Expression, Statement, Arguments> get generator;

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    var propertyAccess =
        generator.buildPropertyAccess(send, operatorOffset, isNullAware);
    if (propertyAccess is Generator) {
      return new DeferredAccessGenerator<Expression, Statement, Arguments>(
          helper, token, builder, propertyAccess);
    } else {
      Expression expression = propertyAccess;
      return helper.wrapInDeferredCheck(expression, builder, token.charOffset);
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

  @override
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

abstract class TypeUseGenerator<Expression, Statement, Arguments>
    implements Generator<Expression, Statement, Arguments> {
  factory TypeUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      Token token,
      PrefixBuilder prefix,
      int declarationReferenceOffset,
      TypeDeclarationBuilder declaration,
      String plainNameForRead) {
    return helper.forest.typeUseGenerator(helper, token, prefix,
        declarationReferenceOffset, declaration, plainNameForRead);
  }

  PrefixBuilder get prefix;

  TypeDeclarationBuilder get declaration;

  @override
  String get debugName => "TypeUseGenerator";

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
}
