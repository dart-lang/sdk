// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSetterTest);
  });
}

@reflectiveTest
class UndefinedSetterTest extends DriverResolutionTest {
  test_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(var a) {
  if (a is A) {
    a.b = 0;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  test_inType() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if(a is A) {
    a.m = 0;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }
}
