// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializingFormalNotAssignableTest);
  });
}

@reflectiveTest
class FieldInitializingFormalNotAssignableTest extends DriverResolutionTest {
  test_unrelated() async {
    await assertErrorsInCode('''
class A {
  int x;
  A(String this.x) {}
}
''', [
      error(StrongModeCode.INVALID_PARAMETER_DECLARATION, 23, 13),
      error(StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, 23, 13),
    ]);
  }
}
