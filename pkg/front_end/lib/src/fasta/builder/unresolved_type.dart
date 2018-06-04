// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.unresolved_type;

import '../fasta_codes.dart' show templateTypeArgumentMismatch;

import 'builder.dart'
    show
        ClassBuilder,
        FunctionTypeAliasBuilder,
        NamedTypeBuilder,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder;

/// A wrapper around a type that is yet to be resolved.
class UnresolvedType<T extends TypeBuilder> {
  final T builder;
  final int charOffset;
  final Uri fileUri;

  UnresolvedType(this.builder, this.charOffset, this.fileUri);

  void resolveIn(Scope scope) => builder.resolveIn(scope, charOffset, fileUri);

  /// Performs checks on the type after it's resolved.
  void checkType() {
    TypeBuilder resolvedType = builder;
    if (resolvedType is NamedTypeBuilder) {
      TypeDeclarationBuilder declaration = resolvedType.declaration;
      if (declaration is ClassBuilder) {
        if (resolvedType.arguments != null &&
            resolvedType.arguments.length != declaration.typeVariablesCount) {
          resolvedType.declaration = resolvedType.buildInvalidType(
              charOffset,
              fileUri,
              templateTypeArgumentMismatch.withArguments(
                  resolvedType.name, "${declaration.typeVariablesCount}"));
        }
      } else if (declaration is FunctionTypeAliasBuilder) {
        if (resolvedType.arguments != null &&
            resolvedType.arguments.length != declaration.typeVariablesCount) {
          resolvedType.declaration = resolvedType.buildInvalidType(
              charOffset,
              fileUri,
              templateTypeArgumentMismatch.withArguments(
                  resolvedType.name, "${declaration.typeVariablesCount}"));
        }
      }
    }
  }

  /// Normalizes the type arguments in accordance with Dart 1 semantics.
  void normalizeType() {
    TypeBuilder resolvedType = builder;
    if (resolvedType is NamedTypeBuilder) {
      TypeDeclarationBuilder declaration = resolvedType.declaration;
      if (declaration is ClassBuilder) {
        if (resolvedType.arguments != null &&
            resolvedType.arguments.length != declaration.typeVariablesCount) {
          // [resolveType.arguments] will be normalized later if they are null.
          resolvedType.arguments = null;
        }
      } else if (declaration is FunctionTypeAliasBuilder) {
        if (resolvedType.arguments != null &&
            resolvedType.arguments.length != declaration.typeVariablesCount) {
          // [resolveType.arguments] will be normalized later if they are null.
          resolvedType.arguments = null;
        }
      }
    }
  }
}
