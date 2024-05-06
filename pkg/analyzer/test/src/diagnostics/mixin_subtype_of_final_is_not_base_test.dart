// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSubtypeOfFinalIsNotBaseTest);
  });
}

@reflectiveTest
class MixinSubtypeOfFinalIsNotBaseTest extends PubPackageResolutionTest {
  test_implements() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B implements A {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE, 23, 1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'final'."),
    ]);
  }

  test_implements_indirect() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B implements A {}
mixin C implements B {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE, 54, 1,
          text:
              "The mixin 'C' must be 'base' because the supertype 'A' is 'final'.",
          contextMessages: [
            ExpectedContextMessage(testFile, 12, 1,
                text:
                    "The type 'B' is a subtype of 'A', and 'A' is defined here.")
          ]),
    ]);
  }

  test_on() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B on A {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE, 23, 1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'final'."),
    ]);
  }
}
