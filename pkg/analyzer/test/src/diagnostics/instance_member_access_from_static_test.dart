// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberAccessFromStaticTest);
  });
}

@reflectiveTest
class InstanceMemberAccessFromStaticTest extends PubPackageResolutionTest {
  test_class_superMethod_fromMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

class B extends A {
  static void bar() {
    foo();
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 75, 3)],
    );
  }

  test_class_thisGetter_fromMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;

  static void bar() {
    foo;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 57, 3)],
    );
  }

  test_class_thisGetter_fromMethod_fromClosure() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;

  static Object bar() {
    return () {
      foo;
    };
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 77, 3)],
    );
  }

  test_class_thisGetter_fromMethod_functionExpression() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;

  static void bar() {
    () => foo;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 63, 3)],
    );
  }

  test_class_thisGetter_fromMethod_functionExpression_localVariable() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;

  static void bar() {
    // ignore:unused_local_variable
    var x = () => foo;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 107, 3)],
    );
  }

  test_class_thisMethod_fromMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}

  static void bar() {
    foo();
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 53, 3)],
    );
  }

  test_class_thisSetter_fromMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(int _) {}

  static void bar() {
    foo = 0;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 57, 3)],
    );
  }

  test_extension_external_getter_fromMethod() async {
    await assertErrorsInCode(
      r'''
extension E on A {
  int get foo => 0;
}

class A {
  static void bar() {
    foo;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 78, 3)],
    );
  }

  test_extension_external_method_fromMethod() async {
    await assertErrorsInCode(
      r'''
extension E on A {
  void foo() {}
}

class A {
  static void bar() {
    foo();
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 74, 3)],
    );
  }

  test_extension_external_setter_fromMethod() async {
    await assertErrorsInCode(
      r'''
extension E on A {
  set foo(int _) {}
}

class A {
  static void bar() {
    foo = 0;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 78, 3)],
    );
  }

  test_extension_internal_getter_fromMethod() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  int get foo => 0;

  static void bar() {
    foo;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 68, 3)],
    );
  }

  test_extension_internal_method_fromMethod() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  void foo() {}

  static void bar() {
    foo();
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 64, 3)],
    );
  }

  test_extension_internal_setter_fromMethod() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  set foo(int _) {}

  static void bar() {
    foo = 0;
  }
}
''',
      [error(CompileTimeErrorCode.instanceMemberAccessFromStatic, 68, 3)],
    );
  }
}
