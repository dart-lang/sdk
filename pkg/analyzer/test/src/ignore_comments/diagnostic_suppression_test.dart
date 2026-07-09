// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../src/dart/resolution/context_collection_resolution.dart';
import '../../src/dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorSuppressionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    await resolveTestCodeWithDiagnostics('''
// ignore: $ignoredCode
int x = '';
//      ^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
int _y = 0; //INVALID_ASSIGNMENT
//  ^^
// [diag.unusedElement] The declaration '_y' isn't referenced.
''');
  }

  test_ignoreFirstOfMultiple() async {
    await resolveTestCodeWithDiagnostics('''
// ignore: unnecessary_cast
int x = (0 as int);
// ... but no ignore here ...
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
//          ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_ignoreFirstOfMultipleWithTrailingComment() async {
    await resolveTestCodeWithDiagnostics('''
int x = (0 as int); // ignore: unnecessary_cast
// ... but no ignore here ...
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
//          ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_ignoreForFile() async {
    await resolveTestCodeWithDiagnostics('''
int x = (0 as int); //UNNECESSARY_CAST
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
//          ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
// ignore_for_file: unnecessary_cast
''');
  }

  test_ignoreForFileWithMuchWhitespace() async {
    await resolveTestCodeWithDiagnostics('''
//ignore_for_file:   unused_element , unnecessary_cast
int x = (0 as int);  //UNNECESSARY_CAST
String _foo = ''; //UNUSED_ELEMENT
''');
  }

  test_ignoreForFileWithTypeMatchesLint() async {
    await resolveTestCodeWithDiagnostics('''
// ignore_for_file: type=lint
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_ignoreForFileWithTypeMatchesUpperCase() async {
    await resolveTestCodeWithDiagnostics('''
// ignore_for_file: TYPE=LINT
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_ignoreForFileWithTypeMatchesWarning() async {
    await resolveTestCodeWithDiagnostics('''
// ignore_for_file: type=warning
void f() {
  var x = 1;
}
''');
  }

  test_ignoreForFileWithTypeMismatchLintVsWarning() async {
    await resolveTestCodeWithDiagnostics('''
// ignore_for_file: type=lint
int a = 0;
int _x = 1;
//  ^^
// [diag.unusedElement] The declaration '_x' isn't referenced.
''');
  }

  test_ignoreOnlyDiagnosticWithTrailingComment() async {
    await resolveTestCodeWithDiagnostics('''
int x = (0 as int); // ignore: unnecessary_cast
''');
  }

  test_ignoreSecondDiagnostic() async {
    await resolveTestCodeWithDiagnostics('''
//UNNECESSARY_CAST
int x = (0 as int);
//       ^^^^^^^^
// [diag.unnecessaryCast] Unnecessary cast.
// ignore: unused_element
String _foo = ''; //UNUSED_ELEMENT
''');
  }

  test_ignoreSecondDiagnosticWithTrailingComment() async {
    await resolveTestCodeWithDiagnostics('''
//UNNECESSARY_CAST
int x = (0 as int);
//       ^^^^^^^^
// [diag.unnecessaryCast] Unnecessary cast.
String _foo = ''; // ignore: $ignoredCode
''');
  }

  test_ignoreTypeMatches() async {
    await resolveTestCodeWithDiagnostics('''
// ignore: type=lint
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_ignoreTypeMismatchLintVsWarning() async {
    await resolveTestCodeWithDiagnostics('''
// ignore: type=lint
int _x = 1;
//  ^^
// [diag.unusedElement] The declaration '_x' isn't referenced.
''');
  }

  test_ignoreTypeWithBadType() async {
    await resolveTestCodeWithDiagnostics('''
// ignore: type=wrong
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
//          ^^^
// [diag.avoidTypesAsParameterNamesFormalParameter] The parameter name 'int' matches a visible type name.
''');
  }

  test_ignoreUniqueName() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

// ignore: deprecated_member_use
int f({@Required('x') int? a}) => 0;

// ignore: missing_required_param_with_details
int x = f();
''');
  }

  test_ignoreUpperCase() async {
    await resolveTestCodeWithDiagnostics('''
int x = (0 as int); // ignore: UNNECESSARY_CAST
''');
  }

  test_invalidCode() async {
    await resolveTestCodeWithDiagnostics('''
// ignore: right_format_wrong_code
int x = '';
//      ^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
//          ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_missingCodes() async {
    await resolveTestCodeWithDiagnostics('''
int x = 3;
// ignore:
String y = x + ''; //INVALID_ASSIGNMENT, ARGUMENT_TYPE_NOT_ASSIGNABLE
//         ^^^^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'String'.
//             ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_missingMetadataSuffix() async {
    await resolveTestCodeWithDiagnostics('''
// ignore invalid_assignment
String y = 3; //INVALID_ASSIGNMENT
//         ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
''');
  }

  test_multipleCodesInIgnore() async {
    await resolveTestCodeWithDiagnostics('''
int x = 3;
// ignore: unnecessary_cast, $ignoredCode
int _y = x as int; //UNNECESSARY_CAST, UNUSED_ELEMENT
''');
  }

  test_multipleCodesInIgnoreForFile() async {
    await resolveTestCodeWithDiagnostics('''
int x = (0 as int); //UNNECESSARY_CAST
String _foo = ''; //UNUSED_ELEMENT
// ignore_for_file: unnecessary_cast,$ignoredCode
''');
  }

  test_multipleCodesInIgnoreTrailingComment() async {
    await resolveTestCodeWithDiagnostics('''
int x = 3;
int _y = x as int; // ignore: unnecessary_cast, $ignoredCode
''');
  }

  test_multipleCommentsPreceding() async {
    await resolveTestCodeWithDiagnostics('''
int x = (0 as int); //This is the first comment...
//       ^^^^^^^^
// [diag.unnecessaryCast] Unnecessary cast.
// ignore: $ignoredCode
String _foo = ''; //UNUSED_ELEMENT
''');
  }

  test_noIgnores() async {
    await resolveTestCodeWithDiagnostics('''
int x = ''; //INVALID_ASSIGNMENT
//      ^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
var y = x + ''; //ARGUMENT_TYPE_NOT_ASSIGNABLE
//          ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
''');
  }

  test_trailingCommentDoesNotCountAsAbove() async {
    await resolveTestCodeWithDiagnostics('''
int x = (0 as int); // ignore: unnecessary_cast
int y = (0 as int);
//       ^^^^^^^^
// [diag.unnecessaryCast] Unnecessary cast.
''');
  }

  test_undefinedFunctionWithinFlutterCanBeIgnored() async {
    var file = getFile('$workspaceRootPath/flutter/lib/flutter.dart');

    await resolveFileWithDiagnostics(file, '''
// ignore: undefined_function
f() => g();
''');
  }

  test_undefinedFunctionWithinFlutterWithoutIgnore() async {
    var file = getFile('$workspaceRootPath/flutter/lib/flutter.dart');

    await resolveFileWithDiagnostics(file, '''
f() => g();
//     ^
// [diag.undefinedFunction] The function 'g' isn't defined.
''');
  }

  test_undefinedPrefixedNameWithinFlutterCanBeIgnored() async {
    var file = getFile('$workspaceRootPath/flutter/lib/flutter.dart');

    await resolveFileWithDiagnostics(file, '''
import 'dart:collection' as c;
// ignore: undefined_prefixed_name
f() => c.g;
''');
  }
}
