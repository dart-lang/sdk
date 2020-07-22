// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolTest extends DriverResolutionTest {
  test_binary_and() async {
    await assertErrorsInCode('''
const c = true && '';
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 10),
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 18, 2),
    ]);
  }

  test_binary_leftTrue() async {
    await assertErrorsInCode('''
const c = (true || 0);
''', [
      error(HintCode.DEAD_CODE, 19, 1),
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 19, 1),
    ]);
  }

  test_binary_or() async {
    await assertErrorsInCode(r'''
const c = false || '';
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 11),
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 19, 2),
    ]);
  }

  test_logicalOr_trueLeftOperand() async {
    await assertNoErrorsInCode(r'''
class C {
  final int x;
  const C({this.x}) : assert(x == null || x >= 0);
}
const c = const C();
''');
  }
}
