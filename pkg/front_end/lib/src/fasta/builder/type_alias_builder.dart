// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.function_type_alias_builder;

import 'builder.dart'
    show
        LibraryBuilder,
        MetadataBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

abstract class TypeAliasBuilder extends TypeDeclarationBuilder {
  final TypeBuilder type;

  final List<TypeVariableBuilder> typeVariables;

  TypeAliasBuilder(
      List<MetadataBuilder> metadata,
      String name,
      this.typeVariables,
      this.type,
      LibraryBuilder<TypeBuilder, Object> parent,
      int charOffset)
      : super(metadata, 0, name, parent, charOffset);

  String get debugName => "TypeAliasBuilder";

  LibraryBuilder<TypeBuilder, Object> get parent => super.parent;

  int get typeVariablesCount;
}
