// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/constant/potentially_constant_test.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentCaseExpressionTypesTest);
    defineReflectiveTests(InconsistentCaseExpressionTypesWithNullSafetyTest);
  });
}

@reflectiveTest
class InconsistentCaseExpressionTypesTest extends DriverResolutionTest {
  test_int() async {
    await assertNoErrorsInCode(r'''
void f(var e) {
  switch (e) {
    case 1:
      break;
    case 2:
      break;
  }
}
''');
  }

  test_int_String() async {
    await assertErrorsInCode(r'''
void f(var e) {
  switch (e) {
    case 1:
      break;
    case 'a':
      break;
  }
}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 65, 3),
    ]);
  }

  test_repeated() async {
    await assertErrorsInCode(r'''
void f(var e) {
  switch (e) {
    case 1:
      break;
    case 'a':
      break;
    case 'b':
      break;
  }
}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 65, 3),
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 92, 3),
    ]);
  }

  test_runtimeType() async {
    // Even though A.S and S have a static type of "dynamic", we should see
    // that they fail to match 3, because they are constant strings.
    await assertErrorsInCode(r'''
class A {
  static const S = 'A.S';
}

const S = 'S';

void f(var e) {
  switch (e) {
    case 3:
      break;
    case S:
      break;
    case A.S:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 120, 1),
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 145, 3),
    ]);
  }
}

@reflectiveTest
class InconsistentCaseExpressionTypesWithNullSafetyTest
    extends DriverResolutionTest with WithNullSafetyMixin {
  test_int_none_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
const a = 0;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.8
import 'a.dart';

void f(int e) {
  switch (e) {
    case a:
      break;
    case 1:
      break;
  }
}
''');
  }
}
