// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros
import 'package:macros/macros.dart';

macro class AnyMacro implements ClassDeclarationsMacro {
  const AnyMacro();

  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {}
}

@AnyMacro()
// [error line 14, column 1]
// [analyzer] unspecified
// [cfe] unspecified
class A {}
