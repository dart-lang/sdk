// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeInheritedMemberConflictTest_extension2);
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
    await resolveTestCodeWithDiagnostics(r'''
extension type A1(int it) {
  void foo() {}
//     ^^^
// [context 1] Inherited from 'A1'
}

extension type A2(int it) {
  void foo() {}
//     ^^^
// [context 2] Inherited from 'A2'
}

extension type B(int it) implements A1, A2 {}
//             ^
// [diag.extensionTypeInheritedMemberConflict][context 1][context 2] The extension type 'B' has more than one distinct member named 'foo' from implemented types.
''');
  }

  test_conflict_representationField() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(String bar) {}
//                      ^^^
// [context 1] Inherited from 'A'

extension type B(String bar) {}
//                      ^^^
// [context 2] Inherited from 'B'

extension type C(String foo) implements A, B {}
//             ^
// [diag.extensionTypeInheritedMemberConflict][context 1][context 2] The extension type 'C' has more than one distinct member named 'bar' from implemented types.
''');
  }

  test_noConflict_redeclared() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] Inherited from 'A'
}

extension type B(A it) {
  void foo() {}
//     ^^^
// [context 2] Inherited from 'B'
}

extension type C(A it) implements A, B {}
//             ^
// [diag.extensionTypeInheritedMemberConflict][context 1][context 2] The extension type 'C' has more than one distinct member named 'foo' from implemented types.
''');
  }

  test_redeclared() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(int a) {}
//     ^^^
// [context 1] Inherited from 'A'
}

class B {
  void foo(String a) {}
//     ^^^
// [context 2] Inherited from 'B'
}

class C implements A, B {
  void foo(Object a) {}
}

extension type D(C it) implements A, B {}
//             ^
// [diag.extensionTypeInheritedMemberConflict][context 1][context 2] The extension type 'D' has more than one distinct member named 'foo' from implemented types.
''');
  }

  test_noConflict_notExtension_combined() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
