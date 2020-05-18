// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberAccessFromStaticTest);
  });
}

@reflectiveTest
class InstanceMemberAccessFromStaticTest extends DriverResolutionTest {
  test_class_field() async {
    await assertErrorsInCode(r'''
class A {
  int foo;

  static void bar() {
    foo;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 48, 3),
    ]);
  }

  test_class_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;

  static void bar() {
    foo;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 57, 3),
    ]);
  }

  test_class_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}

  static void bar() {
    foo();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 53, 3),
    ]);
  }

  test_class_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(int _) {}

  static void bar() {
    foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 57, 3),
    ]);
  }

  test_extension_external_getter() async {
    await assertErrorsInCode(r'''
extension E on A {
  int get foo => 0;
}

class A {
  static void bar() {
    foo;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 78, 3),
    ]);
  }

  test_extension_external_method() async {
    await assertErrorsInCode(r'''
extension E on A {
  void foo() {}
}

class A {
  static void bar() {
    foo();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 74, 3),
    ]);
  }

  test_extension_external_setter() async {
    await assertErrorsInCode(r'''
extension E on A {
  set foo(int _) {}
}

class A {
  static void bar() {
    foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 78, 3),
    ]);
  }

  test_extension_internal_getter() async {
    await assertErrorsInCode(r'''
extension E on int {
  int get foo => 0;

  static void bar() {
    foo;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 68, 3),
    ]);
  }

  test_extension_internal_method() async {
    await assertErrorsInCode(r'''
extension E on int {
  void foo() {}

  static void bar() {
    foo();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 64, 3),
    ]);
  }

  test_extension_internal_setter() async {
    await assertErrorsInCode(r'''
extension E on int {
  set foo(int _) {}

  static void bar() {
    foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 68, 3),
    ]);
  }
}
