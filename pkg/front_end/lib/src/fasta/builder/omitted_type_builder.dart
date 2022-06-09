// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../source/source_library_builder.dart';
import 'library_builder.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

abstract class OmittedTypeBuilder extends TypeBuilder {
  const OmittedTypeBuilder();

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    throw new UnsupportedError('$runtimeType.buildMixedInType');
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library) {
    throw new UnsupportedError('$runtimeType.buildSupertype');
  }

  @override
  int? get charOffset => null;

  @override
  TypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    return this;
  }

  @override
  String get debugName => 'OmittedTypeBuilder';

  @override
  Uri? get fileUri => null;

  @override
  bool get isVoidType => false;

  @override
  Object? get name => null;

  @override
  NullabilityBuilder get nullabilityBuilder =>
      const NullabilityBuilder.omitted();

  @override
  StringBuffer printOn(StringBuffer buffer) => buffer;

  @override
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) {
    return this;
  }

  bool get hasType;

  DartType get type;
}

class ImplicitTypeBuilder extends OmittedTypeBuilder {
  const ImplicitTypeBuilder();

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
          {ClassHierarchyBase? hierarchy}) =>
      type;

  @override
  DartType buildAliased(LibraryBuilder library, TypeUse typeUse,
          ClassHierarchyBase? hierarchy) =>
      type;

  @override
  bool get isExplicit => true;

  @override
  bool get hasType => true;

  @override
  DartType get type => const DynamicType();
}

class InferableTypeBuilder extends OmittedTypeBuilder
    with ListenableTypeBuilderMixin<DartType> {
  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    if (hierarchy != null) {
      inferType(hierarchy);
      return type;
    }
    throw new UnsupportedError('$runtimeType.build');
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
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

  Inferable? get inferable => _inferable;

  @override
  void registerInferable(Inferable inferable) {
    assert(
        _inferable == null,
        "Inferable $_inferable has already been register, "
        "trying to register $inferable.");
    _inferable = inferable;
  }

  /// Triggers inference of this type.
  ///
  /// If an [Inferable] has been register, this is called to infer the type of
  /// this builder. Otherwise the type is inferred to be `dynamic`.
  void inferType(ClassHierarchyBase hierarchy) {
    if (!hasType) {
      Inferable? inferable = _inferable;
      if (inferable != null) {
        inferable.inferTypes(hierarchy);
      } else {
        registerInferredType(const DynamicType());
      }
      assert(hasType);
    }
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
