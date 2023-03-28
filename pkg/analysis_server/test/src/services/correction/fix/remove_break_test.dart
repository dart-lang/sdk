// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveBreakBulkTest);
    defineReflectiveTests(RemoveBreakTest);
  });
}

@reflectiveTest
class RemoveBreakBulkTest extends BulkFixProcessorTest {
  @override
  List<String> get experiments => ['patterns', 'records'];

  @override
  String get lintCode => LintNames.unnecessary_breaks;

  Future<void> test_singleFile_sameLine() async {
    await resolveTestCode('''
void f() {
  switch (0) {
    case 1:
      1; break;
    case 2:
      2; break;
  }
}
''');
    await assertHasFix('''
void f() {
  switch (0) {
    case 1:
      1;
    case 2:
      2;
  }
}
''');
  }

  Future<void> test_singleFile_separateLine() async {
    await resolveTestCode('''
void f() {
  switch (0) {
    case 1:
      1;
      break;
    case 2:
      2;
      break;
  }
}
''');
    await assertHasFix('''
void f() {
  switch (0) {
    case 1:
      1;
    case 2:
      2;
  }
}
''');
  }
}

@reflectiveTest
class RemoveBreakTest extends FixProcessorLintTest {
  @override
  List<String> get experiments => ['patterns', 'records'];

  @override
  FixKind get kind => DartFixKind.REMOVE_BREAK;

  @override
  String get lintCode => LintNames.unnecessary_breaks;

  Future<void> test_single_sameLine() async {
    await resolveTestCode('''
void f() {
  switch (0) {
    case 1:
      1; break;
    case 2:
      2;
  }
}
''');
    await assertHasFix('''
void f() {
  switch (0) {
    case 1:
      1;
    case 2:
      2;
  }
}
''');
  }

  Future<void> test_single_separateLine() async {
    await resolveTestCode('''
void f() {
  switch (0) {
    case 1:
      1;
      break;
    case 2:
      2;
  }
}
''');
    await assertHasFix('''
void f() {
  switch (0) {
    case 1:
      1;
    case 2:
      2;
  }
}
''');
  }
}
