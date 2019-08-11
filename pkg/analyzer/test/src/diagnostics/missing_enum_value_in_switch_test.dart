// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingEnumConstantInSwitchTest);
  });
}

@reflectiveTest
class MissingEnumConstantInSwitchTest extends DriverResolutionTest {
  test_first() async {
    await assertErrorsInCode('''
enum E { ONE, TWO, THREE }
bool odd(E e) {
  switch (e) {
    case E.TWO:
    case E.THREE: return true;
  }
  return false;
}''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 45, 10),
    ]);
  }

  test_last() async {
    await assertErrorsInCode('''
enum E { ONE, TWO, THREE }
bool odd(E e) {
  switch (e) {
    case E.ONE:
    case E.TWO: return true;
  }
  return false;
}''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 45, 10),
    ]);
  }

  test_middle() async {
    await assertErrorsInCode('''
enum E { ONE, TWO, THREE }
bool odd(E e) {
  switch (e) {
    case E.ONE:
    case E.THREE: return true;
  }
  return false;
}''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 45, 10),
    ]);
  }
}
