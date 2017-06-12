// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorSuppressionTest);
  });
}

@reflectiveTest
class ErrorSuppressionTest extends ResolverTestCase {
  test_error_code_mismatch() async {
    Source source = addSource('''
// ignore: const_initialized_with_non_constant_value
int x = '';
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  test_ignore_first() async {
    Source source = addSource('''
// ignore: invalid_assignment
int x = '';
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  test_ignore_first_trailing() async {
    Source source = addSource('''
int x = ''; // ignore: invalid_assignment
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  test_ignore_only_trailing() async {
    Source source = addSource('''
int x = ''; // ignore: invalid_assignment
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_ignore_second() async {
    Source source = addSource('''
//INVALID_ASSIGNMENT
int x = '';
// ignore: const_initialized_with_non_constant_value
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  test_ignore_second_trailing() async {
    Source source = addSource('''
//INVALID_ASSIGNMENT
int x = '';
const y = x; // ignore: const_initialized_with_non_constant_value
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  test_ignore_upper_case() async {
    Source source = addSource('''
int x = ''; // ignore: INVALID_ASSIGNMENT
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_invalid_error_code() async {
    Source source = addSource('''
// ignore: right_format_wrong_code
int x = '';
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  test_missing_error_codes() async {
    Source source = addSource('''
    int x = 3;
// ignore:
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  test_missing_metadata_suffix() async {
    Source source = addSource('''
// ignore invalid_assignment
String y = 3; //INVALID_ASSIGNMENT
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  test_multiple_comments() async {
    Source source = addSource('''
int x = ''; //This is the first comment...
// ignore: const_initialized_with_non_constant_value
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  test_multiple_ignores() async {
    Source source = addSource('''
int x = 3;
// ignore: invalid_assignment, const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_multiple_ignores_traling() async {
    Source source = addSource('''
int x = 3;
const String y = x; // ignore: invalid_assignment, const_initialized_with_non_constant_value
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_multiple_ignores_whitespace_variant_1() async {
    Source source = addSource('''
int x = 3;
//ignore:invalid_assignment,const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_multiple_ignores_whitespace_variant_2() async {
    Source source = addSource('''
int x = 3;
//ignore: invalid_assignment,const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_multiple_ignores_whitespace_variant_3() async {
    Source source = addSource('''
int x = 3;
// ignore: invalid_assignment,const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_no_ignores() async {
    Source source = addSource('''
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  test_ignore_for_file() async {
    Source source = addSource('''
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// ignore_for_file: invalid_assignment
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  test_multiple_ignore_for_files() async {
    Source source = addSource('''
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// ignore_for_file: invalid_assignment,const_initialized_with_non_constant_value
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }

  test_ignore_for_file_whitespace_variant() async {
    Source source = addSource('''
//ignore_for_file:   const_initialized_with_non_constant_value , invalid_assignment
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
  }
}
