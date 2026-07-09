// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedOperatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedOperatorTest extends PubPackageResolutionTest {
  test_assignmentExpression_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {
  f(A a) {
    A a2 = new A();
    a += a2;
//    ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
  }
}
''');
  }

  test_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(a) {
  if (a is A) {
    a + 1;
//    ^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
  }
}
''');
  }

  test_binaryExpression_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { A }
f(E e) => e + 1;
//          ^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'E'.
''');
  }

  test_binaryExpression_inSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator +(B b) {}
}
f(a) {
  if (a is A) {
    a + 1;
//    ^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
  }
}
''');
  }

  test_binaryExpression_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) => m + 1;
//          ^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'M'.
''');
  }

  test_index_both() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

f(A a) {
  a[0]++;
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'A'.
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'A'.
}
''');
  }

  test_index_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
enum E { A }
f(E e) {
  e[0];
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'E'.
}
''');
  }

  test_index_get_extendedHasNone_extensionHasGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void operator[]=(int index, int value) {}
}

extension E on A {
  int operator[](int index) => 0;
}

f(A a) {
  a[0];
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'A'.
}
''');
  }

  test_index_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

f(A a) {
  a[0];
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'A'.
}
''');
  }

  test_index_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) {
  m[0];
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'M'.
}
''');
  }

  test_index_null() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Null x) {
  x[0];
// ^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_index_set_extendedHasGetter_extensionHasSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
}

extension E on A {
  void operator[]=(int index, int value) {}
}

f(A a) {
  a[0] = 1;
// ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'A'.
}
''');
  }

  test_index_set_extendedHasNone_extensionHasSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {}

f(A a) {
  a[0] = 1;
// ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'A'.
}
''');
  }

  test_indexBoth_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(A a) {
  a[0]++;
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'A'.
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'A'.
}
''');
  }

  test_indexGetter_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(A a) {
  a[0];
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'A'.
}
''');
  }

  test_indexSetter_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(A a) {
  a[0] = 1;
// ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'A'.
}
''');
  }

  test_minus_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x - 3;
//  ^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_minusEq_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x -= 1;
//  ^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_plus_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x + 3;
//  ^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_plus_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(A a) {
  a + 1;
//  ^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
}
''');
  }

  test_plusEq_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x += 1;
//  ^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_postfixDec_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x--;
// ^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_postfixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(a) {
  if (a is A) {
    a++;
//   ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
  }
}
''');
  }

  test_postfixExpression_inSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(a) {
  if (a is A) {
    a++;
//   ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
  }
}
''');
  }

  test_postfixExpression_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) {
  m++;
// ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'M'.
}
''');
  }

  test_postfixExpression_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(A a) {
  a++;
// ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
}
''');
  }

  test_postfixInc_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x++;
// ^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_prefixDec_null() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  --x;
//^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(a) {
  if (a is A) {
    ++a;
//  ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
  }
}
''');
  }

  test_prefixExpression_inSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(a) {
  if (a is A) {
    ++a;
//  ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
  }
}
''');
  }

  test_prefixExpression_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) {
  -m;
//^
// [diag.undefinedOperator] The operator 'unary-' isn't defined for the type 'M'.
}
''');
  }

  test_prefixExpression_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(A a) {
  ++a;
//^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
}
''');
  }

  test_prefixInc_null() async {
    await resolveTestCodeWithDiagnostics('''
m() {
  Null x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  ++x;
//^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_tilde_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
const A = 3;
const B = ~((1 << A) - 1);
''');
  }

  test_unaryMinus_null() async {
    await resolveTestCodeWithDiagnostics('''
m() {
  Null x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  -x;
//^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }
}
