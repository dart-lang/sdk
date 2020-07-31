// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.never_type_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;

import 'builtin_type_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class NeverTypeBuilder extends BuiltinTypeBuilder {
  NeverTypeBuilder(
      DartType type, LibraryBuilder compilationUnit, int charOffset)
      : super("Never", type, compilationUnit, charOffset);

  String get debugName => "NeverTypeBuilder";

  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    return type.withDeclaredNullability(nullabilityBuilder.build(library));
  }

  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    return type.withDeclaredNullability(nullability);
  }
}
