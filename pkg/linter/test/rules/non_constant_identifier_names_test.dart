// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantIdentifierNamesTest);
    defineReflectiveTests(NonConstantIdentifierNamesRecordsTest);
    defineReflectiveTests(NonConstantIdentifierNamesPatternsTest);
  });
}

@reflectiveTest
class NonConstantIdentifierNamesPatternsTest extends LintRuleTest {
  @override
  String get lintRule => 'non_constant_identifier_names';

  test_extensionType_representationConstructorName() async {
    await assertDiagnostics(r'''
extension type e.Efg(int i) {}
''', [
      lint(17, 3),
    ]);
  }

  test_patternForStatement() async {
    await assertDiagnostics(r'''
void f() {
  for (var (AB, c) = (0, 1); AB <= 13; (AB, c) = (c, AB + c)) { }
}
''', [
      lint(23, 2),
    ]);
  }

  test_patternIfStatement() async {
    await assertDiagnostics(r'''
void f() {
  if ([1,2] case [int AB, int c]) { }
}
''', [
      lint(33, 2),
    ]);
  }

  test_patternIfStatement_recordField() async {
    await assertDiagnostics(r'''
void f(Object o) {
  if (o case (a: int AB, BC: int CD)) { }
}
''', [
      lint(40, 2),
      lint(52, 2),
    ]);
  }

  test_patternIfStatement_recordField_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  if (o case (:int AB, var b)) { }
}
''');
  }

  test_patternIfStatement_underscores() async {
    await assertNoDiagnostics(r'''
void f() {
  if ([1,2] case [int _, int _]) { }
}
''');
  }

  test_patternList_declaration() async {
    await assertDiagnostics(r'''
f() {
  var [__, foo_bar] = [1,2];
}
''', [
      lint(13, 2),
      lint(17, 7),
    ]);
  }

  test_patternList_declaration_underscore_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [_, a] = [1,2];
}
''');
  }

  test_patternList_wildCardPattern() async {
    await assertNoDiagnostics(r'''
f() {
  var a = 0;
  [_, a] = [1,2];
}
''');
  }

  test_patternRecordField() async {
    await assertDiagnostics(r'''
void f() {
  var (AB, ) = (1, );
}
''', [
      lint(18, 2),
    ]);
  }

  test_patternRecordField_shortcut_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  switch(o) {
    case (:int AB, var b):
  }
  switch(o) {
    case (:int AB?, var b):
    case (:int AB!, var b):
  }
}
''');
  }

  test_patternRecordField_underscores() async {
    await assertDiagnostics(r'''
void f() {
  var (___, ) = (1, );
}
''', [
      lint(18, 3),
    ]);
  }
}

@reflectiveTest
class NonConstantIdentifierNamesRecordsTest extends LintRuleTest {
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

  test_recordFields_fieldNameDuplicated() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var r = (a: 1, a: 2);
''', [
      // No Lint.
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 15, 1),
    ]);
  }

  test_recordFields_fieldNameFromObject() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var a = (hashCode: 1);
''', [
      // No Lint.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 9, 8),
    ]);
  }

  test_recordFields_fieldNamePositional() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var r = (0, $1: 2);
''', [
      // No Lint.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 12, 2),
    ]);
  }

  test_recordFields_privateFieldName() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var a = (_x: 1);
''', [
      // No Lint.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 9, 2),
    ]);
  }

  test_recordTypeAnnotation_named() async {
    await assertDiagnostics(r'''
(int, {String SS, bool b})? triple;
''', [
      lint(14, 2),
    ]);
  }

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
