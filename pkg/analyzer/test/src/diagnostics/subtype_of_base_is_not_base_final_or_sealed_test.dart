// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfBaseIsNotBaseFinalOrSealedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SubtypeOfBaseIsNotBaseFinalOrSealedTest extends PubPackageResolutionTest {
  test_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
class B extends A {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_extends_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
base class B extends A {}
class C extends A {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_extends_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
class B extends A {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_extends_outside_viaLanguage219AndCore() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
// @dart=2.19
import 'dart:collection';
abstract class A implements LinkedListEntry<Never> {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
abstract class B extends A {}
//             ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'LinkedListEntry' is 'base'.
''');
  }

  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
class B implements A {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_implements_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
class B implements A {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
//                 ^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'A' can't be implemented outside of its library because it's a base class.
''');
  }

  test_class_implements_outside_viaLanguage219AndCore() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
// @dart=2.19
import 'dart:collection';
abstract class A implements LinkedListEntry<Never> {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
abstract class B implements A {}
//             ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'LinkedListEntry' is 'base'.
//                          ^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'LinkedListEntry' can't be implemented outside of its library because it's a base class.
''');
  }

  test_class_sealed_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
sealed class B extends A {}
class C extends B {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_sealed_extends_interface_implements_base() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
//         ^
// [context 1] The type 'C' is a subtype of 'A', and 'A' is defined here.
interface class B {}
sealed class C extends B implements A {}
class D extends C {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_sealed_extends_interface_with_base() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin A {}
//         ^
// [context 1] The type 'C' is a subtype of 'A', and 'A' is defined here.
interface class B {}
sealed class C extends B with A {}
class D extends C {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_sealed_extends_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
//         ^
// [context 1] The type 'C' is a subtype of 'A', and 'A' is defined here.
sealed class B extends A {}
sealed class C extends B {}
class D extends C {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_class_sealed_extends_outside() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFilesWithDiagnostics({
      a: r'''
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''',
      testFile: r'''
import 'a.dart';
sealed class B extends A {}
class C extends B {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''',
    });
  }

  test_class_sealed_extends_unordered() async {
    await resolveTestCodeWithDiagnostics(r'''
class C extends B {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
sealed class B extends A {}
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''');
  }

  test_class_sealed_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
sealed class B implements A {}
class C implements B {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
mixin B {}
class C = Object with B implements A;
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_classTypeAlias_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
mixin B {}
interface class C = Object with B implements A;
//              ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_classTypeAlias_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
//         ^
// [context 1] The type 'AA' is a subtype of 'A', and 'A' is defined here.
sealed class AA extends A {}
mixin B {}
class C = Object with B implements AA;
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_classTypeAlias_sealed_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
//         ^
// [context 1] The type 'AA' is a subtype of 'A', and 'A' is defined here.
sealed class AA extends A {}
mixin B {}
interface class C = Object with B implements AA;
//              ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_mixinClass_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin class A {}
//               ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
sealed class B with A {}
class C extends B {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_mixinClass_sealed_outside() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFilesWithDiagnostics({
      a: r'''
base mixin class A {}
//               ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''',
      testFile: r'''
import 'a.dart';
sealed class B with A {}
class C extends B {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed][context 1] The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''',
    });
  }

  test_mixinClass_with() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin class A {}
class B with A {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }

  test_mixinClass_with_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
base mixin class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
class B with A {}
//    ^
// [diag.subtypeOfBaseIsNotBaseFinalOrSealed] The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'base'.
''');
  }
}
