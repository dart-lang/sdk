// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

enum TypeParameterKind {
  /// A type parameter declared on a function, method, or local function.
  function,

  /// A type parameter declared on a class, mixin or enum.
  classMixinOrEnum,

  /// A type parameter declared on an extension or an extension type.
  extensionOrExtensionType,

  /// A type parameter on an extension instance member synthesized from an
  /// extension type parameter.
  extensionSynthesized,

  /// A type parameter builder created from a kernel node.
  fromKernel,
}

sealed class TypeParameterBuilder extends TypeDeclarationBuilderImpl
    implements TypeDeclarationBuilder {
  abstract TypeBuilder? bound;

  abstract TypeBuilder? defaultType;

  bool get isWildcard;

  TypeParameterKind get kind;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  bool get isTypeParameter => true;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(runtimeType);
    sb.write('(');
    sb.write(name);
    if (bound != null) {
      sb.write(" extends ");
      bound!.printOn(sb);
    }
    sb.write(')');
    return sb.toString();
  }

  @override
  int get typeParametersCount => 0;

  Variance get variance;

  void set variance(Variance value);

  /// Unused in interface; left in on purpose.
  bool get hasUnsetParameterBound;

  DartType get parameterBound;

  void set parameterBound(DartType bound);

  Nullability? _nullabilityFromParameterBound;

  Nullability get nullabilityFromParameterBound {
    assert(
      _nullabilityFromParameterBound != null,
      "Nullability has not been computed for $this.",
    );
    return _nullabilityFromParameterBound!;
  }

  /// Unused in interface; left in on purpose.
  bool get hasUnsetParameterDefaultType;

  void set parameterDefaultType(DartType defaultType);

  void finish(
    SourceLibraryBuilder library,
    ClassBuilder object,
    TypeBuilder dynamicType,
  );

  Nullability _computeNullabilityFromType(
    TypeBuilder? typeBuilder, {
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) {
    if (typeBuilder == null) {
      return Nullability.undetermined;
    }
    return typeBuilder.computeNullability(
      typeParametersTraversalState: typeParametersTraversalState,
    );
  }

  Nullability computeNullability({
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) {
    if (_nullabilityFromParameterBound != null) {
      return _nullabilityFromParameterBound!;
    }
    switch (typeParametersTraversalState[this] ??= TraversalState.unvisited) {
      case TraversalState.visited:
        // Coverage-ignore(suite): Not run.
        return _nullabilityFromParameterBound!;
      case TraversalState.active:
        typeParametersTraversalState[this] = TraversalState.visited;
        return _nullabilityFromParameterBound = Nullability.undetermined;
      case TraversalState.unvisited:
        typeParametersTraversalState[this] = TraversalState.active;
        Nullability nullability = _computeNullabilityFromType(
          bound,
          typeParametersTraversalState: typeParametersTraversalState,
        );
        typeParametersTraversalState[this] = TraversalState.visited;
        return _nullabilityFromParameterBound =
            nullability == Nullability.nullable
            ? Nullability.undetermined
            : nullability;
    }
  }

  @override
  Nullability computeNullabilityWithArguments(
    List<TypeBuilder>? typeArguments, {
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) {
    return computeNullability(
      typeParametersTraversalState: typeParametersTraversalState,
    );
  }

  TypeParameterCyclicDependency? findCyclicDependency({
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
    Map<TypeParameterBuilder, TypeParameterBuilder>? cycleElements,
  }) {
    cycleElements ??= {};

    switch (typeParametersTraversalState[this] ??= TraversalState.unvisited) {
      case TraversalState.visited:
        return null;
      case TraversalState.active:
        typeParametersTraversalState[this] = TraversalState.visited;
        List<TypeParameterBuilder>? viaTypeParameters;
        TypeParameterBuilder? nextViaTypeParameter = cycleElements[this];
        while (nextViaTypeParameter != null && nextViaTypeParameter != this) {
          (viaTypeParameters ??= []).add(nextViaTypeParameter);
          nextViaTypeParameter = cycleElements[nextViaTypeParameter];
        }
        return new TypeParameterCyclicDependency(
          this,
          viaTypeParameters: viaTypeParameters,
        );
      case TraversalState.unvisited:
        typeParametersTraversalState[this] = TraversalState.active;
        TypeBuilder? unaliasedAndErasedBound = bound?.unaliasAndErase();
        TypeDeclarationBuilder? unaliasedAndErasedBoundDeclaration =
            unaliasedAndErasedBound?.declaration;
        TypeParameterBuilder? nextVariable;
        if (unaliasedAndErasedBoundDeclaration is TypeParameterBuilder) {
          nextVariable = unaliasedAndErasedBoundDeclaration;
        }

        if (nextVariable != null) {
          cycleElements[this] = nextVariable;
          TypeParameterCyclicDependency? result = nextVariable
              .findCyclicDependency(
                typeParametersTraversalState: typeParametersTraversalState,
                cycleElements: cycleElements,
              );
          typeParametersTraversalState[this] = TraversalState.visited;
          return result;
        } else {
          typeParametersTraversalState[this] = TraversalState.visited;
          return null;
        }
    }
  }
}

abstract class NominalParameterBuilder extends TypeParameterBuilder {
  /// Sentinel value used to indicate that the variable has no name. This is
  /// used for error recovery.
  static const String noNameSentinel = 'no name sentinel';

  NominalParameterBuilder({
    Variance? variableVariance,
    Nullability? nullability,
  }) : _varianceCalculationValue = new VarianceCalculationValue.fromVariance(
         variableVariance ?? Variance.covariant,
       ) {
    _nullabilityFromParameterBound = nullability;
  }

  /// The [TypeParameter] built by this builder.
  TypeParameter get parameter;

  VarianceCalculationValue? _varianceCalculationValue;

  VarianceCalculationValue? get varianceCalculationValue {
    return _varianceCalculationValue;
  }

  void set varianceCalculationValue(VarianceCalculationValue? value) {
    _varianceCalculationValue = value;
    if (value != null && value.isCalculated) {
      parameter.variance = value.variance!;
    } else {
      parameter.variance = null;
    }
  }

  @override
  Variance get variance {
    assert(_varianceCalculationValue?.variance == parameter.variance);
    VarianceCalculationValue varianceCalculationValue =
        _varianceCalculationValue!;
    return varianceCalculationValue.variance!;
  }

  @override
  void set variance(Variance value) {
    _varianceCalculationValue = new VarianceCalculationValue.fromVariance(
      value,
    );
    parameter.variance = value;
  }

  @override
  bool get hasUnsetParameterBound =>
      identical(parameter.bound, TypeParameter.unsetBoundSentinel);

  @override
  DartType get parameterBound => parameter.bound;

  @override
  void set parameterBound(DartType bound) {
    parameter.bound = bound;
  }

  @override
  bool get hasUnsetParameterDefaultType =>
      identical(parameter.defaultType, TypeParameter.unsetDefaultTypeSentinel);

  @override
  void set parameterDefaultType(DartType defaultType) {
    parameter.defaultType = defaultType;
  }

  @override
  TypeParameterType buildAliasedTypeWithBuiltArguments(
    LibraryBuilder library,
    Nullability nullability,
    List<DartType>? arguments,
    TypeUse typeUse,
    Uri fileUri,
    int charOffset, {
    required bool hasExplicitTypeArguments,
  }) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri? fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
        diag.typeArgumentsOnTypeVariable.withArguments(typeVariableName: name),
        charOffset,
        name.length,
        fileUri,
      );
    }
    return new TypeParameterType(parameter, nullability);
  }

  @override
  DartType buildAliasedType(
    LibraryBuilder library,
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments,
    TypeUse typeUse,
    Uri fileUri,
    int charOffset,
    ClassHierarchyBase? hierarchy, {
    required bool hasExplicitTypeArguments,
  }) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      library.addProblem(
        diag.typeArgumentsOnTypeVariable.withArguments(typeVariableName: name),
        charOffset,
        name.length,
        fileUri,
      );
    }
    // If the bound is not set yet, the actual value is not important yet as it
    // will be set later.
    Nullability nullability;
    if (nullabilityBuilder.isOmitted) {
      nullability = nullabilityFromParameterBound;
    } else {
      nullability = nullabilityBuilder.build();
    }
    TypeParameterType type = buildAliasedTypeWithBuiltArguments(
      library,
      nullability,
      null,
      typeUse,
      fileUri,
      charOffset,
      hasExplicitTypeArguments: hasExplicitTypeArguments,
    );
    return type;
  }

  @override
  void finish(
    SourceLibraryBuilder library,
    ClassBuilder object,
    TypeBuilder dynamicType,
  ) {
    DartType objectType = object.buildAliasedType(
      library,
      const NullabilityBuilder.nullable(),
      /* arguments = */ null,
      TypeUse.typeParameterBound,
      fileUri ?? // Coverage-ignore(suite): Not run.
          missingUri,
      fileOffset,
      /* hierarchy = */ null,
      hasExplicitTypeArguments: false,
    );
    if (hasUnsetParameterBound) {
      parameterBound =
          bound?.build(library, TypeUse.typeParameterBound) ?? objectType;
    }
    // If defaultType is not set, initialize it to dynamic, unless the bound is
    // explicitly specified as Object, in which case defaultType should also be
    // Object. This makes sure instantiation of generic function types with an
    // explicit Object bound results in Object as the instantiated type.
    if (hasUnsetParameterDefaultType) {
      parameterDefaultType =
          defaultType?.build(library, TypeUse.typeParameterDefaultType) ??
          (bound != null && parameterBound == objectType
              ? objectType
              : dynamicType.build(library, TypeUse.typeParameterDefaultType));
    }
  }
}

List<TypeParameterBuilder> sortAllTypeParametersTopologically(
  Iterable<TypeParameterBuilder> typeParameters,
) {
  Set<TypeParameterBuilder> unhandled = new Set<TypeParameterBuilder>.identity()
    ..addAll(typeParameters);
  List<TypeParameterBuilder> result = <TypeParameterBuilder>[];
  while (unhandled.isNotEmpty) {
    TypeParameterBuilder rootVariable = unhandled.first;
    unhandled.remove(rootVariable);

    TypeBuilder? rootVariableBound;
    if (rootVariable is NominalParameterBuilder) {
      rootVariableBound = rootVariable.bound;
    } else {
      rootVariable as StructuralParameterBuilder;
      rootVariableBound = rootVariable.bound;
    }

    if (rootVariableBound != null) {
      _sortAllTypeParametersTopologicallyFromRoot(
        rootVariableBound,
        unhandled,
        result,
      );
    }
    result.add(rootVariable);
  }
  return result;
}

void _sortAllTypeParametersTopologicallyFromRoot(
  TypeBuilder root,
  Set<TypeParameterBuilder> unhandled,
  List<TypeParameterBuilder> result,
) {
  List<TypeParameterBuilder>? foundTypeParameters;
  List<TypeBuilder>? internalDependents;

  switch (root) {
    case NamedTypeBuilder(:TypeDeclarationBuilder? declaration):
      switch (declaration) {
        case ClassBuilder():
          foundTypeParameters = declaration.typeParameters;
        case TypeAliasBuilder():
          foundTypeParameters = declaration.typeParameters;
          internalDependents = <TypeBuilder>[declaration.type];
        case NominalParameterBuilder():
          foundTypeParameters = <NominalParameterBuilder>[declaration];
        case StructuralParameterBuilder():
          foundTypeParameters = <StructuralParameterBuilder>[declaration];
        case ExtensionTypeDeclarationBuilder():
        // TODO(johnniwinther):: Handle this case.
        case ExtensionBuilder():
        case BuiltinTypeDeclarationBuilder():
        case InvalidBuilder():
        case null:
      }
    case FunctionTypeBuilder(
      typeParameters: List<StructuralParameterBuilder>? typeParameters,
      :List<ParameterBuilder>? formals,
      :TypeBuilder returnType,
    ):
      foundTypeParameters = typeParameters;
      if (formals != null) {
        internalDependents = <TypeBuilder>[];
        for (ParameterBuilder formal in formals) {
          internalDependents.add(formal.type);
        }
      }
      if (returnType is! OmittedTypeBuilder) {
        (internalDependents ??= <TypeBuilder>[]).add(returnType);
      }
    case RecordTypeBuilder(
      :List<RecordTypeFieldBuilder>? positionalFields,
      :List<RecordTypeFieldBuilder>? namedFields,
    ):
      if (positionalFields != null) {
        internalDependents = <TypeBuilder>[];
        for (RecordTypeFieldBuilder field in positionalFields) {
          internalDependents.add(field.type);
        }
      }
      if (namedFields != null) {
        internalDependents ??= <TypeBuilder>[];
        for (RecordTypeFieldBuilder field in namedFields) {
          internalDependents.add(field.type);
        }
      }
    case OmittedTypeBuilder():
    case FixedTypeBuilder():
    // Coverage-ignore(suite): Not run.
    case InvalidTypeBuilder():
  }

  if (foundTypeParameters != null && foundTypeParameters.isNotEmpty) {
    for (TypeParameterBuilder parameterBuilder in foundTypeParameters) {
      if (unhandled.contains(parameterBuilder)) {
        unhandled.remove(parameterBuilder);

        TypeBuilder? parameterBound;
        if (parameterBuilder is NominalParameterBuilder) {
          parameterBound = parameterBuilder.bound;
        } else {
          parameterBuilder as StructuralParameterBuilder;
          parameterBound = parameterBuilder.bound;
        }

        if (parameterBound != null) {
          _sortAllTypeParametersTopologicallyFromRoot(
            parameterBound,
            unhandled,
            result,
          );
        }
        result.add(parameterBuilder);
      }
    }
  }
  if (internalDependents != null && internalDependents.isNotEmpty) {
    for (TypeBuilder type in internalDependents) {
      _sortAllTypeParametersTopologicallyFromRoot(type, unhandled, result);
    }
  }
}

abstract class StructuralParameterBuilder extends TypeParameterBuilder {
  /// Sentinel value used to indicate that the variable has no name. This is
  /// used for error recovery.
  static const String noNameSentinel = 'no name sentinel';

  StructuralParameterBuilder({Nullability? nullability}) {
    _nullabilityFromParameterBound = nullability;
  }

  StructuralParameter get parameter;

  @override
  bool get isTypeParameter => true;

  @override
  Variance get variance => parameter.variance;

  @override
  // Coverage-ignore(suite): Not run.
  void set variance(Variance value) {
    parameter.variance = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasUnsetParameterBound =>
      identical(parameter.bound, StructuralParameter.unsetBoundSentinel);

  @override
  // Coverage-ignore(suite): Not run.
  DartType get parameterBound => parameter.bound;

  @override
  // Coverage-ignore(suite): Not run.
  void set parameterBound(DartType bound) {
    parameter.bound = bound;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasUnsetParameterDefaultType => identical(
    parameter.defaultType,
    StructuralParameter.unsetDefaultTypeSentinel,
  );

  @override
  // Coverage-ignore(suite): Not run.
  void set parameterDefaultType(DartType defaultType) {
    parameter.defaultType = defaultType;
  }

  @override
  bool operator ==(Object other) {
    return other is StructuralParameterBuilder && parameter == other.parameter;
  }

  @override
  int get hashCode => parameter.hashCode;

  @override
  DartType buildAliasedType(
    LibraryBuilder library,
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments,
    TypeUse typeUse,
    Uri fileUri,
    int charOffset,
    ClassHierarchyBase? hierarchy, {
    required bool hasExplicitTypeArguments,
  }) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      library.addProblem(
        diag.typeArgumentsOnTypeVariable.withArguments(typeVariableName: name),
        charOffset,
        name.length,
        fileUri,
      );
    }
    // If the bound is not set yet, the actual value is not important yet as it
    // will be set later.
    Nullability nullability;
    if (nullabilityBuilder.isOmitted) {
      nullability = nullabilityFromParameterBound;
    } else {
      // Coverage-ignore-block(suite): Not run.
      nullability = nullabilityBuilder.build();
    }
    StructuralParameterType type = buildAliasedTypeWithBuiltArguments(
      library,
      nullability,
      null,
      typeUse,
      fileUri,
      charOffset,
      hasExplicitTypeArguments: hasExplicitTypeArguments,
    );
    return type;
  }

  @override
  StructuralParameterType buildAliasedTypeWithBuiltArguments(
    LibraryBuilder library,
    Nullability nullability,
    List<DartType>? arguments,
    TypeUse typeUse,
    Uri fileUri,
    int charOffset, {
    required bool hasExplicitTypeArguments,
  }) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri? fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
        diag.typeArgumentsOnTypeVariable.withArguments(typeVariableName: name),
        charOffset,
        name.length,
        fileUri,
      );
    }
    return new StructuralParameterType(parameter, nullability);
  }

  @override
  void finish(
    LibraryBuilder library,
    ClassBuilder object,
    TypeBuilder dynamicType,
  ) {
    DartType objectType = object.buildAliasedType(
      library,
      const NullabilityBuilder.nullable(),
      /* arguments = */ null,
      TypeUse.typeParameterBound,
      fileUri ?? // Coverage-ignore(suite): Not run.
          missingUri,
      fileOffset,
      /* hierarchy = */ null,
      hasExplicitTypeArguments: false,
    );
    if (identical(parameter.bound, StructuralParameter.unsetBoundSentinel)) {
      parameter.bound =
          bound?.build(library, TypeUse.typeParameterBound) ?? objectType;
    }
    // If defaultType is not set, initialize it to dynamic, unless the bound is
    // explicitly specified as Object, in which case defaultType should also be
    // Object. This makes sure instantiation of generic function types with an
    // explicit Object bound results in Object as the instantiated type.
    if (identical(
      parameter.defaultType,
      StructuralParameter.unsetDefaultTypeSentinel,
    )) {
      parameter.defaultType =
          defaultType?.build(library, TypeUse.typeParameterDefaultType) ??
          (bound != null && parameter.bound == objectType
              ? objectType
              : dynamicType.build(library, TypeUse.typeParameterDefaultType));
    }
  }
}

/// This enum is used internally for dependency analysis of potentially cyclic
/// builder dependencies.
enum TraversalState {
  /// An [unvisited] builder isn't yet visited by the traversal algorithm.
  unvisited,

  /// An [active] builder is traversed, but not fully processed.
  active,

  /// A [visited] builder is fully processed.
  visited,
}

/// Represents a cyclic dependency of a type parameter on itself.
///
/// An examples of such dependencies are X  in the following cases.
///
///   typedef F<Y> = Y;
///   extension type E<Y>(Y it) {}
///
///   class A<X extends X> {} // Error.
///   class B<X extends Y, Y extends X> {} // Error.
///   class C<X extends F<Y>, Y extends X> {} // Error.
///   class D<X extends E<Y>, Y extends X> {} // Error.
class TypeParameterCyclicDependency {
  /// Type parameter that's the bound of itself.
  final TypeParameterBuilder typeParameterBoundOfItself;

  /// The elements in a non-trivial self-dependency cycle.
  ///
  /// The loop is considered non-trivial if it includes more than one type
  /// variable.
  final List<TypeParameterBuilder>? viaTypeParameters;

  TypeParameterCyclicDependency(
    this.typeParameterBoundOfItself, {
    this.viaTypeParameters,
  });

  @override
  String toString() {
    return "TypeParameterCyclicDependency("
        "typeParameterBoundOfItself=${typeParameterBoundOfItself}, "
        "viaTypeParameters=${viaTypeParameters})";
  }
}
