// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show DartType, Nullability, Supertype, TreeNode, Variance;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../base/messages.dart';
import '../base/scope.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_loader.dart';
import '../source/type_parameter_factory.dart';
import 'declaration_builders.dart';
import 'formal_parameter_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'omitted_type_builder.dart';
import 'record_type_builder.dart';

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

  /// A type used in an extends clause.
  ///
  /// For instance `X` in
  ///
  ///    class Class extends X {}
  ///
  classExtendsType,

  /// A type used in an implements clause or a class or mixin.
  ///
  /// For instance `X` in
  ///
  ///    class Class implements X {}
  ///
  classImplementsType,

  /// A type used in a with clause of a class.
  ///
  /// For instance `X` in
  ///
  ///    class Class with X {}
  ///
  /// This type use creates an intermediate type used for mixin inference. The
  /// type is not check for well-boundedness and contains [UnknownType] where
  /// type arguments are omitted.
  classWithType,

  /// A type used in the on clause of a mixin declaration.
  ///
  /// For instance `X` in
  ///
  ///    mixin Mixin on X {}
  ///
  mixinOnType,

  /// A type used in the on clause of an extension declaration.
  ///
  /// For instance `X` in
  ///
  ///    extension Extension on X {}
  ///
  extensionOnType,

  /// A type used in an implements clause of an extension type.
  ///
  /// For instance `X` in
  ///
  ///    extension type ExtensionType(Y y) implements X {}
  ///
  extensionTypeImplementsType,

  /// A type used as a representation type of an extension type.
  ///
  /// For instance `Y` in
  ///
  ///    extension type ExtensionType(Y y) implements X {}
  ///
  extensionTypeRepresentationType,

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
}

// TODO(johnniwinther): Change from sealed to abstract.
sealed class TypeBuilder {
  const TypeBuilder();

  TypeDeclarationBuilder? get declaration => null;

  // Coverage-ignore(suite): Not run.
  List<TypeBuilder>? get typeArguments => null;

  /// Returns the Uri for the file in which this type annotation occurred, or
  /// `null` if the type was synthesized.
  Uri? get fileUri;

  /// Returns the character offset with [fileUri] at which this type annotation
  /// occurred, or `null` if the type was synthesized.
  int? get charOffset;

  /// May return null, for example, for mixin applications.
  TypeName? get typeName;

  NullabilityBuilder get nullabilityBuilder;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer);

  @override
  String toString() => "$debugName(${printOn(new StringBuffer())})";

  /// Returns the [TypeBuilder] for this type in which [TypeParameterBuilder]s
  /// in [substitution] have been replaced by the corresponding [TypeBuilder]s.
  ///
  /// If [typeParameterFactory] is provided, created type parameter builders
  /// are registered with [typeParameterFactory]. Otherwise, creating a
  /// type parameter builder result in an assertion error.
  ///
  /// The type parameter builders registered with [typeParameterFactory] must be
  /// processed by the caller, unless the created [TypeBuilder]s and
  /// [TypeParameterBuilder]s are not part of the generated AST.
  // TODO(johnniwinther): Change [NamedTypeBuilder] to hold the
  // [TypeParameterScopeBuilder] should resolve it, so that we cannot create
  // [NamedTypeBuilder]s that are orphaned.
  TypeBuilder subst(Map<NominalParameterBuilder, TypeBuilder> substitution,
      {TypeParameterFactory? typeParameterFactory}) {
    if (substitution.isEmpty) {
      return this;
    }
    TypeParameterFactory typeParameterFactoryInternal =
        typeParameterFactory ?? new TypeParameterFactory();
    TypeBuilder result = substituteRange(
            substitution, substitution, typeParameterFactoryInternal,
            variance: Variance.covariant) ??
        this;
    assert(typeParameterFactory != null || typeParameterFactoryInternal.isEmpty,
        "Non-empty unbound type parameters: $typeParameterFactoryInternal.");
    return result;
  }

  // Coverage-ignore(suite): Not run.
  TypeBuilder substitute(
      TypeBuilder type, Map<NominalParameterBuilder, TypeBuilder> substitution,
      {required TypeParameterFactory typeParameterFactory}) {
    return type.substituteRange(
            substitution, substitution, typeParameterFactory,
            variance: Variance.covariant) ??
        type;
  }

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

  Supertype? buildSupertype(LibraryBuilder library, TypeUse typeUse);

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
  /// If [typeParameterFactory] is provided, created type builders that are
  /// not bound are register with [typeParameterFactory]. Otherwise, creating an
  /// unbound type builder results in an assertion error.
  ///
  /// The type parameter builders registered with [typeParameterFactory] must be
  /// processed by the caller, unless the created [TypeBuilder]s and
  /// [TypeParameterBuilder]s are not part of the generated AST.
  TypeBuilder? unalias({Set<TypeAliasBuilder>? usedTypeAliasBuilders}) => this;

  /// Computes the nullability of this type.
  ///
  /// [typeParametersTraversalState] is passed to handle cyclic dependencies
  /// between type parameters,
  Nullability computeNullability(
      {required Map<TypeParameterBuilder, TraversalState>
          typeParametersTraversalState});

  /// Computes the variance of a variable in a type.  The function can be run
  /// before the types are resolved to compute variances of typedefs' type
  /// variables.  For that case if the type has its declaration set to null and
  /// its name matches that of the variable, it's interpreted as an occurrence
  /// of a type parameter.
  VarianceCalculationValue computeTypeParameterBuilderVariance(
      NominalParameterBuilder nominalParameterBuilder,
      {required SourceLoader sourceLoader});

  /// Computes the unaliased [TypeDeclarationBuilder] for this type, if any.
  TypeDeclarationBuilder? computeUnaliasedDeclaration(
      {required bool isUsedAsClass});

  void collectReferencesFrom(Map<TypeParameterBuilder, int> parameterIndices,
      List<List<int>> edges, int index);

  TypeBuilder? substituteRange(
      Map<TypeParameterBuilder, TypeBuilder> upperSubstitution,
      Map<TypeParameterBuilder, TypeBuilder> lowerSubstitution,
      TypeParameterFactory typeParameterFactory,
      {final Variance variance = Variance.covariant});

  TypeBuilder? unaliasAndErase();

  /// Helper function that returns `true` if a type parameter with a name
  /// from [typeParameterNames] is referenced in this type.
  bool usesTypeParameters(Set<String> typeParameterNames);

  /// Finds raw generic types in this type with inbound references in type
  /// variables.
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences();
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
  List<StructuralParameterBuilder>? get typeParameters;

  /// If `true`, this function type was created using function formal parameter
  /// syntax, like `f` in `method(int f()) { ... }`.
  bool get hasFunctionFormalParameterSyntax;
}

// Coverage-ignore(suite): Not run.
abstract class InvalidTypeBuilder extends TypeBuilder {
  @override
  VarianceCalculationValue computeTypeParameterBuilderVariance(
      NominalParameterBuilder variable,
      {required SourceLoader sourceLoader}) {
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  TypeDeclarationBuilder? computeUnaliasedDeclaration(
          {required bool isUsedAsClass}) =>
      null;
}

abstract class NamedTypeBuilder extends TypeBuilder {
  @override
  TypeName get typeName;

  void resolveIn(LookupScope scope, int charOffset, Uri fileUri,
      ProblemReporting problemReporting);
  void bind(
      ProblemReporting problemReporting, TypeDeclarationBuilder declaration);

  NamedTypeBuilder withTypeArguments(List<TypeBuilder> arguments);

  InvalidBuilder buildInvalidTypeDeclarationBuilder(LocatedMessage message,
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

/// The name of a named type as used by the [NamedTypeBuilder].
sealed class TypeName {
  /// The name text. For instance `List` in both `List<int>` and `core.List`.
  String get name;

  /// The offset that can be used to point to the origin of the name in
  /// messages.
  int get nameOffset;

  /// The length that can be used to point to the [name] in messages.
  int get nameLength;

  /// If this is a qualified name, this is the prefix name. For instance `core`
  /// in `core.String`.
  String? get qualifier;

  /// The full name including prefix, if present. For instance `core.String` for
  /// `core . String`.
  String get fullName;

  /// The offset that can be used to point to the origin of the [fullName].
  int get fullNameOffset;

  /// The length that can be used to point to the [fullName] in messages.
  int get fullNameLength;
}

/// A [TypeName] for a predefined type that doesn't occur in the source code and
/// therefore has no offset.
///
/// For instance the use of `Object` as the implicit super type of a class.
class PredefinedTypeName implements TypeName {
  @override
  final String name;

  const PredefinedTypeName(this.name);

  @override
  // Coverage-ignore(suite): Not run.
  String? get qualifier => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get nameOffset => TreeNode.noOffset;

  @override
  // Coverage-ignore(suite): Not run.
  int get nameLength => noLength;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullName => name;

  @override
  // Coverage-ignore(suite): Not run.
  int get fullNameOffset => nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  int get fullNameLength => noLength;
}

/// A [TypeName] synthesized from the source code whose offset therefore doesn't
/// necessarily correspond to the name occurring at this position in the source
/// code.
///
/// For instance the enclosing class name for the return type of a constructor.
class SyntheticTypeName implements TypeName {
  @override
  final String name;

  @override
  final int nameOffset;

  SyntheticTypeName(this.name, this.nameOffset);

  @override
  // Coverage-ignore(suite): Not run.
  int get nameLength => noLength;

  @override
  String? get qualifier => null;

  @override
  String get fullName => name;

  @override
  // Coverage-ignore(suite): Not run.
  int get fullNameOffset => nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  int get fullNameLength => noLength;
}

/// A [TypeName] occurring as an identifier in the source code.
class IdentifierTypeName implements TypeName {
  @override
  final String name;

  @override
  final int nameOffset;

  IdentifierTypeName(this.name, this.nameOffset);

  @override
  int get nameLength => name.length;

  @override
  String? get qualifier => null;

  @override
  String get fullName => name;

  @override
  int get fullNameOffset => nameOffset;

  @override
  int get fullNameLength => name.length;
}

/// A [TypeName] occurring as a qualified identifier in the source code.
class QualifiedTypeName implements TypeName {
  @override
  final String qualifier;

  final int qualifierOffset;

  @override
  final String name;

  @override
  final int nameOffset;

  QualifiedTypeName(
      this.qualifier, this.qualifierOffset, this.name, this.nameOffset);

  @override
  int get nameLength => name.length;

  @override
  String get fullName => '$qualifier.$name';

  @override
  int get fullNameOffset => qualifierOffset;

  @override
  int get fullNameLength => nameOffset - qualifierOffset + name.length;
}
