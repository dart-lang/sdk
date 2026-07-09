// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateFieldName_RecordLiteralTest);
    defineReflectiveTests(DuplicateFieldName_RecordTypeAnnotationTest);
  });
}

@reflectiveTest
class DuplicateFieldName_RecordLiteralTest extends PubPackageResolutionTest {
  void test_duplicated() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (a: 1, a: 2);
//       ^
// [context 1] The first
//             ^
// [diag.duplicateFieldName][context 1] The field name 'a' is already used in this record.
''');
  }

  void test_notDuplicated() async {
    await resolveTestCodeWithDiagnostics(r'''
var r = (a: 1, b: 2);
''');
  }
}

@reflectiveTest
class DuplicateFieldName_RecordTypeAnnotationTest
    extends PubPackageResolutionTest {
  void test_duplicated_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int a, int a}) r) {}
//           ^
// [context 1] The first
//                  ^
// [diag.duplicateFieldName][context 1] The field name 'a' is already used in this record.
''');
  }

  void test_duplicated_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int a, int a) r) {}
//          ^
// [context 1] The first
//                 ^
// [diag.duplicateFieldName][context 1] The field name 'a' is already used in this record.
''');
  }

  void test_duplicated_positionalAndNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int a, {int a}) r) {}
//          ^
// [context 1] The first
//                  ^
// [diag.duplicateFieldName][context 1] The field name 'a' is already used in this record.
''');
  }

  void test_duplicated_wildcard_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int _, int _}) r) {}
//           ^
// [context 1] The first
// [diag.invalidFieldNamePrivate] Record field names can't be private.
//                  ^
// [diag.duplicateFieldName][context 1] The field name '_' is already used in this record.
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }

  void test_duplicated_wildcard_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int _, int _) r) {}
''');
  }

  void test_duplicated_wildcard_positional_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f((int _, int _) r) {}
//          ^
// [context 1] The first
// [diag.invalidFieldNamePrivate] Record field names can't be private.
//                 ^
// [diag.duplicateFieldName][context 1] The field name '_' is already used in this record.
// [diag.invalidFieldNamePrivate] Record field names can't be private.
''');
  }

  void test_notDuplicated_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int a, int b}) r) {}
''');
  }

  void test_notDuplicated_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int a, int b) r) {}
''');
  }

  void test_notDuplicated_positionalAndNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int a, {int b}) r) {}
''');
  }
}
