// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfBaseOrFinalIsNotBaseFinalOrSealedTest);
  });
}

@reflectiveTest
class SubtypeOfBaseOrFinalIsNotBaseFinalOrSealedTest
    extends PubPackageResolutionTest {
  test_class_base_extends() async {
    await assertErrorsInCode(r'''
base class A {}
class B extends A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          22,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_base_extends_multiple() async {
    await assertErrorsInCode(r'''
base class A {}
base class B extends A {}
class C extends A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          48,
          1,
          text:
              "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_base_extends_multiple_files() async {
    await assertErrorsInFile(
        resourceProvider.convertPath('$testPackageLibPath/a.dart'), r'''
base class A {}
class B extends A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          22,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
    await assertErrorsInFile(
        resourceProvider.convertPath('$testPackageLibPath/c.dart'), r'''
import 'a.dart';
class C extends B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        23,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/a.dart', 22, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
    await assertErrorsInCode(r'''
import 'a.dart';
class D extends B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        23,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/a.dart', 22, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_base_extends_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class B extends A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          25,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_base_implements() async {
    await assertErrorsInCode(r'''
base class A {}
class B implements A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          22,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_base_mixin_mixedIn() async {
    await assertErrorsInCode(r'''
base mixin class A {}
class B with A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          28,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_base_mixin_mixedIn_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin class A {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class B with A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          25,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_class_base_multiple() async {
    await assertErrorsInCode(r'''
base class A {}
final class B {}
class C extends B implements A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          39,
          1,
          text:
              "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'B' is 'final'."),
    ]);
  }

  test_class_final_extends() async {
    await assertErrorsInCode(r'''
final class A {}
class B extends A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_class_final_implements() async {
    await assertErrorsInCode(r'''
final class A {}
class B implements A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_class_sealed_base_extends() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class B extends A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        50,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_base_extends_multiple() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class B extends A {}
sealed class C extends B {}
class D extends C {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        78,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 57, 1,
              text:
                  "The type 'C' is a subtype of 'A', and 'C' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_base_extends_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
sealed class B extends A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        53,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 32, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_base_extends_unordered() async {
    await assertErrorsInCode(r'''
class C extends B {}
sealed class B extends A {}
base class A {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        6,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 34, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_base_implements() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class B implements A {}
class C implements B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        53,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_base_mixin_mixedIn() async {
    await assertErrorsInCode(r'''
base mixin class A {}
sealed class B with A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        53,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 35, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_base_mixin_mixedIn_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin class A {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
sealed class B with A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        50,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 32, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_final_extends() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B extends A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        51,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_final_implements() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B implements A {}
class C implements B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        54,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_base_implements() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B implements A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          22,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_mixin_base_on() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B on A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          22,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_mixin_final_implements() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B implements A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_mixin_final_on() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B on A {}
''', [
      error(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23,
          1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_mixin_sealed_base_implements() async {
    await assertErrorsInCode(r'''
base class A {}
sealed mixin B implements A {}
mixin C implements B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        53,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_sealed_base_on() async {
    await assertErrorsInCode(r'''
base class A {}
sealed mixin B on A {}
mixin C on B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        45,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 29, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_sealed_final_implements() async {
    await assertErrorsInCode(r'''
final class A {}
sealed mixin B implements A {}
mixin C implements B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        54,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_sealed_final_on() async {
    await assertErrorsInCode(r'''
final class A {}
sealed mixin B on A {}
mixin C on B {}
''', [
      error(
        CompileTimeErrorCode
            .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        46,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }
}
