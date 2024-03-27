// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:macros/macros.dart';

import 'impl.dart';

macro class ClassDeclarationsDeclareInType implements ClassDeclarationsMacro {
  final String code;

  const ClassDeclarationsDeclareInType(this.code);

  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInType(await builder.code(code));
  }
}

macro class ClassDeclarationsDeclareInLibrary
    implements ClassDeclarationsMacro {
  final String code;

  const ClassDeclarationsDeclareInLibrary(this.code);

  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInLibrary(await builder.code(code));
  }
}
