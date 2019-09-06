// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import 'builder.dart';
import 'declaration_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';
import '../fasta_codes.dart' show templateInternalProblemNotFoundIn;
import '../scope.dart';
import '../problems.dart';

abstract class ExtensionBuilder extends DeclarationBuilder {
  final List<TypeVariableBuilder> typeParameters;
  final TypeBuilder onType;

  ExtensionBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      LibraryBuilder parent,
      int charOffset,
      Scope scope,
      this.typeParameters,
      this.onType)
      : super(metadata, modifiers, name, parent, charOffset, scope);

  @override
  DartType buildType(LibraryBuilder library, List<TypeBuilder> arguments) {
    throw new UnsupportedError("ExtensionBuilder.buildType is not supported.");
  }

  @override
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    throw new UnsupportedError("ExtensionBuilder.buildTypesWithBuiltArguments "
        "is not supported.");
  }

  @override
  bool get isExtension => true;

  @override
  InterfaceType get thisType => null;

  @override
  Builder lookupLocalMember(String name, {bool required: false}) {
    // TODO(johnniwinther): Support patching on extensions.
    Builder builder = scope.local[name];
    if (required && builder == null) {
      internalProblem(
          templateInternalProblemNotFoundIn.withArguments(
              name, fullNameForErrors),
          -1,
          null);
    }
    return builder;
  }

  @override
  String get debugName => "ExtensionBuilder";
}
