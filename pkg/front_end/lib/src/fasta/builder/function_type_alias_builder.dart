// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.function_type_alias_builder;

import 'builder.dart' show
    FormalParameterBuilder,
    LibraryBuilder,
    MetadataBuilder,
    TypeBuilder,
    TypeDeclarationBuilder,
    TypeVariableBuilder;

import 'scope.dart' show
    Scope;

abstract class FunctionTypeAliasBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  final T returnType;

  final List<TypeVariableBuilder> typeVariables;

  final List<FormalParameterBuilder> formals;

  FunctionTypeAliasBuilder(
      List<MetadataBuilder> metadata, this.returnType,
      String name, this.typeVariables, this.formals, List<T> types,
      LibraryBuilder parent, int charOffset)
      : super(metadata, null, name, types, parent, charOffset);

  LibraryBuilder get parent => super.parent;

  int resolveTypes(LibraryBuilder library) {
    assert(library == parent || library == parent.partOfLibrary);
    // TODO(ahe): Only create nested scope if typeVariables != null. It should
    // be safe here, but for constructor field initializers, use the enclosing
    // scope to lookup fields.
    Scope scope = library.scope.createNestedScope();
    if (typeVariables != null) {
      for (TypeVariableBuilder t in typeVariables) {
        scope[t.name] = t;
      }
    }
    if (types != null) {
      for (T t in types) {
        t.resolveIn(scope);
      }
    }
    return types.length;
  }
}
