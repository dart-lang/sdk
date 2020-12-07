// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorSuppressionTest);
  });
}

@reflectiveTest
class ErrorSuppressionTest extends PubPackageResolutionTest {
  String get ignoredCode => 'unused_element';

  test_does_not_ignore_errors() async {
    await assertErrorsInCode('''
int x = ''; // ignore: invalid_assignment
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 8, 2),
    ]);
  }

  test_error_cannot_be_ignored() async {
    await assertErrorsInCode('''
// ignore: unused_import, undefined_function
f() => g();
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 52, 1),
    ]);
  }

  test_error_code_mismatch() async {
    await assertErrorsInCode('''
// ignore: $ignoredCode
int x = '';
int _y = 0; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 34, 2),
      error(HintCode.UNUSED_ELEMENT, 42, 2),
    ]);
  }

  test_ignore_first() async {
    await assertErrorsInCode('''
// ignore: unnecessary_cast
int x = (0 as int);
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 88,
          1),
    ]);
  }

  test_ignore_first_trailing() async {
    await assertErrorsInCode('''
int x = (0 as int); // ignore: unnecessary_cast
// ... but no ignore here ...
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 88,
          1),
    ]);
  }

  test_ignore_for_file() async {
    await assertErrorsInCode('''
int x = (0 as int); //UNNECESSARY_CAST
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// ignore_for_file: unnecessary_cast
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 49,
          1),
    ]);
  }

  test_ignore_for_file_whitespace_variant() async {
    await assertNoErrorsInCode('''
//ignore_for_file:   unused_element , unnecessary_cast
int x = (0 as int);  //UNNECESSARY_CAST
String _foo; //UNUSED_ELEMENT
''');
  }

  test_ignore_only_trailing() async {
    await assertNoErrorsInCode('''
int x = (0 as int); // ignore: unnecessary_cast
''');
  }

  test_ignore_second() async {
    await assertErrorsInCode('''
//UNNECESSARY_CAST
int x = (0 as int);
// ignore: unused_element
String _foo; //UNUSED_ELEMENT
''', [
      error(HintCode.UNNECESSARY_CAST, 28, 8),
    ]);
  }

  test_ignore_second_trailing() async {
    await assertErrorsInCode('''
//UNNECESSARY_CAST
int x = (0 as int);
String _foo; // ignore: $ignoredCode
''', [
      error(HintCode.UNNECESSARY_CAST, 28, 8),
    ]);
  }

  test_ignore_uniqueName() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

int f({@Required('x') int a}) => 0;

// ignore: missing_required_param_with_details
int x = f();
''');
  }

  test_ignore_upper_case() async {
    await assertNoErrorsInCode('''
int x = (0 as int); // ignore: UNNECESSARY_CAST
''');
  }

  test_invalid_error_code() async {
    await assertErrorsInCode('''
// ignore: right_format_wrong_code
int x = '';
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 43, 2),
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
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 43, 1),
    ]);
  }

  test_missing_metadata_suffix() async {
    await assertErrorsInCode('''
// ignore invalid_assignment
String y = 3; //INVALID_ASSIGNMENT
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 40, 1),
    ]);
  }

  test_multiple_comments() async {
    await assertErrorsInCode('''
int x = (0 as int); //This is the first comment...
// ignore: $ignoredCode
String _foo; //UNUSED_ELEMENT
''', [
      error(HintCode.UNNECESSARY_CAST, 9, 8),
    ]);
  }

  test_multiple_ignore_for_files() async {
    await assertNoErrorsInCode('''
int x = (0 as int); //UNNECESSARY_CAST
String _foo; //UNUSED_ELEMENT
// ignore_for_file: unnecessary_cast,$ignoredCode
''');
  }

  test_multiple_ignores() async {
    await assertNoErrorsInCode('''
int x = 3;
// ignore: unnecessary_cast, $ignoredCode
int _y = x as int; //UNNECESSARY_CAST, UNUSED_ELEMENT
''');
  }

  test_multiple_ignores_trailing() async {
    await assertNoErrorsInCode('''
int x = 3;
int _y = x as int; // ignore: unnecessary_cast, $ignoredCode
''');
  }

  test_multiple_ignores_whitespace_variant_1() async {
    await assertNoErrorsInCode('''
int x = 3;
//ignore:unnecessary_cast,$ignoredCode
int _y = x as int; //UNNECESSARY_CAST, UNUSED_ELEMENT
''');
  }

  test_multiple_ignores_whitespace_variant_2() async {
    await assertNoErrorsInCode('''
int x = 3;
//ignore: unnecessary_cast,$ignoredCode
int _y = x as int; //UNNECESSARY_CAST, UNUSED_ELEMENT
''');
  }

  test_multiple_ignores_whitespace_variant_3() async {
    await assertNoErrorsInCode('''
int x = 3;
// ignore: unnecessary_cast,$ignoredCode
int _y = x as int; //UNNECESSARY_CAST, UNUSED_ELEMENT
''');
  }

  test_no_ignores() async {
    await assertErrorsInCode('''
int x = ''; //INVALID_ASSIGNMENT
const y = x; //CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 8, 2),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 43,
          1),
    ]);
  }

  test_trailing_not_above() async {
    await assertErrorsInCode('''
int x = (0 as int); // ignore: unnecessary_cast
int y = (0 as int);
''', [
      error(HintCode.UNNECESSARY_CAST, 57, 8),
    ]);
  }

  test_undefined_function_within_flutter_can_be_ignored() async {
    await assertErrorsInFile(
      '$workspaceRootPath/flutterlib/flutter.dart',
      '''
// ignore: undefined_function
f() => g();
''',
      [],
    );
  }

  test_undefined_function_within_flutter_without_ignore() async {
    await assertErrorsInFile(
      '$workspaceRootPath/flutterlib/flutter.dart',
      '''
f() => g();
''',
      [error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 7, 1)],
    );
  }

  test_undefined_prefixed_name_within_flutter_can_be_ignored() async {
    await assertErrorsInFile(
      '$workspaceRootPath/flutterlib/flutter.dart',
      '''
import 'dart:collection' as c;
// ignore: undefined_prefixed_name
f() => c.g;
''',
      [],
    );
  }
}
