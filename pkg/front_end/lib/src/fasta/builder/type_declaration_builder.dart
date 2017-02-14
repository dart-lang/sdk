// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_declaration_builder;

import 'builder.dart' show
    Builder,
    MetadataBuilder,
    ModifierBuilder,
    TypeBuilder;

abstract class TypeDeclarationBuilder<T extends TypeBuilder, R>
    extends ModifierBuilder {
  final List<MetadataBuilder> metadata;

  final int modifiers;

  final String name;

  Builder parent;

  TypeDeclarationBuilder(this.metadata, this.modifiers, this.name,
      Builder parent, int charOffset, [Uri fileUri])
      : parent = parent, super(parent, charOffset, fileUri ?? parent?.fileUri);

  bool get isTypeDeclaration => true;

  R buildType(List<T> arguments);

  /// [arguments] have already been built.
  R buildTypesWithBuiltArguments(List<R> arguments);
}
