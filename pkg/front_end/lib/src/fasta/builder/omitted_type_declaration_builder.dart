// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

/// [TypeDeclaration] wrapper for an [OmittedTypeBuilder].
///
/// This is used in macro generated code to create type annotations from
/// inferred types in the original code.
class OmittedTypeDeclarationBuilder extends TypeDeclarationBuilderImpl
    implements TypeDeclarationBuilder {
  final OmittedTypeBuilder omittedTypeBuilder;

  OmittedTypeDeclarationBuilder(
      String name, this.omittedTypeBuilder, SourceLibraryBuilder parent)
      : super(null, 0, name, parent, TreeNode.noOffset);

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
    // TODO(johnniwinther): This should probably be an error case.
    throw new UnimplementedError('${runtimeType}.buildAliasedType');
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
    // TODO(johnniwinther): This should probably be an error case.
    throw new UnimplementedError(
        '${runtimeType}.buildAliasedTypeWithBuiltArguments');
  }

  @override
  String get debugName => 'OmittedTypeDeclarationBuilder';

  @override
  Uri? get fileUri => parent!.fileUri;
}
