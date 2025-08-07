// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../codes/cfe_codes.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_loader.dart';
import '../source/type_parameter_factory.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class VoidTypeBuilder extends FixedTypeBuilder {
  @override
  final TypeName typeName;
  @override
  final Uri? fileUri;
  @override
  final int? charOffset;

  VoidTypeBuilder(this.fileUri, this.charOffset)
      : typeName =
            new SyntheticTypeName('void', charOffset ?? TreeNode.noOffset);

  @override
  NullabilityBuilder get nullabilityBuilder =>
      new NullabilityBuilder.fromNullability(const VoidType().nullability);

  @override
  String get debugName => 'VoidTypeBuilder';

  @override
  bool get isVoidType => true;

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write('void');
    return buffer;
  }

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return const VoidType();
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    return const VoidType();
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library, TypeUse typeUse) {
    library.addProblem(codeSupertypeIsIllegal.withArguments('void'),
        charOffset!, noLength, fileUri);
    return null;
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    library.addProblem(codeSupertypeIsIllegal.withArguments('void'),
        charOffset!, noLength, fileUri);
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) =>
      this;

  @override
  bool get isExplicit => true;

  @override
  // Coverage-ignore(suite): Not run.
  Nullability computeNullability(
          {required Map<TypeParameterBuilder, TraversalState>
              typeParametersTraversalState}) =>
      Nullability.nullable;

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

  @override
  void collectReferencesFrom(Map<TypeParameterBuilder, int> parameterIndices,
      List<List<int>> edges, int index) {}

  @override
  TypeBuilder? substituteRange(
      Map<TypeParameterBuilder, TypeBuilder> upperSubstitution,
      Map<TypeParameterBuilder, TypeBuilder> lowerSubstitution,
      TypeParameterFactory typeParameterFactory,
      {Variance variance = Variance.covariant}) {
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder? unaliasAndErase() => this;

  @override
  // Coverage-ignore(suite): Not run.
  bool usesTypeParameters(Set<String> typeParameterNames) => false;

  @override
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() =>
      const [];
}
