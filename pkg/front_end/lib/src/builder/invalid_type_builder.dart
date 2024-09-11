// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../kernel/type_algorithms.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

/// Type builder for invalid types as a type builder.
///
/// This builder results in the creation of an [InvalidType] and can only be
/// used when an error has already been reported.
class InvalidTypeBuilderImpl extends InvalidTypeBuilder {
  @override
  final Uri fileUri;

  @override
  final int charOffset;

  InvalidTypeBuilderImpl(this.fileUri, this.charOffset);

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return const InvalidType();
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    return const InvalidType();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Supertype? buildMixedInType(LibraryBuilder library) {
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Supertype? buildSupertype(LibraryBuilder library, TypeUse typeUse) {
    return null;
  }

  @override
  String get debugName => 'InvalidTypeBuilder';

  @override
  bool get isExplicit => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isVoidType => false;

  @override
  // Coverage-ignore(suite): Not run.
  TypeName? get typeName => null;

  @override
  // Coverage-ignore(suite): Not run.
  NullabilityBuilder get nullabilityBuilder =>
      const NullabilityBuilder.inherent();

  @override
  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) => buffer;

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) {
    return this;
  }

  @override
  Nullability computeNullability(
      {required Map<TypeVariableBuilder, TraversalState>
          typeVariablesTraversalState}) {
    // TODO(johnniwinther,cstefantsova): Consider implementing
    // invalidNullability.
    return Nullability.nullable;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void collectReferencesFrom(Map<TypeVariableBuilder, int> variableIndices,
      List<List<int>> edges, int index) {}

  @override
  TypeBuilder? substituteRange(
      Map<TypeVariableBuilder, TypeBuilder> upperSubstitution,
      Map<TypeVariableBuilder, TypeBuilder> lowerSubstitution,
      List<StructuralVariableBuilder> unboundTypeVariables,
      {Variance variance = Variance.covariant}) {
    return null;
  }

  @override
  TypeBuilder? unaliasAndErase() => this;

  @override
  // Coverage-ignore(suite): Not run.
  bool usesTypeVariables(Set<String> typeVariableNames) => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() =>
      const [];
}
