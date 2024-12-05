// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationModifierMissingTest);
  });
}

@reflectiveTest
class AugmentationModifierMissingTest extends PubPackageResolutionTest {
  test_class_abstract() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

abstract class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }

  test_class_abstract_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

abstract base class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }

  test_class_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

base class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }

  test_class_final() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

final class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }

  test_class_interface() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

interface class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }

  test_class_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

mixin class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }

  test_class_sealed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

sealed class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }

  test_mixin_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

base mixin A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment mixin A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING, 19, 7),
    ]);
  }
}
