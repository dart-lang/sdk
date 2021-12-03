// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.never_type_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;

import 'builtin_type_declaration_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class NeverTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  final LibraryBuilder coreLibrary;

  NeverTypeDeclarationBuilder(DartType type, this.coreLibrary, int charOffset)
      : super("Never", type, coreLibrary, charOffset) {
    assert(coreLibrary.importUri == Uri.parse('dart:core'));
  }

  @override
  String get debugName => "NeverTypeDeclarationBuilder";

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments) {
    return type.withDeclaredNullability(nullabilityBuilder.build(library));
  }

  @override
  DartType buildTypeWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    return type.withDeclaredNullability(nullability);
  }
}
