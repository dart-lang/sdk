// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceImplementsTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceImplementsTest
    extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(
      '''
class A implements A {}
''',
      [
        error(
          CompileTimeErrorCode.recursiveInterfaceInheritanceImplements,
          6,
          1,
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_inAugmentation() async {
    await assertErrorsInCode(
      '''
class A {}
augment class A implements A {}
''',
      [
        error(
          CompileTimeErrorCode.recursiveInterfaceInheritanceImplements,
          6,
          1,
        ),
      ],
    );
  }

  test_class_tail() async {
    await assertErrorsInCode(
      r'''
abstract class A implements A {}
class B implements A {}
''',
      [
        error(
          CompileTimeErrorCode.recursiveInterfaceInheritanceImplements,
          15,
          1,
        ),
      ],
    );
  }

  test_classTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin M {}
class B = A with M implements B;
''',
      [
        error(
          CompileTimeErrorCode.recursiveInterfaceInheritanceImplements,
          28,
          1,
        ),
      ],
    );
  }

  test_mixin() async {
    await assertErrorsInCode(
      r'''
mixin A implements B {}
mixin B implements A {}''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 30, 1),
      ],
    );
  }
}
