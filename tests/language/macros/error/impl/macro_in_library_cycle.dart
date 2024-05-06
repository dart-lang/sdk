// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros
import 'package:macros/macros.dart';

import '../declare_and_use_same_library_cycle_test.dart';

macro class AnyMacro implements ClassDeclarationsMacro {
  const AnyMacro();

  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {}
}

// So the import of the test is not unused.
int get someOtherValue => someValue;
