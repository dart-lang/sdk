// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../base/problems.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_loader.dart';
import '../source/type_parameter_factory.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class FixedTypeBuilderImpl extends FixedTypeBuilder {
  final DartType type;
  @override
  final Uri? fileUri;
  @override
  final int? charOffset;

  const FixedTypeBuilderImpl(this.type, this.fileUri, this.charOffset);

  @override
  // Coverage-ignore(suite): Not run.
  TypeName? get typeName => null;

  @override
  // Coverage-ignore(suite): Not run.
  NullabilityBuilder get nullabilityBuilder =>
      new NullabilityBuilder.fromNullability(type.nullability);

  @override
  String get debugName => 'FixedTypeBuilder';

  @override
  // Coverage-ignore(suite): Not run.
  bool get isVoidType => type is VoidType;

  @override
  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write('type=${type}');
    return buffer;
  }

  @override
  DartType build(
    LibraryBuilder library,
    TypeUse typeUse, {
    ClassHierarchyBase? hierarchy,
  }) {
    return type;
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType buildAliased(
    LibraryBuilder library,
    TypeUse typeUse,
    ClassHierarchyBase? hierarchy,
  ) {
    return type;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Supertype buildSupertype(LibraryBuilder library, TypeUse typeUse) {
    return unhandled(
      'buildSupertype',
      'FixedTypeBuilder',
      charOffset ?? -1,
      fileUri,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Supertype buildMixedInType(LibraryBuilder library) {
    return unhandled(
      'buildMixedInType',
      'FixedTypeBuilder',
      charOffset ?? -1,
      fileUri,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) =>
      this;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExplicit => true;

  @override
  // Coverage-ignore(suite): Not run.
  Nullability computeNullability({
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) => type.nullability;

  @override
  // Coverage-ignore(suite): Not run.
  VarianceCalculationValue computeTypeParameterBuilderVariance(
    NominalParameterBuilder nominalParameterBuilder, {
    required SourceLoader sourceLoader,
  }) {
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  TypeDeclarationBuilder? computeUnaliasedDeclaration({
    required bool isUsedAsClass,
  }) {
    throw new UnsupportedError('$runtimeType.computeUnaliasedDeclaration');
  }

  @override
  // Coverage-ignore(suite): Not run.
  void collectReferencesFrom(
    Map<TypeParameterBuilder, int> parameterIndices,
    List<List<int>> edges,
    int index,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  bool usesTypeParameters(Set<String> typeParameterNames) => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() =>
      const [];
}
