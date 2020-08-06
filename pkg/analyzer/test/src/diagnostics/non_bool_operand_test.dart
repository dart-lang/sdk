// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolOperandTest);
    defineReflectiveTests(NonBoolOperandWithNullSafetyTest);
  });
}

@reflectiveTest
class NonBoolOperandTest extends PubPackageResolutionTest {
  test_and_left() async {
    await assertErrorsInCode(r'''
bool f(int left, bool right) {
  return left && right;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 40, 4),
    ]);
  }

  test_and_right() async {
    await assertErrorsInCode(r'''
bool f(bool left, String right) {
  return left && right;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 51, 5),
    ]);
  }

  test_or_left() async {
    await assertErrorsInCode(r'''
bool f(List<int> left, bool right) {
  return left || right;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 46, 4),
    ]);
  }

  test_or_right() async {
    await assertErrorsInCode(r'''
bool f(bool left, double right) {
  return left || right;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 51, 5),
    ]);
  }
}

@reflectiveTest
class NonBoolOperandWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_and_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  if(x && true) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 21, 1),
    ]);
  }

  test_or_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  if(x || false) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 21, 1),
    ]);
  }
}
