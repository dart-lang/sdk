// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolTest extends PubPackageResolutionTest {
  test_binary_and() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = true && '';
//        ^^^^^^^^^^
// [diag.constEvalTypeBool] In constant expressions, operands of this operator must be of type 'bool'.
//                ^^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
''');
  }

  test_binary_leftTrue() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = (true || 0);
//              ^^^^
// [diag.deadCode] Dead code.
//                 ^
// [diag.nonBoolOperand] The operands of the operator '||' must be assignable to 'bool'.
''');
  }

  test_binary_or() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = false || '';
//        ^^^^^^^^^^^
// [diag.constEvalTypeBool] In constant expressions, operands of this operator must be of type 'bool'.
//                 ^^
// [diag.nonBoolOperand] The operands of the operator '||' must be assignable to 'bool'.
''');
  }

  test_lengthOfErroneousConstant() async {
    // Attempting to compute the length of constant that couldn't be evaluated
    // (due to an error) should not crash the analyzer (see dartbug.com/23383)
    await resolveTestCodeWithDiagnostics(r'''
const int i = (1 ? 'alpha' : 'beta').length;
//             ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
// [diag.constEvalTypeBool] In constant expressions, operands of this operator must be of type 'bool'.
''');
  }

  test_logicalOr_trueLeftOperand() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final int? x;
  const C({this.x}) : assert(x == null || x >= 0);
}
const c = const C();
''');
  }
}
