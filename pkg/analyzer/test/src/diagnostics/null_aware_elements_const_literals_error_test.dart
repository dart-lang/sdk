// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareElementsConstLiteralsErrorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullAwareElementsConstLiteralsErrorTest extends PubPackageResolutionTest {
  test_duplicated_in_key_named_null_aware_key_in_map() async {
    await resolveTestCodeWithDiagnostics('''
const int? intConst = 0;
const String? stringConst = "";
const map = {intConst: null, 0: ?intConst, null: 1, stringConst: 1};
//           ^^^^^^^^
// [context 1] The first key with this value.
//                           ^
// [diag.equalKeysInConstMap][context 1] Two keys in a constant map literal can't be equal.
''');
  }

  test_duplicated_int_in_set() async {
    await resolveTestCodeWithDiagnostics('''
const int? intConst = 0;
const String? stringConst = "";
const set = {0, ?intConst, stringConst};
//           ^
// [context 1] The first element with this value.
//               ^^^^^^^^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_duplicated_int_key_null_aware_key_in_map() async {
    await resolveTestCodeWithDiagnostics('''
const int? intConst = 0;
const String? stringConst = "";
const map = {intConst: null, ?(0 as int?): intConst, null: 1, stringConst: 1};
//           ^^^^^^^^
// [context 1] The first key with this value.
//                            ^^^^^^^^^^^
// [diag.equalKeysInConstMap][context 1] Two keys in a constant map literal can't be equal.
''');
  }

  test_duplicated_null_in_set() async {
    await resolveTestCodeWithDiagnostics('''
const int? nullConst = null;
const int? intConst = 0;
const String? stringConst = "";
const set = {nullConst, null, intConst, stringConst};
//           ^^^^^^^^^
// [context 1] The first element with this value.
//                      ^^^^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_duplicated_null_key_in_map() async {
    await resolveTestCodeWithDiagnostics('''
const nullConst = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {null: 1, nullConst: 1, intConst: 1, stringConst: 1};
//           ^^^^
// [context 1] The first key with this value.
//                    ^^^^^^^^^
// [diag.equalKeysInConstMap][context 1] Two keys in a constant map literal can't be equal.
''');
  }

  test_duplicated_null_key_null_aware_value_in_map() async {
    await resolveTestCodeWithDiagnostics('''
const nullConst = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {null: 1, nullConst: ?intConst, stringConst: 1};
//           ^^^^
// [context 1] The first key with this value.
//                    ^^^^^^^^^
// [diag.equalKeysInConstMap][context 1] Two keys in a constant map literal can't be equal.
''');
  }

  test_duplicated_string_in_set() async {
    await resolveTestCodeWithDiagnostics('''
const int? intConst = 0;
const String? stringConst = "";
const set = {null, intConst, "", ?stringConst};
//                           ^^
// [context 1] The first element with this value.
//                                ^^^^^^^^^^^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_non_const_and_null_under_question_in_list() async {
    await resolveTestCodeWithDiagnostics('''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const list = [?null, ?nullVar, intConst, stringConst];
//                    ^^^^^^^
// [diag.nonConstantListElement] The values in a const list literal must be constants.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_in_key_under_question_in_map() async {
    await resolveTestCodeWithDiagnostics('''
const String? stringConst = "";
int? intVar = 0;
const map = {null: 1, ?intVar: 1, stringConst: 1};
//                     ^^^^^^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_int_under_question_in_set() async {
    await resolveTestCodeWithDiagnostics('''
const nullConst = null;
const String? stringConst = "";
int? intVar = 0;
const set = {nullConst, ?intVar, stringConst};
//                       ^^^^^^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_int_value_under_question_map() async {
    await resolveTestCodeWithDiagnostics('''
const String? stringConst = "";
int? intVar = 0;
const map = {null: 1, 0: ?intVar, stringConst: 1};
//                        ^^^^^^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_null_key_under_question_in_map() async {
    await resolveTestCodeWithDiagnostics('''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {?nullVar: 1, intConst: 1, stringConst: 1};
//            ^^^^^^^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_null_under_question_in_set() async {
    await resolveTestCodeWithDiagnostics('''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const set = {?nullVar, intConst, stringConst};
//            ^^^^^^^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_null_value_under_question_in_map() async {
    await resolveTestCodeWithDiagnostics('''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const map = {null: ?nullVar, intConst: 1, stringConst: 1};
//                  ^^^^^^^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_string_key_under_question_in_map() async {
    await resolveTestCodeWithDiagnostics('''
String? stringVar = "";
const map = {null: 1, 0: 1, ?stringVar: 1};
//                           ^^^^^^^^^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_string_under_question_in_set() async {
    await resolveTestCodeWithDiagnostics('''
const nullConst = null;
const int? intConst = 0;
String? stringVar = "";
const set = {nullConst, intConst, ?stringVar};
//                                 ^^^^^^^^^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_string_value_under_question_in_map() async {
    await resolveTestCodeWithDiagnostics('''
String? stringVar = "";
const map = {null: 1, 0: 1, "": ?stringVar};
//                               ^^^^^^^^^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_non_const_under_question_in_list() async {
    await resolveTestCodeWithDiagnostics('''
var nullVar = null;
const int? intConst = 0;
const String? stringConst = "";
const list = [?nullVar, intConst, stringConst];
//             ^^^^^^^
// [diag.nonConstantListElement] The values in a const list literal must be constants.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }
}
