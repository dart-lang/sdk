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
''', [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  test_localVariable() async {
    await assertErrorsInCode(r'''
f(var y) {
  if (y is String) {
    int x = y;
  }
}
''', [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
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
''', [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
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
  }
}
''', [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
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
}
''', [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }
}
