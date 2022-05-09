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
    defineReflectiveTests(RemoveAssignmentBulkTest);
    defineReflectiveTests(RemoveAssignmentTest);
  });
}

@reflectiveTest
class RemoveAssignmentBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_null_aware_assignments;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  var x;
  var y;
  x ??= null;
  y ??= null;
}
''');
    await assertHasFix('''
void f() {
  var x;
  var y;
}
''');
  }
}

@reflectiveTest
class RemoveAssignmentTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_ASSIGNMENT;

  @override
  String get lintCode => LintNames.unnecessary_null_aware_assignments;

  Future<void> test_assignment() async {
    await resolveTestCode('''
void f() {
  var x;
  x ??= null;
}
''');
    await assertHasFix('''
void f() {
  var x;
}
''');
  }

  Future<void> test_assignment_compound() async {
    await resolveTestCode('''
void f(x, y) {
  y = x ??= null;
}
''');
    await assertHasFix('''
void f(x, y) {
  y = x;
}
''');
  }

  Future<void> test_assignment_parenthesized() async {
    await resolveTestCode('''
void f(int? x) {
  (x ??= null);
}
''');
    await assertHasFix('''
void f(int? x) {
}
''');
  }
}
