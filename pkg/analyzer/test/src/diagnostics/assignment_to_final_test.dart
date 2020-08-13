// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalTest);
    defineReflectiveTests(AssignmentToFinalWithNullSafetyTest);
  });
}

@reflectiveTest
class AssignmentToFinalTest extends PubPackageResolutionTest {
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

  test_set_abstract_field_final_invalid() async {
    await assertErrorsInCode('''
abstract class A {
  abstract final int x;
}
void f(A a, int x) {
  a.x = x;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 70, 1),
    ]);
  }

  test_set_abstract_field_final_overridden_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int x;
}
abstract class B extends A {
  void set x(int value);
}
void f(B b, int x) {
  b.x = x; // ok because setter provided in derived class
}
''');
  }

  test_set_external_field_final_invalid() async {
    await assertErrorsInCode('''
class A {
  external final int x;
}
void f(A a, int x) {
  a.x = x;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 61, 1),
    ]);
  }

  test_set_external_field_final_overridden_valid() async {
    await assertNoErrorsInCode('''
class A {
  external final int x;
}
abstract class B extends A {
  void set x(int value);
}
void f(B b, int x) {
  b.x = x; // ok because setter provided in derived class
}
''');
  }

  test_set_external_static_field_final_invalid() async {
    await assertErrorsInCode('''
class A {
  external static final int x;
}
void f(int x) {
  A.x = x;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 63, 1),
    ]);
  }
}
