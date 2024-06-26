// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterNameTest);
  });
}

@reflectiveTest
class AugmentationTypeParameterNameTest extends PubPackageResolutionTest {
  test_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A<T> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment class A<U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME, 43, 1),
    ]);
  }

  test_enum() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

enum A<T> {v}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment enum A<U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME, 42, 1),
    ]);
  }

  test_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension A<T> on int {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension A<U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME, 47, 1),
    ]);
  }

  test_extensionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension type A<T>(int it) {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment extension type A<U>(int it) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME, 52, 1),
    ]);
  }

  test_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

mixin A<T> {}
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';

augment mixin A<U> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME, 43, 1),
    ]);
  }
}
