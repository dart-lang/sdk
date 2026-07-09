// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeNumTest);
  });
}

@reflectiveTest
class ConstEvalTypeNumTest extends PubPackageResolutionTest {
  test_binary_add() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a + '';
//        ^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_divide() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a / '';
//        ^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_greaterOrEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a >= '';
//        ^^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//             ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_greaterThan() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a > '';
//        ^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_lessOrEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a <= '';
//        ^^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//             ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_lessThan() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a < '';
//        ^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_modulo() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a % '';
//        ^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_multiply() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a * '';
//        ^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_subtract() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a - '';
//        ^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_binary_truncatingDivide() async {
    await resolveTestCodeWithDiagnostics(r'''
const num a = 0;
const b = a ~/ '';
//        ^^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//             ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }
}
