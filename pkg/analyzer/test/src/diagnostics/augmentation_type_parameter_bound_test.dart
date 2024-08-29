// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterBoundTest);
  });
}

@reflectiveTest
class AugmentationTypeParameterBoundTest extends PubPackageResolutionTest {
  test_class_nothing_num() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A<T> {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A<T extends num> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND, 45, 3),
    ]);
  }

  test_class_num_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A<T extends num> {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A<T> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND, 35, 1),
    ]);
  }

  test_class_num_num() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A<T extends num> {}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment class A<T extends num> {}
''');
  }

  test_class_num_Object() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A<T extends num> {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A<T extends Object> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND, 45, 6),
    ]);
  }

  test_enum_nothing_num() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum A<T> {v}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment enum A<T extends num> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND, 44, 3),
    ]);
  }

  test_extension_nothing_num() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

extension A<T> on int {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment extension A<T extends num> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND, 49, 3),
    ]);
  }

  test_extensionType_nothing_num() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

extension type A<T>(int it) {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment extension type A<T extends num>(int it) {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND, 54, 3),
    ]);
  }

  test_mixin_nothing_num() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

mixin A<T> {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment mixin A<T extends num> {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND, 45, 3),
    ]);
  }
}
