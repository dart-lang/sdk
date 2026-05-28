// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolExpressionTest);
    defineReflectiveTests(NonBoolExpressionWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonBoolExpressionTest extends PubPackageResolutionTest {
  test_functionType_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
bool makeAssertion() => true;
f() {
  assert(makeAssertion);
//       ^^^^^^^^^^^^^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');
  }

  test_functionType_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int makeAssertion() => 1;
f() {
  assert(makeAssertion);
//       ^^^^^^^^^^^^^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');
  }

  test_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  assert(0);
//       ^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');
  }
}

@reflectiveTest
class NonBoolExpressionWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_assert() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(dynamic a) {
  assert(a);
//       ^
// [diag.nonBoolExpression] The expression in an assert must be of type 'bool'.
}
''');
  }
}
