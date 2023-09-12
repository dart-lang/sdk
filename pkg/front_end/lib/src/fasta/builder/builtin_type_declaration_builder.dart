// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class BuiltinTypeDeclarationBuilder extends TypeDeclarationBuilderImpl
    implements TypeDeclarationBuilder {
  final DartType type;

  @override
  final Uri fileUri;

  BuiltinTypeDeclarationBuilder(
      String name, this.type, LibraryBuilder compilationUnit, int charOffset)
      : fileUri = compilationUnit.fileUri,
        super(null, 0, name, compilationUnit, charOffset);

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
    return type.withDeclaredNullability(nullabilityBuilder.build(library));
  }

  @override
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

  @override
  String get debugName => "BuiltinTypeDeclarationBuilder";
}
