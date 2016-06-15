// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ErrorSuppressionTest);
}

@reflectiveTest
class ErrorSuppressionTest extends ResolverTestCase {
  void test_error_code_mismatch() {
    Source source = addSource('''
// ignore: const_initialized_with_non_constant_value
int x = '';
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  void test_ignore_first() {
    Source source = addSource('''
// ignore: invalid_assignment
int x = '';
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  void test_ignore_first_trailing() {
    Source source = addSource('''
int x = ''; // ignore: invalid_assignment
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  void test_ignore_only_trailing() {
    Source source = addSource('''
int x = ''; // ignore: invalid_assignment
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_ignore_second() {
    Source source = addSource('''
//INVALID_ASSIGNMENT
int x = '';
// ignore: const_initialized_with_non_constant_value
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_ignore_second_trailing() {
    Source source = addSource('''
//INVALID_ASSIGNMENT
int x = '';
const y = x; // ignore: const_initialized_with_non_constant_value
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_ignore_upper_case() {
    Source source = addSource('''
int x = ''; // ignore: INVALID_ASSIGNMENT
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_invalid_error_code() {
    Source source = addSource('''
// ignore: right_format_wrong_code
int x = '';
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  void test_missing_error_codes() {
    Source source = addSource('''
    int x = 3;
// ignore:
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  void test_missing_metadata_suffix() {
    Source source = addSource('''
// ignore invalid_assignment
String y = 3; //INVALID_ASSIGNMENT
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_multiple_comments() {
    Source source = addSource('''
int x = ''; //This is the first comment...
// ignore: const_initialized_with_non_constant_value
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_multiple_ignores() {
    Source source = addSource('''
int x = 3;
// ignore: invalid_assignment, const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_multiple_ignores_traling() {
    Source source = addSource('''
int x = 3;
const String y = x; // ignore: invalid_assignment, const_initialized_with_non_constant_value
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_multiple_ignores_whitespace_variant_1() {
    Source source = addSource('''
int x = 3;
//ignore:invalid_assignment,const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_multiple_ignores_whitespace_variant_2() {
    Source source = addSource('''
int x = 3;
//ignore: invalid_assignment,const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_multiple_ignores_whitespace_variant_3() {
    Source source = addSource('''
int x = 3;
// ignore: invalid_assignment,const_initialized_with_non_constant_value
const String y = x; //INVALID_ASSIGNMENT, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_no_ignores() {
    Source source = addSource('''
int x = '';  //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      StaticTypeWarningCode.INVALID_ASSIGNMENT,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }
}
