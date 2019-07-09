// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedOperatorTest);
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

  test_index_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  x[0];
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_indexBoth() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a[0]++;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 43, 3),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 43, 3),
    ]);
  }

  test_indexBoth_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if (a is A) {
    a[0]++;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 93, 3),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 93, 3),
    ]);
  }

  test_indexGetter() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a[0];
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 43, 3),
    ]);
  }

  test_indexGetter_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if (a is A) {
    a[0];
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 93, 3),
    ]);
  }

  test_indexSetter() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a[0] = 1;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 43, 3),
    ]);
  }

  test_indexSetter_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator []=(i, v) {}
}
f(var a) {
  if (a is A) {
    a[0] = 1;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 89, 3),
    ]);
  }

  test_minus_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  x - 3;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_minusEq_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  x -= 1;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_plus_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  x + 3;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_plusEq_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  x += 1;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_postfixDec_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  x--;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
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
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  x++;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_prefixDec_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  --x;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
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
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  ++x;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_unaryMinus_null() async {
    await assertErrorCodesInCode(r'''
m() {
  Null x;
  -x;
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
}
