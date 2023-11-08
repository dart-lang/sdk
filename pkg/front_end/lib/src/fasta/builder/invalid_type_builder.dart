// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/builder/library_builder.dart';

import 'package:front_end/src/fasta/builder/nullability_builder.dart';

import 'package:front_end/src/fasta/source/source_library_builder.dart';

import 'package:kernel/ast.dart';

import 'package:kernel/class_hierarchy.dart';

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
  Supertype? buildMixedInType(LibraryBuilder library) {
    return null;
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library) {
    return null;
  }

  @override
  TypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    return this;
  }

  @override
  String get debugName => 'InvalidTypeBuilder';

  @override
  bool get isExplicit => true;

  @override
  bool get isVoidType => false;

  @override
  Object? get name => null;

  @override
  NullabilityBuilder get nullabilityBuilder =>
      const NullabilityBuilder.inherent();

  @override
  StringBuffer printOn(StringBuffer buffer) => buffer;

  @override
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) {
    return this;
  }
}
