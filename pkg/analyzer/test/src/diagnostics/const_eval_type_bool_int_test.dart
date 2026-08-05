// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolIntTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolIntTest extends PubPackageResolutionTest {
  test_binary_bitAnd() async {
    await resolveTestCodeWithDiagnostics(r'''
const int a = 0;
const b = a & '';
//        ^^^^^^
// [diag.constEvalTypeBoolInt] In constant expressions, operands of this operator must be of type 'bool' or 'int'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
''');
  }

  test_binary_bitOr() async {
    await resolveTestCodeWithDiagnostics(r'''
const int a = 0;
const b = a | '';
//        ^^^^^^
// [diag.constEvalTypeBoolInt] In constant expressions, operands of this operator must be of type 'bool' or 'int'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
''');
  }

  test_binary_bitXor() async {
    await resolveTestCodeWithDiagnostics(r'''
const int a = 0;
const b = a ^ '';
//        ^^^^^^
// [diag.constEvalTypeBoolInt] In constant expressions, operands of this operator must be of type 'bool' or 'int'.
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
''');
  }

  test_binary_shiftLeft() async {
    await resolveTestCodeWithDiagnostics(r'''
const int a = 0;
const b = a << '';
//        ^^^^^^^
// [diag.constEvalTypeInt] In constant expressions, operands of this operator must be of type 'int'.
//             ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
''');
  }

  test_binary_shiftRight() async {
    await resolveTestCodeWithDiagnostics(r'''
const int a = 0;
const b = a >> '';
//        ^^^^^^^
// [diag.constEvalTypeInt] In constant expressions, operands of this operator must be of type 'int'.
//             ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
''');
  }
}
