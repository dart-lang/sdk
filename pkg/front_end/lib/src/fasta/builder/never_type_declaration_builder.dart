// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.never_type_builder;

import 'package:kernel/ast.dart' show DartType, InterfaceType, Nullability;

import 'builtin_type_declaration_builder.dart';
import 'class_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class NeverTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  final LibraryBuilder coreLibrary;
  DartType _nullType;

  NeverTypeDeclarationBuilder(DartType type, this.coreLibrary, int charOffset)
      : super("Never", type, coreLibrary, charOffset) {
    assert(coreLibrary.importUri == Uri.parse('dart:core'));
  }

  String get debugName => "NeverTypeDeclarationBuilder";

  DartType get nullType {
    if (_nullType == null) {
      ClassBuilder nullClass = coreLibrary.lookupLocalMember('Null');
      _nullType = new InterfaceType(nullClass.cls, Nullability.nullable, []);
    }
    return _nullType;
  }

  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    if (!library.isNonNullableByDefault) {
      return nullType;
    }
    return type.withDeclaredNullability(nullabilityBuilder.build(library));
  }

  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    if (!library.isNonNullableByDefault) {
      return nullType;
    }
    return type.withDeclaredNullability(nullability);
  }
}
