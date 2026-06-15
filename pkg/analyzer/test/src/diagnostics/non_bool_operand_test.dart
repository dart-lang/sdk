// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolOperandTest);
    defineReflectiveTests(NonBoolOperandWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonBoolOperandTest extends PubPackageResolutionTest {
  test_and_left() async {
    await resolveTestCodeWithDiagnostics(r'''
bool f(int left, bool right) {
  return left && right;
//       ^^^^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
}
''');
  }

  test_and_left_fromInstanceCreationExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  new Object() && true;
//^^^^^^^^^^^^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
}
''');
  }

  test_and_left_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
bool f(List<int> left, bool right) {
  return left && right;
//       ^^^^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
}
''');
  }

  test_and_left_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
bool f(Object left, bool right) {
  return left && right;
//       ^^^^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
}
''');
  }

  test_and_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  if(x && true) {}
//   ^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
}
''');
  }

  test_and_right() async {
    await resolveTestCodeWithDiagnostics(r'''
bool f(bool left, String right) {
  return left && right;
//               ^^^^^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
}
''');
  }

  test_or_left() async {
    await resolveTestCodeWithDiagnostics(r'''
bool f(List<int> left, bool right) {
  return left || right;
//       ^^^^
// [diag.nonBoolOperand] The operands of the operator '||' must be assignable to 'bool'.
}
''');
  }

  test_or_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  if(x || false) {}
//   ^
// [diag.nonBoolOperand] The operands of the operator '||' must be assignable to 'bool'.
}
''');
  }

  test_or_right() async {
    await resolveTestCodeWithDiagnostics(r'''
bool f(bool left, double right) {
  return left || right;
//               ^^^^^
// [diag.nonBoolOperand] The operands of the operator '||' must be assignable to 'bool'.
}
''');
  }
}

@reflectiveTest
class NonBoolOperandWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_and() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(dynamic a) {
  if(a && true) {}
//   ^
// [diag.nonBoolOperand] The operands of the operator '&&' must be assignable to 'bool'.
}
''');
  }
}
