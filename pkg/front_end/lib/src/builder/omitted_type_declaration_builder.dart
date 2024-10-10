// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

// Coverage-ignore(suite): Not run.
/// [TypeDeclaration] wrapper for an [OmittedTypeBuilder].
///
/// This is used in macro generated code to create type annotations from
/// inferred types in the original code.
class OmittedTypeDeclarationBuilder extends TypeDeclarationBuilderImpl
    implements TypeDeclarationBuilder {
  @override
  final SourceLibraryBuilder parent;

  @override
  final String name;

  final OmittedTypeBuilder omittedTypeBuilder;

  OmittedTypeDeclarationBuilder(
      this.name, this.omittedTypeBuilder, this.parent);

  @override
  int get charOffset => TreeNode.noOffset;

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
  Nullability computeNullabilityWithArguments(List<TypeBuilder>? typeArguments,
      {required Map<TypeVariableBuilder, TraversalState>
          typeVariablesTraversalState}) {
    // TODO(johnniwinther): This should probably be an error case.
    throw new UnimplementedError(
        '${runtimeType}.computeNullabilityWithArguments');
  }

  @override
  Uri? get fileUri => parent.fileUri;
}
