// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
const int? intConst = 0;
const String? stringConst = "";
const map = {intConst: null, 0: ?intConst, null: 1, stringConst: 1};
''',
      [
        error(
          diag.equalKeysInConstMap,
          86,
          1,
          contextMessages: [message(testFile, 70, 8)],
        ),
      ],
    );
  }

  test_duplicated_int_in_set() async {
    await assertErrorsInCode(
      '''
const int? intConst = 0;
const String? stringConst = "";
const set = {0, ?intConst, stringConst};
''',
      [
        error(
          diag.equalElementsInConstSet,
          74,
          8,
          contextMessages: [message(testFile, 70, 1)],
        ),
      ],
    );
  }

  test_duplicated_int_key_null_aware_key_in_map() async {
    await assertErrorsInCode(
      '''
const int? intConst = 0;
const String? stringConst = "";
const map = {intConst: null, ?(0 as int?): intConst, null: 1, stringConst: 1};
''',
      [
        error(
          diag.equalKeysInConstMap,
          87,
          11,
          contextMessages: [message(testFile, 70, 8)],
        ),
      ],
    );
  }

  test_duplicated_null_in_set() async {
    await assertErrorsInCode(
      '''
const int? nullConst = null;
const int? intConst = 0;
const String? stringConst = "";
const set = {nullConst, null, intConst, stringConst};
''',
      [
        error(
          diag.equalElementsInConstSet,
          110,
          4,
          contextMessages: [message(testFile, 99, 9)],
        ),
      ],
    );
  }

  test_duplicated_null_key_in_map() async {
    await assertErrorsInCode(
      '''
const nullConst = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {null: 1, nullConst: 1, intConst: 1, stringConst: 1};
''',
      [
        error(
          diag.equalKeysInConstMap,
          103,
          9,
          contextMessages: [message(testFile, 94, 4)],
        ),
      ],
    );
  }

  test_duplicated_null_key_null_aware_value_in_map() async {
    await assertErrorsInCode(
      '''
const nullConst = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {null: 1, nullConst: ?intConst, stringConst: 1};
''',
      [
        error(
          diag.equalKeysInConstMap,
          103,
          9,
          contextMessages: [message(testFile, 94, 4)],
        ),
      ],
    );
  }

  test_duplicated_string_in_set() async {
    await assertErrorsInCode(
      '''
const int? intConst = 0;
const String? stringConst = "";
const set = {null, intConst, "", ?stringConst};
''',
      [
        error(
          diag.equalElementsInConstSet,
          91,
          11,
          contextMessages: [message(testFile, 86, 2)],
        ),
      ],
    );
  }

  test_non_const_and_null_under_question_in_list() async {
    await assertErrorsInCode(
      '''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const list = [?null, ?nullVar, intConst, stringConst];
''',
      [
        error(diag.nonConstantListElement, 99, 7),
        error(diag.constInitializedWithNonConstantValue, 99, 7),
      ],
    );
  }

  test_non_const_in_key_under_question_in_map() async {
    await assertErrorsInCode(
      '''
const String? stringConst = "";
int? intVar = 0;
const map = {null: 1, ?intVar: 1, stringConst: 1};
''',
      [
        error(diag.nonConstantMapKey, 72, 6),
        error(diag.constInitializedWithNonConstantValue, 72, 6),
      ],
    );
  }

  test_non_const_int_under_question_in_set() async {
    await assertErrorsInCode(
      '''
const nullConst = null;
const String? stringConst = "";
int? intVar = 0;
const set = {nullConst, ?intVar, stringConst};
''',
      [
        error(diag.nonConstantSetElement, 98, 6),
        error(diag.constInitializedWithNonConstantValue, 98, 6),
      ],
    );
  }

  test_non_const_int_value_under_question_map() async {
    await assertErrorsInCode(
      '''
const String? stringConst = "";
int? intVar = 0;
const map = {null: 1, 0: ?intVar, stringConst: 1};
''',
      [
        error(diag.nonConstantMapValue, 75, 6),
        error(diag.constInitializedWithNonConstantValue, 75, 6),
      ],
    );
  }

  test_non_const_null_key_under_question_in_map() async {
    await assertErrorsInCode(
      '''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {?nullVar: 1, intConst: 1, stringConst: 1};
''',
      [
        error(diag.nonConstantMapKey, 91, 7),
        error(diag.constInitializedWithNonConstantValue, 91, 7),
      ],
    );
  }

  test_non_const_null_under_question_in_set() async {
    await assertErrorsInCode(
      '''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const set = {?nullVar, intConst, stringConst};
''',
      [
        error(diag.nonConstantSetElement, 91, 7),
        error(diag.constInitializedWithNonConstantValue, 91, 7),
      ],
    );
  }

  test_non_const_null_value_under_question_in_map() async {
    await assertErrorsInCode(
      '''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {null: ?nullVar, intConst: 1, stringConst: 1};
''',
      [
        error(diag.nonConstantMapValue, 97, 7),
        error(diag.constInitializedWithNonConstantValue, 97, 7),
      ],
    );
  }

  test_non_const_string_key_under_question_in_map() async {
    await assertErrorsInCode(
      '''
String? stringVar = "";
const map = {null: 1, 0: 1, ?stringVar: 1};
''',
      [
        error(diag.nonConstantMapKey, 53, 9),
        error(diag.constInitializedWithNonConstantValue, 53, 9),
      ],
    );
  }

  test_non_const_string_under_question_in_set() async {
    await assertErrorsInCode(
      '''
const nullConst = null;
const int? intConst = 0;
String? stringVar = "";
const set = {nullConst, intConst, ?stringVar};
''',
      [
        error(diag.nonConstantSetElement, 108, 9),
        error(diag.constInitializedWithNonConstantValue, 108, 9),
      ],
    );
  }

  test_non_const_string_value_under_question_in_map() async {
    await assertErrorsInCode(
      '''
String? stringVar = "";
const map = {null: 1, 0: 1, "": ?stringVar};
''',
      [
        error(diag.nonConstantMapValue, 57, 9),
        error(diag.constInitializedWithNonConstantValue, 57, 9),
      ],
    );
  }

  test_non_const_under_question_in_list() async {
    await assertErrorsInCode(
      '''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const list = [?nullVar, intConst, stringConst];
''',
      [
        error(diag.nonConstantListElement, 92, 7),
        error(diag.constInitializedWithNonConstantValue, 92, 7),
      ],
    );
  }
}
