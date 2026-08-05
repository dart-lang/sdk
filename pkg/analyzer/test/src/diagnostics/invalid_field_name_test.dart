// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFieldName_RecordLiteralTest);
    defineReflectiveTests(InvalidFieldName_RecordTypeAnnotationTest);
  });
}

@reflectiveTest
class InvalidFieldName_RecordLiteralTest extends PubPackageResolutionTest {
  void test_fromObject() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
//       ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                    ^^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                     ^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                                     ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
''');
  }

  void test_fromObject_noWarningForStaticMembers() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (hash: 1, hashAll: 2, hashAllUnordered: 3);
''');
  }

  void test_fromObject_withPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (0, hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
//          ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                       ^^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                        ^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                                        ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
''');
  }

  void test_positional_named_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (0, $1: 2);
//          ^^
// [diag.invalidFieldNamePositional] Record field names can't be a dollar sign followed by an integer when the integer is the index of a positional field.
''');
  }

  void test_positional_named_conflict_namedBeforePositional() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = ($1: 2, 1);
//       ^^
// [diag.invalidFieldNamePositional] Record field names can't be a dollar sign followed by an integer when the integer is the index of a positional field.
''');
  }

  void test_positional_named_leadingZero() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (0, 1, $02: 2);
''');
  }

  void test_positional_named_noConflict() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (0, $2: 2);
''');
  }

  void test_private() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (_a: 1, b: 2);
//       ^^
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }
}

@reflectiveTest
class InvalidFieldName_RecordTypeAnnotationTest
    extends PubPackageResolutionTest {
  void test_fromObject_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int hashCode, int noSuchMethod, int runtimeType, int toString}) r) {}
//           ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                         ^^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                           ^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                                            ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
''');
  }

  void test_fromObject_noWarningForStaticMembers() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int hash,}) r) {}
void g((int hashAll,) r) {}
''');
  }

  void test_fromObject_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int hashCode, int noSuchMethod, int runtimeType, int toString) r) {}
//          ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                        ^^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                          ^^^^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
//                                                           ^^^^^^^^
// [diag.invalidFieldNameFromObject] Record field names can't be the same as a member from 'Object'.
''');
  }

  void test_positional_named_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int, String, {int $2}) r) {}
//                        ^^
// [diag.invalidFieldNamePositional] Record field names can't be a dollar sign followed by an integer when the integer is the index of a positional field.
''');
  }

  void test_positional_named_leadingZero() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int, String, {int $02}) r) {}
''');
  }

  void test_positional_named_noConflict() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int $22}) r) {}
''');
  }

  void test_positional_positional_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int $2, int b) r) {}
//          ^^
// [diag.invalidFieldNamePositional] Record field names can't be a dollar sign followed by an integer when the integer is the index of a positional field.
''');
  }

  void test_positional_positional_noConflict_same() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int $1, int b) r) {}
''');
  }

  void test_positional_positional_noConflict_unused() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int $4, int b) r) {}
''');
  }

  void test_private_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int _a}) r) {}
//           ^^
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }

  void test_private_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int _a, int b) r) {}
//          ^^
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }

  void test_wildcard_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int _, int b}) r) {}
//           ^
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }

  void test_wildcard_named_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f(({int _, int b}) r) {}
//           ^
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }

  void test_wildcard_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int _, int b) r) {}
''');
  }

  void test_wildcard_positional_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f((int _, int b) r) {}
//          ^
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }
}
