// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantIdentifierNamesTest);
    defineReflectiveTests(NonConstantIdentifierNamesRecordsTest);
  });
}

@reflectiveTest
class NonConstantIdentifierNamesRecordsTest extends LintRuleTest {
  @override
  List<String> get experiments => ['records'];

  @override
  String get lintRule => 'non_constant_identifier_names';

  test_recordFields() async {
    await assertDiagnostics(r'''
var a = (x: 1);
var b = (XX: 1);
''', [
      lint(25, 2),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3622')
  test_recordTypeAnnotation_named() async {
    await assertDiagnostics(r'''
(int, {String SS, bool b})? triple;
''', [
      lint(14, 2),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3622')
  test_recordTypeAnnotation_positional() async {
    await assertDiagnostics(r'''
(int, String SS, bool) triple = (1,'', false);
''', [
      lint(13, 2),
    ]);
  }

  test_recordTypeDeclarations() async {
    await assertDiagnostics(r'''
var AA = (x: 1);
const BB = (x: 1);
''', [
      lint(4, 2),
    ]);
  }

  test_test_recordFields_underscores() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var a = (_x: 1);
''', [
      // No Lint.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 9, 2),
    ]);
  }
}

@reflectiveTest
class NonConstantIdentifierNamesTest extends LintRuleTest {
  @override
  String get lintRule => 'non_constant_identifier_names';

  ///https://github.com/dart-lang/linter/issues/193
  test_ignoreSyntheticNodes() async {
    await assertDiagnostics(r'''
class C <E>{ }
C<int>;
''', [
      // No lint
      error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 15, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 15, 1),
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 21, 1),
    ]);
  }
}
