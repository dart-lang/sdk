// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.null_type_declaration_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;

import 'builtin_type_declaration_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class NullTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  NullTypeDeclarationBuilder(
      DartType type, LibraryBuilder compilationUnit, int charOffset)
      : super("Null", type, compilationUnit, charOffset);

  String get debugName => "NullTypeBuilder";

  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    return type;
  }

  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    return type;
  }
}
