// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_declaration_builder;

import 'builder.dart'
    show Builder, LibraryBuilder, MetadataBuilder, ModifierBuilder, TypeBuilder;

abstract class TypeDeclarationBuilder<T extends TypeBuilder, R>
    extends ModifierBuilder {
  final List<MetadataBuilder> metadata;

  final int modifiers;

  final String name;

  Builder parent;

  TypeDeclarationBuilder(
      this.metadata, this.modifiers, this.name, this.parent, int charOffset,
      [Uri fileUri])
      : super(parent, charOffset, fileUri);

  bool get isTypeDeclaration => true;

  bool get isMixinApplication => false;

  R buildType(LibraryBuilder library, List<T> arguments);

  /// [arguments] have already been built.
  R buildTypesWithBuiltArguments(LibraryBuilder library, List<R> arguments);

  @override
  String get fullNameForErrors => name;
}
