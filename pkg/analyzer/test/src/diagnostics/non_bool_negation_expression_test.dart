// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolNegationExpressionTest);
    defineReflectiveTests(NonBoolNegationExpressionWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonBoolNegationExpressionTest extends PubPackageResolutionTest {
  test_nonBool() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  !42;
// ^^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
}
''');
  }

  test_nonBool_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  ![1, 2, 3];
// ^^^^^^^^^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
}
''');
  }

  test_nonBool_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  !o;
// ^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
}
''');
  }

  test_null() async {
    await resolveTestCodeWithDiagnostics('''
void m(Null x) {
  !x;
// ^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
}
''');
  }
}

@reflectiveTest
class NonBoolNegationExpressionWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_negation() async {
    await assertTestCodeWithStrictCastsDiagnostics(r'''
void f(dynamic a) {
  !a;
// ^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
}
''');
  }
}
