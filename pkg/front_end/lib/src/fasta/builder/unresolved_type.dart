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
    if (builder is NamedTypeBuilder) {
      NamedTypeBuilder resolvedType = builder as NamedTypeBuilder;
      TypeDeclarationBuilder declaration = resolvedType.builder;
      if (declaration is ClassBuilder) {
        if (resolvedType.arguments != null &&
            resolvedType.arguments.length != declaration.typeVariablesCount) {
          resolvedType.builder = resolvedType.buildInvalidType(
              charOffset,
              fileUri,
              templateTypeArgumentMismatch.withArguments(
                  resolvedType.name, "${declaration.typeVariablesCount}"));
        }
      } else if (declaration is FunctionTypeAliasBuilder) {
        if (resolvedType.arguments != null &&
            resolvedType.arguments.length != declaration.typeVariablesCount) {
          resolvedType.builder = resolvedType.buildInvalidType(
              charOffset,
              fileUri,
              templateTypeArgumentMismatch.withArguments(
                  resolvedType.name, "${declaration.typeVariablesCount}"));
        }
      }
    }
  }
}
