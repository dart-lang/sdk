// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddLeadingNewlineToStringBulkTest);
    defineReflectiveTests(AddLeadingNewlineToStringTest);
  });
}

@reflectiveTest
class AddLeadingNewlineToStringBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.leading_newlines_in_multiline_strings;

  Future<void> test_three_fixes() async {
    await resolveTestCode('''
var s1 = \'''{
  "a": 1,
  "b": 2
}\''';

var s2 = \'''{
  "c": 3,
  "d": 4
}\''';

var s3 = \'''{
  "e": 5,
  "f": 6
}\''';
''');
    await assertHasFix('''
var s1 = \'''
{
  "a": 1,
  "b": 2
}\''';

var s2 = \'''
{
  "c": 3,
  "d": 4
}\''';

var s3 = \'''
{
  "e": 5,
  "f": 6
}\''';
''');
  }
}

@reflectiveTest
class AddLeadingNewlineToStringTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_LEADING_NEWLINE_TO_STRING;

  @override
  String get lintCode => LintNames.leading_newlines_in_multiline_strings;

  Future<void> test_one_fix() async {
    await resolveTestCode('''
var s1 = \'''{
  "a": 1,
  "b": 2
}\''';
''');
    await assertHasFix('''
var s1 = \'''
{
  "a": 1,
  "b": 2
}\''';
''');
  }
}
