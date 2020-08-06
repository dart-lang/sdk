// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentInheritanceTest);
  });
}

@reflectiveTest
class InconsistentInheritanceTest extends PubPackageResolutionTest {
  test_class_parameterType() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo(int i);
}
abstract class B {
  void foo(String s);
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 98, 1),
    ]);
  }

  test_class_requiredParameters() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo();
}
abstract class B {
  void foo(int y);
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 90, 1),
    ]);
  }

  test_class_returnType() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}
abstract class B {
  String foo();
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 86, 1),
    ]);
  }

  test_mixin_implements_parameterType() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo(int i);
}
abstract class B {
  void foo(String s);
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 89, 1),
    ]);
  }

  test_mixin_implements_requiredParameters() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo();
}
abstract class B {
  void foo(int y);
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 81, 1),
    ]);
  }

  test_mixin_implements_returnType() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}
abstract class B {
  String foo();
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 77, 1),
    ]);
  }

  test_mixin_on_parameterType() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo(int i);
}
abstract class B {
  void foo(String s);
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 89, 1),
    ]);
  }

  test_mixin_on_requiredParameters() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo();
}
abstract class B {
  void foo(int y);
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 81, 1),
    ]);
  }

  test_mixin_on_returnType() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}
abstract class B {
  String foo();
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 77, 1),
    ]);
  }
}
