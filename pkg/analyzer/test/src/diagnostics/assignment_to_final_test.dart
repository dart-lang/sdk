// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';
import '../dart/resolution/with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalTest);
    defineReflectiveTests(AssignmentToFinalWithNullSafetyTest);
  });
}

@reflectiveTest
class AssignmentToFinalTest extends DriverResolutionTest {
  test_instanceVariable() async {
    await assertErrorsInCode('''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v = 1;
}''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 54, 1),
    ]);
  }

  test_instanceVariable_plusEq() async {
    await assertErrorsInCode('''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v += 1;
}''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 54, 1),
    ]);
  }
}

@reflectiveTest
class AssignmentToFinalWithNullSafetyTest extends AssignmentToFinalTest
    with WithNullSafetyMixin {
  test_field_late() async {
    await assertNoErrorsInCode('''
class A {
  late final int a;
  late final int b = 0;
  void m() {
    a = 1;
    b = 1;
  }
}
''');
  }

  test_field_static_late() async {
    await assertNoErrorsInCode('''
class A {
  static late final int a;
  static late final int b = 0;
  void m() {
    a = 1;
    b = 1;
  }
}
''');
  }
}
