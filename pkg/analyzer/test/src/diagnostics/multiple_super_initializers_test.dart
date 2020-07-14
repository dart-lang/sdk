// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleSuperInitializersTest);
  });
}

@reflectiveTest
class MultipleSuperInitializersTest extends DriverResolutionTest {
  test_twoSuperInitializers() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  B() : super(), super() {}
}
''', [
      error(StrongModeCode.INVALID_SUPER_INVOCATION, 39, 7),
      error(CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS, 48, 7),
    ]);
  }
}
