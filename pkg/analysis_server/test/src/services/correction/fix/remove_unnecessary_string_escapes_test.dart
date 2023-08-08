// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryStringEscapeBulkTest);
    defineReflectiveTests(RemoveUnnecessaryStringEscapeTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryStringEscapeBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_string_escapes;

  Future<void> test_in_file() async {
    await parseTestCode(r'''
var a = '\a\c\e';
''');
    await assertHasFix('''
var a = 'ace';
''', isParse: true);
  }

  Future<void> test_interpolation_multiple() async {
    await parseTestCode(r'''
void f(String s1, String s2) {
  print('a$s1\b$s2\c\9d');
}
''');
    await assertHasFix(r'''
void f(String s1, String s2) {
  print('a$s1\b${s2}c9d');
}
''', isParse: true);
  }
}

@reflectiveTest
class RemoveUnnecessaryStringEscapeTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_STRING_ESCAPE;

  @override
  String get lintCode => LintNames.unnecessary_string_escapes;

  Future<void> test_interpolation() async {
    await resolveTestCode(r'''
void f(String hello) {
  print('Sort$hello\Numbers');
}
''');
    await assertHasFix(r'''
void f(String hello) {
  print('Sort${hello}Numbers');
}
''');
  }

  Future<void> test_interpolation_with_brace() async {
    await resolveTestCode(r'''
void f(String b) {
  print('a${b}\c');
}
''');
    await assertHasFix(r'''
void f(String b) {
  print('a${b}c');
}
''');
  }

  Future<void> test_interpolation_with_space() async {
    await resolveTestCode(r'''
void f(String b) {
  print('a$b c\d');
}
''');
    await assertHasFix(r'''
void f(String b) {
  print('a$b cd');
}
''');
  }

  Future<void> test_letter() async {
    await resolveTestCode(r'''
var a = '\a';
''');
    await assertHasFix('''
var a = 'a';
''');
  }
}
