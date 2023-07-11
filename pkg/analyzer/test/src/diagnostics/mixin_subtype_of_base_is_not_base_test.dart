// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSubtypeOfBaseIsNotBaseTest);
  });
}

@reflectiveTest
class MixinSubtypeOfBaseIsNotBaseTest extends PubPackageResolutionTest {
  test_class_implements() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B implements A {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE, 22, 1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_implements_indirect() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class B implements A {}
mixin C implements B {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE, 53, 1,
          text:
              "The mixin 'C' must be 'base' because the supertype 'A' is 'base'.",
          contextMessages: [
            ExpectedContextMessage(testFile.path, 11, 1,
                text:
                    "The type 'B' is a subtype of 'A', and 'A' is defined here.")
          ]),
    ]);
  }

  test_class_on() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B on A {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE, 22, 1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'base'."),
    ]);
  }

  test_mixin_implements() async {
    await assertErrorsInCode(r'''
base mixin A {}
mixin B implements A {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE, 22, 1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'base'."),
    ]);
  }
}
