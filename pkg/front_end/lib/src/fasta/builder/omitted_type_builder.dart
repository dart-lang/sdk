// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../kernel/implicit_field_type.dart';
import '../source/source_library_builder.dart';
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
  int? get charOffset => null;

  @override
  TypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    return this;
  }

  @override
  Uri? get fileUri => null;

  @override
  bool get isVoidType => false;

  @override
  TypeName? get typeName => null;

  @override
  NullabilityBuilder get nullabilityBuilder =>
      const NullabilityBuilder.omitted();

  @override
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) {
    return this;
  }

  @override
  bool get hasType;

  @override
  DartType get type;
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
  DartType build(LibraryBuilder library, TypeUse typeUse,
          {ClassHierarchyBase? hierarchy}) =>
      type;

  @override
  DartType buildAliased(LibraryBuilder library, TypeUse typeUse,
          ClassHierarchyBase? hierarchy) =>
      type;

  @override
  String get debugName => 'ImplicitTypeBuilder';

  @override
  StringBuffer printOn(StringBuffer buffer) => buffer;

  @override
  bool get isExplicit => true;

  @override
  bool get hasType => true;

  @override
  DartType get type => const DynamicType();
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
  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    if (hierarchy != null) {
      inferType(hierarchy);
      return type;
    } else {
      InferableTypeUse inferableTypeUse =
          new InferableTypeUse(library as SourceLibraryBuilder, this, typeUse);
      library.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
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
  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    if (!hasType) {
      Inferable? inferable = _inferable;
      if (inferable != null) {
        inferable.inferTypes(hierarchy);
      } else {
        registerInferredType(const DynamicType());
      }
      assert(hasType, "No type computed for $this");
    }
    return type;
  }

  @override
  String get debugName => 'InferredTypeBuilder';

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write('(inferable=');
    buffer.write(inferable);
    buffer.write(')');
    return buffer;
  }
}

/// A type defined in terms of another omitted type.
///
/// This is used in macro generated code to create type annotations from
/// inferred types in the original code.
class DependentTypeBuilder extends OmittedTypeBuilderImpl
    with InferableTypeBuilderMixin
    implements InferredTypeListener {
  final OmittedTypeBuilder typeBuilder;

  DependentTypeBuilder(this.typeBuilder) {
    typeBuilder.registerInferredTypeListener(this);
  }

  @override
  void onInferredType(DartType type) {
    registerType(type);
  }

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    if (hasType) {
      return type;
    }
    if (hierarchy != null) {
      return typeBuilder.build(library, typeUse, hierarchy: hierarchy);
    } else {
      InferableTypeUse inferableTypeUse =
          new InferableTypeUse(library as SourceLibraryBuilder, this, typeUse);
      library.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    return typeBuilder.buildAliased(library, typeUse, hierarchy);
  }

  @override
  bool get isExplicit => false;

  @override
  String get debugName => 'DependentTypeBuilder';

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write('(dependency=');
    buffer.write(typeBuilder);
    buffer.write(')');
    return buffer;
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
