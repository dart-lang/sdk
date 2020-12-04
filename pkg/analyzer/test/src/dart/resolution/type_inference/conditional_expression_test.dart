// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalExpressionTest);
    defineReflectiveTests(ConditionalExpressionWithNullSafetyTest);
  });
}

@reflectiveTest
class ConditionalExpressionTest extends PubPackageResolutionTest {
  test_upward() async {
    await resolveTestCode('''
void f(bool a, int b, int c) {
  var d = a ? b : c;
  print(d);
}
''');
    assertType(findNode.simple('d)'), 'int');
  }
}

@reflectiveTest
class ConditionalExpressionWithNullSafetyTest extends ConditionalExpressionTest
    with WithNullSafetyMixin {
  @failingTest
  test_downward() async {
    await resolveTestCode('''
void f(int b, int c) {
  var d = a() ? b : c;
  print(d);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('d)'), 'bool Function()');
  }

  test_type() async {
    await assertNoErrorsInCode('''
void f(bool b) {
  b ? 42 : null;
}
''');
    assertType(findNode.conditionalExpression('b ?'), 'int?');
  }
}
