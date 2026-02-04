// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
var r = (hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
''',
      [
        error(diag.invalidFieldNameFromObject, 9, 8),
        error(diag.invalidFieldNameFromObject, 22, 12),
        error(diag.invalidFieldNameFromObject, 39, 11),
        error(diag.invalidFieldNameFromObject, 55, 8),
      ],
    );
  }

  void test_fromObject_noWarningForStaticMembers() async {
    await assertNoErrorsInCode(
      'var r = (hash: 1, hashAll: 2, hashAllUnordered: 3);',
    );
  }

  void test_fromObject_withPositional() async {
    await assertErrorsInCode(
      r'''
var r = (0, hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
''',
      [
        error(diag.invalidFieldNameFromObject, 12, 8),
        error(diag.invalidFieldNameFromObject, 25, 12),
        error(diag.invalidFieldNameFromObject, 42, 11),
        error(diag.invalidFieldNameFromObject, 58, 8),
      ],
    );
  }

  void test_positional_named_conflict() async {
    await assertErrorsInCode(
      r'''
var r = (0, $1: 2);
''',
      [error(diag.invalidFieldNamePositional, 12, 2)],
    );
  }

  void test_positional_named_conflict_namedBeforePositional() async {
    await assertErrorsInCode(
      r'''
var r = ($1: 2, 1);
''',
      [error(diag.invalidFieldNamePositional, 9, 2)],
    );
  }

  void test_positional_named_leadingZero() async {
    await assertNoErrorsInCode(r'''
var r = (0, 1, $02: 2);
''');
  }

  void test_positional_named_noConflict() async {
    await assertNoErrorsInCode(r'''
var r = (0, $2: 2);
''');
  }

  void test_private() async {
    await assertErrorsInCode(
      r'''
var r = (_a: 1, b: 2);
''',
      [error(diag.invalidFieldNamePrivate, 9, 2)],
    );
  }
}

@reflectiveTest
class InvalidFieldName_RecordTypeAnnotationTest
    extends PubPackageResolutionTest {
  void test_fromObject_named() async {
    await assertErrorsInCode(
      r'''
void f(({int hashCode, int noSuchMethod, int runtimeType, int toString}) r) {}
''',
      [
        error(diag.invalidFieldNameFromObject, 13, 8),
        error(diag.invalidFieldNameFromObject, 27, 12),
        error(diag.invalidFieldNameFromObject, 45, 11),
        error(diag.invalidFieldNameFromObject, 62, 8),
      ],
    );
  }

  void test_fromObject_noWarningForStaticMembers() async {
    await assertNoErrorsInCode(r'''
void f(({int hash,}) r) {}
void g((int hashAll,) r) {}
''');
  }

  void test_fromObject_positional() async {
    await assertErrorsInCode(
      r'''
void f((int hashCode, int noSuchMethod, int runtimeType, int toString) r) {}
''',
      [
        error(diag.invalidFieldNameFromObject, 12, 8),
        error(diag.invalidFieldNameFromObject, 26, 12),
        error(diag.invalidFieldNameFromObject, 44, 11),
        error(diag.invalidFieldNameFromObject, 61, 8),
      ],
    );
  }

  void test_positional_named_conflict() async {
    await assertErrorsInCode(
      r'''
void f((int, String, {int $2}) r) {}
''',
      [error(diag.invalidFieldNamePositional, 26, 2)],
    );
  }

  void test_positional_named_leadingZero() async {
    await assertNoErrorsInCode(r'''
void f((int, String, {int $02}) r) {}
''');
  }

  void test_positional_named_noConflict() async {
    await assertNoErrorsInCode(r'''
void f(({int $22}) r) {}
''');
  }

  void test_positional_positional_conflict() async {
    await assertErrorsInCode(
      r'''
void f((int $2, int b) r) {}
''',
      [error(diag.invalidFieldNamePositional, 12, 2)],
    );
  }

  void test_positional_positional_noConflict_same() async {
    await assertNoErrorsInCode(r'''
void f((int $1, int b) r) {}
''');
  }

  void test_positional_positional_noConflict_unused() async {
    await assertNoErrorsInCode(r'''
void f((int $4, int b) r) {}
''');
  }

  void test_private_named() async {
    await assertErrorsInCode(
      r'''
void f(({int _a}) r) {}
''',
      [error(diag.invalidFieldNamePrivate, 13, 2)],
    );
  }

  void test_private_positional() async {
    await assertErrorsInCode(
      r'''
void f((int _a, int b) r) {}
''',
      [error(diag.invalidFieldNamePrivate, 12, 2)],
    );
  }

  void test_wildcard_named() async {
    await assertErrorsInCode(
      r'''
void f(({int _, int b}) r) {}
''',
      [error(diag.invalidFieldNamePrivate, 13, 1)],
    );
  }

  void test_wildcard_named_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f(({int _, int b}) r) {}
''',
      [error(diag.invalidFieldNamePrivate, 57, 1)],
    );
  }

  void test_wildcard_positional() async {
    await assertNoErrorsInCode(r'''
void f((int _, int b) r) {}
''');
  }

  void test_wildcard_positional_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f((int _, int b) r) {}
''',
      [error(diag.invalidFieldNamePrivate, 56, 1)],
    );
  }
}
