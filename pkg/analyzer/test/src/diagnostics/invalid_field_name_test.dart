// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(r'''
var r = (hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 9, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 22, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 39, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 55, 8),
    ]);
  }

  void test_positional() async {
    await assertErrorsInCode(r'''
var r = (a: 1, $12: 2);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 15, 3),
    ]);
  }

  void test_private() async {
    await assertErrorsInCode(r'''
var r = (_a: 1, b: 2);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 9, 2),
    ]);
  }
}

@reflectiveTest
class InvalidFieldName_RecordTypeAnnotationTest
    extends PubPackageResolutionTest {
  void test_fromObject_named() async {
    await assertErrorsInCode(r'''
void f(({int hashCode, int noSuchMethod, int runtimeType, int toString}) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 13, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 27, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 45, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 62, 8),
    ]);
  }

  void test_fromObject_positional() async {
    await assertErrorsInCode(r'''
void f((int hashCode, int noSuchMethod, int runtimeType, int toString) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 12, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 26, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 44, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 61, 8),
    ]);
  }

  void test_positional_named() async {
    await assertErrorsInCode(r'''
void f(({int $21}) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 13, 3),
    ]);
  }

  void test_positional_positional() async {
    await assertErrorsInCode(r'''
void f((int $3, int b) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 12, 2),
    ]);
  }

  void test_private_named() async {
    await assertErrorsInCode(r'''
void f(({int _a}) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 13, 2),
    ]);
  }

  void test_private_positional() async {
    await assertErrorsInCode(r'''
void f((int _a, int b) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 12, 2),
    ]);
  }
}
