// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfFinalIsNotBaseFinalOrSealedTest);
  });
}

@reflectiveTest
class SubtypeOfFinalIsNotBaseFinalOrSealedTest
    extends PubPackageResolutionTest {
  test_class_extends() async {
    await assertErrorsInCode(r'''
final class A {}
class B extends A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_class_extends_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
class B extends A {}
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 33, 1),
    ]);
  }

  test_class_extends_outside_viaLanguage219AndCore() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
// @dart=2.19
import 'dart:core';
class A implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await assertErrorsInCode(r'''
import 'a.dart';
class B extends A {
  int get key => 0;
  int get value => 1;
}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'."),
    ]);
  }

  test_class_implements() async {
    await assertErrorsInCode(r'''
final class A {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_class_implements_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
class B implements A {}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 36,
          1),
    ]);
  }

  test_class_implements_outside_viaLanguage219AndCore() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library to avoid over-reporting when we have a
    // [FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY] error.
    final a = newFile('$testPackageLibPath/a.dart', r'''
// @dart=2.19
import 'dart:core';
class A implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await assertErrorsInCode(r'''
import 'a.dart';
class B implements A {
  int get key => 0;
  int get value => 1;
}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 36,
          1),
    ]);
  }

  test_class_on_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
mixin B on A {}
''', [
      error(
          CompileTimeErrorCode
              .FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY,
          28,
          1),
    ]);
  }

  test_class_sealed_extends() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B extends A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        51,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 12, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_multiple() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B extends A {}
sealed class C extends B {}
class D extends C {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        79,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 12, 1,
              text:
                  "The type 'C' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
sealed class B extends A {}
class C extends B {}
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 40, 1),
    ]);
  }

  test_class_sealed_extends_unordered() async {
    await assertErrorsInCode(r'''
class C extends B {}
sealed class B extends A {}
final class A {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        6,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 61, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_implements() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B implements A {}
class C implements B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        54,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 12, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_with_extends() async {
    await assertErrorsInCode(r'''
mixin A {}
final class B {}
sealed class C extends B with A {}
class D extends C {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        69,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'B' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 23, 1,
              text:
                  "The type 'C' is a subtype of 'B', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_classTypeAlias() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B {}
class C = Object with B implements A;
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          34, 1,
          text:
              "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_classTypeAlias_interface() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B {}
interface class C = Object with B implements A;
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          44, 1,
          text:
              "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_classTypeAlias_sealed() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class AA extends A {}
mixin B {}
class C = Object with B implements AA;
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        63,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 12, 1,
              text:
                  "The type 'AA' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_classTypeAlias_sealed_interface() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class AA extends A {}
mixin B {}
interface class C = Object with B implements AA;
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        73,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 12, 1,
              text:
                  "The type 'AA' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }
}
