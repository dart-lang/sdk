// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedEnumConstantTest);
  });
}

@reflectiveTest
class UndefinedEnumConstantTest extends DriverResolutionTest {
  test_defined() async {
    await assertNoErrorsInCode(r'''
enum E { ONE }
E e() {
  return E.ONE;
}
''');
  }

  test_undefined() async {
    await assertErrorsInCode(r'''
enum E { ONE }
E e() {
  return E.TWO;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_ENUM_CONSTANT, 34, 3),
    ]);
  }
}
