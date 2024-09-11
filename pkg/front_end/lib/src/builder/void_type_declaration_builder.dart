// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.void_type_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;

import 'declaration_builders.dart';
import 'library_builder.dart';
import 'type_builder.dart';

class VoidTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  VoidTypeDeclarationBuilder(
      DartType type, LibraryBuilder compilationUnit, int charOffset)
      : super("void", type, compilationUnit, charOffset);

  @override
  String get debugName => "VoidTypeDeclarationBuilder";

  @override
  // Coverage-ignore(suite): Not run.
  Nullability computeNullabilityWithArguments(List<TypeBuilder>? typeArguments,
          {required Map<TypeVariableBuilder, TraversalState>
              typeVariablesTraversalState}) =>
      Nullability.nullable;
}
