// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
class A<T> {}
augment class A<U> {}
''',
      [error(diag.augmentationTypeParameterName, 30, 1)],
    );
  }

  test_class_method_differentClassFragment() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo<T>() {}
}
augment class A {
  augment void foo<U>();
}
''',
      [error(diag.augmentationTypeParameterName, 68, 1)],
    );
  }

  test_class_method_sameClassFragment() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo<T>() {}
  augment void foo<U>();
}
''',
      [error(diag.augmentationTypeParameterName, 48, 1)],
    );
  }

  test_enum() async {
    await assertErrorsInCode(
      r'''
enum A<T> {v}
augment enum A<U> {}
''',
      [error(diag.augmentationTypeParameterName, 29, 1)],
    );
  }

  test_extension() async {
    await assertErrorsInCode(
      r'''
extension A<T> on int {}
augment extension A<U> {}
''',
      [error(diag.augmentationTypeParameterName, 45, 1)],
    );
  }

  test_extensionType() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}
augment extension type A<U>(int it) {}
''',
      [error(diag.augmentationTypeParameterName, 56, 1)],
    );
  }

  test_mixin() async {
    await assertErrorsInCode(
      r'''
mixin A<T> {}
augment mixin A<U> {}
''',
      [error(diag.augmentationTypeParameterName, 30, 1)],
    );
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(
      r'''
void foo<T>() {}
augment void foo<U>() {}
''',
      [error(diag.augmentationTypeParameterName, 34, 1)],
    );
  }
}
