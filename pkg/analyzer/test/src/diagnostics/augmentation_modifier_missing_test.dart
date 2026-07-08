// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationModifierMissingTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationModifierMissingTest extends PubPackageResolutionTest {
  test_class_abstract_abstract_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {}
augment abstract class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'abstract' modifier that the declaration has.
''');
  }

  test_class_abstract_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'abstract' modifier that the declaration has.
''');
  }

  test_class_abstractBase_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract base class A {}
augment abstract class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'base' modifier that the declaration has.
''');
  }

  test_class_abstractBase_abstractBase() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract base class A {}
augment abstract base class A {}
''');
  }

  test_class_abstractBase_base() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract base class A {}
augment base class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'abstract' modifier that the declaration has.
''');
  }

  test_class_abstractBase_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract base class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'abstract' modifier that the declaration has.
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'base' modifier that the declaration has.
''');
  }

  test_class_base_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'base' modifier that the declaration has.
''');
  }

  test_class_constructor_secondary_const_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
  augment A();
//^^^^^^^
// [diag.augmentationModifierMissing] The augmentation is missing the 'const' modifier that the declaration has.
}
''');
  }

  test_class_constructor_secondary_factory_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A._();
  factory A() = A._;
  augment A();
//^^^^^^^
// [diag.augmentationModifierMissing] The augmentation is missing the 'factory' modifier that the declaration has.
}
''');
  }

  test_class_final_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'final' modifier that the declaration has.
''');
  }

  test_class_interface_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
interface class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'interface' modifier that the declaration has.
''');
  }

  test_class_mixin_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'mixin' modifier that the declaration has.
''');
  }

  test_class_sealed_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
augment class A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'sealed' modifier that the declaration has.
''');
  }

  test_enum_constructor_secondary_factory_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;

  factory E.named() => v;
}

augment enum E {
  ;
  augment E.named();
//^^^^^^^
// [diag.augmentationModifierMissing] The augmentation is missing the 'factory' modifier that the declaration has.
}
''');
  }

  test_extensionType_constructor_primary_const_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it);

augment extension type E {
  augment E(int it);
//^^^^^^^
// [diag.augmentationModifierMissing] The augmentation is missing the 'const' modifier that the declaration has.
}
''');
  }

  test_mixin_base_base() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin A {}
augment base mixin A {}
''');
  }

  test_mixin_base_base_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin A {}
augment base mixin A {}
augment mixin A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'base' modifier that the declaration has.
''');
  }

  test_mixin_base_nothing() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin A {}
augment mixin A {}
// [diag.augmentationModifierMissing][column 1][length 7] The augmentation is missing the 'base' modifier that the declaration has.
''');
  }
}
