// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

enum TypeVariableKind {
  /// A type variable declared on a function, method, or local function.
  function,

  /// A type variable declared on a class, mixin or enum.
  classMixinOrEnum,

  /// A type variable declared on an extension or an extension type.
  extensionOrExtensionType,

  /// A type variable on an extension instance member synthesized from an
  /// extension type variable.
  extensionSynthesized,

  /// A type variable builder created from a kernel node.
  fromKernel,
}

sealed class TypeVariableBuilder extends TypeDeclarationBuilderImpl
    implements TypeDeclarationBuilder {
  TypeBuilder? bound;

  TypeBuilder? defaultType;

  TypeVariableBuilder? get actualOrigin;

  final TypeVariableKind kind;

  final bool isWildcard;

  @override
  final Uri? fileUri;

  TypeVariableBuilder(
      String name, Builder? compilationUnit, int charOffset, this.fileUri,
      {this.bound,
      this.defaultType,
      required this.kind,
      Variance? variableVariance,
      List<MetadataBuilder>? metadata,
      this.isWildcard = false})
      : super(metadata, 0, name, compilationUnit, charOffset);

  @override
  bool get isTypeVariable => true;

  @override
  String get debugName => "TypeVariableBuilderBase";

  @override
  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (bound != null) {
      buffer.write(" extends ");
      bound!.printOn(buffer);
    }
    return buffer;
  }

  @override
  String toString() => "${printOn(new StringBuffer())}";

  @override
  // Coverage-ignore(suite): Not run.
  TypeVariableBuilder get origin => actualOrigin ?? this;

  Variance get variance;

  void set variance(Variance value);

  /// Unused in interface; left in on purpose.
  bool get hasUnsetParameterBound;

  DartType get parameterBound;

  void set parameterBound(DartType bound);

  /// Unused in interface; left in on purpose.
  Nullability get nullabilityFromParameterBound;

  /// Unused in interface; left in on purpose.
  bool get hasUnsetParameterDefaultType;

  void set parameterDefaultType(DartType defaultType);

  void finish(SourceLibraryBuilder library, ClassBuilder object,
      TypeBuilder dynamicType);

  TypeBuilder? _unaliasAndErase(TypeBuilder? typeBuilder) {
    if (typeBuilder is! NamedTypeBuilder) {
      return typeBuilder;
    } else {
      TypeDeclarationBuilder? declaration = typeBuilder.declaration;
      if (declaration is TypeAliasBuilder) {
        // We pass empty lists as [unboundTypes] and [unboundTypeVariables]
        // because new builders can be generated during unaliasing. We ignore
        // the returned builders, however, because they will not be used in the
        // output and are needed only for the checks.
        //
        // We also don't instantiate-to-bound raw types because it won't affect
        // the dependency cycle analysis.
        return _unaliasAndErase(declaration.unalias(typeBuilder.typeArguments,
            unboundTypes: [], unboundTypeVariables: []));
      } else if (declaration is ExtensionTypeDeclarationBuilder) {
        TypeBuilder? representationType =
            declaration.declaredRepresentationTypeBuilder;
        if (representationType == null) {
          return null;
        } else {
          List<NominalVariableBuilder>? typeParameters =
              declaration.typeParameters;
          List<TypeBuilder>? typeArguments = typeBuilder.typeArguments;
          if (typeParameters != null && typeArguments != null) {
            representationType = representationType.subst(
                new Map<NominalVariableBuilder, TypeBuilder>.fromIterables(
                    typeParameters, typeArguments));
          }
          return _unaliasAndErase(representationType);
        }
      } else {
        return typeBuilder;
      }
    }
  }

  TypeVariableCyclicDependency? findCyclicDependency(
      {Map<TypeVariableBuilder, TypeVariableTraversalState>?
          typeVariablesTraversalState,
      Map<TypeVariableBuilder, TypeVariableBuilder>? cycleElements}) {
    // Coverage-ignore(suite): Not run.
    typeVariablesTraversalState ??= {};
    cycleElements ??= {};

    switch (typeVariablesTraversalState[this] ??=
        TypeVariableTraversalState.unvisited) {
      case TypeVariableTraversalState.visited:
        return null;
      case TypeVariableTraversalState.active:
        typeVariablesTraversalState[this] = TypeVariableTraversalState.visited;
        List<TypeVariableBuilder>? viaTypeVariables;
        TypeVariableBuilder? nextViaTypeVariable = cycleElements[this];
        while (nextViaTypeVariable != null && nextViaTypeVariable != this) {
          (viaTypeVariables ??= []).add(nextViaTypeVariable);
          nextViaTypeVariable = cycleElements[nextViaTypeVariable];
        }
        return new TypeVariableCyclicDependency(this,
            viaTypeVariables: viaTypeVariables);
      case TypeVariableTraversalState.unvisited:
        typeVariablesTraversalState[this] = TypeVariableTraversalState.active;
        TypeBuilder? bound = this.bound;
        if (bound is NamedTypeBuilder) {
          TypeBuilder? unaliasedAndErasedBound = _unaliasAndErase(bound);
          TypeDeclarationBuilder? unaliasedAndErasedBoundDeclaration =
              unaliasedAndErasedBound?.declaration;
          TypeVariableBuilder? nextVariable;
          if (unaliasedAndErasedBoundDeclaration is TypeVariableBuilder) {
            nextVariable = unaliasedAndErasedBoundDeclaration;
          }

          if (nextVariable != null) {
            cycleElements[this] = nextVariable;
            TypeVariableCyclicDependency? result =
                nextVariable.findCyclicDependency(
                    typeVariablesTraversalState: typeVariablesTraversalState,
                    cycleElements: cycleElements);
            typeVariablesTraversalState[this] =
                TypeVariableTraversalState.visited;
            return result;
          } else {
            typeVariablesTraversalState[this] =
                TypeVariableTraversalState.visited;
            return null;
          }
        } else {
          typeVariablesTraversalState[this] =
              TypeVariableTraversalState.visited;
          return null;
        }
    }
  }
}

class NominalVariableBuilder extends TypeVariableBuilder {
  /// Sentinel value used to indicate that the variable has no name. This is
  /// used for error recovery.
  static const String noNameSentinel = 'no name sentinel';

  final TypeParameter actualParameter;

  @override
  NominalVariableBuilder? actualOrigin;

  NominalVariableBuilder(
      String name, Builder? compilationUnit, int charOffset, Uri? fileUri,
      {TypeBuilder? bound,
      required TypeVariableKind kind,
      Variance? variableVariance,
      List<MetadataBuilder>? metadata,
      super.isWildcard = false})
      : actualParameter =
            new TypeParameter(name == noNameSentinel ? null : name, null)
              ..fileOffset = charOffset
              ..variance = variableVariance,
        _varianceCalculationValue = new VarianceCalculationValue.fromVariance(
            variableVariance ?? Variance.covariant),
        super(name, compilationUnit, charOffset, fileUri,
            bound: bound,
            kind: kind,
            variableVariance: variableVariance,
            metadata: metadata);

  /// Restores a [NominalVariableBuilder] from kernel
  ///
  /// The [loader] parameter is supposed to be passed by the clients and be not
  /// null. It is needed to restore [bound] and [defaultType] of the type
  /// variable from dill. The null value of this parameter is used only once in
  /// [TypeBuilderComputer] to break the infinite loop of recovering type
  /// variables of some recursive declarations, like the declaration of `A` in
  /// the example below.
  ///
  ///   class A<X extends A<X>> {}
  NominalVariableBuilder.fromKernel(TypeParameter parameter,
      {required Loader? loader, super.isWildcard = false})
      : actualParameter = parameter,
        // TODO(johnniwinther): Do we need to support synthesized type
        //  parameters from kernel?
        _varianceCalculationValue =
            new VarianceCalculationValue.fromVariance(parameter.variance),
        super(parameter.name ?? "", null, parameter.fileOffset, null,
            kind: TypeVariableKind.fromKernel,
            bound: loader?.computeTypeBuilder(parameter.bound),
            defaultType: loader?.computeTypeBuilder(parameter.defaultType));

  @override
  String get debugName => "NominalVariableBuilder";

  @override
  NominalVariableBuilder get origin => actualOrigin ?? this;

  /// The [TypeParameter] built by this builder.
  TypeParameter get parameter => origin.actualParameter;

  @override
  void applyAugmentation(covariant NominalVariableBuilder augmentation) {
    augmentation.actualOrigin = this;
  }

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
    _varianceCalculationValue =
        new VarianceCalculationValue.fromVariance(value);
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
  Nullability get nullabilityFromParameterBound =>
      TypeParameterType.computeNullabilityFromBound(parameter);

  @override
  bool get hasUnsetParameterDefaultType =>
      identical(parameter.defaultType, TypeParameter.unsetDefaultTypeSentinel);

  @override
  void set parameterDefaultType(DartType defaultType) {
    parameter.defaultType = defaultType;
  }

  @override
  bool operator ==(Object other) {
    return other is NominalVariableBuilder && parameter == other.parameter;
  }

  @override
  int get hashCode => parameter.hashCode;

  @override
  TypeParameterType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri? fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
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
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    // If the bound is not set yet, the actual value is not important yet as it
    // will be set later.
    TypeBuilder? boundBuilder = bound;
    TypeDeclarationBuilder? boundDeclarationBuilder =
        boundBuilder is NamedTypeBuilder ? boundBuilder.declaration : null;
    bool needsPostUpdate =
        nullabilityBuilder.isOmitted && hasUnsetParameterBound ||
            library is SourceLibraryBuilder &&
                library.hasPendingNullability(parameterBound) ||
            nullabilityBuilder.isOmitted &&
                boundDeclarationBuilder is ExtensionTypeDeclarationBuilder &&
                !boundDeclarationBuilder.hasInterfacesBuilt;
    Nullability nullability;
    if (nullabilityBuilder.isOmitted) {
      if (needsPostUpdate) {
        nullability = Nullability.legacy;
      } else {
        nullability = nullabilityFromParameterBound;
      }
    } else {
      nullability = nullabilityBuilder.build();
    }
    TypeParameterType type = buildAliasedTypeWithBuiltArguments(
        library, nullability, null, typeUse, fileUri, charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
    if (needsPostUpdate) {
      if (library is SourceLibraryBuilder) {
        library.registerPendingNullability(
            this.fileUri!, this.charOffset, type);
      } else {
        // Coverage-ignore-block(suite): Not run.
        library.addProblem(
            templateInternalProblemUnfinishedTypeVariable.withArguments(
                name, library.importUri),
            this.charOffset,
            name.length,
            this.fileUri);
      }
    }
    return type;
  }

  void buildOutlineExpressions(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      ClassHierarchy classHierarchy,
      LookupScope scope) {
    MetadataBuilder.buildAnnotations(parameter, metadata, bodyBuilderContext,
        libraryBuilder, fileUri!, scope);
  }

  @override
  void finish(SourceLibraryBuilder library, ClassBuilder object,
      TypeBuilder dynamicType) {
    if (isAugmenting) return;
    DartType objectType = object.buildAliasedType(
        library,
        const NullabilityBuilder.nullable(),
        /* arguments = */ null,
        TypeUse.typeParameterBound,
        fileUri ?? // Coverage-ignore(suite): Not run.
            missingUri,
        charOffset,
        /* hierarchy = */ null,
        hasExplicitTypeArguments: false);
    if (hasUnsetParameterBound) {
      parameterBound =
          bound?.build(library, TypeUse.typeParameterBound) ?? objectType;
    }
    // If defaultType is not set, initialize it to dynamic, unless the bound is
    // explicitly specified as Object, in which case defaultType should also be
    // Object. This makes sure instantiation of generic function types with an
    // explicit Object bound results in Object as the instantiated type.
    if (hasUnsetParameterDefaultType) {
      parameterDefaultType = defaultType?.build(
              library, TypeUse.typeParameterDefaultType) ??
          (bound != null && parameterBound == objectType
              ? objectType
              : dynamicType.build(library, TypeUse.typeParameterDefaultType));
    }
  }

  static List<TypeParameter>? typeParametersFromBuilders(
      List<NominalVariableBuilder>? builders) {
    if (builders == null) return null;
    return new List<TypeParameter>.generate(
        builders.length, (int i) => builders[i].parameter,
        growable: true);
  }
}

List<TypeVariableBuilder> sortAllTypeVariablesTopologically(
    Iterable<TypeVariableBuilder> typeVariables) {
  assert(typeVariables.every((typeVariable) =>
      typeVariable is NominalVariableBuilder ||
      typeVariable is StructuralVariableBuilder));

  Set<TypeVariableBuilder> unhandled = new Set<TypeVariableBuilder>.identity()
    ..addAll(typeVariables);
  List<TypeVariableBuilder> result = <TypeVariableBuilder>[];
  while (unhandled.isNotEmpty) {
    TypeVariableBuilder rootVariable = unhandled.first;
    unhandled.remove(rootVariable);

    TypeBuilder? rootVariableBound;
    if (rootVariable is NominalVariableBuilder) {
      rootVariableBound = rootVariable.bound;
    } else {
      rootVariable as StructuralVariableBuilder;
      rootVariableBound = rootVariable.bound;
    }

    if (rootVariableBound != null) {
      _sortAllTypeVariablesTopologicallyFromRoot(
          rootVariableBound, unhandled, result);
    }
    result.add(rootVariable);
  }
  return result;
}

void _sortAllTypeVariablesTopologicallyFromRoot(
    TypeBuilder root,
    Set< /* TypeVariableBuilder | FunctionTypeTypeVariableBuilder */ Object>
        unhandled,
    List< /* TypeVariableBuilder | FunctionTypeTypeVariableBuilder */ Object>
        result) {
  assert(unhandled.every((typeVariable) =>
      typeVariable is NominalVariableBuilder ||
      typeVariable is StructuralVariableBuilder));
  assert(result.every((typeVariable) =>
      typeVariable is NominalVariableBuilder ||
      typeVariable is StructuralVariableBuilder));

  List< /* TypeVariableBuilder | FunctionTypeTypeVariableBuilder */ Object>?
      foundTypeVariables;
  List<TypeBuilder>? internalDependents;

  switch (root) {
    case NamedTypeBuilder(:TypeDeclarationBuilder? declaration):
      switch (declaration) {
        case ClassBuilder():
          foundTypeVariables = declaration.typeVariables;
        case TypeAliasBuilder():
          foundTypeVariables = declaration.typeVariables;
          internalDependents = <TypeBuilder>[declaration.type];
        case NominalVariableBuilder():
          foundTypeVariables = <NominalVariableBuilder>[declaration];
        case StructuralVariableBuilder():
          foundTypeVariables = <StructuralVariableBuilder>[declaration];
        case ExtensionTypeDeclarationBuilder():
        // TODO(johnniwinther):: Handle this case.
        case ExtensionBuilder():
        case BuiltinTypeDeclarationBuilder():
        case InvalidTypeDeclarationBuilder():
        // Coverage-ignore(suite): Not run.
        // TODO(johnniwinther): How should we handle this case?
        case OmittedTypeDeclarationBuilder():
        case null:
      }
    case FunctionTypeBuilder(
        :List<StructuralVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      foundTypeVariables = typeVariables;
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
        :List<RecordTypeFieldBuilder>? namedFields
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
    // Coverage-ignore(suite): Not run.
    case OmittedTypeBuilder():
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
  }

  if (foundTypeVariables != null && foundTypeVariables.isNotEmpty) {
    for (Object variable in foundTypeVariables) {
      if (unhandled.contains(variable)) {
        unhandled.remove(variable);

        TypeBuilder? variableBound;
        if (variable is NominalVariableBuilder) {
          variableBound = variable.bound;
        } else {
          variable as StructuralVariableBuilder;
          variableBound = variable.bound;
        }

        if (variableBound != null) {
          _sortAllTypeVariablesTopologicallyFromRoot(
              variableBound, unhandled, result);
        }
        result.add(variable);
      }
    }
  }
  if (internalDependents != null && internalDependents.isNotEmpty) {
    for (TypeBuilder type in internalDependents) {
      _sortAllTypeVariablesTopologicallyFromRoot(type, unhandled, result);
    }
  }
}

class StructuralVariableBuilder extends TypeVariableBuilder {
  /// Sentinel value used to indicate that the variable has no name. This is
  /// used for error recovery.
  static const String noNameSentinel = 'no name sentinel';

  final StructuralParameter actualParameter;

  @override
  StructuralVariableBuilder? actualOrigin;

  StructuralVariableBuilder(
      String name, Builder? compilationUnit, int charOffset, Uri? fileUri,
      {TypeBuilder? bound,
      Variance? variableVariance,
      List<MetadataBuilder>? metadata,
      super.isWildcard = false})
      : actualParameter =
            new StructuralParameter(name == noNameSentinel ? null : name, null)
              ..fileOffset = charOffset
              ..variance = variableVariance,
        super(name, compilationUnit, charOffset, fileUri,
            bound: bound,
            kind: TypeVariableKind.function,
            variableVariance: variableVariance,
            metadata: metadata);

  StructuralVariableBuilder.fromKernel(StructuralParameter parameter,
      {super.isWildcard = false})
      : actualParameter = parameter,
        // TODO(johnniwinther): Do we need to support synthesized type
        //  parameters from kernel?
        super(parameter.name ?? "", null, parameter.fileOffset, null,
            kind: TypeVariableKind.fromKernel);

  @override
  bool get isTypeVariable => true;

  @override
  String get debugName => "StructuralVariableBuilder";

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
  Nullability get nullabilityFromParameterBound =>
      StructuralParameterType.computeNullabilityFromBound(parameter);

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasUnsetParameterDefaultType => identical(
      parameter.defaultType, StructuralParameter.unsetDefaultTypeSentinel);

  @override
  // Coverage-ignore(suite): Not run.
  void set parameterDefaultType(DartType defaultType) {
    parameter.defaultType = defaultType;
  }

  @override
  bool operator ==(Object other) {
    return other is StructuralVariableBuilder && parameter == other.parameter;
  }

  @override
  int get hashCode => parameter.hashCode;

  @override
  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (bound != null) {
      buffer.write(" extends ");
      bound!.printOn(buffer);
    }
    return buffer;
  }

  @override
  String toString() => "${printOn(new StringBuffer())}";

  @override
  StructuralVariableBuilder get origin => actualOrigin ?? this;

  /// The [StructuralParameter] built by this builder.
  StructuralParameter get parameter => origin.actualParameter;

  @override
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    // If the bound is not set yet, the actual value is not important yet as it
    // will be set later.
    TypeBuilder? boundBuilder = bound;
    TypeDeclarationBuilder? boundDeclarationBuilder =
        boundBuilder is NamedTypeBuilder ? boundBuilder.declaration : null;
    bool needsPostUpdate = nullabilityBuilder.isOmitted &&
            identical(
                parameter.bound, StructuralParameter.unsetBoundSentinel) ||
        library is SourceLibraryBuilder &&
            library.hasPendingNullability(parameter.bound) ||
        nullabilityBuilder.isOmitted &&
            boundDeclarationBuilder is ExtensionTypeDeclarationBuilder &&
            !boundDeclarationBuilder.hasInterfacesBuilt;
    Nullability nullability;
    if (nullabilityBuilder.isOmitted) {
      if (needsPostUpdate) {
        nullability = Nullability.legacy;
      } else {
        nullability =
            StructuralParameterType.computeNullabilityFromBound(parameter);
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      nullability = nullabilityBuilder.build();
    }
    StructuralParameterType type = buildAliasedTypeWithBuiltArguments(
        library, nullability, null, typeUse, fileUri, charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
    if (needsPostUpdate) {
      if (library is SourceLibraryBuilder) {
        library.registerPendingFunctionTypeNullability(
            this.fileUri!, this.charOffset, type);
      } else {
        // Coverage-ignore-block(suite): Not run.
        library.addProblem(
            templateInternalProblemUnfinishedTypeVariable.withArguments(
                name, library.importUri),
            this.charOffset,
            name.length,
            this.fileUri);
      }
    }
    return type;
  }

  @override
  StructuralParameterType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    if (arguments != null) {
      // Coverage-ignore-block(suite): Not run.
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri? fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    return new StructuralParameterType(parameter, nullability);
  }

  @override
  void finish(
      LibraryBuilder library, ClassBuilder object, TypeBuilder dynamicType) {
    if (isAugmenting) return;
    DartType objectType = object.buildAliasedType(
        library,
        const NullabilityBuilder.nullable(),
        /* arguments = */ null,
        TypeUse.typeParameterBound,
        fileUri ?? // Coverage-ignore(suite): Not run.
            missingUri,
        charOffset,
        /* hierarchy = */ null,
        hasExplicitTypeArguments: false);
    if (identical(parameter.bound, StructuralParameter.unsetBoundSentinel)) {
      parameter.bound =
          bound?.build(library, TypeUse.typeParameterBound) ?? objectType;
    }
    // If defaultType is not set, initialize it to dynamic, unless the bound is
    // explicitly specified as Object, in which case defaultType should also be
    // Object. This makes sure instantiation of generic function types with an
    // explicit Object bound results in Object as the instantiated type.
    if (identical(
        parameter.defaultType, StructuralParameter.unsetDefaultTypeSentinel)) {
      parameter.defaultType = defaultType?.build(
              library, TypeUse.typeParameterDefaultType) ??
          (bound != null && parameter.bound == objectType
              ? objectType
              : dynamicType.build(library, TypeUse.typeParameterDefaultType));
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void applyAugmentation(covariant StructuralVariableBuilder augmentation) {
    augmentation.actualOrigin = this;
  }
}

/// This enum is used internally for dependency analysis of type variables.
enum TypeVariableTraversalState {
  /// An [unvisited] type variable isn't yet visited by the traversal algorithm.
  unvisited,

  /// An [active] type variable is traversed, but not fully processed.
  active,

  /// A [visited] type variable is fully processed.
  visited;
}

/// Represents a cyclic dependency of a type variable on itself.
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
class TypeVariableCyclicDependency {
  /// Type variable that's the bound of itself.
  final TypeVariableBuilder typeVariableBoundOfItself;

  /// The elements in a non-trivial self-dependency cycle.
  ///
  /// The loop is considered non-trivial if it includes more than one type
  /// variable.
  final List<TypeVariableBuilder>? viaTypeVariables;

  TypeVariableCyclicDependency(this.typeVariableBoundOfItself,
      {this.viaTypeVariables});

  @override
  String toString() {
    return "TypeVariableCyclicDependency("
        "typeVariableBoundOfItself=${typeVariableBoundOfItself}, "
        "viaTypeVariable=${viaTypeVariables})";
  }
}
