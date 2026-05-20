// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationModifierExtraTest);
  });
}

@reflectiveTest
class AugmentationModifierExtraTest extends PubPackageResolutionTest {
  test_class_abstract_abstractBase() async {
    await assertErrorsInCode(
      r'''
abstract class A {}
augment abstract base class A {}
''',
      [error(diag.augmentationModifierExtra, 37, 4)],
    );
  }

  test_class_abstractBase_abstractBase() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract base class A {}
augment abstract base class A {}
''');
  }

  test_class_base_abstractBase() async {
    await assertErrorsInCode(
      r'''
base class A {}
augment abstract base class A {}
''',
      [error(diag.augmentationModifierExtra, 24, 8)],
    );
  }

  test_class_nothing_abstract() async {
    await assertErrorsInCode(
      r'''
class A {}
augment abstract class A {}
''',
      [error(diag.augmentationModifierExtra, 19, 8)],
    );
  }

  test_class_nothing_abstractBase() async {
    await assertErrorsInCode(
      r'''
class A {}
augment abstract base class A {}
''',
      [
        error(diag.augmentationModifierExtra, 19, 8),
        error(diag.augmentationModifierExtra, 28, 4),
      ],
    );
  }

  test_class_nothing_base() async {
    await assertErrorsInCode(
      r'''
class A {}
augment base class A {}
''',
      [error(diag.augmentationModifierExtra, 19, 4)],
    );
  }

  test_class_nothing_final() async {
    await assertErrorsInCode(
      r'''
class A {}
augment final class A {}
''',
      [error(diag.augmentationModifierExtra, 19, 5)],
    );
  }

  test_class_nothing_interface() async {
    await assertErrorsInCode(
      r'''
class A {}
augment interface class A {}
''',
      [error(diag.augmentationModifierExtra, 19, 9)],
    );
  }

  test_class_nothing_mixin() async {
    await assertErrorsInCode(
      r'''
class A {}
augment mixin class A {}
''',
      [error(diag.augmentationModifierExtra, 19, 5)],
    );
  }

  test_class_nothing_nothing_abstract() async {
    await assertErrorsInCode(
      r'''
class A {}
augment class A {}
augment abstract class A {}
''',
      [error(diag.augmentationModifierExtra, 38, 8)],
    );
  }

  test_class_nothing_sealed() async {
    await assertErrorsInCode(
      r'''
class A {}
augment sealed class A {}
''',
      [error(diag.augmentationModifierExtra, 19, 6)],
    );
  }

  test_mixin_base_base() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin A {}
augment base mixin A {}
''');
  }

  test_mixin_nothing_base() async {
    await assertErrorsInCode(
      r'''
mixin A {}
augment base mixin A {}
''',
      [error(diag.augmentationModifierExtra, 19, 4)],
    );
  }

  test_mixin_nothing_nothing_base() async {
    await assertErrorsInCode(
      r'''
mixin A {}
augment mixin A {}
augment base mixin A {}
''',
      [error(diag.augmentationModifierExtra, 38, 4)],
    );
  }
}
