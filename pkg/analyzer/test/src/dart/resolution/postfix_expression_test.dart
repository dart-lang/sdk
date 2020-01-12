// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PostfixExpressionResolutionTest);
    defineReflectiveTests(PostfixExpressionResolutionWithNnbdTest);
  });
}

@reflectiveTest
class PostfixExpressionResolutionTest extends DriverResolutionTest {
  test_localVariable_dec() async {
    await assertNoErrorsInCode(r'''
f(int x) {
  x--;
}
''');

    assertPostfixExpression(
      findNode.postfix('x--'),
      element: numElement.getMethod('-'),
      type: 'int',
    );
  }

  test_localVariable_inc() async {
    await assertNoErrorsInCode(r'''
f(int x) {
  x++;
}
''');

    assertPostfixExpression(
      findNode.postfix('x++'),
      element: numElement.getMethod('+'),
      type: 'int',
    );
  }

  test_property_inc_differentTypes() async {
    await assertNoErrorsInCode(r'''
dynamic get x => 0;

set x(Object _) {}

f() {
  x++;
}
''');

    assertSimpleIdentifier(
      findNode.simple('x++'),
      element: findElement.topSet('x'),
      type: 'Object',
    );

    assertPostfixExpression(
      findNode.postfix('x++'),
      element: null,
      type: 'dynamic',
    );
  }
}

@reflectiveTest
class PostfixExpressionResolutionWithNnbdTest
    extends PostfixExpressionResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  @override
  bool get typeToStringWithNullability => true;

  test_bang() async {
    await assertNoErrorsInCode(r'''
f(int? x) {
  x!;
}
''');

    assertPostfixExpression(
      findNode.postfix('x!'),
      element: null,
      type: 'int',
    );
  }

  test_localVariable_inc_depromote() async {
    await assertNoErrorsInCode(r'''
class A {
  Object operator +(int _) => this;
}

f(Object x) {
  if (x is A) {
    x++;
    x; // ref
  }
}
''');

    assertType(findNode.simple('x++;'), 'A');

    assertPostfixExpression(
      findNode.postfix('x++'),
      element: findElement.method('+'),
      type: 'A',
    );

    assertType(findNode.simple('x; // ref'), 'Object');
  }
}
