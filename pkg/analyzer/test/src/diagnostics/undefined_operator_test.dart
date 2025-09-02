// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedOperatorTest);
  });
}

@reflectiveTest
class UndefinedOperatorTest extends PubPackageResolutionTest {
  test_assignmentExpression_undefined() async {
    await assertErrorsInCode(
      r'''
class A {}
class B {
  f(A a) {
    A a2 = new A();
    a += a2;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 58, 2)],
    );
  }

  test_binaryExpression() async {
    await assertErrorsInCode(
      r'''
class A {}
f(var a) {
  if (a is A) {
    a + 1;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 44, 1)],
    );
  }

  test_binaryExpression_enum() async {
    await assertErrorsInCode(
      r'''
enum E { A }
f(E e) => e + 1;
''',
      [error(CompileTimeErrorCode.undefinedOperator, 25, 1)],
    );
  }

  test_binaryExpression_inSubtype() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  operator +(B b) {}
}
f(var a) {
  if (a is A) {
    a + 1;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 87, 1)],
    );
  }

  test_binaryExpression_mixin() async {
    await assertErrorsInCode(
      r'''
mixin M {}
f(M m) => m + 1;
''',
      [error(CompileTimeErrorCode.undefinedOperator, 23, 1)],
    );
  }

  test_index_both() async {
    await assertErrorsInCode(
      r'''
class A {}

f(A a) {
  a[0]++;
}
''',
      [
        error(CompileTimeErrorCode.undefinedOperator, 24, 3),
        error(CompileTimeErrorCode.undefinedOperator, 24, 3),
      ],
    );
  }

  test_index_defined() async {
    await assertNoErrorsInCode(r'''
class A {
  operator [](a) {}
  operator []=(a, b) {}
}
f(A a) {
  a[0];
  a[0] = 1;
}
''');
  }

  test_index_enum() async {
    await assertErrorsInCode(
      r'''
enum E { A }
f(E e) {
  e[0];
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 25, 3)],
    );
  }

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
    await assertErrorsInCode(
      r'''
class A {
  void operator[]=(int index, int value) {}
}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  a[0];
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 125, 3)],
    );
  }

  test_index_getter() async {
    await assertErrorsInCode(
      r'''
class A {}

f(A a) {
  a[0];
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 24, 3)],
    );
  }

  test_index_mixin() async {
    await assertErrorsInCode(
      r'''
mixin M {}
f(M m) {
  m[0];
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 23, 3)],
    );
  }

  test_index_null() async {
    await assertErrorsInCode(
      r'''
f(Null x) {
  x[0];
}
''',
      [error(CompileTimeErrorCode.invalidUseOfNullValue, 15, 1)],
    );
  }

  test_index_set_extendedHasGetter_extensionHasSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int operator[](int index) => 0;
}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  a[0] = 1;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 125, 3)],
    );
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

  test_index_setter() async {
    await assertErrorsInCode(
      r'''
class A {}

f(A a) {
  a[0] = 1;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 24, 3)],
    );
  }

  test_indexBoth_undefined() async {
    await assertErrorsInCode(
      r'''
class A {}
f(A a) {
  a[0]++;
}
''',
      [
        error(CompileTimeErrorCode.undefinedOperator, 23, 3),
        error(CompileTimeErrorCode.undefinedOperator, 23, 3),
      ],
    );
  }

  test_indexGetter_undefined() async {
    await assertErrorsInCode(
      r'''
class A {}
f(A a) {
  a[0];
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 23, 3)],
    );
  }

  test_indexSetter_undefined() async {
    await assertErrorsInCode(
      r'''
class A {}
f(A a) {
  a[0] = 1;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 23, 3)],
    );
  }

  test_minus_null() async {
    await assertErrorsInCode(
      r'''
m() {
  Null x;
  x - 3;
}
''',
      [error(CompileTimeErrorCode.invalidUseOfNullValue, 20, 1)],
    );
  }

  test_minusEq_null() async {
    await assertErrorsInCode(
      r'''
m() {
  Null x;
  x -= 1;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 13, 1),
        error(CompileTimeErrorCode.invalidUseOfNullValue, 20, 2),
      ],
    );
  }

  test_plus_null() async {
    await assertErrorsInCode(
      r'''
m() {
  Null x;
  x + 3;
}
''',
      [error(CompileTimeErrorCode.invalidUseOfNullValue, 20, 1)],
    );
  }

  test_plus_undefined() async {
    await assertErrorsInCode(
      r'''
class A {}
f(A a) {
  a + 1;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 24, 1)],
    );
  }

  test_plusEq_null() async {
    await assertErrorsInCode(
      r'''
m() {
  Null x;
  x += 1;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 13, 1),
        error(CompileTimeErrorCode.invalidUseOfNullValue, 20, 2),
      ],
    );
  }

  test_postfixDec_null() async {
    await assertErrorsInCode(
      r'''
m() {
  Null x;
  x--;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 13, 1),
        error(CompileTimeErrorCode.invalidUseOfNullValue, 19, 2),
      ],
    );
  }

  test_postfixExpression() async {
    await assertErrorsInCode(
      r'''
class A {}
f(var a) {
  if (a is A) {
    a++;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 43, 2)],
    );
  }

  test_postfixExpression_inSubtype() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if (a is A) {
    a++;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 101, 2)],
    );
  }

  test_postfixExpression_mixin() async {
    await assertErrorsInCode(
      r'''
mixin M {}
f(M m) {
  m++;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 23, 2)],
    );
  }

  test_postfixExpression_undefined() async {
    await assertErrorsInCode(
      r'''
class A {}
f(A a) {
  a++;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 23, 2)],
    );
  }

  test_postfixInc_null() async {
    await assertErrorsInCode(
      r'''
m() {
  Null x;
  x++;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 13, 1),
        error(CompileTimeErrorCode.invalidUseOfNullValue, 19, 2),
      ],
    );
  }

  test_prefixDec_null() async {
    await assertErrorsInCode(
      r'''
m() {
  Null x;
  --x;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 13, 1),
        error(CompileTimeErrorCode.invalidUseOfNullValue, 18, 2),
      ],
    );
  }

  test_prefixExpression() async {
    await assertErrorsInCode(
      r'''
class A {}
f(var a) {
  if (a is A) {
    ++a;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 42, 2)],
    );
  }

  test_prefixExpression_inSubtype() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if (a is A) {
    ++a;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 100, 2)],
    );
  }

  test_prefixExpression_mixin() async {
    await assertErrorsInCode(
      r'''
mixin M {}
f(M m) {
  -m;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 22, 1)],
    );
  }

  test_prefixExpression_undefined() async {
    await assertErrorsInCode(
      r'''
class A {}
f(A a) {
  ++a;
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 22, 2)],
    );
  }

  test_prefixInc_null() async {
    await assertErrorsInCode(
      '''
m() {
  Null x;
  ++x;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 13, 1),
        error(CompileTimeErrorCode.invalidUseOfNullValue, 18, 2),
      ],
    );
  }

  test_tilde_defined() async {
    await assertNoErrorsInCode(r'''
const A = 3;
const B = ~((1 << A) - 1);
''');
  }

  test_unaryMinus_null() async {
    await assertErrorsInCode(
      '''
m() {
  Null x;
  -x;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 13, 1),
        error(CompileTimeErrorCode.invalidUseOfNullValue, 18, 1),
      ],
    );
  }
}
