// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationFormalParameterModifierTest);
    defineReflectiveTests(AugmentationFormalParameterNameTest);
    defineReflectiveTests(AugmentationFormalParameterScopeTest);
    defineReflectiveTests(AugmentationFormalParameterShapeTest);
    defineReflectiveTests(AugmentationFormalParameterTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationFormalParameterModifierTest extends PubPackageResolutionTest {
  test_covariant_extra() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int x);
//             ^
// [context 1] The formal parameter is here.
  augment void foo(covariant int x) {}
//                 ^^^^^^^^^
// [diag.augmentationFormalParameterModifierExtra][context 1] The augmentation has the 'covariant' modifier on this formal parameter, but the declaration doesn't.
}
''');
  }

  test_covariant_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(covariant int x);
//                       ^
// [context 1] The formal parameter is here.
  augment void foo(int x) {}
//                     ^
// [diag.augmentationFormalParameterModifierMissing][context 1] The augmentation is missing the 'covariant' modifier on this formal parameter that the declaration has.
}
''');
  }

  test_required_extra() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? x});
//           ^
// [context 1] The formal parameter is here.
augment void f({required int? x}) {}
//              ^^^^^^^^
// [diag.augmentationFormalParameterModifierExtra][context 1] The augmentation has the 'required' modifier on this formal parameter, but the declaration doesn't.
''');
  }

  test_required_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int? x});
//                    ^
// [context 1] The formal parameter is here.
augment void f({int? x}) {}
//                   ^
// [diag.augmentationFormalParameterModifierMissing][context 1] The augmentation is missing the 'required' modifier on this formal parameter that the declaration has.
''');
  }
}

@reflectiveTest
class AugmentationFormalParameterNameTest extends PubPackageResolutionTest {
  test_class_constructor_fP1__rP2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int p1;
  A(this.p1);
//       ^^
// [context 1] The preceding declaration is here.
  augment A(int p2);
//              ^^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'p2' must either match the name 'p1' from a preceding declaration or be '_'.
}
''');
  }

  test_class_constructor_sp1__rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B([super.p1]);
//         ^^
// [context 1] The preceding declaration is here.
  augment B([int? p2]);
//                ^^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'p2' must either match the name 'p1' from a preceding declaration or be '_'.
}
''');
  }

  test_class_instanceMethod_rP__x__y() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int x);
//             ^
// [context 1] The preceding declaration is here.
  augment void foo(int y) {}
//                     ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'y' must either match the name 'x' from a preceding declaration or be '_'.
}
''');
  }

  test_topLevelFunction_rP__wildcard__x__wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int _);
augment void f(int x);
augment void f(int _) {}
''');
  }

  test_topLevelFunction_rP__wildcard__x__y() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int _);
augment void f(int x);
//                 ^
// [context 1] The preceding declaration is here.
augment void f(int y) {}
//                 ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'y' must either match the name 'x' from a preceding declaration or be '_'.
''');
  }

  test_topLevelFunction_rP__x__wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x);
augment void f(int _) {}
''');
  }

  test_topLevelFunction_rp__x__wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([int? x]);
augment void f([int? _]) {}
''');
  }

  test_topLevelFunction_rP__x__wildcard__x() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x);
augment void f(int _);
augment void f(int x) {}
''');
  }

  test_topLevelFunction_rP__x__wildcard__y() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x);
//         ^
// [context 1] The preceding declaration is here.
augment void f(int _);
augment void f(int y) {}
//                 ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'y' must either match the name 'x' from a preceding declaration or be '_'.
''');
  }

  test_topLevelFunction_rP__x__y() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x);
//         ^
// [context 1] The preceding declaration is here.
augment void f(int y) {}
//                 ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'y' must either match the name 'x' from a preceding declaration or be '_'.
''');
  }

  test_topLevelFunction_rp__x__y() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([int? x]);
//           ^
// [context 1] The preceding declaration is here.
augment void f([int? y]) {}
//                   ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'y' must either match the name 'x' from a preceding declaration or be '_'.
''');
  }

  test_topLevelFunction_rP_rP__x_y__a_b() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x, int y);
//         ^
// [context 1] The preceding declaration is here.
//                ^
// [context 2] The preceding declaration is here.
augment void f(int a, int b) {}
//                 ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'a' must either match the name 'x' from a preceding declaration or be '_'.
//                        ^
// [diag.augmentationPositionalFormalParameterName][context 2] The parameter name 'b' must either match the name 'y' from a preceding declaration or be '_'.
''');
  }

  test_topLevelFunction_rP_rp__x_y__x_z() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x, [int? y]);
//                  ^
// [context 1] The preceding declaration is here.
augment void f(int x, [int? z]) {}
//                          ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'z' must either match the name 'y' from a preceding declaration or be '_'.
''');
  }

  test_topLevelSetter_rP__wildcard__x__y() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _);
augment set foo(int x);
//                  ^
// [context 1] The preceding declaration is here.
augment set foo(int y) {}
//                  ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'y' must either match the name 'x' from a preceding declaration or be '_'.
''');
  }

  test_topLevelSetter_rP__x__wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int x);
augment set foo(int _) {}
''');
  }

  test_topLevelSetter_rP__x__y() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int x);
//          ^
// [context 1] The preceding declaration is here.
augment set foo(int y) {}
//                  ^
// [diag.augmentationPositionalFormalParameterName][context 1] The parameter name 'y' must either match the name 'x' from a preceding declaration or be '_'.
''');
  }
}

@reflectiveTest
class AugmentationFormalParameterScopeTest extends PubPackageResolutionTest {
  test_class_constructor_rP1__rPw_body() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
  augment A(int _) {
    p1;
//  ^^
// [diag.undefinedIdentifier] Undefined name 'p1'.
  }
}
''');
  }

  test_class_constructor_rP1__rPw_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int value;
  A(int p1);
  augment A(int _) : value = p1;
//                           ^^
// [diag.undefinedIdentifier] Undefined name 'p1'.
}
''');
  }

  test_class_constructor_rP1_rP2__rP1_constructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int value;
  A(int? p1, int? p2);
//^
// [context 1] The declaration being augmented.
  augment A(int? p1) : value = p2;
//                 ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
//                             ^^
// [diag.undefinedIdentifier] Undefined name 'p2'.
}
''');
  }

  test_class_instanceMethod_rP1__rPw_body() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void f(int p1);
  augment void f(int _) {
    p1;
//  ^^
// [diag.undefinedIdentifier] Undefined name 'p1'.
  }
}
''');
  }

  test_class_primaryConstructor_rP1__rPw_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int p1);
augment class A(int _) {
  final int value = p1;
//                  ^^
// [diag.undefinedIdentifier] Undefined name 'p1'.
}
''');
  }

  test_topLevelFunction_rP1__rPw_body() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x);
augment void f(int _) {
  x;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');
  }

  test_topLevelFunction_rPw__rP1_body() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int _);
augment void f(int x) {
  x;
}
''');
  }
}

@reflectiveTest
class AugmentationFormalParameterShapeTest extends PubPackageResolutionTest {
  test_class_constructor_factory_rP1__rP1_rP2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A._();
  factory A(int? p1);
//        ^
// [context 1] The declaration being augmented.
  augment factory A(int? p1, int? p2) => A._();
//                                ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 2 required positional formal parameters, but the declaration has 1.
}
''');
  }

  test_class_constructor_rN1__rN1_rN2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
//^
// [context 1] The declaration being augmented.
  augment A({required int n1, required int n2}) {}
//                                         ^^
// [diag.augmentationNamedFormalParameterExtra][context 1] The augmentation has a named formal parameter 'n2', but the declaration doesn't.
}
''');
  }

  test_class_constructor_rn1__rn1_rn2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
//^
// [context 1] The declaration being augmented.
  augment A({int? n1, int? n2}) {}
//                         ^^
// [diag.augmentationNamedFormalParameterExtra][context 1] The augmentation has a named formal parameter 'n2', but the declaration doesn't.
}
''');
  }

  test_class_constructor_rn1_rn2__rn1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1, int? n2});
//                 ^^
// [context 1] The formal parameter is here.
  augment A({int? n1}) {}
//                   ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n2' from the declaration.
}
''');
  }

  test_class_constructor_rP1__rp1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? p1);
//^
// [context 1] The declaration being augmented.
  augment A([int? p1]) {}
//          ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 0 required positional formal parameters, but the declaration has 1.
}
''');
  }

  test_class_constructor_rp1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
//^
// [context 1] The declaration being augmented.
  augment A(int? p1) {}
//               ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 0.
}
''');
  }

  test_class_constructor_rP1__rP1_rP2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? p1);
//^
// [context 1] The declaration being augmented.
  augment A(int? p1, int? p2) {}
//                        ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 2 required positional formal parameters, but the declaration has 1.
}

void f() {
  A(0);
}
''');
  }

  test_class_constructor_rP1__rP1_rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? p1);
//^
// [context 1] The declaration being augmented.
  augment A(int? p1, [int? p2]) {}
//                   ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 1 optional positional formal parameters, but the declaration has 0.
}
''');
  }

  test_class_constructor_rP1_rn1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? p1, {int? n1});
//                 ^^
// [context 1] The formal parameter is here.
  augment A(int? p1) {}
//                 ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n1' from the declaration.
}
''');
  }

  test_class_constructor_rP1_rP2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? p1, int? p2);
//^
// [context 1] The declaration being augmented.
  augment A(int? p1) {}
//                 ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
}
''');
  }

  test_class_constructor_rP1_rp2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? p1, [int? p2]);
//^
// [context 1] The declaration being augmented.
  augment A(int? p1) {}
//                 ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 0 optional positional formal parameters, but the declaration has 1.
}
''');
  }

  test_class_constructor_rP1_rP2__rP1_rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? p1, int? p2);
//^
// [context 1] The declaration being augmented.
  augment A(int? p1, [int? p2]) {}
//                   ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
}
''');
  }

  test_class_instanceField_inducedSetter_rP1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
  augment void set foo(int p1);
}
''');
  }

  test_class_instanceMethod_rn1__rn1_rn2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo({int? n1});
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo({int? n1, int? n2}) {}
//                                ^^
// [diag.augmentationNamedFormalParameterExtra][context 1] The augmentation has a named formal parameter 'n2', but the declaration doesn't.
}
''');
  }

  test_class_instanceMethod_rn1_rn2__rn1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo({int? n1, int? n2});
//                        ^^
// [context 1] The formal parameter is here.
  augment void foo({int? n1}) {}
//                          ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n2' from the declaration.
}
''');
  }

  test_class_instanceMethod_rP1__rp1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int? p1);
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo([int? p1]) {}
//                 ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 0 required positional formal parameters, but the declaration has 1.
}
''');
  }

  test_class_instanceMethod_rp1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo([int? p1]);
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo(int? p1) {}
//                      ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 0.
}
''');
  }

  test_class_instanceMethod_rP1__rP1_rP2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int? p1);
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo(int? p1, int? p2) {}
//                               ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 2 required positional formal parameters, but the declaration has 1.
}

void f(A a) {
  a.foo(0);
}
''');
  }

  test_class_instanceMethod_rP1__rP1_rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int? p1);
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo(int? p1, [int? p2]) {}
//                          ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 1 optional positional formal parameters, but the declaration has 0.
}
''');
  }

  test_class_instanceMethod_rP1_rn1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int? p1, {int? n1});
//                        ^^
// [context 1] The formal parameter is here.
  augment void foo(int? p1) {}
//                        ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n1' from the declaration.
}
''');
  }

  test_class_instanceMethod_rP1_rP2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int? p1, int? p2);
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo(int? p1) {}
//                        ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
}
''');
  }

  test_class_instanceMethod_rP1_rp2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int? p1, [int? p2]);
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo(int? p1) {}
//                        ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 0 optional positional formal parameters, but the declaration has 1.
}
''');
  }

  test_class_instanceMethod_rP1_rP2__rP1_rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int? p1, int? p2);
//     ^^^
// [context 1] The declaration being augmented.
  augment void foo(int? p1, [int? p2]) {}
//                          ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
}
''');
  }

  test_class_instanceSetter_rP1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  set foo(int? p1);
  augment set foo(int? p1) {}
}
''');
  }

  test_class_staticMethod_rn1__rn1_rn2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo({int? n1});
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo({int? n1, int? n2}) {}
//                                       ^^
// [diag.augmentationNamedFormalParameterExtra][context 1] The augmentation has a named formal parameter 'n2', but the declaration doesn't.
}
''');
  }

  test_class_staticMethod_rn1_rn2__rn1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo({int? n1, int? n2});
//                               ^^
// [context 1] The formal parameter is here.
  augment static void foo({int? n1}) {}
//                                 ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n2' from the declaration.
}
''');
  }

  test_class_staticMethod_rP1__rp1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int? p1);
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo([int? p1]) {}
//                        ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 0 required positional formal parameters, but the declaration has 1.
}
''');
  }

  test_class_staticMethod_rp1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo([int? p1]);
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo(int? p1) {}
//                             ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 0.
}
''');
  }

  test_class_staticMethod_rP1__rP1_rP2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int? p1);
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo(int? p1, int? p2) {}
//                                      ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 2 required positional formal parameters, but the declaration has 1.
}

void f() {
  A.foo(0);
}
''');
  }

  test_class_staticMethod_rP1__rP1_rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int? p1);
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo(int? p1, [int? p2]) {}
//                                 ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 1 optional positional formal parameters, but the declaration has 0.
}
''');
  }

  test_class_staticMethod_rP1_rn1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int? p1, {int? n1});
//                               ^^
// [context 1] The formal parameter is here.
  augment static void foo(int? p1) {}
//                               ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n1' from the declaration.
}
''');
  }

  test_class_staticMethod_rP1_rP2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int? p1, int? p2);
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo(int? p1) {}
//                               ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
}
''');
  }

  test_class_staticMethod_rP1_rp2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int? p1, [int? p2]);
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo(int? p1) {}
//                               ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 0 optional positional formal parameters, but the declaration has 1.
}
''');
  }

  test_class_staticMethod_rP1_rP2__rP1_rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int? p1, int? p2);
//            ^^^
// [context 1] The declaration being augmented.
  augment static void foo(int? p1, [int? p2]) {}
//                                 ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
}
''');
  }

  test_topLevelFunction_rn1__none() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1});
//           ^^
// [context 1] The formal parameter is here.
augment void f() {}
//             ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n1' from the declaration.
''');
  }

  test_topLevelFunction_rn1__none__rn1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1});
//           ^^
// [context 1] The formal parameter is here.
augment void f();
//             ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n1' from the declaration.
augment void f({int? n1}) {}
''');
  }

  test_topLevelFunction_rn1__rn1_rn2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1});
//   ^
// [context 1] The declaration being augmented.
augment void f({int? n1, int? n2}) {}
//                            ^^
// [diag.augmentationNamedFormalParameterExtra][context 1] The augmentation has a named formal parameter 'n2', but the declaration doesn't.
''');
  }

  test_topLevelFunction_rn1__rn1_rn2__rn1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1});
//   ^
// [context 1] The declaration being augmented.
augment void f({int? n1, int? n2});
//                            ^^
// [diag.augmentationNamedFormalParameterExtra][context 1] The augmentation has a named formal parameter 'n2', but the declaration doesn't.
augment void f({int? n1}) {}
''');
  }

  test_topLevelFunction_rn1_rn2__rn1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1, int? n2});
//                    ^^
// [context 1] The formal parameter is here.
augment void f({int? n1}) {}
//                      ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n2' from the declaration.
''');
  }

  test_topLevelFunction_rn1_rn2__rn2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1, int? n2});
//           ^^
// [context 1] The formal parameter is here.
augment void f({int? n2}) {}
//                      ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n1' from the declaration.
''');
  }

  test_topLevelFunction_rn1_rn2_rn3__rn1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1, int? n2, int? n3});
//                    ^^
// [context 1] The formal parameter is here.
//                             ^^
// [context 2] The formal parameter is here.
augment void f({int? n1}) {}
//                      ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n2' from the declaration.
// [diag.augmentationNamedFormalParameterMissing][context 2] The augmentation is missing the named formal parameter 'n3' from the declaration.
''');
  }

  test_topLevelFunction_rn1_rn2_rn3__rn1_rn3() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1, int? n2, int? n3});
//                    ^^
// [context 1] The formal parameter is here.
augment void f({int? n1, int? n3}) {}
//                               ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n2' from the declaration.
''');
  }

  test_topLevelFunction_rP1__rp1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1);
//   ^
// [context 1] The declaration being augmented.
augment void f([int? p1]) {}
//             ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 0 required positional formal parameters, but the declaration has 1.
''');
  }

  test_topLevelFunction_rp1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([int? p1]);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1) {}
//                  ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 0.
''');
  }

  test_topLevelFunction_rP1__rP1_rP2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1, int? p2) {}
//                           ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 2 required positional formal parameters, but the declaration has 1.

void g() {
  f(0);
}
''');
  }

  test_topLevelFunction_rP1__rP1_rP2_rP3() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1, int? p2, int? p3) {}
//                           ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 3 required positional formal parameters, but the declaration has 1.
''');
  }

  test_topLevelFunction_rP1__rP1_rp2_rp3() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1, [int? p2, int? p3]) {}
//                      ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 2 optional positional formal parameters, but the declaration has 0.
''');
  }

  test_topLevelFunction_rP1__rP2_rP3_nameMismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1);
//   ^
// [context 1] The declaration being augmented.
augment void f(int p2, int p3) {}
//                         ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 2 required positional formal parameters, but the declaration has 1.
''');
  }

  test_topLevelFunction_rP1_rn1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1, {int? n1});
//                    ^^
// [context 1] The formal parameter is here.
augment void f(int? p1) {}
//                    ^
// [diag.augmentationNamedFormalParameterMissing][context 1] The augmentation is missing the named formal parameter 'n1' from the declaration.
''');
  }

  test_topLevelFunction_rP1_rP2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1, int? p2);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1) {}
//                    ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
''');
  }

  test_topLevelFunction_rP1_rp2__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1, [int? p2]);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1) {}
//                    ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 0 optional positional formal parameters, but the declaration has 1.
''');
  }

  test_topLevelFunction_rP1_rP2__rP1_rp2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1, int? p2);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1, [int? p2]) {}
//                      ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 1 required positional formal parameters, but the declaration has 2.
''');
  }

  test_topLevelFunction_rP1_rp2__rP1_rP2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? p1, [int? p2]);
//   ^
// [context 1] The declaration being augmented.
augment void f(int? p1, int? p2) {}
//                           ^^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 2 required positional formal parameters, but the declaration has 1.
''');
  }

  test_topLevelSetter_rP1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int? p1);
augment set foo(int? p1) {}
''');
  }

  test_topLevelVariable_inducedSetter_rP1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
int foo = 0;
augment void set foo(int p1);
''');
  }
}

@reflectiveTest
class AugmentationFormalParameterTypeTest extends PubPackageResolutionTest {
  test_class_constructor_rn1__fn1_omittedIntroductoryType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int? n1;
  A({n1});
  augment A({this.n1});
//           ^^^^^^^
// [diag.fieldInitializingFormalNotAssignable] The parameter type 'dynamic' is incompatible with the field type 'int?'.
}
''');
  }

  test_class_constructor_rN1__sN1_omittedIntroductoryType() async {
    // TODO(fshcheglov): `implicitSuperInitializerMissingArguments` should not
    // be reported because the augmentation provides the required super formal
    // parameter.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B extends A {
  B({required n1});
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
  augment B({required super.n1});
//                          ^^
// [diag.superFormalParameterTypeIsNotSubtypeOfAssociated] The type 'dynamic' of this parameter isn't a subtype of the type 'int' of the associated super constructor parameter.
}
''');
  }

  test_class_constructor_rn1__sn1_omittedIntroductoryType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B extends A {
  B({n1});
  augment B({super.n1});
//                 ^^
// [diag.superFormalParameterTypeIsNotSubtypeOfAssociated] The type 'dynamic' of this parameter isn't a subtype of the type 'int?' of the associated super constructor parameter.
}
''');
  }

  test_class_constructor_rP1__fP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int p1;
  A(int p1);
  augment A(int this.p1);
}
''');
  }

  test_class_constructor_rP1__fP1_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int p1;
  A(int p1);
//      ^^
// [context 1] The formal parameter is here.
  augment A(String this.p1);
//          ^^^^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'String' must be the same as the declaration's formal parameter type 'int'.
}
''');
  }

  test_class_constructor_rP1__fP1_omittedIntroductoryType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int p1;
  A(p1);
  augment A(this.p1);
//          ^^^^^^^
// [diag.fieldInitializingFormalNotAssignable] The parameter type 'dynamic' is incompatible with the field type 'int'.

}
''');
  }

  test_class_constructor_rP1__fP1_omittedType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int p1;
  A(int p1);
  augment A(this.p1);
}
''');
  }

  test_class_constructor_rp1__sp1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B([int? p1]);
  augment B([int? super.p1]);
}
''');
  }

  test_class_constructor_rp1__sp1_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B([int? p1]);
//        ^^
// [context 1] The formal parameter is here.
  augment B([String? super.p1]);
//           ^^^^^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'String?' must be the same as the declaration's formal parameter type 'int?'.
}
''');
  }

  test_class_constructor_rP1__sP1_omittedIntroductoryType() async {
    // TODO(fshcheglov): `implicitSuperInitializerMissingArguments` should not
    // be reported because the augmentation provides the required super formal
    // parameter.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B(p1);
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
  augment B(super.p1);
//                ^^
// [diag.superFormalParameterTypeIsNotSubtypeOfAssociated] The type 'dynamic' of this parameter isn't a subtype of the type 'int' of the associated super constructor parameter.
}
''');
  }

  test_class_constructor_rp1__sp1_omittedIntroductoryType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B([p1]);
  augment B([super.p1]);
//                 ^^
// [diag.superFormalParameterTypeIsNotSubtypeOfAssociated] The type 'dynamic' of this parameter isn't a subtype of the type 'int?' of the associated super constructor parameter.
}
''');
  }

  test_class_constructor_rp1__sp1_omittedType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B([int? p1]);
  augment B([super.p1]);
}
''');
  }

  test_topLevelFunction_rN1__rN1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int Function(int) n1});
augment void f({required int Function(int) n1}) {}
''');
  }

  test_topLevelFunction_rn1__rn1_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1});
//           ^^
// [context 1] The formal parameter is here.
augment void f({String? n1}) {}
//              ^^^^^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'String?' must be the same as the declaration's formal parameter type 'int?'.
''');
  }

  test_topLevelFunction_rn1__rn1_omittedType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? n1});
augment void f({n1}) {}
''');
  }

  test_topLevelFunction_rN1__rN1ft() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int Function(int) n1});
augment void f({required int n1(int a)}) {}
''');
  }

  test_topLevelFunction_rN1__rN1ft_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int n1});
//                   ^^
// [context 1] The formal parameter is here.
augment void f({required int n1(int a)}) {}
//                       ^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'int Function(int)' must be the same as the declaration's formal parameter type 'int'.
''');
  }

  test_topLevelFunction_rN1ft__rN1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int n1(int a)});
augment void f({required int Function(int) n1}) {}
''');
  }

  test_topLevelFunction_rN1ft__rN1_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int n1(int a)});
//                   ^^
// [context 1] The formal parameter is here.
augment void f({required int n1}) {}
//                       ^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'int' must be the same as the declaration's formal parameter type 'int Function(int)'.
''');
  }

  test_topLevelFunction_rN1ft__rN1ft() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int n1(int a)});
augment void f({required int n1(int a)}) {}
''');
  }

  test_topLevelFunction_rP1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int Function(int) p1);
augment void f(int Function(int) p1) {}
''');
  }

  test_topLevelFunction_rP1__rP1_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1);
//         ^^
// [context 1] The formal parameter is here.
augment void f(String p1) {}
//             ^^^^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'String' must be the same as the declaration's formal parameter type 'int'.
''');
  }

  test_topLevelFunction_rP1__rP1_dynamic_objectQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(dynamic p1);
//             ^^
// [context 1] The formal parameter is here.
augment void f(Object? p1) {}
//             ^^^^^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'Object?' must be the same as the declaration's formal parameter type 'dynamic'.
''');
  }

  test_topLevelFunction_rP1__rP1_objectQuestion_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? p1);
//             ^^
// [context 1] The formal parameter is here.
augment void f(dynamic p1) {}
//             ^^^^^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'dynamic' must be the same as the declaration's formal parameter type 'Object?'.
''');
  }

  test_topLevelFunction_rP1__rP1_omittedType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1);
augment void f(p1) {}
''');
  }

  test_topLevelFunction_rP1__rP1ft() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int Function(int) p1);
augment void f(int p1(int a)) {}
''');
  }

  test_topLevelFunction_rP1__rP1ft_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1);
//         ^^
// [context 1] The formal parameter is here.
augment void f(int p1(int a)) {}
//             ^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'int Function(int)' must be the same as the declaration's formal parameter type 'int'.
''');
  }

  test_topLevelFunction_rP1ft__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1(int a));
augment void f(int Function(int) p1) {}
''');
  }

  test_topLevelFunction_rP1ft__rP1_differentType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1(int a));
//         ^^
// [context 1] The formal parameter is here.
augment void f(int p1) {}
//             ^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'int' must be the same as the declaration's formal parameter type 'int Function(int)'.
''');
  }

  test_topLevelFunction_rP1ft__rP1ft() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1(int a));
augment void f(int p1(int a)) {}
''');
  }

  test_topLevelFunction_rP1ft__rP1ft_differentParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1(int a));
//         ^^
// [context 1] The formal parameter is here.
augment void f(int p1(String a)) {}
//             ^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'int Function(String)' must be the same as the declaration's formal parameter type 'int Function(int)'.
''');
  }

  test_topLevelFunction_rP1ft__rP1ft_differentReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1(int a));
//         ^^
// [context 1] The formal parameter is here.
augment void f(String p1(int a)) {}
//             ^^^^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'String Function(int)' must be the same as the declaration's formal parameter type 'int Function(int)'.
''');
  }

  test_topLevelFunction_rP1ftt__rP1ftt() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1<T>(T a));
augment void f(int p1<T>(T a)) {}
''');
  }

  test_topLevelFunction_rP1ftt__rP1ftt_differentParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int p1<T>(T a));
//         ^^
// [context 1] The formal parameter is here.
augment void f(int p1<T>(String a)) {}
//             ^^^
// [diag.augmentationFormalParameterTypeMismatch][context 1] The augmentation's formal parameter type 'int Function<T>(String)' must be the same as the declaration's formal parameter type 'int Function<T>(T)'.
''');
  }
}
