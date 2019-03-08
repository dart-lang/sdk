// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentTypeNotAssignableTest);
  });
}

@reflectiveTest
class ArgumentTypeNotAssignableTest extends DriverResolutionTest {
  test_functionType() async {
    await assertErrorsInCode(r'''
m() {
  var a = new A();
  a.n(() => 0);
}
class A {
  n(void f(int i)) {}
}
''', [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_interfaceType() async {
    await assertErrorsInCode(r'''
m() {
  var i = '';
  n(i);
}
n(int i) {}
''', [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
  }
}
