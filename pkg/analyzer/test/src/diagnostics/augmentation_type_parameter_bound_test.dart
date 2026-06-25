// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterBoundTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationTypeParameterBoundTest extends PubPackageResolutionTest {
  test_class_dynamic_objectQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends dynamic> {}
augment class A<T extends Object?> {}
//                        ^^^^^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_class_method_nothing_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo<T>() {}
  augment void foo<T extends num>();
//                           ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
}
''');
  }

  test_class_method_num_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo<T extends num>() {}
  augment void foo<T extends int>();
//                           ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
}
''');
  }

  test_class_method_num_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo<T extends num>() {}
  augment void foo<T>();
}
''');
  }

  test_class_nothing_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
augment class A<T extends num> {}
//                        ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_class_num_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {}
augment class A<T extends int> {}
//                        ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_class_num_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {}
augment class A<T> {}
''');
  }

  test_class_num_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {}
augment class A<T extends num> {}
''');
  }

  test_class_num_num_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef N = num;

class A<T extends num> {}
augment class A<T extends N> {}
''');
  }

  test_class_num_num_withImportPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core';
import 'dart:core' as core;

class A<T extends num> {}
augment class A<T extends core.num> {}
''');
  }

  test_class_num_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {}
augment class A<T extends Object> {}
//                        ^^^^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_class_objectQuestion_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends Object?> {}
augment class A<T extends dynamic> {}
//                        ^^^^^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_enum_nothing_num() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T> {v}
augment enum A<T extends num> {}
//                       ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_enum_num_int() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T extends num> {v}
augment enum A<T extends int> {}
//                       ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_enum_num_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T extends num> {v}
augment enum A<T> {}
''');
  }

  test_enum_num_num() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T extends num> {v}
augment enum A<T extends num> {}
''');
  }

  test_extension_nothing_num() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T> on int {}
augment extension A<T extends num> {}
//                            ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_extension_num_int() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T extends num> on int {}
augment extension A<T extends int> {}
//                            ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_extension_num_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T extends num> on int {}
augment extension A<T> {}
''');
  }

  test_extension_num_num() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T extends num> on int {}
augment extension A<T extends num> {}
''');
  }

  test_extensionType_nothing_num() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {}
augment extension type A<T extends num> {}
//                                 ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_extensionType_num_int() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T extends num>(int it) {}
augment extension type A<T extends int> {}
//                                 ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_extensionType_num_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T extends num>(int it) {}
augment extension type A<T> {}
''');
  }

  test_extensionType_num_num() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T extends num>(int it) {}
augment extension type A<T extends num> {}
''');
  }

  test_mixin_nothing_num() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<T> {}
augment mixin A<T extends num> {}
//                        ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_mixin_num_int() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<T extends num> {}
augment mixin A<T extends int> {}
//                        ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_mixin_num_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<T extends num> {}
augment mixin A<T> {}
''');
  }

  test_mixin_num_num() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<T extends num> {}
augment mixin A<T extends num> {}
''');
  }

  test_topLevelFunction_nothing_num() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo<T>() {}
augment void foo<T extends num>();
//                         ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_topLevelFunction_num_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo<T extends num>() {}
augment void foo<T extends int>();
//                         ^^^
// [diag.augmentationTypeParameterBound] The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
''');
  }

  test_topLevelFunction_num_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo<T extends num>() {}
augment void foo<T>();
''');
  }

  test_topLevelFunction_num_num_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef N = num;

void foo<T extends num>() {}
augment void foo<T extends N>();
''');
  }

  test_topLevelFunction_num_num_withImportPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core';
import 'dart:core' as core;

void foo<T extends num>() {}
augment void foo<T extends core.num>();
''');
  }
}
