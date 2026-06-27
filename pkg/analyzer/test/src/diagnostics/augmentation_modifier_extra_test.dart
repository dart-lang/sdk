// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationModifierExtraTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationModifierExtraTest extends PubPackageResolutionTest {
  test_class_abstract_abstractBase() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {}
augment abstract base class A {}
//               ^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'base' modifier that the declaration doesn't have.
''');
  }

  test_class_abstractBase_abstractBase() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract base class A {}
augment abstract base class A {}
''');
  }

  test_class_base_abstractBase() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
augment abstract base class A {}
//      ^^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'abstract' modifier that the declaration doesn't have.
''');
  }

  test_class_constructor_secondary_nothing_const() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
  augment const A();
//        ^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'const' modifier that the declaration doesn't have.
}
''');
  }

  test_class_constructor_secondary_nothing_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
  augment factory A();
//        ^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'factory' modifier that the declaration doesn't have.
}
''');
  }

  test_class_nothing_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment abstract class A {}
//      ^^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'abstract' modifier that the declaration doesn't have.
''');
  }

  test_class_nothing_abstractBase() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment abstract base class A {}
//      ^^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'abstract' modifier that the declaration doesn't have.
//               ^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'base' modifier that the declaration doesn't have.
''');
  }

  test_class_nothing_base() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment base class A {}
//      ^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'base' modifier that the declaration doesn't have.
''');
  }

  test_class_nothing_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment final class A {}
//      ^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'final' modifier that the declaration doesn't have.
''');
  }

  test_class_nothing_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment interface class A {}
//      ^^^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'interface' modifier that the declaration doesn't have.
''');
  }

  test_class_nothing_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment mixin class A {}
//      ^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'mixin' modifier that the declaration doesn't have.
''');
  }

  test_class_nothing_nothing_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A {}
augment abstract class A {}
//      ^^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'abstract' modifier that the declaration doesn't have.
''');
  }

  test_class_nothing_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment sealed class A {}
//      ^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'sealed' modifier that the declaration doesn't have.
''');
  }

  test_enum_constructor_primary_const_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E.named() {
  v.named();
}

augment enum E {
  ;
  augment factory E.named();
//^^^^^^^
// [diag.augmentationModifierMissing] The augmentation is missing the 'const' modifier that the declaration has.
//        ^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'factory' modifier that the declaration doesn't have.
}
''');
  }

  test_extensionType_constructor_primary_nothing_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it);

augment extension type E {
  augment factory E(int it);
//        ^^^^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'factory' modifier that the declaration doesn't have.
}
''');
  }

  test_mixin_base_base() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin A {}
augment base mixin A {}
''');
  }

  test_mixin_nothing_base() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
augment base mixin A {}
//      ^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'base' modifier that the declaration doesn't have.
''');
  }

  test_mixin_nothing_nothing_base() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
augment mixin A {}
augment base mixin A {}
//      ^^^^
// [diag.augmentationModifierExtra] The augmentation has the 'base' modifier that the declaration doesn't have.
''');
  }
}
