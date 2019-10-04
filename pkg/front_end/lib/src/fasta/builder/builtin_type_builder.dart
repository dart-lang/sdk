// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builtin_type_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;

import 'builder.dart' show LibraryBuilder, NullabilityBuilder, TypeBuilder;

import 'type_declaration_builder.dart';

abstract class BuiltinTypeBuilder extends TypeDeclarationBuilderImpl {
  final DartType type;

  BuiltinTypeBuilder(
      String name, this.type, LibraryBuilder compilationUnit, int charOffset)
      : super(null, 0, name, compilationUnit, charOffset);

  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments) {
    // TODO(dmitryas): Use [nullabilityBuilder].
    return type;
  }

  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    // TODO(dmitryas): Use [nullability].
    return type;
  }

  String get debugName => "BuiltinTypeBuilder";
}
