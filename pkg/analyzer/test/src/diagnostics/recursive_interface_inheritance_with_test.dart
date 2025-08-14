// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceWithTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceWithTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A extends Object {}
augment class A with A {}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritanceWith, 6, 1),
        error(CompileTimeErrorCode.classUsedAsMixin, 47, 1),
      ],
    );
  }

  test_classTypeAlias() async {
    await assertErrorsInCode(
      r'''
mixin class M = Object with M;
''',
      [error(CompileTimeErrorCode.recursiveInterfaceInheritanceWith, 12, 1)],
    );
  }
}
