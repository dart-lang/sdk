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
  test_class_0_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 42, 1),
    ]);
  }

  test_class_1_0() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A<T> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 41, 1),
    ]);
  }

  test_class_1_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A<T> {}
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';

augment class A<T> {}
''');
  }

  test_class_1_2() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A<T> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A<T, U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 46, 1),
    ]);
  }

  test_class_2_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A<T, U> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 44, 1),
    ]);
  }

  test_enum_0_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

enum A {v}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment enum A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 41, 1),
    ]);
  }

  test_enum_1_0() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

enum A<T> {v}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment enum A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 40, 1),
    ]);
  }

  test_enum_1_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

enum A<T> {v}
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';

augment enum A <T>{}
''');
  }

  test_enum_1_2() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

enum A<T> {v}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment enum A<T, U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 45, 1),
    ]);
  }

  test_enum_2_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

enum A<T, U> {v}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment enum A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 43, 1),
    ]);
  }

  test_extension_0_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension A on int {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 46, 1),
    ]);
  }

  test_extension_1_0() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension A<T> on int {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 45, 1),
    ]);
  }

  test_extension_1_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension A<T> on int {}
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';

augment extension A<T> {}
''');
  }

  test_extension_1_2() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension A<T> on int {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension A<T, U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 50, 1),
    ]);
  }

  test_extension_2_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension A<T, U> on int {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 48, 1),
    ]);
  }

  test_extensionType_0_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension type A(int it) {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension type A<T>(int it) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 51, 1),
    ]);
  }

  test_extensionType_1_0() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension type A<T>(int it) {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension type A(int it) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 50, 1),
    ]);
  }

  test_extensionType_1_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension type A<T>(int it) {}
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';

augment extension type A<T>(int it) {}
''');
  }

  test_extensionType_1_2() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension type A<T>(int it) {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension type A<T, U>(int it) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 55, 1),
    ]);
  }

  test_extensionType_2_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension type A<T, U>(int it) {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension type A<T>(int it) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 53, 1),
    ]);
  }

  test_mixin_0_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

mixin A {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment mixin A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 42, 1),
    ]);
  }

  test_mixin_1_0() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

mixin A<T> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment mixin A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 41, 1),
    ]);
  }

  test_mixin_1_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

mixin A<T> {}
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';

augment mixin A<T> {}
''');
  }

  test_mixin_1_2() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

mixin A<T> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment mixin A<T, U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 46, 1),
    ]);
  }

  test_mixin_2_1() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

mixin A<T, U> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment mixin A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT, 44, 1),
    ]);
  }
}
