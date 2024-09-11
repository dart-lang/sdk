// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dynamic_type_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;

import 'declaration_builders.dart';
import 'library_builder.dart';
import 'type_builder.dart';

class DynamicTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  DynamicTypeDeclarationBuilder(
      DartType type, LibraryBuilder compilationUnit, int charOffset)
      : super("dynamic", type, compilationUnit, charOffset);

  @override
  String get debugName => "DynamicTypeDeclarationBuilder";

  @override
  Nullability computeNullabilityWithArguments(List<TypeBuilder>? typeArguments,
      {required Map<TypeVariableBuilder, TraversalState>
          typeVariablesTraversalState}) {
    return Nullability.nullable;
  }
}
