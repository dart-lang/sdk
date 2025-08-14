// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceOnTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceOnTest extends PubPackageResolutionTest {
  test_1() async {
    await assertErrorsInCode(
      r'''
mixin A on A {}
''',
      [error(CompileTimeErrorCode.recursiveInterfaceInheritanceOn, 6, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_1_inAugmentation() async {
    await assertErrorsInCode(
      r'''
mixin A {}
augment mixin A on A {}
''',
      [error(CompileTimeErrorCode.recursiveInterfaceInheritanceOn, 6, 1)],
    );
  }

  test_2() async {
    await assertErrorsInCode(
      r'''
mixin A on B {}
mixin B on A {}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 22, 1),
      ],
    );
  }
}
