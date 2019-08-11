// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_declaration_builder;

import 'package:kernel/ast.dart' show DartType;

import 'builder.dart'
    show Builder, LibraryBuilder, MetadataBuilder, ModifierBuilder, TypeBuilder;

abstract class TypeDeclarationBuilder extends ModifierBuilder {
  final List<MetadataBuilder> metadata;

  final int modifiers;

  final String name;

  Builder parent;

  TypeDeclarationBuilder(
      this.metadata, this.modifiers, this.name, this.parent, int charOffset,
      [Uri fileUri])
      : assert(modifiers != null),
        super(parent, charOffset, fileUri);

  bool get isTypeDeclaration => true;

  @override
  String get fullNameForErrors => name;

  int get typeVariablesCount => 0;

  DartType buildType(LibraryBuilder library, List<TypeBuilder> arguments);

  /// [arguments] have already been built.
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments);
}
