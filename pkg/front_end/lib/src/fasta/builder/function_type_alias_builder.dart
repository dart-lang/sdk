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

abstract class FunctionTypeAliasBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  final T type;

  final List<TypeVariableBuilder> typeVariables;

  /// List of type arguments provided by instantiate to bound.
  List<TypeBuilder> get calculatedBounds;

  FunctionTypeAliasBuilder(List<MetadataBuilder> metadata, String name,
      this.typeVariables, this.type, LibraryBuilder parent, int charOffset)
      : super(metadata, null, name, parent, charOffset);

  String get debugName => "FunctionTypeAliasBuilder";

  LibraryBuilder get parent => super.parent;
}
