// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareElementsConstLiteralsErrorTest);
  });
}

@reflectiveTest
class NullAwareElementsConstLiteralsErrorTest extends PubPackageResolutionTest {
  test_duplicated_in_key_named_null_aware_key_in_map() async {
    await assertErrorsInCode('''
const intConst = 0;
const stringConst = "";
const map = {intConst: null, 0: ?intConst, null: 1, stringConst: 1};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 73, 1,
          contextMessages: [message(testFile, 57, 8)]),
    ]);
  }

  test_duplicated_int_in_set() async {
    await assertErrorsInCode('''
const intConst = 0;
const stringConst = "";
const set = {0, ?intConst, stringConst};
''', [
      error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 61, 8,
          contextMessages: [message(testFile, 57, 1)]),
    ]);
  }

  test_duplicated_int_key_null_aware_key_in_map() async {
    await assertErrorsInCode('''
const intConst = 0;
const stringConst = "";
const map = {intConst: null, ?0: intConst, null: 1, stringConst: 1};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 74, 1,
          contextMessages: [message(testFile, 57, 8)]),
    ]);
  }

  test_duplicated_null_in_set() async {
    await assertErrorsInCode('''
const nullConst = null;
const intConst = 0;
const stringConst = "";
const set = {nullConst, null, intConst, stringConst};
''', [
      error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 92, 4,
          contextMessages: [message(testFile, 81, 9)]),
    ]);
  }

  test_duplicated_null_key_in_map() async {
    await assertErrorsInCode('''
const nullConst = null;
const intConst = 0;
const stringConst = "";
const map = {null: 1, nullConst: 1, intConst: 1, stringConst: 1};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 90, 9,
          contextMessages: [message(testFile, 81, 4)]),
    ]);
  }

  test_duplicated_null_key_null_aware_value_in_map() async {
    await assertErrorsInCode('''
const nullConst = null;
const intConst = 0;
const stringConst = "";
const map = {null: 1, nullConst: ?intConst, stringConst: 1};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 90, 9,
          contextMessages: [message(testFile, 81, 4)]),
    ]);
  }

  test_duplicated_string_in_set() async {
    await assertErrorsInCode('''
const intConst = 0;
const stringConst = "";
const set = {null, intConst, "", ?stringConst};
''', [
      error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 78, 11,
          contextMessages: [message(testFile, 73, 2)]),
    ]);
  }

  test_non_const_and_null_under_question_in_list() async {
    await assertErrorsInCode('''
var nullVar = null;
const intConst = 0;
const stringConst = "";
const list = [?null, ?nullVar, intConst, stringConst];
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 86,
          7),
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 86, 7),
    ]);
  }

  test_non_const_in_key_under_question_in_map() async {
    await assertErrorsInCode('''
const stringConst = "";
var intVar = 0;
const map = {null: 1, ?intVar: 1, stringConst: 1};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 63, 6),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 63,
          6),
    ]);
  }

  test_non_const_int_under_question_in_set() async {
    await assertErrorsInCode('''
const nullConst = null;
const stringConst = "";
var intVar = 0;
const set = {nullConst, ?intVar, stringConst};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 89, 6),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 89,
          6),
    ]);
  }

  test_non_const_int_value_under_question_map() async {
    await assertErrorsInCode('''
const stringConst = "";
var intVar = 0;
const map = {null: 1, 0: ?intVar, stringConst: 1};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 66, 6),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 66,
          6),
    ]);
  }

  test_non_const_null_key_under_question_in_map() async {
    await assertErrorsInCode('''
var nullVar = null;
const intConst = 0;
const stringConst = "";
const map = {?nullVar: 1, intConst: 1, stringConst: 1};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 78, 7),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 78,
          7),
    ]);
  }

  test_non_const_null_under_question_in_set() async {
    await assertErrorsInCode('''
var nullVar = null;
const intConst = 0;
const stringConst = "";
const set = {?nullVar, intConst, stringConst};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 78, 7),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 78,
          7),
    ]);
  }

  test_non_const_null_value_under_question_in_map() async {
    await assertErrorsInCode('''
var nullVar = null;
const intConst = 0;
const stringConst = "";
const map = {null: ?nullVar, intConst: 1, stringConst: 1};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 84, 7),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 84,
          7),
    ]);
  }

  test_non_const_string_key_under_question_in_map() async {
    await assertErrorsInCode('''
var stringVar = "";
const map = {null: 1, 0: 1, ?stringVar: 1};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 49, 9),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 49,
          9),
    ]);
  }

  test_non_const_string_under_question_in_set() async {
    await assertErrorsInCode('''
const nullConst = null;
const intConst = 0;
var stringVar = "";
const set = {nullConst, intConst, ?stringVar};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 99, 9),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 99,
          9),
    ]);
  }

  test_non_const_string_value_under_question_in_map() async {
    await assertErrorsInCode('''
var stringVar = "";
const map = {null: 1, 0: 1, "": ?stringVar};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 53, 9),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 53,
          9),
    ]);
  }

  test_non_const_under_question_in_list() async {
    await assertErrorsInCode('''
var nullVar = null;
const intConst = 0;
const stringConst = "";
const list = [?nullVar, intConst, stringConst];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 79, 7),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 79,
          7),
    ]);
  }
}
