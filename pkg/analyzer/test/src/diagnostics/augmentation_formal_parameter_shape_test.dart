// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationFormalParameterShapeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationFormalParameterShapeTest extends PubPackageResolutionTest {
  test_class_constructor_rP1__rP1_rP2() async {
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

  test_class_instanceField_inducedSetter_rP1__rP1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
  augment void set foo(int p1);
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
