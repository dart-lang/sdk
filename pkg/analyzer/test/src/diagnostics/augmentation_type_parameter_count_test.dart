// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterCountTest);
  });
}

@reflectiveTest
class AugmentationTypeParameterCountTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_0_1() async {
    await assertErrorsInCode(
      r'''
class A {}
augment class A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 26, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_1_0() async {
    await assertErrorsInCode(
      r'''
class A<T> {}
augment class A {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 29, 1)],
    );
  }

  test_class_1_1() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
augment class A<T> {}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_1_2() async {
    await assertErrorsInCode(
      r'''
class A<T> {}
augment class A<T, U> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 29, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_2_1() async {
    await assertErrorsInCode(
      r'''
class A<T, U> {}
augment class A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 32, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_enum_0_1() async {
    await assertErrorsInCode(
      r'''
enum A {v}
augment enum A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 25, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_enum_1_0() async {
    await assertErrorsInCode(
      r'''
enum A<T> {v}
augment enum A {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 28, 1)],
    );
  }

  test_enum_1_1() async {
    await assertNoErrorsInCode(r'''
enum A<T> {v}
augment enum A <T>{}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_enum_1_2() async {
    await assertErrorsInCode(
      r'''
enum A<T> {v}
augment enum A<T, U> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 28, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_enum_2_1() async {
    await assertErrorsInCode(
      r'''
enum A<T, U> {v}
augment enum A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 31, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extension_0_1() async {
    await assertErrorsInCode(
      r'''
extension A on int {}
augment extension A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 41, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extension_1_0() async {
    await assertErrorsInCode(
      r'''
extension A<T> on int {}
augment extension A {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 44, 1)],
    );
  }

  test_extension_1_1() async {
    await assertNoErrorsInCode(r'''
extension A<T> on int {}
augment extension A<T> {}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extension_1_2() async {
    await assertErrorsInCode(
      r'''
extension A<T> on int {}
augment extension A<T, U> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 44, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extension_2_1() async {
    await assertErrorsInCode(
      r'''
extension A<T, U> on int {}
augment extension A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 47, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extensionType_0_1() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}
augment extension type A<T>(int it) {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 52, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extensionType_1_0() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}
augment extension type A(int it) {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 55, 1)],
    );
  }

  test_extensionType_1_1() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extensionType_1_2() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 55, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extensionType_2_1() async {
    await assertErrorsInCode(
      r'''
extension type A<T, U>(int it) {}
augment extension type A<T>(int it) {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 58, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_0_1() async {
    await assertErrorsInCode(
      r'''
mixin A {}
augment mixin A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 26, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_1_0() async {
    await assertErrorsInCode(
      r'''
mixin A<T> {}
augment mixin A {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 29, 1)],
    );
  }

  test_mixin_1_1() async {
    await assertNoErrorsInCode(r'''
mixin A<T> {}
augment mixin A<T> {}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_1_2() async {
    await assertErrorsInCode(
      r'''
mixin A<T> {}
augment mixin A<T, U> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 29, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_2_1() async {
    await assertErrorsInCode(
      r'''
mixin A<T, U> {}
augment mixin A<T> {}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 32, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_method() async {
    await assertErrorsInCode(
      r'''
mixin A {
  void foo() {}
}
augment mixin A<T> {
  augment void foo() {}
}
''',
      [error(CompileTimeErrorCode.augmentationTypeParameterCount, 43, 1)],
    );
  }
}
