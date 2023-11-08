// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../problems.dart';
import '../source/source_library_builder.dart';
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
  TypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    return this;
  }

  @override
  Object? get name => null;

  @override
  NullabilityBuilder get nullabilityBuilder =>
      new NullabilityBuilder.fromNullability(type.nullability);

  @override
  String get debugName => 'FixedTypeBuilder';

  @override
  bool get isVoidType => type is VoidType;

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write('type=${type}');
    return buffer;
  }

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return type;
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    return type;
  }

  @override
  Supertype buildSupertype(LibraryBuilder library) {
    return unhandled(
        'buildSupertype', 'FixedTypeBuilder', charOffset ?? -1, fileUri);
  }

  @override
  Supertype buildMixedInType(LibraryBuilder library) {
    return unhandled(
        'buildMixedInType', 'FixedTypeBuilder', charOffset ?? -1, fileUri);
  }

  @override
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) =>
      this;

  @override
  bool get isExplicit => true;
}
