// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareInConditionTest);
  });
}

@reflectiveTest
class NullAwareInConditionTest extends DriverResolutionTest {
  test_assert() async {
    await assertErrorsInCode(r'''
m(x) {
  assert (x?.a);
}
''', [HintCode.NULL_AWARE_IN_CONDITION]);
  }

  test_conditionalExpression() async {
    await assertErrorsInCode(r'''
m(x) {
  return x?.a ? 0 : 1;
}
''', [HintCode.NULL_AWARE_IN_CONDITION]);
  }

  test_do() async {
    await assertErrorsInCode(r'''
m(x) {
  do {} while (x?.a);
}
''', [HintCode.NULL_AWARE_IN_CONDITION]);
  }

  test_for() async {
    await assertErrorsInCode(r'''
m(x) {
  for (var v = x; v?.a; v = v.next) {}
}
''', [HintCode.NULL_AWARE_IN_CONDITION]);
  }

  test_if() async {
    await assertErrorsInCode(r'''
m(x) {
  if (x?.a) {}
}
''', [HintCode.NULL_AWARE_IN_CONDITION]);
  }

  test_if_parenthesized() async {
    await assertErrorsInCode(r'''
m(x) {
  if ((x?.a)) {}
}
''', [HintCode.NULL_AWARE_IN_CONDITION]);
  }

  test_while() async {
    await assertErrorsInCode(r'''
m(x) {
  while (x?.a) {}
}
''', [HintCode.NULL_AWARE_IN_CONDITION]);
  }
}
