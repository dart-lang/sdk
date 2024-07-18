// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(r'''
var r = (a: 1, a: 2);
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 15, 1,
          contextMessages: [message(testFile, 9, 1)]),
    ]);
  }

  void test_notDuplicated() async {
    await assertNoErrorsInCode(r'''
var r = (a: 1, b: 2);
''');
  }
}

@reflectiveTest
class DuplicateFieldName_RecordTypeAnnotationTest
    extends PubPackageResolutionTest {
  void test_duplicated_named() async {
    await assertErrorsInCode(r'''
void f(({int a, int a}) r) {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 20, 1,
          contextMessages: [message(testFile, 13, 1)]),
    ]);
  }

  void test_duplicated_positional() async {
    await assertErrorsInCode(r'''
void f((int a, int a) r) {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 19, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  void test_duplicated_positionalAndNamed() async {
    await assertErrorsInCode(r'''
void f((int a, {int a}) r) {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 20, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  void test_duplicated_wildcard_named() async {
    await assertErrorsInCode(r'''
void f(({int _, int _}) r) {}
''', [
      // Only positional wildcard fields can be duplicated.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 13, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 20, 1,
          contextMessages: [message(testFile, 13, 1)]),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 20, 1),
    ]);
  }

  void test_duplicated_wildcard_positional() async {
    await assertNoErrorsInCode(r'''
void f((int _, int _) r) {}
''');
  }

  void test_duplicated_wildcard_positional_preWildcards() async {
    await assertErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f((int _, int _) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 56, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 63, 1,
          contextMessages: [message(testFile, 56, 1)]),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 63, 1),
    ]);
  }

  void test_notDuplicated_named() async {
    await assertNoErrorsInCode(r'''
void f(({int a, int b}) r) {}
''');
  }

  void test_notDuplicated_positional() async {
    await assertNoErrorsInCode(r'''
void f((int a, int b) r) {}
''');
  }

  void test_notDuplicated_positionalAndNamed() async {
    await assertNoErrorsInCode(r'''
void f((int a, {int b}) r) {}
''');
  }
}
