// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentsConstantVariableTest);
    defineReflectiveTests(ConstantVariableAugmentationTest);
  });
}

@reflectiveTest
class AugmentsConstantVariableTest extends PubPackageResolutionTest {
  test_class_staticField_augmentedByField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const int foo = 0;
  augment static abstract final int foo;
//                                  ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
}
''');
  }

  test_class_staticField_augmentedByGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const int foo = 0;
  augment static int get foo;
//                       ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
}
''');
  }

  test_class_staticField_augmentedBySetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const int foo = 0;
  augment static void set foo(int _);
//                        ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
}
''');
  }

  test_enum_staticField_augmentedByGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static const int foo = 0;
  augment static int get foo;
//                       ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
}
''');
  }

  test_extension_staticField_augmentedByGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static const int foo = 0;
  augment static int get foo;
//                       ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
}
''');
  }

  test_extensionType_staticField_augmentedByGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static const int foo = 0;
  augment static int get foo;
//                       ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
}
''');
  }

  test_mixin_staticField_augmentedByGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static const int foo = 0;
  augment static int get foo;
//                       ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
}
''');
  }

  test_topLevelVariable_augmentedByGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
const int foo = 0;
augment int get foo;
//              ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
''');
  }

  test_topLevelVariable_augmentedBySetter() async {
    await resolveTestCodeWithDiagnostics(r'''
const int foo = 0;
augment void set foo(int _);
//               ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
''');
  }

  test_topLevelVariable_augmentedByVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
const int foo = 0;
augment abstract final int foo;
//                         ^^^
// [diag.augmentsConstantVariable] Const variables can't be augmented.
''');
  }
}

@reflectiveTest
class ConstantVariableAugmentationTest extends PubPackageResolutionTest {
  test_class_staticGetter_augmentedByField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
  augment static const int foo = 0;
//                         ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
}
''');
  }

  test_enum_enumConstant_augmentedByEnumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo
}
augment enum E {
  augment foo,
//        ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
}
''');
  }

  test_enum_nothing_augmentedByEnumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  bar
}
augment enum E {
  augment foo,
//        ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
}
''');
  }

  test_enum_staticGetter_augmentedByField() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
  augment static const int foo = 0;
//                         ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
}
''');
  }

  test_extension_staticGetter_augmentedByField() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
  augment static const int foo = 0;
//                         ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
}
''');
  }

  test_extensionType_staticGetter_augmentedByField() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static int get foo => 0;
  augment static const int foo = 0;
//                         ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
}
''');
  }

  test_mixin_staticGetter_augmentedByField() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
  augment static const int foo = 0;
//                         ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
}
''');
  }

  test_topLevelAbstractFinalVariable_augmentedByVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract final int foo;
augment const int foo = 0;
//                ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
''');
  }

  test_topLevelFinalVariable_augmentedByVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
final int foo = 0;
augment const int foo = 0;
//                ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
''');
  }

  test_topLevelGetter_augmentedByVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
augment const int foo = 0;
//                ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
''');
  }

  test_topLevelVariable_augmentedByVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
const int foo = 0;
augment const int foo = 0;
//                ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
''');
  }
}
