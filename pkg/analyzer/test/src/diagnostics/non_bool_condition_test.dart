// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolConditionTest);
    defineReflectiveTests(NonBoolConditionWithNullSafetyTest);
  });
}

@reflectiveTest
class NonBoolConditionTest extends PubPackageResolutionTest {
  test_conditional() async {
    await assertErrorsInCode('''
f() { return 3 ? 2 : 1; }
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 13, 1),
    ]);
  }

  test_do() async {
    await assertErrorsInCode(r'''
f() {
  do {} while (3);
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 21, 1),
    ]);
  }

  test_for() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (;3;) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 14, 1),
    ]);
  }

  test_for_declaration() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (int i = 0; 3;) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 24, 1),
    ]);
  }

  test_for_expression() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  int i;
  for (i = 0; 3;) {}
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 29, 1),
    ]);
  }

  test_forElement() async {
    await assertErrorsInCode('''
var v = [for (; 0;) 1];
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 16, 1),
    ]);
  }

  test_if() async {
    await assertErrorsInCode(r'''
f() {
  if (3) return 2; else return 1;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 12, 1),
    ]);
  }

  test_ifElement() async {
    await assertErrorsInCode('''
var v = [if (3) 1];
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 13, 1),
    ]);
  }

  test_while() async {
    await assertErrorsInCode(r'''
f() {
  while (3) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 15, 1),
    ]);
  }
}

@reflectiveTest
class NonBoolConditionWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_if_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  if (x) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 22, 1),
    ]);
  }

  test_ternary_condition_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x ? 0 : 1;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 18, 1),
    ]);
  }
}
