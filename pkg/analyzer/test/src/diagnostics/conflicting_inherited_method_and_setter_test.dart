// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C implements A, B {
  set foo(int _) {}
}
''',
      [error(diag.conflictingFieldAndMethod, 103, 3)],
    );
  }

  test_class_interface2() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C implements A, B {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          77,
          1,
          contextMessages: [message(testFile, 17, 3), message(testFile, 45, 3)],
        ),
      ],
    );
  }

  test_class_mixin_interface() async {
    await assertErrorsInCode(
      r'''
mixin A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C with A implements B {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          77,
          1,
          contextMessages: [message(testFile, 17, 3), message(testFile, 45, 3)],
        ),
      ],
    );
  }

  test_class_superclass_interface() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C extends A implements B {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          77,
          1,
          contextMessages: [message(testFile, 17, 3), message(testFile, 45, 3)],
        ),
      ],
    );
  }

  test_class_superclass_mixin() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

mixin B {
  set foo(int _) {}
}

abstract class C extends A with B {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          77,
          1,
          contextMessages: [message(testFile, 17, 3), message(testFile, 45, 3)],
        ),
      ],
    );
  }

  test_extensionType_inheritedGetterSetter_noConflict() async {
    await assertNoErrorsInCode(r'''
extension type A(Object? it) {
  int get foo => 0;
}

extension type B(Object? it) {
  set foo(int _) {}
}

extension type C(Object? it) implements A, B {}
''');
  }

  test_extensionType_inheritedMethod_diamond_noConflict() async {
    await assertNoErrorsInCode(r'''
extension type Base(Object? it) {
  void foo() {}
}

extension type Left(Object? it) implements Base {}

extension type Right(Object? it) implements Base {}

extension type C(Object? it) implements Left, Right {}
''');
  }

  test_extensionType_inheritedMethodSetter_conflict() async {
    await assertErrorsInCode(
      r'''
extension type A(Object? it) {
  void foo() {}
}

extension type B(Object? it) {
  set foo(int _) {}
}

extension type C(Object? it) implements A, B {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          119,
          1,
          contextMessages: [message(testFile, 38, 3), message(testFile, 87, 3)],
        ),
      ],
    );
  }

  test_extensionType_inheritedMethodSetter_declaredGetter_noConflict() async {
    await assertNoErrorsInCode(r'''
class A {}

extension type A1(A it) {
  void foo() {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A1, B {
  int get foo => 0;
}
''');
  }

  test_extensionType_inheritedMethodSetter_declaredMethod_noConflict() async {
    await assertNoErrorsInCode(r'''
class A {}

extension type A1(A it) {
  void foo() {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A1, B {
  void foo() {}
}
''');
  }

  test_extensionType_inheritedMethodSetter_declaredSetter_noConflict() async {
    await assertNoErrorsInCode(r'''
class A {}

extension type A1(A it) {
  void foo() {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A1, B {
  set foo(int _) {}
}
''');
  }

  test_extensionType_inheritedMethodSetter_declaredStaticMethod_conflict() async {
    await assertErrorsInCode(
      r'''
extension type A(Object? it) {
  void foo() {}
}

extension type B(Object? it) {
  set foo(int _) {}
}

extension type C(Object? it) implements A, B {
  static void foo() {}
}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          119,
          1,
          contextMessages: [message(testFile, 38, 3), message(testFile, 87, 3)],
        ),
        error(diag.conflictingStaticAndInstance, 165, 3),
      ],
    );
  }

  test_extensionType_inheritedMethodSetter_declaredUnrelated_conflict() async {
    await assertErrorsInCode(
      r'''
extension type A(Object? it) {
  void foo() {}
}

extension type B(Object? it) {
  set foo(int _) {}
}

extension type C(Object? it) implements A, B {
  void bar() {}
}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          119,
          1,
          contextMessages: [message(testFile, 38, 3), message(testFile, 87, 3)],
        ),
      ],
    );
  }

  test_extensionType_inheritedMethodSetter_fromClass_declaredGetter_noConflict() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A, B {
  int get foo => 0;
}
''');
  }

  test_extensionType_inheritedMethodSetter_fromClass_declaredMethod_noConflict() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A, B {
  void foo() {}
}
''');
  }

  test_extensionType_inheritedMethodSetter_fromClass_declaredSetter_noConflict() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A, B {
  set foo(int _) {}
}
''');
  }

  test_extensionType_inheritedMethodSetter_implicitSetter_conflict() async {
    await assertErrorsInCode(
      r'''
class A {
  int foo = 0;
}

abstract class I {
  void foo();
}

extension type E(Object it) implements A, I {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          79,
          1,
          contextMessages: [message(testFile, 54, 3), message(testFile, 16, 3)],
        ),
        error(diag.extensionTypeImplementsNotSupertype, 103, 1),
        error(diag.extensionTypeImplementsNotSupertype, 106, 1),
      ],
    );
  }

  test_extensionType_inheritedMethodSetter_indirect_conflict() async {
    await assertErrorsInCode(
      r'''
extension type BaseMethod(Object? it) {
  void foo() {}
}

extension type BaseSetter(Object? it) {
  set foo(int _) {}
}

extension type Left(Object? it) implements BaseMethod {}

extension type Right(Object? it) implements BaseSetter {}

extension type C(Object? it) implements Left, Right {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          254,
          1,
          contextMessages: [
            message(testFile, 47, 3),
            message(testFile, 105, 3),
          ],
        ),
      ],
    );
  }

  test_extensionType_inheritedMethodSetter_multiple_conflict() async {
    await assertErrorsInCode(
      r'''
extension type A(Object? it) {
  void foo() {}
}

extension type B(Object? it) {
  set foo(int _) {}
}

extension type C(Object? it) {
  void bar() {}
}

extension type D(Object? it) implements A, B, C {}
''',
      [
        error(
          diag.conflictingInheritedMethodAndSetter,
          169,
          1,
          contextMessages: [message(testFile, 38, 3), message(testFile, 87, 3)],
        ),
      ],
    );
  }
}
