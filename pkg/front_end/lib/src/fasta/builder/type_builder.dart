// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder;

import 'package:kernel/ast.dart' show DartType, Supertype;
import 'package:kernel/class_hierarchy.dart';

import '../kernel/type_algorithms.dart';
import '../messages.dart';
import '../scope.dart';
import '../source/source_library_builder.dart';
import 'formal_parameter_builder.dart';
import 'invalid_type_declaration_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'omitted_type_builder.dart';
import 'record_type_builder.dart';
import 'type_alias_builder.dart';
import 'type_declaration_builder.dart';
import 'type_variable_builder.dart';

enum TypeUse {
  /// A type used as the type of a parameter.
  ///
  /// For instance `X` and `Y` in
  ///
  ///    method(X p, {Y q}) {}
  ///
  parameterType,

  /// A type used as the type of a record entry.
  ///
  /// For instance `X` and `Y` in
  ///
  ///    (X, {Y y}) foo = ...;
  ///
  recordEntryType,

  /// A type used as the type of a field.
  ///
  /// For instance `X` and `Y` in
  ///
  ///    X topLevelField;
  ///    class Class {
  ///      Y instanceField;
  ///    }
  ///
  fieldType,

  /// A type used as the return type of a function.
  ///
  /// For instance `X` in
  ///
  ///    X method() { ... }
  ///
  returnType,

  /// A type used as a type argument to a constructor invocation.
  ///
  /// For instance `X` in
  ///
  ///   class Class<T> {}
  ///   method() => new Class<X>();
  ///
  constructorTypeArgument,

  /// A type used as a type argument to a redirecting factory constructor
  /// declaration.
  ///
  /// For instance `X` in
  ///
  ///   class Class<T> {
  ///     Class();
  ///     factory Class.redirect() = Class<X>;
  ///   }
  ///
  redirectionTypeArgument,

  /// A type used as the bound of a type parameter.
  ///
  /// For instance `X` and `Y` in
  ///
  ///    method<T extends X>() {}
  ///    class Class<S extends Y> {}
  ///
  typeParameterBound,

  /// A type computed as the default type for a type parameter.
  ///
  /// For instance the type `X` computed for `T` and the type `dynamic` computed
  /// for `S`.
  ///
  ///    method<T extends X>() {}
  ///    class Class<S> {}
  ///
  typeParameterDefaultType,

  /// A type used as a type argument in the instantiation of a tear off.
  ///
  /// For instance `X` and `Y` in
  ///
  ///    class Class<S> {}
  ///    method<T>() {
  ///      Class<X>.new;
  ///      method<Y>;
  ///    }
  ///
  tearOffTypeArgument,

  /// A type used in an extends, with or implements clause.
  ///
  /// For instance `X`, `Y`, `Z` in
  ///
  ///    class Class extends X with Y implements Z {}
  ///
  // TODO(johnniwinther): The probably enclosed the mixin on clause. Is this
  // a correct handling wrt well-boundedness?
  superType,

  /// A type used in a with clause.
  ///
  /// For instance `X` in
  ///
  ///    class Class extends X {}
  ///
  /// This type use creates an intermediate type used for mixin inference. The
  /// type is not check for well-boundedness and contains [UnknownType] where
  /// type arguments are omitted.
  mixedInType,

  /// A type used in the on clause of an extension declaration.
  ///
  /// For instance `X` in
  ///
  ///    extension Extension on X {}
  ///
  extensionOnType,

  /// A type used as the definition of a typedef.
  ///
  /// For instance `X`, `void Function()` in
  ///
  ///    typedef Typedef1 = X;
  ///    typedef void Typedef2(); // The unaliased type is `void Function()`.
  ///
  typedefAlias,

  /// The this type of an enum.
  // TODO(johnniwinther): This doesn't currently have the correct value and/or
  //  well-boundedness checking.
  enumSelfType,

  /// A type used as a type literal.
  ///
  /// For instance `X` in
  ///
  ///    method() => X;
  ///
  /// where `X` is the name of a class.
  typeLiteral,

  /// A type used as a type argument to a literal.
  ///
  /// For instance `X`, `Y`, `Z`, and `W` in
  ///
  ///    method() {
  ///      <X>[];
  ///      <Y>{};
  ///      <Z, W>{};
  ///    }
  ///
  literalTypeArgument,

  /// A type used as a type argument in an invocation.
  ///
  /// For instance `X`, `Y`, and `Z` in
  ///
  ///   staticMethod<T>(Class c, void Function<S>() f) {
  ///     staticMethod<X>(c, f);
  ///     c.instanceMethod<Y>();
  ///     f<Z>();
  ///   }
  ///   class Class {
  ///     instanceMethod<U>() {}
  ///   }
  invocationTypeArgument,

  /// A type used as the type in an is-test.
  ///
  /// For instance `X` in
  ///
  ///    method(o) => o is X;
  ///
  isType,

  /// A type used as the type in an as-cast.
  ///
  /// For instance `X` in
  ///
  ///    method(o) => o as X;
  ///
  asType,

  /// A type used as the type in an object pattern.
  ///
  /// For instance `X` in
  ///
  ///    method(o) {
  ///      if (o case X()) {}
  ///    }
  ///
  objectPatternType,

  /// A type used as the type of local variable.
  ///
  /// For instance `X` in
  ///
  ///    method() {
  ///      X local;
  ///    }
  ///
  variableType,

  /// A type used as the catch type in a catch clause.
  ///
  /// For instance `X` in
  ///
  ///    method() {
  ///      try {
  ///      } on X catch (e) {
  ///      }
  ///    }
  ///
  catchType,

  /// A type used as an instantiation argument.
  ///
  /// For instance `X` in
  ///
  ///   method(void Function<T>() f) {
  ///     f<X>;
  ///   }
  ///
  instantiation,

  /// A type used as a type argument within another type.
  ///
  /// For instance `X`, `Y`, `Z` and `W` in
  ///
  ///   method(List<X> a, Y Function(Z) f) {}
  ///   class Class implements List<W> {}
  ///
  typeArgument,

  /// The default type of a type parameter used as the type argument in a raw
  /// type.
  ///
  /// For instance `X` implicitly inside `Class<X>` in the type of `cls` in
  ///
  ///   class Class<T extends X> {}
  ///   Class cls;
  ///
  defaultTypeAsTypeArgument,

  /// A type from a deferred library. This is an error case.
  ///
  /// For instance `X` in
  ///
  ///   import 'foo.dart' deferred as prefix;
  ///
  ///   prefix.X field;
  ///
  deferredTypeError,

  /// A type used as a type argument in the construction of a type through the
  /// macro API.
  macroTypeArgument,
}

sealed class TypeBuilder {
  const TypeBuilder();

  TypeDeclarationBuilder? get declaration => null;

  /// Returns the Uri for the file in which this type annotation occurred, or
  /// `null` if the type was synthesized.
  Uri? get fileUri;

  /// Returns the character offset with [fileUri] at which this type annotation
  /// occurred, or `null` if the type was synthesized.
  int? get charOffset;

  /// May return null, for example, for mixin applications.
  Object? get name;

  NullabilityBuilder get nullabilityBuilder;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer);

  @override
  String toString() => "$debugName(${printOn(new StringBuffer())})";

  /// Returns the [TypeBuilder] for this type in which [TypeVariableBuilder]s
  /// in [substitution] have been replaced by the corresponding [TypeBuilder]s.
  ///
  /// If [unboundTypes] is provided, created type builders that are not bound
  /// are added to [unboundTypes]. Otherwise, creating an unbound type builder
  /// results in an assertion error.
  ///
  /// If [unboundTypeVariables] is provided, created type variable builders are
  /// added to [unboundTypeVariables]. Otherwise, creating a
  /// type variable builder result in an assertion error.
  ///
  /// The [unboundTypes] and [unboundTypeVariables] must be processed by the
  /// call, unless the created [TypeBuilder]s and [TypeVariableBuilder]s are
  /// not part of the generated AST.
  // TODO(johnniwinther): Change [NamedTypeBuilder] to hold the
  // [TypeParameterScopeBuilder] should resolve it, so that we cannot create
  // [NamedTypeBuilder]s that are orphaned.
  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution,
      {List<TypeBuilder>? unboundTypes,
      List<TypeVariableBuilder>? unboundTypeVariables}) {
    if (substitution.isEmpty) {
      return this;
    }
    List<TypeBuilder> unboundTypesInternal = unboundTypes ?? [];
    List<TypeVariableBuilder> unboundTypeVariablesInternal =
        unboundTypeVariables ?? [];
    TypeBuilder result = substitute(this, substitution,
        unboundTypes: unboundTypesInternal,
        unboundTypeVariables: unboundTypeVariablesInternal);
    assert(unboundTypes != null || unboundTypesInternal.isEmpty,
        "Non-empty unbound types: $unboundTypesInternal.");
    assert(unboundTypeVariables != null || unboundTypeVariablesInternal.isEmpty,
        "Non-empty unbound type variables: $unboundTypeVariables.");
    return result;
  }

  /// Clones the type builder recursively without binding the subterms to
  /// existing declaration or type variable builders.  All newly built types
  /// are added to [newTypes], so that they can be added to a proper scope and
  /// resolved later.
  TypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration);

  String get fullNameForErrors => "${printOn(new StringBuffer())}";

  /// Returns `true` if [build] can create the type for this type builder
  /// without the need for inference, i.e without the [hierarchy] argument.
  ///
  /// This is false if the type directly or indirectly depends on inferred
  /// types.
  bool get isExplicit;

  /// Creates the [DartType] from this [TypeBuilder] that doesn't contain
  /// [TypedefType].
  ///
  /// [library] is used to determine nullabilities and for registering well-
  /// boundedness checks on the created type. [typeUse] describes how the
  /// type is used which determine which well-boundedness checks are applied.
  ///
  /// If [hierarchy] is provided, inference is triggered on inferable types.
  /// Otherwise, [isExplicit] must be true.
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy});

  /// Creates the [DartType] from this [TypeBuilder] that contains
  /// [TypedefType]. This is used to create types internal on which well-
  /// boundedness checks can be permit. Calls from outside the [TypeBuilder]
  /// subclasses should generally use [build] instead.
  ///
  /// [library] is used to determine nullabilities and for registering well-
  /// boundedness checks on the created type. [typeUse] describes how the
  /// type is used which determine which well-boundedness checks are applied.
  ///
  /// If [hierarchy] is non-null, inference is triggered on inferable types.
  /// Otherwise, [isExplicit] must be true.
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy);

  Supertype? buildSupertype(LibraryBuilder library);

  Supertype? buildMixedInType(LibraryBuilder library);

  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder);

  bool get isVoidType;

  /// Register [type] as the inferred type of this type builder.
  ///
  /// If this is not an [InferableTypeBuilder] this method will throw.
  void registerInferredType(DartType type) {
    throw new UnsupportedError("${runtimeType}.registerInferredType");
  }

  /// Registers a [listener] that is called when this type has been inferred.
  // TODO(johnniwinther): Should we handle this for all types or just those
  // that are inferred or aliases of inferred types?
  void registerInferredTypeListener(InferredTypeListener listener) {}

  /// Registers the [Inferable] object to be called when this type needs to be
  /// inferred.
  ///
  /// If this type is not an [InferableTypeBuilder], this call is a no-op.
  void registerInferable(Inferable inferable) {}

  /// Computes the unaliased type builder for this type builder.
  ///
  /// If [usedTypeAliasBuilders] is supplied, the [TypeAliasBuilder]s used
  /// during unaliasing are added to [usedTypeAliasBuilders].
  ///
  /// If [unboundTypes] is provided, created type builders that are not bound
  /// are added to [unboundTypes]. Otherwise, creating an unbound type builder
  /// results in an assertion error.
  ///
  /// If [unboundTypeVariables] is provided, created type variable builders are
  /// added to [unboundTypeVariables]. Otherwise, creating a
  /// type variable builder result in an assertion error.
  ///
  /// The [unboundTypes] and [unboundTypeVariables] must be processed by the
  /// call, unless the created [TypeBuilder]s and [TypeVariableBuilder]s are
  /// not part of the generated AST.
  TypeBuilder? unalias(
          {Set<TypeAliasBuilder>? usedTypeAliasBuilders,
          List<TypeBuilder>? unboundTypes,
          List<TypeVariableBuilder>? unboundTypeVariables}) =>
      this;
}

abstract class OmittedTypeBuilder extends TypeBuilder {
  const OmittedTypeBuilder();

  bool get hasType;

  DartType get type;
}

abstract class FunctionTypeBuilder extends TypeBuilder {
  @override
  int get charOffset;
  TypeBuilder get returnType;
  List<ParameterBuilder>? get formals;
  List<TypeVariableBuilder>? get typeVariables;
}

abstract class InvalidTypeBuilder extends TypeBuilder {}

abstract class NamedTypeBuilder extends TypeBuilder {
  @override
  Object get name;

  int get nameOffset;

  int get nameLength;

  void resolveIn(
      Scope scope, int charOffset, Uri fileUri, LibraryBuilder library);
  void bind(LibraryBuilder libraryBuilder, TypeDeclarationBuilder declaration);
  List<TypeBuilder>? get arguments;
  NamedTypeBuilder withArguments(List<TypeBuilder> arguments);
  InvalidTypeDeclarationBuilder buildInvalidTypeDeclarationBuilder(
      LocatedMessage message,
      {List<LocatedMessage>? context});
}

abstract class RecordTypeBuilder extends TypeBuilder {
  List<RecordTypeFieldBuilder>? get positionalFields;
  List<RecordTypeFieldBuilder>? get namedFields;
  @override
  int get charOffset;
  @override
  Uri get fileUri;
}

abstract class FixedTypeBuilder extends TypeBuilder {
  const FixedTypeBuilder();
}
