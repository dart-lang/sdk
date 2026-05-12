// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterBoundTest);
  });
}

@reflectiveTest
class AugmentationTypeParameterBoundTest extends PubPackageResolutionTest {
  test_class_method_nothing_num() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo<T>() {}
  augment void foo<T extends num>();
}
''',
      [error(diag.augmentationTypeParameterBound, 58, 3)],
    );
  }

  test_class_method_num_int() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo<T extends num>() {}
  augment void foo<T extends int>();
}
''',
      [error(diag.augmentationTypeParameterBound, 70, 3)],
    );
  }

  test_class_method_num_nothing() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo<T extends num>() {}
  augment void foo<T>();
}
''');
  }

  test_class_nothing_num() async {
    await assertErrorsInCode(
      r'''
class A<T> {}
augment class A<T extends num> {}
''',
      [error(diag.augmentationTypeParameterBound, 40, 3)],
    );
  }

  test_class_num_int() async {
    await assertErrorsInCode(
      r'''
class A<T extends num> {}
augment class A<T extends int> {}
''',
      [error(diag.augmentationTypeParameterBound, 52, 3)],
    );
  }

  test_class_num_nothing() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {}
augment class A<T> {}
''');
  }

  test_class_num_num() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {}
augment class A<T extends num> {}
''');
  }

  test_class_num_num_viaTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef N = num;

class A<T extends num> {}
augment class A<T extends N> {}
''');
  }

  test_class_num_num_withImportPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';
import 'dart:core' as core;

class A<T extends num> {}
augment class A<T extends core.num> {}
''');
  }

  test_class_num_Object() async {
    await assertErrorsInCode(
      r'''
class A<T extends num> {}
augment class A<T extends Object> {}
''',
      [error(diag.augmentationTypeParameterBound, 52, 6)],
    );
  }

  test_enum_nothing_num() async {
    await assertErrorsInCode(
      r'''
enum A<T> {v}
augment enum A<T extends num> {}
''',
      [error(diag.augmentationTypeParameterBound, 39, 3)],
    );
  }

  test_enum_num_int() async {
    await assertErrorsInCode(
      r'''
enum A<T extends num> {v}
augment enum A<T extends int> {}
''',
      [error(diag.augmentationTypeParameterBound, 51, 3)],
    );
  }

  test_enum_num_nothing() async {
    await assertNoErrorsInCode(r'''
enum A<T extends num> {v}
augment enum A<T> {}
''');
  }

  test_enum_num_num() async {
    await assertNoErrorsInCode(r'''
enum A<T extends num> {v}
augment enum A<T extends num> {}
''');
  }

  test_extension_nothing_num() async {
    await assertErrorsInCode(
      r'''
extension A<T> on int {}
augment extension A<T extends num> {}
''',
      [error(diag.augmentationTypeParameterBound, 55, 3)],
    );
  }

  test_extension_num_int() async {
    await assertErrorsInCode(
      r'''
extension A<T extends num> on int {}
augment extension A<T extends int> {}
''',
      [error(diag.augmentationTypeParameterBound, 67, 3)],
    );
  }

  test_extension_num_nothing() async {
    await assertNoErrorsInCode(r'''
extension A<T extends num> on int {}
augment extension A<T> {}
''');
  }

  test_extension_num_num() async {
    await assertNoErrorsInCode(r'''
extension A<T extends num> on int {}
augment extension A<T extends num> {}
''');
  }

  test_extensionType_nothing_num() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}
augment extension type A<T extends num>(int it) {}
''',
      [error(diag.augmentationTypeParameterBound, 66, 3)],
    );
  }

  test_extensionType_num_int() async {
    await assertErrorsInCode(
      r'''
extension type A<T extends num>(int it) {}
augment extension type A<T extends int>(int it) {}
''',
      [error(diag.augmentationTypeParameterBound, 78, 3)],
    );
  }

  test_extensionType_num_nothing() async {
    await assertNoErrorsInCode(r'''
extension type A<T extends num>(int it) {}
augment extension type A<T>(int it) {}
''');
  }

  test_extensionType_num_num() async {
    await assertNoErrorsInCode(r'''
extension type A<T extends num>(int it) {}
augment extension type A<T extends num>(int it) {}
''');
  }

  test_mixin_nothing_num() async {
    await assertErrorsInCode(
      r'''
mixin A<T> {}
augment mixin A<T extends num> {}
''',
      [error(diag.augmentationTypeParameterBound, 40, 3)],
    );
  }

  test_mixin_num_int() async {
    await assertErrorsInCode(
      r'''
mixin A<T extends num> {}
augment mixin A<T extends int> {}
''',
      [error(diag.augmentationTypeParameterBound, 52, 3)],
    );
  }

  test_mixin_num_nothing() async {
    await assertNoErrorsInCode(r'''
mixin A<T extends num> {}
augment mixin A<T> {}
''');
  }

  test_mixin_num_num() async {
    await assertNoErrorsInCode(r'''
mixin A<T extends num> {}
augment mixin A<T extends num> {}
''');
  }

  test_topLevelFunction_nothing_num() async {
    await assertErrorsInCode(
      r'''
void foo<T>() {}
augment void foo<T extends num>();
''',
      [error(diag.augmentationTypeParameterBound, 44, 3)],
    );
  }

  test_topLevelFunction_num_int() async {
    await assertErrorsInCode(
      r'''
void foo<T extends num>() {}
augment void foo<T extends int>();
''',
      [error(diag.augmentationTypeParameterBound, 56, 3)],
    );
  }

  test_topLevelFunction_num_nothing() async {
    await assertNoErrorsInCode(r'''
void foo<T extends num>() {}
augment void foo<T>();
''');
  }

  test_topLevelFunction_num_num_viaTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef N = num;

void foo<T extends num>() {}
augment void foo<T extends N>();
''');
  }

  test_topLevelFunction_num_num_withImportPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';
import 'dart:core' as core;

void foo<T extends num>() {}
augment void foo<T extends core.num>();
''');
  }
}
