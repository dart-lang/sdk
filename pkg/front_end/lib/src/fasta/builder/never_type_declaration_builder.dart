// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.never_type_builder;

import 'package:kernel/ast.dart' show DartType, Nullability;
import 'package:kernel/class_hierarchy.dart';

import '../uris.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class NeverTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  final LibraryBuilder coreLibrary;

  NeverTypeDeclarationBuilder(DartType type, this.coreLibrary, int charOffset)
      : super("Never", type, coreLibrary, charOffset) {
    assert(coreLibrary.importUri == dartCore);
  }

  @override
  String get debugName => "NeverTypeDeclarationBuilder";

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
    return type.withDeclaredNullability(nullabilityBuilder.build(library));
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
    return type.withDeclaredNullability(nullability);
  }
}
