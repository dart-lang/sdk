// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingInheritedMethodAndSetterTest);
  });
}

@reflectiveTest
class ConflictingInheritedMethodAndSetterTest extends PubPackageResolutionTest {
  test_class_declaresSetter() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C implements A, B {
  set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 103, 3),
    ]);
  }

  test_class_interface2() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER, 77, 1,
          contextMessages: [
            message(testFile, 17, 3),
            message(testFile, 45, 3)
          ]),
    ]);
  }

  test_class_mixin_interface() async {
    await assertErrorsInCode(r'''
mixin A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C with A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER, 77, 1,
          contextMessages: [
            message(testFile, 17, 3),
            message(testFile, 45, 3)
          ]),
    ]);
  }

  test_class_superclass_interface() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C extends A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER, 77, 1,
          contextMessages: [
            message(testFile, 17, 3),
            message(testFile, 45, 3)
          ]),
    ]);
  }

  test_class_superclass_mixin() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

mixin B {
  set foo(int _) {}
}

abstract class C extends A with B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER, 77, 1,
          contextMessages: [
            message(testFile, 17, 3),
            message(testFile, 45, 3)
          ]),
    ]);
  }

  test_extensionType() async {
    await assertErrorsInCode(r'''
extension type A(Object? it) {
  void foo() {}
}

extension type B(Object? it) {
  set foo(int _) {}
}

extension type C(Object? it) implements A, B {}
''', [
      error(
          CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER, 119, 1,
          contextMessages: [
            message(testFile, 38, 3),
            message(testFile, 87, 3)
          ]),
    ]);
  }
}
