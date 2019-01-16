// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAssignmentTest);
    defineReflectiveTests(InvalidAssignmentTest_Driver);
  });
}

@reflectiveTest
class InvalidAssignmentTest extends ResolverTestCase {
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

@reflectiveTest
class InvalidAssignmentTest_Driver extends InvalidAssignmentTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
