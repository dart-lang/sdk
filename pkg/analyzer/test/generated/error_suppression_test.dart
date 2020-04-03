// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorSuppressionTest);
  });
}

@reflectiveTest
class ErrorSuppressionTest extends DriverResolutionTest with PackageMixin {
  String get ignoredCode => 'const_initialized_with_non_constant_value';

  test_error_code_mismatch() async {
    await assertErrorsInCode('''
// ignore: $ignoredCode
int x = '';
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 61, 2),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 75,
          1),
    ]);
  }

  test_ignore_first() async {
    await assertErrorsInCode('''
// ignore: invalid_assignment
int x = '';
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 82,
          1),
    ]);
  }

  test_ignore_first_trailing() async {
    await assertErrorsInCode('''
int x = ''; // ignore: invalid_assignment
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 82,
          1),
    ]);
  }

  test_ignore_for_file() async {
    await assertErrorsInCode('''
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// ignore_for_file: invalid_assignment
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 44,
          1),
    ]);
  }

  test_ignore_for_file_whitespace_variant() async {
    await assertNoErrorsInCode('''
//ignore_for_file:   $ignoredCode , invalid_assignment
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
  }

  test_ignore_only_trailing() async {
    await assertNoErrorsInCode('''
int x = ''; // ignore: invalid_assignment
''');
  }

  test_ignore_second() async {
    await assertErrorsInCode('''
//INVALID_ASSIGNMENT
int x = '';
// ignore: $ignoredCode
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 29, 2),
    ]);
  }

  test_ignore_second_trailing() async {
    await assertErrorsInCode('''
//INVALID_ASSIGNMENT
int x = '';
const y = x; // ignore: $ignoredCode
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 29, 2),
    ]);
  }

  test_ignore_uniqueName() async {
    addMetaPackage();
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

int f({@Required('x') int a}) => 0;

// ignore: missing_required_param_with_details
int x = f();
''');
  }

  test_ignore_upper_case() async {
    await assertNoErrorsInCode('''
int x = ''; // ignore: INVALID_ASSIGNMENT
''');
  }

  test_invalid_error_code() async {
    await assertErrorsInCode('''
// ignore: right_format_wrong_code
int x = '';
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 43, 2),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 57,
          1),
    ]);
  }

  test_missing_error_codes() async {
    await assertErrorsInCode('''
    int x = 3;
// ignore:
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 43,
          1),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 43, 1),
    ]);
  }

  test_missing_metadata_suffix() async {
    await assertErrorsInCode('''
// ignore invalid_assignment
String y = 3; //INVALID_ASSIGNMENT
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 40, 1),
    ]);
  }

  test_multiple_comments() async {
    await assertErrorsInCode('''
int x = ''; //This is the first comment...
// ignore: $ignoredCode
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 8, 2),
    ]);
  }

  test_multiple_ignore_for_files() async {
    await assertNoErrorsInCode('''
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// ignore_for_file: invalid_assignment,$ignoredCode
''');
  }

  test_multiple_ignores() async {
    await assertNoErrorsInCode('''
int x = 3;
// ignore: invalid_assignment, $ignoredCode
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
  }

  test_multiple_ignores_trailing() async {
    await assertNoErrorsInCode('''
int x = 3;
const String y = x; // ignore: invalid_assignment, $ignoredCode
''');
  }

  test_multiple_ignores_whitespace_variant_1() async {
    await assertNoErrorsInCode('''
int x = 3;
//ignore:invalid_assignment,$ignoredCode
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
  }

  test_multiple_ignores_whitespace_variant_2() async {
    await assertNoErrorsInCode('''
int x = 3;
//ignore: invalid_assignment,$ignoredCode
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
  }

  test_multiple_ignores_whitespace_variant_3() async {
    await assertNoErrorsInCode('''
int x = 3;
// ignore: invalid_assignment,$ignoredCode
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
  }

  test_no_ignores() async {
    await assertErrorsInCode('''
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 8, 2),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 44,
          1),
    ]);
  }

  test_trailing_not_above() async {
    await assertErrorsInCode('''
int x = ''; // ignore: invalid_assignment
int y = '';
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 50, 2),
    ]);
  }
}
