// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedOperatorTest);
    defineReflectiveTests(UndefinedOperatorTestWithExtensionMethodsTest);
  });
}

@reflectiveTest
class UndefinedOperatorTest extends DriverResolutionTest {
  test_binaryExpression() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a + 1;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 44, 1),
    ]);
  }

  test_binaryExpression_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator +(B b) {}
}
f(var a) {
  if (a is A) {
    a + 1;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 87, 1),
    ]);
  }

  test_index_both() async {
    await assertErrorsInCode(r'''
class A {}

f(A a) {
  a[0]++;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 24, 3),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 24, 3),
    ]);
  }

  test_index_getter() async {
    await assertErrorsInCode(r'''
class A {}

f(A a) {
  a[0];
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 24, 3),
    ]);
  }

  test_index_null() async {
    await assertErrorsInCode(r'''
f(Null x) {
  x[0];
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 15, 3),
    ]);
  }

  test_index_setter() async {
    await assertErrorsInCode(r'''
class A {}

f(A a) {
  a[0] = 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 24, 3),
    ]);
  }

  test_minus_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x - 3;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 20, 1),
    ]);
  }

  test_minusEq_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x -= 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 20, 2),
    ]);
  }

  test_plus_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x + 3;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 20, 1),
    ]);
  }

  test_plusEq_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 20, 2),
    ]);
  }

  test_postfixDec_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x--;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 19, 2),
    ]);
  }

  test_postfixExpression() async {
    await assertNoErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a++;
  }
}
''');
  }

  test_postfixExpression_inSubtype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if (a is A) {
    a++;
  }
}
''');
  }

  test_postfixInc_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x++;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 19, 2),
    ]);
  }

  test_prefixDec_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  --x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 18, 2),
    ]);
  }

  test_prefixExpression() async {
    await assertNoErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    ++a;
  }
}
''');
  }

  test_prefixExpression_inSubtype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if (a is A) {
    ++a;
  }
}
''');
  }

  test_prefixInc_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  ++x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 18, 2),
    ]);
  }

  test_unaryMinus_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  -x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 18, 1),
    ]);
  }
}

@reflectiveTest
class UndefinedOperatorTestWithExtensionMethodsTest
    extends UndefinedOperatorTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_index_get_extendedHasNone_extensionHasGetter() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  a[0];
}
''');
  }

  test_index_get_extendedHasSetter_extensionHasGetter() async {
    await assertErrorsInCode(r'''
class A {
  void operator[]=(int index, int value) {}
}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  a[0];
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 125, 3),
    ]);
  }

  test_index_set_extendedHasGetter_extensionHasSetter() async {
    await assertErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  a[0] = 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 125, 3),
    ]);
  }

  test_index_set_extendedHasNone_extensionHasSetter() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  a[0] = 1;
}
''');
  }
}
