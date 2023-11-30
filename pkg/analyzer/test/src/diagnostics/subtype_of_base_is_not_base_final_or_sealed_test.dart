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

  test_class_extends_outside_viaLanguage219AndCore() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
// @dart=2.19
import 'dart:collection';
abstract class A implements LinkedListEntry<Never> {}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await assertErrorsInCode(r'''
import 'a.dart';
abstract class B extends A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          32, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'LinkedListEntry' is 'base'."),
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

  test_class_implements_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
class B implements A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 36,
          1),
    ]);
  }

  test_class_implements_outside_viaLanguage219AndCore() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
// @dart=2.19
import 'dart:collection';
abstract class A implements LinkedListEntry<Never> {}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await assertErrorsInCode(r'''
import 'a.dart';
abstract class B implements A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          32, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'LinkedListEntry' is 'base'."),
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          1),
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
          ExpectedContextMessage(testFile.path, 11, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_interface_implements_base() async {
    await assertErrorsInCode(r'''
base class A {}
interface class B {}
sealed class C extends B implements A {}
class D extends C {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        84,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 11, 1,
              text:
                  "The type 'C' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_interface_with_base() async {
    await assertErrorsInCode(r'''
base mixin A {}
interface class B {}
sealed class C extends B with A {}
class D extends C {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        78,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 11, 1,
              text:
                  "The type 'C' is a subtype of 'A', and 'A' is defined here.")
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
          ExpectedContextMessage(testFile.path, 11, 1,
              text:
                  "The type 'C' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_outside() async {
    final aPath = '$testPackageLibPath/a.dart';
    newFile(aPath, r'''
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
          ExpectedContextMessage(convertPath(aPath), 11, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
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
          ExpectedContextMessage(testFile.path, 60, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
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
          ExpectedContextMessage(testFile.path, 11, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_classTypeAlias() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B {}
class C = Object with B implements A;
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          33, 1,
          text:
              "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_classTypeAlias_interface() async {
    await assertErrorsInCode(r'''
base class A {}
mixin B {}
interface class C = Object with B implements A;
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          43, 1,
          text:
              "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'."),
    ]);
  }

  test_classTypeAlias_sealed() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class AA extends A {}
mixin B {}
class C = Object with B implements AA;
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        62,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 11, 1,
              text:
                  "The type 'AA' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_classTypeAlias_sealed_interface() async {
    await assertErrorsInCode(r'''
base class A {}
sealed class AA extends A {}
mixin B {}
interface class C = Object with B implements AA;
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
        72,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 11, 1,
              text:
                  "The type 'AA' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_mixinClass_sealed() async {
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
          ExpectedContextMessage(testFile.path, 17, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_mixinClass_sealed_outside() async {
    final aPath = '$testPackageLibPath/a.dart';
    newFile(aPath, r'''
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
          ExpectedContextMessage(convertPath(aPath), 17, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_mixinClass_with() async {
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

  test_mixinClass_with_outside() async {
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
}
