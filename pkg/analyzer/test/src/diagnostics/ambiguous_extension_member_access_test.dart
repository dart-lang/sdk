// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousExtensionMemberAccessTest);
  });
}

@reflectiveTest
class AmbiguousExtensionMemberAccessTest extends DriverResolutionTest {
  test_call() async {
    await assertErrorsInCode('''
class A {}

extension E1 on A {
  int call() => 0;
}

extension E2 on A {
  int call() => 0;
}

int f(A a) => a();
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 110, 1),
      error(
          StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 110, 1),
    ]);
  }

  test_getter_getter() async {
    await assertErrorsInCode('''
extension E1 on int {
  void get a => 1;
}

extension E2 on int {
  void get a => 2;
}

f() {
  0.a;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 98, 1),
    ]);
    var access = findNode.propertyAccess('0.a');
    assertElementNull(access);
    assertTypeDynamic(access);
  }

  test_getter_method() async {
    await assertErrorsInCode('''
extension E on int {
  int get a => 1;
}

extension E2 on int {
  void a() {}
}

f() {
  0.a;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 91, 1),
    ]);
    var access = findNode.propertyAccess('0.a');
    assertElementNull(access);
    assertTypeDynamic(access);
  }

  test_getter_setter() async {
    await assertErrorsInCode('''
extension E on int {
  int get a => 1;
}

extension E2 on int {
  set a(int v) { }
}

f() {
  0.a;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 96, 1),
    ]);
    var access = findNode.propertyAccess('0.a');
    assertElementNull(access);
    assertTypeDynamic(access);
  }

  test_method_method() async {
    await assertErrorsInCode('''
extension E1 on int {
  void a() {}
}

extension E2 on int {
  void a() {}
}

f() {
  0.a();
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 88, 1),
    ]);
    var invocation = findNode.methodInvocation('0.a()');
    assertElementNull(invocation);
    assertTypeDynamic(invocation);
  }

  test_noMoreSpecificExtension() async {
    await assertErrorsInCode(r'''
class Target<T> {}

class SubTarget<T> extends Target<T> {}

extension E1 on SubTarget<Object> {
  int get foo => 0;
}

extension E2<T> on Target<T> {
  int get foo => 0;
}

f(SubTarget<num> t) {
  // The instantiated on type of `E1(t)` is `SubTarget<Object>`.
  // The instantiated on type of `E2(t)` is `Target<num>`.
  // Neither is a subtype of the other, so the resolution is ambiguous.
  t.foo;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 396, 3),
    ]);
  }

  test_operator_binary() async {
    // There is no error reported.
    await assertErrorsInCode('''
class A {}

extension E1 on A {
  A operator +(A a) => a;
}

extension E2 on A {
  A operator +(A a) => a;
}

A f(A a) => a + a;
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 122, 5),
    ]);
  }

  test_operator_index_index() async {
    await assertErrorsInCode('''
class A {}

extension E1 on A {
  int operator [](int i) => 0;
}

extension E2 on A {
  int operator [](int i) => 0;
}

int f(A a) => a[0];
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 134, 1),
    ]);
  }

  test_operator_index_indexEq() async {
    await assertErrorsInCode('''
extension E1 on int {
  int operator[](int index) => 0;
}

extension E2 on int {
  void operator[]=(int index, int value) {}
}

f() {
  0[1] += 2;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 136, 1),
    ]);
  }

  test_operator_unary() async {
    await assertErrorsInCode('''
class A {}

extension E1 on A {
  int operator -() => 0;
}

extension E2 on A {
  int operator -() => 0;
}

int f(A a) => -a;
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 123, 1),
    ]);
  }

  test_setter_setter() async {
    await assertErrorsInCode('''
extension E1 on int {
  set a(x) {}
}

extension E2 on int {
  set a(x) {}
}

f() {
  0.a = 3;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS, 88, 1),
    ]);
    var access = findNode.propertyAccess('0.a');
    assertElementNull(access);
    assertTypeDynamic(access);
  }
}
