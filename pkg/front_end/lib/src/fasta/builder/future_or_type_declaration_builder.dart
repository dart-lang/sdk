// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.future_or_type_builder;

import 'package:kernel/ast.dart' show DartType, FutureOrType, Nullability;

import 'builtin_type_declaration_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class FutureOrTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  FutureOrTypeDeclarationBuilder(
      DartType type, LibraryBuilder compilationUnit, int charOffset)
      : super("FutureOr", type, compilationUnit, charOffset);

  @override
  String get debugName => "FutureOrTypeDeclarationBuilder";

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments) {
    return new FutureOrType(
        arguments!.single.build(library), nullabilityBuilder.build(library));
  }

  @override
  DartType buildTypeWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    return new FutureOrType(arguments.single, nullability);
  }
}
