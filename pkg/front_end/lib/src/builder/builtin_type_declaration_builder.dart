// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class BuiltinTypeDeclarationBuilder extends TypeDeclarationBuilderImpl
    implements TypeDeclarationBuilder {
  @override
  final LibraryBuilder parent;

  @override
  final int charOffset;

  @override
  final String name;

  final DartType type;

  @override
  final Uri fileUri;

  BuiltinTypeDeclarationBuilder(
      this.name, this.type, this.parent, this.charOffset)
      : fileUri = parent.fileUri;

  @override
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    return type.withDeclaredNullability(nullabilityBuilder.build());
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType> arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    return type.withDeclaredNullability(nullability);
  }
}
