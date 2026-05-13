// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationModifierMissingTest);
  });
}

@reflectiveTest
class AugmentationModifierMissingTest extends PubPackageResolutionTest {
  test_class_abstract_abstract_nothing() async {
    await assertErrorsInCode(
      r'''
abstract class A {}
augment abstract class A {}
augment class A {}
''',
      [error(diag.augmentationModifierMissing, 48, 7)],
    );
  }

  test_class_abstract_nothing() async {
    await assertErrorsInCode(
      r'''
abstract class A {}
augment class A {}
''',
      [error(diag.augmentationModifierMissing, 20, 7)],
    );
  }

  test_class_abstractBase_abstract() async {
    await assertErrorsInCode(
      r'''
abstract base class A {}
augment abstract class A {}
''',
      [error(diag.augmentationModifierMissing, 25, 7)],
    );
  }

  test_class_abstractBase_abstractBase() async {
    await assertNoErrorsInCode(r'''
abstract base class A {}
augment abstract base class A {}
''');
  }

  test_class_abstractBase_base() async {
    await assertErrorsInCode(
      r'''
abstract base class A {}
augment base class A {}
''',
      [error(diag.augmentationModifierMissing, 25, 7)],
    );
  }

  test_class_abstractBase_nothing() async {
    await assertErrorsInCode(
      r'''
abstract base class A {}
augment class A {}
''',
      [
        error(diag.augmentationModifierMissing, 25, 7),
        error(diag.augmentationModifierMissing, 25, 7),
      ],
    );
  }

  test_class_base_nothing() async {
    await assertErrorsInCode(
      r'''
base class A {}
augment class A {}
''',
      [error(diag.augmentationModifierMissing, 16, 7)],
    );
  }

  test_class_final_nothing() async {
    await assertErrorsInCode(
      r'''
final class A {}
augment class A {}
''',
      [error(diag.augmentationModifierMissing, 17, 7)],
    );
  }

  test_class_interface_nothing() async {
    await assertErrorsInCode(
      r'''
interface class A {}
augment class A {}
''',
      [error(diag.augmentationModifierMissing, 21, 7)],
    );
  }

  test_class_mixin_nothing() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
augment class A {}
''',
      [error(diag.augmentationModifierMissing, 17, 7)],
    );
  }

  test_class_sealed_nothing() async {
    await assertErrorsInCode(
      r'''
sealed class A {}
augment class A {}
''',
      [error(diag.augmentationModifierMissing, 18, 7)],
    );
  }

  test_mixin_base_base() async {
    await assertNoErrorsInCode(r'''
base mixin A {}
augment base mixin A {}
''');
  }

  test_mixin_base_base_nothing() async {
    await assertErrorsInCode(
      r'''
base mixin A {}
augment base mixin A {}
augment mixin A {}
''',
      [error(diag.augmentationModifierMissing, 40, 7)],
    );
  }

  test_mixin_base_nothing() async {
    await assertErrorsInCode(
      r'''
base mixin A {}
augment mixin A {}
''',
      [error(diag.augmentationModifierMissing, 16, 7)],
    );
  }
}
