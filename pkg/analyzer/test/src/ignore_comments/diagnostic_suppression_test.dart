// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:linter/src/lint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorSuppressionTest);
  });
}

@reflectiveTest
class ErrorSuppressionTest extends PubPackageResolutionTest {
  String get ignoredCode => 'unused_element';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(
        experiments: experiments,
        rules: ['avoid_types_as_parameter_names'],
      ),
    );
  }

  test_codeMismatch() async {
    await assertErrorsInCode(
      '''
// ignore: $ignoredCode
int x = '';
int _y = 0; //INVALID_ASSIGNMENT
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 34, 2),
        error(WarningCode.unusedElement, 42, 2),
      ],
    );
  }

  test_ignoreFirstOfMultiple() async {
    await assertErrorsInCode(
      '''
// ignore: unnecessary_cast
int x = (0 as int);
// ... but no ignore here ...
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 90, 2)],
    );
  }

  test_ignoreFirstOfMultipleWithTrailingComment() async {
    await assertErrorsInCode(
      '''
int x = (0 as int); // ignore: unnecessary_cast
// ... but no ignore here ...
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 90, 2)],
    );
  }

  test_ignoreForFile() async {
    await assertErrorsInCode(
      '''
int x = (0 as int); //UNNECESSARY_CAST
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
// ignore_for_file: unnecessary_cast
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 51, 2)],
    );
  }

  test_ignoreForFileWithMuchWhitespace() async {
    await assertNoErrorsInCode('''
//ignore_for_file:   unused_element , unnecessary_cast
int x = (0 as int);  //UNNECESSARY_CAST
String _foo = ''; //UNUSED_ELEMENT
''');
  }

  test_ignoreForFileWithTypeMatchesLint() async {
    await assertNoErrorsInCode('''
// ignore_for_file: type=lint
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_ignoreForFileWithTypeMatchesUpperCase() async {
    await assertNoErrorsInCode('''
// ignore_for_file: TYPE=LINT
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_ignoreForFileWithTypeMatchesWarning() async {
    await assertNoErrorsInCode('''
// ignore_for_file: type=warning
void f() {
  var x = 1;
}
''');
  }

  test_ignoreForFileWithTypeMismatchLintVsWarning() async {
    await assertErrorsInCode(
      '''
// ignore_for_file: type=lint
int a = 0;
int _x = 1;
''',
      [error(WarningCode.unusedElement, 45, 2)],
    );
  }

  test_ignoreOnlyDiagnosticWithTrailingComment() async {
    await assertNoErrorsInCode('''
int x = (0 as int); // ignore: unnecessary_cast
''');
  }

  test_ignoreSecondDiagnostic() async {
    await assertErrorsInCode(
      '''
//UNNECESSARY_CAST
int x = (0 as int);
// ignore: unused_element
String _foo = ''; //UNUSED_ELEMENT
''',
      [error(WarningCode.unnecessaryCast, 28, 8)],
    );
  }

  test_ignoreSecondDiagnosticWithTrailingComment() async {
    await assertErrorsInCode(
      '''
//UNNECESSARY_CAST
int x = (0 as int);
String _foo = ''; // ignore: $ignoredCode
''',
      [error(WarningCode.unnecessaryCast, 28, 8)],
    );
  }

  test_ignoreTypeMatches() async {
    await assertNoErrorsInCode('''
// ignore: type=lint
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_ignoreTypeMismatchLintVsWarning() async {
    await assertErrorsInCode(
      '''
// ignore: type=lint
int _x = 1;
''',
      [error(WarningCode.unusedElement, 25, 2)],
    );
  }

  test_ignoreTypeWithBadType() async {
    await assertErrorsInCode(
      '''
// ignore: type=wrong
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''',
      [error(LinterLintCode.avoidTypesAsParameterNamesFormalParameter, 34, 3)],
    );
  }

  test_ignoreUniqueName() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

int f({@Required('x') int? a}) => 0;

// ignore: missing_required_param_with_details
int x = f();
''');
  }

  test_ignoreUpperCase() async {
    await assertNoErrorsInCode('''
int x = (0 as int); // ignore: UNNECESSARY_CAST
''');
  }

  test_invalidCode() async {
    await assertErrorsInCode(
      '''
// ignore: right_format_wrong_code
int x = '';
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 43, 2),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 59, 2),
      ],
    );
  }

  test_missingCodes() async {
    await assertErrorsInCode(
      '''
int x = 3;
// ignore:
String y = x + ''; //INVALID_ASSIGNMENT, ARGUMENT_TYPE_NOT_ASSIGNABLE
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 33, 6),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 37, 2),
      ],
    );
  }

  test_missingMetadataSuffix() async {
    await assertErrorsInCode(
      '''
// ignore invalid_assignment
String y = 3; //INVALID_ASSIGNMENT
''',
      [error(CompileTimeErrorCode.invalidAssignment, 40, 1)],
    );
  }

  test_multipleCodesInIgnore() async {
    await assertNoErrorsInCode('''
int x = 3;
// ignore: unnecessary_cast, $ignoredCode
int _y = x as int; //UNNECESSARY_CAST, UNUSED_ELEMENT
''');
  }

  test_multipleCodesInIgnoreForFile() async {
    await assertNoErrorsInCode('''
int x = (0 as int); //UNNECESSARY_CAST
String _foo = ''; //UNUSED_ELEMENT
// ignore_for_file: unnecessary_cast,$ignoredCode
''');
  }

  test_multipleCodesInIgnoreTrailingComment() async {
    await assertNoErrorsInCode('''
int x = 3;
int _y = x as int; // ignore: unnecessary_cast, $ignoredCode
''');
  }

  test_multipleCommentsPreceding() async {
    await assertErrorsInCode(
      '''
int x = (0 as int); //This is the first comment...
// ignore: $ignoredCode
String _foo = ''; //UNUSED_ELEMENT
''',
      [error(WarningCode.unnecessaryCast, 9, 8)],
    );
  }

  test_noIgnores() async {
    await assertErrorsInCode(
      '''
int x = ''; //INVALID_ASSIGNMENT
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 8, 2),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 45, 2),
      ],
    );
  }

  test_trailingCommentDoesNotCountAsAbove() async {
    await assertErrorsInCode(
      '''
int x = (0 as int); // ignore: unnecessary_cast
int y = (0 as int);
''',
      [error(WarningCode.unnecessaryCast, 57, 8)],
    );
  }

  test_undefinedFunctionWithinFlutterCanBeIgnored() async {
    await assertErrorsInFile('$workspaceRootPath/flutterlib/flutter.dart', '''
// ignore: undefined_function
f() => g();
''', []);
  }

  test_undefinedFunctionWithinFlutterWithoutIgnore() async {
    await assertErrorsInFile(
      '$workspaceRootPath/flutterlib/flutter.dart',
      '''
f() => g();
''',
      [error(CompileTimeErrorCode.undefinedFunction, 7, 1)],
    );
  }

  test_undefinedPrefixedNameWithinFlutterCanBeIgnored() async {
    await assertErrorsInFile('$workspaceRootPath/flutterlib/flutter.dart', '''
import 'dart:collection' as c;
// ignore: undefined_prefixed_name
f() => c.g;
''', []);
  }
}
