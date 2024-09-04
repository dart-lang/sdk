// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationModifierExtraTest);
  });
}

@reflectiveTest
class AugmentationModifierExtraTest extends PubPackageResolutionTest {
  test_class_abstract() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment abstract class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 8),
    ]);
  }

  test_class_abstract_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment abstract base class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 8),
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 36, 4),
    ]);
  }

  test_class_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment base class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 4),
    ]);
  }

  test_class_final() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment final class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 5),
    ]);
  }

  test_class_interface() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment interface class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 9),
    ]);
  }

  test_class_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment mixin class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 5),
    ]);
  }

  test_class_sealed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment sealed class A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 6),
    ]);
  }

  test_mixin_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

mixin A {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';

augment base mixin A {}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, 27, 4),
    ]);
  }
}
