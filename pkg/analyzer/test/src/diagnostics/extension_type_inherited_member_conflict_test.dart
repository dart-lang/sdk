// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      ExtensionTypeInheritedMemberConflictTest_extension2,
    );
    defineReflectiveTests(
      ExtensionTypeInheritedMemberConflictTest_extensionAndNot,
    );
    defineReflectiveTests(
      ExtensionTypeInheritedMemberConflictTest_notExtension,
    );
  });
}

@reflectiveTest
class ExtensionTypeInheritedMemberConflictTest_extension2
    extends PubPackageResolutionTest {
  test_conflict() async {
    await assertErrorsInCode('''
extension type A1(int it) {
  void foo() {}
}

extension type A2(int it) {
  void foo() {}
}

extension type B(int it) implements A1, A2 {}
''', [
      error(
        CompileTimeErrorCode.EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT,
        109,
        1,
        contextMessages: [
          message('/home/test/lib/test.dart', 35, 3),
          message('/home/test/lib/test.dart', 82, 3),
        ],
      ),
    ]);
  }

  test_noConflict_redeclared() async {
    await assertNoErrorsInCode('''
extension type A1(int it) {
  void foo() {}
}

extension type A2(int it) {
  void foo() {}
}

extension type B(int it) implements A1, A2 {
  void foo() {}
}
''');
  }

  test_noConflict_sameDeclaration() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  void foo() {}
}

extension type B1(int it) implements A {}

extension type B2(int it) implements A {}

extension type C(int it) implements B1, B2 {}
''');
  }
}

@reflectiveTest
class ExtensionTypeInheritedMemberConflictTest_extensionAndNot
    extends PubPackageResolutionTest {
  test_conflict() async {
    await assertErrorsInCode('''
class A {
  void foo() {}
}

extension type B(A it) {
  void foo() {}
}

extension type C(A it) implements A, B {}
''', [
      error(
        CompileTimeErrorCode.EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT,
        88,
        1,
        contextMessages: [
          message('/home/test/lib/test.dart', 17, 3),
          message('/home/test/lib/test.dart', 61, 3),
        ],
      ),
    ]);
  }

  test_redeclared() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

extension type B(A it) {
  void foo() {}
}

extension type C(A it) implements A, B {
  void foo() {}
}
''');
  }
}

@reflectiveTest
class ExtensionTypeInheritedMemberConflictTest_notExtension
    extends PubPackageResolutionTest {
  test_conflict() async {
    await assertErrorsInCode('''
class A {
  void foo(int a) {}
}

class B {
  void foo(String a) {}
}

class C implements A, B {
  void foo(Object a) {}
}

extension type D(C it) implements A, B {}
''', [
      error(
        CompileTimeErrorCode.EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT,
        139,
        1,
        contextMessages: [
          message('/home/test/lib/test.dart', 17, 3),
          message('/home/test/lib/test.dart', 51, 3)
        ],
      ),
    ]);
  }

  test_noConflict_notExtension_combined() async {
    await assertNoErrorsInCode('''
abstract class A<T> {
  (Object?, dynamic, dynamic) method(T t);
}

abstract class B<T> {
  (dynamic, Object?, dynamic) method(T t);
}

abstract class C<T> implements A<T>, B<T> {}

abstract class D<T> {
  (dynamic, dynamic, Object?) method(T t);
}

abstract class E<T> implements C<T>, D<T> {}

extension type F<T>(C<T> c) implements A<T>, B<T> {}

extension type G<T>(E<T> e) implements F<T>, D<T> {}
''');
  }

  test_noConflict_redeclared() async {
    await assertNoErrorsInCode('''
class A {
  void foo(int a) {}
}

class B {
  void foo(String a) {}
}

class C implements A, B {
  void foo(Object a) {}
}

extension type D(C it) implements A, B {
  void foo() {}
}
''');
  }

  test_noConflict_sameDeclaration() async {
    await assertNoErrorsInCode('''
class A {
  int foo() => 0;
}

class B1 extends A {}

class B2 extends A {}

abstract class C implements B1, B2 {}

extension type D(C it) implements B1, B2 {}
''');
  }
}
