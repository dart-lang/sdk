// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAssignmentTest);
  });
}

@reflectiveTest
class InvalidAssignmentTest extends DriverResolutionTest {
  test_assingment_to_dynamic() async {
    await assertNoErrorsInCode(r'''
f() {
  var g;
  g = () => 0;
}
''');
  }

  test_compoundAssignment() async {
    await assertNoErrorsInCode(r'''
class byte {
  int _value;
  byte(this._value);
  byte operator +(int val) { return this; }
}

void main() {
  byte b = new byte(52);
  b += 3;
}
''');
  }

  test_defaultValue_named() async {
    await assertNoErrorsInCode(r'''
f({String x: '0'}) {
}''');
  }

  test_defaultValue_optional() async {
    await assertNoErrorsInCode(r'''
f([String x = '0']) {
}
''');
  }

  test_ifNullAssignment_compatibleType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  num n;
  n ??= i;
}
''');
  }

  test_ifNullAssignment_sameType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  int j;
  j ??= i;
}
''');
  }

  test_implicitlyImplementFunctionViaCall_1() async {
    // issue 18341
    //
    // This test and
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()' are
    // closely related: here we see that 'I' checks as a subtype of 'IntToInt'.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new I();
''');
  }

  test_implicitlyImplementFunctionViaCall_2() async {
    // issue 18341
    //
    // Here 'C' checks as a subtype of 'I', but 'C' does not check as a subtype
    // of 'IntToInt'. Together with
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_1()' we see
    // that subtyping is not transitive here.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new C();
''');
  }

  test_implicitlyImplementFunctionViaCall_3() async {
    // issue 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()', but
    // uses type 'Function' instead of more precise type 'IntToInt' for 'f'.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
Function f = new C();
''');
  }

  test_implicitlyImplementFunctionViaCall_4() async {
    // issue 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()', but
    // uses type 'VoidToInt' instead of more precise type 'IntToInt' for 'f'.
    //
    // Here 'C <: IntToInt <: VoidToInt', but the spec gives no transitivity
    // rule for '<:'. However, many of the :/tools/test.py tests assume this
    // transitivity for 'JsBuilder' objects, assigning them to
    // '(String) -> dynamic'. The declared type of 'JsBuilder.call' is
    // '(String, [dynamic]) -> Expression'.
    await assertNoErrorsInCode(r'''
class I {
  int call([int x]) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int VoidToInt();
VoidToInt f = new C();
''');
  }

  test_instanceVariable() async {
    await assertErrorsInCode(r'''
class A {
  int x;
}
f(var y) {
  A a;
  if (y is String) {
    a.x = y;
  }
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 70, 1),
    ]);
  }

  test_invalidAssignment() async {
    await assertNoErrorsInCode(r'''
f() {
  var x;
  var y;
  x = y;
}
''');
  }

  test_localVariable() async {
    await assertErrorsInCode(r'''
f(var y) {
  if (y is String) {
    int x = y;
    print(x);
  }
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 44, 1),
    ]);
  }

  test_postfixExpression_localVariable() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  a++;
}
''');
  }

  test_postfixExpression_property() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a;
}

f(C c) {
  c.a++;
}
''');
  }

  test_prefixExpression_localVariable() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  ++a;
}
''');
  }

  test_prefixExpression_property() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a;
}

f(C c) {
  ++c.a;
}
''');
  }

  test_promotedTypeParameter_regress35306() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
class C extends D {}
class D {}

void f<X extends A, Y extends B>(X x) {
  if (x is Y) {
    A a = x;
    B b = x;
    X x2 = x;
    Y y = x;
  }
}
''');
  }

  test_staticVariable() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
}
f(var y) {
  if (y is String) {
    A.x = y;
  }
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 70, 1),
    ]);
  }

  test_typeParameterRecursion_regress35306() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends D {}
class D {}

void f<X extends A, Y extends B>(X x) {
  if (x is Y) {
    D d = x;
    print(d);
  }
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 131, 1),
    ]);
  }

  test_variableDeclaration() async {
    // 17971
    await assertErrorsInCode(r'''
class Point {
  final num x, y;
  Point(this.x, this.y);
  Point operator +(Point other) {
    return new Point(x+other.x, y+other.y);
  }
}
main() {
  var p1 = new Point(0, 0);
  var p2 = new Point(10, 10);
  int n = p1 + p2;
  print(n);
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 218, 7),
    ]);
  }
}
