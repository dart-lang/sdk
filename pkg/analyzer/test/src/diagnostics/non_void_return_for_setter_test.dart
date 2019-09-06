// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonVoidReturnForSetterTest);
  });
}

@reflectiveTest
class NonVoidReturnForSetterTest extends DriverResolutionTest {
  test_function() async {
    await assertErrorsInCode('''
int set x(int v) {
  return 42;
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 0, 3),
    ]);
  }

  test_method() async {
    await assertErrorsInCode('''
class A {
  int set x(int v) {
    return 42;
  }
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 12, 3),
    ]);
  }
}
