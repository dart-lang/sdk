// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/implicit_field_type.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import '../source/type_parameter_factory.dart';
import '../util/helpers.dart';
import 'declaration_builders.dart';
import 'inferable_type_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

abstract class OmittedTypeBuilderImpl extends OmittedTypeBuilder {
  const OmittedTypeBuilderImpl();

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    throw new UnsupportedError('$runtimeType.buildMixedInType');
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library, TypeUse typeUse) {
    throw new UnsupportedError('$runtimeType.buildSupertype');
  }

  @override
  // Coverage-ignore(suite): Not run.
  int? get charOffset => null;

  @override
  // Coverage-ignore(suite): Not run.
  Uri? get fileUri => null;

  @override
  // Coverage-ignore(suite): Not run.
  TypeName? get typeName => null;

  @override
  // Coverage-ignore(suite): Not run.
  NullabilityBuilder get nullabilityBuilder =>
      const NullabilityBuilder.omitted();

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) {
    return this;
  }

  @override
  bool get hasType;

  @override
  DartType get type;

  @override
  VarianceCalculationValue computeTypeParameterBuilderVariance(
    NominalParameterBuilder variable, {
    required SourceLoader sourceLoader,
  }) {
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeDeclarationBuilder? computeUnaliasedDeclaration({
    required bool isUsedAsClass,
  }) => null;

  @override
  void collectReferencesFrom(
    Map<TypeParameterBuilder, int> parameterIndices,
    List<List<int>> edges,
    int index,
  ) {}

  @override
  TypeBuilder? substituteRange(
    Map<TypeParameterBuilder, TypeBuilder> upperSubstitution,
    Map<TypeParameterBuilder, TypeBuilder> lowerSubstitution,
    TypeParameterFactory typeParameterFactory, {
    Variance variance = Variance.covariant,
  }) {
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder? unaliasAndErase() => this;

  @override
  bool usesTypeParameters(Set<String> typeParameterNames) => false;

  @override
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() =>
      const [];
}

/// [TypeBuilder] for when there is no explicit type provided by the user and
/// the type _cannot_ be inferred from context.
///
/// For omitted return types and parameter types of instance method,
/// field types and initializing formal types, use [InferableTypeBuilder]
/// instead. This should be created through
/// [SourceLibraryBuilder.addInferableType] to ensure the type is inferred.
class ImplicitTypeBuilder extends OmittedTypeBuilderImpl {
  const ImplicitTypeBuilder();

  @override
  DartType build(
    LibraryBuilder library,
    TypeUse typeUse, {
    ClassHierarchyBase? hierarchy,
  }) => type;

  @override
  DartType buildAliased(
    LibraryBuilder library,
    TypeUse typeUse,
    ClassHierarchyBase? hierarchy,
  ) => type;

  @override
  String get debugName => 'ImplicitTypeBuilder';

  @override
  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) => buffer;

  @override
  bool get isExplicit => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasType => true;

  @override
  DartType get type => const DynamicType();

  @override
  // Coverage-ignore(suite): Not run.
  Nullability computeNullability({
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) => type.nullability;
}

/// [TypeBuilder] for when there is no explicit type provided by the user but
/// the type _can_ be inferred from context. For instance omitted return types
/// and parameter types of instance method,
///
/// [InferableTypeBuilder] should be created through
/// [SourceLibraryBuilder.addInferableType] to ensure the type is inferred.
class InferableTypeBuilder extends OmittedTypeBuilderImpl
    with InferableTypeBuilderMixin
    implements InferableType {
  final InferenceDefaultType inferenceDefaultType;

  InferableTypeBuilder(this.inferenceDefaultType);

  @override
  DartType build(
    LibraryBuilder library,
    TypeUse typeUse, {
    ClassHierarchyBase? hierarchy,
  }) {
    if (hierarchy != null) {
      inferType(hierarchy);
      return type;
    } else {
      InferableTypeUse inferableTypeUse = new InferableTypeUse(
        library as SourceLibraryBuilder,
        this,
        typeUse,
      );
      library.loader.inferableTypes.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType buildAliased(
    LibraryBuilder library,
    TypeUse typeUse,
    ClassHierarchyBase? hierarchy,
  ) {
    if (hierarchy != null) {
      inferType(hierarchy);
      return type;
    }
    throw new UnsupportedError('$runtimeType.buildAliased');
  }

  @override
  bool get isExplicit => false;

  @override
  void registerInferredType(DartType type) {
    registerType(type);
  }

  Inferable? _inferable;

  // Coverage-ignore(suite): Not run.
  Inferable? get inferable => _inferable;

  @override
  void registerInferable(Inferable inferable) {
    assert(
      _inferable == null,
      "Inferable $_inferable has already been register, "
      "trying to register $inferable.",
    );
    _inferable = inferable;
  }

  /// Triggers inference of this type.
  ///
  /// If an [Inferable] has been register, this is called to infer the type of
  /// this builder. Otherwise the type is inferred to be `dynamic`.
  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    if (!hasType) {
      Inferable? inferable = _inferable;
      if (inferable != null) {
        inferable.inferTypes(hierarchy);
      } else {
        switch (inferenceDefaultType) {
          case InferenceDefaultType.NullableObject:
            registerInferredType(hierarchy.coreTypes.objectNullableRawType);
          case InferenceDefaultType.Dynamic:
            registerInferredType(const DynamicType());
        }
      }
      assert(hasType, "No type computed for $this");
    }
    return type;
  }

  @override
  String get debugName => 'InferredTypeBuilder';

  @override
  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write('(inferable=');
    buffer.write(inferable);
    buffer.write(')');
    return buffer;
  }

  @override
  Nullability computeNullability({
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) {
    throw new UnsupportedError("$runtimeType.computeNullability");
  }
}

/// Listener for the late computation of an inferred type.
abstract class InferredTypeListener {
  /// Called when the type of an [InferableTypeBuilder] has been computed.
  void onInferredType(DartType type);
}

/// Interface for builders that can infer the type of an [InferableTypeBuilder].
abstract class Inferable {
  /// Triggers the inference of the types of one or more
  /// [InferableTypeBuilder]s.
  void inferTypes(ClassHierarchyBase hierarchy);
}

class InferableTypes {
  final List<InferableType> _inferableTypes = [];

  InferableTypeBuilder addInferableType(
    InferenceDefaultType inferenceDefaultType,
  ) {
    InferableTypeBuilder typeBuilder = new InferableTypeBuilder(
      inferenceDefaultType,
    );
    registerInferableType(typeBuilder);
    return typeBuilder;
  }

  void registerInferableType(InferableType inferableType) {
    _inferableTypes.add(inferableType);
  }

  void inferTypes(ClassHierarchyBuilder classHierarchyBuilder) {
    for (InferableType typeBuilder in _inferableTypes) {
      typeBuilder.inferType(classHierarchyBuilder);
    }
    _inferableTypes.clear();
  }
}
