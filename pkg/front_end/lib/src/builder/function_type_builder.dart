// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        DartType,
        FunctionType,
        StructuralParameter,
        Nullability,
        NamedType,
        Supertype,
        Variance;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;
import 'package:kernel/src/unaliasing.dart';

import '../codes/cfe_codes.dart' show messageSupertypeIsFunction, noLength;
import '../kernel/implicit_field_type.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import 'declaration_builders.dart';
import 'formal_parameter_builder.dart';
import 'inferable_type_builder.dart';
import 'library_builder.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

abstract class FunctionTypeBuilderImpl extends FunctionTypeBuilder {
  @override
  final TypeBuilder returnType;
  @override
  final List<StructuralParameterBuilder>? typeParameters;
  @override
  final List<ParameterBuilder>? formals;
  @override
  final NullabilityBuilder nullabilityBuilder;
  @override
  final Uri? fileUri;
  @override
  final int charOffset;
  @override
  final bool hasFunctionFormalParameterSyntax;

  factory FunctionTypeBuilderImpl(
      TypeBuilder returnType,
      List<StructuralParameterBuilder>? typeParameters,
      List<ParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri? fileUri,
      int charOffset,
      {bool hasFunctionFormalParameterSyntax = false}) {
    bool isExplicit = true;
    if (!returnType.isExplicit) {
      isExplicit = false;
    }
    if (isExplicit && formals != null) {
      for (ParameterBuilder formal in formals) {
        if (!formal.type.isExplicit) {
          isExplicit = false;
          break;
        }
      }
    }
    if (isExplicit && typeParameters != null) {
      for (StructuralParameterBuilder typeParameter in typeParameters) {
        if (!(typeParameter.bound?.isExplicit ?? true)) {
          isExplicit = false;
          break;
        }
      }
    }
    return isExplicit
        ? new _ExplicitFunctionTypeBuilder(
            returnType,
            typeParameters,
            formals,
            nullabilityBuilder,
            fileUri,
            charOffset,
            hasFunctionFormalParameterSyntax)
        :
        // Coverage-ignore(suite): Not run.
        new _InferredFunctionTypeBuilder(
            returnType,
            typeParameters,
            formals,
            nullabilityBuilder,
            fileUri,
            charOffset,
            hasFunctionFormalParameterSyntax);
  }

  FunctionTypeBuilderImpl._(
      this.returnType,
      this.typeParameters,
      this.formals,
      this.nullabilityBuilder,
      this.fileUri,
      this.charOffset,
      this.hasFunctionFormalParameterSyntax);

  @override
  TypeName? get typeName => null;

  @override
  String get debugName => "Function";

  @override
  // Coverage-ignore(suite): Not run.
  bool get isVoidType => false;

  @override
  StringBuffer printOn(StringBuffer buffer) {
    if (typeParameters != null) {
      // Coverage-ignore-block(suite): Not run.
      buffer.write("<");
      bool isFirst = true;
      for (StructuralParameterBuilder t in typeParameters!) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        buffer.write(t.name);
      }
      buffer.write(">");
    }
    buffer.write("(");
    if (formals != null) {
      // Coverage-ignore-block(suite): Not run.
      bool isFirst = true;
      for (ParameterBuilder t in formals!) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        buffer.write(t.name);
      }
    }
    buffer.write(") ->");
    nullabilityBuilder.writeNullabilityOn(buffer);
    buffer.write(" ");
    buffer.write(returnType.fullNameForErrors);
    return buffer;
  }

  DartType _buildInternal(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    DartType aliasedType = buildAliased(library, typeUse, hierarchy);
    return unalias(aliasedType, legacyEraseAliases: false);
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    assert(hierarchy != null || isExplicit, "Cannot build $this.");
    DartType builtReturnType =
        returnType.buildAliased(library, TypeUse.returnType, hierarchy);
    List<DartType> positionalParameters = <DartType>[];
    List<NamedType>? namedParameters;
    int requiredParameterCount = 0;
    if (formals != null) {
      for (ParameterBuilder formal in formals!) {
        DartType type =
            formal.type.buildAliased(library, TypeUse.parameterType, hierarchy);
        if (formal.isPositional) {
          positionalParameters.add(type);
          if (formal.isRequiredPositional) requiredParameterCount++;
        } else if (formal.isNamed) {
          namedParameters ??= <NamedType>[];
          namedParameters.add(new NamedType(formal.name!, type,
              isRequired: formal.isRequiredNamed));
        }
      }
      if (namedParameters != null) {
        namedParameters.sort();
      }
    }
    List<StructuralParameter>? newTypeParameters;
    if (typeParameters != null) {
      newTypeParameters = <StructuralParameter>[];
      for (StructuralParameterBuilder t in typeParameters!) {
        newTypeParameters.add(t.parameter);
        // Build the bound to detect cycles in typedefs.
        t.bound?.build(library, TypeUse.typeParameterBound);
      }
    }
    return new FunctionType(
        positionalParameters, builtReturnType, nullabilityBuilder.build(),
        namedParameters: namedParameters ?? const <NamedType>[],
        typeParameters: newTypeParameters ?? const <StructuralParameter>[],
        requiredParameterCount: requiredParameterCount);
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library, TypeUse typeUse) {
    library.addProblem(
        messageSupertypeIsFunction, charOffset, noLength, fileUri);
    return null;
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    return buildSupertype(library, TypeUse.classWithType);
  }

  @override
  FunctionTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new FunctionTypeBuilderImpl(returnType, typeParameters, formals,
        nullabilityBuilder, fileUri, charOffset);
  }

  @override
  Nullability computeNullability(
      {required Map<TypeParameterBuilder, TraversalState>
          typeParametersTraversalState}) {
    return nullabilityBuilder.build();
  }

  @override
  VarianceCalculationValue computeTypeParameterBuilderVariance(
      NominalParameterBuilder variable,
      {required SourceLoader sourceLoader}) {
    List<StructuralParameterBuilder>? typeParameters = this.typeParameters;
    List<ParameterBuilder>? formals = this.formals;
    TypeBuilder returnType = this.returnType;

    Variance result = Variance.unrelated;
    if (returnType is! OmittedTypeBuilder) {
      result = result.meet(returnType
          .computeTypeParameterBuilderVariance(variable,
              sourceLoader: sourceLoader)
          .variance!);
    }
    if (typeParameters != null) {
      for (StructuralParameterBuilder typeParameter in typeParameters) {
        // If [variable] is referenced in the bound at all, it makes the
        // variance of [variable] in the entire type invariant.  The
        // invocation of [computeVariance] below is made to simply figure out
        // if [variable] occurs in the bound.
        if (typeParameter.bound != null &&
            typeParameter.bound!.computeTypeParameterBuilderVariance(variable,
                    sourceLoader: sourceLoader) !=
                VarianceCalculationValue.calculatedUnrelated) {
          result = Variance.invariant;
        }
      }
    }
    if (formals != null) {
      for (ParameterBuilder formal in formals) {
        result = result.meet(Variance.contravariant.combine(formal.type
            .computeTypeParameterBuilderVariance(variable,
                sourceLoader: sourceLoader)
            .variance!));
      }
    }
    return new VarianceCalculationValue.fromVariance(result);
  }

  @override
  TypeDeclarationBuilder? computeUnaliasedDeclaration(
          {required bool isUsedAsClass}) =>
      null;

  @override
  void collectReferencesFrom(Map<TypeParameterBuilder, int> parameterIndices,
      List<List<int>> edges, int index) {
    List<StructuralParameterBuilder>? typeParameters = this.typeParameters;
    List<ParameterBuilder>? formals = this.formals;
    TypeBuilder returnType = this.returnType;
    if (typeParameters != null) {
      for (StructuralParameterBuilder typeParameter in typeParameters) {
        typeParameter.bound
            ?.collectReferencesFrom(parameterIndices, edges, index);
      }
    }
    if (formals != null) {
      for (ParameterBuilder parameter in formals) {
        parameter.type.collectReferencesFrom(parameterIndices, edges, index);
      }
    }
    returnType.collectReferencesFrom(parameterIndices, edges, index);
  }

  @override
  TypeBuilder? substituteRange(
      Map<TypeParameterBuilder, TypeBuilder> upperSubstitution,
      Map<TypeParameterBuilder, TypeBuilder> lowerSubstitution,
      List<StructuralParameterBuilder> unboundTypeParameters,
      {final Variance variance = Variance.covariant}) {
    List<StructuralParameterBuilder>? typeParameters = this.typeParameters;
    List<ParameterBuilder>? formals = this.formals;
    TypeBuilder returnType = this.returnType;

    List<StructuralParameterBuilder>? newTypeParameters;
    List<ParameterBuilder>? newFormals;
    TypeBuilder? newReturnType;

    Map<TypeParameterBuilder, TypeBuilder>? functionTypeUpperSubstitution;
    Map<TypeParameterBuilder, TypeBuilder>? functionTypeLowerSubstitution;
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters.length; i++) {
        StructuralParameterBuilder variable = typeParameters[i];
        TypeBuilder? bound;
        if (variable.bound != null) {
          bound = variable.bound!.substituteRange(
              upperSubstitution, lowerSubstitution, unboundTypeParameters,
              variance: Variance.invariant);
        }
        if (bound != null) {
          newTypeParameters ??= typeParameters.toList();
          StructuralParameterBuilder newTypeParameterBuilder =
              newTypeParameters[i] = new StructuralParameterBuilder(
                  variable.name, variable.fileOffset, variable.fileUri,
                  bound: bound);
          unboundTypeParameters.add(newTypeParameterBuilder);
          if (functionTypeUpperSubstitution == null) {
            functionTypeUpperSubstitution = {...upperSubstitution};
            functionTypeLowerSubstitution = {...lowerSubstitution};
          }
          functionTypeUpperSubstitution[variable] =
              functionTypeLowerSubstitution![variable] =
                  new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                      newTypeParameterBuilder,
                      const NullabilityBuilder.omitted(),
                      instanceTypeParameterAccess:
                          InstanceTypeParameterAccessState.Unexpected);
        }
      }
    }
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        ParameterBuilder formal = formals[i];
        TypeBuilder? parameterType = formal.type.substituteRange(
            functionTypeUpperSubstitution ?? upperSubstitution,
            functionTypeLowerSubstitution ?? lowerSubstitution,
            unboundTypeParameters,
            variance: variance.combine(Variance.contravariant));
        if (parameterType != null) {
          newFormals ??= new List.of(formals);
          newFormals[i] = new FunctionTypeParameterBuilder(
              formal.kind, parameterType, formal.name);
        }
      }
    }
    newReturnType = returnType.substituteRange(
        functionTypeUpperSubstitution ?? upperSubstitution,
        functionTypeLowerSubstitution ?? lowerSubstitution,
        unboundTypeParameters,
        variance: variance);

    if (newTypeParameters != null ||
        newFormals != null ||
        newReturnType != null) {
      return new FunctionTypeBuilderImpl(
          newReturnType ?? returnType,
          newTypeParameters ?? typeParameters,
          newFormals ?? formals,
          this.nullabilityBuilder,
          this.fileUri,
          this.charOffset);
    }
    return null;
  }

  @override
  TypeBuilder? unaliasAndErase() => this;

  @override
  bool usesTypeParameters(Set<String> typeParameterNames) {
    if (formals != null) {
      for (ParameterBuilder formal in formals!) {
        if (formal.type.usesTypeParameters(typeParameterNames)) {
          return true;
        }
      }
    }
    if (typeParameters != null) {
      for (StructuralParameterBuilder variable in typeParameters!) {
        if (variable.bound?.usesTypeParameters(typeParameterNames) ?? false) {
          return true;
        }
      }
    }
    return returnType.usesTypeParameters(typeParameterNames);
  }

  @override
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() {
    List<TypeWithInBoundReferences> typesAndDependencies = [];
    List<StructuralParameterBuilder>? typeParameters = this.typeParameters;
    List<ParameterBuilder>? formals = this.formals;
    typesAndDependencies.addAll(returnType.findRawTypesWithInboundReferences());
    if (typeParameters != null) {
      for (StructuralParameterBuilder typeParameter in typeParameters) {
        if (typeParameter.bound != null) {
          typesAndDependencies
              .addAll(typeParameter.bound!.findRawTypesWithInboundReferences());
        }
        if (typeParameter.defaultType != null) {
          // Coverage-ignore-block(suite): Not run.
          typesAndDependencies.addAll(
              typeParameter.defaultType!.findRawTypesWithInboundReferences());
        }
      }
    }
    if (formals != null) {
      for (ParameterBuilder formal in formals) {
        typesAndDependencies
            .addAll(formal.type.findRawTypesWithInboundReferences());
      }
    }
    return typesAndDependencies;
  }
}

/// A function type that is defined without the need for type inference.
///
/// This is the normal function type whose return type or parameter types are
/// either explicit or omitted.
class _ExplicitFunctionTypeBuilder extends FunctionTypeBuilderImpl {
  _ExplicitFunctionTypeBuilder(
      TypeBuilder returnType,
      List<StructuralParameterBuilder>? typeParameters,
      List<ParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri? fileUri,
      int charOffset,
      bool hasFunctionFormalParameterSyntax)
      : super._(returnType, typeParameters, formals, nullabilityBuilder,
            fileUri, charOffset, hasFunctionFormalParameterSyntax);

  @override
  bool get isExplicit => true;

  DartType? _type;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return _type ??= _buildInternal(library, typeUse, hierarchy);
  }
}

// Coverage-ignore(suite): Not run.
/// A function type that needs type inference to be fully defined.
///
/// This occurs through macros where return type or parameter types can be
/// defined in terms of inferred types, making this type indirectly depend
/// on type inference.
class _InferredFunctionTypeBuilder extends FunctionTypeBuilderImpl
    with InferableTypeBuilderMixin {
  _InferredFunctionTypeBuilder(
      TypeBuilder returnType,
      List<StructuralParameterBuilder>? typeParameters,
      List<ParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri? fileUri,
      int charOffset,
      bool hasFunctionFormalParameterSyntax)
      : super._(returnType, typeParameters, formals, nullabilityBuilder,
            fileUri, charOffset, hasFunctionFormalParameterSyntax);

  @override
  bool get isExplicit => false;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    if (hasType) {
      return type;
    } else if (hierarchy != null) {
      return registerType(_buildInternal(library, typeUse, hierarchy));
    } else {
      InferableTypeUse inferableTypeUse =
          new InferableTypeUse(library as SourceLibraryBuilder, this, typeUse);
      library.loader.inferableTypes.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
  }
}
