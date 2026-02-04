// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryNameBulkTest);
    defineReflectiveTests(RemoveUnnecessaryNameTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryNameBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.simplify_variable_pattern;

  Future<void> test_singleFile() async {
    await parseTestCode('''
void f(Object o) {
  if (o case int(isEven:var isEven) when isEven) {}
  if (o case int(isOdd:var isOdd) when isOdd) {}
}
''');
    await assertHasFix('''
void f(Object o) {
  if (o case int(:var isEven) when isEven) {}
  if (o case int(:var isOdd) when isOdd) {}
}
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryNameTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeUnnecessaryName;

  @override
  String get lintCode => LintNames.simplify_variable_pattern;

  Future<void> test_patternField_explicit() async {
    await resolveTestCode('''
void f(Object o) {
  if (o case int(isEven:var isEven) when isEven) {}
}
''');
    await assertHasFix('''
void f(Object o) {
  if (o case int(:var isEven) when isEven) {}
}
''');
  }

  Future<void> test_recordDestructuring() async {
    await resolveTestCode('''
void f((int, {String name}) record) {
  var (x, name: name) = record;
  print(name);
}
''');
    await assertHasFix('''
void f((int, {String name}) record) {
  var (x, : name) = record;
  print(name);
}
''');
  }
}
