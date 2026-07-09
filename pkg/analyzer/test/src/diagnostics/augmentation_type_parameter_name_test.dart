// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationTypeParameterNameTest extends PubPackageResolutionTest {
  test_class_method_T_U() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo<T>() {}
  augment void foo<U>();
//                 ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
}
''');
  }

  test_class_T_U() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
augment class A<U> {}
//              ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
''');
  }

  test_class_TU_UT() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {}
augment class A<U, T> {}
//              ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
//                 ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
''');
  }

  test_enum_T_U() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T> {v}
augment enum A<U> {}
//             ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
''');
  }

  test_extension_T_U() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T> on int {}
augment extension A<U> {}
//                  ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
''');
  }

  test_extensionType_T_U() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {}
augment extension type A<U> {}
//                       ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
''');
  }

  test_mixin_T_U() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<T> {}
augment mixin A<U> {}
//              ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
''');
  }

  test_topLevelFunction_T_U() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo<T>() {}
augment void foo<U>();
//               ^
// [diag.augmentationTypeParameterName] The augmentation type parameter must have the same name as the corresponding type parameter of the declaration.
''');
  }
}
