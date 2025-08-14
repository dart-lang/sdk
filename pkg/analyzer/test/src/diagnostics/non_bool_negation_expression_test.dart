// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolNegationExpressionTest);
    defineReflectiveTests(NonBoolNegationExpressionWithStrictCastsTest);
  });
}

@reflectiveTest
class NonBoolNegationExpressionTest extends PubPackageResolutionTest {
  test_nonBool() async {
    await assertErrorsInCode(
      r'''
f() {
  !42;
}
''',
      [error(CompileTimeErrorCode.nonBoolNegationExpression, 9, 2)],
    );
  }

  test_nonBool_fromLiteral() async {
    await assertErrorsInCode(
      '''
f() {
  ![1, 2, 3];
}
''',
      [error(CompileTimeErrorCode.nonBoolNegationExpression, 9, 9)],
    );
  }

  test_nonBool_fromSupertype() async {
    await assertErrorsInCode(
      '''
f(Object o) {
  !o;
}
''',
      [error(CompileTimeErrorCode.nonBoolNegationExpression, 17, 1)],
    );
  }

  test_null() async {
    await assertErrorsInCode(
      '''
void m(Null x) {
  !x;
}
''',
      [error(CompileTimeErrorCode.nonBoolNegationExpression, 20, 1)],
    );
  }
}

@reflectiveTest
class NonBoolNegationExpressionWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_negation() async {
    await assertErrorsWithStrictCasts(
      r'''
void f(dynamic a) {
  !a;
}
''',
      [error(CompileTimeErrorCode.nonBoolNegationExpression, 23, 1)],
    );
  }
}
