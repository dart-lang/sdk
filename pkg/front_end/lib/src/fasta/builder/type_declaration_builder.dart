// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_declaration_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;

import 'builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'modifier_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

abstract class TypeDeclarationBuilder implements ModifierBuilder {
  bool get isNamedMixinApplication;

  void set parent(Builder value);

  List<MetadataBuilder> get metadata;

  int get typeVariablesCount => 0;

  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]);

  /// [arguments] have already been built.
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments);
}

abstract class TypeDeclarationBuilderImpl extends ModifierBuilderImpl
    implements TypeDeclarationBuilder {
  @override
  final List<MetadataBuilder> metadata;

  @override
  final int modifiers;

  @override
  final String name;

  TypeDeclarationBuilderImpl(
      this.metadata, this.modifiers, this.name, Builder parent, int charOffset,
      [Uri fileUri])
      : assert(modifiers != null),
        super(parent, charOffset, fileUri);

  @override
  bool get isNamedMixinApplication => false;

  @override
  bool get isTypeDeclaration => true;

  @override
  String get fullNameForErrors => name;

  @override
  int get typeVariablesCount => 0;
}
