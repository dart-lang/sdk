// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macros/macros.dart';

/// Adds a function with a specified name to a class, with no body and a void
/// return type.
macro class AddFunction implements ClassDeclarationsMacro {
  /// The name of the function to add.
  final String name;

  const AddFunction(this.name);

  @override
  void buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) {
    builder.declareInType(DeclarationCode.fromString('void $name() {}'));
  }
}
