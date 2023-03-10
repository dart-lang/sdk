// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfBaseIsNotBaseFinalOrSealedTest);
  });
}

@reflectiveTest
class SubtypeOfBaseIsNotBaseFinalOrSealedTest extends PubPackageResolutionTest {
  test_class_extends() async {
    await assertErrorsInCode(r'''
base class A {}
class B extends A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          22, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_extends_multiple() async {
    await assertErrorsInCode(r'''
base class A {}
base class B extends A {}
class C extends A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          48, 1,
          text:
              "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_extends_multiple_files() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
base class A {}
class B extends A {}
''');

    await assertErrorsInFile2(a.path, [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          22, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
    await assertErrorsInCode(r'''
import 'a.dart';
class C extends B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        23,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(a.path, 22, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_extends_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
class B extends A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_implements() async {
    await assertErrorsInCode(r'''
base class A {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          22, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_mixin_mixedIn() async {
    await assertErrorsInCode(r'''
base mixin class A {}
class B with A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          28, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_mixin_mixedIn_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base mixin class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
class B with A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_sealed_extends() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class B extends A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        50,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_multiple() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class B extends A {}
sealed class C extends B {}
class D extends C {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        78,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 57, 1,
              text:
                  "The type 'C' is a subtype of 'A', and 'C' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
sealed class B extends A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        51,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_unordered() async {
    await assertErrorsInCode(r'''
class C extends B {}
sealed class B extends A {}
base class A {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        6,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 34, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_implements() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class B implements A {}
class C implements B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        53,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_mixin_mixedIn() async {
    await assertErrorsInCode(r'''
base mixin class A {}
sealed class B with A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        53,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 35, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_mixin_mixedIn_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base mixin class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
sealed class B with A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        48,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_implements() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B implements A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          22, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_mixin_on() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B on A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          22, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_mixin_sealed_implements() async {
    await assertErrorsInCode(r'''
base class A {}
sealed mixin B implements A {}
mixin C implements B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        53,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_sealed_on() async {
    await assertErrorsInCode(r'''
base class A {}
sealed mixin B on A {}
mixin C on B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        45,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }
}
