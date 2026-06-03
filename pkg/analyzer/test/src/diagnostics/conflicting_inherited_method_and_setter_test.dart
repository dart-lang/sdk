// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B {
  set foo(int _) {}
}

abstract class C implements A, B {
  set foo(int _) {}
//    ^^^
// [diag.conflictingFieldAndMethod] Class 'C' can't define field 'foo' and have method 'A.foo' with the same name.
}
''');
  }

  test_class_interface2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the class 'A'.
}

class B {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the class 'B'.
}

abstract class C implements A, B {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The class 'C' can't inherit both a method and a setter named 'foo'.
''');
  }

  test_class_mixin_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the mixin 'A'.
}

class B {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the class 'B'.
}

abstract class C with A implements B {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The class 'C' can't inherit both a method and a setter named 'foo'.
''');
  }

  test_class_superclass_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the class 'A'.
}

class B {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the class 'B'.
}

abstract class C extends A implements B {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The class 'C' can't inherit both a method and a setter named 'foo'.
''');
  }

  test_class_superclass_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the class 'A'.
}

mixin B {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the mixin 'B'.
}

abstract class C extends A with B {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The class 'C' can't inherit both a method and a setter named 'foo'.
''');
  }

  test_extensionType_inheritedGetterSetter_noConflict() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
extension type Base(Object? it) {
  void foo() {}
}

extension type Left(Object? it) implements Base {}

extension type Right(Object? it) implements Base {}

extension type C(Object? it) implements Left, Right {}
''');
  }

  test_extensionType_inheritedMethodSetter_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Object? it) {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the extension type 'A'.
}

extension type B(Object? it) {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the extension type 'B'.
}

extension type C(Object? it) implements A, B {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The extension type 'C' can't inherit both a method and a setter named 'foo'.
''');
  }

  test_extensionType_inheritedMethodSetter_declaredGetter_noConflict() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Object? it) {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the extension type 'A'.
}

extension type B(Object? it) {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the extension type 'B'.
}

extension type C(Object? it) implements A, B {
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The extension type 'C' can't inherit both a method and a setter named 'foo'.
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_extensionType_inheritedMethodSetter_declaredUnrelated_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Object? it) {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the extension type 'A'.
}

extension type B(Object? it) {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the extension type 'B'.
}

extension type C(Object? it) implements A, B {
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The extension type 'C' can't inherit both a method and a setter named 'foo'.
  void bar() {}
}
''');
  }

  test_extensionType_inheritedMethodSetter_fromClass_declaredGetter_noConflict() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
//    ^^^
// [context 2] The setter is inherited from the class 'A'.
}

abstract class I {
  void foo();
//     ^^^
// [context 1] The method is inherited from the class 'I'.
}

extension type E(Object it) implements A, I {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The extension type 'E' can't inherit both a method and a setter named 'foo'.
//                                     ^
// [diag.extensionTypeImplementsNotSupertype] 'A' is not a supertype of 'Object', the representation type.
//                                        ^
// [diag.extensionTypeImplementsNotSupertype] 'I' is not a supertype of 'Object', the representation type.
''');
  }

  test_extensionType_inheritedMethodSetter_indirect_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type BaseMethod(Object? it) {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the extension type 'BaseMethod'.
}

extension type BaseSetter(Object? it) {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the extension type 'BaseSetter'.
}

extension type Left(Object? it) implements BaseMethod {}

extension type Right(Object? it) implements BaseSetter {}

extension type C(Object? it) implements Left, Right {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The extension type 'C' can't inherit both a method and a setter named 'foo'.
''');
  }

  test_extensionType_inheritedMethodSetter_multiple_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Object? it) {
  void foo() {}
//     ^^^
// [context 1] The method is inherited from the extension type 'A'.
}

extension type B(Object? it) {
  set foo(int _) {}
//    ^^^
// [context 2] The setter is inherited from the extension type 'B'.
}

extension type C(Object? it) {
  void bar() {}
}

extension type D(Object? it) implements A, B, C {}
//             ^
// [diag.conflictingInheritedMethodAndSetter][context 1][context 2] The extension type 'D' can't inherit both a method and a setter named 'foo'.
''');
  }
}
