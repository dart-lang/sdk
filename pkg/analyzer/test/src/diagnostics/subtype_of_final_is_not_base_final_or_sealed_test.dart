// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfFinalIsNotBaseFinalOrSealedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SubtypeOfFinalIsNotBaseFinalOrSealedTest
    extends PubPackageResolutionTest {
  test_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
class B extends A {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_class_extends_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
class B {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
augment class B extends A {}
''');
  }

  test_class_extends_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
class B extends A {}
//              ^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'A' can't be extended outside of its library because it's a final class.
''');
  }

  test_class_extends_outside_viaLanguage219AndCore() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
// @dart=2.19
import 'dart:core';
class A implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
class B extends A {
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.
  int get key => 0;
  int get value => 1;
}
''');
  }

  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
class B implements A {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_class_implements_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
class B implements A {}
//                 ^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'A' can't be implemented outside of its library because it's a final class.
''');
  }

  test_class_implements_outside_viaLanguage219AndCore() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library to avoid over-reporting when we have a
    // [FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY] error.
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
// @dart=2.19
import 'dart:core';
class A implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
class B implements A {
//                 ^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'MapEntry' can't be implemented outside of its library because it's a final class.
  int get key => 0;
  int get value => 1;
}
''');
  }

  test_class_on_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
mixin B on A {}
//         ^
// [diag.finalClassUsedAsMixinConstraintOutsideOfLibrary] The class 'A' can't be used as a mixin superclass constraint outside of its library because it's a final class.
''');
  }

  test_class_sealed_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
//          ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
sealed class B extends A {}
class C extends B {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_class_sealed_extends_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
//          ^
// [context 1] The type 'C' is a subtype of 'A', and 'A' is defined here.
sealed class B extends A {}
sealed class C extends B {}
class D extends C {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed][context 1] The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_class_sealed_extends_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
sealed class B extends A {}
//                     ^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'A' can't be extended outside of its library because it's a final class.
class C extends B {}
''');
  }

  test_class_sealed_extends_unordered() async {
    await resolveTestCodeWithDiagnostics(r'''
class C extends B {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
sealed class B extends A {}
final class A {}
//          ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''');
  }

  test_class_sealed_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
//          ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
sealed class B implements A {}
class C implements B {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_class_sealed_with_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
final class B {}
//          ^
// [context 1] The type 'C' is a subtype of 'B', and 'B' is defined here.
sealed class C extends B with A {}
class D extends C {}
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed][context 1] The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'B' is 'final'.
''');
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
mixin B {}
class C = Object with B implements A;
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_classTypeAlias_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
mixin B {}
interface class C = Object with B implements A;
//              ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_classTypeAlias_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
//          ^
// [context 1] The type 'AA' is a subtype of 'A', and 'A' is defined here.
sealed class AA extends A {}
mixin B {}
class C = Object with B implements AA;
//    ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }

  test_classTypeAlias_sealed_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
//          ^
// [context 1] The type 'AA' is a subtype of 'A', and 'A' is defined here.
sealed class AA extends A {}
mixin B {}
interface class C = Object with B implements AA;
//              ^
// [diag.subtypeOfFinalIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.
''');
  }
}
