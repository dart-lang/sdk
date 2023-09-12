// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.null_type_declaration_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;
import 'package:kernel/class_hierarchy.dart';

import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class NullTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  NullTypeDeclarationBuilder(
      DartType type, LibraryBuilder compilationUnit, int charOffset)
      : super("Null", type, compilationUnit, charOffset);

  @override
  String get debugName => "NullTypeBuilder";

  @override
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    return type;
  }

  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType> arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    return type;
  }
}
