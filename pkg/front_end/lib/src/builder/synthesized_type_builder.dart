// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:kernel/ast.dart'
    show DartType, Nullability, Supertype, TypeParameter;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;
import 'package:kernel/src/unaliasing.dart' as unaliasing;
import 'package:kernel/type_algebra.dart' show Substitution;

import '../kernel/type_algorithms.dart';
import '../source/source_loader.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class SynthesizedTypeBuilder extends FixedTypeBuilder {
  final TypeBuilder _typeBuilder;

  final Map<NominalVariableBuilder, NominalVariableBuilder>
      _newToOldVariableMap;

  final Map<NominalVariableBuilder, TypeBuilder> _substitutionMap;

  Substitution? _substitution;
  DartType? _type;

  // Coverage-ignore(suite): Not run.
  /// Creates the [typeBuilder] in the context of [_substitutionMap].
  ///
  /// If [typeBuilder] is a reference to a variable in [_substitutionMap] the
  /// corresponding is returned. Otherwise a new [SynthesizedTypeBuilder] based
  /// on [typeBuilder] with the [_substitutionMap] is created.
  static TypeBuilder createSynthesizedTypeBuilder(
      TypeBuilder typeBuilder,
      Map<NominalVariableBuilder, NominalVariableBuilder> _newToOldVariableMap,
      Map<NominalVariableBuilder, TypeBuilder> _substitutionMap) {
    return _substitutionMap[typeBuilder.declaration] ??
        new SynthesizedTypeBuilder(
            typeBuilder, _newToOldVariableMap, _substitutionMap);
  }

  SynthesizedTypeBuilder(
      this._typeBuilder, this._newToOldVariableMap, this._substitutionMap);

  @override
  TypeDeclarationBuilder? get declaration => _typeBuilder.declaration;

  @override
  // Coverage-ignore(suite): Not run.
  List<TypeBuilder>? get typeArguments {
    return _typeBuilder.typeArguments
        ?.map((TypeBuilder type) => createSynthesizedTypeBuilder(
            type, _newToOldVariableMap, _substitutionMap))
        .toList();
  }

  Substitution _computeSubstitution(LibraryBuilder libraryBuilder,
      TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    if (_substitution != null) return _substitution!;
    Map<TypeParameter, DartType> map = {};
    for (MapEntry<NominalVariableBuilder, TypeBuilder> entry
        in _substitutionMap.entries) {
      map[entry.key.actualParameter] =
          entry.value.build(libraryBuilder, typeUse, hierarchy: hierarchy);
    }
    return _substitution = Substitution.fromMap(map);
  }

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return _type ??= _buildInternal(library, typeUse, hierarchy);
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    return _buildAliasedInternal(library, typeUse, hierarchy);
  }

  DartType _buildAliasedInternal(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    DartType type = _typeBuilder.buildAliased(library, typeUse, hierarchy);
    Substitution substitution =
        _computeSubstitution(library, typeUse, hierarchy);
    if ('$type'.contains('T*')) {
      // Coverage-ignore-block(suite): Not run.
      _typeBuilder.buildAliased(library, typeUse, hierarchy);
    }
    return substitution.substituteType(type);
  }

  DartType _buildInternal(LibraryBuilder libraryBuilder, TypeUse typeUse,
      ClassHierarchyBase? hierarchy) {
    DartType aliasedType =
        _buildAliasedInternal(libraryBuilder, typeUse, hierarchy);
    return unaliasing.unalias(aliasedType, legacyEraseAliases: false);
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder libraryBuilder) {
    Supertype? mixedInType = _typeBuilder.buildMixedInType(libraryBuilder);
    if (mixedInType == null) return null;
    return _computeSubstitution(libraryBuilder, TypeUse.classWithType, null)
        .substituteSupertype(mixedInType);
  }

  @override
  Supertype? buildSupertype(LibraryBuilder libraryBuilder, TypeUse typeUse) {
    Supertype? mixedInType =
        _typeBuilder.buildSupertype(libraryBuilder, typeUse);
    if (mixedInType == null) return null;
    return _computeSubstitution(libraryBuilder, typeUse, null)
        .substituteSupertype(mixedInType);
  }

  @override
  int? get charOffset => _typeBuilder.charOffset;

  @override
  String get debugName => _typeBuilder.debugName;

  @override
  Uri? get fileUri => _typeBuilder.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExplicit => _typeBuilder.isExplicit;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isVoidType => _typeBuilder.isVoidType;

  @override
  NullabilityBuilder get nullabilityBuilder => _typeBuilder.nullabilityBuilder;

  @override
  StringBuffer printOn(StringBuffer buffer) {
    return _typeBuilder.printOn(buffer);
  }

  /// Creates the [type] in the context of [_substitutionMap].
  ///
  /// If [v] is `null`, `null` is returned. If [type] is a reference of a
  /// variable in [_substitutionMap] the corresponding is returned. Otherwise
  /// a new [SynthesizedTypeBuilder] based on [type] with the
  /// [_substitutionMap] is created.
  TypeBuilder? _applySubstitution(TypeBuilder? type) {
    if (type == null) return null;
    return _substitutionMap[type.declaration] ??
        new SynthesizedTypeBuilder(
            type, _newToOldVariableMap, _substitutionMap);
  }

  @override
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) {
    return new SynthesizedTypeBuilder(
        _typeBuilder.withNullabilityBuilder(nullabilityBuilder),
        _newToOldVariableMap,
        _substitutionMap);
  }

  @override
  VarianceCalculationValue computeTypeVariableBuilderVariance(
      NominalVariableBuilder variable,
      {required SourceLoader sourceLoader}) {
    variable = _newToOldVariableMap[variable] ?? variable;
    return _typeBuilder.computeTypeVariableBuilderVariance(variable,
        sourceLoader: sourceLoader);
  }

  @override
  TypeDeclarationBuilder? computeUnaliasedDeclaration(
      {required bool isUsedAsClass}) {
    return _typeBuilder.computeUnaliasedDeclaration(
        isUsedAsClass: isUsedAsClass);
  }

  @override
  TypeName? get typeName => _typeBuilder.typeName;

  @override
  void collectReferencesFrom(Map<TypeVariableBuilder, int> variableIndices,
      List<List<int>> edges, int index) {
    Map<TypeVariableBuilder, int> oldVariableIndices = {};
    for (MapEntry<TypeVariableBuilder, int> entry in variableIndices.entries) {
      oldVariableIndices[_newToOldVariableMap[entry.key] ?? entry.key] =
          entry.value;
    }
    _typeBuilder.collectReferencesFrom(oldVariableIndices, edges, index);
  }

  @override
  TypeBuilder? substituteRange(
      Map<TypeVariableBuilder, TypeBuilder> upperSubstitution,
      Map<TypeVariableBuilder, TypeBuilder> lowerSubstitution,
      List<TypeBuilder> unboundTypes,
      List<StructuralVariableBuilder> unboundTypeVariables,
      {Variance variance = Variance.covariant}) {
    Map<TypeVariableBuilder, TypeBuilder> oldUpperSubstitution = {};
    for (MapEntry<TypeVariableBuilder, TypeBuilder> entry
        in upperSubstitution.entries) {
      oldUpperSubstitution[_newToOldVariableMap[entry.key] ?? entry.key] =
          entry.value;
    }
    Map<TypeVariableBuilder, TypeBuilder> oldLowerSubstitution;
    if (upperSubstitution == lowerSubstitution) {
      oldLowerSubstitution = oldUpperSubstitution;
    } else {
      oldLowerSubstitution = {};
      for (MapEntry<TypeVariableBuilder, TypeBuilder> entry
          in lowerSubstitution.entries) {
        oldLowerSubstitution[_newToOldVariableMap[entry.key] ?? entry.key] =
            entry.value;
      }
    }
    return _applySubstitution(_typeBuilder.substituteRange(oldUpperSubstitution,
        oldLowerSubstitution, unboundTypes, unboundTypeVariables));
  }

  @override
  TypeBuilder? unaliasAndErase() {
    return _applySubstitution(_typeBuilder.unaliasAndErase());
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool usesTypeVariables(Set<String> typeVariableNames) {
    return _typeBuilder.usesTypeVariables(typeVariableNames);
  }

  @override
  Nullability computeNullability(
      {required Map<TypeVariableBuilder, TraversalState>
          typeVariablesTraversalState}) {
    return _typeBuilder.computeNullability(
        typeVariablesTraversalState: typeVariablesTraversalState);
  }

  @override
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() {
    return _typeBuilder.findRawTypesWithInboundReferences();
  }
}
