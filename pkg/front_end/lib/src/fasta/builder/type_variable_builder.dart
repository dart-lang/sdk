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

sealed class TypeVariableBuilderBase extends TypeDeclarationBuilderImpl
    implements TypeDeclarationBuilder {
  TypeBuilder? bound;

  TypeBuilder? defaultType;

  TypeVariableBuilderBase? get actualOrigin;

  final TypeVariableKind kind;

  @override
  final Uri? fileUri;

  TypeVariableBuilderBase(
      String name, Builder? compilationUnit, int charOffset, this.fileUri,
      {this.bound,
      required this.kind,
      int? variableVariance,
      List<MetadataBuilder>? metadata})
      : super(metadata, 0, name, compilationUnit, charOffset);

  @override
  bool get isTypeVariable => true;

  @override
  String get debugName => "TypeVariableBuilderBase";

  @override
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
  TypeVariableBuilderBase get origin => actualOrigin ?? this;

  int get variance;

  void set variance(int value);

  bool get hasUnsetParameterBound;

  DartType get parameterBound;

  void set parameterBound(DartType bound);

  Nullability get nullabilityFromParameterBound;

  bool get hasUnsetParameterDefaultType;

  void set parameterDefaultType(DartType defaultType);

  void finish(SourceLibraryBuilder library, ClassBuilder object,
      TypeBuilder dynamicType);
}

class NominalVariableBuilder extends TypeVariableBuilderBase {
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
      int? variableVariance,
      List<MetadataBuilder>? metadata})
      : actualParameter =
            new TypeParameter(name == noNameSentinel ? null : name, null)
              ..fileOffset = charOffset
              ..variance = variableVariance,
        super(name, compilationUnit, charOffset, fileUri,
            bound: bound,
            kind: kind,
            variableVariance: variableVariance,
            metadata: metadata);

  NominalVariableBuilder.fromKernel(TypeParameter parameter)
      : actualParameter = parameter,
        // TODO(johnniwinther): Do we need to support synthesized type
        //  parameters from kernel?
        super(parameter.name ?? "", null, parameter.fileOffset, null,
            kind: TypeVariableKind.fromKernel);

  @override
  String get debugName => "NominalVariableBuilder";

  @override
  NominalVariableBuilder get origin => actualOrigin ?? this;

  /// The [TypeParameter] built by this builder.
  TypeParameter get parameter => origin.actualParameter;

  @override
  void applyPatch(covariant NominalVariableBuilder patch) {
    patch.actualOrigin = this;
  }

  @override
  int get variance => parameter.variance;

  @override
  void set variance(int value) {
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
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    // If the bound is not set yet, the actual value is not important yet as it
    // will be set later.
    bool needsPostUpdate =
        nullabilityBuilder.isOmitted && hasUnsetParameterBound ||
            library is SourceLibraryBuilder &&
                library.hasPendingNullability(parameterBound);
    Nullability nullability;
    if (nullabilityBuilder.isOmitted) {
      if (needsPostUpdate) {
        nullability = Nullability.legacy;
      } else {
        nullability = library.isNonNullableByDefault
            ? nullabilityFromParameterBound
            : Nullability.legacy;
      }
    } else {
      nullability = nullabilityBuilder.build(library);
    }
    TypeParameterType type = buildAliasedTypeWithBuiltArguments(
        library, nullability, null, typeUse, fileUri, charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
    if (needsPostUpdate) {
      if (library is SourceLibraryBuilder) {
        library.registerPendingNullability(
            this.fileUri!, this.charOffset, type);
      } else {
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
      List<DelayedActionPerformer> delayedActionPerformers,
      Scope scope) {
    MetadataBuilder.buildAnnotations(parameter, metadata, bodyBuilderContext,
        libraryBuilder, fileUri!, scope);
  }

  @override
  void finish(SourceLibraryBuilder library, ClassBuilder object,
      TypeBuilder dynamicType) {
    if (isPatch) return;
    DartType objectType = object.buildAliasedType(
        library,
        library.nullableBuilder,
        /* arguments = */ null,
        TypeUse.typeParameterBound,
        fileUri ?? missingUri,
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

  NominalVariableBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    // TODO(cstefantsova): Figure out if using [charOffset] here is a good
    // idea.  An alternative is to use the offset of the node the cloned type
    // variable is declared on.
    return new NominalVariableBuilder(name, parent!, charOffset, fileUri,
        bound: bound?.clone(newTypes, contextLibrary, contextDeclaration),
        variableVariance: variance,
        kind: kind);
  }

  static List<TypeParameter>? typeParametersFromBuilders(
      List<NominalVariableBuilder>? builders) {
    if (builders == null) return null;
    return new List<TypeParameter>.generate(
        builders.length, (int i) => builders[i].parameter,
        growable: true);
  }
}

List< /* TypeVariableBuilder | FunctionTypeTypeVariableBuilder */ Object>
    sortAllTypeVariablesTopologically(
        Iterable< /* TypeVariableBuilder | FunctionTypeTypeVariableBuilder */
                Object>
            typeVariables) {
  assert(typeVariables.every((typeVariable) =>
      typeVariable is NominalVariableBuilder ||
      typeVariable is StructuralVariableBuilder));

  Set< /* TypeVariableBuilder | FunctionTypeTypeVariableBuilder */ Object>
      unhandled = new Set<Object>.identity()..addAll(typeVariables);
  List< /* TypeVariableBuilder | FunctionTypeTypeVariableBuilder */ Object>
      result = <Object>[];
  while (unhandled.isNotEmpty) {
    Object rootVariable = unhandled.first;
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

class StructuralVariableBuilder extends TypeVariableBuilderBase {
  /// Sentinel value used to indicate that the variable has no name. This is
  /// used for error recovery.
  static const String noNameSentinel = 'no name sentinel';

  final StructuralParameter actualParameter;

  @override
  StructuralVariableBuilder? actualOrigin;

  StructuralVariableBuilder(
      String name, Builder? compilationUnit, int charOffset, Uri? fileUri,
      {TypeBuilder? bound,
      int? variableVariance,
      List<MetadataBuilder>? metadata})
      : actualParameter =
            new StructuralParameter(name == noNameSentinel ? null : name, null)
              ..fileOffset = charOffset
              ..variance = variableVariance,
        super(name, compilationUnit, charOffset, fileUri,
            bound: bound,
            kind: TypeVariableKind.function,
            variableVariance: variableVariance,
            metadata: metadata);

  StructuralVariableBuilder.fromKernel(StructuralParameter parameter)
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
  int get variance => parameter.variance;

  @override
  void set variance(int value) {
    parameter.variance = value;
  }

  @override
  bool get hasUnsetParameterBound =>
      identical(parameter.bound, StructuralParameter.unsetBoundSentinel);

  @override
  DartType get parameterBound => parameter.bound;

  @override
  void set parameterBound(DartType bound) {
    parameter.bound = bound;
  }

  @override
  Nullability get nullabilityFromParameterBound =>
      StructuralParameterType.computeNullabilityFromBound(parameter);

  @override
  bool get hasUnsetParameterDefaultType => identical(
      parameter.defaultType, StructuralParameter.unsetDefaultTypeSentinel);

  @override
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
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    // If the bound is not set yet, the actual value is not important yet as it
    // will be set later.
    bool needsPostUpdate = nullabilityBuilder.isOmitted &&
            identical(
                parameter.bound, StructuralParameter.unsetBoundSentinel) ||
        library is SourceLibraryBuilder &&
            library.hasPendingNullability(parameter.bound);
    Nullability nullability;
    if (nullabilityBuilder.isOmitted) {
      if (needsPostUpdate) {
        nullability = Nullability.legacy;
      } else {
        nullability = library.isNonNullableByDefault
            ? StructuralParameterType.computeNullabilityFromBound(parameter)
            : Nullability.legacy;
      }
    } else {
      nullability = nullabilityBuilder.build(library);
    }
    StructuralParameterType type = buildAliasedTypeWithBuiltArguments(
        library, nullability, null, typeUse, fileUri, charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
    if (needsPostUpdate) {
      if (library is SourceLibraryBuilder) {
        library.registerPendingFunctionTypeNullability(
            this.fileUri!, this.charOffset, type);
      } else {
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
    if (isPatch) return;
    DartType objectType = object.buildAliasedType(
        library,
        library.nullableBuilder,
        /* arguments = */ null,
        TypeUse.typeParameterBound,
        fileUri ?? missingUri,
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
  void applyPatch(covariant StructuralVariableBuilder patch) {
    patch.actualOrigin = this;
  }

  StructuralVariableBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    // TODO(cstefantsova): Figure out if using [charOffset] here is a good
    // idea.  An alternative is to use the offset of the node the cloned type
    // variable is declared on.
    return new StructuralVariableBuilder(name, parent!, charOffset, fileUri,
        bound: bound?.clone(newTypes, contextLibrary, contextDeclaration),
        variableVariance: variance);
  }

  static List<TypeParameter>? typeParametersFromBuilders(
      List<NominalVariableBuilder>? builders) {
    if (builders == null) return null;
    return new List<TypeParameter>.generate(
        builders.length, (int i) => builders[i].parameter,
        growable: true);
  }
}

class FreshStructuralVariableBuildersFromNominalVariableBuilders {
  final List<StructuralVariableBuilder> freshStructuralVariableBuilders;
  final Map<NominalVariableBuilder, TypeBuilder> substitutionMap;

  FreshStructuralVariableBuildersFromNominalVariableBuilders(
      this.freshStructuralVariableBuilders, this.substitutionMap);
}
